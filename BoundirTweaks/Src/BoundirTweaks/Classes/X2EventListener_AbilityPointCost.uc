class X2EventListener_AbilityPointCost extends X2EventListener config(GameData);

var config int AbilityPointCostBase;
var config float AbilityPointCostGrowth;
var config int PowerfulAbilityAdditionalCost;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	Templates.AddItem(CreateExponentialAbilityPurchaseCostTemplate());

	return Templates;
}

static function CHEventListenerTemplate CreateExponentialAbilityPurchaseCostTemplate()
{
	local CHEventListenerTemplate Template;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'ExponentialAbilityPurchaseCost');
	Template.AddCHEvent('CPS_OverrideAbilityPointCost', IncreaseAbilityPurchaseCostExponentially, ELD_Immediate);

	Template.RegisterInTactical = false;
	Template.RegisterInStrategy = true;

	return Template;
}

static function EventListenerReturn IncreaseAbilityPurchaseCostExponentially(Object EventData, Object EventSource, XComGameState GameState, Name InEventID, Object CallbackData)
{
	local XComGameState_Unit UnitState;
	local XComLWTuple Tuple;
	local int AdditionalAbilitiesPurchased;
	local bool IsResistanceHero, IsPowerfulAbility;
	local int Branch;
	local int ClassAbilityRankCount;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	Tuple = XComLWTuple(EventData);

	if (Tuple == none)
	{
		return ELR_NoInterrupt;
	}

	IsResistanceHero = Tuple.Data[10].b;
	IsPowerfulAbility = Tuple.Data[3].b;
	Branch = Tuple.Data[2].i;
	ClassAbilityRankCount = Tuple.Data[11].i;

	if (IsResistanceHero)
	{
		return ELR_NoInterrupt;
	}

	UnitState = XComGameState_Unit(EventSource);

	if (UnitState == none)
	{
		return ELR_NoInterrupt;
	}

	AdditionalAbilitiesPurchased = class'Helper_Tweaks'.static.GetAdditionalAbilitiesPurchased(UnitState);

	Tuple.Data[12].i = Round(default.AbilityPointCostBase * (1 + default.AbilityPointCostGrowth) ** AdditionalAbilitiesPurchased);

	if (IsPowerfulAbility && (Branch == ClassAbilityRankCount))
	{
		Tuple.Data[12].i += default.PowerfulAbilityAdditionalCost;
	}

	return ELR_NoInterrupt;
}
