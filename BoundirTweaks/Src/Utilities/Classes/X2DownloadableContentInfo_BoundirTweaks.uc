//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_BoundirTweaks.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_BoundirTweaks extends X2DownloadableContentInfo;

static exec function KeyBindTweaksCopy()
{
	local UIScreen CurrentScreen;
	local UIScreenStack ScreenStack;

	`log("copy");

	ScreenStack = `SCREENSTACK;
	CurrentScreen = `ScreenStack.GetCurrentScreen();
	`log("Current Screen: " @ CurrentScreen);
	//`XENGINE.GamePlayers[0].Actor.CopyToClipboard(CurrentScreen.AS_GetInputText());
}

static exec function KeyBindTweaksPaste()
{
	local string ClipboardContent;
	local UIScreenStack ScreenStack;
	local UIScreen CurrentScreen;

	`log("paste");

	ScreenStack = `SCREENSTACK;
	CurrentScreen = `ScreenStack.GetCurrentScreen();

	`log("Current Screen: " @ CurrentScreen);
	
	ClipboardContent = `XENGINE.GamePlayers[0].Actor.PasteFromClipboard();
}