
class X2BreakthroughCondition_WeaponTypeTweak extends X2BreakthroughCondition editinlinenew hidecategories(Object);

var array<name> WeaponTypesMatch;

function bool MeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Item ItemState;
	local X2WeaponTemplate WeaponTemplate;

	ItemState = XComGameState_Item(kTarget);

	if (ItemState == none)
	{
		return false;
	}

	WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());

	if (WeaponTemplate == none)
	{
		return false;
	}

	if (WeaponTemplate.ItemCat != 'weapon')
	{
		return false;
	}

	return (WeaponTypesMatch.Find(WeaponTemplate.WeaponCat) != INDEX_NONE);
}