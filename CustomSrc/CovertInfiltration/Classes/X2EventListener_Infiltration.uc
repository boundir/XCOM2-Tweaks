//---------------------------------------------------------------------------------------
//  AUTHOR:  Xymanek and statusNone
//  PURPOSE: Houses X2EventListenerTemplates that affect gameplay. Mostly CHL hooks
//---------------------------------------------------------------------------------------
//  WOTCStrategyOverhaul Team
//---------------------------------------------------------------------------------------

class X2EventListener_Infiltration extends X2EventListener config(Infiltration);

// Unrealscript doesn't support nested arrays, so we place a struct inbetween
struct SitRepsArray
{
	var array<name> SitReps;
};

struct SitRepMissionPair
{
	var string MissionType; // Will be preffered if set
	var string MissionFamily;
	var name SitRep;
};

// Values from config represent a percentage to be removed from total will e.g.(25 = 25%, 50 = 50%)
var config int MIN_WILL_LOSS;
var config int MAX_WILL_LOSS;

var config(GameData) bool ALLOW_SQUAD_SIZE_SITREPS_ON_INFILS;
var config(GameData) array<SitRepsArray> SITREPS_EXCLUSIVE_BUCKETS;
var config(GameData) array<SitRepMissionPair> SITREPS_MISSION_BLACKLIST;

var config(GameBoard) array<name> CovertActionsPreventRandomSpawn;

var config(GameData) int NumDarkEventsFirstMonth;
var config(GameData) int NumDarkEventsSecondMonth;
var config(GameData) int NumDarkEventsThirdMonth;

var config(GameBoard) float RiskChancePercentMultiplier;
var config(GameBoard) float RiskChancePercentPerForceLevel;

var config(Missions) bool SupplyExtraction_HoldResponseUntilSquadReveal;

var config array<StrategyCost> OneTimeMarketLeadCost;

var config array<bool> MindShieldOnTiredNerf_Enabled; // Whether the system is enabled by difficluty
var config array<name> MindShieldOnTiredNerf_Items; // Items that will trigger the penalty
var config bool MindShieldOnTiredNerf_PermitTraitStacking; // If enabled, a negative trait will be added even if one (or more) is already recieved from the mission by the unit

var localized string strOneTimeMarketLeadDescription;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateStrategyListeners());
	Templates.AddItem(CreateTacticalListeners());

	return Templates;
}

////////////////
/// Strategy ///
////////////////

static function CHEventListenerTemplate CreateStrategyListeners()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'Infiltration_Strategy');
	Template.AddCHEvent('NumCovertActionsToAdd', NumCovertActionToAdd, ELD_Immediate, 99);
	Template.AddCHEvent('CovertActionCompleted', CovertActionCompleted, ELD_Immediate, 99);
	Template.AddCHEvent('AllowDarkEventRisk', AllowDarkEventRisk, ELD_Immediate, 99);
	Template.AddCHEvent('CovertActionRisk_AlterChanceModifier', AlterRiskChanceModifier, ELD_Immediate, 99);
	Template.AddCHEvent('CovertAction_PreventGiveRewards', PreventActionRewards, ELD_Immediate, 99);
	Template.AddCHEvent('CovertAction_RemoveEntity_ShouldEmptySlots', ShouldEmptySlotsOnActionRemoval, ELD_Immediate, 99);
	Template.AddCHEvent('ShouldCleanupCovertAction', ShouldCleanupCovertAction, ELD_Immediate, 99);
	Template.AddCHEvent('SitRepCheckAdditionalRequirements', SitRepCheckAdditionalRequirements, ELD_Immediate, 99);
	Template.AddCHEvent('CovertActionAllowCheckForProjectOverlap', CovertActionAllowCheckForProjectOverlap, ELD_Immediate, 99);
	Template.AddCHEvent('CovertAction_AllowResActivityRecord', CovertAction_AllowResActivityRecord, ELD_Immediate, 99);
	Template.AddCHEvent('AllowOnCovertActionCompleteAnalytics', AllowOnCovertActionCompleteAnalytics, ELD_Immediate, 99);
	Template.AddCHEvent('CovertActionStarted', CovertActionStarted, ELD_OnStateSubmitted, 99);
	Template.AddCHEvent('PostEndOfMonth', PostEndOfMonth, ELD_OnStateSubmitted, 99);
	Template.AddCHEvent('AllowActionToSpawnRandomly', AllowActionToSpawnRandomly, ELD_Immediate, 99);
	Template.AddCHEvent('AfterActionModifyRecoveredLoot', AfterActionModifyRecoveredLoot, ELD_Immediate, 99);
	Template.AddCHEvent('SoldierTacticalToStrategy', SoldierInfiltrationToStrategyUpgradeGear, ELD_Immediate, 99);
	Template.AddCHEvent('SoldierTacticalToStrategy', SoldierTacticalToStrategy_CheckStartedTired, ELD_OnStateSubmitted, 99);
	Template.AddCHEvent('OverrideDarkEventCount', OverrideDarkEventCount, ELD_Immediate, 99);
	Template.AddCHEvent('LowSoldiersCovertAction', PreventLowSoldiersCovertActionNag, ELD_OnStateSubmitted, 99);
	Template.AddCHEvent('OverrideAddChosenTacticalTagsToMission', OverrideAddChosenTacticalTagsToMission, ELD_Immediate, 99);
	Template.AddCHEvent('PreCompleteStrategyFromTacticalTransfer', PreCompleteStrategyFromTacticalTransfer, ELD_Immediate, 99);
	Template.AddCHEvent('AllowNoSquadSizeUpgradeAchievement', AllowNoSquadSizeUpgradeAchievement, ELD_Immediate, 99);
	Template.AddCHEvent('BlackMarketGoodsReset', BlackMarketGoodsReset, ELD_Immediate, 99);
	Template.AddCHEvent('BlackMarketPurchase', BlackMarketPurchase_OSS, ELD_OnStateSubmitted, 99);
	Template.AddCHEvent('AddResource', AddResource_OSS, ELD_OnStateSubmitted, 99);
	Template.AddCHEvent('rjSquadSelect_ExtraInfo', AddSquadSelectSlotNotes, ELD_Immediate, 99);
	Template.RegisterInStrategy = true;

	return Template;
}

static protected function EventListenerReturn NumCovertActionToAdd(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_ResistanceFaction Faction;
	local XComLWTuple Tuple;

	Faction = XComGameState_ResistanceFaction(EventSource);
	Tuple = XComLWTuple(EventData);
	
	if (Faction == none || Tuple == none || Tuple.Id != 'NumCovertActionsToAdd') return ELR_NoInterrupt;

	// Force the same behaviour as with ring
	Tuple.Data[0].i = class'XComGameState_ResistanceFaction'.default.CovertActionsPerInfluence[Faction.Influence];

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn CovertActionCompleted(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_MissionSiteInfiltration MissionState;
	local XComGameState_CovertAction CovertAction;
	local XComGameState_Activity Activity;

	CovertAction = XComGameState_CovertAction(EventSource);

	if (CovertAction == none)
	{
		return ELR_NoInterrupt;
	}

	if (class'X2Helper_Infiltration'.static.IsInfiltrationAction(CovertAction))
	{
		`log(CovertAction.GetMyTemplateName() @ "finished, activating infiltration mission",, 'CI');

		Activity = class'XComGameState_Activity'.static.GetActivityFromSecondaryObject(CovertAction);
		MissionState = XComGameState_MissionSiteInfiltration(GameState.ModifyStateObject(class'XComGameState_MissionSiteInfiltration', Activity.PrimaryObjectRef.ObjectID));
		MissionState.OnActionCompleted(GameState);

		// Do not show the CA report, the mission will show its screen instead
		CovertAction.bNeedsActionCompletePopup = false;

		// Remove the CA, the mission takes over from here
		CovertAction.RemoveEntity(GameState);
	}
	else
	{
		`log(CovertAction.GetMyTemplateName() @ "finished, it was not an infiltration - applying fatigue",, 'CI');

		ApplyPostActionWillLoss(CovertAction, GameState);
	}
	
	return ELR_NoInterrupt;
}

static protected function ApplyPostActionWillLoss(XComGameState_CovertAction CovertAction, XComGameState NewGameState)
{
	local CovertActionStaffSlot CovertActionSlot;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_Unit UnitState;
	
	foreach CovertAction.StaffSlots(CovertActionSlot)
	{
		SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(CovertActionSlot.StaffSlotRef.ObjectID));
		if (SlotState.IsSlotFilled())
		{
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', SlotState.GetAssignedStaff().ObjectID));
			if (UnitState.UsesWillSystem() && !UnitState.IsInjured() && !UnitState.bCaptured)
			{
				UnitState.SetCurrentStat(eStat_Will, GetWillLoss(UnitState));
				UnitState.UpdateMentalState();

				class'X2Helper_Infiltration'.static.CreateWillRecoveryProject(NewGameState, UnitState);
			}
		}
	}
}

static protected function int GetWillLoss(XComGameState_Unit UnitState)
{
	local int WillToLose, LowestWill;

	WillToLose = default.MIN_WILL_LOSS + `SYNC_RAND_STATIC(default.MAX_WILL_LOSS - default.MIN_WILL_LOSS);
	WillToLose *= UnitState.GetMaxStat(eStat_Will) / 100;

	LowestWill = (UnitState.GetMaxStat(eStat_Will) * class'X2StrategyGameRulesetDataStructures'.default.MentalStatePercents[eMentalState_Shaken] / 100) + 1;
	//never put the soldier into shaken state from covert actions
	if (UnitState.GetMaxStat(eStat_Will) - WillToLose < LowestWill)
	{
		return LowestWill;
	}

	return UnitState.GetCurrentStat(eStat_Will) - WillToLose;
}

static protected function EventListenerReturn AllowDarkEventRisk(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_CovertAction Action;
	local XComLWTuple Tuple;

	Action = XComGameState_CovertAction(EventSource);
	Tuple = XComLWTuple(EventData);
	
	if (Action == none || Tuple == none || Tuple.Id != 'AllowDarkEventRisk') return ELR_NoInterrupt;

	if (class'X2Helper_Infiltration'.static.IsInfiltrationAction(Action))
	{
		// Infiltrations cannot get DE risks (at least for now)
		Tuple.Data[1].b = false;
	}

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn AlterRiskChanceModifier(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local array<StateObjectReference> ActionSquad;
	local XComGameState_CovertAction Action;
	local XComLWTuple Tuple;
	local int ForceLevel;
	local float ModifierForceLevel;

	Action = XComGameState_CovertAction(EventSource);
	Tuple = XComLWTuple(EventData);
	
	if (Action == none || Tuple == none || Tuple.Id != 'CovertActionRisk_AlterChanceModifier') return ELR_NoInterrupt;
	if (class'X2Helper_Infiltration'.static.IsInfiltrationAction(Action)) return ELR_NoInterrupt;

	Tuple.Data[4].i += Tuple.Data[1].i * (default.RiskChancePercentMultiplier - 1);
	
	ForceLevel = class'UIUtilities_Strategy'.static.GetAlienHQ().GetForceLevel();
	ModifierForceLevel = default.RiskChancePercentPerForceLevel * ForceLevel;
	Tuple.Data[4].i += ModifierForceLevel;
	
	ActionSquad = class'X2Helper_Infiltration'.static.GetCovertActionSquad(Action);
	Tuple.Data[4].i -= class'X2Helper_Infiltration'.static.GetSquadRiskReduction(ActionSquad);
	
	`log("Risk modifier for" @ Tuple.Data[0].n @ "is" @ Tuple.Data[4].i $ ", base chance is" @ Tuple.Data[1].i);

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn PreventActionRewards(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_CovertAction Action;
	local XComLWTuple Tuple;

	Action = XComGameState_CovertAction(EventSource);
	Tuple = XComLWTuple(EventData);
	
	if (Action == none || Tuple == none || Tuple.Id != 'CovertAction_PreventGiveRewards') return ELR_NoInterrupt;

	if (class'X2Helper_Infiltration'.static.IsInfiltrationAction(Action))
	{
		// The reward is the mission, you greedy
		Tuple.Data[0].b = true;
	}

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn ShouldEmptySlotsOnActionRemoval(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_CovertAction Action;
	local XComLWTuple Tuple;

	Action = XComGameState_CovertAction(EventSource);
	Tuple = XComLWTuple(EventData);
	
	if (Action == none || Tuple == none || Tuple.Id != 'CovertAction_RemoveEntity_ShouldEmptySlots') return ELR_NoInterrupt;

	if (Action.bStarted && class'X2Helper_Infiltration'.static.IsInfiltrationAction(Action))
	{
		// do not kick people from finished infiltration - we will do it right before launching the mission
		Tuple.Data[0].b = false;
	}

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn ShouldCleanupCovertAction(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local ActionExpirationInfo ExpirationInfo;
	local XComGameState_CovertAction Action;
	local XComLWTuple Tuple;

	Tuple = XComLWTuple(EventData);
	if (Tuple == none || Tuple.Id != 'ShouldCleanupCovertAction') return ELR_NoInterrupt;

	Action = XComGameState_CovertAction(Tuple.Data[0].o);

	if (class'XComGameState_CovertActionExpirationManager'.static.GetActionExpirationInfo(Action.GetReference(), ExpirationInfo))
	{
		if (ExpirationInfo.bBlockMonthlyCleanup)
		{
			Tuple.Data[1].b = false;
		}
	}

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn SitRepCheckAdditionalRequirements (Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_MissionSiteInfiltration InfiltrationState;
	local InfilBonusMilestoneSelection InfilBonusSelection;
	local X2OverInfiltrationBonusTemplate BonusTemplate;
	local X2StrategyElementTemplateManager StratMgr;
	local SitRepMissionPair SitRepMissionExclusion;
	local X2SitRepEffect_SquadSize SquadSizeEffect;
	local XComGameState_MissionSite MissionState;
	local X2SitRepTemplate TestedSitRepTemplate;
	local SitRepsArray ExclusivityBucket;
	local array<name> CurrentSitReps;
	local bool bMissionMatched;
	local XComLWTuple Tuple;
	local name SitRepName;

	TestedSitRepTemplate = X2SitRepTemplate(EventSource);
	Tuple = XComLWTuple(EventData);

	if (TestedSitRepTemplate == none || Tuple == none || Tuple.Id != 'SitRepCheckAdditionalRequirements') return ELR_NoInterrupt;

	// Check if another listener already blocks this sitrep - in this case we don't need to do anything
	if (Tuple.Data[0].b == false) return ELR_NoInterrupt;

	MissionState = XComGameState_MissionSite(Tuple.Data[1].o);
	InfiltrationState = XComGameState_MissionSiteInfiltration(MissionState);

	// Block squad-size-modifying sitreps from infil

	if (InfiltrationState != none && !default.ALLOW_SQUAD_SIZE_SITREPS_ON_INFILS)
	{
		CurrentSitReps.Length = 1;
		CurrentSitReps[0] = TestedSitRepTemplate.DataName;

		foreach class'X2SitreptemplateManager'.static.IterateEffects(class'X2SitRepEffect_SquadSize', SquadSizeEffect, CurrentSitReps)
		{
			// If we reached this code then, there is at least one X2SitRepEffect_SquadSize attached to this sitrep
			// Block and exit early
			Tuple.Data[0].b = false;
			return ELR_NoInterrupt;
		}

		// If we didn't return above, then there are no X2SitRepEffect_SquadSize - keep going
		CurrentSitReps.Length = 0;
	}

	// Check mission blacklist

	foreach default.SITREPS_MISSION_BLACKLIST(SitRepMissionExclusion)
	{
		if (SitRepMissionExclusion.SitRep != TestedSitRepTemplate.DataName) continue;

		if (SitRepMissionExclusion.MissionType != "")
		{
			bMissionMatched = MissionState.GeneratedMission.Mission.sType == SitRepMissionExclusion.MissionType;
		}
		else if (SitRepMissionExclusion.MissionFamily != "")
		{
			bMissionMatched =
				MissionState.GeneratedMission.Mission.MissionFamily == SitRepMissionExclusion.MissionFamily ||
				(
					MissionState.GeneratedMission.Mission.MissionFamily == "" && // missions without families are their own family
					MissionState.GeneratedMission.Mission.sType == SitRepMissionExclusion.MissionFamily
				);
		}
		else
		{
			`RedScreen("SITREPS_MISSION_BLACKLIST entry encoutered without mission type or family");
			continue;
		}

		if (bMissionMatched)
		{
			// Found incompatibility - exit early
			Tuple.Data[0].b = false;
			return ELR_NoInterrupt;
		}
	}

	// Get the current sitreps, accounting for selected bonuses

	CurrentSitReps = MissionState.GeneratedMission.SitReps;

	if (InfiltrationState != none)
	{
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

		foreach InfiltrationState.SelectedInfiltartionBonuses(InfilBonusSelection)
		{
			if (InfilBonusSelection.BonusName == '') continue;

			BonusTemplate = X2OverInfiltrationBonusTemplate(StratMgr.FindStrategyElementTemplate(InfilBonusSelection.BonusName));

			if (BonusTemplate.bSitRep)
			{
				CurrentSitReps.AddItem(BonusTemplate.MetatdataName);
			}
		}
	}

	// Check for exclusivity with other sitreps

	foreach default.SITREPS_EXCLUSIVE_BUCKETS(ExclusivityBucket)
	{
		if (ExclusivityBucket.SitReps.Find(TestedSitRepTemplate.DataName) == INDEX_NONE) continue;

		// This bucket includes the tested sitrep, check if any other is already included
		foreach ExclusivityBucket.SitReps(SitRepName)
		{
			// Cannot be incompatible with itself
			if (SitRepName == TestedSitRepTemplate.DataName) continue;

			if (CurrentSitReps.Find(SitRepName) != INDEX_NONE)
			{
				// Found incompatibility - exit early
				Tuple.Data[0].b = false;
				return ELR_NoInterrupt;
			}
		}
	}

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn CovertActionAllowCheckForProjectOverlap (Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_CovertAction Action;
	local XComLWTuple Tuple;

	Action = XComGameState_CovertAction(EventSource);
	Tuple = XComLWTuple(EventData);

	if (Action == none || Tuple == none || Tuple.Id != 'CovertActionAllowCheckForProjectOverlap') return ELR_NoInterrupt;

	// For now preserve the vanilla behaviour for non-infil CAs
	if (class'X2Helper_Infiltration'.static.IsInfiltrationAction(Action))
	{
		Tuple.Data[0].b = false;
	}

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn CovertAction_AllowResActivityRecord (Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_CovertAction Action;
	local XComLWTuple Tuple;

	Action = XComGameState_CovertAction(EventSource);
	Tuple = XComLWTuple(EventData);

	if (Action == none || Tuple == none) return ELR_NoInterrupt;

	if (class'X2Helper_Infiltration'.static.IsInfiltrationAction(Action))
	{
		Tuple.Data[0].b = false;
	}

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn AllowOnCovertActionCompleteAnalytics (Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_CovertAction Action;
	local XComLWTuple Tuple;

	Tuple = XComLWTuple(EventData);
	if (Tuple == none) return ELR_NoInterrupt;

	Action = XComGameState_CovertAction(Tuple.Data[2].o);
	if (Action == none) return ELR_NoInterrupt;

	if (class'X2Helper_Infiltration'.static.IsInfiltrationAction(Action))
	{
		Tuple.Data[0].b = false;
	}

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn CovertActionStarted (Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local array<StateObjectReference> CurrentSquad;
	local XComGameState_CovertAction ActionState;
	local StateObjectReference UnitRef;
	local XComGameState NewGameState;

	ActionState = XComGameState_CovertAction(EventSource);
	if (ActionState == none) return ELR_NoInterrupt;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CI: Stop will recovery at action start");
	CurrentSquad = class'X2Helper_Infiltration'.static.GetCovertActionSquad(ActionState);

	foreach CurrentSquad(UnitRef)
	{
		//make sure soldier actually uses will system before we nuke it cuz reasons
		if (XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID)).UsesWillSystem())
		{
			class'X2Helper_Infiltration'.static.DestroyWillRecoveryProject(NewGameState, UnitRef);
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn PostEndOfMonth (Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CI: Handling post end of month");
	class'XComGameState_ActivityChainSpawner'.static.SpawnCounterDarkEvents(NewGameState);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	return ELR_NoInterrupt;
}

static protected function EventListenerReturn AllowActionToSpawnRandomly (Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local X2CovertActionTemplate ActionTemplate;
	local XComLWTuple Tuple;

	local X2ActivityTemplate_Infiltration InfiltrationActivityTemplate;
	local X2ActivityTemplate_CovertAction ActionActivityTemplate;
	local X2StrategyElementTemplateManager TemplateManager;
	local X2DataTemplate DataTemplate;
	
	Tuple = XComLWTuple(EventData);
	if (Tuple == none || Tuple.Id != 'AllowActionToSpawnRandomly') return ELR_NoInterrupt;

	ActionTemplate = X2CovertActionTemplate(Tuple.Data[1].o);

	if (default.CovertActionsPreventRandomSpawn.Find(ActionTemplate.DataName) != INDEX_NONE)
	{
		Tuple.Data[0].b = false;
		return ELR_NoInterrupt;
	}

	TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	foreach TemplateManager.IterateTemplates(DataTemplate)
	{
		InfiltrationActivityTemplate = X2ActivityTemplate_Infiltration(DataTemplate);
		if (InfiltrationActivityTemplate != none && InfiltrationActivityTemplate.CovertActionName == ActionTemplate.DataName)
		{
			Tuple.Data[0].b = false;
			return ELR_NoInterrupt;
		}

		ActionActivityTemplate = X2ActivityTemplate_CovertAction(DataTemplate);
		if (ActionActivityTemplate != none && ActionActivityTemplate.CovertActionName == ActionTemplate.DataName)
		{
			Tuple.Data[0].b = false;
			return ELR_NoInterrupt;
		}
	}

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn AfterActionModifyRecoveredLoot (Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local UIInventory_LootRecovered LootRecoveredUI;
	
	local XComGameState_ActivityChain ChainState;
	local XComGameState_Activity ActivityState;
	
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local bool bDirty;

	local XComGameState_Complication_RewardInterception ComplicationState;
	local XComGameState_ResourceContainer ResContainer;
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference ItemRef;
	local XComGameState_Item ItemState;
	local ResourcePackage Package;
	local int InterceptedQuantity;
	
	LootRecoveredUI = UIInventory_LootRecovered(EventSource);
	if (LootRecoveredUI == none) return ELR_NoInterrupt;

	XComHQ = `XCOMHQ;
	ActivityState = class'XComGameState_Activity'.static.GetActivityFromPrimaryObjectID(XComHQ.MissionRef.ObjectID);
	if (ActivityState == none) return ELR_NoInterrupt;
	
	ChainState = ActivityState.GetActivityChain();
	if (ChainState.GetLastActivity().ObjectID != ActivityState.ObjectID) return ELR_NoInterrupt;
	
	ComplicationState = XComGameState_Complication_RewardInterception(ChainState.FindComplication('Complication_RewardInterception'));
	if (ComplicationState == none) return ELR_NoInterrupt;
	
	if (!ComplicationState.bTriggered) return ELR_NoInterrupt;

	// All checks have passed, we are good to do our magic
	`log("Processing Reward Interception");

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CI: Apply reward interception");
	ResContainer = XComGameState_ResourceContainer(NewGameState.ModifyStateObject(class'XComGameState_ResourceContainer', ComplicationState.ResourceContainerRef.ObjectID));
	History = `XCOMHISTORY;

	// Loop through all of the recovered loot and see if we can't screw with it
	foreach XComHQ.LootRecovered(ItemRef)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
		if (ItemState == none) continue;

		if (!class'X2StrategyElement_DefaultComplications'.static.IsInterceptableItem(ItemState.GetMyTemplateName()))
		{
			`log(ItemState.GetMyTemplateName() @ "is not interceptable - skipping");
			continue;
		}
		
		`log(ItemState.GetMyTemplateName() @ "is intercepted");
		bDirty = true;
		
		// Reduce the quantity
		ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemState.ObjectID));
		InterceptedQuantity = ItemState.Quantity * class'X2StrategyElement_DefaultComplications'.default.REWARD_INTERCEPTION_TAKENLOOT;
		ItemState.Quantity -= InterceptedQuantity;

		// Store the quantity to give later
		Package.ItemType = ItemState.GetMyTemplateName();
		Package.ItemAmount = InterceptedQuantity;
		ResContainer.Packages.AddItem(Package);
	}
	
	// Save the changes, if there was any intercepted items
	if (bDirty)	
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else 
	{
		if (!ComplicationState.RewardStateIntercepted)
		{
			`REDSCREEN("No interceptable loot for the complication - rescue mission will spawn empty!");
		}

		History.CleanupPendingGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

// Note that we cannot use DLCInfo::OnPostMission as the gear of dead soldiers is stripped by that point
// This otoh is called right before the gear is stripped
static protected function EventListenerReturn SoldierInfiltrationToStrategyUpgradeGear (Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComGameState_MissionSiteInfiltration InfiltrationState;
	local XComGameState_CovertInfiltrationInfo CIInfo;
	local XComGameState_Unit UnitState;

	InfiltrationState = XComGameState_MissionSiteInfiltration(`XCOMHISTORY.GetGameStateForObjectID(`XCOMHQ.MissionRef.ObjectID));
	UnitState = XComGameState_Unit(EventSource);

	if (InfiltrationState == none || UnitState == none) return ELR_NoInterrupt;

	// This is required as EventData/EventSource inside ELD_Immediate are from last submitted state, not the pending one
	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(UnitState.ObjectID));

	// Captured soldiers are handeled when they are rescued - see #407 for more details
	if (UnitState.bCaptured) return ELR_NoInterrupt;

	if (!UnitState.IsDead())
	{
		// If we upgrade here, soldiers will have magically upgraded gear when exiting the skyranger, so defer it
		CIInfo = class'XComGameState_CovertInfiltrationInfo'.static.ChangeForGamestate(NewGameState);
		CIInfo.UnitsToConsiderUpgradingGearOnMissionExit.AddItem(UnitState.GetReference());
	}
	else
	{
		// Upgrade here so that it's stripped/added to hq inventory correctly
		class'X2StrategyElement_XpackStaffSlots'.static.CheckToUpgradeItems(NewGameState, UnitState);
	}
	
	return ELR_NoInterrupt;	
}

// This needs to be ELD_OnStateSubmitted as XCGSC_SGR limits how many units can get shaken/traits - we want to bypass all of those checks
static protected function EventListenerReturn SoldierTacticalToStrategy_CheckStartedTired (Object EventData, Object EventSource, XComGameState EventGameState, Name Event, Object CallbackData)
{
	local XComGameState_CovertInfiltrationInfo CIInfo;
	local XComGameState_Unit UnitState, PrevUnitState;
	local XComGameStateHistory History;
	local XComGameState NewGameState;

	local int MaxWill, MinWill, Roll, Diff, HalfDiff;
	local array<name> ValidTraits, GenericTraits;
	local bool bAddTrait;
	local name TraitName;

	if (!default.MindShieldOnTiredNerf_Enabled[`StrategyDifficultySetting])
	{
		return ELR_NoInterrupt;
	}

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none) return ELR_NoInterrupt;

	// Make sure the unit fully came back to avenger
	// Since we are in ELD_OSS, this will take care of things like death and capture (see XCGSC_SGR)
	if (`XCOMHQ.Crew.Find('ObjectID', UnitState.ObjectID) == INDEX_NONE)
	{
		`log(nameof(SoldierTacticalToStrategy_CheckStartedTired) $ ": unit" @ UnitState.ObjectID @ "is not part of HQ crew, skipping");
		return ELR_NoInterrupt;
	}

	CIInfo = class'XComGameState_CovertInfiltrationInfo'.static.GetInfo();
	History = `XCOMHISTORY;

	if (CIInfo.UnitsStartedMissionBelowReadyWill.Find('ObjectID', UnitState.ObjectID) == INDEX_NONE)
	{
		`log(nameof(SoldierTacticalToStrategy_CheckStartedTired) $ ": unit" @ UnitState.ObjectID @ "did not start mission below ready will, skipping");
		return ELR_NoInterrupt;
	}

	if (!UnitHasMindshieldNerfItem(UnitState.GetReference()))
	{
		`log(nameof(SoldierTacticalToStrategy_CheckStartedTired) $ ": unit" @ UnitState.ObjectID @ "started below ready will but has no mindshield item, skipping");
		return ELR_NoInterrupt;
	}

	`log(nameof(SoldierTacticalToStrategy_CheckStartedTired) $ ": applying penalty to unit" @ UnitState.ObjectID);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CI: Applying tired mindshield penatly to unit" @ UnitState.ObjectID);
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

	// Part 1 - set unit to shaken if not shaken already
	if (UnitState.GetMentalState() == eMentalState_Shaken)
	{
		`log(nameof(SoldierTacticalToStrategy_CheckStartedTired) $ ": unit" @ UnitState.ObjectID @ "is already shaken");
	}
	else
	{
		MaxWill = UnitState.GetMaxWillForMentalState(eMentalState_Shaken);
		MinWill = UnitState.GetMinWillForMentalState(eMentalState_Shaken);

		Diff = MaxWill - MinWill;
		HalfDiff = Diff / 2; // int division is correct here

		Roll = `SYNC_RAND_STATIC(HalfDiff);

		UnitState.SetCurrentStat(eStat_Will, MinWill + HalfDiff + Roll);
		UnitState.UpdateMentalState();

		`log(nameof(SoldierTacticalToStrategy_CheckStartedTired) $ ": set unit" @ UnitState.ObjectID @ "to shaken");
		`log(`showvar(MinWill));
		`log(`showvar(MaxWill));
		`log(`showvar(Diff));
		`log(`showvar(HalfDiff));
		`log(`showvar(Roll));
	}

	// Part 2 - add a negative trait
	bAddTrait = true;

	if (!default.MindShieldOnTiredNerf_PermitTraitStacking)
	{
		// Get the unit state from before SquadTacticalToStrategyTransfer was applied to it
		PrevUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitState.ObjectID,, EventGameState.HistoryIndex - 1));

		if (UnitState.NegativeTraits.Length > PrevUnitState.NegativeTraits.Length)
		{
			bAddTrait = false;
			`log(nameof(SoldierTacticalToStrategy_CheckStartedTired) $ ": unit" @ UnitState.ObjectID @ "already got a negative trait from this mission");
		}
	}

	if (bAddTrait)
	{
		GenericTraits = class'X2TraitTemplate'.static.GetAllGenericTraitNames();

		foreach GenericTraits(TraitName)
		{
			if (UnitState.AcquiredTraits.Find(TraitName) == INDEX_NONE && UnitState.PendingTraits.Find(TraitName) == INDEX_NONE)
			{
				`AddUniqueItemToArray(ValidTraits, TraitName);
			}
		}

		if (ValidTraits.Length < 1)
		{
			`RedScreen(nameof(SoldierTacticalToStrategy_CheckStartedTired) $ ": found no valid traits for unit" @ UnitState.ObjectID);
		}
		else
		{
			TraitName = ValidTraits[`SYNC_RAND_STATIC(ValidTraits.Length)];

			UnitState.AddAcquiredTrait(NewGameState, TraitName);
			`log(nameof(SoldierTacticalToStrategy_CheckStartedTired) $ ": unit" @ UnitState.ObjectID @ "got trait" @ TraitName);
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	return ELR_NoInterrupt;
}

static function bool UnitHasMindshieldNerfItem (StateObjectReference UnitRef)
{
	local XComGameStateHistory History;
	local StateObjectReference ItemRef;
	local XComGameState_Item ItemState;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));

	// Check the entire inventory - we don't care in which slot the item is present
	// This also supports mod-added items that have MS's effects

	foreach UnitState.InventoryItems(ItemRef)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
		if (ItemState == none) continue;

		if (default.MindShieldOnTiredNerf_Items.Find(ItemState.GetMyTemplateName()) != INDEX_NONE)
		{
			return true;
		}
	}

	return false;
}

static protected function EventListenerReturn OverrideDarkEventCount(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComLWTuple Tuple;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	
	Tuple = XComLWTuple(EventData);
	ResistanceHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	if (Tuple == none || Tuple.Id != 'OverrideDarkEventCount') return ELR_NoInterrupt;
	
	if (ResistanceHQ.NumMonths == 0)
	{
		Tuple.Data[0].i = default.NumDarkEventsFirstMonth;
	}
	else if (ResistanceHQ.NumMonths == 1)
	{
		Tuple.Data[0].i = default.NumDarkEventsSecondMonth;
	}
	else
	{
		Tuple.Data[0].i = default.NumDarkEventsThirdMonth;
	}
	
	if (Tuple.Data[1].b)
	{
		Tuple.Data[0].i += 1;
	}

	return ELR_NoInterrupt;
}
	
static protected function EventListenerReturn PreventLowSoldiersCovertActionNag(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn OverrideAddChosenTacticalTagsToMission (Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComGameState_AdventChosen ChosenState, LocalChosenState;
	local array<XComGameState_AdventChosen> AllChosen;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_MissionSite MissionState;
	local bool bForce, bGuaranteed, bSpawn;
	local float AppearChanceScalar;
	local name ChosenSpawningTag;
	local int AppearanceChance;
	local XComLWTuple Tuple;

	`log(GetFuncName() @ "start");

	MissionState = XComGameState_MissionSite(EventSource);
	Tuple = XComLWTuple(EventData);

	if (MissionState == none || Tuple == none || NewGameState == none) return ELR_NoInterrupt;
	
	`log(GetFuncName() @ `showvar(MissionState.GeneratedMission.Mission.sType));

	AlienHQ = class'UIUtilities_Strategy'.static.GetAlienHQ();
	AllChosen = AlienHQ.GetAllChosen(NewGameState);

	// Get the actual pending mission state
	MissionState = XComGameState_MissionSite(NewGameState.GetGameStateForObjectID(MissionState.ObjectID));

	// If another mod already did something, skip our logic
	if (Tuple.Data[0].b) 
	{
		`log(GetFuncName() @ "another mod already did something, skip our logic");
		return ELR_NoInterrupt;
	}

	// Do not mess with the guaranteed missions
	if (!ShouldManageChosenOnAssault(MissionState, NewGameState))
	{
		`log(GetFuncName() @ "ShouldManageChosenOnAssault() is false");
		return ELR_NoInterrupt;
	}

	// Infiltrations handle chosen internally
	if (MissionState.IsA(class'XComGameState_MissionSiteInfiltration'.Name))
	{
		`log(GetFuncName() @ "infiltration");
		Tuple.Data[0].b = true;
		return ELR_NoInterrupt;
	}

	// Ok, simple assault mission that allows chosen so we replace the logic
	`log(GetFuncName() @ "simple assault mission that allows chosen so we replace the logic");
	Tuple.Data[0].b = true;	

	// First, remove tags of dead chosen and find the one that controls our region
	foreach AllChosen(ChosenState)
	{
		if (ChosenState.bDefeated)
		{
			ChosenState.PurgeMissionOfTags(MissionState);
		}
		else if (ChosenState.ChosenControlsRegion(MissionState.Region))
		{
			LocalChosenState = ChosenState;
		}
	}

	// Check if we found someone who can appear here
	if (LocalChosenState == none)
	{
		`log(GetFuncName() @ "no chosen found");
		return ELR_NoInterrupt;
	}

	ChosenSpawningTag = LocalChosenState.GetMyTemplate().GetSpawningTag(LocalChosenState.Level);
	
	`log(GetFuncName() @ `showvar(LocalChosenState.GetMyTemplateName()) @ `showvar(ChosenSpawningTag));

	// Check if the chosen is already scheduled to spawn
	if (MissionState.TacticalGameplayTags.Find(ChosenSpawningTag) != INDEX_NONE)
	{
		`log(GetFuncName() @ "chosen tag already present");
		return ELR_NoInterrupt;
	}

	// Then see if the chosen is forced to show up (used to spawn chosen on specific missions when the global active flag is disabled)
	// The current use case for this is the "introduction retaliation" - if we active the chosen when the retal spawns and then launch an infil, the chosen will appear on the infil
	// This could be expanded in future if we choose to completely override chosen spawning handling
	if (MissionState.Source == 'MissionSource_Retaliation' && class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('CI_CompleteFirstRetal') == eObjectiveState_InProgress)
	{
		`log(GetFuncName() @ "forcing due to CI_CompleteFirstRetal");
		bForce = true;
	}

	// If chosen are not forced to show up and they are not active, bail
	if (!bForce && !AlienHQ.bChosenActive)
	{
		`log(GetFuncName() @ "!bForce && !AlienHQ.bChosenActive");
		return ELR_NoInterrupt;
	}

	// Now check for the guranteed spawn
	if (bForce)
	{
		bGuaranteed = true;
	}
	else if (LocalChosenState.NumEncounters == 0)
	{
		`log(GetFuncName() @ "guaranteed due to NumEncounters == 0");
		bGuaranteed = true;
	}

	// If we are checking only for the guranteed spawns and there isn't one, bail
	if (!bGuaranteed && Tuple.Data[1].b)
	{
		`log(GetFuncName() @ "!bGuaranteed && Tuple.Data[1].b");
		return ELR_NoInterrupt;
	}

	// See if the chosen should actually spawn or not (either guranteed or by a roll)
	if (bGuaranteed)
	{
		`log(GetFuncName() @ "spawn because guaranteed");
		bSpawn = true;
	}
	else if (CanChosenAppear(NewGameState))
	{
		AppearanceChance = LocalChosenState.GetChosenAppearChance();
		
		AppearChanceScalar = AlienHQ.ChosenAppearChanceScalar;
		if (AppearChanceScalar <= 0) AppearChanceScalar = 1.0f;

		`log(GetFuncName() @ "spawn roll");
		`log(GetFuncName() @ `showvar(LocalChosenState.CurrentAppearanceRoll));
		`log(GetFuncName() @ `showvar(LocalChosenState.MissionsSinceLastAppearance));
		`log(GetFuncName() @ `showvar(AppearanceChance));
		`log(GetFuncName() @ `showvar(AppearChanceScalar));
		`log(GetFuncName() @ `showvar(Round(float(AppearanceChance) * AppearChanceScalar)));

		if (LocalChosenState.CurrentAppearanceRoll < Round(float(AppearanceChance) * AppearChanceScalar))
		{
			`log(GetFuncName() @ "spawn roll success");
			bSpawn = true;
		}
		else
		{
			`log(GetFuncName() @ "spawn roll fail");
		}
	}
	else
	{
		`log(GetFuncName() @ "not bGuaranteed and not CanChosenAppear");
	}

	// Add the tag to mission if the chosen is to show up
	if (bSpawn)
	{
		`log(GetFuncName() @ "added" @ ChosenSpawningTag);
		MissionState.TacticalGameplayTags.AddItem(ChosenSpawningTag);
	}

	`log(GetFuncName() @ "exit");

	// We are finally done
	return ELR_NoInterrupt;
}

// Copy paste from XComGameState_HeadquartersAlien
static protected function bool CanChosenAppear (XComGameState NewGameState)
{
	local array<XComGameState_AdventChosen> ActiveChosen;
	local XComGameState_HeadquartersAlien AlienHQ;
	local int MinNumMissions, NumActiveChosen;

	AlienHQ = class'UIUtilities_Strategy'.static.GetAlienHQ();
	ActiveChosen = AlienHQ.GetAllChosen(NewGameState);
	NumActiveChosen = ActiveChosen.Length; // Can't inline ActiveChosen cuz unrealscript

	if(NumActiveChosen < 0)
	{
		MinNumMissions = class'XComGameState_HeadquartersAlien'.default.MinMissionsBetweenChosenAppearances[0];
	}
	else if(NumActiveChosen >= class'XComGameState_HeadquartersAlien'.default.MinMissionsBetweenChosenAppearances.Length)
	{
		MinNumMissions = class'XComGameState_HeadquartersAlien'.default.MinMissionsBetweenChosenAppearances[class'XComGameState_HeadquartersAlien'.default.MinMissionsBetweenChosenAppearances.Length - 1];
	}
	else
	{
		MinNumMissions = class'XComGameState_HeadquartersAlien'.default.MinMissionsBetweenChosenAppearances[NumActiveChosen];
	}

	`log(GetFuncName() @ `showvar(NumActiveChosen));
	`log(GetFuncName() @ `showvar(MinNumMissions));
	`log(GetFuncName() @ `showvar(AlienHQ.MissionsSinceChosen));

	return AlienHQ.MissionsSinceChosen >= MinNumMissions;
}

// Used by OverrideAddChosenTacticalTagsToMission and DLCInfo::ResetAssaultChosenRoll
//
// Note that currently uses of this function assume that it will filter out mission
// types where the chosen are either guranteed to show up or guranteed to not show up
// (i.e. do not use random rolls). If that is ever changed, uses might need to be adjusted
static function bool ShouldManageChosenOnAssault (XComGameState_MissionSite MissionState, optional XComGameState NewGameState = none)
{
	local array<XComGameState_AdventChosen> AllChosen;
	local XComGameState_AdventChosen ChosenState;

	// Do not mess with the golden path missions
	if (MissionState.GetMissionSource().bGoldenPath) 
	{
		`log(GetFuncName() @ "golden path mission");
		return false;
	}

	// Do not mess with missions that disallow chosen
	if (class'XComGameState_HeadquartersAlien'.default.ExcludeChosenMissionSources.Find(MissionState.Source) != INDEX_NONE)
	{
		`log(GetFuncName() @ "mission disallows chosen");
		return false;
	}

	// Do not mess with the chosen base defense
	if (MissionState.IsA(class'XComGameState_MissionSiteChosenAssault'.Name))
	{
		`log(GetFuncName() @ "chosen base defense");
		return false;
	}

	// Do not mess with the chosen stronghold assault
	AllChosen = class'UIUtilities_Strategy'.static.GetAlienHQ().GetAllChosen(NewGameState);
	foreach AllChosen(ChosenState)
	{
		if (ChosenState.StrongholdMission.ObjectID == MissionState.ObjectID)
		{
			`log(GetFuncName() @ "chosen stronghold assault");
			return false;
		}
	}

	return true;
}

static protected function EventListenerReturn PreCompleteStrategyFromTacticalTransfer (Object EventData, Object EventSource, XComGameState NullGameState, Name Event, Object CallbackData)
{
	PreCompleteStrategyFromTacticalTransfer_RewardInterception();
	PreCompleteStrategyFromTacticalTransfer_ForceRevealCounteredDE();

	return ELR_NoInterrupt;
}

static protected function PreCompleteStrategyFromTacticalTransfer_RewardInterception ()
{
	local XComGameState_ActivityChain ChainState;
	local XComGameState_Activity ActivityState;
	
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local bool bDirty;

	local XComGameState_Complication_RewardInterception ComplicationState;
	local XComGameState_ResourceContainer ResContainer;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;
	local StateObjectReference RewardRef;
	local XComGameState_Reward RewardState;
	local ResourcePackage Package;
	local int InterceptedQuantity;
	
	XComHQ = `XCOMHQ;
	ActivityState = class'XComGameState_Activity'.static.GetActivityFromPrimaryObjectID(XComHQ.MissionRef.ObjectID);
	if (ActivityState == none) return;
	
	ChainState = ActivityState.GetActivityChain();
	if (ChainState.GetLastActivity().ObjectID != ActivityState.ObjectID) return;
	
	ComplicationState = XComGameState_Complication_RewardInterception(ChainState.FindComplication('Complication_RewardInterception'));
	if (ComplicationState == none) return;

	if (!ComplicationState.bTriggered) return;

	// All checks have passed, we are good to do our magic
	`log("Processing Reward Interception");

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CI: Apply reward interception");
	ResContainer = XComGameState_ResourceContainer(NewGameState.ModifyStateObject(class'XComGameState_ResourceContainer', ComplicationState.ResourceContainerRef.ObjectID));
	History = `XCOMHISTORY;
	
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));

	foreach MissionState.Rewards(RewardRef)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRef.ObjectID));
		if (RewardState == none) continue;

		if (!class'X2StrategyElement_DefaultComplications'.static.IsInterceptableItem(RewardState.GetMyTemplate().rewardObjectTemplateName))
		{
			`log(RewardState.GetMyTemplateName() @ "is not interceptable - skipping");
			continue;
		}
		
		`log(RewardState.GetMyTemplateName() @ "is intercepted");
		bDirty = true;
		
		// Reduce the quantity
		RewardState = XComGameState_Reward(NewGameState.ModifyStateObject(class'XComGameState_Reward', RewardState.ObjectID));
		InterceptedQuantity = RewardState.Quantity * class'X2StrategyElement_DefaultComplications'.default.REWARD_INTERCEPTION_TAKENLOOT;
		RewardState.Quantity -= InterceptedQuantity;

		// Store the quantity to give later
		Package.ItemType = RewardState.GetMyTemplate().rewardObjectTemplateName;
		Package.ItemAmount = InterceptedQuantity;
		ResContainer.Packages.AddItem(Package);
	}

	// Save the changes, if there was any intercepted items
	if (bDirty)	
	{
		ComplicationState = XComGameState_Complication_RewardInterception(NewGameState.ModifyStateObject(class'XComGameState_Complication_RewardInterception', ComplicationState.ObjectID));
		ComplicationState.RewardStateIntercepted = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else 
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

// Note: we cannot use the activity status since this code runs before the mission callbacks are triggered.
// Such earliness is needed since the reward text is cached before the mission callbacks are triggered.
// As such, need to manually keep in sync with X2StrategyElement_DefaultActivityChains::CleanupDarkEventChain.
static protected function PreCompleteStrategyFromTacticalTransfer_ForceRevealCounteredDE ()
{
	local XComGameState_ActivityChain ChainState;
	local XComGameState_DarkEvent DarkEventState;
	local XComGameState_Activity ActivityState;
	local XComGameState_BattleData BattleData;
	local XComGameState NewGameState;

	ActivityState = class'XComGameState_Activity'.static.GetActivityFromPrimaryObjectID(`XCOMHQ.MissionRef.ObjectID);
	if (ActivityState == none) return;
	
	ChainState = ActivityState.GetActivityChain();
	if (ChainState.GetMyTemplateName() != 'ActivityChain_CounterDarkEvent') return;
	if (ChainState.GetLastActivity().ObjectID != ActivityState.ObjectID) return;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if (!BattleData.bLocalPlayerWon) return;

	DarkEventState = ChainState.GetChainDarkEvent();
	if (!DarkEventState.bSecretEvent) return;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CI: Force reveal DE");
	DarkEventState = XComGameState_DarkEvent(NewGameState.ModifyStateObject(class'XComGameState_DarkEvent', DarkEventState.ObjectID));

	DarkEventState.bSecretEvent = false;

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

static protected function EventListenerReturn AllowNoSquadSizeUpgradeAchievement (Object EventData, Object EventSource, XComGameState NullGameState, Name EventID, Object CallbackData)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComLWTuple Tuple;

	Tuple = XComLWTuple(EventData);

	if (Tuple == none || Tuple.Id != 'AllowNoSquadSizeUpgradeAchievement') return ELR_NoInterrupt;

	XComHQ = `XCOMHQ;

	Tuple.Data[0].b = !(XComHQ.HasSoldierUnlockTemplate('InfiltrationSize1') || XComHQ.HasSoldierUnlockTemplate('InfiltrationSize2'));

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn BlackMarketGoodsReset (Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2ItemTemplateManager ItemTemplateMgr;
	local XComGameState_BlackMarket MarketState;
	local XComGameState_Reward RewardState;
	local X2RewardTemplate RewardTemplate;
	local XComGameState_Item ItemState;
	local X2ItemTemplate ItemTemplate;
	local Commodity ForSaleItem;

	MarketState = XComGameState_BlackMarket(EventData);
	if (MarketState == none) return ELR_NoInterrupt;

	// Check if we reached the relevant part of the game
	if (!class'X2Helper_Infiltration'.static.IsLeadsSystemEngaged()) return ELR_NoInterrupt;

	// Check if the player bought the first lead already
	if (class'XComGameState_CovertInfiltrationInfo'.static.GetInfo().bBlackMarketLeadPurchased) return ELR_NoInterrupt;

	// Get the latest pending state
	MarketState = XComGameState_BlackMarket(NewGameState.ModifyStateObject(class'XComGameState_BlackMarket', MarketState.ObjectID));

	// Create the item
	ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemTemplate = ItemTemplateMgr.FindItemTemplate('ActionableFacilityLead');
	ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
	ItemState.Quantity = 1;

	// Create the reward
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_Item'));
	RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	RewardState.SetReward(ItemState.GetReference());

	// Fill out the commodity (default)
	ForSaleItem.RewardRef = RewardState.GetReference();
	ForSaleItem.Image = RewardState.GetRewardImage();
	ForSaleItem.CostScalars = MarketState.GoodsCostScalars;
	ForSaleItem.DiscountPercent = MarketState.GoodsCostPercentDiscount;

	// Fill out the commodity (custom)
	ForSaleItem.Title = ItemTemplate.GetItemFriendlyName(); // Get rid of the "1"
	ForSaleItem.Desc = default.strOneTimeMarketLeadDescription;
	ForSaleItem.Cost = default.OneTimeMarketLeadCost[`StrategyDifficultySetting];

	// Add to sale
	MarketState.ForSaleItems.AddItem(ForSaleItem);

	// We are done
	return ELR_NoInterrupt;
}

static protected function EventListenerReturn BlackMarketPurchase_OSS (Object EventData, Object EventSource, XComGameState SubmittedGameState, Name Event, Object CallbackData)
{
	local XComGameState_CovertInfiltrationInfo CIInfo;
	local XComGameState_Reward RewardState;
	local XComGameState_Item ItemState;
	local XComGameState NewGameState;

	RewardState = XComGameState_Reward(EventData);
	if (RewardState == none) return ELR_NoInterrupt;

	ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));
	if (ItemState == none) return ELR_NoInterrupt;
	
	// Make sure we bought a lead and not something else
	if (ItemState.GetMyTemplateName() != 'ActionableFacilityLead') return ELR_NoInterrupt;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CI: Handling BM Actionable Lead purchase");
	class'X2Helper_Infiltration'.static.UpdateFacilityMissionLocks(NewGameState);
	CIInfo = class'XComGameState_CovertInfiltrationInfo'.static.ChangeForGamestate(NewGameState);
	CIInfo.bBlackMarketLeadPurchased = true;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if (`HQPRES.StrategyMap2D != none) `HQPRES.StrategyMap2D.UpdateMissions();

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn AddResource_OSS (Object EventData, Object EventSource, XComGameState SubmittedGameState, Name Event, Object CallbackData)
{
	local XComGameState_Item ResourceItemState;

	ResourceItemState = XComGameState_Item(EventData);
	if (ResourceItemState == none) return ELR_NoInterrupt;

	if (ResourceItemState.GetMyTemplateName() == 'ActionableFacilityLead')
	{
		class'X2Helper_Infiltration'.static.UpdateFacilityMissionLocks();
		if (`HQPRES.StrategyMap2D != none) `HQPRES.StrategyMap2D.UpdateMissions();
	}

	 return ELR_NoInterrupt;
}

static protected function EventListenerReturn AddSquadSelectSlotNotes(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local UIScreenStack ScreenStack;
	local UICovertActionsGeoscape CovertActions;

	local LWTuple Tuple;
	local int SlotIndex;

	local SSAAT_SlotNote Note;
	local LWTuple NoteTuple;
	local LWTValue Value;

	Tuple = LWTuple(EventData);
	
	// Check that we are interested in actually doing something
	if (Tuple == none || Tuple.Id != 'rjSquadSelect_ExtraInfo') return ELR_NoInterrupt;
	
	ScreenStack = `SCREENSTACK;
	CovertActions = UICovertActionsGeoscape(ScreenStack.GetFirstInstanceOf(class'UICovertActionsGeoscape'));
	
	if (CovertActions == none) return ELR_NoInterrupt;
	
	// don't show warning if the activity will result in combat either through infiltration or ambush
	if (class'X2Helper_Infiltration'.static.IsInfiltrationAction(CovertActions.SSManager.GetAction())) return ELR_NoInterrupt;
	if (class'X2Helper_Infiltration'.static.ActionHasAmbushRisk(CovertActions.SSManager.GetAction())) return ELR_NoInterrupt;

	SlotIndex = Tuple.Data[0].i;

	if (!class'X2Helper_Infiltration'.static.UnitHasIrrelevantItems(`XCOMHQ.Squad[SlotIndex])) return ELR_NoInterrupt;

	Note = class'UISSManager_CovertAction'.static.CreateIrrelevantNote();
	
	Value.kind = LWTVObject;
	NoteTuple = new class'LWTuple';
	NoteTuple.Data.Length = 3;
	
	NoteTuple.Data[0].kind = LWTVString;
	NoteTuple.Data[0].s = Note.Text;

	NoteTuple.Data[1].kind = LWTVString;
	NoteTuple.Data[1].s = Note.TextColor;
  
	NoteTuple.Data[2].kind = LWTVString;
	NoteTuple.Data[2].s = Note.BGColor;

	Value.o = NoteTuple;
	Tuple.Data.AddItem(Value);
	
	return ELR_NoInterrupt;
}

////////////////
/// Tactical ///
////////////////

static function CHEventListenerTemplate CreateTacticalListeners()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'Infiltration_Tactical');
	Template.AddCHEvent('SquadConcealmentBroken', CallReinforcementsOnSupplyExtraction, ELD_OnStateSubmitted, 99);
	Template.AddCHEvent('ScamperEnd', CallReinforcementsOnSupplyExtraction, ELD_OnStateSubmitted, 99);
	Template.AddCHEvent('OnTacticalBeginPlay', OnTacticalPlayBegun_VeryEarly, ELD_OnStateSubmitted, 99999);
	Template.AddCHEvent('OnTacticalBeginPlay', OnTacticalPlayBegun_VeryLate, ELD_OnStateSubmitted, -99999);
	Template.AddCHEvent('OverrideKillXp', OverrideKillXp, ELD_Immediate, 99);
	Template.AddCHEvent('PostAliensSpawned', PostAliensSpawned, ELD_Immediate, 99);
	Template.AddCHEvent('KismetGameStateMatinee', KismetGameStateMatinee_PreSupplyExtract, ELD_OnVisualizationBlockStarted, 99);
	Template.AddCHEvent('KismetGameStateMatinee', KismetGameStateMatinee_PostSupplyExtract, ELD_OnVisualizationBlockCompleted, 99);
	Template.AddCHEvent('OnUnitBeginPlay', OnUnitBeginPlay_CheckTired, ELD_OnStateSubmitted, 99);
	Template.RegisterInTactical = true;

	return Template;
}

static function EventListenerReturn CallReinforcementsOnSupplyExtraction(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState NewGameState;
	local XComGameState_CIReinforcementsManager ManagerState;
	local DelayedReinforcementOrder DelayedReinforcementOrder;
	local XComGameState_CovertInfiltrationInfo CIInfo;

	if (`TACTICALMISSIONMGR.ActiveMission.sType != "SupplyExtraction")
	{
		return ELR_NoInterrupt;
	}

	// Check if we activated the system already
	CIInfo = class'XComGameState_CovertInfiltrationInfo'.static.GetInfo();
	if (CIInfo.bSupplyExtractionRnfsStarted) return ELR_NoInterrupt;

	// Hold until the player squad is revealed
	if (
		default.SupplyExtraction_HoldResponseUntilSquadReveal &&
		Event == 'ScamperEnd' &&
		class'XComGameState_Player'.static.GetPlayerState(eTeam_XCom).bSquadIsConcealed
	)
	{
		return ELR_NoInterrupt;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CI: CallReinforcementsOnSupplyExtraction");
	ManagerState = class'XComGameState_CIReinforcementsManager'.static.GetReinforcementsManager();
	ManagerState = XComGameState_CIReinforcementsManager(NewGameState.ModifyStateObject(class'XComGameState_CIReinforcementsManager', ManagerState.ObjectID));

	DelayedReinforcementOrder.EncounterID = 'ADVx3_Standard';
	DelayedReinforcementOrder.TurnsUntilSpawn = 3;
	DelayedReinforcementOrder.Repeating = true;
	DelayedReinforcementOrder.RepeatTime = 2;

	ManagerState.DelayedReinforcementOrders.AddItem(DelayedReinforcementOrder);

	CIInfo = class'XComGameState_CovertInfiltrationInfo'.static.ChangeForGamestate(NewGameState);
	CIInfo.bSupplyExtractionRnfsStarted = true;

	`TACTICALRULES.SubmitGameState(NewGameState);

	// Fix for advent extraction never starting when starting mission without concealment
	if (Event == 'ScamperEnd') KismetStartSupplyExtract();

	return ELR_NoInterrupt;
}

// MUST BE CALLED
// 1) Inside gamestate submission "thread"
// 2) Without pending gamestate (inside ELD_OnStateSubmitted window)
static protected function KismetStartSupplyExtract ()
{
	local array<SequenceObject> Events;
	local SeqEvent_X2GameState Event;
	local WorldInfo WorldInfo;
	local Sequence GameSeq;
	local int Index;

	WorldInfo = class'WorldInfo'.static.GetWorldInfo();
	GameSeq = class'WorldInfo'.static.GetWorldInfo().GetGameSequence();

	GameSeq.FindSeqObjectsByClass(class'SeqEvent_X2GameState', true, Events);
	for (Index = 0; Index < Events.length; ++Index)
	{
		Event = SeqEvent_X2GameState(Events[Index]);

		if (Event == none) continue;
		if (Event.EventName != 'UMS_XCOMFirstLossOfConcealment') continue;
		if (Event.GetPackageName() != 'Obj_SupplyExtraction_CI') continue;

		// Correct node, FIRE
		Event.CheckActivate(WorldInfo, none);
	}
}

static function EventListenerReturn OnTacticalPlayBegun_VeryEarly (Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	// Ensure that our singletons exist
	class'XComGameState_CovertInfiltrationInfo'.static.CreateInfo();
	class'XComGameState_CIReinforcementsManager'.static.CreateReinforcementsManager();

	return ELR_NoInterrupt;
}

static function EventListenerReturn OnTacticalPlayBegun_VeryLate (Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local X2TacticalGameRuleset GameRules;
	local XComGameState NewGameState;
	local XComGameState_BattleData BattleData;
	local XComGameState_Activity ActivityState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CI: OnTacticalPlayBegun_VeryLate");

	// We want to do this very late, since some mods spawn units in OnTacticalBeginPlay and we want to account for them
	class'X2Helper_Infiltration'.static.SetStartingEnemiesForXp(NewGameState);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	// If supply extract, show tutorial
	if (`TACTICALMISSIONMGR.ActiveMission.sType == "SupplyExtraction")
	{
		class'UIUtilities_InfiltrationTutorial'.static.SupplyExtractMission();
	}
	
	GameRules = X2TacticalGameRuleset(EventData);
	BattleData = XComGameState_BattleData(GameRules.CachedHistory.GetGameStateForObjectID(GameRules.GetCachedBattleDataRef().ObjectID));
	ActivityState = class'XComGameState_Activity'.static.GetActivityFromPrimaryObjectID(BattleData.m_iMissionID);

	// If avatar DVIP capture, show tutorial
	if (ActivityState != none && ActivityState.GetActivityChain().GetMyTemplateName() == 'ActivityChain_DestroyFacility')
	{
		class'UIUtilities_InfiltrationTutorial'.static.AvatarCaptureMission();
	}

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn OverrideKillXp (Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local float KillXp, BonusKillXp, KillAssistXp, XpMult;
	local XComGameState_Unit KillerState, VictimState;
	local XComLWTuple Tuple;
	local int WetWorkXp;

	VictimState = XComGameState_Unit(EventSource);
	Tuple = XComLWTuple(EventData);

	KillXp = Tuple.Data[0].f;
	BonusKillXp = Tuple.Data[1].f;
	KillAssistXp = Tuple.Data[2].f;
	WetWorkXp = Tuple.Data[3].i;
	KillerState = XComGameState_Unit(Tuple.Data[4].o);

	`log("Processing kill XP granted by" @ VictimState.GetFullName() @ "to" @ KillerState.GetFullName() $ ". Original values:");
	`log(`showvar(KillXp));
	`log(`showvar(BonusKillXp));
	`log(`showvar(KillAssistXp));
	`log(`showvar(WetWorkXp));

	// First record the kill - it's needed for GetKillContributionMultiplerForKill
	class'XComGameState_CovertInfiltrationInfo'.static.ChangeForGamestate(NewGameState)
		.RecordCharacterGroupsKill(VictimState.GetMyTemplate().CharacterGroupName);

	XpMult = class'X2Helper_Infiltration'.static.GetKillContributionMultiplerForKill(VictimState.GetMyTemplate().CharacterGroupName);

	// Scale the values
	KillXp *= XpMult;
	BonusKillXp *= XpMult;
	KillAssistXp *= XpMult;

	// Special handling for Wet Work GTS bonus
	// In theory, this code should never matter as wet work was removed in WOTC
	// However, the code is still there, and can very easily reenabled by a mod
	// As such, we would like to handle this case as well - apply the bonus as
	// BonusKills (WOTC's replacement for WetWorkKills)
	BonusKillXp += WetWorkXp * class'X2ExperienceConfig'.default.NumKillsBonus * XpMult;
	WetWorkXp = 0;

	`log("Finished processing kill XP. Final values:");
	`log(`showvar(XpMult));
	`log(`showvar(KillXp));
	`log(`showvar(BonusKillXp));
	`log(`showvar(KillAssistXp));
	`log(`showvar(WetWorkXp));

	Tuple.Data[0].f = KillXp;
	Tuple.Data[1].f = BonusKillXp;
	Tuple.Data[2].f = KillAssistXp;
	Tuple.Data[3].i = WetWorkXp;

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn PostAliensSpawned (Object EventData, Object EventSource, XComGameState StartGameState, Name Event, Object CallbackData)
{
	if (`TACTICALMISSIONMGR.ActiveMission.sType == "CovertEscape")
	{
		`log("CovertEscape PostAliensSpawned ClearPendingLootFromAllUnits");
		ClearPendingLootFromAllUnits(StartGameState);
	}

	return ELR_NoInterrupt;
}

static protected function ClearPendingLootFromAllUnits (XComGameState StartGameState)
{
	local XComGameState_Unit UnitState;
	local LootResults EmptyLootResults;
	local StateObjectReference ItemRef;
	local bool bHasLoot;

	EmptyLootResults.bRolledForLoot = true;

	foreach StartGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		bHasLoot = false;

		if (UnitState.PendingLoot.LootToBeCreated.Length > 0)
		{
			bHasLoot = true;
		}
		
		if (UnitState.PendingLoot.AvailableLoot.Length > 0)
		{
			bHasLoot = true;

			foreach UnitState.PendingLoot.AvailableLoot(ItemRef)
			{
				// Let's hope this is actually a fresh item and not something else...
				StartGameState.RemoveStateObject(ItemRef.ObjectID);

				`log("Removed loot" @ ItemRef.ObjectID @ "carried by" @ UnitState.ObjectID @ UnitState.GetMyTemplateName() @ UnitState.GetFullName());
			}
		}

		if (bHasLoot)
		{
			UnitState.SetLoot(EmptyLootResults);

			`log("Cleared pending loot from" @ UnitState.ObjectID @ UnitState.GetMyTemplateName() @ UnitState.GetFullName());
		}
	}
}

static protected function EventListenerReturn KismetGameStateMatinee_PreSupplyExtract (Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	TrySetSupplyExtractorATTVisibility(true, GameState);
	return ELR_NoInterrupt;
}

static protected function EventListenerReturn KismetGameStateMatinee_PostSupplyExtract (Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	TrySetSupplyExtractorATTVisibility(false, GameState);
	return ELR_NoInterrupt;
}

static protected function TrySetSupplyExtractorATTVisibility (bool bNewVisible, XComGameState GameState)
{
	local XComGameStateContext_Kismet KismetContext;
	local SeqAct_PlayGameStateMatinee Trigger;
	local SkeletalMeshActor MeshActor;

	// Check that we are in the correct mission type
	if (`TACTICALMISSIONMGR.ActiveMission.sType != "SupplyExtraction") return;

	KismetContext = XComGameStateContext_Kismet(GameState.GetContext());
	if (KismetContext == none) return;

	Trigger = SeqAct_PlayGameStateMatinee(KismetContext.FindSequenceOp());
	if (Trigger == none) return;

	// Check that it's the correct matinee
	if (Trigger.MatineeComment != "CIN_SupplyExtraction_ATTArrives") return;

	// Find the ATT actor
	foreach `XWORLDINFO.AllActors(class'SkeletalMeshActor', MeshActor)
	{
		if (
			MeshActor.GetPackageName() == 'CIN_XP_SupplyExtractionATTArrival' &&
			PathName(MeshActor.SkeletalMeshComponent.SkeletalMesh) == "TroopTransport_ANIM.Meshes.SM_TroopTransport"
		)
		{
			MeshActor.SetHidden(!bNewVisible);
			break;
		}
	}
}

static protected function EventListenerReturn OnUnitBeginPlay_CheckTired (Object EventData, Object EventSource, XComGameState EventGameState, Name Event, Object CallbackData)
{
	local XComGameState_CovertInfiltrationInfo CIInfo;
	local XComGameState_BattleData BattleDataState;
	local XComGameState_Unit UnitState;
	local XComGameState NewGameState;
	local string strDebugUnit;

	// Get the unit as it was at the frame that event was triggered.
	// EventSource is the latest and we could've have more frames since.
	UnitState = XComGameState_Unit(EventSource);
	UnitState = XComGameState_Unit(EventGameState.GetGameStateForObjectID(UnitState.ObjectID));

	if (UnitState == none)
	{
		`RedScreen(nameof(OnUnitBeginPlay_CheckTired) $ ": failed to fetch UnitState???");
		return ELR_NoInterrupt;
	}

	// We need the version of the unit before the play begun - we care how the unit was
	// sent into tactical, bypassing any begin play logic.
	// If there is no previous version, then the unit was created mid-tactical - don't care
	UnitState = XComGameState_Unit(UnitState.GetPreviousVersion());
	if (UnitState == none) return ELR_NoInterrupt;

	strDebugUnit = UnitState.ObjectID @ "\"" $ UnitState.GetFullName() $ "\"";

	// For future debugging, if any
	if (UnitState.IsInPlay())
	{
		`RedScreen(nameof(OnUnitBeginPlay_CheckTired) $ ": unit" @ strDebugUnit @ "previous state is in play. Not fatal, but likely incorrect");
	}

	if (!UnitState.UsesWillSystem())
	{
		return ELR_NoInterrupt;
	}

	// Check that it's the first time that the unit is begining play (relevant for multi-part missions)
	// Logic adapted from CHL#44
	BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if (
		BattleDataState.DirectTransferInfo.IsDirectMissionTransfer &&
		BattleDataState.DirectTransferInfo.TransferredUnitStats.Find('UnitStateRef', UnitState.GetReference()) != INDEX_NONE
	)
	{
		`log(nameof(OnUnitBeginPlay_CheckTired) $ ": unit" @ strDebugUnit @ "was transferred from tactical, skipping");
		return ELR_NoInterrupt;
	}

	if (!UnitState.BelowReadyWillState())
	{
		`log(nameof(OnUnitBeginPlay_CheckTired) $ ": unit" @ strDebugUnit @ "is not tired, skipping");
		return ELR_NoInterrupt;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CI: Mark unit started below ready will:" @ UnitState.ObjectID @ UnitState.GetFullName());
	CIInfo = class'XComGameState_CovertInfiltrationInfo'.static.ChangeForGamestate(NewGameState);
	CIInfo.UnitsStartedMissionBelowReadyWill.AddItem(UnitState.GetReference());
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`log(nameof(OnUnitBeginPlay_CheckTired) $ ": unit" @ strDebugUnit @ "recorded as below ready will");

	return ELR_NoInterrupt;
}
