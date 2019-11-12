/***
* Name: Hello
* Author: javier
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Hello


global {
    int number_of_guests <- 50;

    init {
		create guest number: number_of_guests with: (hungry:0, thirsty:0, info:{50, 50});
		
		create information_center number: 1 returns: center { 
	     set location <- {50, 50};
	     set food_stands <- [{10,10},{90,90}];
	     set drink_stands <- [{10,90},{90,10}];
		}
		
		create food_stand  number: 1  returns: food1 { 
	     set location <- {10, 10};
		}
		
		create food_stand  number: 1 returns: food2 { 
	     set location <- {90, 90};
		}
		
		create drinks_stand  number: 1 returns: drinks1 { 
	     set location <- {10, 90};
		}
		
		create drinks_stand  number: 1 returns: drinks2 { 
	     set location <- {90, 10};
		}
    }
}

species guest skills: [moving] {

	//0: idle
	//11: hungry:info
	//12: hungry:food_store
	//21: thirsty:info
	//22: thirsty:food_store
	//3: go_back
	int state; 

	int hungry;
	int thirsty;
	point info;
	point current_target;

    aspect base {
    	if(state = 0 or state = 3){
			draw circle(1) color: #red;
    	}else if(state = 11 or state = 21){
    		draw circle(1) color: #yellow;
    	}
    	else if(state = 12){
    		draw circle(1) color: #blue;
    	} else if(state = 22){
    		draw circle(1) color: #green;
    	}
    }
    
    reflex dance_reflex when: state = 0 {
    	do wander;
    }
    
    reflex walk_reflex when: state != 0 {
    	do goto(current_target);
    }
    
    reflex stop_walking_reflex when: state = 3 and location distance_to(current_target) < 2{
    		state <- 0;
    }
    
    reflex food_reflex when: (state = 0 or state = 3) and flip(0.1) {
   		hungry <- hungry + 1;
   		
   		if(hungry >= 20){
   			state <- 11;
			current_target <- info;			
   		}
   	}
   	
   	reflex drink_reflex when: (state = 0 or state = 3) and flip(0.1) {
   		thirsty <- thirsty + 1;
   		
   		if(thirsty >= 20){
   			state <- 21;
			current_target <- info;			
   		}
   	}
    
}

species information_center  {

	list<point> food_stands;
	list<point> drink_stands;

    aspect base {
		draw square(15) color: #yellow;
    }
    
    reflex redirect {
	    list<guest> nearby_guests <- guest at_distance(5);	
	    
	    loop g over: nearby_guests {
    		ask g {
    			if(g.state = 11){
    				g.current_target <- one_of(myself.food_stands).location;
    				g.state <- 12;
    			} else if(g.state = 21){
    				g.current_target <- one_of(myself.drink_stands).location;
    				g.state <- 22;
    			}
    		}
		}
    }
}

species food_stand  {

    aspect base {
		draw square(4) color: #blue;
    }
    
    reflex feed {
	    list<guest> nearby_guests <- guest at_distance(5);	
	    
	    loop g over: nearby_guests {
    		ask g {
    			if(g.state = 12){
    				g.hungry <- 0;
    				g.current_target <- { rnd(20, 80), rnd(20, 80)};
    				g.state <- 3;
    			}
    		}
		}
    }
}

species drinks_stand {

    aspect base {
    	draw square(4) color: #green;
    }
    
    reflex give_drink {
	    list<guest> nearby_guests <- guest at_distance(5);	
	    
	    loop g over: nearby_guests {
    		ask g {
    			if(g.state = 22){
    				g.thirsty <- 0;
    				g.current_target <- { rnd(20, 80), rnd(20, 80)};
    				g.state <- 3;	
    			}
    		}
		}
    }
}



experiment MyExperiment type: gui {
    output {
	display MyDisplay type: opengl {
	    species guest aspect: base;
	    species information_center aspect: base;
	    species food_stand aspect: base;
	    species drinks_stand aspect: base;
	}
    }
}