#include "SparkFun_BNO080_Arduino_Library.h"
#include <Wire.h>
#include <bluefruit.h>
#include <avr/dtostrf.h>
#include <Adafruit_SleepyDog.h>

BNO080 myIMU;


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

#define BATTERY_STATUS_DELAY 10000
#define lmillis() ((long)millis())
long lastAction;
int analogPin = A0;
int value;
float voltage;
int perc;
float perctp;

void setup()
{
  Serial.begin(115200);
  delay(1000);
  Serial.println("Serial starts");
  delay(1000);
  Wire.begin();
  delay(1000);
  Serial.println("Wire starts");
  delay(1000);

  lastAction = lmillis() + BATTERY_STATUS_DELAY;
  analogReference(AR_INTERNAL_3_0);
  analogReadResolution(10);
  value = analogRead(analogPin);
  // double voltage value due to voltage divider
  voltage = 2 * (float)value * 3.0/1024.0;
  perctp = (100.0-0.0)/(4.2-3.6)*(voltage-3.6);
  ///perctp = -180.945*pow(voltage,2)+1590.773*voltage-3391.5;
  perc = (int)constrain(perctp, 0, 100);
  Serial.println("Analog A0:");
  Serial.println(value);
  Serial.println(voltage);
  Serial.println(perctp);
  Serial.println(perc);

  // start watchdog
  int countdownMS = Watchdog.enable(2000);
 
  // connect to IMU
  Serial.println("Try to connect to IMU");
  myIMU.begin();
  delay(1000);
  Serial.println("myIMU starts");
  // configure IMU
  Wire.setClock(400000);                            // Increase I2C data rate to 400kHz
  myIMU.enableGameRotationVector(5);                // Send data update every 5ms
  gyroService.begin();;
  gyroCharact.begin();

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
  Bluefruit.setName("HT_BNO085");
  Bluefruit.Periph.setConnectCallback(connect_callback);
  Bluefruit.Periph.setDisconnectCallback(disconnect_callback);

  // Configure and Start Device Information Service
  bledis.setManufacturer("Adafruit Industries");
  bledis.setModel("Bluefruit Feather52");
  bledis.begin();

  // Configure and Start BLE Uart Service
  bleuart.begin();

  // Start BLE Battery Service
  blebas.begin();
  blebas.write(perc);

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

void loop()
{
  Watchdog.reset();
  uint8_t data_byte[4];
  fTime2 = millis();
    
  if (myIMU.dataAvailable() == true)
  {
    Serial.println("data available");
    float eulerX, eulerY, eulerZ;
    CalcEuler(&eulerX, &eulerY, &eulerZ);
    //PrintEuler(eulerX,eulerY,eulerZ);
    uint16_t eulerX_int = eulerX*100;
    uint16_t eulerZ_int = eulerZ*1000;
    uint32_t data = uint32_t(eulerX_int*pow(2,13)+eulerZ_int);
    memcpy(data_byte, &data, sizeof(data));
    //Serial.println(fTime2-fTime1); // commented for speed issues
    bleuart.write(data_byte,3);
    fTime1 = fTime2;
  }
  if (lmillis() - lastAction >=0 ) {
    lastAction = lmillis() + BATTERY_STATUS_DELAY;
    value = analogRead(analogPin);
    // double voltage value due to voltage divider
    voltage = 2 * value * 3.0/1024.0;
    perctp = -180.945*pow(voltage,2)+1590.773*voltage-3391.5;
    //perctp = (100.0-0.0)/(4.2-3.6)*(voltage-3.6);
    perc = (int)constrain(perctp, 0, 100);
    blebas.write(perc);
  }
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

/**
   Software Timer callback is invoked via a built-in FreeRTOS thread with
   minimal stack size. Therefore it should be as simple as possible. If
   a periodically heavy task is needed, please use Scheduler.startLoop() to
   create a dedicated task for it.

   More information http://www.freertos.org/RTOS-software-timer.html
*/
void blink_timer_callback(TimerHandle_t xTimerID)
{
  (void) xTimerID;
  digitalToggle(LED_RED);
}

/**
   RTOS Idle callback is automatically invoked by FreeRTOS
   when there are no active threads. E.g when loop() calls delay() and
   there is no bluetooth or hw event. This is the ideal place to handle
   background data.

   NOTE: FreeRTOS is configured as tickless idle mode. After this callback
   is executed, if there is time, freeRTOS kernel will go into low power mode.
   Therefore waitForEvent() should not be called in this callback.
   http://www.freertos.org/low-power-tickless-rtos.html

   WARNING: This function MUST NOT call any blocking FreeRTOS API
   such as delay(), xSemaphoreTake() etc ... for more information
   http://www.freertos.org/a00016.html
*/
void rtos_idle_callback(void)
{
  // Don't call any other FreeRTOS blocking API()
  // Perform background task(s) here
}
void CalcEuler(float *eulerX, float *eulerY, float *eulerZ)
{
  float quatI = myIMU.getQuatI();
  float quatJ = myIMU.getQuatJ();
  float quatK = myIMU.getQuatK();
  float quatReal = myIMU.getQuatReal();

  float sqx = quatI * quatI;
  float sqy = quatJ * quatJ;
  float sqz = quatK * quatK;
  *eulerX = atan2(2 * quatI * quatReal + 2 * quatJ * quatK , 1 - 2 * sqx - 2 * sqy);
  *eulerX = wrapAngle(*eulerX);
  *eulerY = asin(2 * quatJ * quatReal - 2 * quatI * quatK);
  *eulerY = wrapAngle(*eulerY);
  *eulerZ = atan2(2 * quatK * quatReal + 2 * quatI * quatJ , 1 - 2 * sqy - 2 * sqz);
  *eulerZ = wrapAngle(*eulerZ);
}
inline float wrapAngle(float angle)
{
  float twoPi = 2.0 * 3.141592865;
  return angle - twoPi * floor( angle / twoPi );
}
/* Function which prints euler angles into serial port
   ---------------------------------------------------
*/
void PrintEuler(float eulerX, float eulerY, float eulerZ)
{
  Serial.print(eulerX, 3);
  Serial.print(F("x"));
  Serial.print(eulerY, 3);
  Serial.print(F("y"));
  Serial.print(eulerZ, 3);
  Serial.print(F("z"));
  Serial.println();
}
/* Function which prints euler angles into serial port
   ---------------------------------------------------
*/
void PrintEulerDegree(float eulerX, float eulerY, float eulerZ)
{
  Serial.print(180 / 3.14159265359 * eulerX, 2);
  Serial.print(F("x"));
  Serial.print(180 / 3.14159265359 * eulerY, 2);
  Serial.print(F("y"));
  Serial.print(180 / 3.14159265359 * eulerZ, 2);
  Serial.print(F("z"));
  Serial.println();
}
/* Function which prints quaternions into serial port
   --------------------------------------------------
*/
void PrintQuat(float quatI, float quatJ, float quatK, float quatReal, float quatRadianAccuracy)
{
  Serial.print(quatI, 2);
  Serial.print(F(","));
  Serial.print(quatJ, 2);
  Serial.print(F(","));
  Serial.print(quatK, 2);
  Serial.print(F(","));
  Serial.print(quatReal, 2);
  Serial.print(F(","));
  Serial.print(quatRadianAccuracy, 2);
  Serial.print(F(","));
  Serial.println();
}
