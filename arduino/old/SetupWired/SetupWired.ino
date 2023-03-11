#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BNO055.h>
#include <utility/imumaths.h>

boolean bCalib;
Adafruit_BNO055 bno = Adafruit_BNO055(55);
/**************************************************************************/
/*
    Arduino setup function (automatically called at startup)
*/
/**************************************************************************/
void setup(void)
{
  Serial.begin(115200);
  /* Initialise the sensor */
  if(!bno.begin())
  {
    /* There was a problem detecting the BNO055 ... check your connections */
    Serial.print("Ooops, no BNO055 detected ... Check your wiring or I2C ADDR!");
  }
  delay(1000);
  while(!bCalib){
    bCalib = IsCalibrated();
  }
  bno.setExtCrystalUse(true);
}

/**************************************************************************/
/*
    Arduino loop function, called once 'setup' is complete (your own code
    should go here)
*/
/**************************************************************************/
void loop(void)
{
  /* Get a new sensor event */
  sensors_event_t event;
  bno.getEvent(&event);
  imu::Quaternion quat = bno.getQuat();
  //Serial.print(event.orientation.x,4);
  //Serial.print(event.orientation.z,4);
  Serial.print(180/3.1415933*quat.toEuler().x(),4);
  Serial.print('x');
  Serial.print(-180/3.1415933*quat.toEuler().z(),4);
  Serial.print('z');
  delay(2);
}
boolean IsCalibrated(void)
{
  /* Get the four calibration values (0..3) */
  /* Any sensor data reporting 0 should be ignored, */
  /* 3 means 'fully calibrated" */
  boolean bCalib = 0;
  uint8_t system, gyro, accel, mag;
  system = gyro = accel = mag = 0;
  bno.getCalibration(&system, &gyro, &accel, &mag);
  bCalib = (system>0);
  return bCalib;
}
