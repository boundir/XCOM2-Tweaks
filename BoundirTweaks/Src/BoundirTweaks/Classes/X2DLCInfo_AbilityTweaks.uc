class X2DLCInfo_AbilityTweaks extends X2DownloadableContentInfo;

var config(GameData_SoldierSkills) array<name> UNIT_TYPE_UNAFFECTED_BY_DISRUPTOR_GUARANTEED_CRIT;
var config(GameData_SoldierSkills) array<name> CLASSES_AFFECTED_BY_DISRUPTOR_GUARANTEED_CRIT;

var config(GameData_SoldierSkills) array<name> ABILITY_UNAVAILABLE_UNDER_SUPPRESSION;
var config(GameData_SoldierSkills) array<name> ABILITY_REMOVE_SUPPRESSION;
var config(GameData_SoldierSkills) array<name> ABILITY_IGNORE_BASE_WEAPON_DAMAGE;

var config(GameData_SoldierSkills) array<AbilityEnvironmentalDamageControl> ABILITY_ENVIRONMENTAL_DAMAGE;

static event OnPostTemplatesCreated()
{
	local X2AbilityTemplateManager AbilityTemplateManager;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	RageStrikeIsMeleeAttack(AbilityTemplateManager);
	ControlAbilityEnvironmentalDamage(AbilityTemplateManager);

	RemoveSuppressionEffectOnAbilityTriggered(AbilityTemplateManager);
	CantUseAbilityUnderSuppression(AbilityTemplateManager);

	ReworkEUBerserkerBullRush(AbilityTemplateManager);
	DisruptorRifleCritUnitCondition(AbilityTemplateManager);
	RulerResumeTimerOnEscape(AbilityTemplateManager);
	PounceDontTriggerIfConcealed(AbilityTemplateManager);

	RecreateDevastatingPunchAtMeleeRange(AbilityTemplateManager);
	RecreateBladestormAssassinAttack(AbilityTemplateManager);

	FeedbackCanOnlyTriggerOnce(AbilityTemplateManager);
	IgnoreBaseWeaponDamage(AbilityTemplateManager);
}

static function RageStrikeIsMeleeAttack(X2AbilityTemplateManager AbilityTemplateManager)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityToHitCalc_StandardMelee StandardMelee;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('Ragestrike');

	if (AbilityTemplate == none)
	{
		return;
	}

	StandardMelee = new class'X2AbilityToHitCalc_StandardMelee';
	StandardMelee.bGuaranteedHit = true;
	AbilityTemplate.AbilityToHitCalc = StandardMelee;
}

static function ControlAbilityEnvironmentalDamage(X2AbilityTemplateManager AbilityTemplateManager)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect Effect;
	local X2Effect_ApplyWeaponDamage WeaponEffect;
	local AbilityEnvironmentalDamageControl EnvironmentalDamageControl;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	foreach default.ABILITY_ENVIRONMENTAL_DAMAGE(EnvironmentalDamageControl)
	{
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(EnvironmentalDamageControl.AbilityName);

		if (AbilityTemplate == none)
		{
			continue;
		}

		foreach AbilityTemplate.AbilityTargetEffects(Effect)
		{
			WeaponEffect = X2Effect_ApplyWeaponDamage(Effect);

			if (WeaponEffect == none)
			{
				continue;
			}

			WeaponEffect.EnvironmentalDamageAmount = EnvironmentalDamageControl.EnvironmentDamage;

			`Log("Changing Environmental Damage from" @ WeaponEffect.EnvironmentalDamageAmount @ "to" @ EnvironmentalDamageControl.EnvironmentDamage @ "for template" @ AbilityTemplate.DataName, class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
		}
	}
}

static function RemoveSuppressionEffectOnAbilityTriggered(X2AbilityTemplateManager AbilityTemplateManager)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect_RemoveEffects RemoveSuppression;
	local name AbilityName;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	foreach default.ABILITY_REMOVE_SUPPRESSION(AbilityName)
	{
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName);

		if (AbilityTemplate == none)
		{
			return;
		}

		RemoveSuppression = new class'X2Effect_RemoveEffects';
		RemoveSuppression.EffectNamesToRemove.AddItem(class'X2Effect_Suppression'.default.EffectName);
		RemoveSuppression.bCheckSource = true;
		RemoveSuppression.bCleanse = true;
		RemoveSuppression.SetupEffectOnShotContextResult(true, true);

		AbilityTemplate.AddTargetEffect(RemoveSuppression);

		if (AbilityTemplate.DataName == 'Teleport')
		{
			AbilityTemplate.AddShooterEffect(RemoveSuppression);
			AbilityTemplate.ConcealmentRule = eConceal_Always;
		}
	}
}

static function CantUseAbilityUnderSuppression(X2AbilityTemplateManager AbilityTemplateManager)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2Condition_UnitEffects SuppressedCondition;
	local name AbilityName;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	foreach default.ABILITY_UNAVAILABLE_UNDER_SUPPRESSION(AbilityName)
	{
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName);

		if (AbilityTemplate == none)
		{
			continue;
		}

		SuppressedCondition = new class'X2Condition_UnitEffects';
		SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
		SuppressedCondition.AddExcludeEffect(class'X2Effect_SkirmisherInterrupt'.default.EffectName, 'AA_AbilityUnavailable');

		AbilityTemplate.AbilityShooterConditions.AddItem(SuppressedCondition);
	}
}

static function ReworkEUBerserkerBullRush(X2AbilityTemplateManager AbilityTemplateManager)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2Condition_OnTeamTurn TeamTurnCondition;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('EUBullRush');

	if (AbilityTemplate == none)
	{
		return;
	}

	TeamTurnCondition = new class'X2Condition_OnTeamTurn';
	TeamTurnCondition.Team = eTeam_XCom;
	AbilityTemplate.AbilityShooterConditions.AddItem(TeamTurnCondition);
}

static function DisruptorRifleCritUnitCondition(X2AbilityTemplateManager AbilityTemplateManager)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2Condition_UnitPropertyTweak UnitProperty;
	local X2Effect_ToHitModifier PersistentEffect;
	local name UnitType;
	local name UnitClass;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('DisruptorRifleCrit');

	if (AbilityTemplate == none)
	{
		return;
	}

	AbilityTemplate.AbilityTargetEffects.Length = 0;

	UnitProperty = new class'X2Condition_UnitPropertyTweak';
	UnitProperty.ExcludeNonPsionic = true;

	foreach default.UNIT_TYPE_UNAFFECTED_BY_DISRUPTOR_GUARANTEED_CRIT(UnitType)
	{
		UnitProperty.ExcludeTypes.AddItem(UnitType);
	}

	foreach default.CLASSES_AFFECTED_BY_DISRUPTOR_GUARANTEED_CRIT(UnitClass)
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

static function RulerResumeTimerOnEscape(X2AbilityTemplateManager AbilityTemplateManager)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect_SuspendMissionTimer MissionTimerEffect;
	local X2Effect_SetUnitValue SetUnitValue;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('AlienRulerEscape');

	if (AbilityTemplate == none)
	{
		return;
	}

	MissionTimerEffect = new class'X2Effect_SuspendMissionTimer';
	MissionTimerEffect.bResumeMissionTimer = true;
	AbilityTemplate.AddShooterEffect(MissionTimerEffect);

	SetUnitValue = new class'X2Effect_SetUnitValue';
	SetUnitValue.UnitName = class'X2Ability_Tweaks'.default.RULER_STATE;
	SetUnitValue.NewValueToSet = class'X2Ability_Tweaks'.default.RULER_DISENGAGED;
	SetUnitValue.CleanupType = eCleanup_BeginTactical;
	AbilityTemplate.AddShooterEffect(SetUnitValue);
}

static function PounceDontTriggerIfConcealed(X2AbilityTemplateManager AbilityTemplateManager)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2Condition_UnitProperty ShooterCondition;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('PounceTrigger');

	if (AbilityTemplate == none)
	{
		return;
	}

	ShooterCondition = new class'X2Condition_UnitProperty';
	ShooterCondition.ExcludeConcealed = true;
	AbilityTemplate.AbilityShooterConditions.AddItem(ShooterCondition);
}

static function RecreateDevastatingPunchAtMeleeRange(X2AbilityTemplateManager AbilityTemplateManager)
{
	local X2AbilityTemplate OriginalAbilityTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTarget_Single MeleeAtRange;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	OriginalAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('EUBerserkerDevastatingPunch');

	if (OriginalAbilityTemplate == none)
	{
		return;
	}

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('EUBerserkerDevastatingPunchAtMeleeRange');

	if (AbilityTemplate == none)
	{
		return;
	}

	AbilityTemplate = class'Helper_Tweaks'.static.CloneAbility(OriginalAbilityTemplate, AbilityTemplate);

	MeleeAtRange = new class'X2AbilityTarget_Single';
	MeleeAtRange.OnlyIncludeTargetsInsideWeaponRange = true;
	MeleeAtRange.bAllowDestructibleObjects = true;
	AbilityTemplate.AbilityTargetStyle = MeleeAtRange;
}

static function RecreateBladestormAssassinAttack(X2AbilityTemplateManager AbilityTemplateManager)
{
	local X2AbilityTemplate OriginalAbilityTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityToHitCalc_StandardMelee ToHitCalc;
	local X2Effect_Persistent ActivatedEffect;
	local X2Condition_UnitEffectsWithAbilitySource ExcludeEffectsCondition;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	OriginalAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('BladestormAttack');

	if (OriginalAbilityTemplate == none)
	{
		return;
	}

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('BladestormAssassinAttack');

	if (AbilityTemplate == none)
	{
		return;
	}

	AbilityTemplate = class'Helper_Tweaks'.static.CloneAbility(OriginalAbilityTemplate, AbilityTemplate);

	ToHitCalc = new class'X2AbilityToHitCalc_StandardMelee';
	ToHitCalc.bReactionFire = true;
	ToHitCalc.bGuaranteedHit = true;
	AbilityTemplate.AbilityToHitCalc = ToHitCalc;

	ExcludeEffectsCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	ExcludeEffectsCondition.AddExcludeEffect('BladestormAssassinActivated', 'AA_DuplicateEffectIgnored');
	AbilityTemplate.AbilityShooterConditions.AddItem(ExcludeEffectsCondition);

	ActivatedEffect = new class'X2Effect_Persistent';
	ActivatedEffect.EffectName = 'BladestormAssassinActivated';
	ActivatedEffect.BuildPersistentEffect(1, true, false, true);
	ActivatedEffect.DuplicateResponse = eDupe_Ignore;
	AbilityTemplate.AddTargetEffect(ActivatedEffect);
}

static function FeedbackCanOnlyTriggerOnce(X2AbilityTemplateManager AbilityTemplateManager)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect_Persistent ActivatedEffect;
	local X2Condition_UnitEffectsWithAbilitySource ExcludeEffectsCondition;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('Feedback');

	if (AbilityTemplate == none)
	{
		return;
	}

	ExcludeEffectsCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	ExcludeEffectsCondition.AddExcludeEffect('FeedbackActivated', 'AA_DuplicateEffectIgnored');
	AbilityTemplate.AbilityShooterConditions.AddItem(ExcludeEffectsCondition);

	ActivatedEffect = new class'X2Effect_Persistent';
	ActivatedEffect.EffectName = 'FeedbackActivated';
	ActivatedEffect.BuildPersistentEffect(1, true, false, true);
	ActivatedEffect.DuplicateResponse = eDupe_Ignore;
	AbilityTemplate.AddTargetEffect(ActivatedEffect);
}

static function IgnoreBaseWeaponDamage(X2AbilityTemplateManager AbilityTemplateManager)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect TargetEffect;
	local X2Effect MultiTargetEffect;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;
	local name AbilityName;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	foreach default.ABILITY_IGNORE_BASE_WEAPON_DAMAGE(AbilityName)
	{
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName);

		if (AbilityTemplate == none)
		{
			continue;
		}

		foreach AbilityTemplate.AbilityTargetEffects(TargetEffect)
		{
			WeaponDamageEffect = X2Effect_ApplyWeaponDamage(TargetEffect);

			if (WeaponDamageEffect == none)
			{
				continue;
			}

			WeaponDamageEffect.bIgnoreBaseDamage = true;
		}

		foreach AbilityTemplate.AbilityMultiTargetEffects(MultiTargetEffect)
		{
			WeaponDamageEffect = X2Effect_ApplyWeaponDamage(MultiTargetEffect);

			if (WeaponDamageEffect == none)
			{
				continue;
			}

			WeaponDamageEffect.bIgnoreBaseDamage = true;
		}
	}
}

static function bool AbilityTagExpandHandler(string InString, out string OutString)
{
	local name Type;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local int BonusDamage;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	Type = name(InString);

	switch(Type)
	{
		case 'REPEATERDMGBONUSM1':
			BonusDamage = (XComHQ.bEmpoweredUpgrades) ? class'X2Effect_BetterRepeater'.default.REPEATER_EMPOWER_BONUS_DMG : 0;
			OutString = string(class'X2Effect_BetterRepeater'.default.REPEATER_M1_CRIT_DMG + BonusDamage);
			return true;
		case 'REPEATERDMGBONUSM2':
			BonusDamage = (XComHQ.bEmpoweredUpgrades) ? class'X2Effect_BetterRepeater'.default.REPEATER_EMPOWER_BONUS_DMG : 0;
			OutString = string(class'X2Effect_BetterRepeater'.default.REPEATER_M2_CRIT_DMG + BonusDamage);
			return true;
		case 'REPEATERDMGBONUSM3':
			BonusDamage = (XComHQ.bEmpoweredUpgrades) ? class'X2Effect_BetterRepeater'.default.REPEATER_EMPOWER_BONUS_DMG : 0;
			OutString = string(class'X2Effect_BetterRepeater'.default.REPEATER_M3_CRIT_DMG + BonusDamage);
			return true;
	}
	return false;
}