class X2Condition_UnitPropertyTweak extends X2Condition;

var() array<name> IncludeTypes;
var() array<name> ExcludeTypes;
var() array<name> IncludeSoldierClasses;
var() array<name> ExcludeSoldierClasses;
var() bool IncludeWeakAgainstTechLikeRobot;
var() bool ExcludeOrganic;
var() bool ExcludePsionic;
var() bool ExcludeNonPsionic;
var() bool ExcludeRobotic;
var() bool ExcludeNonRobotic;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{ 
	local XComGameState_Unit UnitState;
	local name UnitTypeName;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	UnitState = XComGameState_Unit(kTarget);

	if (UnitState == none)
	{
		return 'AA_NotAUnit';
	}

	if (UnitState.IsDead())
	{
		return 'AA_UnitIsDead';
	}

	UnitTypeName = UnitState.GetMyTemplate().CharacterGroupName;

	if (UnitState.IsSoldier())
	{
		if (IncludeSoldierClasses.Find(UnitState.GetSoldierClassTemplateName()) != INDEX_NONE)
		{
			return 'AA_Success';
		}

		if (ExcludeSoldierClasses.Find(UnitState.GetSoldierClassTemplateName()) != INDEX_NONE)
		{
			return 'AA_WrongSoldierClass';
		}
	}

	if (IncludeTypes.Find(UnitTypeName) != INDEX_NONE)
	{
		return 'AA_Success';
	}

	if (ExcludeTypes.Find(UnitTypeName) != INDEX_NONE)
	{
		return 'AA_UnitIsWrongType';
	}

	if (IncludeWeakAgainstTechLikeRobot && UnitState.GetMyTemplate().bWeakAgainstTechLikeRobot)
	{
		return 'AA_Success';
	}

	if ((ExcludePsionic && UnitState.IsPsionic()) || (ExcludeNonPsionic && !UnitState.IsPsionic()))
	{
		return 'AA_UnitIsWrongType';
	}

	if ((ExcludeRobotic && UnitState.IsRobotic()) || (ExcludeNonRobotic && !UnitState.IsRobotic()))
	{
		return 'AA_UnitIsWrongType';
	}

	return 'AA_Success';
}

DefaultProperties
{
	ExcludePsionic = false;
	ExcludeNonPsionic = false;
	ExcludeRobotic = false;
	ExcludeNonRobotic = false;
}