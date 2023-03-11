#include <Wire.h>
#include <bluefruit.h>
#include <avr/dtostrf.h>
#include <Adafruit_SleepyDog.h>
#include <Arduino.h>
// This demo explores two reports (SH2_ARVR_STABILIZED_RV and SH2_GYRO_INTEGRATED_RV) both can be used to give 
// quartenion and euler (yaw, pitch roll) angles.  Toggle the FAST_MODE define to see other report.  
// Note sensorValue.status gives calibration accuracy (which improves over time)
#include <Adafruit_BNO08x.h>


// For SPI mode, we need a CS pin
#define BNO08X_CS 10
#define BNO08X_INT 9

// #define FAST_MODE

// For SPI mode, we also need a RESET 
//#define BNO08X_RESET 5
// but not for I2C or UART
#define BNO08X_RESET -1

struct euler_t {
  float yaw;
  float pitch;
  float roll;
} ypr;

Adafruit_BNO08x  bno08x(BNO08X_RESET);
sh2_SensorValue_t sensorValue;

// BLE Service
BLEDis  bledis;
BLEUart bleuart;
BLEBas  blebas; // battery service
BLEService        gyroService = BLEService(0x180D);
BLECharacteristic gyroCharact = BLECharacteristic(0xABCD);

// Software Timer for blinking RED LED
SoftwareTimer blinkTimer;
int iCounter = 0;
unsigned int long fTime1 = 0;
unsigned int long fTime2;

#ifdef FAST_MODE
  // Top frequency is reported to be 1000Hz (but freq is somewhat variable)
  sh2_SensorId_t reportType = SH2_GYRO_INTEGRATED_RV;
  long reportIntervalUs = 2000;
#else
  // Top frequency is about 250Hz but this report is more accurate
  //sh2_SensorId_t reportType = SH2_ARVR_STABILIZED_RV;
  sh2_SensorId_t reportType = SH2_GAME_ROTATION_VECTOR;
  long reportIntervalUs = 5000;
#endif
void setReports(sh2_SensorId_t reportType, long report_interval) {
  Serial.println("Setting desired reports");
  if (! bno08x.enableReport(reportType, report_interval)) {
    Serial.println("Could not enable stabilized remote vector");
  }
  if (!bno08x.enableReport(SH2_GAME_ROTATION_VECTOR)) {
    Serial.println("Could not enable game rotation vector");
  }
}

void setup()
{
  Serial.begin(115200);
  while (!Serial) delay(10);     // will pause Zero, Leonardo, etc until serial console opens
  Serial.println("Serial starts");

  // Start watchdog
  int countdownMS = Watchdog.enable(5000);  
  
  Serial.println("Adafruit BNO08x test!");
  // Try to initialize!
  if (!bno08x.begin_I2C()) {
    Serial.println("Failed to find BNO08x chip");
    while (1) { delay(10); }
  }
  Serial.println("BNO08x Found!");
  setReports(reportType, reportIntervalUs);
  Serial.println("Reading events");
  delay(100);

  // Bluetooth connection
  Serial.println("Bluefruit52 BLEUART Example");
  Serial.println("---------------------------\n");

  // Initialize blinkTimer for 1000 ms and start it
  blinkTimer.begin(1000, blink_timer_callback);
  blinkTimer.start();

  // Setup the BLE LED to be enabled on CONNECT
  // Note: This is actually the default behaviour, but provided
  // here in case you want to control this LED manually via PIN 19
  Bluefruit.autoConnLed(true);

  // Config the peripheral connection with maximum bandwidth
  // more SRAM required by SoftDevice
  // Note: All config***() function must be called before begin()
  Bluefruit.configPrphBandwidth(BANDWIDTH_MAX);

  Bluefruit.begin();
  // Set max power. Accepted values are: -40, -30, -20, -16, -12, -8, -4, 0, 4
  Bluefruit.setTxPower(4);
  Bluefruit.setName("Oldyhead");
  Bluefruit.Periph.setConnectCallback(connect_callback);
  Bluefruit.Periph.setDisconnectCallback(disconnect_callback);

  // Configure and Start Device Information Service
  bledis.setManufacturer("Adafruit Industries");
  bledis.setModel("Bluefruit Feather52");
  bledis.begin();

  // Configure and Start BLE Uart Service
  bleuart.begin();

  // Set up and start advertising
  startAdv();
}

void startAdv(void)
{
  // Advertising packet
  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.addTxPower();

  // Include bleuart 128-bit uuid
  Bluefruit.Advertising.addService(bleuart);

  // Secondary Scan Response packet (optional)
  // Since there is no room for 'Name' in Advertising packet
  Bluefruit.ScanResponse.addName();

  /* Start Advertising
     - Enable auto advertising if disconnected
     - Interval:  fast mode = 20 ms, slow mode = 152.5 ms
     - Timeout for fast mode is 30 seconds
     - Start(timeout) with timeout = 0 will advertise forever (until connected)

     For recommended advertising interval
     https://developer.apple.com/library/content/qa/qa1931/_index.html
  */
  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(32, 244);    // in unit of 0.625 ms
  Bluefruit.Advertising.setFastTimeout(30);      // number of seconds in fast mode
  Bluefruit.Advertising.start(0);                // 0 = Don't stop advertising after n seconds
}

void connect_callback(uint16_t conn_handle)
{
  // Get the reference to current connection
  BLEConnection* connection = Bluefruit.Connection(conn_handle);

  char central_name[32] = { 0 };
  connection->getPeerName(central_name, sizeof(central_name));

  Serial.print("Connected to ");
  Serial.println(central_name);

    // request PHY changed to 2MB
  Serial.println("Request to change PHY");
  //connection->requestPHY();

  // request to update data length
  //Serial.println("Request to change Data Length");
  //connection->requestDataLengthUpdate();
    
  // request mtu exchange
  Serial.println("Request to change MTU");
  //connection->requestMtuExchange(247);
  //connection->requestMtuExchange(46); // minimum: 23

  // request connection interval of 7.5 ms
  connection->requestConnectionParameter(6); // in unit of 1.25

  Serial.printf("Connection Info: PHY = %d Mbps, Conn Interval = %.2f ms, Data Length = %d, MTU = %d\n",
                  connection->getPHY(), connection->getConnectionInterval()*1.25f, connection->getDataLength(), connection->getMtu());

  // delay a bit for all the request to complete
  delay(2000);
  connection->requestConnectionParameter(6); // in unit of 1.25 // called second time, do not know why it is necessary

  Serial.printf("Connection Info: PHY = %d Mbps, Conn Interval = %.2f ms, Data Length = %d, MTU = %d\n",
                  connection->getPHY(), connection->getConnectionInterval()*1.25f, connection->getDataLength(), connection->getMtu());
}

void disconnect_callback(uint16_t conn_handle, uint8_t reason)
{
  (void) conn_handle;
  (void) reason;

  Serial.println();
  // delay a bit for all the request to complete
  delay(1000);  
  //Serial.print("Disconnected, reason = 0x"); Serial.println(reason, HEX);
}
void blink_timer_callback(TimerHandle_t xTimerID)
{
  (void) xTimerID;
  digitalToggle(LED_RED);
}

void rtos_idle_callback(void)
{
  // Don't call any other FreeRTOS blocking API()
  // Perform background task(s) here
}


void quaternionToEuler(float qr, float qi, float qj, float qk, euler_t* ypr, bool degrees = false) {

//    float t=qi; qi=qj; qj=t; qk=-qk;
//    
//    float sqr = sq(qr);
//    float sqi = sq(qi);
//    float sqj = sq(qj);
//    float sqk = sq(qk);
//    
//    ypr->yaw = atan2(2.0 * (qi * qj + qk * qr), (sqi - sqj - sqk + sqr));
//    ypr->pitch = asin(-2.0 * (qi * qk - qj * qr) / (sqi + sqj + sqk + sqr));
//    ypr->roll = atan2(2.0 * (qj * qk + qi * qr), (-sqi - sqj + sqk + sqr));

    float quatI = qi; 
    float quatReal = qr; 
    float quatJ = qj; 
    float quatK = qk; 

    //Serial.println(sq(qi)+sq(qr)+sq(qj)+sq(qk));
    if (sq(qi)+sq(qr)+sq(qj)+sq(qk)<0.99){
      if (sq(qi)+sq(qr)+sq(qj)+sq(qk)>1.01){
        Serial.println(sq(qi)+sq(qr)+sq(qj)+sq(qk));
        Serial.println("Hier stimmt etwas nichtHier stimmt etwas nichtHier stimmt etwas nichtHier stimmt etwas nichtHier stimmt etwas nichtHier stimmt etwas nichtHier stimmt etwas nichtHier stimmt etwas nicht!");
      }
    }
    float sqx = quatI * quatI;
    float sqy = quatJ * quatJ;
    float sqz = quatK * quatK;
    ypr->roll = atan2(2 * quatI * quatReal + 2 * quatJ * quatK , 1 - 2 * sqx - 2 * sqy);
    ypr->pitch = asin(2 * quatJ * quatReal - 2 * quatI * quatK);
    ypr->yaw = atan2(2 * quatK * quatReal + 2 * quatI * quatJ , 1 - 2 * sqy - 2 * sqz);

  
    if (degrees) {
      ypr->yaw *= RAD_TO_DEG;
      ypr->pitch *= RAD_TO_DEG;
      ypr->roll *= RAD_TO_DEG;
    }
    else {
      float twoPi = 2.0 * 3.141592865;
      ypr->yaw = wrapAngle(ypr->yaw);
      ypr->pitch = wrapAngle(ypr->pitch);
      ypr->roll = wrapAngle(ypr->roll);
    }
}

void quaternionToEulerRV(sh2_RotationVectorWAcc_t* rotational_vector, euler_t* ypr, bool degrees = false) {
    quaternionToEuler(rotational_vector->real, rotational_vector->i, rotational_vector->j, rotational_vector->k, ypr, degrees);
}

void quaternionToEulerGI(sh2_GyroIntegratedRV_t* rotational_vector, euler_t* ypr, bool degrees = false) {
    quaternionToEuler(rotational_vector->real, rotational_vector->i, rotational_vector->j, rotational_vector->k, ypr, degrees);
}

void quaternionToEulerGRV(sh2_RotationVector* rotational_vector, euler_t* ypr, bool degrees = false) {
    quaternionToEuler(rotational_vector->real, rotational_vector->i, rotational_vector->j, rotational_vector->k, ypr, degrees);
}

void loop()
{
  Watchdog.reset();
  uint8_t data_byte[3];
  fTime2 = millis();
  boolean bValidData = false;
  float qsum = 0.0;
  
  if (bno08x.wasReset()) {
    Serial.print("sensor was reset ");
    setReports(reportType, reportIntervalUs);
  }
  
  if (bno08x.getSensorEvent(&sensorValue)) {
    // in this demo only one report type will be received depending on FAST_MODE define (above)
    switch (sensorValue.sensorId) {
      case SH2_ARVR_STABILIZED_RV:
        quaternionToEulerRV(&sensorValue.un.arvrStabilizedRV, &ypr, false);
        //quaternionToEulerRV(&sensorValue.un.gameRotationVector, &ypr, false);
      case SH2_GYRO_INTEGRATED_RV:
        // faster (more noise?)
        quaternionToEulerGI(&sensorValue.un.gyroIntegratedRV, &ypr, false);
      case SH2_GAME_ROTATION_VECTOR:
        quaternionToEulerGRV(&sensorValue.un.gameRotationVector, &ypr, false);
        qsum = sq(sensorValue.un.gameRotationVector.real)+sq(sensorValue.un.gameRotationVector.i)+sq(sensorValue.un.gameRotationVector.j)+sq(sensorValue.un.gameRotationVector.k);
        Serial.println(qsum);
        if (qsum<1.015){
          if (qsum>0.985){
            bValidData = true;            
          }
        }
        if (!bValidData){
          Serial.println(qsum);
        }
      break;
    }
    static long last = 0;
    long now = micros();
    Serial.print(now - last);             Serial.print("\t");
    last = now;

    uint16_t eulerX_int = ypr.roll*100;
    uint16_t eulerZ_int = ypr.yaw*1000; // more precise
    uint32_t data = uint32_t(eulerX_int*pow(2,13)+eulerZ_int);
    memcpy(data_byte, &data, sizeof(data));
    if (bValidData){
      bleuart.write(data_byte,3);
    }
    
    Serial.print(sensorValue.status);     Serial.print("\t");  // This is accuracy in the range of 0 to 3
    Serial.print(ypr.yaw);                Serial.print("\t");
    Serial.print(ypr.pitch);              Serial.print("\t");
    Serial.print(ypr.roll);               Serial.print("\t");
    Serial.print(qsum);                   Serial.print("\t");
    Serial.println(bValidData);
  }
}

inline float wrapAngle(float angle)
{
  float twoPi = 2.0 * 3.141592865;
  return angle - twoPi * floor( angle / twoPi );
}
