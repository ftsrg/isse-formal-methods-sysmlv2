package autonomous_vehicle_custom {
    
    doc /* Model based on paper "Automatic Formal Verification of SysML State Machine Diagrams for Vehicular
    Control Systems" from Clemson University */

    private import ISQ::*;
    private import ISQBase::*;
    private import Time::*;
    private import ScalarValues::*;
    private import StringFunctions::*;
    private import NumericalFunctions::*;
    private import ScalarValues::*;
    private import SI::*;
    private import GammaLib::*;
   
    public import ad_interfaces::*;

    part def System :> CascadeCompositeComponent {

        port environment : Environmental_port;

        bind environment = controller.environment;

        part controller : Controller;
    }

    part def Controller {

        port environment : Environmental_port;

        exhibit state driving_control_module {
            entry;
            then human_mode;
            
            state human_mode {}
            state autonomous_mode parallel {
                state autonomous_driving {
                    state initialize {}
                    state highway_driving {
                        state enter_hwy {}
                        state lane_change {}
                        state cruise {}
                        state exit_hwy {}
                        
                        first start then enter_hwy; // Is this what we want?
                        
                        transition enter_hwy_to_cruise
                            first enter_hwy
                            then cruise;
                        
                        transition cruise_to_lane_change
                            first cruise
                            accept i : Payload via environment
                            if ((Dist_calc(i.e.op.ped_distance_front, i.e.ov.front_distance) < 25.0) and
                                        (i.e.rf.extra_lane))
                            then lane_change;

                        transition enter_hwy_to_lane_change
                            first enter_hwy
                            accept i : Payload via environment if ((Dist_calc(i.e.op.ped_distance_front, i.e.ov.front_distance) < 25.0) and
                                        (i.e.rf.extra_lane))
                            then lane_change;
                        
                        transition lane_change_to_cruse
                            first lane_change
                            then cruise;
                        
                        transition lane_change_to_exit_hwy
                            first lane_change
                            accept i : Payload via environment if (i.e.rf.distance_to_exit < 2.0)
                            then exit_hwy;
                        
                        transition cruise_to_exit_hwy
                            first cruise
                            accept i : Payload via environment if (i.e.rf.distance_to_exit < 2.0)
                            then exit_hwy;
                        
                        /*transition exit_hwy_to_done
                            first exit_hwy
                            then done;*/
                    }
                    
                    state urban_driving {
                        state enter_urban {}
                        state intersection {}
                        state straight {}
                        state urban_lane_change {}
                        state exit_urban {}
                        
                        first start then enter_urban;
                        
                        transition enter_urban_to_straight
                            first enter_urban
                            then straight;
                        
                        transition enter_urban_to_intersection
                            first enter_urban
                            accept i : Payload via environment if (i.e.rf.intersection)
                            then intersection;
                        
                        transition straight_to_intersection
                            first straight
                            accept i : Payload via environment if (i.e.rf.intersection)
                            then intersection;
                        
                        transition intersection_to_straight
                            first intersection
                            then straight;
                        
                        transition straight_to_lane_change
                            first straight
                            accept i : Payload via environment if ((Dist_calc(i.e.op.ped_distance_front, i.e.ov.front_distance) < 15.0) and
                                        (i.e.rf.extra_lane))
                            then urban_lane_change;

                        transition enter_urban_to_lane_change
                            first enter_urban
                            accept i : Payload via environment if ((Dist_calc(i.e.op.ped_distance_front, i.e.ov.front_distance) < 15.0) and
                                        (i.e.rf.extra_lane))
                            then urban_lane_change;
                        
                        transition lane_change_to_straight
                            first urban_lane_change
                            then straight;   
                        
                        transition lane_change_to_exit_urban
                            first urban_lane_change
                            accept i : Payload via environment if (i.e.rf.distance_to_exit < 0.7)
                            then exit_urban;
                        
                        transition straight_to_exit_urban
                            first straight
                            accept i : Payload via environment if (i.e.rf.distance_to_exit < 0.7)
                            then exit_urban;
                        
                        /*transition exit_urban_to_done
                            first exit_urban
                            then done;*/
                    }
                    
                    state finish {}
                    
                    first start then initialize;
                    
                    transition initialize_to_highway_driving
                        first initialize
                        accept i : Payload via environment if ((i.e.odd == Odd::highway))
                        then highway_driving;
                    
                    transition initialize_to_urban_driving
                        first initialize
                        accept i : Payload via environment if ((i.e.odd == Odd::urban))
                        then urban_driving;
                    
                    transition urban_driving_to_finish
                        first urban_driving
                        accept i : Payload via environment if (i.e.di.power_off)
                        then finish;
                    
                    transition highway_driving_to_finish
                        first highway_driving
                        accept i : Payload via environment if (i.e.di.power_off)
                        then finish;
                    
                    /*transition finish_to_done
                        first finish
                        then done;*/ 
                    
                    transition highway_driving_to_highway_driving
                        first highway_driving
                        accept i : Payload via environment if ((i.e.di.power_off == false) and ((i.e.odd == Odd::urban) == false))
                        then highway_driving;
                    
                    transition urban_driving_to_urban_driving
                        first urban_driving
                        accept i : Payload via environment if ((i.e.di.power_off == false) and ((i.e.odd == Odd::highway) == false))
                        then urban_driving;
                }
                
                state obstacle_detection {
                    
                    first start then collision_avoidance_deactive;
                    
                    state collision_avoidance_deactive;
                    state collision_avoidance_active {
                        state collision_avoidance parallel {
                            state frontend {
                                first start then front_inactive;
                                
                                transition front_inactive_to_avoid_frontend_collision 
                                    first front_inactive
                                    accept i : Payload via environment if (((Dist_calc(i.e.op.ped_distance_front, i.e.ov.front_distance) < 15.0) and ((i.e.odd == Odd::highway))) or
                                                ((Dist_calc(i.e.op.ped_distance_front, i.e.ov.front_distance) < 10.0) and ((i.e.odd == Odd::urban))))
                                    then avoid_frontend_collision;
                                
                                transition avoid_frontend_collision_to_front_inactive
                                    first avoid_frontend_collision
                                    accept i : Payload via environment if (Dist_calc(i.e.op.ped_distance_front, i.e.ov.front_distance) > 15.0)
                                    then front_inactive;
                                
                                    
                                state avoid_frontend_collision {}
                                state front_inactive {}
                            }
                            state rearend {
                                first start then rear_inactive;
                                
                                transition rear_inactive_to_avoid_rearend_collision 
                                    first rear_inactive
                                    accept i : Payload via environment if  (((Dist_calc(i.e.op.ped_distance_rear, i.e.ov.rear_distance) < 5.0) and (i.e.k.vel > 30.0)) or
                                                ((Dist_calc(i.e.op.ped_distance_rear, i.e.ov.rear_distance) < 1.0) and (i.e.k.vel > 60.0)))
                                    then avoid_rearend_collision;
                                
                                transition avoid_frontend_collision_to_front_inactive
                                    first avoid_rearend_collision
                                    accept i : Payload via environment if (Dist_calc(i.e.op.ped_distance_rear, i.e.ov.rear_distance) > 12.0)
                                    then rear_inactive;
                                
                                state avoid_rearend_collision {}
                                state rear_inactive {}
                            }
                            state pedestian {
                                
                                first start then pedestrian_inactive;
                                
                                transition pedestrian_inactive_to_avoid_pedestrian_collision 
                                    first pedestrian_inactive
                                    accept i : Payload via environment if (i.e.op.ped_detected)
                                    then avoid_pedestrian_collision;
                                
                                transition avoid_pedestrian_collision_to_pedestrian_inactive
                                    first avoid_pedestrian_collision
                                    accept i : Payload via environment if (i.e.op.ped_detected == false)
                                    then pedestrian_inactive;
                                
                                state avoid_pedestrian_collision {}
                                state pedestrian_inactive {}
                            }                    
                        }

                        state collision_avoidance_done;

                        first start then collision_avoidance;
                        
                        transition collision_avoidance_to_done
                            first collision_avoidance
                            accept i : Payload via environment if ((Dist_calc(i.e.op.ped_distance_rear, i.e.ov.rear_distance) > 12.0) and
                                        (i.e.op.ped_detected == false) and
                                        (Dist_calc(i.e.op.ped_distance_front, i.e.ov.front_distance) > 15.0))
                            then collision_avoidance_done;
                    }
                    transition collision_avoidance_deactive_to_collision_avoidance_active
                        first collision_avoidance_deactive
                        accept i : Payload via environment if ((i.e.op.ped_detected) or
                                    ((Dist_calc(i.e.op.ped_distance_rear, i.e.ov.rear_distance) < 5.0) and (i.e.k.vel > 30.0)) or
                                    ((Dist_calc(i.e.op.ped_distance_rear, i.e.ov.rear_distance) < 15.0) and (i.e.k.vel > 60.0)) or
                                    ((Dist_calc(i.e.op.ped_distance_front, i.e.ov.front_distance) < 15.0) and ((i.e.odd == Odd::highway))) or
                                    ((Dist_calc(i.e.op.ped_distance_front, i.e.ov.front_distance) < 10.0) and ((i.e.odd == Odd::urban))))
                        then collision_avoidance_active;
                    
                    transition collision_avoidance_active_to_collision_avoidance_deactive
                        first collision_avoidance_active
                        accept i : Payload via environment if ((i.e.op.ped_detected == false) and
                                    (Dist_calc(i.e.op.ped_distance_rear, i.e.ov.rear_distance) >= 12.0) and 
                                    (Dist_calc(i.e.op.ped_distance_front, i.e.ov.front_distance) >= 15.0))
                        then collision_avoidance_deactive;
                }            
            }

            state autonomous_mode_done;

            transition human_mode_to_autonomous_mode
                first human_mode 
                accept i : Payload via environment if ((i.e.in_autonomous_mode) and 
                            (i.e.di.brake_pressed == false) and
                            (i.e.di.human_steering_cmd == false) and
                            (i.e.power_on))
                then autonomous_mode;
            
            transition autonomous_mode_to_human_mode
                first autonomous_mode
                accept i : Payload via environment if ((i.e.di.brake_pressed) and
                            (i.e.di.human_steering_cmd) and
                            (i.e.power_on))
                then human_mode;
            
            transition human_mode_to_done
                first human_mode
                accept i : Payload via environment if (i.e.power_on == false)
                then autonomous_mode_done;
            
            transition autonomous_mode_to_done
                first autonomous_mode
                accept i : Payload via environment if (i.e.power_on == false)
                then autonomous_mode_done;
        }
    }

    calc def Dist_calc { 
        in ped_dist : Real;
        in veh_dist : Real;
        return : Real = 
                    if (veh_dist < ped_dist) ? veh_dist
                    else ped_dist;
    }
    
}

package ad_interfaces {

    private import NumericalFunctions::*;
    private import ScalarValues::*;

    enum def Odd {highway; urban;}

    attribute def Obstacle_vehicle {
        attribute front_distance : Real;
        attribute rear_distance : Real;
    }

    attribute def Kinematics {
        attribute vel : Real;
    }

    attribute def Road_features {
        attribute intersection : Boolean;   
        attribute extra_lane : Boolean;
        attribute distance_to_exit : Real;
    }

    attribute def Obstacle_pedestrian {
        attribute ped_detected : Boolean;
        attribute ped_distance_front : Real;
        attribute ped_distance_rear : Real;
    }

    attribute def Driver_input {
	    attribute brake_pressed : Boolean;
	    attribute power_off : Boolean;
	    attribute power_on : Boolean;
	    attribute human_steering_cmd : Boolean;
	    attribute auto_requested : Boolean;
    }

    attribute def Environment {
        attribute odd : Odd;
        attribute ov : Obstacle_vehicle;
        attribute op : Obstacle_pedestrian;
        attribute di : Driver_input;
        attribute rf : Road_features;
        attribute k : Kinematics;
        // Control signals
        attribute in_autonomous_mode : Boolean;
        attribute power_on : Boolean;
    }

    item def Payload {
    	attribute e : Environment;
    }

    port def Environmental_port {
        out item payload : Payload;
    }

}