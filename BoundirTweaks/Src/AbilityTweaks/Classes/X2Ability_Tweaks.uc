class X2Ability_Tweaks extends X2Ability config(GameCore);

var name RULER_STATE;

enum ERulerEngagement
{
	ERulerEngagement_Unknown,
	ERulerEngagement_Activated,
	ERulerEngagement_Disabled
};

var config int REPEATER_M1_CRIT_DMG;
var config int REPEATER_M2_CRIT_DMG;
var config int REPEATER_M3_CRIT_DMG;
var config int REPEATER_EMPOWER_BONUS_DMG;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(AddBetterRepeaterAbility('BetterRepeaterM1', default.REPEATER_M1_CRIT_DMG));
	Templates.AddItem(AddBetterRepeaterAbility('BetterRepeaterM2', default.REPEATER_M2_CRIT_DMG));
	Templates.AddItem(AddBetterRepeaterAbility('BetterRepeaterM3', default.REPEATER_M3_CRIT_DMG));
	Templates.AddItem(CreateResumeTimer());
	Templates.AddItem(CreatePauseTimer());

	return Templates;
}

static function X2AbilityTemplate AddBetterRepeaterAbility(name TemplateName, int RepeaterDmgMod)
{
	local X2AbilityTemplate Template;
	local X2Effect_BetterRepeater DamageEffect;

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
	ActivatedValueNotSet.AddCheckValue(default.RULER_STATE, ERulerEngagement_Activated, eCheck_Exact);
	Template.AbilityShooterConditions.AddItem(ActivatedValueNotSet);

	MissionTimerEffect = new class'X2Effect_SuspendMissionTimer';
	MissionTimerEffect.bResumeMissionTimer = true;
	Template.AddShooterEffect(MissionTimerEffect);

	SetUnitValue = new class'X2Effect_SetUnitValue';
	SetUnitValue.UnitName = default.RULER_STATE;
	SetUnitValue.NewValueToSet = ERulerEngagement_Disabled;
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
	ActivatedValueNotSet.AddCheckValue(default.RULER_STATE, ERulerEngagement_Disabled, eCheck_Exact);
	Template.AbilityShooterConditions.AddItem(ActivatedValueNotSet);

	MissionTimerEffect = new class'X2Effect_SuspendMissionTimer';
	MissionTimerEffect.bResumeMissionTimer = false;
	Template.AddShooterEffect(MissionTimerEffect);

	SetUnitValue = new class'X2Effect_SetUnitValue';
	SetUnitValue.UnitName = default.RULER_STATE;
	SetUnitValue.NewValueToSet = ERulerEngagement_Activated;
	SetUnitValue.CleanupType = eCleanup_BeginTactical;
	Template.AddShooterEffect(SetUnitValue);

	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Always;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

static function EventListenerReturn RulerDefeatedListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit KilledUnit;

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

	if(GameState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt )
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;
	SourceAbilityState = XComGameState_Ability(CallbackData);

	// Check 1 - Ruler is not already engaged.
	RulerState = XComGameState_Unit(History.GetGameStateForObjectID(SourceAbilityState.OwnerStateObject.ObjectID));
	RulerState.GetUnitValue(default.RULER_STATE, RulerStateValue);

	if(RulerStateValue.fValue == ERulerEngagement_Activated)
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
			if( EnemyViewerInfo.bClearLOS )
			{
				EnemyState = XComGameState_Unit(History.GetGameStateForObjectID(EnemyViewerInfo.SourceID));
				if( !EnemyState.IsConcealed() )
				{
					bVisible = true;
					break;
				}
			}
		}
	}

	if(!bVisible )
	{
		return ELR_NoInterrupt;
	}

	class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName( RulerState.GetReference(), 'PauseTimer', RulerState.GetReference() );

	return ELR_NoInterrupt;
}

defaultProperties
{
	RULER_STATE = "RulerEngaged"
}