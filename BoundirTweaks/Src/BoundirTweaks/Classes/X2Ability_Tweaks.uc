class X2Ability_Tweaks extends X2Ability config(GameCore);

var name RULER_STATE;
var const float RULER_ENGAGED;
var const float RULER_DISENGAGED;

var config(GameData_SoldierSkills) array<name> UNIT_TYPE_MILITIA_CANT_TARGET;
var config(GameData_SoldierSkills) array<name> UNIT_TEMPLATE_MILITIA_CANT_TARGET;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	Templates.AddItem(CreateDevastatingPunchAtMeleeRange());
	Templates.AddItem(CreateBladestormAssassin());
	Templates.AddItem(CreateBladestormAssassinAttack());

	Templates.AddItem(AddBetterRepeaterAbility('BetterRepeaterM1', class'X2Effect_BetterRepeater'.default.REPEATER_M1_CRIT_DMG));
	Templates.AddItem(AddBetterRepeaterAbility('BetterRepeaterM2', class'X2Effect_BetterRepeater'.default.REPEATER_M2_CRIT_DMG));
	Templates.AddItem(AddBetterRepeaterAbility('BetterRepeaterM3', class'X2Effect_BetterRepeater'.default.REPEATER_M3_CRIT_DMG));

	Templates.AddItem(CreateResumeTimer());
	Templates.AddItem(CreatePauseTimer());

	Templates.AddItem(CreateStandardShotMilitia());

	return Templates;
}

static function X2AbilityTemplate CreateDevastatingPunchAtMeleeRange()
{
	local X2AbilityTemplate Template;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	`CREATE_X2ABILITY_TEMPLATE(Template, 'EUBerserkerDevastatingPunchAtMeleeRange');

	return Template;
}

static function X2AbilityTemplate CreateBladestormAssassin()
{
	local X2AbilityTemplate Template;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	Template = PurePassive('BladestormAssassin', "img:///UILibrary_PerkIcons.UIPerk_bladestorm", false, 'eAbilitySource_Perk');
	Template.AdditionalAbilities.AddItem('BladestormAssassinAttack');

	return Template;
}

static function X2AbilityTemplate CreateBladestormAssassinAttack()
{
	local X2AbilityTemplate Template;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	`CREATE_X2ABILITY_TEMPLATE(Template, 'BladestormAssassinAttack');

	return Template;
}

static function X2AbilityTemplate AddBetterRepeaterAbility(name TemplateName, int RepeaterDmgMod)
{
	local X2AbilityTemplate Template;
	local X2Effect_BetterRepeater DamageEffect;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	`CREATE_X2ABILITY_TEMPLATE (Template, TemplateName);
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.bIsPassive = true;

	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	DamageEffect = new class'X2Effect_BetterRepeater';
	DamageEffect.BonusCritDmg = RepeaterDmgMod;
	DamageEffect.BuildPersistentEffect(1, true, false, false);
	DamageEffect.DuplicateResponse = eDupe_Ignore;
	Template.AddTargetEffect(DamageEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate CreateResumeTimer()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;
	local X2Condition_UnitValue ActivatedValueNotSet;
	local X2Effect_SetUnitValue SetUnitValue;
	local X2Effect_SuspendMissionTimer MissionTimerEffect;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ResumeTimer');
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDontDisplayInAbilitySummary = true;

	Template.AbilityTargetStyle = default.SelfTarget;

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'UnitDied';
	EventListener.ListenerData.EventFn = RulerDefeatedListener;
	EventListener.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(EventListener);

	ActivatedValueNotSet = new class'X2Condition_UnitValue';
	ActivatedValueNotSet.AddCheckValue(default.RULER_STATE, default.RULER_ENGAGED, eCheck_Exact);
	Template.AbilityShooterConditions.AddItem(ActivatedValueNotSet);

	MissionTimerEffect = new class'X2Effect_SuspendMissionTimer';
	MissionTimerEffect.bResumeMissionTimer = true;
	Template.AddShooterEffect(MissionTimerEffect);

	SetUnitValue = new class'X2Effect_SetUnitValue';
	SetUnitValue.UnitName = default.RULER_STATE;
	SetUnitValue.NewValueToSet = default.RULER_DISENGAGED;
	SetUnitValue.CleanupType = eCleanup_BeginTactical;
	Template.AddShooterEffect(SetUnitValue);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate CreatePauseTimer()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;
	local X2Condition_UnitValue ActivatedValueNotSet;
	local X2Effect_SetUnitValue SetUnitValue;
	local X2Effect_SuspendMissionTimer MissionTimerEffect;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PauseTimer');
	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	// Activate trigger when the ruler can see an xcom unit.
	// Custom event function checks xcom unit is unconcealed and has LoS. Also removes unit from Initiative Order.
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'UnitSeesUnit';
	EventListener.ListenerData.EventFn = ActivateRulerEngaged;
	EventListener.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(EventListener);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	ActivatedValueNotSet = new class'X2Condition_UnitValue';
	ActivatedValueNotSet.AddCheckValue(default.RULER_STATE, default.RULER_DISENGAGED, eCheck_Exact);
	Template.AbilityShooterConditions.AddItem(ActivatedValueNotSet);

	MissionTimerEffect = new class'X2Effect_SuspendMissionTimer';
	MissionTimerEffect.bResumeMissionTimer = false;
	Template.AddShooterEffect(MissionTimerEffect);

	SetUnitValue = new class'X2Effect_SetUnitValue';
	SetUnitValue.UnitName = default.RULER_STATE;
	SetUnitValue.NewValueToSet = default.RULER_ENGAGED;
	SetUnitValue.CleanupType = eCleanup_BeginTactical;
	Template.AddShooterEffect(SetUnitValue);

	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Always;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

static function X2AbilityTemplate CreateStandardShotMilitia()
{
	local X2AbilityTemplate Template;
	local X2Condition_UnitPropertyTweak UnitPropertyCondition;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	Template = class'X2Ability_WeaponCommon'.static.Add_StandardShot('StandardShotMilitia');

	UnitPropertyCondition = new class'X2Condition_UnitPropertyTweak';
	UnitPropertyCondition.ExcludeTypes = default.UNIT_TYPE_MILITIA_CANT_TARGET;
	UnitPropertyCondition.ExcludeTemplates = default.UNIT_TEMPLATE_MILITIA_CANT_TARGET;

	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	return Template;
}

static function EventListenerReturn RulerDefeatedListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit KilledUnit;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	KilledUnit = XComGameState_Unit(EventSource);

	if (KilledUnit.GetMyTemplate().Abilities.Find('AlienRulerInitialState') == INDEX_NONE)
	{
		return ELR_NoInterrupt;
	}

	class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName( KilledUnit.GetReference(), 'ResumeTimer', KilledUnit.GetReference() );

	return ELR_NoInterrupt;
}

static function EventListenerReturn ActivateRulerEngaged(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit RulerState, EnemyState;
	local XComGameStateHistory History;
	local UnitValue RulerStateValue;
	local array<GameRulesCache_VisibilityInfo> EnemyViewers;
	local GameRulesCache_VisibilityInfo EnemyViewerInfo;
	local XComGameState_Ability SourceAbilityState;
	local bool bVisible;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	if (GameState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt)
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;
	SourceAbilityState = XComGameState_Ability(CallbackData);

	// Check 1 - Ruler is not already engaged.
	RulerState = XComGameState_Unit(History.GetGameStateForObjectID(SourceAbilityState.OwnerStateObject.ObjectID));
	RulerState.GetUnitValue(default.RULER_STATE, RulerStateValue);

	if (RulerStateValue.fValue == default.RULER_ENGAGED)
	{
		return ELR_NoInterrupt;
	}

	// Check 2 - an unconcealed XCOM unit has LoS to this Ruler.
	// Update - only activate if XCOM can see the target.
	if (class'X2TacticalVisibilityHelpers'.static.CanXComSquadSeeTarget(RulerState.ObjectID))
	{
		class'X2TacticalVisibilityHelpers'.static.GetAllTeamUnitsForTileLocation(RulerState.TileLocation, RulerState.ControllingPlayer.ObjectID, eTeam_XCom, EnemyViewers);
		foreach EnemyViewers(EnemyViewerInfo)
		{
			if (EnemyViewerInfo.bClearLOS)
			{
				EnemyState = XComGameState_Unit(History.GetGameStateForObjectID(EnemyViewerInfo.SourceID));

				if (!EnemyState.IsConcealed())
				{
					bVisible = true;
					break;
				}
			}
		}
	}

	if (!bVisible)
	{
		return ELR_NoInterrupt;
	}

	class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName( RulerState.GetReference(), 'PauseTimer', RulerState.GetReference() );

	return ELR_NoInterrupt;
}

defaultproperties
{
	RULER_STATE = "RulerEngaged"
	RULER_ENGAGED = 1.f
	RULER_DISENGAGED = 2.f
}