#include <uStepperS.h>
uStepperS stepper;
long position = 5;
bool state = 0; 
unsigned long time_delay = 0;
unsigned long memo = 0;

void setup() {
  // put your setup code here, to run once:
  stepper.setup(NORMAL,200);
  //define stepper motor
  stepper.setMaxAcceleration(20000);     //use an acceleration of 2000 fullsteps/s^2
  stepper.setMaxVelocity(72000);          //Max velocity of 500 fullsteps/s
  //stepper.checkOrientation(10.0);       //Check orientation of motor connector with +/- 30 microsteps movement
  Serial.begin(9600);
}

//void run_to_next(){
//  _position = - _position;
//  state = 0;
//  memo = millis();
//}

void loop() {
  // put your main code here, to run repeatedly:
   //stepper.run();
 //  if ( !state ){
    position = - position;
    stepper.moveAngle(position ); 
    time_delay = millis() - memo;
    state=1;
    Serial.println(time_delay);
    delay(10000);
   // run_to_next();
    
  // }

}
