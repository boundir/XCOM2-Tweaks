class X2DLCInfo_ResistanceWarriorTweaks extends X2DownloadableContentInfo;

static event InstallNewCampaign(XComGameState StartState)
{
	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	PullResistanceWarriorFromCharacterPool(StartState);
}

static function PullResistanceWarriorFromCharacterPool(XComGameState StartState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_Unit CharacterPoolUnitState;
	local XComGameState_Item KevlarItemState;
	local XComOnlineProfileSettings ProfileSettings;
	local CharacterPoolManager CharacterPoolManager;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate KevlavTemplate;
	local StateObjectReference UnitRef;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	XComHQ = `XCOMHQ;
	CharacterPoolManager = `CHARACTERPOOLMGR;
	History = `XCOMHISTORY;
	ProfileSettings = `XPROFILESETTINGS;

	if (CharacterPoolManager.CharacterPool.Length == 0)
	{
		`Log("No character found in the Character Pool. Skipping.", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

		return;
	}

	if (ProfileSettings.Data.m_eCharPoolUsage != eCPSM_PoolOnly && ProfileSettings.Data.m_eCharPoolUsage != eCPSM_Mixed)
	{
		`Log("Character Pool setting does not pull from it. Skipping.", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

		return;
	}

	foreach XComHQ.Crew(UnitRef)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
		UnitState = XComGameState_Unit(StartState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

		if (UnitState == none)
		{
			continue;
		}

		if (!UnitState.IsSoldier())
		{
			continue;
		}

		if (!class'Helper_Tweaks'.static.IsResistanceWarriorUnit(UnitState))
		{
			continue;
		}

		`Log("Found Resistance Warrior" @ UnitState.GetFullName(), class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
		
		CharacterPoolUnitState = CharacterPoolManager.GetCharacter(UnitState.GetFullName());

		if (class'Helper_Tweaks'.static.IsUnitFromCharacterPool(CharacterPoolUnitState, UnitState))
		{
			`Log(UnitState.GetFullName() @ "is from the pool", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

			ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
			KevlavTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('KevlarArmor'));
			KevlarItemState = KevlavTemplate.CreateInstanceFromTemplate(StartState);

			UnitState.RemoveItemFromInventory(UnitState.GetItemInSlot(eInvSlot_Armor), StartState);
			UnitState.AddItemToInventory(KevlarItemState, eInvSlot_Armor, StartState);

			UnitState.SetTAppearance(CharacterPoolUnitState.kAppearance);
			UnitState.SetBackground(CharacterPoolUnitState.GetBackground());
		}
		else
		{
			`Log(UnitState.GetFullName() @ "is not from the pool. Remove them from the crew", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

			XComHQ.RemoveFromCrew(UnitRef);

			UnitState = CharacterPoolManager.CreateCharacter(StartState, ProfileSettings.Data.m_eCharPoolUsage, 'Soldier');
			UnitState.RandomizeStats();
			UnitState.ApplyInventoryLoadout(StartState);
			XComHQ.AddToCrew(StartState, UnitState);

			`Log(UnitState.GetFullName() @ "was added to the crew", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
		}
	}
}
