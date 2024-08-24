class BT_TacticalDataStructuresTweaks extends Object;

struct WeaponEnvironmentalDamageControlException
{
	var name Weapon;
	var int EnvironmentDamage;
};

struct WeaponEnvironmentalDamageControl
{
	var name WeaponCategory;
	var int EnvironmentDamage;
	var name Tech;
	var array<WeaponEnvironmentalDamageControlException> Exceptions;
};

struct LootControl
{
	var name Table;
	var name Loot;
	var name Replacement;
};

struct UnitLootReplacer
{
	var name Supplier;
	var name Consumer;
};
