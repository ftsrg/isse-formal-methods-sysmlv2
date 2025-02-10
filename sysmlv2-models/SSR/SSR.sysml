
package SSR {
	private import ScalarValues::Real;
	private import ScalarValues::Boolean;

	private import Contracts::*;
	private import LogicFunctions::*;
	private import LTLFunctions::*;
	private import Hierarchy::*;
	private import ThreatsPropagation::States::*;
		
	// Definitions
	part def System {
		in speed : Real;
		out sensed_speed: Real;
		out sensed_speed_is_present : Boolean;	
		
		part sensor1: SpeedSensor::SpeedSensor;
		part sensor2: SpeedSensor::SpeedSensor;
		
		part selector : Selector::Selector;
		
		part monitor1: MonitorPresence::MonitorPresence;
		part monitor2: MonitorPresence::MonitorPresence;
		
		connect speed to sensor1.speed;  
		connect speed to sensor2.speed;
		
		connect sensor1.sensed_speed to selector.input1;
		connect sensor2.sensed_speed to selector.input2;
		
		connect sensor1.sensed_speed_is_present to selector.input1_is_present;
		connect sensor2.sensed_speed_is_present to selector.input2_is_present;

		connect sensor1.sensed_speed_is_present to monitor1.input_is_present;
		connect sensor2.sensed_speed_is_present to monitor2.input_is_present;
		
		connect selector.output to sensed_speed;
		connect selector.output_is_present to sensed_speed_is_present;
		
		// Complex connections
		:>> selector.switch_current_use = monitor1.absence_alarm or monitor2.absence_alarm;
		:>> monitor1.enabled = (selector.current_use==Selector::Interval1_2::ONE);
		:>> monitor2.enabled = (selector.current_use==Selector::Interval1_2::TWO);
			
		// contract of the System component
		attribute sense : Contract 
		{
			assert constraint :>> assumption 
			{
				// assuming that:
				// - at the beginning the speed is 0
				// - the acceleration/deceleration is below a threshold
				 
				// the original one written in OCRA language
				//  speed=0 & G((next(speed) - speed)<=1 and (next(speed) - speed)>=-1)

				speed==0 and G({(next({speed}) - speed)<=1 and (next({speed}) - speed)>=-1 })
			}
			
			assert constraint :>> guarantee 
			{
				// we expect that:
				// - there is always a sensed speed
				// - the delta between the speed and the sensed speed is <= 4 

				// the original one 
				//  always ((sensed_speed - speed <= 4) and (sensed_speed - speed >= - 4) and sensed_speed_is_present)
				 
				always ({(sensed_speed - speed <= 4) and (sensed_speed - speed >= -4) and sensed_speed_is_present})
			}		
			refinedBy = (monitor1.monitor, monitor2.monitor, selector.select, selector.switch, sensor1.sense, sensor2.sense);
		}
	}	
		
	package SpeedSensor {	
		part def SpeedSensor {
			in  speed : Real;
			out sensed_speed: Real;
			out sensed_speed_is_present : Boolean;
			
			attribute sense : Contract // constraint usage
			{
				assert constraint assumption :>> assumption 
				{
					// assuming that:
					// - at the beginning the speed is 0
					// - the acceleration/deceleration is below a threshold
					 
					// the original one
					//  speed=0 & G((next(speed) - speed)<=1 and (next(speed) - speed)>=-1 )
					
					speed==0 and G({(next({speed}) - speed) <= 1 and (next({speed}) - speed)>=-1 })
				}
				
				assert constraint guarantee :>> guarantee 
				{
					// we expect that:
					// - there is always a sensed speed
					// - the delta between the speed and the sensed speed is <= 1

					// the original one written in OCRA language
					//  always ((sensed_speed - speed <= 1) and (sensed_speed - speed >= -1) and sensed_speed_is_present)
	   	      	      
					always({(sensed_speed - speed <= 1) and (sensed_speed - speed >= -1) and sensed_speed_is_present})  
				}		
			}
			
			state speedSensorStates
			{			
				// init transition
				entry action {assign sensed_speed := 0; assign sensed_speed_is_present := true;}  // transition effect as variables assigments
				then primary; 
				
				state primary;
					
				// nominal transition						
	            transition 'primary-primary'
		            first primary
		            if true // guard
		            do action {assign sensed_speed_is_present := true; assign sensed_speed := speed;} // effect
		            then primary;
			}

			state faultSpeedSensorStates
			{			
				entry action {}
				then nominal;
			
				state nominal;
				state error : Inverted	// flipped output (for Boolean signals)
				{
					:>> probability = 0.05;
					:>> property = sensed_speed_is_present;
				}
									
				transition 'nominal-error'
					first nominal
					if true // guard
					do action {} //effect
					then error;	       
			}
		}			
	}
	
	package MonitorPresence {
		part def MonitorPresence {
			in input_is_present: Boolean;
			in enabled: Boolean;
			out absence_alarm: Boolean;
			
			attribute monitor : Contract
			{
				assert constraint assumption :>> assumption 
				{
					// assuming that: at the beginning the sensor associated to this monitor is working
					
					// the original one written in OCRA language
					//  input_is_present=true
					
					(input_is_present==true)
				}
				
				assert constraint guarantee :>> guarantee 
				{
					// we expect that: an alarm is triggered whenever the monitor is enabled and the input is not present (is absent)
					
					// the original one written in OCRA language
					// always((absence_alarm) iff (enabled and not(input_is_present)))
					 
					// always({iff({next({absence_alarm})}, {enabled and not(input_is_present)})})	// correct
					always({iff({absence_alarm}, {enabled and not(input_is_present)})}) 			// wrong
				}		
			}
											
			state monitorPresenceStates 	
			{			
				// init transition				
				entry action {assign absence_alarm := false;} // transition effect as variables assigments
				then primary; 
				
				state primary;
				
				// nominal transition						
	            transition 'primary-primary'
		            first primary
		            if true // guard
		            do action {assign absence_alarm := (not(input_is_present) and (enabled));} // effect
		            then primary;
			}
			
			state faultMonitorStates
			{			
				entry action {}
				then nominal;
			
				state nominal;
				state error : StuckAtFixed	// stuck at fixed random value
				{
					:>> probability = 0.05;
					:>> property = absence_alarm;
				}
									
				transition 'nominal-error'
					first nominal
					if true // guard
					do action {} //effect
					then error;	       
			}
		}
	}
	
	package Selector {
		part def Selector {
			in input1: Real;
			in input1_is_present: Boolean;
			in input2: Real;
			in input2_is_present: Boolean;
			
			out output: Real;
			out output_is_present: Boolean;
			
			in switch_current_use: Boolean;
			out current_use: Interval1_2;
			
			attribute select : Contract
			{
				assert constraint assumption :>> assumption 
				{
					true
				}
				
				assert constraint guarantee :>> guarantee 
				{
					// we expect that:
					// - at the beginning the sensed speed is 0
					// - the sensed speed will be measured by the current sensor
					 	
					// the original one written in OCRA language
					//  (output=0 and output_is_present = TRUE) and always ((next(current_use=1) implies 
	    	 	    //  (next(output)=input1 and next(output_is_present)=input1_is_present)) and 
	   	    		//  (next(current_use=2) implies 
		     		//  (next(output)=input2 and next(output_is_present)=input2_is_present)))
		     			 
		     		(output==0 and output_is_present == true) and always ({(next({current_use==Interval1_2::ONE}) implies 
	    	 	      (next({output})==input1 and next({output_is_present})==input1_is_present)) and 
	   	    		  (next({current_use==Interval1_2::TWO}) implies 
		     		  (next({output})==input2 and next({output_is_present})==input2_is_present))})	     		  
				}		
			}
			 
			attribute switch : Contract
			{
				assert constraint assumption :>> assumption 
				{
					true
				}
				
				assert constraint guarantee :>> guarantee 
				{
					// we expect that: the switch of the sensor depends only on the input boolean port 'switch_current_use'
					
					// the original one written in OCRA language
					//  always (
	    			//  ((current_use=1 and switch_current_use) implies next(current_use)=2) and
				    //  ((current_use=2 and switch_current_use) implies next(current_use)=1) and
				    //  ((not switch_current_use) implies not change(current_use)))
				     				     
				    always ({
				    ((current_use==Interval1_2::ONE and switch_current_use) implies next({current_use})==Interval1_2::TWO) and
				    ((current_use==Interval1_2::TWO and switch_current_use) implies next({current_use})==Interval1_2::ONE) and
				    ((not switch_current_use) implies not change({current_use}))})			    
				}		
			}
			
			state selectorStates 	
			{			
				// init transition				
				entry action {assign current_use := Interval1_2::ONE; assign output := 0; assign output_is_present := true;} // transition effect as variables assigments
				then input_1; 
				
				state input_1;
				state input_2;
					
				// nominal transition						
	            transition 'input_1-input_1'
		            first input_1
		            if not switch_current_use // guard
		            do action {assign output := input1 ; assign output_is_present := input1_is_present;} // effect
		            then input_1;
		            
		        // nominal transition    
		        transition 'input_1-input_2'
		            first input_1
		            if switch_current_use // guard
		            do action {assign current_use := Interval1_2::TWO; assign output := input2; assign output_is_present := input2_is_present;} // effect
		            then input_2; 
		         
		        // nominal transition    
		        transition 'input_2-input_2'
		            first input_2
		            if not switch_current_use // guard
		            do action {assign output := input2; assign output_is_present := input2_is_present;} //effect
		            then input_2;
		          
		        // nominal transition    
		        transition 'input_2-input_1'
		            first input_2
		            if switch_current_use // guard
		            do action {assign current_use := Interval1_2::ONE; assign output := input1 ; assign output_is_present := input1_is_present;} // effect
		            then input_1;          
			}
			
			state faultSelectorStates
			{			
				entry action {}
				then nominal;
			
				state nominal;
				state error : StuckAtByReference_D	// stuck at given term
				{
					:>> probability = 0.05;
					:>> property = output_is_present;
					:>> term = "FALSE";
				}
									
				transition 'nominal-error'
					first nominal
					if true // guard
					do action {} //effect
					then error;	       
			}
		}
		
		enum def Interval1_2 {
			enum ONE;
			enum TWO;
		}
	}
		
	part system : System, SystemComponent {			
	}
}
