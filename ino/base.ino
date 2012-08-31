/*
 * PIN LAYOUT A1120 UA PACKAGE
 * 1 - VCC 5V
 * 2 - GND
 * 3 - SIGNAL
 * 1 is from the left looking at the branded face
 */
 
#define hallPinA 2
#define hallPinB 3
#define FanPin 5
#define OikosPin1 6
#define OikosPin2 7

int incomingByte = 0;

 int statusA = false;
 int statusB = false;
 int direzione = 0; //0 = orario, 1 = antiorario
 int led = 13;
 
 void setup()
 {
   Serial.begin(9600);
   digitalWrite(hallPinA, HIGH);
   digitalWrite(hallPinB, HIGH);
   attachInterrupt(0, doHallA, RISING);
   attachInterrupt(1, doHallB, RISING);
   pinMode(led, OUTPUT);
   
   pinMode(FanPin, OUTPUT);
   pinMode(OikosPin1, OUTPUT);
   pinMode(OikosPin2, OUTPUT);
 }
 
 void loop() {
   if (Serial.available() > 0) {
     incomingByte = Serial.read();
     switch (incomingByte) {
       case 49:
         digitalWrite(FanPin, HIGH);
         break;
       case 50:
         digitalWrite(FanPin, LOW);
         break;
       case 51:
         digitalWrite(OikosPin1, HIGH);
         break;
       case 52:
         digitalWrite(OikosPin1, LOW);
         break;
       case 53:
         digitalWrite(OikosPin2, HIGH);
         break;
       case 54:
         digitalWrite(OikosPin2, LOW);
         break;
     }
   }
 }
 
 void doHallA() {
   if (statusA == false) {
     statusA = true;
   }
   //Serial.println("A triggered");
   //Serial.println(statusA);
   doRPM();
 }
 
 void doHallB() {
   if (statusB == false) {
     statusB = true;
   }
   //Serial.println("B triggered");
   //Serial.println(statusB);
   doRPM();
 }
 
 void doRPM()
 {
   //Serial.print(statusA);
   //Serial.print(statusB);
   //Serial.println(triggers);
   digitalWrite(led, HIGH);
   delay(50);
   digitalWrite(led, LOW);
   if (statusA == true && statusB == true) {
     if (direzione == 0) {
       Serial.print("B"); 
     } else {
       Serial.print("F");
     }
     statusA = false;
     statusB = false;
   }
   if (statusA == true && statusB == false) {
     direzione = 1;
   }
   if (statusA == false && statusB == true) {
     direzione = 0;
   }
 }
