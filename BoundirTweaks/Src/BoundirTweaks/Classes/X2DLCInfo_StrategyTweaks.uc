class X2DLCInfo_StrategyTweaks extends X2DownloadableContentInfo;

var config(GameData) array<DarkEventAppearanceRestriction> DARK_EVENT_CONDITIONS;
var config(GameData) array<name> SITREP_RULER_EXCLUSION;
var config(GameData) int CHOSEN_WEAKNESSES_REMOVED_BY_TRAINING;
var config(GameData) array<CovertActionStatRewardLimit> COVERT_ACTION_STAT_LIMIT;
var config(GameData) array<FacilityPersonelManagement> FACILITY_PERSONEL_MANAGEMENT;
var config(GameData) array<WeaponBreakthrough> WEAPON_BREAKTHROUGH;
var config(GameData) array<string> FORBID_MOCX_FROM_MISSION_TYPE;

static private function X2DLCInfo_StrategyTweaks GetClassDefaultObject()
{
	return X2DLCInfo_StrategyTweaks(class'XComEngine'.static.GetClassDefaultObjectByName(default.Class.Name));
}

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
	FacilityPersonelManagement(StrategyElementTemplateManager);
	AllowCategoryListOnWeaponBreakthroughs(StrategyElementTemplateManager);
	MOCXNotAllowedInRetaliationMission();
}

static function ExcludeRulersFromSitrep(X2SitRepTemplateManager SitRepTemplateManager)
{
	local X2SitRepTemplate SitRepTemplate;
	local AlienRulerData RulerData;
	local AlienRulerAdditionalTags AdditionalTag;
	local name SitRepName;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	foreach default.SITREP_RULER_EXCLUSION(SitRepName)
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
	local X2ChosenActionTemplate ChosenActionTemplate;
	local ChosenTrainingDecorator ChosenTrainingDecorator;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	ChosenActionTemplate = X2ChosenActionTemplate(StrategyElementTemplateManager.FindStrategyElementTemplate('ChosenAction_Training'));

	if (ChosenActionTemplate == none)
	{
		return;
	}

	ChosenTrainingDecorator = new class'ChosenTrainingDecorator';
	ChosenTrainingDecorator.ActivateTraining = ChosenActionTemplate.OnActivatedFn;

	ChosenActionTemplate.OnActivatedFn = ChosenTrainingDecorator.ActivateStrongerTraining;
}

static function ManageDarkEventSpawningConditions(X2StrategyElementTemplateManager StrategyElementTemplateManager)
{
	local X2DarkEventTemplate DarkEventTemplate;
	local DarkEventAppearanceRestriction DarkEventRestriction;
	local DarkEventActivationRestrictionDecorator DarkEventCanActivateDecorator;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	foreach default.DARK_EVENT_CONDITIONS(DarkEventRestriction)
	{
		DarkEventTemplate = X2DarkEventTemplate(StrategyElementTemplateManager.FindStrategyElementTemplate(DarkEventRestriction.DarkEvent));

		if (DarkEventTemplate == none)
		{
			continue;
		}

		DarkEventCanActivateDecorator = new class'DarkEventActivationRestrictionDecorator';
		DarkEventCanActivateDecorator.CanActivateOriginalRestrictionFn = DarkEventTemplate.CanActivateFn;

		DarkEventTemplate.CanActivateFn = DarkEventCanActivateDecorator.CanActivate;
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

		RewardTemplate.GiveRewardFn = GiveStatRewardIfUnrestricted;
	}
}

static function FacilityPersonelManagement(X2StrategyElementTemplateManager StrategyElementTemplateManager)
{
	local array<X2DataTemplate> DataTemplates;
	local X2DataTemplate Template;
	local X2StaffSlotTemplate StaffTemplate;
	local FacilityPersonelManagement Management;
	local int Index;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	DataTemplates = StrategyElementTemplateManager.GetAllTemplatesOfClass(class'X2StaffSlotTemplate');

	foreach DataTemplates(Template)
	{
		StaffTemplate = X2StaffSlotTemplate(Template);

		if (StaffTemplate == none)
		{
			continue;
		}

		Index = default.FACILITY_PERSONEL_MANAGEMENT.Find('StaffName', Template.DataName);

		if (Index == INDEX_NONE)
		{
			continue;
		}

		Management = default.FACILITY_PERSONEL_MANAGEMENT[Index];

		StaffTemplate.bEngineerSlot = Management.StaffEngineer;
		StaffTemplate.bScientistSlot = Management.StaffScientist;
	}
}

static function AllowCategoryListOnWeaponBreakthroughs(X2StrategyElementTemplateManager StrategyElementTemplateManager)
{
	local X2TechTemplate TechTemplate;
	local X2BreakthroughCondition_WeaponTypeTweak WeaponTypeCondition;
	local WeaponBreakthrough Breakthrough;
	local WeaponBreakthroughDecorator BreakthroughDecorator;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	foreach default.WEAPON_BREAKTHROUGH(Breakthrough)
	{
		TechTemplate = X2TechTemplate(StrategyElementTemplateManager.FindStrategyElementTemplate(Breakthrough.BreakthroughName));

		if (TechTemplate == none)
		{
			continue;
		}

		`Log(TechTemplate.DataName @ "is being modified", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

		WeaponTypeCondition = new class'X2BreakthroughCondition_WeaponTypeTweak';
		WeaponTypeCondition.WeaponTypesMatch = Breakthrough.WeaponCategories;

		TechTemplate.BreakthroughCondition = WeaponTypeCondition;

		BreakthroughDecorator = new class'WeaponBreakthroughDecorator';
		BreakthroughDecorator.WeaponCategories = Breakthrough.WeaponCategories;

		TechTemplate.ResearchCompletedFn = BreakthroughDecorator.ResearchCompleted;
	}
}

static function MOCXNotAllowedInRetaliationMission()
{
	local XComTacticalMissionManager MissionManager;
	local MissionDefinition MissionDefinition;
	local string MissionType;
	local int Scan;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	MissionManager = `TACTICALMISSIONMGR;

	foreach default.FORBID_MOCX_FROM_MISSION_TYPE(MissionType)
	{
		Scan = MissionManager.arrMissions.Find('sType', MissionType);

		if (Scan == INDEX_NONE)
		{
			continue;
		}

		`Log("Prevent MOCX from appearing in" @ MissionManager.arrMissions[Scan].MissionName, class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

		MissionManager.arrMissions[Scan].ForcedTacticalTags.AddItem('NoMOCX');
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

static function GiveStatRewardIfUnrestricted(
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
	}

	ItemState.LinkedEntity = UnitState.GetReference(); // Link the item and unit together so the stat boost gets applied properly

	if (!XComHQ.PutItemInInventory(NewGameState, ItemState))
	{
		NewGameState.PurgeGameStateForObjectID(XComHQ.ObjectID);
	}
}


