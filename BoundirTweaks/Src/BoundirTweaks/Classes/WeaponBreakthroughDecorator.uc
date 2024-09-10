class WeaponBreakthroughDecorator extends Object;

var array<name> WeaponCategories;

function ResearchCompleted(XComGameState NewGameState, XComGameState_Tech TechState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local name WeaponCategory;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	foreach WeaponCategories(WeaponCategory)
	{
		`Log(WeaponCategory @ "weapon category benefits from breakthrough" @ TechState.GetMyTemplateName(), default.EnableDebug, 'TweaksDebug');

		XComHQ.ExtraUpgradeWeaponCats.AddItem(WeaponCategory);
	}
}
