class X2Helper_TemplateTweaks extends Object config(Game);

struct BetaStrikeModifier
{
	var Name TemplateName;
	var Float BetaStrikeMod;
};

struct StatBoostCap
{
	var ECharStatType StatType;
	var float StatCap;
	var name BoostName;
};

var config(GameData) array<name> DISABLE_DARK_EVENTS;
var config(GameData) array<StatBoostCap> STAT_BOOST_CAP;

var config(GameData_SoldierSkills) float REVEAL_RANGE_METERS;
var config(GameData_SoldierSkills) array<name> VANISH_ABILITIES;
var config(GameData_SoldierSkills) array<BetaStrikeModifier> BETA_STRIKE_CHARACTERS;

var config(GameData_SoldierSkills) array<name> BLUESCREENROUNDS_DAMAGE_EXCLUDE_TYPE;
var config(GameData_SoldierSkills) array<name> BLUESCREENROUNDS_DAMAGE_INCLUDE_CLASS;
var config(GameData_SoldierSkills) array<name> NULLROUNDS_DAMAGE_EXCLUDE_TYPE;
var config(GameData_SoldierSkills) array<name> NULLROUNDS_DAMAGE_INCLUDE_CLASS;

var config(GameData_SoldierSkills) array<name> DISRUPTOR_EXCLUDE_TYPE;
var config(GameData_SoldierSkills) array<name> DISRUPTOR_INCLUDE_CLASS;

var config(Ammo) int NULL_DMGMOD;
var config(Ammo) int NULL_NONPSIONIC_DMGMOD;


// ========================
// #   STRATEGY CHANGES   #
// ========================

static function DisableDarkEvents()
{
	local X2StrategyElementTemplateManager StrategyTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2DarkEventTemplate DarkEventTemplate;
	local name DarkEventName;

	StrategyTemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	foreach default.DISABLE_DARK_EVENTS(DarkEventName)
	{
		StrategyTemplateManager.FindDataTemplateAllDifficulties(DarkEventName, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			DarkEventTemplate = X2DarkEventTemplate(DataTemplate);

			if(DarkEventTemplate != none)
			{
				DarkEventTemplate.CanActivateFn = CantActivate;
			}
		}
	}
}

static function bool CantActivate(XComGameState_DarkEvent DarkEventState)
{
	return ReturnFalse();
}

static function ExcludeRulersFromSitrep(Name SitRepName)
{
	local X2SitRepTemplate SitRepTemplate;
	local AlienRulerData RulerData;
	local AlienRulerAdditionalTags AdditionalTag;

	SitRepTemplate = class'X2SitRepTemplateManager'.static.GetSitRepTemplateManager().FindSitRepTemplate(SitRepName);

	foreach class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates(RulerData)
	{
		// Check if we already have the tag excluded.
		if(SitRepTemplate.ExcludeGameplayTags.Find(RulerData.ActiveTacticalTag) != INDEX_NONE)
		{
			continue;
		}

		SitRepTemplate.ExcludeGameplayTags.AddItem(RulerData.ActiveTacticalTag);

		foreach RulerData.AdditionalTags(AdditionalTag)
		{
			SitRepTemplate.ExcludeGameplayTags.AddItem(AdditionalTag.TacticalTag);
		}
	}
}


// ====================
// #   ITEM CHANGES   #
// ====================

static function PatchWeaponThrown()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local array<Name> arrAxes;
	local int idx;

	arrAxes.AddItem('AlienHunterAxeThrown_CV');
	arrAxes.AddItem('AlienHunterAxeThrown_MG');
	arrAxes.AddItem('AlienHunterAxeThrown_BM');
	arrAxes.AddItem('IRI_ChosenThrowingKnife');

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	for( idx = 0; idx < arrAxes.Length; idx++ )
	{
		ItemTemplateManager.FindDataTemplateAllDifficulties(arrAxes[idx], DifficulityVariants);

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
}

static function PatchBluescreenRoundsDamageCondition()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2AmmoTemplate AmmoTemplate;
	local X2Condition_UnitPropertyTweak Condition_UnitProperty;
	local WeaponDamageValue DamageValue;
	local name UnitType, UnitClass;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	ItemTemplateManager.FindDataTemplateAllDifficulties('BluescreenRounds', DifficulityVariants);

	foreach DifficulityVariants(DataTemplate)
	{
		AmmoTemplate = X2AmmoTemplate(DataTemplate);

		if(AmmoTemplate != none)
		{
			AmmoTemplate.DamageModifiers.Length = 0;
			DamageValue.DamageType = 'Electrical';

			// Bluescreen rounds organic damages
			Condition_UnitProperty = new class'X2Condition_UnitPropertyTweak';
			Condition_UnitProperty.ExcludeRobotic = true;

			foreach default.BLUESCREENROUNDS_DAMAGE_EXCLUDE_TYPE(UnitType)
			{
				Condition_UnitProperty.IncludeTypes.AddItem(UnitType);
			}

			foreach default.BLUESCREENROUNDS_DAMAGE_INCLUDE_CLASS(UnitClass)
			{
				Condition_UnitProperty.IncludeSoldierClasses.AddItem(UnitClass);
			}

			DamageValue.Damage = class'X2Item_DefaultAmmo'.default.BLUESCREEN_ORGANIC_DMGMOD;

			AmmoTemplate.AddAmmoDamageModifier(Condition_UnitProperty, DamageValue);

			// Bluescreen rounds robotic damages
			Condition_UnitProperty = new class'X2Condition_UnitPropertyTweak';
			Condition_UnitProperty.ExcludeNonRobotic = true;

			foreach default.BLUESCREENROUNDS_DAMAGE_EXCLUDE_TYPE(UnitType)
			{
				Condition_UnitProperty.ExcludeTypes.AddItem(UnitType);
			}

			foreach default.BLUESCREENROUNDS_DAMAGE_INCLUDE_CLASS(UnitClass)
			{
				Condition_UnitProperty.IncludeSoldierClasses.AddItem(UnitClass);
			}

			DamageValue.Damage = class'X2Item_DefaultAmmo'.default.BLUESCREEN_DMGMOD;

			AmmoTemplate.AddAmmoDamageModifier(Condition_UnitProperty, DamageValue);
		}
	}
}

static function PatchNullRoundsDamageCondition()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2AmmoTemplate AmmoTemplate;
	local X2Condition_UnitPropertyTweak UnitProperty;
	local WeaponDamageValue DamageValue;
	local name UnitType, UnitClass;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	ItemTemplateManager.FindDataTemplateAllDifficulties('NullRounds', DifficulityVariants);

	foreach DifficulityVariants(DataTemplate)
	{
		AmmoTemplate = X2AmmoTemplate(DataTemplate);

		if(AmmoTemplate != none)
		{
			AmmoTemplate.DamageModifiers.Length = 0;
			DamageValue.DamageType = 'Psi';

			// Null Rounds non psionic damages
			UnitProperty = new class'X2Condition_UnitPropertyTweak';
			UnitProperty.ExcludePsionic = true;

			foreach default.NULLROUNDS_DAMAGE_EXCLUDE_TYPE(UnitType)
			{
				UnitProperty.IncludeTypes.AddItem(UnitType);
			}

			foreach default.NULLROUNDS_DAMAGE_INCLUDE_CLASS(UnitClass)
			{
				UnitProperty.IncludeSoldierClasses.AddItem(UnitClass);
			}

			DamageValue.Damage = default.NULL_NONPSIONIC_DMGMOD;

			AmmoTemplate.AddAmmoDamageModifier(UnitProperty, DamageValue);

			// Null Rounds psionic damages
			UnitProperty = new class'X2Condition_UnitPropertyTweak';
			UnitProperty.ExcludeNonPsionic = true;

			foreach default.NULLROUNDS_DAMAGE_EXCLUDE_TYPE(UnitType)
			{
				UnitProperty.ExcludeTypes.AddItem(UnitType);
			}

			foreach default.NULLROUNDS_DAMAGE_INCLUDE_CLASS(UnitClass)
			{
				UnitProperty.IncludeSoldierClasses.AddItem(UnitClass);
			}

			DamageValue.Damage = default.NULL_DMGMOD;

			AmmoTemplate.AddAmmoDamageModifier(UnitProperty, DamageValue);
		}
	}
}

static function BetterRepeater()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local array<Name> arrUpgrades;
	local name UpgradeName, AbilityName;
	local int idx;

	arrUpgrades.AddItem('FreeKillUpgrade_Bsc');
	arrUpgrades.AddItem('FreeKillUpgrade_Adv');
	arrUpgrades.AddItem('FreeKillUpgrade_Sup');

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach arrUpgrades(UpgradeName, idx)
	{
		ItemTemplateManager.FindDataTemplateAllDifficulties(UpgradeName, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			WeaponUpgradeTemplate = X2WeaponUpgradeTemplate(DataTemplate);

			if(WeaponUpgradeTemplate != none)
			{
				AbilityName = name('BetterRepeaterM' $ idx+1);
				WeaponUpgradeTemplate.FreeKillFn = NoFreeKill;

				WeaponUpgradeTemplate.BonusAbilities.AddItem(AbilityName);
			}
		}
	}
}

function bool NoFreeKill(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Unit TargetUnit)
{
	return ReturnFalse();
}

static function PatchWarlockRifle()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local array<Name> arrWarlockRifles;
	local name WeaponName;

	arrWarlockRifles.AddItem('ChosenRifle_CV');
	arrWarlockRifles.AddItem('ChosenRifle_MG');
	arrWarlockRifles.AddItem('ChosenRifle_BM');
	arrWarlockRifles.AddItem('ChosenRifle_T4');

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach arrWarlockRifles(WeaponName)
	{
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
}

static function CapSoldierStatBoostRewards()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2EquipmentTemplate EquipmentTemplate;
	local StatBoostCap Boost;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach default.STAT_BOOST_CAP(Boost)
	{
		ItemTemplateManager.FindDataTemplateAllDifficulties(Boost.BoostName, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			EquipmentTemplate = X2EquipmentTemplate(DataTemplate);

			if(EquipmentTemplate != none)
			{
				EquipmentTemplate.OnAcquiredFn = ApplyStatBoostIfAllowed;
			}
		}
	}
}

static function bool ApplyStatBoostIfAllowed(XComGameState NewGameState, XComGameState_Item ItemState)
{
	local XComGameState_Unit UnitState;
	local StatBoost ItemStatBoost;
	local float NewMaxStat;
	
	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ItemState.LinkedEntity.ObjectID));
	if (UnitState == none)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ItemState.LinkedEntity.ObjectID));
	}
	
	if (UnitState == none)
	{
		// Should not happen if the item is set up as a reward properly
		`RedScreen("Tried to give a stat boost item, but there is no linked unit to increase stats @gameplay @jweinhoffer");
		return false;
	}

	foreach ItemState.StatBoosts(ItemStatBoost)
	{
		NewMaxStat = int(UnitState.GetMaxStat(ItemStatBoost.StatType) + ItemStatBoost.Boost);

		if ((ItemStatBoost.StatType == eStat_HP) && `SecondWaveEnabled('BetaStrike'))
		{
			NewMaxStat += ItemStatBoost.Boost * (class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod - 1.0);
		}

		if(isUnitStatCapped(ItemStatBoost.StatType, NewMaxStat))
		{
			NewMaxStat = GetStatCapAmount(ItemStatBoost.StatType);
		}

		UnitState.SetBaseMaxStat(ItemStatBoost.StatType, NewMaxStat);
		
		if (ItemStatBoost.StatType != eStat_HP || !UnitState.IsInjured())
		{
			UnitState.SetCurrentStat(ItemStatBoost.StatType, NewMaxStat);
		}
	}

	return true;
}

static function bool isUnitStatCapped(ECharStatType StatType, float StatAmount)
{
	local float StatCap;

	StatCap = GetStatCapAmount(StatType);

	if(StatAmount >= StatCap && StatCap != 0.0)
	{
		return true;
	}

	return false;
}

static function float GetStatCapAmount(ECharStatType StatType)
{
	local int Index;
	local float StatCap;

	StatCap = 0.0;
	Index = default.STAT_BOOST_CAP.Find('StatType', StatType);

	if(Index == INDEX_NONE)
	{
		return StatCap;
	}

	return default.STAT_BOOST_CAP[Index].StatCap;
}

// =======================
// #   ABILITY CHANGES   #
// =======================

static function PatchRageStrike()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityToHitCalc_StandardMelee StandardMelee;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	AbilityTemplateManager.FindDataTemplateAllDifficulties('Ragestrike', DifficulityVariants);

	foreach DifficulityVariants(DataTemplate)
	{
		AbilityTemplate = X2AbilityTemplate(DataTemplate);

		if (AbilityTemplate != none)
		{
			StandardMelee = new class'X2AbilityToHitCalc_StandardMelee';
			StandardMelee.bGuaranteedHit = true;
			AbilityTemplate.AbilityToHitCalc = StandardMelee;
		}
	}
}

static function PatchJustice()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect TempEffect;
	local X2Effect_ApplyWeaponDamage WeaponEffect;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	AbilityTemplateManager.FindDataTemplateAllDifficulties('Justice', DifficulityVariants);

	foreach DifficulityVariants(DataTemplate)
	{
		AbilityTemplate = X2AbilityTemplate(DataTemplate);

		if(AbilityTemplate != none)
		{
			foreach AbilityTemplate.AbilityTargetEffects(TempEffect)
			{
				if(TempEffect != none )
				{
					if( TempEffect.IsA('X2Effect_ApplyWeaponDamage') )
					{
						WeaponEffect = X2Effect_ApplyWeaponDamage(TempEffect);
						WeaponEffect.EnvironmentalDamageAmount = 3;
					}
				}
			}
		}
	}
}


static function PatchSuppression()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local X2Condition_UnitEffects UnitEffects;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	AbilityTemplateManager.FindDataTemplateAllDifficulties('Suppression', DifficulityVariants);

	foreach DifficulityVariants(DataTemplate)
	{
		AbilityTemplate = X2AbilityTemplate(DataTemplate);

		if(AbilityTemplate != none)
		{
			UnitEffects = new class'X2Condition_UnitEffects';
			UnitEffects.AddExcludeEffect('Shadowstep', 'AA_UnitIsImmune');
			AbilityTemplate.AbilityTargetConditions.AddItem(UnitEffects);
		}
	}
}

static function PatchRemoveSuppressionEffect()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect_RemoveEffects RemoveSuppression;
	local array<Name> arrAbilities;
	local Name AbilityName;

	arrAbilities.AddItem('Stasis');
	arrAbilities.AddItem('PriestStasis');
	arrAbilities.AddItem('SustainTriggered');
	arrAbilities.AddItem('Teleport');

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	foreach arrAbilities(AbilityName)
	{
		AbilityTemplateManager.FindDataTemplateAllDifficulties(AbilityName, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			AbilityTemplate = X2AbilityTemplate(DataTemplate);

			if(AbilityTemplate != none)
			{
				RemoveSuppression = new class'X2Effect_RemoveEffects';
				RemoveSuppression.EffectNamesToRemove.AddItem(class'X2Effect_Suppression'.default.EffectName);
				RemoveSuppression.bCheckSource = true;
				RemoveSuppression.bCleanse = true;
				RemoveSuppression.SetupEffectOnShotContextResult(true, true);

				AbilityTemplate.AddTargetEffect(RemoveSuppression);

				if(AbilityTemplate.DataName == 'Teleport')
				{
					AbilityTemplate.AddShooterEffect(RemoveSuppression);
					AbilityTemplate.ConcealmentRule = eConceal_Always;
				}
			}
		}
	}
}

static function PatchCantDoIfSuppressed()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local X2Condition_UnitEffects SuppressedCondition;
	local array<Name> arrAbilities;
	local Name AbilityName;

	arrAbilities.AddItem('Suppression');
	arrAbilities.AddItem('Stealth');
	arrAbilities.AddItem('Vanish');
	arrAbilities.AddItem('SitRepStealth');
	arrAbilities.AddItem('Shadow');
	arrAbilities.AddItem('DistractionShadow');
	arrAbilities.AddItem('RefractionFieldAbility');

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	foreach arrAbilities(AbilityName)
	{
		AbilityTemplateManager.FindDataTemplateAllDifficulties(AbilityName, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			AbilityTemplate = X2AbilityTemplate(DataTemplate);

			if(AbilityTemplate != none)
			{
				SuppressedCondition = new class'X2Condition_UnitEffects';
				SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
				SuppressedCondition.AddExcludeEffect(class'X2Effect_SkirmisherInterrupt'.default.EffectName, 'AA_AbilityUnavailable');

				AbilityTemplate.AbilityShooterConditions.AddItem(SuppressedCondition);
				// AbilityTemplate.AbilityTargetConditions.AddItem(SuppressedCondition);
			}
		}
	}
}

static function PatchBullRush()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local X2Condition_OnTeamTurn TurnCondition;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	AbilityTemplateManager.FindDataTemplateAllDifficulties('EUBullRush', DifficulityVariants);

	foreach DifficulityVariants(DataTemplate)
	{
		AbilityTemplate = X2AbilityTemplate(DataTemplate);

		if(AbilityTemplate != none)
		{
			TurnCondition = new class'X2Condition_OnTeamTurn';
			AbilityTemplate.AbilityShooterConditions.AddItem(TurnCondition);
		}
	}
}

static function PatchRulerPauseTimer()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect_SuspendMissionTimer MissionTimerEffect;
	local X2Effect_SetUnitValue SetUnitValue;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	AbilityTemplateManager.FindDataTemplateAllDifficulties('AlienRulerEscape', DifficulityVariants);

	foreach DifficulityVariants(DataTemplate)
	{
		AbilityTemplate = X2AbilityTemplate(DataTemplate);

		if(AbilityTemplate != none)
		{
			MissionTimerEffect = new class'X2Effect_SuspendMissionTimer';
			MissionTimerEffect.bResumeMissionTimer = true;
			AbilityTemplate.AddShooterEffect(MissionTimerEffect);

			SetUnitValue = new class'X2Effect_SetUnitValue';
			SetUnitValue.UnitName = class'X2Ability_Tweaks'.default.RULER_STATE;
			SetUnitValue.NewValueToSet = class'X2Ability_Tweaks'.default.RULER_DISABLED;
			SetUnitValue.CleanupType = eCleanup_BeginTactical;
			AbilityTemplate.AddShooterEffect(SetUnitValue);
		}
	}
}

static function PatchPounce()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local X2Condition_UnitProperty ShooterCondition;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	AbilityTemplateManager.FindDataTemplateAllDifficulties('PounceTrigger', DifficulityVariants);

	foreach DifficulityVariants(DataTemplate)
	{
		AbilityTemplate = X2AbilityTemplate(DataTemplate);

		if(AbilityTemplate != none)
		{
			ShooterCondition = new class'X2Condition_UnitProperty';
			ShooterCondition.ExcludeConcealed = true;
			AbilityTemplate.AbilityShooterConditions.AddItem(ShooterCondition);
		}
	}
}

static function PatchDisruptorRifleAbility()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local X2Condition_UnitPropertyTweak UnitProperty;
	local X2Effect_ToHitModifier PersistentEffect;
	local name UnitType, UnitClass;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	AbilityTemplateManager.FindDataTemplateAllDifficulties('DisruptorRifleCrit', DifficulityVariants);

	foreach DifficulityVariants(DataTemplate)
	{
		AbilityTemplate = X2AbilityTemplate(DataTemplate);

		if(AbilityTemplate != none)
		{
			AbilityTemplate.AbilityTargetEffects.Length = 0;

			UnitProperty = new class'X2Condition_UnitPropertyTweak';
			UnitProperty.ExcludeNonPsionic = true;

			foreach default.DISRUPTOR_EXCLUDE_TYPE(UnitType)
			{
				UnitProperty.ExcludeTypes.AddItem(UnitType);
			}

			foreach default.DISRUPTOR_INCLUDE_CLASS(UnitClass)
			{
				UnitProperty.IncludeSoldierClasses.AddItem(UnitClass);
			}

			PersistentEffect = new class'X2Effect_ToHitModifier';
			PersistentEffect.DuplicateResponse = eDupe_Ignore;
			PersistentEffect.BuildPersistentEffect(1, true, false);
			PersistentEffect.AddEffectHitModifier(
				eHit_Crit, 
				class'X2Ability_XPackAbilitySet'.default.DISRUPTOR_RIFLE_PSI_CRIT, 
				class'X2Ability_XPackAbilitySet'.default.DisruptorRifleCritDisplayText,
				,,,,,,,
				true);
			PersistentEffect.ToHitConditions.AddItem(UnitProperty);

			AbilityTemplate.AddTargetEffect(PersistentEffect);
		}
	}
}

static function PatchBetaStrike()
{
	local X2CharacterTemplateManager CharacterTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2CharacterTemplate CharacterTemplate;
	local BetaStrikeModifier Character;

	CharacterTemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	foreach default.BETA_STRIKE_CHARACTERS(Character)
	{
		CharacterTemplateManager.FindDataTemplateAllDifficulties(Character.TemplateName, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			CharacterTemplate = X2CharacterTemplate(DataTemplate);

			if(CharacterTemplate != none)
			{
				CharacterTemplate.OnStatAssignmentCompleteFn = BetastrikeHPMod;
			}
		}
	}
}

function BetastrikeHPMod(XComGameState_Unit UnitState)
{
	local float CurrentHealthMax;
	local UnitValue UnitValue;
	local int Idx;
	
	if( !`SecondWaveEnabled('BetaStrike') )
	{
		return;
	}

	if( !UnitState.GetUnitValue('Betastrikemod', UnitValue) )
	{
		UnitState.SetUnitFloatValue('Betastrikemod', 1, eCleanup_Never);
		return;
	}

	if (UnitValue.fValue ~= 2)
	{
		return;
	}

	Idx = default.BETA_STRIKE_CHARACTERS.Find('TemplateName', UnitState.GetMyTemplateName());

	if (Idx != INDEX_NONE)
	{
		CurrentHealthMax = UnitState.GetMaxStat(eStat_HP);
		UnitState.SetBaseMaxStat(eStat_HP, Round(CurrentHealthMax * default.BETA_STRIKE_CHARACTERS[Idx].BetastrikeMod));
		UnitState.SetCurrentStat(eStat_HP, UnitState.GetMaxStat(eStat_HP));
		UnitState.SetUnitFloatValue('Betastrikemod', 2, eCleanup_Never);
	}
}

static function PatchRulersTimer()
{
	local X2CharacterTemplateManager CharacterTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2CharacterTemplate CharacterTemplate;
	local AlienRulerData RulerData;

	CharacterTemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	foreach class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates(RulerData)
	{
		CharacterTemplateManager.FindDataTemplateAllDifficulties(RulerData.AlienRulerTemplateName, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			CharacterTemplate = X2CharacterTemplate(DataTemplate);

			if(CharacterTemplate != none)
			{
				CharacterTemplate.Abilities.AddItem('ResumeTimer');
				CharacterTemplate.Abilities.AddItem('PauseTimer');
			}
		}
	}
}

static function bool ReturnFalse()
{
	return false;
}
