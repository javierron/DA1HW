/***
* Name: hw31
* Author: javier
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model hw31

/* Insert your model definition here */

global {
    int n_queens <- 8;
    int n_tiles <- n_queens * n_queens;
	int offset <- int(100 / (n_queens * 2));
	
	list<queen> queens;
	
    init {
		loop i from: 0 to: n_tiles - 1 {
			
			int grid_align <- 0;
			if(n_queens mod 2 = 0){
				if(int(i / n_queens) mod 2 = 1){
					grid_align <- 1;
				}
			}
			
			int x <- (i mod n_queens) * (int(100 / n_queens)) + offset;
			int y <- (int(i / n_queens)) * (int(100 / n_queens)) + offset;
			create tile number: 1 with: (col: ((i + grid_align) mod 2), size: 100 / n_queens, location: {x, y});
		}
    
		loop i from: 0 to: n_queens - 1 {		
			create queen number: 1 with: (index: i) returns: q {
				set current <- i = 0;
			}
			add q at 0 to: queens;
		}
		
		
    }
}

species queen skills:[moving, fipa] {
	
	aspect base {
 		draw circle(3) color: #red;
	}
	
	int index;
	int row <- -1;
	
	bool current;
	bool do_set;
	
	
	reflex move_to_target when: !current {
		int x <- index * (int(100 / n_queens)) + offset;
		int y <- row * (int(100 / n_queens)) + offset;
		do goto(target : {x,y});
	}
	
	reflex select_next_row when: current and time mod (n_queens + 1) = 0 {
		
		row <- row + 1;
		
		if(row >= n_queens){
			row <- -1;
			current <- false;
			if(index != 0){
				do start_conversation (to: [queens[index - 1]], contents: ["Move, please", row, index], performative: "request", protocol: 'fipa-contract-net');				
			}
			return;
		}
		
		if(index != 0){
			do start_conversation (to: [queens[index - 1]], contents: ["Can I sit here?", row, index], performative: "query", protocol: 'fipa-contract-net');
		}else{
			do_set <- true;		
		}
		
	}
	
	reflex get_set when: do_set {
		current <- false;
		if(index < n_queens - 1){
			do start_conversation (to: [queens[index + 1]], contents: ["I'm set"], performative: "inform", protocol: 'fipa-contract-net');
		}
		do_set <- false;
	}
	
	reflex receive_request when: !empty(requests) {
		message r <- requests at 0;
		current <- true;
		
		do end_conversation(message: r, contents: []) ;
		
	}
	
	reflex receive_query when: !empty(queries) {
		message r <- queries at 0;
		if(r.contents at 0 = "Can I sit here?"){
			if(index = 0){
				point dir_vector <- {int(r.contents at 2) - index, int(r.contents at 1) - row};
				bool no_collision <- (row != r.contents at 1) and (abs(dir_vector.y atan2 dir_vector.x) != 45.0); 	
				if(no_collision){
					do query(message: r, contents: [true, r.contents at 1, r.contents at 2]);
					return;
				}else{
					do query(message: r, contents: [false, r.contents at 1, r.contents at 2]);
					return;				
				}
			}else{
				do end_conversation(message: r, contents: ["wait"]);
				do start_conversation (to: [queens[index - 1]], contents: ["Can I sit here?", r.contents at 1, r.contents at 2], performative: "query", protocol: 'fipa-contract-net');
			}
		}else if(r.contents at 0 = false){
			if(r.contents at 2 = index){				
				
			}else{
				do start_conversation (to: [queens[index + 1]], contents: [false, r.contents at 1, r.contents at 2], performative: "query", protocol: 'fipa-contract-net');
			}
			do end_conversation(message: r, contents: []);
			return;
		}else if(r.contents at 0 = true){
			if(r.contents at 2 = index){
				do_set <- true;			
			}else{
				point dir_vector <- {int(r.contents at 2) - index, int(r.contents at 1) - row};
				bool b <- true and row !=  r.contents at 1 and (abs(dir_vector.y atan2 dir_vector.x) != 45.0);
				do start_conversation (to: [queens[index + 1]], contents: [b, r.contents at 1, r.contents at 2], performative: "query", protocol: 'fipa-contract-net');	
			}
			
			do end_conversation(message: r, contents: []);
			return;
		}
	}
	
	reflex receive_informs when: !empty(informs){
		message r <- informs at 0;
		
		do end_conversation(message: r, contents: []);
		
		current <- true;	
	}
}


species tile {
	int size;
	
	//0 white
	//1 black
	int col;
	
	aspect base {
	 	if(col = 0){
			draw square(size) color: #white; 		
	 	}else if(col = 1){
	 		draw square(size) color: #black;
	 	}
    }
    
    reflex lol {
    	
    }
	
}

experiment MyExperiment type: gui {
    output {
		display MyDisplay type: opengl {
	    	species tile aspect: base;
	    	species queen aspect: base;
	    }
    }
}
