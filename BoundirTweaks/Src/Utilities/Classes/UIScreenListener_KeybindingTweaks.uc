class UIScreenListener_KeybindingTweaks extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local XComInputBase XComInputBase;
	local name Key;

	if (UIInputDialogue(Screen) == none)
	{
		`log("UIInputDialogue none");
		return;
	}

	if (RegisterHandler())
	{
		return;
	}

	XComInputBase = XComInputBase(Screen.PC.PlayerInput);

	if (XComInputBase == none)
	{
		`log("XComInputBase none");
		return;
	}

	Key = 'C';
	if (InStr(XComInputBase.GetBind(Key), "KeyBindTweaks") == INDEX_NONE)
	{
		SetKeyBinding(XComInputBase, Key, "KeyBindTweaksCopy", true, false);
	}

	Key = 'V';
	if (InStr(XComInputBase.GetBind(Key), "KeyBindTweaks") == INDEX_NONE)
	{
		SetKeyBinding(XComInputBase, Key, "KeyBindTweaksPaste", true, false);
	}

	Key = 'Insert';
	if (InStr(XComInputBase.GetBind(Key), "KeyBindTweaks") == INDEX_NONE)
	{
		SetKeyBinding(XComInputBase, Key, "KeyBindTweaksPaste", false, true);
	}
}

static function SetKeyBinding(XComInputBase XComInputBase, const out name KeyBindName, string Command, bool Control, bool Shift)
{
	local KeyBind KeyBind;
	local int KeyBindIndex;

	if (Left(Command, 1) == "\"" && Right(Command, 1) == "\"")
	{
		Command = Mid(Command, 1, Len(Command) - 2);
	}

	for (KeyBindIndex = XComInputBase.Bindings.Length - 1; KeyBindIndex >= 0; KeyBindIndex--)
	{
		if (XComInputBase.Bindings[KeyBindIndex].Name == KeyBindName)
		{
			XComInputBase.Bindings[KeyBindIndex].Command = Command;
			`log("Binding '"@KeyBindName@"' found, setting command '"@Command@"'");

			return;
		}
	}

	
	`log("Binding '"@KeyBindName@"' NOT found, adding new binding with command '"@Command@"'");

	KeyBind.Name = KeyBindName;
	KeyBind.Command = Command;
	KeyBind.Control = Control;
	KeyBind.Shift = Shift;
	XComInputBase.Bindings[XComInputBase.Bindings.Length] = KeyBind;
}

function bool RegisterHandler()
{
	local BoundirTweaks_CallbackHandler CallbackHandler;

	if (Function'XComGame.UIScreenStack.SubscribeToOnInput' != none)
	{
		CallbackHandler = new class'BoundirTweaks_CallbackHandler';
		`log("Subbed");

		`SCREENSTACK.SubscribeToOnInput(CallbackHandler.CHOnInput);
		return true;
	}
	`log("Not subbed");

	return false;
}