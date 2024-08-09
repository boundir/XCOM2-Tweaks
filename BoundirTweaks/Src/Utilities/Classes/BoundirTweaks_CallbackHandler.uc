class BoundirTweaks_CallbackHandler extends Object;

function bool CHOnInput(int iInput, int ActionMask)
{

	`log("iInput" $ iInput);
	`log("ActionMask" $ ActionMask);

	if (iInput == class'UIUtilities_Input'.const.FXS_KEY_LEFT_CONTROL)
	{
		`log("CONTROL pressed");
		if (iInput == class'UIUtilities_Input'.const.FXS_KEY_V)
		{
			`log("V pressed");
			if (ActionMask == class'UIUtilities_Input'.const.FXS_ACTION_RELEASE)
			{
				`log("Released");
				class'X2DownloadableContentInfo_BoundirTweaks'.static.KeyBindTweaksPaste();
				return true;
			}
		}
	}

	return false;
}