//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_BoundirTweaks.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_BoundirTweaks extends X2DownloadableContentInfo;

static event OnPostTemplatesCreated()
{
	OnPostStrategyTemplatesCreated();
	OnPostAbilityTemplatesCreated();
	OnPostItemTemplatesCreated();
	OnPostCharacterTemplatesCreated();
}

static function OnPostStrategyTemplatesCreated()
{
	// Prevent DE from spawning
	class'X2Helper_TemplateTweaks'.static.DisableDarkEvents();
}

static function OnPostAbilityTemplatesCreated()
{
	// Rage Strike will do Melee damage
	class'X2Helper_TemplateTweaks'.static.PatchRageStrike();
	// Reduce Justice environemental damage
	class'X2Helper_TemplateTweaks'.static.PatchJustice();
	// Fixes Suppression issues (AA AbilityTweaks)
	class'X2Helper_TemplateTweaks'.static.PatchSuppression(); // Prevent units from suppressing Shadowstep units.
	class'X2Helper_TemplateTweaks'.static.PatchRemoveSuppressionEffect(); // Teleport removes suppression.
	class'X2Helper_TemplateTweaks'.static.PatchCantDoIfSuppressed(); // Can't xxx while suppressed galore.
	// Blazing Pinions can panic units
	// class'X2Helper_TemplateTweaks'.static.PatchBlazingPinions();
	// EU Berserker's Bull Rush only activate on XCOM turn
	class'X2Helper_TemplateTweaks'.static.PatchBullRush();
	// Modify DisruptorRifleCrit so it can also be effective against Templar and Psi Operative
	class'X2Helper_TemplateTweaks'.static.PatchDisruptorRifleAbility();
	// Rulers resume timer on escape
	class'X2Helper_TemplateTweaks'.static.PatchRulerPauseTimer();
	// Fix Pounce to not trigger when concealed
	class'X2Helper_TemplateTweaks'.static.PatchPounce();
}

static function OnPostItemTemplatesCreated()
{
	// Remove the melee attribute from Hunter Axe and Knife Thrown
	class'X2Helper_TemplateTweaks'.static.PatchWeaponThrown();
	// Add custom condition to prevent and allow some units to take extra damage from Bluescreen and Null Rounds
	class'X2Helper_TemplateTweaks'.static.PatchBluescreenRoundsDamageCondition();
	class'X2Helper_TemplateTweaks'.static.PatchNullRoundsDamageCondition();
	// Include A Better Repeater with Inside Knowledge
	class'X2Helper_TemplateTweaks'.static.BetterRepeater();
	// Add Crit ability to Warlock rifle (DisruptorRifleCrit)
	class'X2Helper_TemplateTweaks'.static.PatchWarlockRifle();
	// Cap ability rewards from Covert Action
	class'X2Helper_TemplateTweaks'.static.CapSoldierStatBoostRewards();
}

static function OnPostCharacterTemplatesCreated()
{
	// Modify Beta Strike bonus for specific units
	class'X2Helper_TemplateTweaks'.static.PatchBetaStrike();
	// Adds Pause & Resume Timer abilities to Rulers
	class'X2Helper_TemplateTweaks'.static.PatchRulersTimer();
}

static function bool AbilityTagExpandHandler(string InString, out string OutString)
{
	local name Type;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local int BonusDamage;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	Type = name(InString);

	switch(Type)
	{
		case 'REPEATERDMGBONUSM1':
			BonusDamage = (XComHQ.bEmpoweredUpgrades) ? class'X2Ability_Tweaks'.default.REPEATER_EMPOWER_BONUS_DMG : 0;
			OutString = string(class'X2Ability_Tweaks'.default.REPEATER_M1_CRIT_DMG + BonusDamage);
			return true;
		case 'REPEATERDMGBONUSM2':
			BonusDamage = (XComHQ.bEmpoweredUpgrades) ? class'X2Ability_Tweaks'.default.REPEATER_EMPOWER_BONUS_DMG : 0;
			OutString = string(class'X2Ability_Tweaks'.default.REPEATER_M2_CRIT_DMG + BonusDamage);
			return true;
		case 'REPEATERDMGBONUSM3':
			BonusDamage = (XComHQ.bEmpoweredUpgrades) ? class'X2Ability_Tweaks'.default.REPEATER_EMPOWER_BONUS_DMG : 0;
			OutString = string(class'X2Ability_Tweaks'.default.REPEATER_M3_CRIT_DMG + BonusDamage);
			return true;
	}
	return false;
}