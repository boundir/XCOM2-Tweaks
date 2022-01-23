class ChosenTrainingDecorator extends Object;

var delegate <X2GameplayMutatorTemplate.OnActivatedDelegate> ActivateTraining; // Base game behavior or modded altered version
var delegate <X2GameplayMutatorTemplate.OnActivatedDelegate> RemoveChosenWeakness;

function ActivateStrongerTraining(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	ActivateTraining(NewGameState, InRef, bReactivate);
	RemoveChosenWeakness(NewGameState, InRef, bReactivate);
}

static function PrepareTraining(X2ChosenActionTemplate ChosenActionTemplate, delegate<X2GameplayMutatorTemplate.OnActivatedDelegate> ChosenTraining)
{
	local ChosenTrainingDecorator Decorator;

	Decorator = new class'ChosenTrainingDecorator';
	Decorator.ActivateTraining = ChosenActionTemplate.OnActivatedFn;
	Decorator.RemoveChosenWeakness = ChosenTraining;

	ChosenActionTemplate.OnActivatedFn = Decorator.ActivateStrongerTraining;
}