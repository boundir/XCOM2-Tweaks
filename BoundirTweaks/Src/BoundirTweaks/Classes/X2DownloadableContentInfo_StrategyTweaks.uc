class X2DownloadableContentInfo_StrategyTweaks extends X2DownloadableContentInfo;

var config(GameData) array<DarkEventAppearanceRestriction> DARK_EVENT_CONDITIONS;
var config(GameData) array<name> SitrepRulerExclusion;
var config(GameData) int CHOSEN_WEAKNESSES_REMOVED_BY_TRAINING;
var config(GameData) array<CovertActionStatRewardLimit> COVERT_ACTION_STAT_LIMIT;

static event OnPostTemplatesCreated()
{
	local X2StrategyElementTemplateManager StrategyElementTemplateManager;
	local X2SitRepTemplateManager SitRepTemplateManager;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	StrategyElementTemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	SitRepTemplateManager = class'X2SitRepTemplateManager'.static.GetSitRepTemplateManager();

	ExcludeRulersFromSitrep(SitRepTemplateManager);
	AllowFactionHeroesRecruitment(StrategyElementTemplateManager);
	TrainingRemovesWeaknesses(StrategyElementTemplateManager);
	ManageDarkEventSpawningConditions(StrategyElementTemplateManager);
	LimitCovertActionStatBonus(StrategyElementTemplateManager);
}

static function ExcludeRulersFromSitrep(X2SitRepTemplateManager SitRepTemplateManager)
{
	local X2SitRepTemplate SitRepTemplate;
	local AlienRulerData RulerData;
	local AlienRulerAdditionalTags AdditionalTag;
	local name SitRepName;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	foreach default.SitrepRulerExclusion(SitRepName)
	{
		SitRepTemplate = SitRepTemplateManager.FindSitRepTemplate(SitRepName);

		if (SitRepTemplate == none)
		{
			continue;
		}

		foreach class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates(RulerData)
		{
			// Check if we already have the tag excluded.
			if (SitRepTemplate.ExcludeGameplayTags.Find(RulerData.ActiveTacticalTag) != INDEX_NONE)
			{
				continue;
			}

			SitRepTemplate.ExcludeGameplayTags.AddItem(RulerData.ActiveTacticalTag);

			foreach RulerData.AdditionalTags(AdditionalTag)
			{
				SitRepTemplate.ExcludeGameplayTags.AddItem(AdditionalTag.TacticalTag);
			}
		}
	}

}

static function AllowFactionHeroesRecruitment(X2StrategyElementTemplateManager StrategyElementTemplateManager)
{
	local X2RewardTemplate RewardTemplate;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	RewardTemplate = X2RewardTemplate(StrategyElementTemplateManager.FindStrategyElementTemplate('Reward_ExtraFactionSoldier'));

	if (RewardTemplate == none)
	{
		return;
	}

	RewardTemplate.IsRewardAvailableFn = CanRecruitFactionHeroe;
}

static function TrainingRemovesWeaknesses(X2StrategyElementTemplateManager StrategyElementTemplateManager)
{
	local X2ChosenActionTemplate ChosenTrainingAction;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	ChosenTrainingAction = X2ChosenActionTemplate(StrategyElementTemplateManager.FindStrategyElementTemplate('ChosenAction_Training'));

	if (ChosenTrainingAction == none)
	{
		return;
	}

	class'ChosenTrainingDecorator'.static.PrepareTraining(ChosenTrainingAction, RemoveWeakness);
}

static function ManageDarkEventSpawningConditions(X2StrategyElementTemplateManager StrategyElementTemplateManager)
{
	local X2DarkEventTemplate DarkEventTemplate;
	local DarkEventAppearanceRestriction DarkEventRestriction;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	foreach default.DARK_EVENT_CONDITIONS(DarkEventRestriction)
	{
		DarkEventTemplate = X2DarkEventTemplate(StrategyElementTemplateManager.FindStrategyElementTemplate(DarkEventRestriction.DarkEvent));

		if (DarkEventTemplate == none)
		{
			continue;
		}

		class'DarkEventActivationRestrictionDecorator'.static.CanActivateDarkEvent(DarkEventTemplate, CanActivateRestriction);
	}
}

static function LimitCovertActionStatBonus(X2StrategyElementTemplateManager StrategyElementTemplateManager)
{
	local X2RewardTemplate RewardTemplate;
	local CovertActionStatRewardLimit StatRewardLimit;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	foreach default.COVERT_ACTION_STAT_LIMIT(StatRewardLimit)
	{
		RewardTemplate = X2RewardTemplate(StrategyElementTemplateManager.FindStrategyElementTemplate(StatRewardLimit.RewardName));

		if (RewardTemplate == none)
		{
			continue;
		}

		RewardTemplate.GiveRewardFn = GiveStatBoostRewardIfUnrestricted;
	}
}

static function bool CanRecruitFactionHeroe(optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameState_ResistanceFaction FactionState;
	local int CurrentLivingFactionHeroesRoster;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	FactionState = class'X2StrategyElement_DefaultRewards'.static.GetFactionState(NewGameState, AuxRef);

	if (FactionState == none)
	{
		`Redscreen("@jweinhoffer ExtraFactionSoldierReward not available because FactionState was not found");
		return false;
	}

	if (!FactionState.bMetXCom)
	{
		return false;
	}

	CurrentLivingFactionHeroesRoster = FactionState.GetNumFactionSoldiers(NewGameState);

	return CurrentLivingFactionHeroesRoster < FactionState.default.MaxHeroesPerFaction;
}

static function RemoveWeakness(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
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

	// ChosenState.LoseWeaknesses(default.CHOSEN_WEAKNESSES_REMOVED_BY_TRAINING);
	ChosenWeaknesses = ChosenState.GetChosenWeaknesses();
	ChosenWeaknessesCount = ChosenWeaknesses.Length;

	for (idx = 0; idx < default.CHOSEN_WEAKNESSES_REMOVED_BY_TRAINING; idx++)
	{
		if (ChosenWeaknessesCount == 0)
		{
			break;
		}

		Roll = class'Engine'.static.GetEngine().SyncRand(ChosenWeaknessesCount, "RollForChosenWeakness");
		ChosenState.RemoveTrait(ChosenWeaknesses[Roll].DataName);
		ChosenWeaknessesCount--;
	}
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

	DarkEventRestrictions = class'Helper_Tweaks'.static.FindDarkEventListByName(DarkEvent, default.DARK_EVENT_CONDITIONS);

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

static function GiveStatBoostRewardIfUnrestricted(
	XComGameState NewGameState,
	XComGameState_Reward RewardState,
	optional StateObjectReference AuxRef,
	optional bool bOrder = false,
	optional int OrderHours = -1
)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_Item ItemState;
	local StatBoost ItemStatBoost;
	local float NewMaxStat;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AuxRef.ObjectID));

	if (UnitState == none)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', AuxRef.ObjectID));
	}

	ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', RewardState.RewardObjectReference.ObjectID));

	foreach ItemState.StatBoosts(ItemStatBoost)
	{
		`Log("Unit stat" @ UnitState.GetMaxStat(ItemStatBoost.StatType), class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
		`Log("Item boost" @ ItemStatBoost.Boost, class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

		NewMaxStat = int(UnitState.GetMaxStat(ItemStatBoost.StatType) + ItemStatBoost.Boost);

		if ((ItemStatBoost.StatType == eStat_HP) && `SecondWaveEnabled('BetaStrike'))
		{
			NewMaxStat += ItemStatBoost.Boost * (class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod - 1.0);
		}

		if (class'Helper_Tweaks'.static.IsUnitStatLimitReached(NewMaxStat, ItemStatBoost.StatType, default.COVERT_ACTION_STAT_LIMIT))
		{
			`Log("Stat limit is reached", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
			return;
		}

		`Log("Stat limit is not reached", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
		`Log("Stat type" @ ItemStatBoost.StatType, class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
		`Log("Unit new stat" @ NewMaxStat, class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
	}

	ItemState.LinkedEntity = UnitState.GetReference(); // Link the item and unit together so the stat boost gets applied properly

	if (!XComHQ.PutItemInInventory(NewGameState, ItemState))
	{
		NewGameState.PurgeGameStateForObjectID(XComHQ.ObjectID);
	}
}
