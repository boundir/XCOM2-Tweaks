class X2EventListener_CovertActionStaffSlotFilled extends X2EventListener config(GameData);

var localized string CovertActionNoRewardReason;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateCovertActionStaffSlotFilledTemplate());

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

static function EventListenerReturn CanUnitGainReward(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple Tuple;
	local XComGameState_Reward RewardState;
	local XComGameState_Unit UnitState;
	local UICovertActionStaffSlot UIStaffSlot;
	local XComGameState_StaffSlot StaffSlotState;
	local StateObjectReference UnitRef;
	local CovertActionStatRewardLimit StatRewardLimit;
	local ECharStatType StatType;
	local XComGameStateHistory History;
	local int StatLimit;
	local int UnitStat;
	local int StatBonus;
	local int ScanStatRewardLimit;

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

	if (!UnitState.IsSoldier())
	{
		`Log("Unit is not a soldier", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
		return ELR_NoInterrupt;
	}

	`Log("CovertAction Reward is" @ RewardState.GetMyTemplateName(), class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
	`Log("CovertAction Unit is" @ UnitState.GetMyTemplateName(), class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
	`Log("CovertAction Reward text is" @ Tuple.Data[0].s, class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

	ScanStatRewardLimit = class'X2DownloadableContentInfo_StrategyTweaks'.default.COVERT_ACTION_STAT_LIMIT.Find('RewardName', RewardState.GetMyTemplateName());

	if (ScanStatRewardLimit == INDEX_NONE)
	{
		`Log(RewardState.GetMyTemplateName() @ "not found in config", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

		return ELR_NoInterrupt;
	}

	StatRewardLimit = class'X2DownloadableContentInfo_StrategyTweaks'.default.COVERT_ACTION_STAT_LIMIT[ScanStatRewardLimit];

	StatType = StatRewardLimit.StatType;
	StatLimit = StatRewardLimit.StatLimit;
	UnitStat = int(UnitState.GetMaxStat(StatType));

	`Log("StatType" @ StatType, class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
	`Log("StatLimit" @ StatLimit, class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
	`Log("UnitStat" @ UnitStat, class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

	StatBonus = class'Helper_Tweaks'.static.ExtractNumberFromString(Tuple.Data[0].s);
	`Log("StatBonus" @ StatBonus, class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');

	if (UnitStat + StatBonus > StatLimit)
	{
		`Log("Stat limit" @ StatLimit @ "reached. This unit won't receive stat boost", class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
		Tuple.Data[0].s = "";
	}
	else
	{
		`Log("This unit has not reached stat limit" @ StatLimit $ ". They will receive" @ RewardState.GetRewardPreviewString() @ class'X2TacticalGameRulesetDataStructures'.default.m_aCharStatLabels[StatType], class'Helper_Tweaks'.default.EnableDebug, 'TweaksDebug');
	
		return ELR_NoInterrupt;
	}

	return ELR_NoInterrupt;
}
