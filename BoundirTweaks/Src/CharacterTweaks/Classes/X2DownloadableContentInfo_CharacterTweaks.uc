class X2DownloadableContentInfo_CharacterTweaks extends X2DownloadableContentInfo;

struct BetaStrikeModifier
{
	var Name TemplateName;
	var Float BetaStrikeMod;
};

var config(GameData_SoldierSkills) array<BetaStrikeModifier> BETA_STRIKE_CHARACTERS;

static event OnPostTemplatesCreated()
{
	RulersAffectTimerAbilities();
	BetaStrikeCustomUnitHealthMultiplier();
}

static function RulersAffectTimerAbilities()
{
	local X2CharacterTemplateManager CharacterTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2CharacterTemplate CharacterTemplate;
	local AlienRulerData RulerData;

	CharacterTemplateManager = `GetCharMngr;

	foreach class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates(RulerData)
	{
		CharacterTemplateManager.FindDataTemplateAllDifficulties(RulerData.AlienRulerTemplateName, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			CharacterTemplate = X2CharacterTemplate(DataTemplate);

			if(CharacterTemplate != none)
			{
				CharacterTemplate.Abilities.AddItem('ResumeTimer');
				CharacterTemplate.Abilities.AddItem('PauseTimer');
			}
		}
	}
}

static function BetaStrikeCustomUnitHealthMultiplier()
{
	local X2CharacterTemplateManager CharacterTemplateManager;
	local array<X2DataTemplate> DifficulityVariants;
	local X2DataTemplate DataTemplate;
	local X2CharacterTemplate CharacterTemplate;
	local BetaStrikeModifier Character;

	CharacterTemplateManager = `GetCharMngr;

	foreach default.BETA_STRIKE_CHARACTERS(Character)
	{
		CharacterTemplateManager.FindDataTemplateAllDifficulties(Character.TemplateName, DifficulityVariants);

		foreach DifficulityVariants(DataTemplate)
		{
			CharacterTemplate = X2CharacterTemplate(DataTemplate);

			if(CharacterTemplate != none)
			{
				CharacterTemplate.OnStatAssignmentCompleteFn = BetaStrikeStatAssignment;
			}
		}
	}
}

function BetaStrikeStatAssignment(XComGameState_Unit UnitState)
{
	local float CurrentHealthMax;
	local UnitValue UnitValue;
	local int Idx;
	
	if(!`SecondWaveEnabled('BetaStrike'))
	{
		return;
	}

	if(!UnitState.GetUnitValue('Betastrikemod', UnitValue))
	{
		UnitState.SetUnitFloatValue('Betastrikemod', 1f, eCleanup_Never);
		return;
	}

	if (UnitValue.fValue ~= 2f)
	{
		return;
	}

	Idx = default.BETA_STRIKE_CHARACTERS.Find('TemplateName', UnitState.GetMyTemplateName());

	if (Idx != INDEX_NONE)
	{
		CurrentHealthMax = UnitState.GetMaxStat(eStat_HP);
		UnitState.SetBaseMaxStat(eStat_HP, Round(CurrentHealthMax * default.BETA_STRIKE_CHARACTERS[Idx].BetastrikeMod));
		UnitState.SetCurrentStat(eStat_HP, UnitState.GetMaxStat(eStat_HP));
		UnitState.SetUnitFloatValue('Betastrikemod', 2f, eCleanup_Never);
	}
}