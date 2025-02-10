package AdExampleVerification {
	
	private import VerificationCases::*;
	private import GammaLib::*;
	
	private import autonomous_vehicle_custom::*;
	
	verification def ExampleVerification {
		subject adSystem : System;
		
		objective ProveSafetyObjective : TestGenerationObjective {
			:>> coverage = CoverageKind::TrapState;
		}
		
		return verdict : VerdictKind;
	}
}