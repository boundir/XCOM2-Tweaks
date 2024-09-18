class X2Encyclopedia_InfiltrationTutorialClosure extends Object;

var name StageName;

function bool ShouldShow ()
{
	local XComGameState_CovertInfiltrationInfo CIInfo;
	local bool EnableTutorial;

	EnableTutorial = true;
	if (!EnableTutorial) return true;

	CIInfo = class'XComGameState_CovertInfiltrationInfo'.static.GetInfo();
	
	return CIInfo.TutorialStagesShown.Find(StageName) != INDEX_NONE;
}
