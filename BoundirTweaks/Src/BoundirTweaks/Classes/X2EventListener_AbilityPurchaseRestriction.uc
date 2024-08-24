class X2EventListener_AbilityPurchaseRestriction extends X2EventListener config(GameData);

var config array<name> CLASSES_CANT_PURCHASE_BONUS_ABILITIES;

var localized string ReasonLockedClassForbidden;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	Templates.AddItem(CreateValidateAbilityPurchaseListenerTemplate());

	return Templates;
}

static function CHEventListenerTemplate CreateValidateAbilityPurchaseListenerTemplate()
{
	local CHEventListenerTemplate Template;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'DisallowSameRankAbility_Psionic');
	Template.AddCHEvent('CPS_OverrideCanPurchaseAbility', PsionicAbilityPurchase, ELD_Immediate);

	Template.RegisterInTactical = false;
	Template.RegisterInStrategy = true;

	return Template;
}

static function EventListenerReturn PsionicAbilityPurchase(Object EventData, Object EventSource, XComGameState GameState, Name InEventID, Object CallbackData)
{
	local XComGameState_Unit UnitState;
	local XComLWTuple Tuple;
	local name SoldierClass;
	local int Branch;
	local int ClassAbilityRankCount;
	local string ReasonLocked;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

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
	Branch = Tuple.Data[2].i;
	ClassAbilityRankCount = Tuple.Data[11].i;

	if (Branch < ClassAbilityRankCount)
	{
		if (default.CLASSES_CANT_PURCHASE_BONUS_ABILITIES.Find(SoldierClass) != INDEX_NONE)
		{
			ReasonLocked = default.ReasonLockedClassForbidden;
			ReasonLocked = Repl(ReasonLocked, "%CLASSNAME%", SoldierClass);

			Tuple.Data[13].b = false;
			Tuple.Data[15].s = ReasonLocked;
		}
	}

	return ELR_NoInterrupt;
}
