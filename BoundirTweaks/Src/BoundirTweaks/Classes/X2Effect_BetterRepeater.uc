class X2Effect_BetterRepeater extends X2Effect_Persistent;

var int BonusCritDmg;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local X2WeaponTemplate WeaponTemplate;
	local X2AbilityToHitCalc_StandardAim StandardHit;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;
	local XComGameState_HeadquartersXCom XComHQ;
	local int DamageMod;

	`log("Bonus critical damage:" @ BonusCritDmg,, 'BetterRepeaterEffect');

	if (class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult))
	{
		WeaponDamageEffect = X2Effect_ApplyWeaponDamage(class'X2Effect'.static.GetX2Effect(AppliedData.EffectRef));

		if (WeaponDamageEffect != none)
		{
			if (WeaponDamageEffect.bIgnoreBaseDamage)
			{
				return 0;
			}
		}

		StandardHit = X2AbilityToHitCalc_StandardAim(AbilityState.GetMyTemplate().AbilityToHitCalc);

		if(StandardHit != none && StandardHit.bIndirectFire) 
		{
			return 0;
		}

		DamageMod = 0;
		WeaponTemplate = X2WeaponTemplate(AbilityState.GetSourceWeapon().GetMyTemplate());

		XComHQ = XComGameState_HeadquartersXCom( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_HeadquartersXCom', true ) );
		if (XComHQ != none)
		{
			if(XComHQ.bEmpoweredUpgrades)
			{
				DamageMod = class'X2Ability_Tweaks'.default.REPEATER_EMPOWER_BONUS_DMG;
			}
		}

		if(WeaponTemplate.InventorySlot == eInvSlot_PrimaryWeapon)
		{
			if(AbilityState.SourceWeapon == EffectState.ApplyEffectParameters.ItemStateObjectRef)
			{
				if (AppliedData.AbilityResultContext.HitResult == eHit_Crit)
				{
					return DamageMod + BonusCritDmg;
				}
			}
		}
	}

	return 0;
}
