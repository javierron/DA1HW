/***
* Name: Hello
* Author: javier
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Hello


global {
    int number_of_guests <- 75;
    int interactions <- 0;

    init {
		create guest number: number_of_guests with: (state: 0, interest: one_of(['CD','T-shirt','Poster']), fairPrice: rnd(200, 500));
		
		create dutch_auctioneer  number: 1  returns: d_auct { 
	     set location <- {20, 20};
		}
		create sealed_bid_auctioneer  number: 1  returns: sb_auct { 
	     set location <- {80, 30};
		}
		create vickrey_auctioneer  number: 1  returns: v_auct { 
	     set location <- {50, 80};
		}
    }
}

species guest skills: [moving, fipa] {

	//0: idle
	//1: onAuction
	int state; 
	
	string interest;

	int fairPrice;

    aspect base {
		draw circle(1) color: #red;
    }
    
    reflex move {
    	do wander amplitude: 90.0;
    }

	reflex receive_cfp_from_initiator when: !empty(cfps) {
		loop proposalFromInitiator over: cfps{
			
		
		write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(proposalFromInitiator.sender).name + ':' + string(proposalFromInitiator.contents[1]);
		
		switch(proposalFromInitiator.contents at 0){
			match 'dutch'{
				if(interest = proposalFromInitiator.contents[1]){
					if(int(proposalFromInitiator.contents[2]) <= fairPrice ){
						do propose (message: proposalFromInitiator, contents: ['propose', interest, proposalFromInitiator.contents[2]]);	
					}else{
				
					}
				}else{
					do refuse (message: proposalFromInitiator, contents: ['not interested'] );		
				}
				cfps <- [];
				break;
			}
			
			match 'sealed_bid' {
				if(interest = proposalFromInitiator.contents[1]){
					do propose (message: proposalFromInitiator, contents: ['propose', interest, fairPrice - rnd(1, 10)]);	
				}else{
					do refuse (message: proposalFromInitiator, contents: ['not interested'] );		
				}
				cfps <- [];
				break;
			}
			match 'vickrey'{
				if(interest = proposalFromInitiator.contents[1]){
					do propose (message: proposalFromInitiator, contents: ['propose', interest, fairPrice]);	
				}else{
					do refuse (message: proposalFromInitiator, contents: ['not interested'] );		
				}
				cfps <- [];
				break;
			}
		}
		}
		
	}
	
	reflex receive_proposal_accept_messages when: !empty(accept_proposals) {
		write '(Time ' + time + '): ' + name + ' receives proposals';
		
		loop accepted_proposal over: accept_proposals {
			write '\t' + name + ' Proposal made to ' + accepted_proposal.sender + 'was accepted. Item bought for ' + accepted_proposal.contents at 1 +'!';
			do inform ( message: accepted_proposal, contents: ['OK']);
		}
		accept_proposals <- [];
	}
	
	reflex receive_proposal_reject_messages when: !empty(reject_proposals) {
		write '(Time ' + time + '): ' + name + ' receives proposals';
		
		loop rejected_proposal over: reject_proposals {
			write '\t' + name + 'Proposal made to' + rejected_proposal.sender + ' was rejected because of ' + rejected_proposal.contents;
			reject_proposals <- [];
		}
	}
}

species sealed_bid_auctioneer skills: [moving, fipa] {
	
	int amount <- 0;
	int auctions <- 0;
	int startPrice <- rnd(200,500);
	string item <- one_of(['CD','T-shirt','Poster']);
	
	
	aspect base {
		draw circle(20) color: #yellow;
		draw circle(1) color: #blue;
    }
	
	reflex send_cfp_to_participants when: (time mod 50 = 0) {
		
		list<guest> participants <- guest at_distance(20);
		
		if(empty(participants)){
			write 'No proposals.';
			return;
		}
		
		write '(Time ' + time + '): ' + name + ' sends a cfp message to all participants';
		do start_conversation (to: participants, protocol: 'fipa-contract-net', performative: 'cfp', contents: ['sealed_bid', item]);
	}
	
	reflex receive_proposal_messages when: !empty(proposes) {
		write '(Time ' + time + '): ' + name + ' RECEIVES PROPOSALS';
		
		int max <- 0;
		message max_m;
		list<message> all_messages <- proposes;
		
		loop r over: proposes {
			message proposal <- r;
			write '\t' + name + ' receives a propose message from ' + r.sender + ' with content ' + r.contents ;
			if(int(r.contents at 2) > max){
				max_m <- r;
				max <- int(r.contents at 2);
			}
		}
		
		loop r over: all_messages {
			message proposal <- r;
			if(r = max_m){
				amount <- amount + max;
				auctions <- auctions + 1;
				do accept_proposal (message: r, contents:['Sold for ', max]);			
			}else{
				do reject_proposal (message: r, contents:['You were outbid']);
			}
		}
		proposes <- [];
	}
	
	reflex receive_refuse_messages when: !empty(refuses) {
		write '(Time ' + time + '): ' + name + ' receives refuse messages';
		
		loop r over: refuses {
			write '\t' + name + ' receives a refuse message from ' + r.sender + ' with content ' + r.contents ;
		}
		refuses <- [];
	}

}

species dutch_auctioneer skills: [moving, fipa] {
	
	int amount <- 0;
	int auctions <-0;
	string item <- one_of(['CD','T-shirt','Poster']);
	
	
	int startPrice <- rnd(200 ,500) * 2;
	int currentPrice <- startPrice;
	int delta <- 25;
	bool sold <- true;
	
	aspect base {
		draw circle(20) color: #yellow;
		draw circle(1) color: #green;
    }
	
	reflex send_cfp_to_participants when: (time mod 50 = 0) {
		
		
		if(!sold){
			currentPrice <- currentPrice - delta;
		}else{
			currentPrice <- startPrice;
			sold <- false;
		}
		
		if(currentPrice < startPrice / 2){
			write 'No proposals above real price were made';
			sold <- true;
			return;
		}
		
		list<guest> participants <- guest at_distance(20);
		
		write '(Time ' + time + '): ' + name + ' sends a cfp message to all participants';
		do start_conversation (to: participants, protocol: 'fipa-contract-net', performative: 'cfp', contents: ['dutch', item, currentPrice]);
	}
	
	reflex receive_proposal_messages when: !empty(proposes) {
		write '(Time ' + time + '): ' + name + ' RECEIVES PROPOSALS';
		
		sold <- false;

		loop r over: proposes {
			message proposal <- r;
			write '\t' + name + ' receives a propose message from ' + r.sender + ' with content ' + r.contents ;
			if(!sold){
				amount <- amount + int(r.contents at 2);
				auctions <- auctions + 1;
				do accept_proposal (message: r, contents:['Sold', int(r.contents at 2)]);
				sold <- true;
			}else{
				do reject_proposal (message: r, contents:['already sold']);
			}
		}
		
		proposes <- [];
	}
	
	reflex receive_refuse_messages when: !empty(refuses) {
		write '(Time ' + time + '): ' + name + ' receives refuse messages';
		
		loop r over: refuses {
			write '\t' + name + ' receives a refuse message from ' + r.sender + ' with content ' + r.contents ;
		}
		refuses <- [];
	}

}

species vickrey_auctioneer skills: [moving, fipa] {
	
	int amount <- 0;
	int auctions <- 0;
	int startPrice <- rnd(200,500);
	string item <- one_of(['CD','T-shirt','Poster']);
	
	aspect base {
		draw circle(20) color: #yellow;
		draw circle(1) color: #black;
    }
	
	reflex send_cfp_to_participants when: (time mod 50 = 0) {
		
		list<guest> participants <- guest at_distance(20);
		
		if(empty(participants)){
			write 'No proposals.';
			return;
		}
		
		write '(Time ' + time + '): ' + name + ' sends a cfp message to all participants';
		do start_conversation (to: participants, protocol: 'fipa-contract-net', performative: 'cfp', contents: ['vickrey', item]);
	}
	
	reflex receive_proposal_messages when: !empty(proposes) {
		write '(Time ' + time + '): ' + name + ' RECEIVES PROPOSALS';
		
		list<int> prices;
		list<message> all_messages <- proposes;
		
		if(length(proposes) < 2){
			write 'Only one proposal received, cannot continue';
			message r <- proposes[0];
			do reject_proposal (message: r, contents:['Not enough proposals']);
			return;
		}
		
		loop r over: proposes {
			message proposal <- r;
			write '\t' + name + ' receives a propose message from ' + r.sender + ' with content ' + r.contents ;
			add to: prices item: int(r.contents at 2);
		}
		
		prices <- prices sort_by each;
		prices <- reverse(prices);
		
		write prices;
		
		loop r over: all_messages {
			message proposal <- r;
			if(r.contents at 2 = prices at 0){
				amount <- amount + prices at 1;
				auctions <- auctions + 1;
				do accept_proposal (message: r, contents:['Sold for ', prices at 1]);			
			}else{
				do reject_proposal (message: r, contents:['You were outbid']);
			}
		}
		proposes <- [];
	}
	
	reflex receive_refuse_messages when: !empty(refuses) {
		write '(Time ' + time + '): ' + name + ' receives refuse messages';
		
		loop r over: refuses {
			write '\t' + name + ' receives a refuse message from ' + r.sender + ' with content ' + r.contents ;
		}
		refuses <- [];
	}

}





experiment MyExperiment type: gui {
    output {
		display MyDisplay type: opengl {
	    	species dutch_auctioneer aspect: base;
	    	species sealed_bid_auctioneer aspect: base;
	    	species vickrey_auctioneer aspect: base;
	    	species guest aspect: base;
		}
    }
}