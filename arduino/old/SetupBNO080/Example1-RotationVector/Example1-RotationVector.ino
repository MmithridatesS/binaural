/*
  Using the BNO080 IMU
  By: Nathan Seidle
  SparkFun Electronics
  Date: December 21st, 2017
  License: This code is public domain but you buy me a beer if you use this and we meet someday (Beerware license).
  Feel like supporting our work? Buy a board from SparkFun!
  https://www.sparkfun.com/products/14586
  This example shows how to output the i/j/k/real parts of the rotation vector.
  https://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation
  It takes about 1ms at 400kHz I2C to read a record from the sensor, but we are polling the sensor continually
  between updates from the sensor. Use the interrupt pin on the BNO080 breakout to avoid polling.
  Hardware Connections:
  Attach the Qwiic Shield to your Arduino/Photon/ESP32 or other
  Plug the sensor onto the shield
  Serial.print it out at 9600 baud to serial monitor.
*/

#include <Wire.h>

#include "SparkFun_BNO080_Arduino_Library.h"
BNO080 myIMU;

void setup()
{
  Serial.begin(115200);
  Serial.println();
  Serial.println("BNO080 Read Example");

  Wire.begin();

  if (myIMU.begin() == false)
  {
    Serial.println("BNO080 not detected at default I2C address. Check your jumpers and the hookup guide. Freezing...");
    while (1);
  }

  Wire.setClock(400000); //Increase I2C data rate to 400kHz

  myIMU.enableGameRotationVector(5); //Send data update every 10ms

  Serial.println(F("Rotation vector enabled"));
  Serial.println(F("Output in form i, j, k, real, accuracy"));
}

void loop()
{
  unsigned long time;
  unsigned long time1, time2, time3, timeNew, timeOld;
//  time = millis();
  //Look for reports from the IMU
  if (myIMU.dataAvailable() == true)
  {
    float eulerX, eulerY, eulerZ;
    time1 = millis();
    CalcEuler(&eulerX,&eulerY,&eulerZ);
    time2 = millis();    
    PrintEulerRad(eulerX,eulerY,eulerZ);
    time3 = millis();
    //PrintQuat(quatI,quatJ,quatK,quatReal,quatRadianAccuracy);
    timeNew = millis();
    Serial.println(timeNew);
  }
  //delay(1);
}
/* Function which reads quaternions and calculates euler angles
   ------------------------------------------------------------
*/

void CalcEuler(float *eulerX, float *eulerY, float *eulerZ)
{
    float test;
    float quatI = myIMU.getQuatI();
    float quatJ = myIMU.getQuatJ();
    float quatK = myIMU.getQuatK();
    float quatReal = myIMU.getQuatReal();
    float quatRadianAccuracy = myIMU.getQuatRadianAccuracy();
    test = quatI*quatJ + quatK*quatReal;
    if (test > 0.499) { // singularity at north pole
      *eulerX = 2 * atan2(quatI,quatReal);
      *eulerY = 3.14159265359/2;
      *eulerZ = 0;
      return;
    }
    if (test < -0.499) { // singularity at south pole
      *eulerX = -2 * atan2(quatI,quatReal);
      *eulerY = - 3.14159265359/2;
      *eulerZ = 0;
      return;
    }
    double sqx = quatI*quatI;
    double sqy = quatJ*quatJ;
    double sqz = quatK*quatK;
    *eulerX = atan2(2*quatI*quatReal+2*quatJ*quatK , 1 - 2*sqx - 2*sqy);
    *eulerY = asin(2*quatJ*quatReal-2*quatI*quatK);
    *eulerZ = atan2(2*quatK*quatReal+2*quatI*quatJ , 1 - 2*sqy - 2*sqz);    
}
/* Function which prints euler angles into serial port
   ---------------------------------------------------
*/
void PrintEulerGrad(float eulerX, float eulerY, float eulerZ)
{
    Serial.print(180/3.14159265359*eulerX, 2);
    Serial.print(F("x"));
    Serial.print(180/3.14159265359*eulerY, 2);
    Serial.print(F("y"));
    Serial.print(180/3.14159265359*eulerZ, 2);
    Serial.print(F("z"));
    Serial.println();
}
void PrintEulerRad(float eulerX, float eulerY, float eulerZ)
{
    Serial.print(wrapAngle(eulerX), 3);
    Serial.print(F("x"));
    Serial.print(wrapAngle(eulerY), 3);
    Serial.print(F("y"));
    Serial.print(wrapAngle(eulerZ), 3);
    Serial.print(F("z"));
    Serial.println();
}
inline float wrapAngle(float angle)
{
    float twoPi = 2.0 * 3.141592865358979;
    return angle - twoPi * floor( angle / twoPi );
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
