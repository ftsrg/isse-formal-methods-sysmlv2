package Traffic_light {
	
//	private import ISQ::*;
//	private import ISQBase::*;
//	private import Time::*;
//	private import ScalarValues::*;
//	private import StringFunctions::*;
//	private import NumericalFunctions::*;
	private import ScalarValues::*;
//	private import SI::*;
	
//	private import GammaLib::*;
		
	private import Hierarchy::*;
		
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
				
	part def System {
		in control_message_queue : Custom_string;
		in control_wait_duration : Natural;
		
		part controller : Controller;
		
		bind control_message_queue = controller.control_message_queue;
		bind control_wait_duration = controller.control_wait_duration;
	}
	
	part def Controller {
		in control_message_queue : Custom_string;
		in control_wait_duration : Natural;
		in vehicle_at_light : Boolean;
		in error : Boolean;
		
		attribute yellow_on_time : Natural := 2;	// Default value not used, set during off_to_init transition
		attribute green_on_time : Natural := 30;	// Default value not used, set during off_to_init transition
		attribute red_on_time : Natural := 90;		// Default value not used, set during off_to_init transition
		attribute yellow_light_state : Light_state;
		attribute red_light_state : Light_state;
		attribute green_light_state : Light_state;
		attribute trans : Boolean;
	
		state traffic_light {
			entry; then off;

			state off;
				
			state initial {
			}
					
			state diagnostic {
			}
				
			state operation_selection{
			}
			
			state stop_sign;
			 
			state red_blinking {
			}
				
			state caution;
			 
			state yellow_blinking {
			}
				
			state traffic_flow {
			}
			 
			state green_on {
			}
				
			state yellow_on {
			}
			 
			state red_on {
			}
				
			transition off_to_init
				first off 
				do action {
					assign red_on_time := 90;
					assign yellow_on_time := 2;
					assign green_on_time := 30;
				}
				then initial; 
				
			transition init_to_diagnostic
				first initial
				if (error == true)
				do assign trans := true
				then diagnostic;
				
			transition diagnostic_to_red_blinking
				first diagnostic
				do action {
			  assign green_light_state := Light_state::off;
			  assign yellow_light_state := Light_state::off;
			  assign red_light_state := Light_state::off;
			  assign trans := false;
			  assign red_light_state := Light_state::blinking;
		}
				then red_blinking;

			transition operation_selection_to_init
				first operation_selection
				if (error == true)
				then initial;

			transition init_to_operation_selection
				first initial
				if (error == false)
				then operation_selection;
			
			transition operation_selection_to_stop_sign
				first operation_selection
				if ((control_message_queue == Custom_string::operating_mode_stop_sign)
						and (error == false))
				then stop_sign;  

			transition operation_selection_to_caution
				first operation_selection
				if ((control_message_queue == Custom_string::operating_mode_caution) 
						and (error == false))
				then caution;
				
			transition operation_selection_to_traffic_flow
				first operation_selection
				if ((control_message_queue == Custom_string::operating_mode_traffic_flow) 
						and (error == false))
				then traffic_flow;
			
			transition caution_to_yellow_blinking
				first caution
				do assign yellow_light_state := Light_state::blinking
				then yellow_blinking;
				
			transition stop_sign_to_red_blinking
				first stop_sign
				do action {
					assign green_light_state := Light_state::off;
					assign yellow_light_state := Light_state::off;
					assign red_light_state := Light_state::off;
					assign trans := false;
					assign red_light_state := Light_state::blinking;
				}
				then red_blinking;
				
			transition traffic_flow_to_red_on
				first traffic_flow
				if (error == false)
				do action {
					assign green_light_state := Light_state::off;
					assign yellow_light_state := Light_state::off;
					assign red_light_state := Light_state::off;
					assign trans := false;
					assign red_light_state := Light_state::lit;
				}
				then red_on;

			transition red_on_to_green_on
				first red_on
				if (control_wait_duration > red_on_time) 
						and (vehicle_at_light == true)
						and (control_message_queue == Custom_string::Safe_all_red)
						and (error == false)
				do action {
					assign green_light_state := Light_state::off;
					assign yellow_light_state := Light_state::off;
					assign red_light_state := Light_state::off;
					assign trans := false;
					assign green_light_state := Light_state::lit;
				}
				then green_on;
				
			transition red_on_to_traffic_flow
				first red_on
				if ((((control_message_queue != Custom_string::_)
						and (control_message_queue != Custom_string::Safe_all_red))
						or (error == true)))
				then traffic_flow; 

			transition green_on_to_yellow_on
				first green_on
				if (control_wait_duration > green_on_time
						or (error == true))
				do action {
					assign green_light_state := Light_state::off;
					assign yellow_light_state := Light_state::off;
					assign red_light_state := Light_state::off;
					assign trans := false;
					assign yellow_light_state := Light_state::lit;
				}
				then yellow_on;

			transition yellow_on_to_red_on
				first yellow_on
				if (control_wait_duration > yellow_on_time
						or (error == true)// TODO added
				) 
				do action {
					assign green_light_state := Light_state::off;
					assign yellow_light_state := Light_state::off;
					assign red_light_state := Light_state::off;
					assign trans := false;
					assign red_light_state := Light_state::lit;
				}
				then red_on;

			transition traffic_flow_to_operation_selection
				first traffic_flow
				if ((control_message_queue != Custom_string::_)
						or (error == true))
				then operation_selection;	
				
			transition red_blinking_to_operation_selection
				first red_blinking
				if ((control_message_queue != Custom_string::_)
						or (error == true))
				then operation_selection;
				
			transition yellow_blinking_to_operation_selection
				first yellow_blinking
				if ((control_message_queue != Custom_string::_)
						or (error == true))
				then operation_selection;
		}
	}
	
	part traffic_light_simplified : System, SystemComponent;
}
