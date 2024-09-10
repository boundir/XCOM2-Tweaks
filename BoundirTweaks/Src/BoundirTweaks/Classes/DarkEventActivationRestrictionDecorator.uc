class DarkEventActivationRestrictionDecorator extends Object;

var delegate<X2DarkEventTemplate.CanActivateDelegate> CanActivateOriginalRestrictionFn;

function bool CanActivate(XComGameState_DarkEvent DarkEventState)
{
	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	return CanActivateRestriction(DarkEventState) && CanActivateOriginalRestrictionFn(DarkEventState);
}

static function bool CanActivateRestriction(XComGameState_DarkEvent DarkEventState)
{
	local name DarkEvent;
	local array<DarkEventAppearanceRestriction> DarkEventRestrictions;
	local DarkEventAppearanceRestriction DarkEventRestriction;
	local bool CanActivate;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	DarkEvent = DarkEventState.GetMyTemplateName();
	CanActivate = true;

	DarkEventRestrictions = class'Helper_Tweaks'.static.FindDarkEventListByName(DarkEvent, class'X2DLCInfo_StrategyTweaks'.default.DARK_EVENT_CONDITIONS);

	foreach DarkEventRestrictions(DarkEventRestriction)
	{
		if (!CanActivate)
		{
			break;
		}

		switch (DarkEventRestriction.Restriction)
		{
			case eDarkEventRestriction_NeverAppear:
				CanActivate = CantActivate(DarkEventState);
				break;

			case eDarkEventRestriction_ForceLevel:
				CanActivate = ForceLevelRestriction(DarkEventState, DarkEventRestriction);
				break;

			case eDarkEventRestriction_ChosenMustHaveAtLeastOneWeakness:
				CanActivate = ChosenHasWeaknesses(DarkEventState);
				break;

			case eDarkEventRestriction_ChosenMustBeAlive:
				CanActivate = ChosenIsAlive(DarkEventRestriction.ChosenName);
				break;

			case eDarkEventRestriction_ChosenMustBeDead:
				CanActivate = !ChosenIsAlive(DarkEventRestriction.ChosenName);
				break;

			default:
				`Log("No condition given!", , 'TweaksLog');
				break;
		}
	}

	return CanActivate;
}

static function bool CantActivate(XComGameState_DarkEvent DarkEventState)
{
	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	return class'Helper_Tweaks'.static.ReturnFalse();
}

static function bool ForceLevelRestriction(XComGameState_DarkEvent DarkEventState, DarkEventAppearanceRestriction DarkEventRestriction)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local int ForceLevel;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	ForceLevel = AlienHQ.GetForceLevel();

	return ForceLevel >= DarkEventRestriction.MinForceLevel && ForceLevel <= DarkEventRestriction.MaxForceLevel;
}

static function bool ChosenHasWeaknesses(XComGameState_DarkEvent DarkEventState)
{
	local XComGameStateHistory History;
	local XComGameState_AdventChosen ChosenState;
	local array<X2AbilityTemplate> ChosenWeaknesses;
	local int NumValidChosen;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	History = `XCOMHISTORY;
	NumValidChosen = 0;

	foreach History.IterateByClassType(class'XComGameState_AdventChosen', ChosenState)
	{
		if (!ChosenState.bMetXCom || ChosenState.bDefeated)
		{
			continue;
		}

		ChosenWeaknesses = ChosenState.GetChosenWeaknesses();

		if (ChosenWeaknesses.Length == 0)
		{
			continue;
		}

		NumValidChosen++;
	}

	return NumValidChosen > 0;
}

static function bool ChosenIsAlive(name ChosenTemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_AdventChosen ChosenState;
	local int NumActiveChosen;
	local bool bSpecifiedChosenActive, RequireSpecificChosen;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	History = `XCOMHISTORY;
	NumActiveChosen = 0;
	bSpecifiedChosenActive = false;
	RequireSpecificChosen = true;

	if (ChosenTemplateName == '')
	{
		RequireSpecificChosen = false;
	}

	foreach History.IterateByClassType(class'XComGameState_AdventChosen', ChosenState)
	{
		if (ChosenState.bMetXCom && !ChosenState.bDefeated)
		{
			NumActiveChosen++;

			if (ChosenState.GetMyTemplateName() == ChosenTemplateName)
			{
				bSpecifiedChosenActive = true;
			}
		}
	}

	return (bSpecifiedChosenActive && NumActiveChosen > 1) || (!RequireSpecificChosen && NumActiveChosen > 1);
}