class X2EventListener_GTSTrainingTweak extends X2EventListener config(GameData);

var config array<name> RESEARCH_UNLOCK_PSIONIC_CLASS;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateValidateGTSClassTrainingListenerTemplate());

	return Templates;
}

static function CHEventListenerTemplate CreateValidateGTSClassTrainingListenerTemplate()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'ValidateGTSTraining_Psionic');

	Template.RegisterInTactical = false;
	Template.RegisterInStrategy = true;
	Template.AddCHEvent('ValidateGTSClassTraining', PsionicValidateGTSClassTraining, ELD_Immediate);
	
	return Template;
}

static function EventListenerReturn PsionicValidateGTSClassTraining(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple Tuple;
	local X2SoldierClassTemplate SoldierClassTemplate;

	Tuple = XComLWTuple(EventData);

	if (Tuple != none)
	{
		SoldierClassTemplate = X2SoldierClassTemplate(Tuple.Data[1].o);

		if (SoldierClassTemplate != none && SoldierClassTemplate.DataName == 'Psionic')
		{
			Tuple.Data[0].b = CanTrainPsionicClass();
		}
	}

	return ELR_NoInterrupt;
}

// Dictates conditions for Psionic Class to be trainable
// May want to add conditions in the future (psionic count, crew count, force level...)
static private function bool CanTrainPsionicClass()
{
	return SatisfyResearch();
}

static private function bool SatisfyResearch()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local bool SatisfyCondition;

	XComHQ = `XCOMHQ;
	History = `XCOMHISTORY;

	SatisfyCondition = false;

	foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
	{
		if(default.RESEARCH_UNLOCK_PSIONIC_CLASS.Find(TechState.GetMyTemplateName()) == INDEX_NONE)
		{
			continue;
		}

		SatisfyCondition = XComHQ.TechIsResearched(TechState.GetReference()) ? true : false;
	}

	return SatisfyCondition;
}

