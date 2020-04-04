class X2Ability_Tweaks extends X2Ability config(GameCore);

var config int REPEATER_M1_CRIT_DMG;
var config int REPEATER_M2_CRIT_DMG;
var config int REPEATER_M3_CRIT_DMG;
var config int REPEATER_EMPOWER_BONUS_DMG;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(AddBetterRepeaterAbility('BetterRepeaterM1', default.REPEATER_M1_CRIT_DMG));
	Templates.AddItem(AddBetterRepeaterAbility('BetterRepeaterM2', default.REPEATER_M2_CRIT_DMG));
	Templates.AddItem(AddBetterRepeaterAbility('BetterRepeaterM3', default.REPEATER_M3_CRIT_DMG));

	return Templates;
}

static function X2AbilityTemplate AddBetterRepeaterAbility(name TemplateName, int RepeaterDmgMod)
{
	local X2AbilityTemplate Template;
	local X2Effect_BetterRepeater DamageEffect;

	`CREATE_X2ABILITY_TEMPLATE (Template, TemplateName);
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.bIsPassive = true;

	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	DamageEffect = new class'X2Effect_BetterRepeater';
	DamageEffect.BonusCritDmg = RepeaterDmgMod;
	DamageEffect.BuildPersistentEffect(1, true, false, false);
	DamageEffect.DuplicateResponse = eDupe_Ignore;
	Template.AddTargetEffect(DamageEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	
	return Template;
}
