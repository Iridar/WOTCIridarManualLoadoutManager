class UISL_MLM extends UIStrategyScreenListener config(UI);

// Add Save Loadout and Load Loadout buttons to UIArmory_Loadout. 

var config int SaveLoadout_OffsetX;
var config int SaveLoadout_OffsetY;

var config int LockLoadout_OffsetX;
var config int LockLoadout_OffsetY;

var localized string strSaveLoadout;
var localized string strLockLoadout;

var bool bCHLPresent;

// This event is triggered after a screen is initialized
event OnInit(UIScreen Screen)
{
	if (UIArmory_Loadout(Screen) != none)
	{
		AddButtons(UIArmory_Loadout(Screen));

		if (bCHLPresent)
		{
			`SCREENSTACK.SubscribeToOnInput(OnArmoryLoadoutInput);
		}
		else
		{
			bCHLPresent = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate('CHXComGameVersion') != none;
			if (bCHLPresent)
			{
				`SCREENSTACK.SubscribeToOnInput(OnArmoryLoadoutInput);
			}
		}
	}
}

// This event is triggered after a screen receives focus
event OnReceiveFocus(UIScreen Screen)
{
	if (UIArmory_Loadout(Screen) != none)
	{
		AddButtons(UIArmory_Loadout(Screen)); // Mr. Nice: Not sure this is required? It's not like NavHelp which gets flushed on pratically any kind of refresh/update...

		if (bCHLPresent)
		{
			`SCREENSTACK.SubscribeToOnInput(OnArmoryLoadoutInput);
		}
	}
}

event OnLoseFocus(UIScreen Screen)
{
	if (UIArmory_Loadout(Screen) != none && bCHLPresent)
	{
		`SCREENSTACK.UnsubscribeFromOnInput(OnArmoryLoadoutInput);
	}
}

event OnRemovedFocus(UIScreen Screen)
{
	if (UIArmory_Loadout(Screen) != none && bCHLPresent)
	{
		`SCREENSTACK.UnsubscribeFromOnInput(OnArmoryLoadoutInput);
	}
}

private function AddButtons(UIArmory_Loadout Screen)
{
	local XComGameState_Unit	Unit;
	local UIButton				SaveLoadoutButton;
	local UIButton				ToggleLoadoutLockButton;
	local UIPanel				ListContainer;
	local UIList				List;

	Unit = Screen.GetUnit();

	if (Unit == none) return;

	ListContainer = Screen.EquippedListContainer;

	SaveLoadoutButton = UIButton(ListContainer.GetChild('IRI_SaveLoadoutButton', false));
	SaveLoadoutButton = ListContainer.Spawn(class'UIButton', ListContainer).InitButton('IRI_SaveLoadoutButton', default.strSaveLoadout, SaveLoadoutButtonClicked, eUIButtonStyle_NONE);
	SaveLoadoutButton.SetPosition(default.SaveLoadout_OffsetX - 108.65, default.SaveLoadout_OffsetY - 121);
	SaveLoadoutButton.AnimateIn(0);

	ToggleLoadoutLockButton = UIButton(ListContainer.GetChild('IRI_ToggleLoadoutLockButton', false));
	ToggleLoadoutLockButton = ListContainer.Spawn(class'UIButton', ListContainer).InitButton('IRI_ToggleLoadoutLockButton',, ToggleLoadoutButtonClicked, eUIButtonStyle_NONE);

	ToggleLoadoutLockButton.SetText(default.strLockLoadout);
	ToggleLoadoutLockButton.SetPosition(default.LockLoadout_OffsetX - 108.65, default.LockLoadout_OffsetY - 121);
	ToggleLoadoutLockButton.AnimateIn(0);

	// The screen disables navigations for the list, which now forces selection to the buttons, when it flips between the two lists
	// This is redundant, since navigation is flipped on the list container as well. So, just do this brilliant fudge...
	// This is done not just for controllers, since it messes up keyboard navigation as well, and even for mouse only
	// highlights one of the buttons when it shouldn't.
	ListContainer.Navigator.OnRemoved = EnableNavigation;
	// Stops it highlighting both buttons when you go from item selection back to the slot list, regardless of input method.
	ListContainer.bCascadeFocus = false;

	// Mr. Nice: Allows navigation to leave the slot list, to get to the new buttons (which as UIButtons, are navigable by default)
	// Only if controller active, ie leave keyboard navigation as is.
	if (`ISCONTROLLERACTIVE && ListContainer.GetChild('IRI_DummyList', false) == none)
	{
		List = Screen.EquippedList;

		// Fiddle with a few flags on the list, it's navigator and container to get the behaviour we want
		List.bLoopSelection = false; 
		List.Navigator.LoopSelection = false;
		List.bPermitNavigatorToDefocus = true;
		List.Navigator.LoopOnReceiveFocus = true;
		ListContainer.Navigator.LoopSelection = true;

		// Mr. Nice: bumping it to the end of the navigation list makes the top/bottom stops for autorepeat intuitive
		// (Even if 'LoopSelection' is set, auto-repeat input still stops at the ends without looping). Also why this section is last, so the buttons are already in the array
		// Sneakily take advantage of the fact that we had to add in an OnRemoved delegate to reverse disabling navigation, so that simply disabling it effectively just bumps it to the end!
		List.DisableNavigation();

		// Just a bit of polish so can get between the two buttons with left/right, not just up/down, given their relative positions on screen
		SaveLoadoutButton.Navigator.AddNavTargetRight(ToggleLoadoutLockButton);
		ToggleLoadoutLockButton.Navigator.AddNavTargetLeft(SaveLoadoutButton);
	}
}

private function EnableNavigation(UIPanel Control)
{
	Control.EnableNavigation();
	//  For no obvious reason, directly setting selected navigation doesn't call OnLoseFocus for the existing selection?
	Control.ParentPanel.Navigator.GetSelected().OnLoseFocus();
	// When UIArmory_Loadout disables navigation for the list, it was by definition the selected navigation. So make it so again...
	Control.SetSelectedNavigation();
}

private function SaveLoadoutButtonClicked(UIButton btn_clicked)
{
	local UIArmory_Loadout			UIArmoryLoadoutScreen;
	local XComGameState_Unit		Unit;
	local UIScreen_Loadouts			SaveLoadout;

	UIArmoryLoadoutScreen = UIArmory_Loadout(btn_clicked.Screen);

	if (UIArmoryLoadoutScreen != none)
	{
		Unit = UIArmoryLoadoutScreen.GetUnit();
		if (Unit != none)
		{
			
			`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
			SaveLoadout = UIArmoryLoadoutScreen.Movie.Pres.Spawn(class'UIScreen_Loadouts', UIArmoryLoadoutScreen.Movie.Pres);
			SaveLoadout.UnitState = Unit;
			SaveLoadout.UIArmoryLoadoutScreen = UIArmoryLoadoutScreen;
			SaveLoadout.bForSaving = true;
			UIArmoryLoadoutScreen.Movie.Pres.ScreenStack.Push(SaveLoadout, UIArmoryLoadoutScreen.Movie.Pres.Get3DMovie());
		}
	}
}
	

private function ToggleLoadoutButtonClicked(UIButton btn_clicked)
{
	local UIArmory_Loadout			UIArmoryLoadoutScreen;
	local XComGameState_Unit		Unit;
	local UIScreen_Loadouts			SaveLoadout;

	UIArmoryLoadoutScreen = UIArmory_Loadout(btn_clicked.Screen);

	if (UIArmoryLoadoutScreen != none)
	{
		Unit = UIArmoryLoadoutScreen.GetUnit();
		if (Unit != none)
		{
			//class'X2LoadoutSafe'.static.EquipLoadut_Static('SomeName', Unit);
			`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
			SaveLoadout = UIArmoryLoadoutScreen.Movie.Pres.Spawn(class'UIScreen_Loadouts', UIArmoryLoadoutScreen.Movie.Pres);
			SaveLoadout.UnitState = Unit;
			SaveLoadout.UIArmoryLoadoutScreen = UIArmoryLoadoutScreen;
			UIArmoryLoadoutScreen.Movie.Pres.ScreenStack.Push(SaveLoadout, UIArmoryLoadoutScreen.Movie.Pres.Get3DMovie());
		}
	}
}

//	================================================================================
//							ARMOURY INPUT HANDLING
//	================================================================================
private function bool OnArmoryLoadoutInput(int cmd, int arg)
{
	local UIArmory_Loadout Screen;
	
	Screen = UIArmory_Loadout(`SCREENSTACK.GetCurrentScreen());

	if (Screen==none) return false; // Shouldn't be possible, since we unsubscribe in OnLoseFocus and OnRemoved!

	if (!Screen.CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return false;
	}

	// Mr. Nice: Just a bit of polish, since we're faffing with input handling anyway
	Screen.EquippedList.Navigator.LoopSelection = !`ISCONTROLLERACTIVE || (arg & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			return Screen.Navigator.OnUnrealCommand(cmd, arg); // Where the selection input should have ended up in the first place, and would have by default if not handled by the Screen!
														// Note how we don't even have to check if one of our buttons is selected, works fine for the lists too...
		default:
			return false;
	}
}
