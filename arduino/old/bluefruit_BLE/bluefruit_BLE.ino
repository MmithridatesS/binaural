#include "SparkFun_BNO080_Arduino_Library.h"
#include <Wire.h>
#include <bluefruit.h>
#include <avr/dtostrf.h>

BNO080 myIMU;


// BLE Service
BLEDis  bledis;
BLEUart bleuart;
BLEBas  blebas;
BLEService gyroService = BLEService(0x180D);
BLECharacteristic gyroCharact = BLECharacteristic(0xABCD);

// Software Timer for blinking RED LED
SoftwareTimer blinkTimer;
int iCounter = 0;
unsigned int long fTime1 = 0;
unsigned int long fTime2;

void setup()
{
  Serial.begin(38400);
  Serial.println("Serial starts");
  Wire.begin();
  delay(1000);
  Serial.println("Wire starts");
  delay(1000);
  myIMU.begin();
  delay(1000);
  Serial.println("myIMU starts");
  //if (myIMU.begin() == false)
  //{
  //  Serial.println("BNO080 not detected at default I2C address. Check your jumpers and the hookup guide. Freezing...");
  //  while (1);
  //}
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
  Bluefruit.setName("Bluefruit52_2");
  //Bluefruit.setName(getMcuUniqueID()); // useful testing with multiple central connections
  Bluefruit.setConnectCallback(connect_callback);
  Bluefruit.setDisconnectCallback(disconnect_callback);

  // Configure and Start Device Information Service
  bledis.setManufacturer("Adafruit Industries");
  bledis.setModel("Bluefruit Feather52");
  bledis.begin();

  // Configure and Start BLE Uart Service
  bleuart.begin();

  // Start BLE Battery Service
  blebas.begin();
  blebas.write(90);

  // Set up and start advertising
  startAdv();

  Serial.println("Please use Adafruit's Bluefruit LE app to connect in UART mode");
  Serial.println("Once connected, enter character(s) that you wish to send");
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
  char buf1[50] = "";
  char buf1short[4] = ""; // leave dot out to reduce amount of data to be transmitted
  char buf2[4] = "";
  char buf2short[3] = "";
  char buf[7] = "";
  Serial.println(buf);
  fTime2 = millis();
  if (myIMU.dataAvailable() == true)
  {
    float eulerX, eulerY, eulerZ;
    CalcEuler(&eulerX, &eulerY, &eulerZ);
    PrintEuler(eulerX,eulerY,eulerZ);
    dtostrf(eulerZ, 1, 3, buf1);
    buf1short[0] = buf1[0];
    for (int iC=1;iC<4;iC++){
      buf1short[iC] = buf1[iC+1];
    }
    Serial.println("Buffer 1");
    Serial.println(buf1);
    Serial.println(buf1short);

    dtostrf(eulerX, 10, 2, buf2);
    Serial.println("Buffer 2:");
    Serial.println(buf2);
    Serial.println("Buffer 1:");
    Serial.println(buf1short);
    buf2short[0] = buf2[0];
    for (int iC=1; iC<3;iC++){
      buf2short[iC] = buf2[iC+1];
    }
    Serial.println("Buffer 2");
    Serial.println(buf2short);
    Serial.println(buf2);


    Serial.println("Copy buffer 1 into buffer");
    Serial.println(buf);
    Serial.println(buf1short);
    strcpy(buf, buf1short);
    Serial.println(buf);
    Serial.println("Copy buffer 2 into buffer");
    strcat(buf, buf2short);
    Serial.println(buf);
    //PrintEuler(eulerX,eulerY,eulerZ);
    Serial.println("Complete Buffer");
    
    Serial.println(buf);
    Serial.println(fTime2);
  }
  //bleuart.write( buf, 2 * (buf_len-1) );
  bleuart.write( buf, 7 );
}

void connect_callback(uint16_t conn_handle)
{
  char central_name[32] = { 0 };
  Bluefruit.Gap.getPeerName(conn_handle, central_name, sizeof(central_name));

  Serial.print("Connected to ");
  Serial.println(central_name);
}

void disconnect_callback(uint16_t conn_handle, uint8_t reason)
{
  (void) conn_handle;
  (void) reason;

  Serial.println();
  Serial.println("Disconnected");
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
