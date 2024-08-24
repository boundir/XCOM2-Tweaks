class X2DownloadableContentInfo_AbilityTweaks extends X2DownloadableContentInfo;

var config(GameData_SoldierSkills) array<name> UNIT_TYPE_UNAFFECTED_BY_DISRUPTOR_GUARANTEED_CRIT;
var config(GameData_SoldierSkills) array<name> CLASSES_AFFECTED_BY_DISRUPTOR_GUARANTEED_CRIT;

var config(GameData_SoldierSkills) array<name> ABILITY_UNAVAILABLE_UNDER_SUPPRESSION;
var config(GameData_SoldierSkills) array<name> ABILITY_REMOVE_SUPPRESSION;

static event OnPostTemplatesCreated()
{
	local X2AbilityTemplateManager AbilityTemplateManager;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	RageStrikeIsMeleeAttack(AbilityTemplateManager);
	ModifyJusticeEnvironmentalDamage(AbilityTemplateManager);

	RemoveSuppressionEffectOnAbilityTriggered(AbilityTemplateManager);
	RemoveSuppressionEffectOnAbilityTriggered(AbilityTemplateManager);
	RemoveSuppressionEffectOnAbilityTriggered(AbilityTemplateManager);
	RemoveSuppressionEffectOnAbilityTriggered(AbilityTemplateManager);

	CantUseAbilityUnderSuppression(AbilityTemplateManager);
	CantUseAbilityUnderSuppression(AbilityTemplateManager);
	CantUseAbilityUnderSuppression(AbilityTemplateManager);
	CantUseAbilityUnderSuppression(AbilityTemplateManager);
	CantUseAbilityUnderSuppression(AbilityTemplateManager);
	CantUseAbilityUnderSuppression(AbilityTemplateManager);
	CantUseAbilityUnderSuppression(AbilityTemplateManager);

	ReworkEUBerserkerBullRush(AbilityTemplateManager);
	DisruptorRifleCritUnitCondition(AbilityTemplateManager);
	RulerResumeTimerOnEscape(AbilityTemplateManager);
	PounceDontTriggerIfConcealed(AbilityTemplateManager);

	RecreateDevastatingPunchAtMeleeRange(AbilityTemplateManager);
	RecreateBladestormAssassinAttack(AbilityTemplateManager);
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

static function ModifyJusticeEnvironmentalDamage(X2AbilityTemplateManager AbilityTemplateManager)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect Effect;
	local X2Effect_ApplyWeaponDamage WeaponEffect;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('Justice');

	if (AbilityTemplate == none)
	{
		return;
	}

	foreach AbilityTemplate.AbilityTargetEffects(Effect)
	{
		if (Effect == none)
		{
			continue;
		}

		if (Effect.IsA('X2Effect_ApplyWeaponDamage'))
		{
			WeaponEffect = X2Effect_ApplyWeaponDamage(Effect);
			WeaponEffect.EnvironmentalDamageAmount = 3;
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