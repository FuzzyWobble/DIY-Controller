//DIY Controller 
//fuzzywobble.com

//libraries
#include <Wire.h>


// EDIT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //

//DEBUG 
//enable if you want to test your output in the serial monitor
boolean enableDebug = 0;  // 1 for enable, 0 for disable. **Remember to disable debug when running MIDI**. 

//I2C 
//enable for module->module communication
boolean enableI2C = 0; // 1 for enable, 0 for disable **DO NOT enable I2C if this is the master module**. 
//If this is the master module then masterAddress must equal this Address
//If thisAddress is equal to masterAddress the program will assume this is the master module
//If you are only using one module ENSURE thisAddress is not equal to masterAddress
boolean thisAddress = 1; //each module should have a unique address
boolean masterAddress = 0; //address of the master module

//CHANNEL
int channelNumber = 1; //each module should have a unique channel number between 1 and 125 (126 & 127 are used by the encoders).

//PUSHBUTTON 
//enter '1' for a pin which a pushbutton is connected 
//enter '0' for a pin which a pushbutton is not connected 
//pins with '9' are those which are encoders and should not be used as pushbuttons unless necessary
//do NOT include the SHIFT button here
int toReadPushButton[38] = 
{           //Pin number are written below
9,9,9,9,0,  //0-4
0,9,1,1,1,  //5-9
0,0,0,0,0,  //10-14
0,0,0,9,9,  //15-19
1,1,1,1,1,  //20-24
1,1,0,0,0,  //25-29
0,0,0,0,0,  //30-34
0,9,9       //35-37
}; 
//pushbutton mode
//there are a few different modes in which you may wish for your pushbutton to behave
//'1' - standard mode - when pushbutton is engaged note is turned on, when pushbutton is released, note is turned off
//'2' - on mode - note is only turned on with each click
//'3' - off mode - note is only turned off with each click
//'4' - toggle mode - note is switched between on and off with each click
//pins with '9' are those which are encoders and should not be used as pushbuttons unless necessary
int pushbuttonMode[76] = 
{           //Pin number are written below
9,9,9,9,1,  //0-4
1,9,1,1,1,  //5-9
1,1,1,1,1,  //10-14
1,1,1,9,9,  //15-19
1,1,1,1,1,  //20-24
1,1,1,1,1,  //25-29
1,1,1,1,1,  //30-34
1,9,9,      //35-37
9,9,9,9,0,  //38-42 SHIFT
0,9,1,1,1,  //43-47 SHIFT
1,1,1,1,1,  //48-52 SHIFT
1,1,1,9,9,  //53-57 SHIFT
1,1,1,1,1,  //58-62 SHIFT
1,1,1,1,1,  //63-67 SHIFT
1,1,1,1,1,  //68-72 SHIFT
1,9,9       //73-75 SHIFT
}; 
int pbBounce = 150; //150 millisecond debounce duration - you may want to change this value depending on your pushbuttons

//SHIFT
int shiftPin = 5; //if using a shift button enter the pin number here, else put 0

//LEDs
//'1' for pins which have LEDs hooked up to them, else '0'
int toDisplayLED[38] = 
{           //Pin number are written below
9,9,9,9,0,  //0-4
0,9,0,0,0,  //5-9
1,1,1,1,0,  //10-14
0,0,0,9,9,  //15-19
0,0,0,0,0,  //20-24
0,0,0,0,0,  //25-29
0,0,0,0,0,  //30-34
0,9,9       //35-37
}; 

//ROTARY ENCODER
//'1' for encoders which are in use, else '0'
int toReadEncoder[4] = {
0, //1: pins 0,1 / interrupt 0,1
1, //2: pins 2,3 / interrupt 2,3
0, //3: pins 36,37 / interrupt 4,5
1  //4: pins 18,19 / interrupt 6,7
}; 

//ANALOG IN MUX
//CD4067BE - http://www.ti.com/lit/ds/symlink/cd4067b.pdf
//'1' for multiplexer inputs you want to read, else enter '0'
int toReadMux[16] = 
{        //IC pin number are written below 
0,0,0,0, //0-3
0,0,0,0, //4-7
0,0,0,0, //8-11
0,0,0,0  //12-15
}; 

//ANALOG IN (Teensy)
//directly from Teensy analog pins
//enter '1' for analog inputs which are in use, else enter '0'
int toReadAnalogTeensy[8] = {
1,1,1,1,
0,0,0,0
}; 





// VARIABLES AND FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
//PUSHBUTTONS
long timeHit[76]; //38*2 = 76 (shift button)
boolean buttonState[76]; //stored state: if the button was last turned on or off
int shiftChange;
//ENCODER
int engagedEnc[4] = {0,0,0,0}; 
int p1_state[4] = {0,0,0,0}; //previous state
int encoderPins[4][2] = {{0,1},{2,3},{36,37},{18,19}}; //encoder pin numbers
int8_t enc_states[] = 
{
  0,-1,1,0,1,0,0,-1,-1,0,0,1,0,1,-1,0 //16
};
//interrupt functions
void intFunc1(void){
  engagedEnc[0] = 1;
}  
void intFunc2(void){
  engagedEnc[1] = 1;
}  
void intFunc3(void){
  engagedEnc[2] = 1;
}  
void intFunc4(void){
  engagedEnc[3] = 1;
}  
//function to read encoder
int readEncoder(int encNum)
{
  p1_state[encNum] <<= 2; //remember previous state
  p1_state[encNum] |= (digitalRead(encoderPins[encNum][0]) << 1) | digitalRead(encoderPins[encNum][1]);
  p1_state[encNum] &= 0x0f;
  return enc_states[p1_state[encNum]];
}
//ANALOG IN
int s0 = 14; //control pin A
int s1 = 15; //control pin B
int s2 = 16; //control pin C
int s3 = 17; //control pin D
int SIG_pin = 45; //read pin
int analogInsPrev[16]; //array to hold previously read analog values - set all to zero for now
int tempAnalogIn = 0; //array to hold previously read analog values 
int tempAnalogInMap = 0;
int analogThreshold = 4; //threshold
int controlPin[] = {s0, s1, s2, s3}; //set contol pins in array
//control array 
int muxChannel[16][4]={ 
  {0,0,0,0}, //channel 0
  {1,0,0,0}, //channel 1
  {0,1,0,0}, //channel 2
  {1,1,0,0}, //channel 3
  {0,0,1,0}, //channel 4
  {1,0,1,0}, //channel 5
  {0,1,1,0}, //channel 6
  {1,1,1,0}, //channel 7
  {0,0,0,1}, //channel 8
  {1,0,0,1}, //channel 9
  {0,1,0,1}, //channel 10
  {1,1,0,1}, //channel 11
  {0,0,1,1}, //channel 12
  {1,0,1,1}, //channel 13
  {0,1,1,1}, //channel 14
  {1,1,1,1}  //channel 15
};
//function to read mux
int readMux(int channel){  
  //loop through the four control pins
  for(int i = 0; i < 4; i ++){ 
    //turn on/off the appropriate control pins according to what channel we are trying to read 
    digitalWrite(controlPin[i], muxChannel[channel][i]); 
  }
  //read the value of the pin
  int val = analogRead(SIG_pin); 
  //return the value
  return val; 
}
int analogPinsTeensy[8] = {38,38,40,41,42,43,44,45};
int analogInsPrevTeensy[8]; //array to hold previously read analog values 
int tempAnalogInTeensy = 0; 
int tempAnalogInMapTeensy = 0;
int analogThresholdTeensy = 4; //threshold




// SETUP (pin config) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
void setup(){ 

  //DEBUG
  if(enableDebug==1){
  Serial.begin(9600);//open serail port @ debug speed
  }
  else{
  Serial.begin(31250);//open serail port @ midi speed
  }
  
  //I2C
  if(thisAddress==masterAddress){
  delay(150*channelNumber);  
  Wire.begin(thisAddress);  
  Wire.onReceive(receiveEvent); 
  }
  else if(enableI2C==1){
  delay(200*channelNumber); //if we start the address for all the modules at the same time there will be a communication crash (i think). lets add a delay just to be sure. 
  Wire.begin(thisAddress); //start I2C
  }
  else{
  //do nothing  
  }
  
  //PUSHBUTTON pin config
  //we need enable each pushbutton pin as an INPUT as well as turn on the pullup resistor 
  for(int i=0;i<38;i++){
    if(toReadPushButton[i]==1){
    pinMode(i,INPUT_PULLUP); //pushbutton pullup
    }  
  }
  
  //LED pin config
  //we need enable each LED pin as an OUTPUT
  for(int i=0;i<38;i++){
    if(toDisplayLED[i]==1){
    pinMode(i,OUTPUT); //pushbutton pullup
    }  
  }   
 
  //SHIFT pin config
  //we need enable the shift pin as an INPUT as well as turn on the pullup resistor 
  if(shiftPin!=0){
  pinMode(shiftPin,INPUT_PULLUP); //shift button  
  }

  //ENCODER pin config
  //we need to enable each encoder pin as INPUT
  for(int i=0;i<4;i++){
      if(toReadEncoder[i]==1){  
      pinMode(encoderPins[i][0],INPUT);
      digitalWrite(encoderPins[i][0],HIGH);
      pinMode(encoderPins[i][1],INPUT);
      digitalWrite(encoderPins[i][1],HIGH);
      }
  }
  attachInterrupt(0,intFunc1,CHANGE); //add interrupt function to interrupt 0
  attachInterrupt(1,intFunc1,CHANGE); //add interrupt function to interrupt 1
  attachInterrupt(2,intFunc2,CHANGE); 
  attachInterrupt(3,intFunc2,CHANGE); 
  attachInterrupt(4,intFunc3,CHANGE); 
  attachInterrupt(5,intFunc3,CHANGE); 
  attachInterrupt(6,intFunc4,CHANGE); 
  attachInterrupt(7,intFunc4,CHANGE); 
  
  //ANALOG IN MUX pin config
  //set analog in reading
  pinMode(SIG_pin,INPUT);
  //set our control pins to output
  pinMode(s0,OUTPUT);
  pinMode(s1,OUTPUT);
  pinMode(s2,OUTPUT);
  pinMode(s3,OUTPUT); 
  //turn all control pins off (for now)
  digitalWrite(s0,LOW);
  digitalWrite(s1,LOW);
  digitalWrite(s2,LOW);
  digitalWrite(s3,LOW);
  
}




// LOOPS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
void loop(){
  
  //SHIFT loop
  if(shiftPin!=0){
    if(digitalRead(shiftPin)==LOW){ //check if shift button was engaged
    shiftChange = 38;  //if enganged, the offset is 38
    }
    else{
    shiftChange = 0;  
    }
  }
  
  //PUSHBUTTONS loop
  boolean tempDigitalRead;
  for(int i=0;i<38;i++){ //loop through all 38 digital pins
  int j = i + shiftChange; //add the shift change
    if(toReadPushButton[i]==1){ //check if this a pin with a pushbutton hooked up to it
    tempDigitalRead = digitalRead(i);
      if(pushbuttonMode[j]==1){ //normal mode
        if(tempDigitalRead!=buttonState[j]){ //something has changed
        delay(2); //just a delay for noise to ensure push button was actually hit
          if(digitalRead(i)==tempDigitalRead){ //check if pushbutton is still the same
            if(tempDigitalRead==LOW){ //button pressed, turn note on
            midiNoteOnOff(1,j); //call note on/off function
            }
            else{ //button released
            midiNoteOnOff(0,j);
            }
          buttonState[j] = tempDigitalRead; //update the state (on or off)           
          }
        }
      }
      else{ //all other modes (2,3,4)
        if(digitalRead(i)==LOW){ //button was pressed
          if((millis()-timeHit[j])>pbBounce){ //check bounce time  
            if(pushbuttonMode[j]==2){ //mode 2 - only note on
            midiNoteOnOff(1,j); 
            }
            else if(pushbuttonMode[j]==3){ //mode 3 - only note off
            midiNoteOnOff(0,j);          
            }
            else{ //mode 4 - toggle
              if(buttonState[j]==1){
              midiNoteOnOff(0,j);
              buttonState[j]=0;  
              }
              else{
              midiNoteOnOff(1,j);
              buttonState[j]=1;  
              }
            }
          timeHit[j] = millis();
          }
        }
      }   
    }
  }
  
  //ENCODER loop
  for(int i=0;i<4;i++){
    if(toReadEncoder[i]==1){
      if(engagedEnc[i]==1){
        //Reset our flag
        engagedEnc[i] = 0;
        // Act on the encoder value   
        switch(readEncoder(i)){
        case -1:
          //Send encoder messages -1
          if(enableDebug==1){ //SERIAL debug is on
            serialDebugOut("Encoder",i,"fwd >>");
          }
          else if(enableI2C==1){ //I2C
            serialI2COut('e',i,127,127);
          }
          else{ //MIDI
            usbMIDI.sendNoteOn(i,127,127);   
          }
          break;
        case 0:
          break;
        case 1:
          //Send encoder messages +1
          if(enableDebug==1){ //SERIAL debug is on
            serialDebugOut("Encoder",i,"<< bck");
          }
          else if(enableI2C==1){ //I2C
            serialI2COut('e',i,127,126);
          }
          else{ //MIDI
            usbMIDI.sendNoteOn(i,127,126);   
          }
          break;
        }
      }
    }
  } 
 
 
  //ANALOG IN MUX loop
  for(int i=0;i<16;i++){ //loop through 16 mux channels
    if(toReadMux[i]==1){ //check if this a pin with a analog input hooked up to it
      tempAnalogIn = readMux(i); //ready valued using readMux function
      if(abs(analogInsPrev[i]-tempAnalogIn)>analogThreshold){ //ensure value changed more than our threshold
      tempAnalogInMap = map(tempAnalogIn,0,1023,0,127); //remap value between 0 and 127
      
        //Send analog messages 
        if(enableDebug==1){ //SERIAL debug is on
          serialDebugOut("Analog",i,tempAnalogInMap);
        }
        else if(enableI2C==1){ //I2C
          serialI2COut('a',i,tempAnalogInMap,channelNumber);
        }
        else{ //MIDI
          usbMIDI.sendControlChange(i,tempAnalogInMap,channelNumber);   
        }
        
        analogInsPrev[i]=tempAnalogIn; //reset current value
      }
    }    
  } 
  
  
  //ANALOG IN TEENSY loop  
  for(int i=0;i<8;i++){ //loop through the 8 analog teensy channels
    if(toReadAnalogTeensy[i]==1){ //read if plugged in
      tempAnalogInTeensy = analogRead(analogPinsTeensy[i]);
      if(abs(analogInsPrevTeensy[i]-tempAnalogInTeensy)>analogThresholdTeensy){
      tempAnalogInMapTeensy = map(tempAnalogInTeensy,0,1023,0,127);
        
        //Send analog messages 
        if(enableDebug==1){ //SERIAL debug is on
          serialDebugOut("Analog",i,tempAnalogInMapTeensy);
        }
        else if(enableI2C==1){ //I2C
          serialI2COut('a',i,tempAnalogInMapTeensy,0x01);
        }
        else{ //MIDI
          usbMIDI.sendControlChange(i,tempAnalogInMapTeensy,channelNumber);   
        }
        
      analogInsPrevTeensy[i]=tempAnalogInTeensy; 
      }
    }    
  }
  
  
  //LED loop
  //you must write your own LED code
  //this is just a sample
  if(digitalRead(20)==LOW){
    digitalWrite(10, HIGH);  
  }
  else{
    digitalWrite(10, LOW);  
  }
  if(digitalRead(21)==LOW){
    digitalWrite(13, HIGH);  
  }
  else{
    digitalWrite(13, LOW);  
  }
  if(digitalRead(22)==LOW){
    digitalWrite(12, HIGH);  
  }
  else{
    digitalWrite(12, LOW);  
  }
  if(digitalRead(23)==LOW){
    digitalWrite(11, HIGH);  
  }
  else{
    digitalWrite(11, LOW);  
  }
}







// COMMUNICATION FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //

//I2C - module
//Ignore if this code is for master module
void serialI2COut(char type, int n, int vp, int c){ // type of message, note, velocity/pressure, channel
Wire.beginTransmission(masterAddress);
Wire.send(type);
Wire.send(n);
Wire.send(vp);
Wire.send(c);
Wire.endTransmission(); 
}

//I2C - master module
//This function is ONLY needed by the master module
//called whenever data is received via I2C
void receiveEvent(int howMany){ 
  while (Wire.available() > 0){
    char messageType = Wire.receive();
    int n = Wire.receive();
    int vp = Wire.receive();
    int c = Wire.receive();
    
    if(enableDebug==1){ //Serial debug mode
      if((messageType=='x')||(messageType=='o')){  
        serialDebugOut("(i2c) Pushbutton",n,"clk");  
      }
      else if(messageType=='p'){ 
        serialDebugOut("(i2c) Analog",n,vp);
      }
      else if(messageType=='e'){
        if(c==126){
        serialDebugOut("(i2c) Encoder",n,"fwd >>");  
        }
        else{
        serialDebugOut("(i2c) Encoder",n,"fwd >>");  
        }
      }
      else{
      //do nothing
      }      
    }
    else{ //MIDI mode
      if(messageType=='x'){ //note off
      usbMIDI.sendNoteOff(n,vp,c);   
      }
      else if((messageType=='o')||(messageType=='e')){ //both pushbutton and encoder send note-on
      usbMIDI.sendNoteOn(n,vp,c);  
      }
      else if(messageType=='p'){ //potentiometer control change
      usbMIDI.sendControlChange(n,vp,c);  
      }
      else{
      //do nothing  
      }
    }
  }
}

//debug out
void serialDebugOut(String cType, int cNum, String cVal){
  Serial.print(cType);
  Serial.print(cNum);
  Serial.print(": ");
  Serial.println(cVal);    
}

//function to send note on/off
//this helps to keep the code concise 
void midiNoteOnOff(boolean onoff, int q){
    if(onoff==1){//note on
        if(enableDebug==1){ //SERIAL debug is on
        serialDebugOut("Pushbutton",q,"clk on");
        }
        else if(enableI2C==1){ //I2C
        serialI2COut('o',q,127,channelNumber);
        }
        else{ //MIDI
        usbMIDI.sendNoteOn(q,127,channelNumber); 
        }    
    }
    else{ //note off
        if(enableDebug==1){ //SERIAL debug is on
        serialDebugOut("Pushbutton",q,"clk off");
        }
        else if(enableI2C==1){ //I2C
        serialI2COut('x',q,127,channelNumber);
        }
        else{ //MIDI
        usbMIDI.sendNoteOff(q,127,channelNumber); 
        }     
    }
}

