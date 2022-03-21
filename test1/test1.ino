/********************************************************************************************
* 	    	File:  LimitDetection.ino                                                         *
*		    Version:    2.3.0                                          						    *
*      	Date: 		December 27th, 2021  	                                    			*
*       Author:  Thomas Hørring Olsen                                                       *
*  Description:  Bounce Example Sketch!                                                     *
*                                                                                           *
* This example demonstrates how the library can be used to move the motor a specific angle, *
* Set the acceleration/velocity and read out the angle moved !                              *            *
*                                                                                           *
* For more information, check out the documentation:                                        * 
*                http://ustepper.com/docs/usteppers/html/index.html                         *
*                                                                                           *
*********************************************************************************************
*	(C) 2020                                                                                  *
*                                                                                           *
*	uStepper ApS                                                                              *
*	www.ustepper.com                                                                          *
*	administration@ustepper.com                                                               *
*                                                                                           *
*	The code contained in this file is released under the following open source license:      *
*                                                                                           *
*			Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International               *
*                                                                                           *
* 	The code in this file is provided without warranty of any kind - use at own risk!       *
* 	neither uStepper ApS nor the author, can be held responsible for any damage             *
* 	caused by the use of the code contained in this file !                                  *
*                                                                                           *
*                                                                                           *
********************************************************************************************/

#include <uStepperS.h>

uStepperS stepper;
float angle = 15.0;      //amount of degrees to move
float initialAngle = 0;
// define the digital from labview
int remPin = 7;
int bacPin = 8;

int buttonStateRising_rem = 1;
int lastButtonStateRising_rem = 1;
int buttonStateRising_bac = 1;
int lastButtonStateRising_bac = 1;
unsigned long millisPrevious_rem;
unsigned long startMoveTime;
unsigned long millisPrevious_bac;
byte debounceInterval = 0; // milliseconds

void setup() {
  stepper.setup(NORMAL, 200);        //Initialisation of the uStepper S
  // define pinmode
  pinMode(remPin, INPUT);  // 
  pinMode(bacPin, INPUT);    
  //define stepper motpr
  stepper.setMaxAcceleration(10000000);     //use an acceleration of 2000 fullsteps/s^2
  stepper.setMaxVelocity(200.0*200.0/60.0);          //Max velocity of 500 fullsteps/s
 // stepper.checkOrientation(30.0);       //Check orientation of motor connector with +/- 30 microsteps movement
  Serial.begin(115200);
}

void loop() {
  
  //stepper.getMotorState())          //If motor is at standstill
  
   // stepper.encoder.setHome();

    buttonStateRising_rem = digitalRead(remPin);
    if((buttonStateRising_rem == HIGH) && (lastButtonStateRising_rem == LOW)){
      if(millis() - millisPrevious_rem >= debounceInterval){
        Serial.println("There was a rising edge on pin 7");
        startMoveTime = millis();
        Serial.println(startMoveTime);
        stepper.moveAngle(angle); 

        while(stepper.getMotorState(POSITION_REACHED));
        
        millisPrevious_rem = millis();
        Serial.println(millisPrevious_rem - startMoveTime);
        Serial.println("removed");
      }
      
    }
    lastButtonStateRising_rem = buttonStateRising_rem;
// back
    buttonStateRising_bac = digitalRead(bacPin);
    if((buttonStateRising_bac == HIGH) && (lastButtonStateRising_bac == LOW)){
      if(millis() - millisPrevious_bac >= debounceInterval){
        Serial.println("There was a rising edge on pin 8");
        startMoveTime = millis();
        Serial.println(startMoveTime);
        stepper.moveAngle(-angle); 

        while(stepper.getMotorState(POSITION_REACHED));
        
        millisPrevious_bac = millis();
        Serial.println(millisPrevious_bac - startMoveTime);
        Serial.println("bring back");
      }
      
    }
    lastButtonStateRising_bac = buttonStateRising_bac;


 /*   
    
    if(remObj == 1){
      stepper.moveToAngle(angle); 
      Serial.println("remove");
    }
    
    if(bacObj == 1){
      stepper.moveToAngle(-angle); 
      Serial.println("back");
    }
    
    } 
    */
  
}
/*
int RisingEdge(pin_num,lastButtonStateRising,debounceInterval,millisPrevious){
  
  buttonStateRising = digitalRead(remPin);
    if((buttonStateRising == HIGH) && (lastButtonStateRising == LOW)){
      if(millis() - millisPrevious >= debounceInterval){
        rising = HIGH;
        return rising;
      }
}
}
*/
