class X2DownloadableContentInfo_AbilityTweaks extends X2DownloadableContentInfo;

var config(GameData_SoldierSkills) array<name> UNIT_TYPE_UNAFFECTED_BY_DISRUPTOR_GUARANTEED_CRIT;
var config(GameData_SoldierSkills) array<name> CLASSES_AFFECTED_BY_DISRUPTOR_GUARANTEED_CRIT;

static event OnPostTemplatesCreated()
{
	RageStrikeIsMeleeAttack();
	ModifyJusticeEnvironmentalDamage();

	RemoveSuppressionEffectOnAbilityTriggered('Stasis');
	RemoveSuppressionEffectOnAbilityTriggered('PriestStasis');
	RemoveSuppressionEffectOnAbilityTriggered('SustainTriggered');
	RemoveSuppressionEffectOnAbilityTriggered('Teleport');

	CantUseAbilityUnderSuppression('Suppression');
	CantUseAbilityUnderSuppression('Stealth');
	CantUseAbilityUnderSuppression('Vanish');
	CantUseAbilityUnderSuppression('SitRepStealth');
	CantUseAbilityUnderSuppression('Shadow');
	CantUseAbilityUnderSuppression('DistractionShadow');
	CantUseAbilityUnderSuppression('RefractionFieldAbility');

	ReworkEUBerserkerBullRush();
	DisruptorRifleCritUnitCondition();
	RulerResumeTimerOnEscape();
	PounceDontTriggerIfConcealed();
}

static function RageStrikeIsMeleeAttack()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityToHitCalc_StandardMelee StandardMelee;

	AbilityTemplateManager = `GetAbilityMngr;

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('Ragestrike');

	if (AbilityTemplate != none)
	{
		StandardMelee = new class'X2AbilityToHitCalc_StandardMelee';
		StandardMelee.bGuaranteedHit = true;
		AbilityTemplate.AbilityToHitCalc = StandardMelee;
	}
}

static function ModifyJusticeEnvironmentalDamage()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect Effect;
	local X2Effect_ApplyWeaponDamage WeaponEffect;

	AbilityTemplateManager = `GetAbilityMngr;

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('Justice');

	if(AbilityTemplate != none)
	{
		continue;
	}

	foreach AbilityTemplate.AbilityTargetEffects(Effect)
	{
		if(Effect == none)
		{
			continue;
		}

		if( Effect.IsA('X2Effect_ApplyWeaponDamage') )
		{
			WeaponEffect = X2Effect_ApplyWeaponDamage(Effect);
			WeaponEffect.EnvironmentalDamageAmount = 3;
		}
	}
}

static function RemoveSuppressionEffectOnAbilityTriggered(name AbilityName)
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect_RemoveEffects RemoveSuppression;

	AbilityTemplateManager = `GetAbilityMngr;

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName);

	if(AbilityTemplate != none)
	{
		continue;
	}

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

static function CantUseAbilityUnderSuppression(name AbilityName)
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;
	local X2Condition_UnitEffects SuppressedCondition;

	AbilityTemplateManager = `GetAbilityMngr;

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName);

	if(AbilityTemplate != none)
	{
		SuppressedCondition = new class'X2Condition_UnitEffects';
		SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
		SuppressedCondition.AddExcludeEffect(class'X2Effect_SkirmisherInterrupt'.default.EffectName, 'AA_AbilityUnavailable');

		AbilityTemplate.AbilityShooterConditions.AddItem(SuppressedCondition);
	}
}

static function ReworkEUBerserkerBullRush()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;
	local X2Condition_OnTeamTurn TeamTurnCondition;
	local X2AbilityTarget_Single SimpleSingleMeleeTarget;

	AbilityTemplateManager = `GetAbilityMngr;

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('EUBullRush');

	if(AbilityTemplate != none)
	{
		TeamTurnCondition = new class'X2Condition_OnTeamTurn';
		TeamTurnCondition.Team = eTeam_XCom;
		AbilityTemplate.AbilityShooterConditions.AddItem(TeamTurnCondition);
	}

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('EUBerserkerDevastatingPunch');

	if(AbilityTemplate != none)
	{
		// SimpleSingleMeleeTarget = new class'X2AbilityTarget_Single';
		// SimpleSingleMeleeTarget.bAllowDestructibleObjects = true;
		// SimpleSingleMeleeTarget.OnlyIncludeTargetsInsideWeaponRange = true;
		// AbilityTemplate.AbilityTargetStyle = SimpleSingleMeleeTarget;
		AbilityTemplate.AbilityTargetStyle = class'X2Ability'.default.SimpleSingleMeleeTarget;
	}
}

static function DisruptorRifleCritUnitCondition()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;
	local X2Condition_UnitPropertyTweak UnitProperty;
	local X2Effect_ToHitModifier PersistentEffect;
	local name UnitType;
	local name UnitClass;

	AbilityTemplateManager = `GetAbilityMngr;

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('DisruptorRifleCrit');

	if(AbilityTemplate != none)
	{
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
}

static function RulerResumeTimerOnEscape()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect_SuspendMissionTimer MissionTimerEffect;
	local X2Effect_SetUnitValue SetUnitValue;

	AbilityTemplateManager = `GetAbilityMngr;

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('AlienRulerEscape');

	if(AbilityTemplate != none)
	{
		MissionTimerEffect = new class'X2Effect_SuspendMissionTimer';
		MissionTimerEffect.bResumeMissionTimer = true;
		AbilityTemplate.AddShooterEffect(MissionTimerEffect);

		SetUnitValue = new class'X2Effect_SetUnitValue';
		SetUnitValue.UnitName = class'X2Ability_Tweaks'.default.RULER_STATE;
		SetUnitValue.NewValueToSet = ERulerEngagement_Disabled;
		SetUnitValue.CleanupType = eCleanup_BeginTactical;
		AbilityTemplate.AddShooterEffect(SetUnitValue);
	}
}

static function PounceDontTriggerIfConcealed()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;
	local X2Condition_UnitProperty ShooterCondition;

	AbilityTemplateManager = `GetAbilityMngr;

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('PounceTrigger');

	if(AbilityTemplate != none)
	{
		ShooterCondition = new class'X2Condition_UnitProperty';
		ShooterCondition.ExcludeConcealed = true;
		AbilityTemplate.AbilityShooterConditions.AddItem(ShooterCondition);
	}
}

static function bool AbilityTagExpandHandler(string InString, out string OutString)
{
	local name Type;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local int BonusDamage;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	Type = name(InString);

	switch(Type)
	{
		case 'REPEATERDMGBONUSM1':
			BonusDamage = (XComHQ.bEmpoweredUpgrades) ? class'X2Ability_Tweaks'.default.REPEATER_EMPOWER_BONUS_DMG : 0;
			OutString = string(class'X2Ability_Tweaks'.default.REPEATER_M1_CRIT_DMG + BonusDamage);
			return true;
		case 'REPEATERDMGBONUSM2':
			BonusDamage = (XComHQ.bEmpoweredUpgrades) ? class'X2Ability_Tweaks'.default.REPEATER_EMPOWER_BONUS_DMG : 0;
			OutString = string(class'X2Ability_Tweaks'.default.REPEATER_M2_CRIT_DMG + BonusDamage);
			return true;
		case 'REPEATERDMGBONUSM3':
			BonusDamage = (XComHQ.bEmpoweredUpgrades) ? class'X2Ability_Tweaks'.default.REPEATER_EMPOWER_BONUS_DMG : 0;
			OutString = string(class'X2Ability_Tweaks'.default.REPEATER_M3_CRIT_DMG + BonusDamage);
			return true;
	}
	return false;
}