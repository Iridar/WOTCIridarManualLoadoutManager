//-----------------------------------------------------------
//	Class:	WOTCIridarManualLoadoutManager_MCMScreenListener
//	Author: Iridar
//	
//-----------------------------------------------------------

class WOTCIridarManualLoadoutManager_MCMScreenListener extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local WOTCIridarManualLoadoutManager_MCMScreen MCMScreen;

	if (ScreenClass==none)
	{
		if (MCM_API(Screen) != none)
			ScreenClass=Screen.Class;
		else return;
	}

	MCMScreen = new class'WOTCIridarManualLoadoutManager_MCMScreen';
	MCMScreen.OnInit(Screen);
}

defaultproperties
{
    ScreenClass = none;
}
