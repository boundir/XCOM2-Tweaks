//---------------------------------------------------------------------------------------
//  AUTHOR:  Xymanek
//  PURPOSE: Base template for missions as activity. Contains code common to both
//           assault (instant) and infiltration missions. Note that this is also used
//           by many event listeners. Note that the mission families used are specified
//           in X2Helper_Infiltration::ActivityMissionFamily config to allow for easy
//           changes by other mods
//---------------------------------------------------------------------------------------
//  WOTCStrategyOverhaul Team
//---------------------------------------------------------------------------------------

class X2ActivityTemplate_Mission extends X2ActivityTemplate abstract;

const MISSION_SOURCE_NAME = 'MissionSource_ActivityCI';

var class<UIMission> ScreenClass;
var array<name> MissionRewards;
var int Difficulty; // Meaning depends on the GetMissionDifficulty delegate used
var string OverworldMeshPath;
var string UIButtonIcon;
var string MissionImage;
var bool bAssignFactionToMissionSite;
var bool bNeedsPOI;

delegate array<StateObjectReference> InitializeMissionRewards (XComGameState NewGameState, XComGameState_Activity ActivityState);
delegate PreMissionSetup (XComGameState NewGameState, XComGameState_Activity ActivityState);
delegate OnStrategyMapSelected (XComGameState_Activity ActivityState);
delegate OverrideStrategyMapIconTooltip (XComGameState_Activity ActivityState, out string Title, out string Body);
delegate string GetMissionImage (XComGameState_Activity ActivityState);

delegate OnPreMission (XComGameState StartGameState, XComGameState_Activity ActivityState);
delegate OnExitPostMissionSequence (XComGameState_Activity ActivityState);

////////////////////////////////////////////
/// Proxied from X2MissionSourceTemplate ///
////////////////////////////////////////////

delegate OnSuccess (XComGameState NewGameState, XComGameState_Activity ActivityState);
delegate OnFailure (XComGameState NewGameState, XComGameState_Activity ActivityState);
delegate OnExpire (XComGameState NewGameState, XComGameState_Activity ActivityState);

delegate OnTriadSuccess (XComGameState NewGameState, XComGameState_Activity ActivityState);
delegate OnTriadFailure (XComGameState NewGameState, XComGameState_Activity ActivityState);

delegate int GetMissionDifficulty (XComGameState_Activity ActivityState);
delegate string GetOverworldMeshPath (XComGameState_Activity ActivityState);
delegate bool WasMissionSuccessful (XComGameState_BattleData BattleDataState);
delegate array<name> GetSitreps (XComGameState_MissionSite MissionState, XComGameState_Activity ActivityState);

delegate bool RequireLaunchMissionPopup (XComGameState_MissionSite MissionState, XComGameState_Activity ActivityState);
delegate bool CanLaunchMission (XComGameState_MissionSite MissionState, XComGameState_Activity ActivityState);

///////////////////////////////////////
/// Generic/default implementations ///
///////////////////////////////////////

static function array<StateObjectReference> GenericInitializeMissionRewards (XComGameState NewGameState, XComGameState_Activity ActivityState)
{
	local X2StrategyElementTemplateManager TemplateManager;
	local X2ActivityTemplate_Mission ActivityTemplate;
	local XComGameState_ActivityChain ChainState;
	local X2RewardTemplate RewardTemplate;
	local array<StateObjectReference> RewardRefs;
	local ChainStage StageDef;
	local name RewardName;

	TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	ActivityTemplate = X2ActivityTemplate_Mission(ActivityState.GetMyTemplate());
	
	ChainState = ActivityState.GetActivityChain();
	StageDef = ChainState.GetMyTemplate().Stages[ActivityState.GetStageIndex()];

	if (StageDef.RewardOverrides.Length > 0)
	{
		foreach StageDef.RewardOverrides(RewardName)
		{
			RewardTemplate = X2RewardTemplate(TemplateManager.FindStrategyElementTemplate(RewardName));
			if (RewardTemplate != none)
			{
				`log("Initializing overridden reward: " $ RewardName);
				RewardRefs.AddItem(InitMissionReward(NewGameState, ActivityState, RewardTemplate));
			}
		}
	}
	else
	{
		foreach ActivityTemplate.MissionRewards(RewardName)
		{
			RewardTemplate = X2RewardTemplate(TemplateManager.FindStrategyElementTemplate(RewardName));
			if (RewardTemplate != none)
			{
				`log("Initializing normal reward: " $ RewardName);
				RewardRefs.AddItem(InitMissionReward(NewGameState, ActivityState, RewardTemplate));
			}
		}
		if (StageDef.RewardAdditions.Length > 0)
		{
			foreach StageDef.RewardAdditions(RewardName)
			{
				RewardTemplate = X2RewardTemplate(TemplateManager.FindStrategyElementTemplate(RewardName));
				if (RewardTemplate != none)
				{
					`log("Initializing additional reward: " $ RewardName);
					RewardRefs.AddItem(InitMissionReward(NewGameState, ActivityState, RewardTemplate));
				}
			}
		}
	}
	
	`log("InitializeMissionRewards reports " $ RewardRefs.Length $ " rewards");

	return RewardRefs;
}

static function StateObjectReference InitMissionReward (XComGameState NewGameState, XComGameState_Activity ActivityState, X2RewardTemplate RewardTemplate)
{
	local XComGameState_Reward RewardState;
	local XComGameState_HeadquartersResistance ResHQ;

	RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	
	// If this is a chain proxy reward, replace it with a reward from the chainwide reward pool
	if (RewardState.GetMyTemplateName() == 'Reward_ChainProxy')
	{
		RewardState = ActivityState.GetActivityChain().ClaimChainReward(NewGameState);
	}
	else
	{
		RewardState.GenerateReward(NewGameState, ResHQ.GetMissionResourceRewardScalar(RewardState), ActivityState.GetActivityChain().PrimaryRegionRef);
	}

	ActivityState.GetActivityChain().ActivityRewardGenerated(NewGameState, ActivityState, RewardState);

	return RewardState.GetReference();
}

static function string GenericGetOverworldMeshPath (XComGameState_Activity ActivityState)
{
	local X2ActivityTemplate_Mission ActivityTemplate;
	
	ActivityTemplate = X2ActivityTemplate_Mission(ActivityState.GetMyTemplate());

	return ActivityTemplate.OverworldMeshPath;
}

static function GenericOnSuccess (XComGameState NewGameState, XComGameState_Activity ActivityState)
{
	local XComGameState_MissionSite MissionState;

	MissionState = class'X2Helper_Infiltration'.static.GetMissionStateFromActivity(ActivityState);
	class'X2StrategyElement_DefaultMissionSources'.static.GiveRewards(NewGameState, MissionState);
	class'X2Helper_Infiltration'.static.HandlePostMissionPOI(NewGameState, ActivityState, true);
	MissionState.RemoveEntity(NewGameState);

	ActivityState = XComGameState_Activity(NewGameState.ModifyStateObject(class'XComGameState_Activity', ActivityState.ObjectID));
	ActivityState.MarkSuccess(NewGameState);
	
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_GuerrillaOpsCompleted');
	class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, class'X2Helper_Infiltration'.static.GetPostMissionText(ActivityState, true), false);
}

static function GenericOnFailure (XComGameState NewGameState, XComGameState_Activity ActivityState)
{
	local XComGameState_MissionSite MissionState;
	
	MissionState = class'X2Helper_Infiltration'.static.GetMissionStateFromActivity(ActivityState);
	class'X2Helper_Infiltration'.static.HandlePostMissionPOI(NewGameState, ActivityState, false);
	MissionState.RemoveEntity(NewGameState);
	
	ActivityState = XComGameState_Activity(NewGameState.ModifyStateObject(class'XComGameState_Activity', ActivityState.ObjectID));
	ActivityState.MarkFailed(NewGameState);
	
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_GuerrillaOpsFailed');
	class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, class'X2Helper_Infiltration'.static.GetPostMissionText(ActivityState, false), true);
}

static function GenericOnExpire (XComGameState NewGameState, XComGameState_Activity ActivityState)
{
	local XComGameState_MissionSite MissionState;

	`log("Handling Activity Expiration: " $ ActivityState.GetMyTemplateName());
	
	MissionState = class'X2Helper_Infiltration'.static.GetMissionStateFromActivity(ActivityState);
	class'X2Helper_Infiltration'.static.HandlePostMissionPOI(NewGameState, ActivityState, false);
	MissionState.RemoveEntity(NewGameState);
	
	ActivityState = XComGameState_Activity(NewGameState.ModifyStateObject(class'XComGameState_Activity', ActivityState.ObjectID));
	ActivityState.MarkExpired(NewGameState);
}

static function DefaultOnStrategyMapSelected (XComGameState_Activity ActivityState)
{
	local X2ActivityTemplate_Mission ActivityTemplate;
	local XComHQPresentationLayer HQPres;
	local UIMission MissionUI;
	
	ActivityTemplate = X2ActivityTemplate_Mission(ActivityState.GetMyTemplate());
	HQPres = `HQPRES;

	MissionUI = HQPres.Spawn(ActivityTemplate.ScreenClass, HQPres);
	MissionUI.MissionRef = ActivityState.PrimaryObjectRef;
	HQPres.ScreenStack.Push(MissionUI);
}

static function DefaultOverrideStrategyMapIconTooltip (XComGameState_Activity ActivityState, out string Title, out string Body)
{
	local XComGameState_MissionSite MissionSite;
	
	MissionSite = class'X2Helper_Infiltration'.static.GetMissionStateFromActivity(ActivityState);
	
	// Otherwise no title as the default version is "GetMissionSource().MissionPinLabel"
	// which is useless in our case
	Title = MissionSite.GetMissionObjectiveText();
}

static function string DefaultGetMissionImage (XComGameState_Activity ActivityState)
{
	local X2ActivityTemplate_Mission ActivityTemplate;
	
	ActivityTemplate = X2ActivityTemplate_Mission(ActivityState.GetMyTemplate());

	return ActivityTemplate.MissionImage;
}

static function int DefaultGetMissionActivityRandWeight (X2ActivityTemplate Template)
{
	if (class'X2Helper_Infiltration'.default.bMissionActivityDefaultBiasUsesTypes)
	{
		return GetRandWeightByCountOfTypes(Template);
	}

	return GetRandWeightByCountOfFamilies(Template);
}

static function int GetRandWeightByCountOfFamilies (X2ActivityTemplate Template)
{
	local array<string> Families;

	Families = X2ActivityTemplate_Mission(Template).GetMissionFamilies();

	return Families.Length;
}

static function int GetRandWeightByCountOfTypes (X2ActivityTemplate Template)
{
	local MissionDefinition MissionDef;
	local array<string> Families;
	local string MissionFamily;
	local int Result;

	Families = X2ActivityTemplate_Mission(Template).GetMissionFamilies();

	foreach `TACTICALMISSIONMGR.arrMissions(MissionDef)
	{
		MissionFamily = MissionDef.MissionFamily;
		if (MissionFamily == "") MissionFamily = MissionDef.sType;
		
		if (Families.Find(MissionFamily) != INDEX_NONE) Result++;
	}

	return Result;
}

// This also dedupes the families (in case of any errors in the config)
final function array<string> GetMissionFamilies ()
{
	local ActivityMissionFamilyMapping Mapping;
	local array<string> Families;

	foreach class'X2Helper_Infiltration'.default.ActivityMissionFamily (Mapping)
	{
		if (Mapping.ActivityTemplate == DataName)
		{
			`AddUniqueItemToArray(Families, Mapping.MissionFamily)
		}
	}

	return Families;
}

static function bool DefaultShouldProgressChain (XComGameState_Activity ActivityState)
{
	return ActivityState.CompletionStatus == eActivityCompletion_Success || ActivityState.CompletionStatus == eActivityCompletion_PartialSuccess;
}

defaultproperties
{
	bAssignFactionToMissionSite = true
	ScreenClass = class'UIMission_Council'

	InitializeMissionRewards = GenericInitializeMissionRewards
	GetOverworldMeshPath = GenericGetOverworldMeshPath
	OnStrategyMapSelected = DefaultOnStrategyMapSelected
	OverrideStrategyMapIconTooltip = DefaultOverrideStrategyMapIconTooltip
	GetMissionImage = DefaultGetMissionImage

	OnSuccess = GenericOnSuccess
	OnFailure = GenericOnFailure
	OnExpire = GenericOnExpire

	GetRandWeight = DefaultGetMissionActivityRandWeight
	ShouldProgressChain = DefaultShouldProgressChain
}