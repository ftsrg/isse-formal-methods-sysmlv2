package Traffic_light {
	
	private import ISQ::*;
	private import ISQBase::*;
	private import Time::*;
	private import ScalarValues::*;
	private import StringFunctions::*;
	private import NumericalFunctions::*;
	private import ScalarValues::*;
	private import SI::*;
	
	private import GammaLib::*;
		
//	port def Can_bus;
//	port def Clock;
//	port def Vehicle_sensor_port;
//	port def Comm;
	
	enum def Light_state {
		off;
		lit;
		blinking;
	}
	
	enum def Custom_string {
		_;
		Safe_all_red;
		operating_mode_stop_sign;
		operating_mode_caution;
		operating_mode_traffic_flow;
	}
					  
	calc def Light_power { in light_state : Light_state;
	   return : Integer = 
				 if light_state == Light_state::off ? 0
					else if light_state == Light_state::lit ? 12
					else if light_state == Light_state::blinking ? 8
					else 0;
	   }
		   
	calc def Radio_power { in radio_on : Boolean;
	   return : Integer = 
				 if radio_on ? 4
				 else 0;
	}
			
	item def Power;
	item def State_message_item {
		attribute message_queue : Custom_string;
		attribute wait_duration : Natural;
	}
	
	port def Control {
//		in item power : Power;
		in item state_message_item : State_message_item;
	}
	
	part def System {
		port control : Control;
		
		part controller : Controller;
		
		bind control = controller.control;
	}
	
	part def Controller {
//		port light_control_out : Can_bus;
//		port communications_in : Comm;
		port control : Control;
		
//		attribute power : Boolean;
		attribute error : Boolean;
//		attribute error_code : Integer;
//		attribute message_queue : Custom_string;
//		attribute counter : Integer;
//		attribute current_time : TimeInstantValue;
//		attribute state_duration : DurationValue;
//		attribute wait_duration : Natural;
		attribute yellow_on_time : Natural := 2;
		attribute green_on_time : Natural := 30;
		attribute red_on_time : Natural := 90;
		attribute yellow_light_state : Light_state;
		attribute red_light_state : Light_state;
		attribute green_light_state : Light_state;
//		attribute mass : Real := 0.8;
//		attribute power_usage : Real := 2.0;
		
		attribute vehicle_at_light : Boolean;
		attribute trans : Boolean;
	
		state traffic_light {
			entry; then off;
			state off;
				
			state initial {
				entry action : power_up_test { in val = 10; }
				do action : check_error;
				exit;
			}
					
			state diagnostic {
				entry action : run_diagnostic;
				exit action : reset_error;
			}
				
			state operation_selection{
				entry action : check_error;
				do action : check_status;
				exit;
			}
			state stop_sign;
			 
			state red_blinking {
				entry action : blink_red_light;
				do action : check_error;
				exit;
			}
				
			state caution;
			 
			state yellow_blinking {
				entry action : blink_yellow_light;
				do action : check_status; 
				exit;
			}
				
			state traffic_flow {
				entry action : check_status;
				exit;
			}
			 
			state green_on {
				entry action : turn_green_on; 
				do action : check_status;
				exit;
			}
				
			state yellow_on {
				 entry action : turn_yellow_on;
				 do action : check_error;
				 exit;
			}
			 
			state red_on {
				 entry action : turn_red_on;
				 do action : check_status;
				 exit;
			}
				
			transition off_to_init
				first off 
				accept State_message_item via control // Changed
				then initial; 
				
			transition init_to_diagnostic
				first initial
				accept when (error == true)
				then diagnostic;
				
			transition diagnostic_to_red_blinking
				first diagnostic
				then red_blinking;

			transition operation_selection_to_init
				first operation_selection
				accept when (error == true)
				then initial;

			transition init_to_operation_selection
				first initial
				accept when (error == false)
				then operation_selection;
			
			transition operation_selection_to_stop_sign
				first operation_selection
				accept state_message_item : State_message_item via control
				if ((state_message_item.message_queue == Custom_string::operating_mode_stop_sign)
						and (error == false))
				then stop_sign;  

			transition operation_selection_to_caution
				first operation_selection
				accept state_message_item : State_message_item via control
				if ((state_message_item.message_queue == Custom_string::operating_mode_caution) 
						and (error == false))
				then caution;
				
			transition operation_selection_to_traffic_flow
				first operation_selection
				accept state_message_item : State_message_item via control
				if ((state_message_item.message_queue == Custom_string::operating_mode_traffic_flow) 
						and (error == false))
				then traffic_flow;
			
			transition caution_to_yellow_blinking
				first caution
				then yellow_blinking;
				
			transition stop_sign_to_red_blinking
				first stop_sign
				then red_blinking;
				
			transition traffic_flow_to_red_on
				first traffic_flow
				accept when (error == false)
				then red_on;

			transition red_on_to_green_on
				first red_on
				accept state_message_item : State_message_item via control
				if (state_message_item.wait_duration > red_on_time) 
						and (vehicle_at_light == true)
						and (state_message_item.message_queue == Custom_string::Safe_all_red)
						and (error == false)
				then green_on;
				
			transition red_on_to_traffic_flow
				first red_on
				accept state_message_item : State_message_item via control
				if ((((state_message_item.message_queue != Custom_string::_)
						and (state_message_item.message_queue != Custom_string::Safe_all_red))
						or (error == true)))
				then traffic_flow; 

			transition green_on_to_yellow_on
				first green_on
				accept state_message_item : State_message_item via control
				if (state_message_item.wait_duration > green_on_time
						or (error == true))
				then yellow_on;

			transition yellow_on_to_red_on
				first yellow_on
				accept state_message_item : State_message_item via control
				if (state_message_item.wait_duration > yellow_on_time
						or (error == true)) // TODO added
				then red_on;

			transition traffic_flow_to_operation_selection
				first traffic_flow
				accept state_message_item : State_message_item via control
				if ((state_message_item.message_queue != Custom_string::_)
						or (error == true))
				then operation_selection;	
				
			transition red_blinking_to_operation_selection
				first red_blinking
				accept state_message_item : State_message_item via control
				if ((state_message_item.message_queue != Custom_string::_)
						or (error == true))
				then operation_selection;
				
			transition yellow_blinking_to_operation_selection
				first yellow_blinking
				accept state_message_item : State_message_item via control
				if ((state_message_item.message_queue != Custom_string::_)
						or (error == true))
				then operation_selection;

		}

		action def power_up_test {
	        in val : ScalarValues::Integer;
	    }
		
		action def turn_lights_off {
			  assign green_light_state := Light_state::off;
			  assign yellow_light_state := Light_state::off;
			  assign red_light_state := Light_state::off;
			  assign trans := false;
		}			

		action def turn_yellow_on {
			  action : turn_lights_off;
			  action : reset_wait_clock;
			  assign yellow_light_state := Light_state::lit;
	  	}
		action def turn_green_on {
			  action : turn_lights_off;
			  action : reset_wait_clock;
			  assign green_light_state := Light_state::lit;
		}
		action def turn_red_on {
			  action : turn_lights_off;
			  action : reset_wait_clock;
			  assign red_light_state := Light_state::lit;
		}

		action def reset_error;
		action def reset_wait_clock;

		action def run_diagnostic{
			action update_error_code;
			action update_error;
			assign trans := true;
		}
		action def check_status {
			action : check_error;
		}
		action def check_error {
			
		}
		action def blink_red_light {
			  action : turn_lights_off;
			  assign red_light_state := Light_state::blinking;
		}
		action def blink_yellow_light {
			  assign yellow_light_state := Light_state::blinking;
		}
		
	}
}

