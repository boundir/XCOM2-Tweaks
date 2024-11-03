class Helper_Tweaks extends Object config(Engine);

var config bool EnableDebug;
var config bool EnableTrace;

`define TweaksLog(msg) `Log(`msg, , 'TweaksLog')
`define TweaksDebug(msg) `Log(`msg, class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug')
`define TweaksDebug(msg) `Log(`msg, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace')

static final function bool IsModActive(name ModName)
{
	local XComOnlineEventMgr EventManager;
	local int Index;

	EventManager = `ONLINEEVENTMGR;

	for (Index = EventManager.GetNumDLC() - 1; Index >= 0; Index--)
	{
		if (EventManager.GetDLCNames(Index) == ModName)
		{
			return true;
		}
	}

	return false;
}

static function bool IsResistanceWarriorUnit(XComGameState_Unit UnitState)
{
	local XComGameState_Item ItemState;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	ItemState = UnitState.GetItemInSlot(eInvSlot_Armor);

	if (ItemState.GetMyTemplateName() != 'KevlarArmor_DLC_Day0')
	{
		return false;
	}

	return ((UnitState.kAppearance.nmHaircut == 'Classic_M' && UnitState.kAppearance.nmFacePropUpper == 'Aviators_M') ||
		(UnitState.kAppearance.nmHaircut == 'Classic_F' && UnitState.kAppearance.nmFacePropUpper == 'Aviators_F')
	);
}

static function bool IsUnitFromCharacterPool(XComGameState_Unit CharacterPoolUnit, XComGameState_Unit UnitState)
{
	// `Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	return (CharacterPoolUnit != none && CharacterPoolUnit.GetNickName() == UnitState.GetNickName() && CharacterPoolUnit.GetFullName() == UnitState.GetFullName());
}

static function array<DarkEventAppearanceRestriction> FindDarkEventListByName(name DarkEvent, array<DarkEventAppearanceRestriction> DARK_EVENT_CONDITIONS)
{
	local DarkEventAppearanceRestriction DarkEventCondition;
	local array<DarkEventAppearanceRestriction> DarkEvents;

	`Log(`StaticLocation, default.EnableTrace, 'TweaksTrace');

	foreach DARK_EVENT_CONDITIONS(DarkEventCondition)
	{
		if (DarkEventCondition.DarkEvent == DarkEvent)
		{
			DarkEvents.AddItem(DarkEventCondition);
		}
	}

	return DarkEvents;
}

static function CloneAbility(X2AbilityTemplate OriginalAbility, out X2AbilityTemplate AbilityTemplate)
{
	`Log(`StaticLocation, default.EnableTrace, 'TweaksTrace');

	AbilityTemplate.AbilitySourceName = OriginalAbility.AbilitySourceName;
	AbilityTemplate.eAbilityIconBehaviorHUD = OriginalAbility.eAbilityIconBehaviorHUD;
	AbilityTemplate.IconImage = OriginalAbility.IconImage;
	AbilityTemplate.ShotHUDPriority = OriginalAbility.ShotHUDPriority;

	AbilityTemplate.AbilityToHitCalc = OriginalAbility.AbilityToHitCalc;
	AbilityTemplate.AbilityTargetStyle = OriginalAbility.AbilityTargetStyle;

	AbilityTemplate.bAllowBonusWeaponEffects = OriginalAbility.bAllowBonusWeaponEffects;

	AbilityTemplate.AbilityCharges = OriginalAbility.AbilityCharges;
	AbilityTemplate.AbilityCooldown = OriginalAbility.AbilityCooldown;
	AbilityTemplate.AbilityToHitCalc = OriginalAbility.AbilityToHitCalc;
	AbilityTemplate.AbilityToHitOwnerOnMissCalc = OriginalAbility.AbilityToHitOwnerOnMissCalc;

	AbilityTemplate.TriggerChance = OriginalAbility.TriggerChance;
	AbilityTemplate.bUseThrownGrenadeEffects = OriginalAbility.bUseThrownGrenadeEffects;
	AbilityTemplate.bUseLaunchedGrenadeEffects = OriginalAbility.bUseLaunchedGrenadeEffects;
	AbilityTemplate.bAllowFreeFireWeaponUpgrade = OriginalAbility.bAllowFreeFireWeaponUpgrade;
	AbilityTemplate.bAllowAmmoEffects = OriginalAbility.bAllowAmmoEffects;
	AbilityTemplate.bAllowBonusWeaponEffects = OriginalAbility.bAllowBonusWeaponEffects;
	AbilityTemplate.Requirements = OriginalAbility.Requirements;

	AbilityTemplate.FinalizeAbilityName = OriginalAbility.FinalizeAbilityName;
	AbilityTemplate.CancelAbilityName = OriginalAbility.CancelAbilityName;

	AbilityTemplate.Hostility = OriginalAbility.Hostility;
	AbilityTemplate.bAllowedByDefault = OriginalAbility.bAllowedByDefault;
	AbilityTemplate.bUniqueSource = OriginalAbility.bUniqueSource;
	AbilityTemplate.bRecordValidTiles = OriginalAbility.bRecordValidTiles;
	AbilityTemplate.bIsPassive = OriginalAbility.bIsPassive;
	AbilityTemplate.bCrossClassEligible = OriginalAbility.bCrossClassEligible;
	AbilityTemplate.ConcealmentRule = OriginalAbility.ConcealmentRule;
	AbilityTemplate.SuperConcealmentLoss = OriginalAbility.SuperConcealmentLoss;
	AbilityTemplate.bSilentAbility = OriginalAbility.bSilentAbility;
	AbilityTemplate.bCannotTeleport = OriginalAbility.bCannotTeleport;
	AbilityTemplate.bPreventsTargetTeleport = OriginalAbility.bPreventsTargetTeleport;
	AbilityTemplate.bTickPerActionEffects = OriginalAbility.bTickPerActionEffects;
	AbilityTemplate.bCheckCollision = OriginalAbility.bCheckCollision;
	AbilityTemplate.bAffectNeighboringTiles = OriginalAbility.bAffectNeighboringTiles;
	AbilityTemplate.bFragileDamageOnly = OriginalAbility.bFragileDamageOnly;

	AbilityTemplate.ChosenActivationIncreasePerUse = OriginalAbility.ChosenActivationIncreasePerUse;
	AbilityTemplate.LostSpawnIncreasePerUse = OriginalAbility.LostSpawnIncreasePerUse;

	AbilityTemplate.AbilityPointCost = OriginalAbility.AbilityPointCost;
	AbilityTemplate.DefaultSourceItemSlot = OriginalAbility.DefaultSourceItemSlot;

	AbilityTemplate.AbilityRevealEvent = OriginalAbility.AbilityRevealEvent;
	AbilityTemplate.ChosenTraitType = OriginalAbility.ChosenTraitType;
	AbilityTemplate.ChosenTraitForceLevelGate = OriginalAbility.ChosenTraitForceLevelGate;

	AbilityTemplate.eAbilityIconBehaviorHUD = OriginalAbility.eAbilityIconBehaviorHUD;
	AbilityTemplate.DisplayTargetHitChance = OriginalAbility.DisplayTargetHitChance;
	AbilityTemplate.bUseAmmoAsChargesForHUD = OriginalAbility.bUseAmmoAsChargesForHUD;
	AbilityTemplate.iAmmoAsChargesDivisor = OriginalAbility.iAmmoAsChargesDivisor;
	AbilityTemplate.IconImage = OriginalAbility.IconImage;
	AbilityTemplate.AbilityIconColor = OriginalAbility.AbilityIconColor;
	AbilityTemplate.bHideOnClassUnlock = OriginalAbility.bHideOnClassUnlock;
	AbilityTemplate.ShotHUDPriority = OriginalAbility.ShotHUDPriority;
	AbilityTemplate.bDisplayInUITooltip = OriginalAbility.bDisplayInUITooltip;
	AbilityTemplate.bDisplayInUITacticalText = OriginalAbility.bDisplayInUITacticalText;
	AbilityTemplate.bNoConfirmationWithHotKey = OriginalAbility.bNoConfirmationWithHotKey;
	AbilityTemplate.bLimitTargetIcons = OriginalAbility.bLimitTargetIcons;
	AbilityTemplate.bBypassAbilityConfirm = OriginalAbility.bBypassAbilityConfirm;
	AbilityTemplate.AbilitySourceName = OriginalAbility.AbilitySourceName;
	AbilityTemplate.AbilityConfirmSound = OriginalAbility.AbilityConfirmSound;
	AbilityTemplate.bDontDisplayInAbilitySummary = OriginalAbility.bDontDisplayInAbilitySummary;
	AbilityTemplate.DefaultKeyBinding = OriginalAbility.DefaultKeyBinding;
	AbilityTemplate.bCommanderAbility = OriginalAbility.bCommanderAbility;
	AbilityTemplate.bFriendlyFireWarning = OriginalAbility.bFriendlyFireWarning;
	AbilityTemplate.bFriendlyFireWarningRobotsOnly = OriginalAbility.bFriendlyFireWarningRobotsOnly;

	AbilityTemplate.CustomFireAnim = OriginalAbility.CustomFireAnim;
	AbilityTemplate.CustomFireKillAnim = OriginalAbility.CustomFireKillAnim;
	AbilityTemplate.CustomMovingFireAnim = OriginalAbility.CustomMovingFireAnim;
	AbilityTemplate.CustomMovingFireKillAnim = OriginalAbility.CustomMovingFireKillAnim;
	AbilityTemplate.CustomMovingTurnLeftFireAnim = OriginalAbility.CustomMovingTurnLeftFireAnim;
	AbilityTemplate.CustomMovingTurnLeftFireKillAnim = OriginalAbility.CustomMovingTurnLeftFireKillAnim;
	AbilityTemplate.CustomMovingTurnRightFireAnim = OriginalAbility.CustomMovingTurnRightFireAnim;
	AbilityTemplate.CustomMovingTurnRightFireKillAnim = OriginalAbility.CustomMovingTurnRightFireKillAnim;
	AbilityTemplate.CustomSelfFireAnim = OriginalAbility.CustomSelfFireAnim;

	AbilityTemplate.AssociatedPlayTiming = OriginalAbility.AssociatedPlayTiming;
	AbilityTemplate.bShowActivation = OriginalAbility.bShowActivation;
	AbilityTemplate.bShowPostActivation = OriginalAbility.bShowPostActivation;
	AbilityTemplate.bSkipFireAction = OriginalAbility.bSkipFireAction;
	AbilityTemplate.bSkipExitCoverWhenFiring = OriginalAbility.bSkipExitCoverWhenFiring;
	AbilityTemplate.bSkipPerkActivationActions = OriginalAbility.bSkipPerkActivationActions;
	AbilityTemplate.bSkipPerkActivationActionsSync = OriginalAbility.bSkipPerkActivationActionsSync;
	AbilityTemplate.bSkipMoveStop = OriginalAbility.bSkipMoveStop;
	AbilityTemplate.bOverrideMeleeDeath = OriginalAbility.bOverrideMeleeDeath;
	AbilityTemplate.bOverrideVisualResult = OriginalAbility.bOverrideVisualResult;
	AbilityTemplate.OverrideVisualResult = OriginalAbility.OverrideVisualResult;
	AbilityTemplate.bHideWeaponDuringFire = OriginalAbility.bHideWeaponDuringFire;
	AbilityTemplate.bHideAmmoWeaponDuringFire = OriginalAbility.bHideAmmoWeaponDuringFire;
	AbilityTemplate.bIsASuppressionEffect = OriginalAbility.bIsASuppressionEffect;
	AbilityTemplate.bOverrideAim = OriginalAbility.bOverrideAim;
	AbilityTemplate.bUseSourceLocationZToAim = OriginalAbility.bUseSourceLocationZToAim;
	AbilityTemplate.bOverrideWeapon = OriginalAbility.bOverrideWeapon;
	AbilityTemplate.bStationaryWeapon = OriginalAbility.bStationaryWeapon;
	AbilityTemplate.ActionFireClass = OriginalAbility.ActionFireClass;
	AbilityTemplate.bForceProjectileTouchEvents = OriginalAbility.bForceProjectileTouchEvents;

	AbilityTemplate.ActivationSpeech = OriginalAbility.ActivationSpeech;
	AbilityTemplate.SourceHitSpeech = OriginalAbility.SourceHitSpeech;
	AbilityTemplate.TargetHitSpeech = OriginalAbility.TargetHitSpeech;
	AbilityTemplate.SourceMissSpeech = OriginalAbility.SourceMissSpeech;
	AbilityTemplate.TargetMissSpeech = OriginalAbility.TargetMissSpeech;
	AbilityTemplate.TargetKilledByAlienSpeech = OriginalAbility.TargetKilledByAlienSpeech;
	AbilityTemplate.TargetKilledByXComSpeech = OriginalAbility.TargetKilledByXComSpeech;
	AbilityTemplate.MultiTargetsKilledByAlienSpeech = OriginalAbility.MultiTargetsKilledByAlienSpeech;
	AbilityTemplate.MultiTargetsKilledByXComSpeech = OriginalAbility.MultiTargetsKilledByXComSpeech;
	AbilityTemplate.TargetWingedSpeech = OriginalAbility.TargetWingedSpeech;
	AbilityTemplate.TargetArmorHitSpeech = OriginalAbility.TargetArmorHitSpeech;
	AbilityTemplate.TargetMissedSpeech = OriginalAbility.TargetMissedSpeech;

	AbilityTemplate.AbilityTargetStyle = OriginalAbility.AbilityTargetStyle;
	AbilityTemplate.AbilityMultiTargetStyle = OriginalAbility.AbilityMultiTargetStyle;
	AbilityTemplate.AbilityPassiveAOEStyle = OriginalAbility.AbilityPassiveAOEStyle;
	AbilityTemplate.bAllowUnderhandAnim = OriginalAbility.bAllowUnderhandAnim;

	AbilityTemplate.TargetingMethod = OriginalAbility.TargetingMethod;
	AbilityTemplate.SecondaryTargetingMethod = OriginalAbility.SecondaryTargetingMethod;

	AbilityTemplate.SkipRenderOfAOETargetingTiles = OriginalAbility.SkipRenderOfAOETargetingTiles;
	AbilityTemplate.SkipRenderOfTargetingTemplate = OriginalAbility.SkipRenderOfTargetingTemplate;

	AbilityTemplate.MeleePuckMeshPath = OriginalAbility.MeleePuckMeshPath;

	AbilityTemplate.CinescriptCameraType = OriginalAbility.CinescriptCameraType;
	AbilityTemplate.CameraPriority = OriginalAbility.CameraPriority;

	AbilityTemplate.bUsesFiringCamera = OriginalAbility.bUsesFiringCamera;
	AbilityTemplate.FrameAbilityCameraType = OriginalAbility.FrameAbilityCameraType;
	AbilityTemplate.bFrameEvenWhenUnitIsHidden = OriginalAbility.bFrameEvenWhenUnitIsHidden;

	AbilityTemplate.TwoTurnAttackAbility = OriginalAbility.TwoTurnAttackAbility;

	AbilityTemplate.AbilityCosts = OriginalAbility.AbilityCosts;

	AbilityTemplate.AbilityShooterConditions = OriginalAbility.AbilityShooterConditions;
	AbilityTemplate.AbilityTargetConditions = OriginalAbility.AbilityTargetConditions;
	AbilityTemplate.AbilityMultiTargetConditions = OriginalAbility.AbilityMultiTargetConditions;

	AbilityTemplate.AbilityTargetEffects = OriginalAbility.AbilityTargetEffects;
	AbilityTemplate.AbilityMultiTargetEffects = OriginalAbility.AbilityMultiTargetEffects;
	AbilityTemplate.AbilityShooterEffects = OriginalAbility.AbilityShooterEffects;

	AbilityTemplate.AbilityTriggers = OriginalAbility.AbilityTriggers;

	AbilityTemplate.AdditionalAbilities = OriginalAbility.AdditionalAbilities;
	AbilityTemplate.PrerequisiteAbilities = OriginalAbility.PrerequisiteAbilities;
	AbilityTemplate.OverrideAbilities = OriginalAbility.OverrideAbilities;

	AbilityTemplate.AssociatedPassives = OriginalAbility.AssociatedPassives;
	AbilityTemplate.AbilityEventListeners = OriginalAbility.AbilityEventListeners;
	AbilityTemplate.PostActivationEvents = OriginalAbility.PostActivationEvents;

	AbilityTemplate.ChosenReinforcementGroupName = OriginalAbility.ChosenReinforcementGroupName;
	AbilityTemplate.ChosenExcludeTraits = OriginalAbility.ChosenExcludeTraits;
	AbilityTemplate.HideIfAvailable = OriginalAbility.HideIfAvailable;
	AbilityTemplate.HideErrors = OriginalAbility.HideErrors;
	AbilityTemplate.UIStatMarkups = OriginalAbility.UIStatMarkups;

	AbilityTemplate.BuildNewGameStateFn = OriginalAbility.BuildNewGameStateFn;
	AbilityTemplate.BuildInterruptGameStateFn = OriginalAbility.BuildInterruptGameStateFn;
	AbilityTemplate.BuildVisualizationFn = OriginalAbility.BuildVisualizationFn;
	AbilityTemplate.BuildAppliedVisualizationSyncFn = OriginalAbility.BuildAppliedVisualizationSyncFn;
	AbilityTemplate.BuildAffectedVisualizationSyncFn = OriginalAbility.BuildAffectedVisualizationSyncFn;
	AbilityTemplate.SoldierAbilityPurchasedFn = OriginalAbility.SoldierAbilityPurchasedFn;
	AbilityTemplate.OnVisualizationTrackInsertedFn = OriginalAbility.OnVisualizationTrackInsertedFn;
	AbilityTemplate.ModifyNewContextFn = OriginalAbility.ModifyNewContextFn;
	AbilityTemplate.DamagePreviewFn = OriginalAbility.DamagePreviewFn;
	AbilityTemplate.GetBonusWeaponAmmoFn = OriginalAbility.GetBonusWeaponAmmoFn;
	AbilityTemplate.MergeVisualizationFn = OriginalAbility.MergeVisualizationFn;
	AbilityTemplate.AlternateFriendlyNameFn = OriginalAbility.AlternateFriendlyNameFn;
	AbilityTemplate.ShouldRevealChosenTraitFn = OriginalAbility.ShouldRevealChosenTraitFn;
	AbilityTemplate.OverrideAbilityAvailabilityFn = OriginalAbility.OverrideAbilityAvailabilityFn;

	AbilityTemplate.MP_PerkOverride = OriginalAbility.MP_PerkOverride;
}

static function bool IsUnitStatLimitReached(float StatAmount, ECharStatType StatType, array<CovertActionStatRewardLimit> StatRewardLimits)
{
	local float StatLimit;
	local int Index;

	`Log(`StaticLocation, default.EnableTrace, 'TweaksTrace');

	Index = StatRewardLimits.Find('StatType', StatType);

	if (Index == INDEX_NONE)
	{
		`Log("We didn't find the Stat type in config", default.EnableDebug, 'TweaksDebug');
		return false;
	}

	StatLimit = StatRewardLimits[Index].StatLimit;

	`Log("StatLimit:" @ StatLimit, default.EnableDebug, 'TweaksDebug');
	`Log("UnitStat:" @ StatAmount, default.EnableDebug, 'TweaksDebug');

	return StatAmount > StatLimit;
}

static function int GetAdditionalAbilitiesPurchased(XComGameState_Unit UnitState)
{
	local array<SoldierClassAbilityType> RankAbilities;
	local int MaxRanks, BranchesPerRank;
	local int Rank, Branch;
	local bool PurchasedRankUpAbility;
	local int AdditionalAbilitiesPurchased;

	`Log(`StaticLocation, default.EnableTrace, 'TweaksTrace');

	MaxRanks = UnitState.AbilityTree.Length > 7 ? 8 : 7;
	AdditionalAbilitiesPurchased = 0;

	for (Rank = 1; Rank < MaxRanks; ++Rank)
	{
		PurchasedRankUpAbility = false;
		RankAbilities = UnitState.AbilityTree[Rank].Abilities;
		BranchesPerRank = RankAbilities.Length;

		for (Branch = 0; Branch < BranchesPerRank; ++Branch)
		{
			if (UnitState.HasSoldierAbility(RankAbilities[Branch].AbilityName))
			{
				if (PurchasedRankUpAbility)
				{
					AdditionalAbilitiesPurchased++;
				}

				PurchasedRankUpAbility = true;
			}
		}
	}

	return AdditionalAbilitiesPurchased;
}

static function int ExtractNumberFromString(string InputString)
{
	local int i;
	local int Num;
	local int StartIndex;
	local int EndIndex;
	local string NumString;
	local string Char;

	`Log(`StaticLocation, default.EnableTrace, 'TweaksTrace');

	Num = 0;
	StartIndex = -1;
	InputString = RemoveHTMLTags(InputString);

	for (i = 0; i < Len(InputString); i++)
	{
		Char = Mid(InputString, i, 1);

		if (Char >= "0" && Char <= "9")
		{
			if (StartIndex == -1)
			{
				StartIndex = i;
			}
		}
		else
		{
			if (StartIndex != -1)
			{
				EndIndex = i;
				break;
			}
		}
	}

	if (StartIndex != -1)
	{
		if (EndIndex == 0)
		{
			EndIndex = Len(InputString);
		}

		NumString = Mid(InputString, StartIndex, EndIndex - StartIndex);
		Num = int(NumString);
	}

	return Num;
}

static function string RemoveHTMLTags(string InputString)
{
	local string Result;
	local int i;
	local bool InsideTag;
	local string Char;

	`Log(`StaticLocation, default.EnableTrace, 'TweaksTrace');

	Result = "";
	InsideTag = false;

	for (i = 0; i < Len(InputString); i++)
	{
		Char = Mid(InputString, i, 1);

		if (Char == "<")
		{
			InsideTag = true;
		}
		else if (Char == ">")
		{
			InsideTag = false;
		}
		else if (!InsideTag)
		{
			Result $= Char;
		}
	}

	return Result;
}

static function bool ReturnFalse()
{
	return false;
}
