package ThreatsPropagation
{
	private import Base::Anything;
	private import ScalarValues::*;

	package States
	{
		state def ErrorState
		{
			attribute probability: Real[1];
		}
		
		state def StuckAtByReference_D :> ErrorState // stuck at given term
		{
			attribute property: Anything[1];
			attribute term: String[1];
		}
		
		state def RampDown :> ErrorState // decreasing over time
		{
			attribute property: Anything[1];
			attribute decr: String[1];
			attribute endValue: String[1];
		}
		
		state def Inverted :> ErrorState // flipped output (for Boolean signals)
		{	
			attribute property: Anything[1];
		}
		
		state def StuckAtFixed :> ErrorState // stuck at fixed random value
		{
			attribute property: Anything[1];
		}
		
		state def Frozen :> ErrorState // frozen to the last value
		{
			attribute property: Anything[1];
		}
		
		/* TO BE FIXED */
		state def NonDeterminism // random between bounds
		{} // tbd its properties
		
		state def Conditional // if-then-else
		{} // tbd its properties
		
		state def ConditionalDualOutputs // conditional with two outputs
		{} // tbd its properties
		
		state def Random // random output
		{} // tbd its properties
		
		state def Erroneous // random output, but other than correct value
		{} // tbd its properties
		
		state def DeltaOut // output out of bounds
		{} // tbd its properties
		
		state def DeltaInRandom // output displaced and within bounds
		{} // tbd its properties
		
		state def DeltaInErroneous // output displaced and within bounds, but other than correct value
		{} // tbd its properties
	}
}