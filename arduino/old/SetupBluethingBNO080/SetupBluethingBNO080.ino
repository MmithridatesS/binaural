#include <Wire.h>
#include "SparkFun_BNO080_Arduino_Library.h"
#include <SoftwareSerial.h> // Einbinden der Bibliothek für Software-UART
SoftwareSerial HC05(12, 11); // Pin 11 und 12 für die Software-UART
BNO080 myIMU;

char status_char[40]    = "";
String status_string    = "";
boolean bConnected      = 1;
boolean bCalibrated     = 0;

/*-------------------------------------------------------------------------------------------------------------
   SETUP
-------------------------------------------------------------------------------------------------------------*/
void setup() {
  Serial.begin(38400);                              // Baudrate für die Kommunikation mit dem seriellen Monitor
  Wire.begin();
  if (myIMU.begin() == false)
  {
    Serial.println("BNO080 not detected at default I2C address. Check your jumpers and the hookup guide. Freezing...");
    while (1);
  }
  Wire.setClock(400000);                            // Increase I2C data rate to 400kHz
  myIMU.enableGameRotationVector(5);                // Send data update every 5ms
    
  pinMode(13, OUTPUT);                              // Pin13 als Ausgang setzen

  HC05.begin(38400);                                // Initialisieren mit 38400 Baud  
  HC05.println("AT+ORGL"); delay(500);              // HC-05 auf Default-Werte setzen -> Slave mode, Baudrate 38400, Passwort:1234, Device-Name: "hc01.com HC-05"
  HC05.println("AT+RMAAD"); delay(500);             // Lösche alle Devices aus der Pair-Liste
  HC05.println("AT+NAME:ht1"); delay(500);          // Setze Name  
  HC05.println("AT+PSWD=0000"); delay(500);         // Setze Pin auf 0000  
  HC05.println("AT+UART=115200,0,0"); delay(500);   // Setze Baudrate auf 115200
  HC05.println("AT+RESET"); delay(1000);            // Modul neustarten und eventuelle Verbindungen resetten
  HC05.println("AT+INIT"); delay(500);              // SPP Profile Lib initialisieren und disconnecten
  HC05.println("AT+DISC"); delay(500);              // disconnecten

  digitalWrite(13, HIGH);

  while (bConnected != 0) {
    status_string = ReadOut("AT+STATE?");
    status_string.toCharArray(status_char, 30);
    Serial.print(status_char);
    bConnected = strncmp(status_char, "", 11);
  }
  Serial.print("Connected to device");
  digitalWrite(13, 0);

}
/*-------------------------------------------------------------------------------------------------------------
   LOOP
-------------------------------------------------------------------------------------------------------------*/
void loop() {
  if (myIMU.dataAvailable() == true)
  {
    float eulerX, eulerY, eulerZ;
    CalcEuler(&eulerX,&eulerY,&eulerZ);
    //PrintEuler(eulerX,eulerY,eulerZ);
    HC05.print(wrapAngle(eulerZ), 3);
    HC05.print('x');
    HC05.print(wrapAngle(eulerX), 3);
    HC05.print('z');
  }
}

/*-------------------------------------------------------------------------------------------------------------
   SUBROUTINES
-------------------------------------------------------------------------------------------------------------*/
String ReadOut(String Befehl) {
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
void CalcEuler(float *eulerX, float *eulerY, float *eulerZ)
{
//    float test;
    float quatI = myIMU.getQuatI();
    float quatJ = myIMU.getQuatJ();
    float quatK = myIMU.getQuatK();
    float quatReal = myIMU.getQuatReal();

    float sqx = quatI*quatI;
    float sqy = quatJ*quatJ;
    float sqz = quatK*quatK;
    *eulerX = atan2(2*quatI*quatReal+2*quatJ*quatK , 1 - 2*sqx - 2*sqy);
    *eulerY = asin(2*quatJ*quatReal-2*quatI*quatK);
    *eulerZ = atan2(2*quatK*quatReal+2*quatI*quatJ , 1 - 2*sqy - 2*sqz);    
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
    Serial.print(180/3.14159265359*eulerX, 2);
    Serial.print(F("x"));
    Serial.print(180/3.14159265359*eulerY, 2);
    Serial.print(F("y"));
    Serial.print(180/3.14159265359*eulerZ, 2);
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
