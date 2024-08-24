class X2Condition_OnTeamTurn extends X2Condition;

var ETeam Team;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{
	local XComGameState_Unit UnitState;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');
	
	UnitState = XComGameState_Unit(kTarget);
	
	if (UnitState != none)
	{
		if (`TACTICALRULES.GetUnitActionTeam() == Team)
		{
			return 'AA_Success'; 
		}
	}
	else
	{
		return 'AA_NotAUnit';
	}

	return 'AA_AbilityUnavailable';
}

DefaultProperties
{
	Team = eTeam_XCom;
}