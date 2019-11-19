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
		write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(proposalFromInitiator.sender).name + ':' + string(proposalFromInitiator.contents[1]);
		if(interest = proposalFromInitiator.contents[1]){
			do propose (message: proposalFromInitiator, contents: ['propose', interest, fairPrice]);	
		}else{
			do refuse (message: proposalFromInitiator, contents: ['not interested'] );		
		}
		cfps <- [];
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

species auctioneer skills: [moving, fipa] {
	
	int amount <- 0;
	int auctions <- 0;
	int startPrice <- rnd(200,500);
	string item <- one_of(['CD','T-shirt','Poster']);
	
	aspect base {
		draw circle(20) color: #yellow;
		draw circle(1) color: #green;
    }
	
	reflex send_cfp_to_participants when: (time mod 50 = 0) {
		
		list<guest> participants <- guest at_distance(20);
		
		if(empty(participants)){
			write 'No proposals.';
			return;
		}
		
		write '(Time ' + time + '): ' + name + ' sends a cfp message to all participants';
		do start_conversation (to: participants, protocol: 'fipa-contract-net', performative: 'cfp', contents: ['Selling', item]);
	}
	
	reflex receive_proposal_messages when: !empty(proposes) {
		write '(Time ' + time + '): ' + name + ' RECEIVES PROPOSALS';
		
		list<int> prices;
		list<message> all_messages <- proposes;
		
		if(length(proposes) <= 2){
			write 'Only one proposal received, cannot continue';
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
			write "second loop";
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
	    	species auctioneer aspect: base;
	    	species guest aspect: base;
		}
    }
}