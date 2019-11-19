/***
* Name: creativePart
* Author: jahangirzafar
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model creativePart

/* Insert your model definition here */

global {
	int CATEGORY_CDs <- 0;
	int CATEGORY_TSHIRT <- 1;
	int CATEGORY_DRINKS <- 2;
	
	int MAX_CATEGORY <- 2;
	init
	{
		// Make sure we get consistent behaviour
		seed <- 10.0;
				
		create AuctionPlaces number: 2 {
			set location <- {rnd(100), rnd(100)};
		}
		
		
		create Auctioneer number: 2
		{
			location <- {50,50};
			category <- rnd(MAX_CATEGORY);
			
			int count <- length(AuctionPlaces);
			int index <- rnd(count - 1);
			
			auction_place <- AuctionPlaces[index];
		}
		
		create AuctioneerRoom number: 1 {
			location <- {50, 50};
		}
		
		create Guest number: 30
		{
			location <- {rnd(100),rnd(100)};
			
			loop times: MAX_CATEGORY + 1
			{
				wanted_categories << flip(0.5);
			}
		}
		
	}
}
species AuctioneerRoom {
	rgb myColor <- #purple;
	
	aspect default {
		draw square(5) at: location color: myColor;
	}
}
species Auctioneer skills: [moving, fipa] {
	rgb myColor <- #blue;
	AuctionPlaces auction_place;
	
	int go_to_auction_timeout <- rnd(100) update: go_to_auction_timeout - 1 min: 0;
	
	int start_price <- 200 + rnd(300);
	int lowest_price <- round(start_price * 0.5);
	int current_price <- start_price;
	int auction_iteration <- 0;
	
	int category min: 0 max: MAX_CATEGORY;
	
	bool should_start_auction <- true;
	bool should_start_second_auction <- false;
	bool auction_active <- false;
	int auction_start_timeout <- 0 update: auction_start_timeout - 1 min: 0;
	
	int nr_buyers_ready <- 0;
	
	list<Guest> agreed_buyers;
	
//	Auctioneer winnerInfo;
	
	int wait <- 0;
	
	reflex waiting when : should_start_second_auction and wait < 200{
		wait <- wait + 1;
		if (wait = 200) {
			auction_active <- false;
			auction_start_timeout <- 0;
			nr_buyers_ready <- 0;
			go_to_auction_timeout <- rnd(100);
			auction_iteration <- 0;
			should_start_auction <- true;
		}
	}
	
	reflex go_to_auction when: go_to_auction_timeout <= 0 and should_start_auction and !should_start_second_auction
	{
		if (location distance_to auction_place > 2) {
			do goto target:auction_place;
		}
	}
	
	reflex go_to_new_auction when: go_to_auction_timeout <= 0 and should_start_auction and should_start_second_auction and wait >= 200
	{
		if (location distance_to auction_place > 2) {
			do goto target:auction_place;
		}
	}
	
	reflex inform_about_auction when: location distance_to auction_place <= 2 and not auction_active and should_start_auction
	{
		agreed_buyers <- [];
		auction_active <- true;
		should_start_auction <- false;
		auction_start_timeout <- 100;
		
		write '(Time ' + time + '): ' + self + " sends a cfp message to all participants about auction for category " + category;
		list<Guest> participants <- list<Guest> (Guest);
		
		do start_conversation to: participants protocol: 'fipa-request' performative: 'inform' contents: ['Starting Auction', auction_place, category] ;
	}
	
	reflex add_agreed_buyer when: !empty(informs)
	{
		loop info over: informs {
			write '(Time ' + time + '): ' + info.sender + " " + info.contents at 0;
			if (info.contents at 0 = 'Participate in Auction')
			{
				agreed_buyers << info.sender;
			}
		}
		
		informs <- [];
	}
	
	reflex abort_auction when: auction_start_timeout = 0 and not should_start_auction and auction_active and nr_buyers_ready = 0 and length(agreed_buyers) = 0
	{
		write '(Time ' + time + '): ' +  self + " Giving up on auction because no one wants to start.";
		auction_active <- false; 
	}
	
	reflex start_auction when: auction_active and 	auction_start_timeout <= 0 or (nr_buyers_ready = length(agreed_buyers) and nr_buyers_ready > 0)
		
	{		
		auction_iteration <- auction_iteration + 1;
				
		if (auction_iteration > 1)
		{
			current_price <- round(current_price * 0.9);
		}
		
		if (current_price >= lowest_price) 
		{
			write '(Time ' + time + '): ' +  self + " Starting auction iteration: " + auction_iteration;
			write '(Time ' + time + '): ' +  self + " Sell for price: " + current_price;
			auction_start_timeout <- 100;
			nr_buyers_ready <- 0;
			
			do start_conversation(
				to: agreed_buyers, protocol: 'fipa-contract-net', 
				performative: 'cfp', 
				contents: ['Sell for price', current_price]
			);	
		}
		else
		{
			auction_active <- false;
			write '(Time ' + time + '): ' +  self + " No one is willing to buy at the right price.";
			
			do start_conversation(
				to: agreed_buyers, protocol: 'fipa-request', 
				performative: 'inform', 
				contents: ['Auction Ended', auction_place]
			);
		}
	}
	
	reflex collect_failures when: !empty(failures)
	{
		write "Failue in communication protocol! Removing participant!";
		loop wrongdoerMessage over: failures
		{
			remove wrongdoerMessage.sender from: agreed_buyers;	
		}
		
		failures <- [];
	}
	
	reflex collect_accepts when: !empty(proposes)
	{
		auction_active <- false;
		message winnerMessage <- first(1 among proposes);
		remove winnerMessage from: proposes;
		
		write '(Time ' + time + '): '  + self + " Agent [" + winnerMessage.sender + "] will buy at price: " + current_price;	
		write "Item sold!";
		
		write "printing info " + winnerMessage;
		
		
		do accept_proposal with: (message: winnerMessage, contents: ['Item sold to you at price', current_price]);
		
		
		
		// Reject all others
		loop proposition over: proposes {
			do reject_proposal with: (message: proposition, contents: ['Item already sold']);
		}
		
		if(agreed_buyers != nil)
		{
			do start_conversation to: agreed_buyers protocol: 'fipa-request' performative: 'inform' contents: ['Auction Ended', auction_place] ;
			agrees <- [];
			agreed_buyers <- [];
		}
		
		 start_price <- current_price + rnd(100);
		 lowest_price <- current_price  + rnd(10);
		 current_price <- start_price;
		 
		 should_start_second_auction <- true;
		 
	}
	
	reflex collect_refusals when: !empty(refuses)
	{
		write '(Time ' + time + '): ' + name + ' receives refuse messages';
		
		loop refuser over: refuses {
			write '\t' + name + ' receives a refuse message from ' + refuser.sender + ' with content ' + refuser.contents ;
		}
		refuses <- [];
	}
	
	reflex go_back when: not should_start_auction and not auction_active
	{
		do goto(AuctioneerRoom[0].location);
		if location distance_to AuctioneerRoom[0].location <= 0
		{
			//do die;
		}
	} 

	aspect default {
    	draw circle(1) at: {location.x, location.y, 3} color: myColor;
	}
}

species Guest skills: [moving, fipa] {
	rgb myColor <- #red;
	AuctionPlaces auction_place;
	point target_point;
	int accepted_price <- 100 + rnd(100);
	list<bool> wanted_categories;
	Guest winner <- nil;
	reflex go_to_auction when: auction_place != nil
	{
		if (location distance_to auction_place > 2) {
			do goto target:auction_place;
		}
	}
	
	reflex die_when_color_is_green when: winner != nil{
		do die;
	}
	
	reflex go_to_target_point when: target_point != nil
	{
		do goto target:target_point;
		accepted_price <- 200;
		if location distance_to target_point < 2
		{
			target_point <- nil;
			
			if (myColor = #green) {
				//do die;
				winner <- self;
				
			}
			
		}
	}
	
	// Selects an auction when a new auctioneer comes.
	reflex answer_auction when: !empty(informs) and auction_place = nil
	{
		loop info over: informs
		{
			if (info.contents at 0 = "Starting Auction")
			{
				int category <- info.contents at 2;
				if (wanted_categories[category])
				{				
					write '(Time ' + time + '): ' + name + " receives a cfp message from " +info.sender+ " that "+info.contents at 0+" of category: " + info.contents at 2;	
					auction_place <- info.contents at 1;
									
					// Inform about participations
					do start_conversation to: info.sender protocol: 'fipa-request' performative: 'inform' contents: ['Participate in Auction'] ;
				}
			}
		}
		
		informs <- [];
	}
	
	reflex win_auction when: !empty(accept_proposals)
	{
		write '(Time ' + time + '): ' + name + ' receives proposals';
		loop accepted_proposals over: accept_proposals
		{
			if (accepted_proposals.contents at 0 = 'Item sold to you at price')
			{
				write '(Time ' + time + '): ' + self + " I won the auction";
				write '\t' + name + ' Proposal made to ' + accepted_proposals.sender + 'was accepted. Item Bought!';
				myColor <- #green;
				target_point <- AuctioneerRoom[0].location;
			}
		}
		accept_proposals <- [];
		
		
	}
	reflex receive_proposal_reject_messages when: !empty(reject_proposals) {
		write '(Time ' + time + '): ' + name + ' receives proposals';
		
		loop rejected_proposal over: reject_proposals {
			write '\t' + name + 'Proposal made to' + rejected_proposal.sender + ' with content ' + rejected_proposal.contents + 'was rejected';
			reject_proposals <- [];
		}
	}
	// Selects an auction when a new auctioneer comes.
	reflex end_auction when: !empty(informs) and auction_place != nil
	{
		loop info over: informs
		{
			if (info.contents at 0 = 'Auction Ended' and info.contents at 1 = auction_place)
			{
				write '(Time ' + time + '): ' + self + " Leaving auction";
				auction_place <- nil;
				if (myColor != #green) {
					target_point <- {rnd(100), rnd(100)};
				}
			}	
		}	
	}
	
	reflex auction_request when: !empty(cfps)
	{
		message proposalFromAuctioneer <- cfps[0];
		if (proposalFromAuctioneer.contents at 0 = 'Sell for price')
		{
			int proposedPrice <- proposalFromAuctioneer.contents at 1;
			if (proposedPrice < accepted_price)
			{
				// Accept
				do propose with: (message: proposalFromAuctioneer, contents: ['Accept price', proposedPrice]);
			}
			else
			{
				// Refuse
				do refuse with: (message: proposalFromAuctioneer, contents: ['Does not accept price', proposedPrice]);
			}
		}
		else
		{
			write "Received wrong message: " + proposalFromAuctioneer.contents;
			do failure with: (message: proposalFromAuctioneer, contents: ['Did not understand message']);
		}
		
		cfps <- [];
	}
	
	
	aspect default {
    	draw circle(1) at: {location.x, location.y, 3} color: myColor;
	}
}

species AuctionPlaces skills: [] {
	rgb myColor <- #gray;
	aspect default{
    	draw circle(10) at: {location.x, location.y} color: myColor;
    }
}


experiment main type: gui {
	output {
		display map type: opengl 
		{
			species AuctionPlaces;
			species Guest;
			species Auctioneer;
			species AuctioneerRoom;
		}

	}
}
