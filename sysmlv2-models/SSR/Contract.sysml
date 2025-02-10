package Contracts
{	
	
	// Contract is a new type of attribute
	attribute def Contract
	{
		abstract constraint assumption; // abstract; body will be defined in the component (part definition)
		abstract constraint guarantee;	// abstract; body will be defined in the component (part definition)
		
		attribute refinedBy : Contract[0..*]; // will be instantiated in the part usage
	}
}