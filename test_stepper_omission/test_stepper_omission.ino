// ConstantSpeed.pde
// -*- mode: C++ -*-
//
// Shows how to run AccelStepper in the simplest,
// fixed speed mode with no accelerations
/// \author  Mike McCauley (mikem@airspayce.com)
// Copyright (C) 2009 Mike McCauley
// $Id: ConstantSpeed.pde,v 1.1 2011/01/05 01:51:01 mikem Exp mikem $

#include <AccelStepper.h>

AccelStepper stepper(4,2,3,4,5); // Defaults to AccelStepper::FULL4WIRE (4 pins) on 2, 3, 4, 5

unsigned long memo = 0;
long _position = 5;
bool state = 0;

unsigned long time_delay = 0;

void setup()
{  
   stepper.setMaxSpeed(20000);
   stepper.setAcceleration(100000); //100000 seems to be the fastest acceleration possible with this motor and controller combo
   stepper.moveTo(_position); 
   Serial.begin(115200);
}

void run_to_next(){
  _position = - _position;
  stepper.moveTo(_position); 
  state = 0;
  memo = millis();
}

void loop(){  
   stepper.run();
   if (! stepper.isRunning() && !state ){
    time_delay = millis()-memo;
    state=1;
    Serial.println(time_delay);
    delay(20);
    run_to_next();
   }
   
}
