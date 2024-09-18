//---------------------------------------------------------------------------------------
// AUTHOR:    Xymanek
// PURPOSE:   Houses functionality used for interacting with DLC2
// IMPORTANT: DO NOT call any method on this class if DLC2 isn't loaded
//
// Implementation detail: do not declare variables of struct types that come from the DLC
// package - these will CTD on game start if the DLC is missing. Reference types are fine
//---------------------------------------------------------------------------------------
//  WOTCStrategyOverhaul Team
//---------------------------------------------------------------------------------------

class X2Helper_Infiltration_DLC2 extends Object config(Infiltration) abstract;

var config int RULER_ON_INFIL_CHANCE;

static function StateObjectReference GetRulerOnInfiltration (StateObjectReference InfiltrationRef)
{
    local XComGameState_AlienRulerManager RulerManager;
    local StateObjectReference EmptyRef;
    local int i;

    RulerManager = XComGameState_AlienRulerManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
    if (RulerManager == none) return EmptyRef;

    i = RulerManager.AlienRulerLocations.Find('MissionRef', InfiltrationRef);
    return i != INDEX_NONE ? RulerManager.AlienRulerLocations[i].RulerRef : EmptyRef;
}

static function bool InfiltrationHasRuler (StateObjectReference InfiltrationRef)
{
    return GetRulerOnInfiltration(InfiltrationRef).ObjectID != 0;
}

static function PlaceRulerOnInfiltration (XComGameState NewGameState, XComGameState_MissionSiteInfiltration InfiltrationState)
{
    local XComGameState_AlienRulerManager RulerManager;
    local array<StateObjectReference> Candidates;
    local StateObjectReference Candidate;
    local XComGameState_Unit RulerState;
    local XComGameStateHistory History;
	local int i;

    if (InfiltrationHasRuler(InfiltrationState.GetReference()))
    {
        `RedScreen("CI: PlaceRulerOnInfiltration called for infil that already has a ruler, skipping");
        return;
    }

    History = `XCOMHISTORY;
    RulerManager = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));

	// Make sure the casual spawning of rulers is enabled (e.g. the nest mission is done)
	if (!RulerManager.AreAlienRulersAllowedToSpawn()) return;

	RulerManager = XComGameState_AlienRulerManager(NewGameState.ModifyStateObject(class'XComGameState_AlienRulerManager', RulerManager.ObjectID));
	RulerManager.UpdateActiveAlienRulers();

    foreach RulerManager.ActiveAlienRulers(Candidate)
    {
        // Check that the ruler is not waiting on another mission
        if (RulerManager.AlienRulerLocations.Find('RulerRef', Candidate) == INDEX_NONE)
        {
			// This is safe to do even with integrated DLC even if the ruler is waiting for a facility to be built
			// since those rulers do not get added to the ActiveAlienRulers array
            Candidates.AddItem(Candidate);
        }
    }

	// Don't bother to do anything if there are no rulers to place
	if (Candidates.Length == 0) return;
	
	// Roll to place a ruler
	if (!class'X2StrategyGameRulesetDataStructures'.static.Roll(default.RULER_ON_INFIL_CHANCE)) return;

	// Roll to select which ruler to spawn
	Candidate = Candidates[`SYNC_RAND_STATIC(Candidates.Length)];

	// Place the ruler
	RulerManager.AlienRulerLocations.Add(1);
	i = RulerManager.AlienRulerLocations.Length - 1;
	RulerManager.AlienRulerLocations[i].RulerRef = Candidate;
	RulerManager.AlienRulerLocations[i].MissionRef = InfiltrationState.GetReference();
	RulerManager.AlienRulerLocations[i].bActivated = true;
	RulerManager.AlienRulerLocations[i].bNeedsPopup = false;

    // The ruler is ready and waiting bwahahaha
    RulerState = XComGameState_Unit(History.GetGameStateForObjectID(Candidate.ObjectID));
	`log(RulerState.GetMyTemplateName() @ "is waiting on infiltration" @ InfiltrationState.ObjectID @ "-" @ InfiltrationState.GeneratedMission.BattleOpName);
}

static function RemoveRulerFromInfiltration (XComGameState NewGameState, XComGameState_MissionSiteInfiltration InfiltrationState)
{
    local XComGameState_AlienRulerManager RulerManager;
    local int i;

    RulerManager = XComGameState_AlienRulerManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
    i = RulerManager.AlienRulerLocations.Find('MissionRef', InfiltrationState.GetReference());

    if (i != INDEX_NONE)
    {
        RulerManager = XComGameState_AlienRulerManager(NewGameState.ModifyStateObject(class'XComGameState_AlienRulerManager', RulerManager.ObjectID));
        RulerManager.AlienRulerLocations.Remove(i, 1);
    }
}
