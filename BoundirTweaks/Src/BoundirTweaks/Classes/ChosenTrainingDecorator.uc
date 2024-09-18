class ChosenTrainingDecorator extends Object;

var delegate <X2GameplayMutatorTemplate.OnActivatedDelegate> ActivateTraining;

function ActivateStrongerTraining(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	ActivateTraining(NewGameState, InRef, bReactivate);
	RemoveChosenWeakness(NewGameState, InRef, bReactivate);
}

static function RemoveChosenWeakness(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_ChosenAction ActionState;
	local XComGameState_AdventChosen ChosenState;
	local array<X2AbilityTemplate> ChosenWeaknesses;
	local int idx;
	local int ChosenWeaknessesCount;
	local int Roll;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	ActionState = GetAction(InRef, NewGameState);
	ChosenState = GetChosen(ActionState.ChosenRef, NewGameState);

	ChosenWeaknesses = ChosenState.GetChosenWeaknesses();
	ChosenWeaknessesCount = ChosenWeaknesses.Length;

	if (ChosenWeaknessesCount <= class'X2DLCInfo_StrategyTweaks'.default.MINIMUM_CHOSEN_TOTAL_WEAKNESSES)
	{
		return;
	}

	for (idx = 0; idx < class'X2DLCInfo_StrategyTweaks'.default.CHOSEN_WEAKNESSES_REMOVED_BY_TRAINING; idx++)
	{
		if (ChosenWeaknessesCount == class'X2DLCInfo_StrategyTweaks'.default.MINIMUM_CHOSEN_TOTAL_WEAKNESSES)
		{
			break;
		}

		Roll = class'Engine'.static.GetEngine().SyncRand(ChosenWeaknessesCount, "RollForChosenWeakness");
		ChosenState.RemoveTrait(ChosenWeaknesses[Roll].DataName);
		ChosenWeaknessesCount--;
	}
}

static function XComGameState_ChosenAction GetAction(StateObjectReference ActionRef, optional XComGameState NewGameState = none)
{
	local XComGameStateHistory History;
	local XComGameState_ChosenAction ActionState;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	if (NewGameState == none)
	{
		History = `XCOMHISTORY;
		ActionState = XComGameState_ChosenAction(History.GetGameStateForObjectID(ActionRef.ObjectID));
	}
	else
	{
		ActionState = XComGameState_ChosenAction(NewGameState.ModifyStateObject(class'XComGameState_ChosenAction', ActionRef.ObjectID));
	}

	return ActionState;
}

static function XComGameState_AdventChosen GetChosen(StateObjectReference ChosenRef, optional XComGameState NewGameState = none)
{
	local XComGameStateHistory History;
	local XComGameState_AdventChosen ChosenState;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	if (NewGameState == none)
	{
		History = `XCOMHISTORY;
		ChosenState = XComGameState_AdventChosen(History.GetGameStateForObjectID(ChosenRef.ObjectID));
	}
	else
	{
		ChosenState = XComGameState_AdventChosen(NewGameState.ModifyStateObject(class'XComGameState_AdventChosen', ChosenRef.ObjectID));
	}

	return ChosenState;
}
