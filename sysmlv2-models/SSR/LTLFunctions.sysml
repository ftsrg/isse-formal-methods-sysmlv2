package LTLFunctions
{
	private import Base::Anything;
	private import ScalarValues::*;
	
	calc def 'next' {in constraint x; return : Anything[1];}
	calc def 'change' {in constraint x; return : Boolean[1];}

	calc def 'always' {in constraint x; return : Boolean[1];}
	calc def 'never' {in constraint x; return : Boolean[1];}
	calc def 'in_the_future' {in constraint x; return : Boolean[1];}
	calc def 'then' {in constraint x; return : Boolean[1];}
			
	calc def 'historically' {in constraint x; return Boolean[1];}
	calc def 'in_the_past' {in constraint x; return Boolean[1];}
	calc def 'previously' {in constraint x; return Boolean[1];}

	calc def 'until' {in constraint x; in constraint y; return : Boolean[1];}
	calc def 'releases' {in constraint x; in constraint y; return : Boolean[1];}
	
	calc def 'since' {in constraint x; in constraint y; return : Boolean[1];}
	calc def 'triggered' {in constraint x; in constraint y; return : Boolean[1];}
	
	calc def 'at_next' {in constraint x; in constraint y; return : Boolean[1];}
	calc def 'at_last' {in constraint x; in constraint y; return : Boolean[1];}
	
	calc def 'time_until' {in constraint x; return : Boolean[1];}
	calc def 'time_since' {in constraint x; return : Boolean[1];}
	
	calc def 'fall' {in constraint x; return : Boolean[1];}
	calc def 'rise' {in constraint x; return : Boolean[1];}
	
	calc def 'G' {in constraint x; return : Boolean[1];} // Globally
	calc def 'F' {in constraint x; return : Boolean[1];} // Finally
	calc def 'X' {in constraint x; return : Boolean[1];} // Next State
	calc def 'O' {in constraint x; return : Boolean[1];} // Once
	calc def 'H' {in constraint x; return : Boolean[1];} // Historically
	
	calc def 'Y' {in constraint x; return : Boolean[1];} // Previous State
	calc def 'U' {in constraint x; return : Boolean[1];} // Until
	calc def 'V' {in constraint x; return : Boolean[1];} // Release
	calc def 'S' {in constraint x; return : Boolean[1];} // Since
	calc def 'T' {in constraint x; return : Boolean[1];} // Triggered
	calc def 'Z' {in constraint x; return : Boolean[1];} // Not Previous State
}
