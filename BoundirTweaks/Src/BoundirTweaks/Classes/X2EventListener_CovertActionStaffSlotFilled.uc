class X2EventListener_CovertActionStaffSlotFilled extends X2EventListener;

var localized string ReasonNoReward;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateCovertActionStaffSlotFilledTemplate());

	if (class'Helper_Tweaks'.static.IsModActive('CovertInfiltration'))
	{
		Templates.AddItem(CreateOnSquadSelectUpdate());
	}

	return Templates;
}

static function CHEventListenerTemplate CreateCovertActionStaffSlotFilledTemplate()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'CAUnitSelected');

	Template.RegisterInTactical = false;
	Template.RegisterInStrategy = true;
	Template.AddCHEvent('CovertAction_UpdateRewardString', CanUnitGainReward, ELD_Immediate);

	return Template;
}

static function CHEventListenerTemplate CreateOnSquadSelectUpdate()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'SquadSelectExtraInfo');

	Template.RegisterInTactical = false;
	Template.RegisterInStrategy = true;
	Template.AddCHEvent('rjSquadSelect_ExtraInfo', CanUnitGainRewardWithCI, ELD_Immediate, 100);

	return Template;
}

static function EventListenerReturn CanUnitGainReward(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple Tuple;
	local XComGameState_Reward RewardState;
	local XComGameState_Unit UnitState;
	local UICovertActionStaffSlot UIStaffSlot;
	local XComGameState_StaffSlot StaffSlotState;
	local StateObjectReference UnitRef;
	local XComGameStateHistory History;
	local int StatBonus;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	Tuple = XComLWTuple(EventData);
	UIStaffSlot = UICovertActionStaffSlot(EventSource);

	if (Tuple == none || Tuple.id != 'CovertAction_UpdateRewardString')
	{
		return ELR_NoInterrupt;
	}

	if (UIStaffSlot == none)
	{
		`Log("UIStaffSlot missing", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;
	StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(UIStaffSlot.StaffSlotRef.ObjectID));

	if (StaffSlotState == none || !StaffSlotState.IsSlotFilled())
	{
		`Log("StaffSlotState missing or no slot is filled", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
		return ELR_NoInterrupt;
	}

	RewardState = XComGameState_Reward(History.GetGameStateForObjectID(UIStaffSlot.RewardRef.ObjectID));

	if (RewardState == none)
	{
		`Log("RewardState missing", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
		return ELR_NoInterrupt;
	}

	UnitRef = StaffSlotState.GetAssignedStaffRef();
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	if (UnitState == none)
	{
		`Log("UnitState missing", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
		return ELR_NoInterrupt;
	}

	StatBonus = class'Helper_Tweaks'.static.ExtractNumberFromString(Tuple.Data[0].s);

	if (ShouldRewriteReward(UnitState, RewardState, StatBonus))
	{
		Tuple.Data[0].s = "";
	}

	return ELR_NoInterrupt;
}

static function EventListenerReturn CanUnitGainRewardWithCI(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComGameStateHistory History;
	local UIScreenStack ScreenStack;
	local XComGameState_Reward RewardState;
	local SSAAT_SquadSelectConfiguration Configuration;
	local UICovertActionsGeoscape UICovertAction;
	local XComGameState_CovertAction ActionState;
	local XComGameState_Unit UnitState;
	local StateObjectReference UnitRef;
	local LWTuple Tuple;
	local array<SSAAT_SlotNote> Notes;
	local SSAAT_SlotNote Note;
	local LWTuple NoteTuple;
	local LWTValue Value;
	local int SlotIndex;
	local int StatBonus;
	local int NoteIndex;
	local int i;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	Tuple = LWTuple(EventData);

	if (Tuple == none || Tuple.id != 'rjSquadSelect_ExtraInfo')
	{
		return ELR_NoInterrupt;
	}

	Configuration = class'SSAAT_Helpers'.static.GetCurrentConfiguration();

	if (Configuration == none)
	{
		`Log("Configuration missing", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

		return ELR_NoInterrupt;
	}

	Notes = Configuration.GetSlotConfiguration(SlotIndex).Notes;

	for (i = Notes.Length - 1; i >= 0; i--)
	{
		`Log("Note:" @ Notes[i].Text, class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

		if (InStr(Notes[i].Text, class'UICovertActionStaffSlot'.default.m_strSoldierReward) != -1)
		{
			Note = Notes[i];
			NoteIndex = i;
		}

		if (InStr(Notes[i].Text, default.ReasonNoReward) != -1)
		{
			Notes.Remove(i, 1);
		}
	}

	SlotIndex = Tuple.Data[0].i;
	Configuration.Slots[SlotIndex].Notes[NoteIndex].BGColor = class'UIUtilities_Colors'.const.GOOD_HTML_COLOR;

	ScreenStack = `SCREENSTACK;
	UICovertAction = UICovertActionsGeoscape(ScreenStack.GetFirstInstanceOf(class'UICovertActionsGeoscape'));

	if (UICovertAction == none)
	{
		`Log("UICovertAction missing", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

		return ELR_NoInterrupt;
	}

	ActionState = UICovertAction.SSManager.GetAction();

	if (ActionState == none)
	{
		`Log("ActionState missing", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;
	RewardState = XComGameState_Reward(History.GetGameStateForObjectID(ActionState.StaffSlots[SlotIndex].RewardRef.ObjectID));

	if (RewardState == none)
	{
		`Log("RewardState missing", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

		return ELR_NoInterrupt;
	}

	UnitRef = `XCOMHQ.Squad[SlotIndex];

	if (UnitRef.ObjectID <= 0)
	{
		`Log("Incorrect UnitRef", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

		return ELR_NoInterrupt;
	}

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));

	if (UnitState == none)
	{
		`Log("UnitState missing", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

		return ELR_NoInterrupt;
	}

	

	StatBonus = class'Helper_Tweaks'.static.ExtractNumberFromString(Note.Text);

	if (ShouldRewriteReward(UnitState, RewardState, StatBonus))
	{
		Configuration.Slots[SlotIndex].Notes[NoteIndex].BGColor = class'UIUtilities_Colors'.const.DISABLED_HTML_COLOR;

		Value.kind = LWTVObject;
		NoteTuple = new class'LWTuple';
		NoteTuple.Data.Length = 3;
		
		NoteTuple.Data[0].kind = LWTVString;
		NoteTuple.Data[0].s = default.ReasonNoReward;

		NoteTuple.Data[1].kind = LWTVString;
		NoteTuple.Data[1].s = "000000";
	
		NoteTuple.Data[2].kind = LWTVString;
		NoteTuple.Data[2].s = class'UIUtilities_Colors'.const.BAD_HTML_COLOR;

		Value.o = NoteTuple;
		Tuple.Data.AddItem(Value);
	}

	return ELR_NoInterrupt;
}

static private function bool ShouldRewriteReward(XComGameState_Unit UnitState, XComGameState_Reward RewardState, int StatBonus)
{
	local CovertActionStatRewardLimit StatRewardLimit;
	local ECharStatType StatType;
	local int StatLimit;
	local int UnitStat;
	local int ScanStatRewardLimit;

	if (!UnitState.IsSoldier())
	{
		`Log("Unit is not a soldier", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
		return false;
	}

	ScanStatRewardLimit = class'X2DLCInfo_StrategyTweaks'.default.COVERT_ACTION_STAT_LIMIT.Find('RewardName', RewardState.GetMyTemplateName());

	if (ScanStatRewardLimit == INDEX_NONE)
	{
		`Log(RewardState.GetMyTemplateName() @ "not found in config", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
		return false;
	}

	StatRewardLimit = class'X2DLCInfo_StrategyTweaks'.default.COVERT_ACTION_STAT_LIMIT[ScanStatRewardLimit];

	StatType = StatRewardLimit.StatType;
	StatLimit = StatRewardLimit.StatLimit;
	UnitStat = int(UnitState.GetMaxStat(StatType));

	if (UnitStat + StatBonus > StatLimit)
	{
		`Log("Stat limit" @ StatLimit @ "reached. This unit won't receive stat boost", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
		return true;
	}
	else
	{
		`Log("This unit has not reached stat limit" @ StatLimit $ ". They will receive" @ RewardState.GetRewardPreviewString(), class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
		return false;
	}
}
