class X2Condition_OnTeamAction extends X2Condition;

var ETeam Team;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit UnitState;

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

defaultproperties
{
	Team = eTeam_XCom;
}