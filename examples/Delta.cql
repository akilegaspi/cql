typeside Ty = literal {
	types
		int
		string
	constants
	//	"100" "150" "200" "250" "300" : int
	//	"115-234" "112-988" "198-887" Smith Jones "250" "300" "100" : string
	options
	allow_empty_sorts_unsafe = true
}

schema C = literal : Ty {
 	entities 
		T1 T2
 	attributes
		ssn first1 last1 : T1 -> string
		first2 last2 : T2 -> string
		salary : T2 -> int
	options
	allow_empty_sorts_unsafe = true	
}

schema D = literal : Ty {
 	entities 
		T
 	attributes
		ssn0 first0 last0 : T -> string
		salary0 : T -> int
	options
	allow_empty_sorts_unsafe = true	
}

mapping F = literal : C -> D {
 	entity
		T1 -> T
	attributes
		ssn    -> lambda x. ssn0(x) 
		first1  -> lambda x. first0(x)
		last1   -> lambda x. x.last0
		
	entity	
		T2 -> T
 	attributes
		last2   -> lambda x. x.last0
		salary -> salary0 //dot notation
		first2  -> lambda x. x.first0 
} 

instance J = literal : D {
	generators 
		XF667 XF891 XF221 : T
	equations
	//	XF667.ssn0 = "115-234" XF891.ssn0 = "112-988" XF221.ssn0 = "198-887"
//		XF667.first0 = Bob XF891.first0 = Sue XF221.first0 = Alice
	//	XF667.last0 = Smith XF891.last0 = Smith XF221.last0 = Jones
	//	XF667.salary0 = 250 XF891.salary0 = 300 XF221.salary0 = 100
	options
	allow_empty_sorts_unsafe = true
}  



instance deltaFJ = delta F J

instance J0 = literal : D {
 generators 
	XF22 aXF66 XF89  xxx : T 
 equations
	//aXF66.ssn0 = "115-234" XF89.ssn0 = "112-988" XF22.ssn0 = "198-887"
	// aXF66.first0 = Bob XF89.first0 = Sue XF22.first0 = Alice
	//aXF66.last0 = Smith XF89.last0 = Smith XF22.last0 = Jones
	//aXF66.salary0 = 250 XF89.salary0 = 300 XF22.salary0 = 100
	options
	allow_empty_sorts_unsafe = true
}

transform h = literal : J -> J0 {
 generators
	 XF667 -> aXF66 
	 XF891 -> XF89 
	 XF221 -> XF22
}

transform h0 = delta F h

instance sigmadeltaFJ = sigma F deltaFJ {
	options
		program_allow_nontermination_unsafe = true
		allow_empty_sorts_unsafe = true
}

transform u = counit F J {
	options
		program_allow_nontermination_unsafe = true
		allow_empty_sorts_unsafe = true
}
