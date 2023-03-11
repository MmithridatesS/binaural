#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BNO055.h>
#include <utility/imumaths.h>

Adafruit_BNO055 bno = Adafruit_BNO055(55);

void setup() {
  // initialize serial connection, set baud rate
  Serial.begin(38400);
  //Serial.begin(115200);
  if(!bno.begin())
  {
    Serial.print("BNO055 could not be detected. Check i2c connection");
  }
  delay(1000);
  bno.setExtCrystalUse(true);  
}

void loop() {
//  char Received = 0;
  sensors_event_t event;
  bno.getEvent(&event);
  Serial.print(event.orientation.x,4);
  Serial.print('x');
  Serial.print(event.orientation.z,4);
  Serial.print('z');
//  Serial.print(event.orientation.z,4);
//  Serial.print('y');
  delay(2); // for baudrate=115200 
//  Serial.print("X: ");
//  Serial.print(event.orientation.x, 4);
//  Serial.print("\tY: ");
//  Serial.print(event.orientation.y, 4);
//  Serial.print("\tZ: ");
//  Serial.print(event.orientation.z, 4);
//  Serial.println("");
  
}
