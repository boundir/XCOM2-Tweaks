class X2DLCInfo_CharacterTweaks extends X2DownloadableContentInfo;

var config(GameData_SoldierSkills) array<name> GRANT_BLADESTORM_GUARANTEED_HIT;
var config(GameData_SoldierSkills) array<name> NOT_EASY_TO_HIT;

var config(GameCore) array<UnitLootReplacer> SUPPLANT_LOOT_UNITS;

static private function X2DLCInfo_CharacterTweaks GetClassDefaultObject()
{
	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	return X2DLCInfo_CharacterTweaks(class'XComEngine'.static.GetClassDefaultObjectByName(default.Class.Name));
}

static event OnPostTemplatesCreated()
{
	local X2CharacterTemplateManager CharacterTemplateManager;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	CharacterTemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	RulersAffectTimerAbilities(CharacterTemplateManager);
	EUBerserkerGetsDevastatingPunchAtMeleeRange(CharacterTemplateManager);
	AttachGaranteedHitBladestorm(CharacterTemplateManager);
	RemoveEasyToHitAbililty(CharacterTemplateManager);
	RemoveUnwantedLoot(CharacterTemplateManager);
}

static function RulersAffectTimerAbilities(X2CharacterTemplateManager CharacterTemplateManager)
{
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2CharacterTemplate CharacterTemplate;
	local AlienRulerData RulerData;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	foreach class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates(RulerData)
	{
		CharacterTemplateManager.FindDataTemplateAllDifficulties(RulerData.AlienRulerTemplateName, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			CharacterTemplate = X2CharacterTemplate(DataTemplate);

			if (CharacterTemplate == none)
			{
				continue;
			}

			CharacterTemplate.Abilities.AddItem('ResumeTimer');
			CharacterTemplate.Abilities.AddItem('PauseTimer');
		}
	}
}

static function EUBerserkerGetsDevastatingPunchAtMeleeRange(X2CharacterTemplateManager CharacterTemplateManager)
{
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2CharacterTemplate CharacterTemplate;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	CharacterTemplateManager.FindDataTemplateAllDifficulties('EUBerserker', DifficulityVariants);

	foreach DifficulityVariants(DataTemplate)
	{
		CharacterTemplate = X2CharacterTemplate(DataTemplate);

		if (CharacterTemplate == none)
		{
			continue;
		}

		CharacterTemplate.Abilities.AddItem('EUBerserkerDevastatingPunchAtMeleeRange');
	}
}

static function AttachGaranteedHitBladestorm(X2CharacterTemplateManager CharacterTemplateManager)
{
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2CharacterTemplate CharacterTemplate;
	local name TemplateName;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	foreach default.GRANT_BLADESTORM_GUARANTEED_HIT(TemplateName)
	{
		CharacterTemplateManager.FindDataTemplateAllDifficulties(TemplateName, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			CharacterTemplate = X2CharacterTemplate(DataTemplate);

			if (CharacterTemplate == none)
			{
				continue;
			}

			CharacterTemplate.Abilities.AddItem('BladestormAssassin');
		}
	}
}

static function RemoveEasyToHitAbililty(X2CharacterTemplateManager CharacterTemplateManager)
{
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2CharacterTemplate CharacterTemplate;
	local name TemplateName;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	foreach default.NOT_EASY_TO_HIT(TemplateName)
	{
		CharacterTemplateManager.FindDataTemplateAllDifficulties(TemplateName, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			CharacterTemplate = X2CharacterTemplate(DataTemplate);

			if (CharacterTemplate == none)
			{
				continue;
			}

			CharacterTemplate.Abilities.RemoveItem('CivilianEasyToHit');
		}
	}
}

static function RemoveUnwantedLoot(X2CharacterTemplateManager CharacterTemplateManager)
{
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2CharacterTemplate CharacterTemplate;
	local X2CharacterTemplate SupplierCharacterTemplate;
	local UnitLootReplacer Unit;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	foreach default.SUPPLANT_LOOT_UNITS(Unit)
	{
		SupplierCharacterTemplate = CharacterTemplateManager.FindCharacterTemplate(Unit.Supplier);

		if (SupplierCharacterTemplate == none)
		{
			continue;
		}

		CharacterTemplateManager.FindDataTemplateAllDifficulties(Unit.Consumer, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			CharacterTemplate = X2CharacterTemplate(DataTemplate);

			if (CharacterTemplate == none)
			{
				continue;
			}

			CharacterTemplate.Loot = SupplierCharacterTemplate.Loot;
			CharacterTemplate.TimedLoot = SupplierCharacterTemplate.TimedLoot;
			CharacterTemplate.VultureLoot = SupplierCharacterTemplate.VultureLoot;
		}
	}
}
