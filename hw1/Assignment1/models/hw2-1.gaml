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
		
		create auctioneer  number: 1  returns: auct { 
	     set location <- {50, 50};
		}
    }
}

species guest skills: [moving, fipa] {

	//0: idle
	//1: onAuction
	int state; 
	
	//0 CDs
	//1 Clothes
	//2 Posters
	string interest;

	int fairPrice;

    aspect base {
		draw circle(1) color: #red;
    }
    
    reflex move {
    	do wander amplitude: 90.0;
    }

	reflex receive_cfp_from_initiator when: !empty(cfps) {
		message proposalFromInitiator <- cfps[0];
		write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(proposalFromInitiator.sender).name + ':' + string(proposalFromInitiator.contents[1]) + ' ' + string(proposalFromInitiator.contents[2]);
		if(interest = proposalFromInitiator.contents[1]){
			if(int(proposalFromInitiator.contents[2]) <= fairPrice ){
				do propose (message: proposalFromInitiator, contents: ['propose', interest, proposalFromInitiator.contents[2]]);	
			}else{
				
			}
		}else{
			do refuse (message: proposalFromInitiator, contents: ['not interested'] );		
		}
		cfps <- [];
	}
	
	reflex receive_proposal_accept_messages when: !empty(accept_proposals) {
		write '(Time ' + time + '): ' + name + ' receives proposals';
		
		loop accepted_proposal over: accept_proposals {
			write '\t' + name + ' Proposal made to ' + accepted_proposal.sender + 'was accepted. Item Bought!';
			do inform ( message: accepted_proposal, contents: ['OK']);
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
}

species auctioneer skills: [moving, fipa] {
	
	int startPrice <- 1000;
	int currentPrice <- startPrice;
	int delta <- 100;
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
		
		list<guest> participants <- guest at_distance(20);
		
		write '(Time ' + time + '): ' + name + ' sends a cfp message to all participants';
		do start_conversation (to: participants, protocol: 'fipa-contract-net', performative: 'cfp', contents: ['Selling', 'CD', currentPrice]);
	}
	
	reflex receive_proposal_messages when: !empty(proposes) {
		write '(Time ' + time + '): ' + name + ' RECEIVES PROPOSALS';
		
		sold <- false;

		loop r over: proposes {
			message proposal <- r;
			write '\t' + name + ' receives a propose message from ' + r.sender + ' with content ' + r.contents ;
			if(!sold){
				do accept_proposal (message: r, contents:['Seld']);
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





experiment MyExperiment type: gui {
    output {
		display MyDisplay type: opengl {
	    	species auctioneer aspect: base;
	    	species guest aspect: base;
		}
    }
}