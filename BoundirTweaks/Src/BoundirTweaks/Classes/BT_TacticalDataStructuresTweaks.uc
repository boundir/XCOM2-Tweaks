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

struct AbilityEnvironmentalDamageControl
{
	var name AbilityName;
	var int EnvironmentDamage;
};

struct WeaponDamageValueControl
{
	var name Weapon;
	var WeaponDamageValue BaseDamage;
};

struct LoadoutManagement
{
	var name LoadoutName;
	var array<InventoryLoadoutItem> AddToLoadout;
	var array<InventoryLoadoutItem> RemoveFromLoadout;
};
