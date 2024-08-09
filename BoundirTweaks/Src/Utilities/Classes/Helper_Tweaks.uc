class Helper_Tweaks extends Object;

var config(Engine) bool EnableDebug;
var config(Engine) bool EnableTrace;

var X2AbilityTemplateManager AbilityTemplateManager;
var X2CharacterTemplateManager CharacterTemplateManager;
var X2ItemTemplateManager ItemTemplateManager;
var X2SitRepTemplateManager SitRepTemplateManager;
var X2StrategyElementTemplateManager StrategyTemplateManager;

static function X2AbilityTemplateManager GetAbilityTemplateManager()
{
	if (AbilityTemplateManager == none)
	{
		`TweaksLog(`StaticLocation);
		AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	}

	return AbilityTemplateManager;
}

static function X2CharacterTemplateManager GetCharacterTemplateManager()
{
	if (CharacterTemplateManager == none)
	{
		`TweaksLog(`StaticLocation);
		CharacterTemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	}

	return CharacterTemplateManager;
}

static function X2ItemTemplateManager GetItemTemplateManager()
{
	if (ItemTemplateManager == none)
	{
		`TweaksLog(`StaticLocation);
		ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	}

	return ItemTemplateManager;
}

static function X2SitRepTemplateManager GetSitRepTemplateManager()
{
	if (SitRepTemplateManager == none)
	{
		`TweaksLog(`StaticLocation);
		SitRepTemplateManager = class'X2SitRepTemplateManager'.static.GetSitRepTemplateManager();
	}

	return SitRepTemplateManager;
}

static function X2StrategyElementTemplateManager GetStrategyTemplateManager()
{
	if (StrategyTemplateManager == none)
	{
		`TweaksLog(`StaticLocation);
		StrategyTemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	}

	return StrategyTemplateManager;
}

static function array<DarkEventAppearanceRestriction> FindDarkEventListByName(name DarkEvent, array<DarkEventAppearanceRestriction> DarkEventConditions)
{
	local DarkEventAppearanceRestriction DarkEventCondition;
	local array<DarkEventAppearanceRestriction> DarkEvents;

	foreach DarkEventConditions(DarkEventCondition)
	{
		if (DarkEventCondition.DarkEvent == DarkEvent)
		{
			DarkEvents.AddItem(DarkEventCondition);
		}
	}

	return DarkEvents;
}

static function X2Condition FillConditionFromConfig(out Condition, array<name> UnitTypes, array<name> UnitClasses)
{
	local name UnitType;
	local name UnitClass;

	foreach UnitTypes(UnitType)
	{
		Condition.IncludeTypes.AddItem(UnitType);
	}

	foreach UnitClasses(UnitClass)
	{
		Condition.IncludeSoldierClasses.AddItem(UnitClass);
	}
}

static function bool ReturnFalse()
{
	return false;
}