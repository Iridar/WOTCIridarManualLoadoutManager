//-----------------------------------------------------------
//	Class:	WOTCIridarManualLoadoutManager_MCMScreen
//	Author: Iridar
//	
//-----------------------------------------------------------


class WOTCIridarManualLoadoutManager_MCMScreen extends Object config(WOTCIridarManualLoadoutManager);

var config int VERSION_CFG;

var localized string ModName;
var localized string PageTitle;
var localized string GroupHeader;

`include(WOTCIridarManualLoadoutManager\Src\ModConfigMenuAPI\MCM_API_Includes.uci)

`MCM_API_AutoCheckBoxVars(DEBUG_LOGGING);

`include(WOTCIridarManualLoadoutManager\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

`MCM_API_AutoCheckBoxFns(DEBUG_LOGGING, 1);

event OnInit(UIScreen Screen)
{
	`MCM_API_Register(Screen, ClientModCallback);
}

//Simple one group framework code
simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
	local MCM_API_SettingsPage Page;
	local MCM_API_SettingsGroup Group;

	LoadSavedSettings();
	Page = ConfigAPI.NewSettingsPage(ModName);
	Page.SetPageTitle(PageTitle);
	Page.SetSaveHandler(SaveButtonClicked);
	Page.EnableResetButton(ResetButtonClicked);

	Group = Page.AddGroup('Group', GroupHeader);

	`MCM_API_AutoAddCheckBox(Group, DEBUG_LOGGING);


	Group.AddLabel('Label_End', "Created by Iridar | www.patreon.com/Iridar", "Thank you for using my mods, I hope you enjoy! Please consider supporting me at Patreon so I can afford the time to make more awesome mods <3");
	Page.ShowSettings();
}

simulated function LoadSavedSettings()
{
	DEBUG_LOGGING = `GETMCMVAR(DEBUG_LOGGING);
}

simulated function ResetButtonClicked(MCM_API_SettingsPage Page)
{
	`MCM_API_AutoReset(DEBUG_LOGGING);
}


simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	VERSION_CFG = `MCM_CH_GetCompositeVersion();
	SaveConfig();
}


