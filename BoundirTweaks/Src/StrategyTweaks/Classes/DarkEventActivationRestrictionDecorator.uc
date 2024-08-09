class DarkEventActivationRestrictionDecorator extends Object;

var delegate bool CanActivateOriginalRestriction;
var delegate bool CanActivateConfigRestriction;

function bool CanActivate(XComGameState_DarkEvent DarkEventState)
{
	return CanActivateOriginalRestriction && CanActivateConfigRestriction;
}

static function CanActivateDarkEvent(X2DarkEventTemplate DarkEventTemplate, delegate bool CanActivateConfigRestriction)
{
	local ChosenTrainingDecorator Decorator;

	Decorator = new class'ChosenTrainingDecorator';
	Decorator.CanActivateOriginalRestriction = DarkEventTemplate.CanActivateFn;
	Decorator.CanActivateConfigRestriction = CanActivateConfigRestriction;

	DarkEventTemplate.CanActivateFn = Decorator.CanActivate;
}