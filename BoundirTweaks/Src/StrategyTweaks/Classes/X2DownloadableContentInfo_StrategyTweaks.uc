class X2DownloadableContentInfo_StrategyTweaks extends X2DownloadableContentInfo;

const STAT_NOT_CAPPED = -99.99f;

enum EDarkEventRestriction
{
	eDarkEventRestriction_NeverAppear,
	eDarkEventRestriction_ForceLevel,
	eDarkEventRestriction_ChosenMustBeAlive,
	eDarkEventRestriction_ChosenMustHaveAtLeastOneWeakness,
	eDarkEventRestriction_ChosenMustBeDead
	// @todo StrategyRequirement
};

struct DarkEventAppearanceRestriction
{
	var name DarkEvent;
	var EDarkEventRestriction Restriction;
	var name ChosenName;
	var int MinForceLevel;
	var int MaxForceLevel;
};

struct StatBoostCap
{
	var ECharStatType StatType;
	var float StatCap;
	var name BoostName;
};


var config(GameData) array<DarkEventAppearanceRestriction> DarkEventConditions;
var config(GameData) array<StatBoostCap> STAT_BOOST_CAP;
var config(GameData) array<name> SitrepRulerExclusion;
var config(GameData) int CHOSEN_WEAKNESSES_REMOVED_BY_TRAINING;

static event OnPostTemplatesCreated()
{
	ExcludeRulersFromSitrep()
	AllowFactionHeroesRecruitment();
	TrainingRemovesWeaknesses();
	ManageDarkEventSpawningConditions();
}

static function ExcludeRulersFromSitrep()
{
	local X2SitRepTemplate SitRepTemplate;
	local AlienRulerData RulerData;
	local AlienRulerAdditionalTags AdditionalTag;
	local name SitRepName;

	foreach default.SitrepRulerExclusion(SitRepName)
	{
		SitRepTemplate = `GetSitRepMngr.FindSitRepTemplate(SitRepName);

		foreach class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates(RulerData)
		{
			// Check if we already have the tag excluded.
			if(SitRepTemplate.ExcludeGameplayTags.Find(RulerData.ActiveTacticalTag) != INDEX_NONE)
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

static function AllowFactionHeroesRecruitment()
{
	local X2StrategyElementTemplateManager StrategyTemplateManager;
	local X2RewardTemplate RewardTemplate;

	StrategyTemplateManager = `GetStratMngr;

	RewardTemplate = X2RewardTemplate(StrategyTemplateManager.FindStrategyElementTemplate('Reward_ExtraFactionSoldier'));

	if (RewardTemplate == none)
	{
		return;
	}

	RewardTemplate.IsRewardAvailableFn = CanRecruitFactionHeroe;
}

static function bool CanRecruitFactionHeroe(optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameState_ResistanceFaction FactionState;
	local int CurrentLivingFactionHeroesRoster;

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

static function TrainingRemovesWeaknesses()
{
	local X2ChosenActionTemplate ChosenTrainingAction;

	StrategyTemplateManager = `GetStratMngr;

	ChosenTrainingAction = X2ChosenActionTemplate(StrategyTemplateManager.FindStrategyElementTemplate('ChosenAction_Training'));

	if(ChosenTrainingAction != none)
	{
		class'ChosenTrainingDecorator'.static.PrepareTraining(ChosenTrainingAction, RemoveWeakness);
	}
}

static function RemoveWeakness(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_ChosenAction ActionState;
	local XComGameState_AdventChosen ChosenState;
	local array<X2AbilityTemplate> ChosenWeaknesses;
	local int idx;
	local int ChosenWeaknessesCount;
	local int Roll;

	ActionState = GetAction(InRef, NewGameState);
	ChosenState = GetChosen(ActionState.ChosenRef, NewGameState);


	// ChosenState.LoseWeaknesses(default.CHOSEN_WEAKNESSES_REMOVED_BY_TRAINING);
	ChosenWeaknesses = ChosenState.GetChosenWeaknesses();
	ChosenWeaknessesCount = ChosenWeaknesses.Length;

	for(idx = 0; idx < default.CHOSEN_WEAKNESSES_REMOVED_BY_TRAINING; idx++)
	{
		if(ChosenWeaknessesCount == 0)
		{
			break;
		}

		Roll = `SYNC_RAND(ChosenWeaknessesCount, "RollForChosenWeakness");
		ChosenState.RemoveTrait(ChosenWeaknesses[Roll].DataName);
		ChosenWeaknessesCount--;
	}
}

static function ManageDarkEventSpawningConditions()
{
	local X2StrategyElementTemplateManager StrategyTemplateManager;
	local X2DarkEventTemplate DarkEventTemplate;
	local DarkEventAppearanceRestriction DarkEventRestriction;

	StrategyTemplateManager = `GetStratMngr;
	
	foreach default.DarkEventConditions(DarkEventRestriction)
	{
		DarkEventTemplate = X2DarkEventTemplate(StrategyTemplateManager.FindStrategyElementTemplate(DarkEventRestriction.DarkEvent));

		if(DarkEventTemplate != none)
		{
			class'DarkEventActivationRestrictionDecorator'.static.CanActivateDarkEvent(DarkEventTemplate, CanActivateRestriction);
		}
	}
}

static function bool CanActivateRestriction(XComGameState_DarkEvent DarkEventState)
{
	local name DarkEvent;
	local array<DarkEventAppearanceRestriction> DarkEventRestrictions;
	local DarkEventAppearanceRestriction DarkEventRestriction;
	local bool CanActivate;

	DarkEvent = DarkEventState.GetMyTemplateName();
	CanActivate = true;

	DarkEventRestrictions = class'Helper_Tweaks'.static.FindDarkEventListByName(DarkEvent, default.DarkEventConditions);

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
				continue;

			case eDarkEventRestriction_ChosenMustHaveAtLeastOneWeakness:
				CanActivate = ChosenHasWeaknesses(DarkEventState);
				continue;

			case eDarkEventRestriction_ChosenMustBeAlive:
				CanActivate = ChosenIsAlive(DarkEventState, DarkEventRestriction.ChosenName);
				continue;

			case eDarkEventRestriction_ChosenMustBeDead:
				CanActivate = !ChosenIsAlive(DarkEventState, DarkEventRestriction.ChosenName);

			default:
				`TweaksLog("No condition given!");
				break;
		}
	}

	return CanActivate;
}

static function bool CantActivate(XComGameState_DarkEvent DarkEventState)
{
	return class'Helper_Tweaks'.static.ReturnFalse();
}

static function bool ForceLevelRestriction(XComGameState_DarkEvent DarkEventState, DarkEventAppearanceRestriction DarkEventRestriction)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local int ForceLevel;

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
	local int ChosenWeaknessesCount;
	local int NumValidChosen;

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

	History = `XCOMHISTORY;
	NumActiveChosen = 0;
	bSpecifiedChosenActive = false;
	RequireSpecificChosen = true;

	if (ChosenTemplateName = '')
	{
		RequireSpecificChosen = false;
	}

	foreach History.IterateByClassType(class'XComGameState_AdventChosen', ChosenState)
	{
		if(ChosenState.bMetXCom && !ChosenState.bDefeated)
		{
			NumActiveChosen++;

			if(ChosenState.GetMyTemplateName() == ChosenTemplateName)
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

	if(NewGameState == none)
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

	if(NewGameState == none)
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

static function LimitStatBoostRewardOnCovertActions()
{
	local X2ItemTemplateManager ItemTemplateManager;

	ItemTemplateManager = `GetItemMngr;


}

static function CapSoldierStatBoostRewards()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2EquipmentTemplate EquipmentTemplate;
	local StatBoostCap Boost;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach default.STAT_BOOST_CAP(Boost)
	{
		ItemTemplateManager.FindDataTemplateAllDifficulties(Boost.BoostName, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			EquipmentTemplate = X2EquipmentTemplate(DataTemplate);

			if(EquipmentTemplate != none)
			{
				// @TODO use decorator
				EquipmentTemplate.OnAcquiredFn = ApplyStatBoostIfAllowed;
			}
		}
	}
}

static function bool ApplyStatBoostIfAllowed(XComGameState NewGameState, XComGameState_Item ItemState)
{
	local XComGameState_Unit UnitState;
	local StatBoost ItemStatBoost;
	local float NewMaxStat;
	
	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ItemState.LinkedEntity.ObjectID));
	if (UnitState == none)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ItemState.LinkedEntity.ObjectID));
	}
	
	if (UnitState == none)
	{
		// Should not happen if the item is set up as a reward properly
		`RedScreen("Tried to give a stat boost item, but there is no linked unit to increase stats @gameplay @jweinhoffer");
		return false;
	}

	foreach ItemState.StatBoosts(ItemStatBoost)
	{
		NewMaxStat = int(UnitState.GetMaxStat(ItemStatBoost.StatType) + ItemStatBoost.Boost);

		if ((ItemStatBoost.StatType == eStat_HP) && `SecondWaveEnabled('BetaStrike'))
		{
			NewMaxStat += ItemStatBoost.Boost * (class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod - 1.0);
		}

		if(IsUnitStatCapped(ItemStatBoost.StatType, NewMaxStat))
		{
			NewMaxStat = GetStatCapAmount(ItemStatBoost.StatType);
		}

		UnitState.SetBaseMaxStat(ItemStatBoost.StatType, NewMaxStat);
		
		if (ItemStatBoost.StatType != eStat_HP || !UnitState.IsInjured())
		{
			UnitState.SetCurrentStat(ItemStatBoost.StatType, NewMaxStat);
		}
	}

	return true;
}

static function bool IsUnitStatCapped(ECharStatType StatType, float StatAmount)
{
	local float StatCap;

	StatCap = GetStatCapAmount(StatType);

	if (StatCap == STAT_NOT_CAPPED)
	{
		return false;
	}

	if (StatAmount >= StatCap)
	{
		return true;
	}

	return false;
}

static function float GetStatCapAmount(ECharStatType StatType)
{
	local int Index;

	Index = default.STAT_BOOST_CAP.Find('StatType', StatType);

	if(Index == INDEX_NONE)
	{
		return STAT_NOT_CAPPED;
	}

	return default.STAT_BOOST_CAP[Index].StatCap;
}

static function GenerateItemReward(XComGameState_Reward RewardState, XComGameState NewGameState, optional float RewardScalar = 1.0, optional StateObjectReference RegionRef)
{
	local XComGameState_Item ItemState;
	local X2ItemTemplate ItemTemplate;

	ItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(RewardState.GetMyTemplate().rewardObjectTemplateName);
	ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);

	RewardState.RewardObjectReference = ItemState.GetReference();
}

static function GiveStatBoostReward(XComGameState NewGameState, XComGameState_Reward RewardState, optional StateObjectReference AuxRef, optional bool bOrder = false, optional int OrderHours = -1)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_Item ItemState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	
	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AuxRef.ObjectID));
	if (UnitState == none)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', AuxRef.ObjectID));
	}	
	
	ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', RewardState.RewardObjectReference.ObjectID));
	ItemState.LinkedEntity = UnitState.GetReference(); // Link the item and unit together so the stat boost gets applied properly
	
	if (!XComHQ.PutItemInInventory(NewGameState, ItemState))
	{
		NewGameState.PurgeGameStateForObjectID(XComHQ.ObjectID);
	}
}

static function string GetStatBoostRewardPreviewString(XComGameState_Reward RewardState)
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local StatBoost ItemStatBoost;
	local int Quantity;

	History = `XCOMHISTORY;
	ItemState = XComGameState_Item(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	if (ItemState != none)
	{
		foreach ItemState.StatBoosts(ItemStatBoost)
		{
			Quantity += ItemStatBoost.Boost;

			if ((ItemStatBoost.StatType == eStat_HP) && `SecondWaveEnabled('BetaStrike'))
			{
				Quantity += ItemStatBoost.Boost * (class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod - 1.0);
			}
		}
		return ItemState.GetMyTemplate().GetItemFriendlyName() @ "+" $ string(Quantity);
	}

	return "";
}

static function string GetStatBoostRewardString(XComGameState_Reward RewardState)
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local StatBoost ItemStatBoost;
	local XGParamTag kTag;
	local int Quantity;

	History = `XCOMHISTORY;
	ItemState = XComGameState_Item(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	if (ItemState != none)
	{
		foreach ItemState.StatBoosts(ItemStatBoost)
		{
			Quantity += ItemStatBoost.Boost;

			if ((ItemStatBoost.StatType == eStat_HP) && `SecondWaveEnabled('BetaStrike'))
			{
				Quantity += ItemStatBoost.Boost * (class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod - 1.0);
			}
		}
		
		kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		kTag.StrValue0 = ItemState.GetMyTemplate().GetItemFriendlyName();
		kTag.IntValue0 = Quantity;

		return `XEXPAND.ExpandString(default.RewardStatBoost);
	}

	return "";
}