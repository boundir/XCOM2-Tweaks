class X2EventListener_SoldierManagementTweak extends X2EventListener config(GameData);

var config array<name> RESEARCH_UNLOCK_PSIONIC_CLASS;
var config array<name> CANT_PURCHASE_ABILITY_CLASSES;

var localized string ReasonLockedClassForbidden;

enum EReasonLocked
{
	eReason_MissingAbilityRequirements,
	eReason_WrongRank,
	eReason_MissingTrainingFacility,
	eReason_NotEnoughtAbilityPoints,
	eReason_RequireHigherRank,
};

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateValidateGTSClassTrainingListenerTemplate());
	Templates.AddItem(CreateValidateAbilityPurchaseListenerTemplate());

	return Templates;
}

static function CHEventListenerTemplate CreateValidateGTSClassTrainingListenerTemplate()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'ValidateGTSTraining_Psionic');

	Template.RegisterInTactical = false;
	Template.RegisterInStrategy = true;
	Template.AddCHEvent('ValidateGTSClassTraining', PsionicValidateGTSClassTraining, ELD_Immediate);
	
	return Template;
}

static function CHEventListenerTemplate CreateValidateAbilityPurchaseListenerTemplate()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'DisallowSameRankAbility_Psionic');
	Template.AddCHEvent('CPS_OverrideCanPurchaseAbility', PsionicAbilityPurchase, ELD_Immediate);

	// Create new resource for Psi? regular Soldiers
	// Template.AddCHEvent('CPS_OverrideAbilityPointCost', OverrideAbilityPointCost, ELD_Immediate);

	Template.RegisterInStrategy = true;

	return Template;
}

static function EventListenerReturn PsionicValidateGTSClassTraining(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple Tuple;
	local X2SoldierClassTemplate SoldierClassTemplate;

	Tuple = XComLWTuple(EventData);

	if (Tuple != none)
	{
		SoldierClassTemplate = X2SoldierClassTemplate(Tuple.Data[1].o);

		if (SoldierClassTemplate != none && SoldierClassTemplate.DataName == 'Psionic')
		{
			Tuple.Data[0].b = CanTrainPsionicClass();
		}
	}

	return ELR_NoInterrupt;
}

// Dictates conditions for Psionic Class to be trainable
// May want to add conditions in the future (psionic count, crew count, force level...)
static private function bool CanTrainPsionicClass()
{
	return SatisfyResearch();
}

static private function bool SatisfyResearch()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local bool SatisfyCondition;

	XComHQ = `XCOMHQ;
	History = `XCOMHISTORY;

	SatisfyCondition = false;

	foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
	{
		if(default.RESEARCH_UNLOCK_PSIONIC_CLASS.Find(TechState.GetMyTemplateName()) == INDEX_NONE)
		{
			continue;
		}

		SatisfyCondition = XComHQ.TechIsResearched(TechState.GetReference());
	}

	return SatisfyCondition;
}

static function EventListenerReturn PsionicAbilityPurchase(Object EventData, Object EventSource, XComGameState GameState, Name InEventID, Object CallbackData)
{
	local XComGameState_Unit UnitState;
	local XComLWTuple Tuple;
	local name SoldierClass;
	local int Rank, Branch;
	local int ClassAbilityRankCount; //Rank is 0 indexed but AbilityRanks is not. This means a >= comparison requires no further adjustments
	local string ReasonLocked;

	Tuple = XComLWTuple(EventData);
	if (Tuple == none)
	{
		return ELR_NoInterrupt;
	}

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none)
	{
		return ELR_NoInterrupt;
	}

	SoldierClass = UnitState.GetSoldierClassTemplateName();
	Rank = Tuple.Data[1].i;
	Branch = Tuple.Data[2].i;
	ClassAbilityRankCount = Tuple.Data[11].i;

	if (default.CANT_PURCHASE_ABILITY_CLASSES.Find(SoldierClass) != INDEX_NONE)
	{
		ReasonLocked = default.ReasonLockedClassForbidden;
		ReasonLocked = Repl(ReasonLocked, "%CLASSNAME%", SoldierClass);

		Tuple.Data[13].b = false;
		Tuple.Data[15].s = ReasonLocked;
		return ELR_NoInterrupt;
	}

	// All non-class abilities should be available for purchase as soon as the
	// training center has been built.
	if (Branch >= ClassAbilityRankCount)
	{
		if (`XCOMHQ.HasFacilityByName('RecoveryCenter'))
		{
			Tuple.Data[13].b = true;
		}
		else
		{
			Tuple.Data[13].b = false;
			Tuple.Data[14].i = eReason_MissingTrainingFacility;
		}
	}

	return ELR_NoInterrupt;
}
