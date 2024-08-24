class X2Effect_BetterRepeater extends X2Effect_Persistent config(GameCore);

var config int REPEATER_M1_CRIT_DMG;
var config int REPEATER_M2_CRIT_DMG;
var config int REPEATER_M3_CRIT_DMG;
var config int REPEATER_EMPOWER_BONUS_DMG;

var int BonusCritDmg;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local X2WeaponTemplate WeaponTemplate;
	local X2AbilityToHitCalc_StandardAim StandardHit;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;
	local int DamageMod;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	DamageMod = 0;

	if (class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult))
	{
		WeaponDamageEffect = X2Effect_ApplyWeaponDamage(class'X2Effect'.static.GetX2Effect(AppliedData.EffectRef));

		if (WeaponDamageEffect != none)
		{
			if (WeaponDamageEffect.bIgnoreBaseDamage)
			{
				return DamageMod;
			}
		}

		StandardHit = X2AbilityToHitCalc_StandardAim(AbilityState.GetMyTemplate().AbilityToHitCalc);

		if (StandardHit != none && StandardHit.bIndirectFire) 
		{
			return DamageMod;
		}

		WeaponTemplate = X2WeaponTemplate(AbilityState.GetSourceWeapon().GetMyTemplate());

		if (WeaponTemplate.WeaponCat == 'grenade')
		{
			return DamageMod;
		}

		if (AbilityState.SourceWeapon == EffectState.ApplyEffectParameters.ItemStateObjectRef)
		{
			if (AppliedData.AbilityResultContext.HitResult == eHit_Crit)
			{
				DamageMod = (class'X2Item_DefaultUpgrades'.static.AreUpgradesEmpowered()) ? default.REPEATER_EMPOWER_BONUS_DMG : 0;

				return DamageMod + BonusCritDmg;
			}
		}
	}

	return DamageMod;
}
