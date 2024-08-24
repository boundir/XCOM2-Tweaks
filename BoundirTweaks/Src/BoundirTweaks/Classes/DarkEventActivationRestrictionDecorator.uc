class DarkEventActivationRestrictionDecorator extends Object;

var delegate<X2DarkEventTemplate.CanActivateDelegate> CanActivateOriginalRestrictionFn;
var delegate<X2DarkEventTemplate.CanActivateDelegate> CanActivateConfigRestrictionFn;

function bool CanActivate(XComGameState_DarkEvent DarkEventState)
{
	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	return CanActivateOriginalRestrictionFn(DarkEventState) && CanActivateConfigRestrictionFn(DarkEventState);
}

static function CanActivateDarkEvent(X2DarkEventTemplate DarkEventTemplate, delegate<X2DarkEventTemplate.CanActivateDelegate> CanActivateConfigRestriction)
{
	local DarkEventActivationRestrictionDecorator Decorator;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	Decorator = new class'DarkEventActivationRestrictionDecorator';
	Decorator.CanActivateOriginalRestrictionFn = DarkEventTemplate.CanActivateFn;
	Decorator.CanActivateConfigRestrictionFn = CanActivateConfigRestriction;

	DarkEventTemplate.CanActivateFn = Decorator.CanActivate;
}