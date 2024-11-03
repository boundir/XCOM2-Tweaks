class UICovertActionStaffSlot_Tweak extends UICovertActionStaffSlot dependson(UIPersonnel, XComGameState_CovertAction);

function UpdateData()
{
	local XComGameStateHistory History;
	local XComGameState_CovertAction ActionState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_Reward RewardState;
	local Texture2D SoldierPicture;
	local string Label, Value, Button, SlotImage, RankImage, ClassImage, ButtonLabel2, CohesionUnitNames;
	local XComGameState_Unit Unit;
	local XComGameState_CampaignSettings SettingsState;
	local XGParamTag ParamTag;

	`Log(`StaticLocation, class'Helper_Tweaks'.default.EnableTrace, 'TweaksTrace');

	History = `XCOMHISTORY;
	StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(StaffSlotRef.ObjectID));
	RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRef.ObjectID));
	ActionState = GetAction();

	eState = eUIState_Normal;

	if (RewardState != None && !ActionState.bCompleted)
	{
		Value = UpdateRewardStringOnSlotUpdated(RewardState.GetRewardPreviewString());
		if (Value != "" && RewardState.GetMyTemplateName() != 'Reward_DecreaseRisk')
		{
			Value = class'UIUtilities_Text'.static.GetColoredText(m_strSoldierReward @ Value, eUIState_Good);
		}
	}

	Label = StaffSlotState.GetNameDisplayString();
	ButtonLabel2 = "";

	if (!StaffSlotState.IsSlotFilled())
	{
		if (bFame)
		{
			Label = m_strFamous @ Label;
		}

		if (bOptional)
		{
			Label = m_strOptionalSlot @ Label;
		}
		else
		{
			Label = m_strRequiredSlot @ Label;
		}

		if (StaffSlotState.IsEngineerSlot())
		{
			Button = m_strAddEngineer;
		}
		else if (StaffSlotState.IsScientistSlot())
		{
			Button = m_strAddScientist;
		}
		else
		{
			Button = m_strAddSoldier;
		}

		SlotImage = "";
		eState = eUIState_Normal;

		if (!StaffSlotState.IsUnitAvailableForThisSlot())
		{
			Value @= "\n" $ class'UIUtilities_Text'.static.GetColoredText(m_strNoUnitAvailable, eUIState_Disabled);
			eState = eUIState_Disabled;
		}
	}
	else
	{
		eState = eUIState_Good;
		if (!ActionState.bCompleted && !ActionState.bStarted)
		{
			Button = m_strClearSoldier;
		}

		//TODO: @kderda This check should be removed once the UpdateSoldierPortraitImage callback no longer comes back through here
		UnitRef = StaffSlotState.GetAssignedStaffRef();
		SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
		SoldierPicture = `XENGINE.m_kPhotoManager.GetHeadshotTexture(SettingsState.GameIndex, UnitRef.ObjectID, 128, 128);

		if (SoldierPicture == none)
		{
			//Take a picture if one isn't available - this could happen in the initial mission prior to any soldier getting their picture taken
			`HQPRES.GetPhotoboothAutoGen().AddHeadShotRequest(UnitRef, 128, 128, UpdateSoldierPortraitImage, , , true);
			`HQPRES.GetPhotoboothAutoGen().RequestPhotos();

			`GAME.GetGeoscape().m_kBase.m_kCrewMgr.TakeCrewPhotobgraph(UnitRef, , true);
		}
		else
		{
			SlotImage = class'UIUtilities_Image'.static.ValidateImagePath(PathName(SoldierPicture));
		}

		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		RankImage = Unit.IsSoldier() ? class'UIUtilities_Image'.static.GetRankIcon(Unit.GetRank(), Unit.GetSoldierClassTemplateName()) : "";
		ClassImage = Unit.IsSoldier() ? Unit.GetSoldierClassTemplate().IconImage : Unit.GetMPCharacterTemplate().IconImage;

		if (Unit.IsSoldier() && ActionState.HasAmbushRisk() && !ActionState.bStarted)
		{
			ButtonLabel2 = m_strEditLoadout;
		}

		if (ActionState.bCompleted && Unit.IsSoldier())
		{
			if (Unit.IsDead())
			{
				Value4 = Caps(m_strSoldierKilled);
			}
			else
			{
				PromoteLabel = (Unit.ShowPromoteIcon()) ? class'UISquadSelect_ListItem'.default.m_strPromote : "";
				Value4 = Caps(ActionState.GetStaffRisksAppliedString(StaffIndex)); // Value 4 is automatically red / negative!

				// Issue #810: Don't display XP and cohesion gain if rewards weren't
				// given on completion of the covert action (since XP and cohesion are
				// not granted in that case).
				/// HL-Docs: ref:CovertAction_PreventGiveRewards
				if (!Unit.bCaptured && !ActionState.RewardsNotGivenOnCompletion)
				{
					Value1 = m_strGainedXP; // Gained Experience
					CohesionUnitNames = GetCohesionRewardUnits();
					if (CohesionUnitNames != "")
					{
						ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
						ParamTag.StrValue0 = CohesionUnitNames;
						Value2 = `XEXPAND.ExpandString(m_strGainedCohesion); // Cohesion increased
						Value3 = (RewardState != none) ? UpdateRewardStringOnSlotUpdated(RewardState.GetRewardString()) : "";
					}
					else
					{
						// If there are no other soldiers on the CA for cohesion, bump the reward info to the second line
						Value2 = (RewardState != none) ? UpdateRewardStringOnSlotUpdated(RewardState.GetRewardString()) : "";
					}
				}
			}
		}
	}

	Update(Label, Value, Button, SlotImage, RankImage, ClassImage, ButtonLabel2);
}

private function string UpdateRewardStringOnSlotUpdated(string RewardString)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'CovertAction_UpdateRewardString';
	Tuple.Data.Add(1);
	Tuple.Data[0].kind = XComLWTVString;
	Tuple.Data[0].s = RewardString;

	`XEVENTMGR.TriggerEvent('CovertAction_UpdateRewardString', Tuple, self, none);

	return Tuple.Data[0].s;
}
