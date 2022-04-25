class WOTCIridarManualLoadoutManager_MCMScreen extends Object config(WOTCIridarManualLoadoutManager);

var config int VERSION_CFG;

var localized string ModName;
var localized string PageTitle;
var localized string GroupHeader;

`include(WOTCIridarManualLoadoutManager\Src\ModConfigMenuAPI\MCM_API_Includes.uci)

`MCM_API_AutoCheckBoxVars(DEBUG_LOGGING);
`MCM_API_AutoCheckBoxVars(ALLOW_MODIFIED_ITEMS);
`MCM_API_AutoCheckBoxVars(USE_SIMPLE_HEADERS);
`MCM_API_AutoCheckBoxVars(ALLOW_REPLACEMENT_ITEMS);

`include(WOTCIridarManualLoadoutManager\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

`MCM_API_AutoCheckBoxFns(DEBUG_LOGGING, 1);
`MCM_API_AutoCheckBoxFns(ALLOW_MODIFIED_ITEMS, 1);
`MCM_API_AutoCheckBoxFns(USE_SIMPLE_HEADERS, 1);
`MCM_API_AutoCheckBoxFns(ALLOW_REPLACEMENT_ITEMS, 1);

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


	`MCM_API_AutoAddCheckBox(Group, USE_SIMPLE_HEADERS);
	`MCM_API_AutoAddCheckBox(Group, ALLOW_MODIFIED_ITEMS);
	`MCM_API_AutoAddCheckBox(Group, ALLOW_REPLACEMENT_ITEMS);
	`MCM_API_AutoAddCheckBox(Group, DEBUG_LOGGING);


	Group.AddLabel('Label_End', "Created by Iridar | www.patreon.com/Iridar", "Thank you for using my mods, I hope you enjoy! Please consider supporting me at Patreon so I can afford the time to make more awesome mods <3");
	Page.ShowSettings();
}

simulated function LoadSavedSettings()
{
	USE_SIMPLE_HEADERS = `GETMCMVAR(USE_SIMPLE_HEADERS);
	ALLOW_MODIFIED_ITEMS = `GETMCMVAR(ALLOW_MODIFIED_ITEMS);
	ALLOW_REPLACEMENT_ITEMS = `GETMCMVAR(ALLOW_REPLACEMENT_ITEMS);
	DEBUG_LOGGING = `GETMCMVAR(DEBUG_LOGGING);
}

simulated function ResetButtonClicked(MCM_API_SettingsPage Page)
{
	`MCM_API_AutoReset(USE_SIMPLE_HEADERS);
	`MCM_API_AutoReset(ALLOW_MODIFIED_ITEMS);
	`MCM_API_AutoReset(ALLOW_REPLACEMENT_ITEMS);
	`MCM_API_AutoReset(DEBUG_LOGGING);
}

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	VERSION_CFG = `MCM_CH_GetCompositeVersion();
	SaveConfig();
}


