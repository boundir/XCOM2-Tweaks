class X2DownloadableContentInfo_ItemTweaks extends X2DownloadableContentInfo;

var config(Ammo) int NULL_DMGMOD;
var config(Ammo) int NULL_NONPSIONIC_DMGMOD;

var config(GameData_SoldierSkills) array<name> UNIT_TYPE_AFFECTED_BY_BLUESCREENROUNDS_DAMAGE;
var config(GameData_SoldierSkills) array<name> UNIT_TYPE_UNAFFECTED_BY_BLUESCREENROUNDS_DAMAGE;
var config(GameData_SoldierSkills) array<name> CLASSES_UNAFFECTED_BY_BLUESCREENROUNDS_DAMAGE;
var config(GameData_SoldierSkills) array<name> CLASSES_AFFECTED_BY_BLUESCREENROUNDS_DAMAGE;

var config(GameData_SoldierSkills) array<name> UNIT_TYPE_AFFECTED_BY_NULLROUNDS_DAMAGE;
var config(GameData_SoldierSkills) array<name> UNIT_TYPE_UNAFFECTED_BY_NULLROUNDS_DAMAGE;
var config(GameData_SoldierSkills) array<name> CLASSES_AFFECTED_BY_NULLROUNDS_DAMAGE;
var config(GameData_SoldierSkills) array<name> CLASSES_UNAFFECTED_BY_NULLROUNDS_DAMAGE;

static event OnPostTemplatesCreated()
{
	WarlockRifleGuaranteedCritDamage('ChosenRifle_CV');
	WarlockRifleGuaranteedCritDamage('ChosenRifle_MG');
	WarlockRifleGuaranteedCritDamage('ChosenRifle_BM');
	WarlockRifleGuaranteedCritDamage('ChosenRifle_T4');

	RepeaterIncreaseCritDamage('FreeKillUpgrade_Bsc');
	RepeaterIncreaseCritDamage('FreeKillUpgrade_Adv');
	RepeaterIncreaseCritDamage('FreeKillUpgrade_Sup');

	BluescreenRoundsDamageUnitCondition();
	NullRoundsDamageUnitCondition();

	WeaponThrownDoNotApplyMeleeDamage('AlienHunterAxeThrown_CV');
	WeaponThrownDoNotApplyMeleeDamage('AlienHunterAxeThrown_MG');
	WeaponThrownDoNotApplyMeleeDamage('AlienHunterAxeThrown_BM');
	WeaponThrownDoNotApplyMeleeDamage('IRI_ChosenThrowingKnife');
}

static function WarlockRifleGuaranteedCritDamage(name WeaponName)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2WeaponTemplate WeaponTemplate;

	ItemTemplateManager = `GetItemMngr;

	ItemTemplateManager.FindDataTemplateAllDifficulties(WeaponName, DifficulityVariants);

	foreach DifficulityVariants(DataTemplate)
	{
		WeaponTemplate = X2WeaponTemplate(DataTemplate);

		if(WeaponTemplate != none)
		{
			WeaponTemplate.Abilities.AddItem('DisruptorRifleCrit');
		}
	}
}

static function RepeaterIncreaseCritDamage(name UpgradeName)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local name AbilityName;
	local int WeaponUpgradeLevel;

	WeaponUpgradeLevel = 1;
	ItemTemplateManager = `GetItemMngr;

	ItemTemplateManager.FindDataTemplateAllDifficulties(UpgradeName, DifficulityVariants);

	foreach DifficulityVariants(DataTemplate)
	{
		WeaponUpgradeTemplate = X2WeaponUpgradeTemplate(DataTemplate);

		if(WeaponUpgradeTemplate != none)
		{
			AbilityName = name('BetterRepeaterM' $ WeaponUpgradeLevel);
			WeaponUpgradeTemplate.FreeKillFn = NoFreeKill;

			WeaponUpgradeTemplate.BonusAbilities.AddItem(AbilityName);
			WeaponUpgradeLevel++;
		}
	}
}

function bool NoFreeKill(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Unit TargetUnit)
{
	return class'Helper_Tweaks'.static.ReturnFalse();
}

static function BluescreenRoundsDamageUnitCondition()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2AmmoTemplate AmmoTemplate;
	local X2Condition_UnitPropertyTweak Condition_UnitProperty;
	local WeaponDamageValue DamageValue;
	local name UnitType, UnitClass;

	ItemTemplateManager = `GetItemMngr;

	ItemTemplateManager.FindDataTemplateAllDifficulties('BluescreenRounds', DifficulityVariants);

	foreach DifficulityVariants(DataTemplate)
	{
		AmmoTemplate = X2AmmoTemplate(DataTemplate);

		if(AmmoTemplate != none)
		{
			AmmoTemplate.DamageModifiers.Length = 0;
			DamageValue.DamageType = 'Electrical';

			NonRoboticUnitCondition = new class'X2Condition_UnitPropertyTweak';
			NonRoboticUnitCondition.ExcludeRobotic = true;

			class'Helper_Tweaks'.static.FillUnitConditionFromConfig(NonRoboticUnitCondition,
				default.UNIT_TYPE_UNAFFECTED_BY_BLUESCREENROUNDS_DAMAGE,
				default.CLASSES_UNAFFECTED_BY_BLUESCREENROUNDS_DAMAGE
			);

			DamageValue.Damage = class'X2Item_DefaultAmmo'.default.BLUESCREEN_ORGANIC_DMGMOD;

			AmmoTemplate.AddAmmoDamageModifier(NonRoboticUnitCondition, DamageValue);

			RoboticUnitCondition = new class'X2Condition_UnitPropertyTweak';
			RoboticUnitCondition.ExcludeNonRobotic = true;

			class'Helper_Tweaks'.static.FillUnitConditionFromConfig(RoboticUnitCondition,
				default.UNIT_TYPE_AFFECTED_BY_BLUESCREENROUNDS_DAMAGE,
				default.CLASSES_AFFECTED_BY_BLUESCREENROUNDS_DAMAGE
			);

			DamageValue.Damage = class'X2Item_DefaultAmmo'.default.BLUESCREEN_DMGMOD;

			AmmoTemplate.AddAmmoDamageModifier(RoboticUnitCondition, DamageValue);
		}
	}
}

static function NullRoundsDamageUnitCondition()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2AmmoTemplate AmmoTemplate;
	local X2Condition_UnitPropertyTweak UnitProperty;
	local WeaponDamageValue DamageValue;
	local name UnitType, UnitClass;

	ItemTemplateManager = `GetItemMngr;

	ItemTemplateManager.FindDataTemplateAllDifficulties('NullRounds', DifficulityVariants);

	foreach DifficulityVariants(DataTemplate)
	{
		AmmoTemplate = X2AmmoTemplate(DataTemplate);

		if(AmmoTemplate != none)
		{
			AmmoTemplate.DamageModifiers.Length = 0;
			DamageValue.DamageType = 'Psi';

			NonPsionicUnitCondition = new class'X2Condition_UnitPropertyTweak';
			NonPsionicUnitCondition.ExcludePsionic = true;

			class'Helper_Tweaks'.static.FillUnitConditionFromConfig(NonPsionicUnitCondition,
				default.UNIT_TYPE_UNAFFECTED_BY_NULLROUNDS_DAMAGE,
				default.CLASSES_UNAFFECTED_BY_NULLROUNDS_DAMAGE
			);

			DamageValue.Damage = default.NULL_NONPSIONIC_DMGMOD;

			AmmoTemplate.AddAmmoDamageModifier(NonPsionicUnitCondition, DamageValue);

			PsionicUnitCondition = new class'X2Condition_UnitPropertyTweak';
			PsionicUnitCondition.ExcludeNonPsionic = true;

			class'Helper_Tweaks'.static.FillUnitConditionFromConfig(PsionicUnitCondition,
				default.UNIT_TYPE_AFFECTED_BY_NULLROUNDS_DAMAGE,
				default.CLASSES_AFFECTED_BY_NULLROUNDS_DAMAGE
			);

			DamageValue.Damage = default.NULL_DMGMOD;

			AmmoTemplate.AddAmmoDamageModifier(PsionicUnitCondition, DamageValue);
		}
	}
}

static function WeaponThrownDoNotApplyMeleeDamage(name WeaponName)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2WeaponTemplate WeaponTemplate;

	ItemTemplateManager = `GetItemMngr;

	ItemTemplateManager.FindDataTemplateAllDifficulties(WeaponName, DifficulityVariants);

	foreach DifficulityVariants(DataTemplate)
	{
		WeaponTemplate = X2WeaponTemplate(DataTemplate);

		if(WeaponTemplate != none)
		{
			WeaponTemplate.BaseDamage.DamageType = 'DefaultProjectile';
			WeaponTemplate.DamageTypeTemplateName = 'DefaultProjectile';
		}
	}
}
