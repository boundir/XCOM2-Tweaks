//---------------------------------------------------------------------------------------
//  AUTHOR:  Xymanek and NotSoLoneWolf
//  PURPOSE: Replacement for base game MissionCalendar which instead spawns activity 
//           chains based on "work" done by XCom (base) and contacted regions
//           and relays built (bonus)
//---------------------------------------------------------------------------------------
//  WOTCStrategyOverhaul Team
//---------------------------------------------------------------------------------------

class XComGameState_ActivityChainSpawner extends XComGameState_BaseObject config(Infiltration);

var protectedwrite float PreviousWork;
var protectedwrite TDateTime PreviousWorkSubmittedAt;

// Work rate is meaured in hours
var protectedwrite int CachedWorkRate;
var protectedwrite int NextSpawnAt; // In work units

var const config array<int> WorkRateXcom;
var const config array<int> WorkRatePerContact;
var const config array<int> WorkRatePerRelay;
var const config bool bStartingRegionContributesToWork;

var const config array<int> GameStartWork; // How much work to add when the campaign starts
var const config array<int> WorkRequiredForSpawn;
var const config array<int> WorkRequiredForSpawnVariance;

static function Update()
{
	local XComGameState_ActivityChainSpawner Spawner;
	local XComGameState NewGameState;
	local UIStrategyMap StrategyMap;
	local bool bDirty;

	Spawner = GetSpawner(false); // Do not spam redscreens every tick
	if (Spawner == none)
	{
		`RedScreenOnce("CI: Failed to fetch XComGameState_ActivityChainSpawner for ticking");
		return;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CI: XComGameState_ActivityChainSpawner update");
	Spawner = XComGameState_ActivityChainSpawner(NewGameState.ModifyStateObject(class'XComGameState_ActivityChainSpawner', Spawner.ObjectID));
	
	StrategyMap = `HQPRES.StrategyMap2D;

	// STEP 1: we check if we are due spawning an action at CachedWorkRate
	if (Spawner.ShouldSpawnChain() && StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight)
	{
		`log("Enough work for activity chain, starting spawning");
		bDirty = true;
		
		Spawner.SpawnActivityChain(NewGameState);
		Spawner.ResetProgress();
		Spawner.SetNextSpawnAt();
	}

	// STEP 2: See if we need to adjust current work rate
	if (Spawner.CachedWorkRate != GetCurrentWorkRate())
	{
		`log("Cached work rate (" $ Spawner.CachedWorkRate $ ") doesn't match current, submitting work done and caching new work rate");
		bDirty = true;
		
		Spawner.SubmitWorkDone();
		Spawner.SetCachedWorkRate();
	}

	if (bDirty)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}
}

///////////////////
/// Bookkeeping ///
///////////////////

function bool ShouldSpawnChain()
{
	local float WorkDone;

	WorkDone = PreviousWork + GetWorkDoneInCurrentPeriod();

	return WorkDone >= NextSpawnAt;
}

function ResetProgress()
{
	`log("Reset progress for next chain");

	PreviousWork = 0;
	PreviousWorkSubmittedAt = `STRATEGYRULES.GameTime;
}

function SubmitWorkDone()
{
	PreviousWork += GetWorkDoneInCurrentPeriod();
	PreviousWorkSubmittedAt = `STRATEGYRULES.GameTime;

	`log("Submitted work done, now" $ PreviousWork);
}

function float GetWorkDoneInCurrentPeriod()
{
	local int MinutesSinceLastSubmission;
	local float HoursSinceLastSubmission;

	MinutesSinceLastSubmission = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMinutes(`STRATEGYRULES.GameTime, PreviousWorkSubmittedAt);
	HoursSinceLastSubmission = MinutesSinceLastSubmission / 60;
	
	return fmax(CachedWorkRate * HoursSinceLastSubmission, 0);
}

static function int GetCurrentWorkRate()
{
	local int Contacts, Relays, WorkRate;

	GetNumContactsAndRelays(Contacts, Relays);

	WorkRate = `ScaleStrategyArrayInt(default.WorkRateXcom);
	Workrate += Contacts * `ScaleStrategyArrayInt(default.WorkRatePerContact);
	Workrate += Relays * `ScaleStrategyArrayInt(default.WorkRatePerRelay);

	return WorkRate;
}

function SetCachedWorkRate()
{
	CachedWorkRate = GetCurrentWorkRate();
	`log("New cached work rate - " $ CachedWorkRate);
}

static function GetNumContactsAndRelays(out int Contacts, out int Relays)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_WorldRegion Region;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	XComHQ = `XCOMHQ;
	Contacts = 0;
	Relays = 0;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', Region)
	{
		if (!default.bStartingRegionContributesToWork && XComHQ.StartingRegion.ObjectID == Region.ObjectID)
		{
			continue;
		}

		if (Region.ResistanceLevel == eResLevel_Contact)
		{
			Contacts++;
		}

		if (Region.ResistanceLevel == eResLevel_Outpost)
		{
			Contacts++;
			Relays++;
		}
	}
}

function SetNextSpawnAt(optional bool StartingChain = false)
{
	local int WorkRequired, Variance;
	local bool bVarianceHigher;

	WorkRequired = `ScaleStrategyArrayInt(WorkRequiredForSpawn);
	NextSpawnAt = WorkRequired;

	if (StartingChain == false)
	{
		Variance = `SYNC_RAND(`ScaleStrategyArrayInt(WorkRequiredForSpawnVariance));

		bVarianceHigher = `SYNC_RAND(2) < 1;
		if (!bVarianceHigher) Variance *= -1;

		NextSpawnAt = WorkRequired + Variance;
	}

	`log("Next chain at" @ NextSpawnAt @ "work");
}

////////////////
/// Spawning ///
////////////////

function SpawnActivityChain (XComGameState NewGameState)
{
	local XComGameState_ActivityChain ChainState;
	local X2ActivityChainTemplate ChainTemplate;

	BuildChainDeck();
	ChainTemplate = PickChainToSpawn(NewGameState);

	if (ChainTemplate == none)
	{
		`RedScreen("CI: Cannot spawn chain - failed to pick a chain");
		return;
	}

	`log("All inputs ok, spawning chain");

	ChainState = ChainTemplate.CreateInstanceFromTemplate(NewGameState);
	ChainState.StartNextStage(NewGameState);
}

static protected function BuildChainDeck ()
{
	local X2StrategyElementTemplateManager TemplateManager;
	local X2ActivityChainTemplate ChainTemplate;
	local X2DataTemplate DataTemplate;
	local X2CardManager CardManager;

	TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	CardManager = class'X2CardManager'.static.GetCardManager();

	foreach TemplateManager.IterateTemplates(DataTemplate)
	{
		ChainTemplate = X2ActivityChainTemplate(DataTemplate);
		if (ChainTemplate == none) continue;

		if (ChainTemplate.SpawnInDeck)
		{
			CardManager.AddCardToDeck('ActivityChainSpawner', string(ChainTemplate.DataName), ChainTemplate.NumInDeck);
		}
	}
}

protected function X2ActivityChainTemplate PickChainToSpawn (XComGameState NewGameState)
{
	local X2StrategyElementTemplateManager TemplateManager;
	local X2ActivityChainTemplate ChainTemplate;
	local X2CardManager CardManager;
	local array<string> CardLabels;
	local string Card;

	TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	CardManager = class'X2CardManager'.static.GetCardManager();
	
	CardManager.GetAllCardsInDeck('ActivityChainSpawner', CardLabels);
	foreach CardLabels(Card)
	{
		ChainTemplate = X2ActivityChainTemplate(TemplateManager.FindStrategyElementTemplate(name(Card)));
		if (ChainTemplate == none) continue;
		
		if (!ChainTemplate.SpawnInDeck) continue;
		if (!ChainTemplate.DeckReq(NewGameState)) continue;

		CardManager.MarkCardUsed('ActivityChainSpawner', Card);

		return ChainTemplate;
	}

	return none;
}

///////////////////
/// Dark events ///
///////////////////

// Called from X2EventListener_Infiltration::PostEndOfMonth
static function SpawnCounterDarkEvents (XComGameState NewGameState)
{
	local X2StrategyElementTemplateManager TemplateManager;
	local XComGameState_HeadquartersAlien AlienHQ;
	
	local array<StateObjectReference> ChainObjectRefs;
	local XComGameState_DarkEvent DarkEventState;
	local StateObjectReference DarkEventRef, SelectedRegion;
	local array<StateObjectReference> DarkEventRefs, RegionRefs;

	local array<XComGameState_ActivityChain> SpawnedChains;
	local XComGameState_ActivityChain ChainState;
	local X2ActivityChainTemplate ChainTemplate;

	local int SecondsDelay, SecondsDuration, WindowDuration, SecondsChainDelay;
	local XComGameState_Activity_Wait WaitActivity;
	local int i;

	AlienHQ = class'UIUtilities_Strategy'.static.GetAlienHQ();
	TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	ChainTemplate = X2ActivityChainTemplate(TemplateManager.FindStrategyElementTemplate('ActivityChain_CounterDarkEvent'));

	// Step 1: spawn the chains

	RegionRefs = GetContactedRegions();
	DarkEventRefs = AlienHQ.ChosenDarkEvents;

	`log("Initial Events:" @ DarkEventRefs.Length);
	
	for (i = 0; i < DarkEventRefs.Length; i++)
	{
		DarkEventRef = DarkEventRefs[i];
		DarkEventState = XComGameState_DarkEvent(`XCOMHISTORY.GetGameStateForObjectID(DarkEventRef.ObjectID));
		
		`log("Evaluating:" @ DarkEventState.GetMyTemplateName());

		if (DarkEventState == none)
		{
			DarkEventRefs.Remove(i, 1);
			i--;
			continue;
		}

		// Chosen-initiated DEs cannot be countered
		if (DarkEventState.bChosenActionEvent)
		{
			DarkEventRefs.Remove(i, 1);
			i--;
			continue;
		}
		
		`log("Cleared:" @ DarkEventState.GetMyTemplateName());
	}
	
	`log("Loop Begins!");
	
	while (DarkEventRefs.Length > 0 && RegionRefs.Length > 0)
	{
		`log("Regions:" @ RegionRefs.Length);
		`log("Events:" @ DarkEventRefs.Length);
		`log("Spawns:" @ SpawnedChains.Length);

		DarkEventRef = DarkEventRefs[`SYNC_RAND_STATIC(DarkEventRefs.Length)];
		DarkEventRefs.RemoveItem(DarkEventRef);

		DarkEventState = XComGameState_DarkEvent(`XCOMHISTORY.GetGameStateForObjectID(DarkEventRef.ObjectID));
		
		`log("Spawning:" @ DarkEventState.GetMyTemplateName());

		ChainObjectRefs.Length = 0;
		ChainObjectRefs.AddItem(DarkEventRef);

		SelectedRegion = RegionRefs[`SYNC_RAND_STATIC(RegionRefs.Length)];
		RegionRefs.RemoveItem(SelectedRegion);

		ChainState = ChainTemplate.CreateInstanceFromTemplate(NewGameState, ChainObjectRefs);
		ChainState.PrimaryRegionRef = SelectedRegion;
		ChainState.SecondaryRegionRef = SelectedRegion;
		ChainState.StartNextStage(NewGameState);
		
		SpawnedChains.AddItem(ChainState);
	}
	
	`log("Regions:" @ RegionRefs.Length);
	`log("Events:" @ DarkEventRefs.Length);
	`log("Spawns:" @ SpawnedChains.Length);
	
	`log("Loop Broken!");

	// If we didn't manage to make any chains, don't bother with the timing
	if (SpawnedChains.Length == 0) return;

	// Step 2: spread them randomly over the beginning of the month

	GetCounterDarkEventPeriodStartAndDuration(SecondsDelay, SecondsDuration);
	WindowDuration = SecondsDuration / SpawnedChains.Length;
	SpawnedChains = SortChainsRandomly(SpawnedChains);

	foreach SpawnedChains(ChainState, i)
	{
		WaitActivity = XComGameState_Activity_Wait(ChainState.GetActivityAtIndex(0));
		// No need to call NewGameState.ModifyStateObject here as the object was just created above

		if (WaitActivity == none)
		{
			`RedScreen("Counter DE chain should start with XComGameState_Activity_Wait so that it can be delayed by the spawner");
			continue;
		}

		SecondsChainDelay =
			SecondsDelay + // The global delay for all counter DE chains
			i * WindowDuration + // Account for previous chains
			`SYNC_RAND_STATIC(WindowDuration); // Pop somewhere randomly within our window

		WaitActivity.ProgressAt = `STRATEGYRULES.GameTime;
		class'X2StrategyGameRulesetDataStructures'.static.AddTime(WaitActivity.ProgressAt, SecondsChainDelay);
	}
}

static protected function GetCounterDarkEventPeriodStartAndDuration (out int SecondsDelay, out int SecondsDuration)
{
	local int Min, Max;

	Min = class'X2StrategyElement_DefaultActivities'.default.MinDarkEventWaitDays;
	Max = class'X2StrategyElement_DefaultActivities'.default.MaxDarkEventWaitDays;

	// Make sure that the values are sensible
	if (Min < 0) Min = 0;
	if (Max < Min) Max = Min; // This will probably won't work properly -.-

	// Convert to seconds
	Min *= 86400;
	Max *= 86400;

	// Return
	SecondsDelay = Min;
	SecondsDuration = Max - Min;
}

static protected function array<XComGameState_ActivityChain> SortChainsRandomly (array<XComGameState_ActivityChain> Chains)
{
	local array<XComGameState_ActivityChain> Result;
	local XComGameState_ActivityChain Chain;

	while (Chains.Length > 0)
	{
		Chain = Chains[`SYNC_RAND_STATIC(Chains.Length)];

		Chains.RemoveItem(Chain);
		Result.AddItem(Chain);
	}

	return Result;
}

///////////////////////////
/// Creation and access ///
///////////////////////////

static function XComGameState_ActivityChainSpawner GetSpawner(optional bool AllowNull = false)
{
	return XComGameState_ActivityChainSpawner(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_ActivityChainSpawner', AllowNull));
}

static function CreateSpawner(optional XComGameState StartState)
{
	local XComGameState_ActivityChainSpawner Spawner;
	local XComGameState NewGameState;

	if (StartState != none)
	{
		Spawner = XComGameState_ActivityChainSpawner(StartState.CreateNewStateObject(class'XComGameState_ActivityChainSpawner'));
		Spawner.PreviousWork = `ScaleStrategyArrayInt(default.GameStartWork);
		Spawner.PreviousWorkSubmittedAt = GetGameTimeFromHistory();
		Spawner.SetCachedWorkRate();
		Spawner.SetNextSpawnAt(true);
	}
	// Do not create if already exists
	else if (GetSpawner(true) == none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CI: Creating Activity Chain Spawner singleton");
		Spawner = XComGameState_ActivityChainSpawner(NewGameState.CreateNewStateObject(class'XComGameState_ActivityChainSpawner'));
		Spawner.PreviousWorkSubmittedAt = GetGameTimeFromHistory();
		Spawner.SetCachedWorkRate();
		Spawner.SetNextSpawnAt(true);
		
		`XCOMHISTORY.AddGameStateToHistory(NewGameState);
	}
}

static protected function TDateTime GetGameTimeFromHistory()
{
	return XComGameState_GameTime(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_GameTime')).CurrentTime;
}

/////////////////////
/// Debug helpers ///
/////////////////////

static function PrintDebugInfo()
{
	local XComGameState_ActivityChainSpawner Spawner;
	Spawner = GetSpawner(true);

	if (Spawner == none)
	{
		`log("PrintDebugInfo - no spawner found in history",, 'CI_ACSpawner');
		return;
	}

	`log("Submitted work - " $ Spawner.PreviousWork); // TODO: Figure out how to concatenate TDateTime
	`log("Next spawn at" @ Spawner.NextSpawnAt);
	`log("Cached work rate - " $ Spawner.CachedWorkRate);
	`log("Current work rate - " $ Spawner.GetCurrentWorkRate());
}

//////////////////////
/// Region Helpers ///
//////////////////////

static function array<StateObjectReference> GetContactedRegions ()
{
	local array<StateObjectReference> RegionRefs;
	local XComGameState_WorldRegion RegionState;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		if (RegionState.HaveMadeContact())
		{
			RegionRefs.AddItem(RegionState.GetReference());
		}
	}
	
	return RegionRefs;
}
