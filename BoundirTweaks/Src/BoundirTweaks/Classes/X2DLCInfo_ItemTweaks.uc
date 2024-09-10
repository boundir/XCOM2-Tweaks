class X2DLCInfo_ItemTweaks extends X2DownloadableContentInfo;

var config(Ammo) int NULL_DMGMOD;
var config(Ammo) int NULL_NONPSIONIC_DMGMOD;

var config(GameData_SoldierSkills) array<name> UNIT_TYPE_AFFECTED_BY_BLUESCREENROUNDS_ORGANIC_DAMAGE;
var config(GameData_SoldierSkills) array<name> UNIT_TYPE_AFFECTED_BY_BLUESCREENROUNDS_ROBOTIC_DAMAGE;
var config(GameData_SoldierSkills) array<name> CLASSES_AFFECTED_BY_BLUESCREENROUNDS_ORGANIC_DAMAGE;
var config(GameData_SoldierSkills) array<name> CLASSES_AFFECTED_BY_BLUESCREENROUNDS_ROBOTIC_DAMAGE;

var config(GameData_SoldierSkills) array<name> UNIT_TYPE_AFFECTED_BY_NULLROUNDS_PSI_DAMAGE;
var config(GameData_SoldierSkills) array<name> UNIT_TYPE_AFFECTED_BY_NULLROUNDS_NON_PSI_DAMAGE;
var config(GameData_SoldierSkills) array<name> CLASSES_AFFECTED_BY_NULLROUNDS_PSI_DAMAGE;
var config(GameData_SoldierSkills) array<name> CLASSES_AFFECTED_BY_NULLROUNDS_NON_PSI_DAMAGE;

var config(GameData_WeaponData) array<name> CRIT_PSIONIC_WEAPONS;
var config(GameData_WeaponData) array<name> NO_MELEE_DAMAGE_ON_THROWN_WEAPONS;

var config(GameData_WeaponData) array<WeaponEnvironmentalDamageControl> WEAPON_ENVIRONMENTAL_DAMAGE;

static event OnPostTemplatesCreated()
{
	local X2ItemTemplateManager ItemTemplateManager;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	WarlockRifleGuaranteedCritDamage(ItemTemplateManager);
	RepeaterIncreaseCritDamage(ItemTemplateManager);

	BluescreenRoundsDamageUnitCondition(ItemTemplateManager);
	NullRoundsDamageUnitCondition(ItemTemplateManager);

	WeaponThrownDoNotApplyMeleeDamage(ItemTemplateManager);

	EnvironmentalDamageControl(ItemTemplateManager);
}

static function WarlockRifleGuaranteedCritDamage(X2ItemTemplateManager ItemTemplateManager)
{
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local name WeaponName;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	foreach default.CRIT_PSIONIC_WEAPONS(WeaponName)
	{
		ItemTemplateManager.FindDataTemplateAllDifficulties(WeaponName, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			WeaponTemplate = X2WeaponTemplate(DataTemplate);

			if (WeaponTemplate == none)
			{
				continue;
			}

			WeaponTemplate.Abilities.AddItem('DisruptorRifleCrit');
		}
	}
}

static function RepeaterIncreaseCritDamage(X2ItemTemplateManager ItemTemplateManager)
{
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local array<name> BetterRepeaterAbilities;
	local array<name> UpgradeNames;
	local name UpgradeName;
	local name AbilityName;
	local int AbilityIndex;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	AbilityIndex = 0;

	BetterRepeaterAbilities.AddItem('BetterRepeaterM1');
	BetterRepeaterAbilities.AddItem('BetterRepeaterM2');
	BetterRepeaterAbilities.AddItem('BetterRepeaterM3');

	UpgradeNames.AddItem('FreeKillUpgrade_Bsc');
	UpgradeNames.AddItem('FreeKillUpgrade_Adv');
	UpgradeNames.AddItem('FreeKillUpgrade_Sup');

	foreach UpgradeNames(UpgradeName)
	{
		ItemTemplateManager.FindDataTemplateAllDifficulties(UpgradeName, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			WeaponUpgradeTemplate = X2WeaponUpgradeTemplate(DataTemplate);

			if (WeaponUpgradeTemplate == none)
			{
				continue;
			}

			AbilityName = BetterRepeaterAbilities[AbilityIndex];
			WeaponUpgradeTemplate.FreeKillFn = NoFreeKill;

			WeaponUpgradeTemplate.BonusAbilities.AddItem(AbilityName);
		}

		AbilityIndex++;
	}
}

static function BluescreenRoundsDamageUnitCondition(X2ItemTemplateManager ItemTemplateManager)
{
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2AmmoTemplate AmmoTemplate;
	local X2Condition_UnitPropertyTweak NonRoboticUnitCondition;
	local X2Condition_UnitPropertyTweak RoboticUnitCondition;
	local WeaponDamageValue DamageValue;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	ItemTemplateManager.FindDataTemplateAllDifficulties('BluescreenRounds', DifficulityVariants);

	foreach DifficulityVariants(DataTemplate)
	{
		AmmoTemplate = X2AmmoTemplate(DataTemplate);

		if (AmmoTemplate == none)
		{
			continue;
		}

		AmmoTemplate.DamageModifiers.Length = 0;
		DamageValue.DamageType = 'Electrical';

		NonRoboticUnitCondition = new class'X2Condition_UnitPropertyTweak';
		NonRoboticUnitCondition.ExcludeRobotic = true;

		NonRoboticUnitCondition.IncludeTypes = default.UNIT_TYPE_AFFECTED_BY_BLUESCREENROUNDS_ORGANIC_DAMAGE;
		NonRoboticUnitCondition.IncludeSoldierClasses = default.CLASSES_AFFECTED_BY_BLUESCREENROUNDS_ORGANIC_DAMAGE;
		NonRoboticUnitCondition.ExcludeTypes = default.UNIT_TYPE_AFFECTED_BY_BLUESCREENROUNDS_ROBOTIC_DAMAGE;
		NonRoboticUnitCondition.ExcludeSoldierClasses = default.CLASSES_AFFECTED_BY_BLUESCREENROUNDS_ROBOTIC_DAMAGE;

		DamageValue.Damage = class'X2Item_DefaultAmmo'.default.BLUESCREEN_ORGANIC_DMGMOD;

		AmmoTemplate.AddAmmoDamageModifier(NonRoboticUnitCondition, DamageValue);

		RoboticUnitCondition = new class'X2Condition_UnitPropertyTweak';
		RoboticUnitCondition.ExcludeNonRobotic = true;

		RoboticUnitCondition.IncludeTypes = default.UNIT_TYPE_AFFECTED_BY_BLUESCREENROUNDS_ROBOTIC_DAMAGE;
		RoboticUnitCondition.IncludeSoldierClasses = default.CLASSES_AFFECTED_BY_BLUESCREENROUNDS_ROBOTIC_DAMAGE;
		RoboticUnitCondition.ExcludeTypes = default.UNIT_TYPE_AFFECTED_BY_BLUESCREENROUNDS_ORGANIC_DAMAGE;
		RoboticUnitCondition.ExcludeSoldierClasses = default.CLASSES_AFFECTED_BY_BLUESCREENROUNDS_ORGANIC_DAMAGE;

		DamageValue.Damage = class'X2Item_DefaultAmmo'.default.BLUESCREEN_DMGMOD;

		AmmoTemplate.AddAmmoDamageModifier(RoboticUnitCondition, DamageValue);
	}
}

static function NullRoundsDamageUnitCondition(X2ItemTemplateManager ItemTemplateManager)
{
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2AmmoTemplate AmmoTemplate;
	local X2Condition_UnitPropertyTweak NonPsionicUnitCondition;
	local X2Condition_UnitPropertyTweak PsionicUnitCondition;
	local WeaponDamageValue DamageValue;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	ItemTemplateManager.FindDataTemplateAllDifficulties('NullRounds', DifficulityVariants);

	foreach DifficulityVariants(DataTemplate)
	{
		AmmoTemplate = X2AmmoTemplate(DataTemplate);

		if (AmmoTemplate == none)
		{
			continue;
		}

		AmmoTemplate.DamageModifiers.Length = 0;
		DamageValue.DamageType = 'Psi';

		NonPsionicUnitCondition = new class'X2Condition_UnitPropertyTweak';
		NonPsionicUnitCondition.ExcludePsionic = true;

		NonPsionicUnitCondition.IncludeTypes = default.UNIT_TYPE_AFFECTED_BY_NULLROUNDS_NON_PSI_DAMAGE;
		NonPsionicUnitCondition.IncludeSoldierClasses = default.CLASSES_AFFECTED_BY_NULLROUNDS_NON_PSI_DAMAGE;
		NonPsionicUnitCondition.ExcludeTypes = default.UNIT_TYPE_AFFECTED_BY_NULLROUNDS_PSI_DAMAGE;
		NonPsionicUnitCondition.ExcludeSoldierClasses = default.CLASSES_AFFECTED_BY_NULLROUNDS_PSI_DAMAGE;

		DamageValue.Damage = default.NULL_NONPSIONIC_DMGMOD;

		AmmoTemplate.AddAmmoDamageModifier(NonPsionicUnitCondition, DamageValue);

		PsionicUnitCondition = new class'X2Condition_UnitPropertyTweak';
		PsionicUnitCondition.ExcludeNonPsionic = true;

		PsionicUnitCondition.IncludeTypes = default.UNIT_TYPE_AFFECTED_BY_NULLROUNDS_PSI_DAMAGE;
		PsionicUnitCondition.IncludeSoldierClasses = default.CLASSES_AFFECTED_BY_NULLROUNDS_PSI_DAMAGE;
		PsionicUnitCondition.ExcludeTypes = default.UNIT_TYPE_AFFECTED_BY_NULLROUNDS_NON_PSI_DAMAGE;
		PsionicUnitCondition.ExcludeSoldierClasses = default.CLASSES_AFFECTED_BY_NULLROUNDS_NON_PSI_DAMAGE;

		DamageValue.Damage = default.NULL_DMGMOD;

		AmmoTemplate.AddAmmoDamageModifier(PsionicUnitCondition, DamageValue);
	}
}

static function WeaponThrownDoNotApplyMeleeDamage(X2ItemTemplateManager ItemTemplateManager)
{
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local name WeaponName;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	foreach default.NO_MELEE_DAMAGE_ON_THROWN_WEAPONS(WeaponName)
	{
		ItemTemplateManager.FindDataTemplateAllDifficulties(WeaponName, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			WeaponTemplate = X2WeaponTemplate(DataTemplate);

			if (WeaponTemplate == none)
			{
				continue;
			}

			WeaponTemplate.BaseDamage.DamageType = 'DefaultProjectile';
			WeaponTemplate.DamageTypeTemplateName = 'DefaultProjectile';
		}
	}
}

static function EnvironmentalDamageControl(X2ItemTemplateManager ItemTemplateManager)
{
	local array<X2WeaponTemplate> WeaponTemplates;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local X2WeaponTemplate ChangeWeaponTemplate;
	local WeaponEnvironmentalDamageControl EnvironmentalDamageControl;
	local WeaponEnvironmentalDamageControlException EnvironmentalDamageControlException;
	local int ScanWeaponCategoryException;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	WeaponTemplates = ItemTemplateManager.GetAllWeaponTemplates();

	foreach WeaponTemplates(WeaponTemplate)
	{
		ItemTemplateManager.FindDataTemplateAllDifficulties(WeaponTemplate.DataName, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			ChangeWeaponTemplate = X2WeaponTemplate(DataTemplate);

			if (ChangeWeaponTemplate == none)
			{
				continue;
			}

			foreach default.WEAPON_ENVIRONMENTAL_DAMAGE(EnvironmentalDamageControl)
			{
				ScanWeaponCategoryException = EnvironmentalDamageControl.Exceptions.Find('Weapon', ChangeWeaponTemplate.DataName);

				if (ScanWeaponCategoryException != INDEX_NONE)
				{
					EnvironmentalDamageControlException = EnvironmentalDamageControl.Exceptions[ScanWeaponCategoryException];

					`Log("Changing Environmental Damage from" @ ChangeWeaponTemplate.iEnvironmentDamage @ "to" @ EnvironmentalDamageControlException.EnvironmentDamage @ "for template" @ ChangeWeaponTemplate.DataName, class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

					ChangeWeaponTemplate.iEnvironmentDamage = EnvironmentalDamageControlException.EnvironmentDamage;

					continue;
				}

				if (EnvironmentalDamageControl.WeaponCategory != ChangeWeaponTemplate.WeaponCat)
				{
					continue;
				}

				if (EnvironmentalDamageControl.Tech == '')
				{
					`Log("Changing Environmental Damage from" @ ChangeWeaponTemplate.iEnvironmentDamage @ "to" @ EnvironmentalDamageControl.EnvironmentDamage @ "for template" @ ChangeWeaponTemplate.DataName, class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

					ChangeWeaponTemplate.iEnvironmentDamage = EnvironmentalDamageControl.EnvironmentDamage;
				}
				else
				{
					if (ChangeWeaponTemplate.WeaponTech == EnvironmentalDamageControl.Tech)
					{
						`Log("Changing Environmental Damage from" @ ChangeWeaponTemplate.iEnvironmentDamage @ "to" @ EnvironmentalDamageControl.EnvironmentDamage @ "for template" @ ChangeWeaponTemplate.DataName, class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

						ChangeWeaponTemplate.iEnvironmentDamage = EnvironmentalDamageControl.EnvironmentDamage;
					}
				}
			}
		}
	}
}

function bool NoFreeKill(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Unit TargetUnit)
{
	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	return class'Helper_Tweaks'.static.ReturnFalse();
}
