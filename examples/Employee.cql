options  
		//prover = completion  
		program_allow_nontermination_unsafe = true  
		allow_empty_sorts_unsafe = true  
		//timeout = "1"
		
typeside T = literal {  
	types  
		string   
 		nat  
	constants  
 		Al Akin Bob Bo Carl Cork Dan Dunn Math CS : string  
 		zero : nat  
 	functions 		  
	 	succ : nat -> nat  
	 	plus : nat, nat -> nat  
	equations    
//	zero = zero
//	 	forall x . plus(zero, x) = x  
//	 	forall x , y . plus(succ(x),y) = succ(plus(x,y))  
 }

schema S = literal : T {   
	entities  
		Employee   
		Department 
	foreign_keys 
		manager   : Employee -> Employee 
		worksIn   : Employee -> Department 
		secretary : Department -> Employee 
	attributes 
  	    first last : Employee -> string 
     	age : Employee -> nat 
     	name : Department -> string 
     observation_equations
//	forall e. e.first = Al     	 
		
    }

instance I = literal : S { 
	generators  
		a b : Employee 
	equations  
	    a.manager=a a.worksIn.secretary=a     
	    b.manager=a b.worksIn = a.worksIn  
	     last(b) = Bo 

	multi_equations
		first -> {a Al, b Bob}
		 
}    


instance J = literal : S { 
	generators  
		a b : Employee
		c d : Department

y:nat
	equations  
	    a.manager=a a.worksIn = d   c.secretary=b     
	    b.manager=a b.worksIn = c   d.secretary=b    
        first(a) = Al a.last = Al  d.name=Bob
c.name = Al	
		age(a)=zero age(b) = y
 options interpret_as_algebra = true
}    
