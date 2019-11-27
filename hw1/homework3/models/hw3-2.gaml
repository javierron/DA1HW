/***
* Name: Task2
* Author: jahangirzafar
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Task2

/* Insert your model definition here */

global {
	int BAND_1 <- 0; // RAP
	int BAND_2 <- 1; // METAL
	int BAND_3 <- 2; // POP
	int BAND_4 <- 3; // HIPHOP
	int BAND_Count <- 3;
	
	
	init{
		seed <- 10.0;
				
		create BANDSTAGES number: 4 {
			location <- {rnd(100), rnd(100)};
		}
		
		create GUEST number: 20
		{
			location <- {rnd(100),rnd(100)};
			
			preference_band_types << rnd(BAND_Count);
			

			write "["+self+"]:";
			write "\tband_rating:    " + band_rating;
			write "\tband_lighting:  " + band_lighting;
			write "\tband_speakers:  " + band_speakers;
			write "\tband_size:    	 " + band_size;
			write "\tband_type:    	 " + preference_band_types;
			write "\tdancing:    	 " + band_dancing;
		}
	}
}
species BANDSTAGES skills: [fipa] {
	rgb myColor <- #yellow;
	rgb myColor_lightshow <- #green;
	
	// Changing properties
	float property_speakers <- rnd(1.0);
	int   property_band_size <- 2 + rnd(5); // number of singers
	int   property_band_type <- rnd(BAND_Count);
	float property_band_rating <- rnd(1.0);
	float property_band_dancing <- rnd(1.0);
	float property_lighting <- rnd_choice([0.1, 0.4, 0.6, 0.8]) / 2.0;
	float property_dancing <- rnd(1.0);
	bool show_active <- false;
	int show_timeout <- 50 + rnd(500) update: show_timeout - 1 min: 0;
	
	
	reflex start_show when: (not show_active) and show_timeout < 1 {
		show_active <- true;
		show_timeout <- 300 + rnd(500);
		
		list<GUEST> participants <- list<GUEST> (GUEST);
		
		map<string, float> property_map <- [
			'band_rating':: property_band_rating,
			'lighting':: property_lighting,
			'speakers':: property_speakers,
			'size':: property_band_size,
			'band_type':: property_band_type,
			'dancing' ::property_band_dancing
		];
		
		write "["+self+"]: Announcing Concert";
		write "\tband-rating:   " + property_band_rating;
		write "\tlighting:  " + property_lighting;
		write "\tspeaker:" + property_speakers;
		write "\tband-size:   " + property_band_size;
		write "\tdancing:   " + property_band_dancing;
		if (property_band_type = BAND_1) {
			write "\ts-music:  RAP";
		}
		else if (property_band_type = BAND_2) {
			write "\ts-music:  METAL";
		}
		else if (property_band_type = BAND_3) {
			write "\ts-music:  POP";
		}
		else  {
			write "\ts-music:  HIPHOP";
		}

		if (length(participants) > 0) {
			do start_conversation( to: participants, protocol: 'fipa-request', 
				performative: 'inform', 
				contents: ['Starting Concert', property_map]
			);				
		}
	}
	reflex stop_show when: show_active and show_timeout < 1 {
		show_timeout <- 300 + rnd(500);
		show_active <- false;
		
		// Update settings
		property_band_type <- rnd(BAND_Count);
		property_band_rating <- rnd(1.0);
		property_lighting <- rnd_choice([0.0, 0.2, 0.6, 0.2]) / 3.0;
		property_dancing <- rnd(1.0);
		list<GUEST> participants <- list<GUEST> (GUEST);
		if (length(participants) > 0) {
			do start_conversation(
				to: participants, protocol: 'fipa-request', 
				performative: 'inform', 
				contents: ['Concert Ended']
			);	
		}
	}

	
	reflex update_light_color when: show_active
	{
		if (flip(property_lighting)) {
			myColor_lightshow <- rnd_color(255);	
		}
	}
	
	
	aspect default{
		if (show_active) {	
			draw circle(10) at: {location.x, location.y} color: myColor_lightshow;
		}
		else{
			draw circle(10) at: {location.x, location.y} color: myColor;
		}
		
    	
    }
}
species GUEST skills: [fipa, moving]{
	BANDSTAGES band_stages;
	float current_scene_rating <- 0.0;
	point target_point;
	
	float band_rating <- rnd(1.0);
	float band_lighting <- rnd(0.2, 1.0);
	float band_speakers <- rnd(1.0);
	float band_dancing <- rnd(1.0);
	int band_size <- rnd(5);
	list<int>   preference_band_types <- [];	
	
	reflex go_to_concert when: band_stages != nil and target_point = nil 
		and location distance_to band_stages > 5
	{
		do goto target:band_stages;
	}
	
	reflex dance when: band_stages != nil and target_point = nil
		and location distance_to band_stages <= 5
	{
		do wander;
	}
	
	reflex go_to_target_point when: target_point != nil
	{
		do goto target:target_point;
		
		if location distance_to target_point < 2
		{
			target_point <- nil;
		}
	}
	
	// Selects an auction when a new auctioneer comes.
	reflex check_inform_messages when: !empty(informs)
	{
		loop info over: informs
		{
			if (info.contents at 0 = "Starting Concert")
			{
				map<string, float> properties <- map<string,float> (info.contents at 1);
				float personal_scene_rating <-
					band_rating 		* properties["band_rating"] +
					band_lighting 		* properties["lighting"] + 
					band_speakers 		* properties["speakers"] +
					band_dancing		* properties["dancing"]+
					band_size 			* properties["size"];
					
				if (properties["band_type"] in preference_band_types) {
					personal_scene_rating <- personal_scene_rating + 2; 
				}
				
				
				if (current_scene_rating < personal_scene_rating) {
					current_scene_rating <- personal_scene_rating;
					band_stages <- info.sender;
				
					write "["+self+"] - Going to new concert at ("+info.sender+") with my utility: " + personal_scene_rating;
				} else {
					write "["+self+"] - Ignoring new concert at ("+info.sender+") with my utility: " + personal_scene_rating;
				}
			
				
			} else if (info.contents at 0 = "Concert Ended" and band_stages != nil) {
				if (info.sender = band_stages) {
					target_point <- {rnd(100), rnd(100)};
					band_stages <- nil;
					current_scene_rating <- 0.0;
					write "["+self+"] - Leavng concert";	
				}
			}
		}
		
		informs <- [];
	}
	
	aspect default {
    	draw circle(1) at: {location.x, location.y} color: #black;
    }
	
}
experiment main type: gui {
	output {
		display map type: opengl 
		{
			species BANDSTAGES;
			species GUEST;
		}
	}
}