class BT_StrategyDataStructuresTweaks extends Object;

enum EDarkEventRestriction
{
	eDarkEventRestriction_NeverAppear,
	eDarkEventRestriction_ForceLevel,
	eDarkEventRestriction_ChosenMustBeAlive,
	eDarkEventRestriction_ChosenMustHaveAtLeastOneWeakness,
	eDarkEventRestriction_ChosenMustBeDead
	// @todo StrategyRequirement
};

enum EReasonLocked
{
	eReason_MissingAbilityRequirements,
	eReason_WrongRank,
	eReason_MissingTrainingFacility,
	eReason_NotEnoughtAbilityPoints,
	eReason_RequireHigherRank
};

struct DarkEventAppearanceRestriction
{
	var name DarkEvent;
	var EDarkEventRestriction Restriction;
	var name ChosenName;
	var int MinForceLevel;
	var int MaxForceLevel;
};

struct CovertActionStatRewardLimit
{
	var name RewardName;
	var ECharStatType StatType;
	var float StatLimit;
};

