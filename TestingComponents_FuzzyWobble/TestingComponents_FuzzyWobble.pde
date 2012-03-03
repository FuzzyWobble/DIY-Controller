//fuzzywobble.com

//PUSHBUTTONS
//pin assignment below
int pb_pin_encoder = 26; //the encoder pushbutton is hooked up to pin 26 on the Teensy++
int pb_pin_a = 25;
int pb_pin_b = 24;
int pb_pin_c = 23;

//POTENTIOMETER 
//potentiomer variables defined below
int analogReadVal_a = 0; 
int analogReadVal_b = 0;
int analogReadPrev_a = 0;
int analogReadPrev_b = 0;
//pin assignment below 
int analog_pin_a = 0; //potentiometer is hooked up to pin analog 0 (f0) on the Teensy++
int analog_pin_b = 1;

//LED
//pin assignment below
int led_pin = 16; //led is hooked up to digital PWM pin 16 on the Teensy++

//ENCODER
//variables defined below
int pressed1 = 0; 
int p1_state = 0; 
//pin assignment below
int encoder_pin_a = 2;
int encoder_pin_b = 3; 




void setup(){
  
  //begin serial communication at 9600bps 
  //this allows the arduino to talk to the computer (serial monitor)
  Serial.begin(9600);
  
  //PUSHBUTTONS
  //declare that pushbutton pins are inputs and turn on pullup resistor
  pinMode(pb_pin_encoder, INPUT_PULLUP);
  pinMode(pb_pin_a, INPUT_PULLUP);
  pinMode(pb_pin_b, INPUT_PULLUP);
  pinMode(pb_pin_c, INPUT_PULLUP);
  
  //ENCODER
  //turn on encoder pins
  pinMode(encoder_pin_a, INPUT);
  digitalWrite(encoder_pin_a, HIGH);
  pinMode(encoder_pin_b, INPUT);
  digitalWrite(encoder_pin_b, HIGH);
  //add special function (intFunc1) to encoder pins
  //whenever something changes on these pins they call the function intFunc1
  //interrupt pins 2 and 3 are used. (Teensy++ has eight total interrupt pins)
  attachInterrupt(2, intFunc1, CHANGE); 
  attachInterrupt(3, intFunc1, CHANGE);
  
}





void loop(){ //this loops over and over and over forever while the Teensy++ is powered
 
   //PUSHBUTTON 
   if(digitalRead(pb_pin_encoder)==LOW){ //pushbutton 26 (enocder) was clicked
   Serial.println("button 26 pressed"); //write to the serial monitor 
   delay(250); //delay 250 milliseconds
   } 
   if(digitalRead(pb_pin_a)==LOW){ //pushbutton 25 was clicked
   Serial.println("button 25 pressed"); 
   analogWrite(led_pin,20); //LED at 20 PWM, this means the led will be very dim. You can write anything between 0 and 255 on the Teensy++ PWM pins.
   delay(250);
   analogWrite(led_pin,0); //turn LED off
   } 
   if(digitalRead(pb_pin_b)==LOW){
   Serial.println("button 24 pressed"); 
   analogWrite(led_pin,80); 
   delay(250);
   analogWrite(led_pin,0); 
   } 
   if(digitalRead(pb_pin_c)==LOW){
   Serial.println("button 23 pressed"); 
   analogWrite(led_pin,255); //LED at full brightness 
   delay(250);
   analogWrite(led_pin,0);
   }
   
   //POTENTIOMETER 
   analogReadVal_a = analogRead(analog_pin_a); //read analog value from analog pin 0 (F0)
   if(abs(analogReadPrev_a-analogReadVal_a)>5){ //check if analog value changed from the last reading with a (high) threshold of 5
   Serial.print("analog 1 value: ");
   Serial.println(analogReadVal_a); //write the value to the serial monitor
   analogReadPrev_a = analogReadVal_a; //reset the current value
   }
   analogReadVal_b = analogRead(analog_pin_b); //read analog value from analog pin 1 (F1)
   if(abs(analogReadPrev_b-analogReadVal_b)>5){
   Serial.print("analog 2 value: ");
   Serial.println(analogReadVal_b); 
   analogReadPrev_b = analogReadVal_b; 
   }
  
  //ENCODER 
  if(pressed1){ //encoder has been touched
    pressed1=0; //reset flag
    switch(readEncoder()){ //call out encoder function
    case -1:
     Serial.println("encoder +"); 
      break;
    case 0:
      break;
    case 1:
      Serial.println("encoder -"); 
      break;
    }
  }

}


//ENCODER FUNCTION
//dont worry if you cant understand this, it is quite confusing
//just know that it works
int8_t enc_states[] = 
{
  0,-1,1,0,1,0,0,-1,-1,0,0,1,0,1,-1,0 //16
};
int readEncoder(){
  p1_state <<= 2; //remember previous state
  p1_state |= (digitalRead(encoder_pin_a) << 1) | digitalRead(encoder_pin_b);
  p1_state &= 0x0f;
  return enc_states[p1_state];
}
void intFunc1(void){
  pressed1 = 1;
}

