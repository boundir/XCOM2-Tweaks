class X2DLCInfo_DisableAmbush extends X2DownloadableContentInfo config(GameData);

var config bool DISABLE_AMBUSH;

static event InstallNewCampaign(XComGameState StartState)
{
	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	DisableAmbush(StartState);
}

static event OnLoadedSavedGameToStrategy()
{
	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	DisableAmbush();
}

static function DisableAmbush(optional XComGameState NewGameState = none)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	if (!default.DISABLE_AMBUSH)
	{
		return;
	}

	History = `XCOMHISTORY;

	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	if (ResistanceHQ.bPreventCovertActionAmbush)
	{
		`Log("Ambush is disabled already. Skipping.", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

		return;
	}

	if (NewGameState == none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Disable Ambush");
	}

	ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));

	ResistanceHQ.bPreventCovertActionAmbush = true;

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`Log("Ambush is now disabled.", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

static event OnPostTemplatesCreated()
{
	local X2StrategyElementTemplateManager StrategyManager;
	local X2StrategyCardTemplate CardTemplate;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	if (!default.DISABLE_AMBUSH)
	{
		return;
	}

	StrategyManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	CardTemplate = X2StrategyCardTemplate(StrategyManager.FindStrategyElementTemplate('ResCard_GuardianAngels'));

	if (CardTemplate == none)
	{
		return;
	}

	CardTemplate.Category = "NotAResistanceCard";
	CardTemplate.CanBePlayedFn = CantBePlayed;
	CardTemplate.bContinentBonus = false;
	CardTemplate.Strength = 99;
}

static function bool CantBePlayed(StateObjectReference InRef, optional XComGameState NewGameState = none)
{
	return false;
}
