class ChosenTrainingDecorator extends Object;

var delegate <X2GameplayMutatorTemplate.OnActivatedDelegate> ActivateTraining;
var delegate <X2GameplayMutatorTemplate.OnActivatedDelegate> RemoveChosenWeakness;

function ActivateStrongerTraining(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	ActivateTraining(NewGameState, InRef, bReactivate);
	RemoveChosenWeakness(NewGameState, InRef, bReactivate);
}

static function PrepareTraining(X2ChosenActionTemplate ChosenActionTemplate, delegate<X2GameplayMutatorTemplate.OnActivatedDelegate> ChosenTraining)
{
	local ChosenTrainingDecorator Decorator;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	Decorator = new class'ChosenTrainingDecorator';
	Decorator.ActivateTraining = ChosenActionTemplate.OnActivatedFn;
	Decorator.RemoveChosenWeakness = ChosenTraining;

	ChosenActionTemplate.OnActivatedFn = Decorator.ActivateStrongerTraining;
}
