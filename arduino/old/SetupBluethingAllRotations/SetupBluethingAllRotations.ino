// For BNO055
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BNO055.h>
#include <utility/imumaths.h>

//Initialisieren der Softserial-Schnittstelle
#include <SoftwareSerial.h> // Einbinden der Bibliothek für Software-UART
SoftwareSerial HC05(12, 11); // Pin 11 und 12 für die Software-UART

//Adafruit_BNO055 bno     = Adafruit_BNO055(55);
Adafruit_BNO055 bno     = Adafruit_BNO055(0X0C);

char status_char[40]    = "";
String status_string    = "";
boolean bConnected      = 1;
boolean bCalibrated     = 0;

void setup() {
  pinMode(13, OUTPUT); // Pin13 als Ausgang setzen

  Serial.begin(38400);  //Baudrate für die Kommunikation mit dem seriellen Monitor
  //HC05.begin(115200);
  HC05.begin(38400);    // Initialisieren mit 38400 Baud

  // HC-05 auf Default-Werte setzen -> Slave mode, Baudrate 38400, Passwort:1234, Device-Name: "hc01.com HC-05"
  HC05.println("AT+ORGL"); delay(500);

  // Lösche alle Devices aus der Pair-Liste
  HC05.println("AT+RMAAD"); delay(500);

  // Setze Name
  HC05.println("AT+NAME:ht1"); delay(500);

  // Setze Pin auf 0000
  HC05.println("AT+PSWD=0000"); delay(500);

  // Setze Baudrate auf 115200
  HC05.println("AT+UART=115200,0,0"); delay(500);

  // Modul neustarten und eventuelle Verbindungen resetten
  HC05.println("AT+RESET"); delay(1000);

  // SPP Profile Lib initialisieren und disconnecten
  HC05.println("AT+INIT"); delay(500);
  HC05.println("AT+DISC"); delay(500);

  digitalWrite(13, HIGH);

//  while (bConnected != 0) {
//    status_string = auslesen("AT+STATE?");
//    status_string.toCharArray(status_char, 30);
//    Serial.print(status_char);
//    bConnected = strncmp(status_char, "", 11);
//  }
  Serial.print("Connected to device");
  digitalWrite(13, 0);

  if (!bno.begin())
  {
    Serial.print("BNO055 could not be detected. Check i2c connection");
  }
  delay(1000);
  while (!bCalibrated) {
    bCalibrated = IsCalibrated();
  }
  
  bno.setExtCrystalUse(true);
}
// main loop
void loop() {
  displayCalStatus();
  sensors_event_t event;
  bno.getEvent(&event);
  imu::Quaternion quat = bno.getQuat();
  HC05.print(180 / 3.1415933 * quat.toEuler().x(), 4);
  HC05.print('x');
  HC05.print(-180 / 3.1415933 * quat.toEuler().z(), 4);
  HC05.print('z');
  HC05.print(180 / 3.1415933 * quat.toEuler().y(), 4);
  HC05.print('y');
  Serial.print(180 / 3.1415933 * quat.toEuler().x(), 4);
  Serial.print('x');
  Serial.print(-180 / 3.1415933 * quat.toEuler().z(), 4);
  Serial.print('z');
  Serial.print(180 / 3.1415933 * quat.toEuler().y(), 4);
  Serial.print('y');
  delay(1);
}

String auslesen(String Befehl) {
  char Zeichen;                             // Jedes empfangene Zeichen kommt kurzzeitig in diese Variable.
  String result = "";
  //Serial.println(Befehl);                 // Schreibe den übergebenen String auf den seriellen Monitor
  HC05.println(Befehl);                     // Sende den übergebenen String an das Modul
  delay(1000);
  while (HC05.available() > 0) {            // So lange etwas empfangen wird, durchlaufe die Schleife.
    Zeichen = HC05.read();                  // Speichere das empfangene Zeichen in der Variablen "Zeichen".
    result.concat(Zeichen);                 // Speichere die Antwort des Moduls
  }
  return result;                            // Übergebe die Rückantwort des Moduls
}

/**************************************************************************/
/*
    Display sensor calibration status
*/
/**************************************************************************/
void displayCalStatus(void)
{
  /* Get the four calibration values (0..3) */
  /* Any sensor data reporting 0 should be ignored, */
  /* 3 means 'fully calibrated" */
  uint8_t system, gyro, accel, mag;
  system = gyro = accel = mag = 0;
  bno.getCalibration(&system, &gyro, &accel, &mag);

  /* The data should be ignored until the system calibration is > 0 */
  Serial.print("\t");
  if (!system)
  {
    Serial.print("! ");
  }

  /* Display the individual values */
  Serial.print("Sys:");
  Serial.print(system, DEC);
  Serial.print(" G:");
  Serial.print(gyro, DEC);
  Serial.print(" A:");
  Serial.print(accel, DEC);
  Serial.print(" M:");
  Serial.println(mag, DEC);
}

boolean IsCalibrated(void)
{
  /* Get the four calibration values (0..3) */
  /* Any sensor data reporting 0 should be ignored, */
  /* 3 means 'fully calibrated" */
  bCalibrated = 0;
  uint8_t system, gyro, accel, mag;
  system = gyro = accel = mag = 0;
  bno.getCalibration(&system, &gyro, &accel, &mag);
  bCalibrated = (system>2 && gyro>2 && mag>2 &&accel>0);
  displayCalStatus();
  return bCalibrated;
}
