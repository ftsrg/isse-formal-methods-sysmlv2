package GammaLib {
	// Experimental formal methods library stub
	
	enum def CoverageKind {
		State;
		Transition;
		TransitionPair;
		Interaction;
		InteractionDataflow;
		Dataflow;
		UnstableState;
		TrapState;
		Deadlock;
		NondeterministicTransition;
	}
	requirement def TestGenerationObjective {
		attribute coverage : CoverageKind default CoverageKind::State;
	}
	
	part def GammaComponent;
	part def SynchronousComponent :> GammaComponent;
	part def AsynchronousComponent :> GammaComponent;
	part def CompositeComponent :> GammaComponent;
	part def CascadeCompositeComponent :> SynchronousComponent, CompositeComponent;
	part def SynchronousCompositeComponent :> SynchronousComponent, CompositeComponent;
	part def ScheduledAsynchronousCompositeComponent :> AsynchronousComponent, CompositeComponent;
	part def AsynchronousCompositeComponent :> AsynchronousComponent, CompositeComponent;
	
	calc def <MustAlways> AG;
	calc def <MustEventually> AF;
	calc def <MayAlways> EG;
	calc def <MayEventually> EF;
	
}