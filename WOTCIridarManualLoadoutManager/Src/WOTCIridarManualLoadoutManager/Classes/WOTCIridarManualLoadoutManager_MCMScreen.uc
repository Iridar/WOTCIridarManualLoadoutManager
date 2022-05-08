class WOTCIridarManualLoadoutManager_MCMScreen extends Object config(WOTCIridarManualLoadoutManager);

var config int VERSION_CFG;

var localized string ModName;
var localized string PageTitle;
var localized string GroupHeader;
var localized string Group2Header;
var localized string Group3Header;

var localized array<string> LOADOUT_FILTER_STATUS_Tooltips;

`include(WOTCIridarManualLoadoutManager\Src\ModConfigMenuAPI\MCM_API_Includes.uci)

`MCM_API_AutoCheckBoxVars(DEBUG_LOGGING);
`MCM_API_AutoCheckBoxVars(ALLOW_MODIFIED_ITEMS);
`MCM_API_AutoCheckBoxVars(SHOW_HEADERS);
`MCM_API_AutoCheckBoxVars(USE_SIMPLE_HEADERS);
`MCM_API_AutoCheckBoxVars(DISPLAY_SQUAD_ITEMS_BUTTON);
`MCM_API_AutoCheckBoxVars(ALLOW_REPLACEMENT_ITEMS);
`MCM_API_AutoIndexDropdownVars(LOADOUT_FILTER_STATUS);
`MCM_API_AutoCheckBoxVars(DISPLAY_SQUAD_SELECT_SHORTCUT);
`MCM_API_AutoSliderVars(MAX_LOADOUT_LIST_ITEMS);

`include(WOTCIridarManualLoadoutManager\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

`MCM_API_AutoCheckBoxFns(DEBUG_LOGGING, 1);
`MCM_API_AutoCheckBoxFns(ALLOW_MODIFIED_ITEMS, 1);
`MCM_API_AutoCheckBoxFns(SHOW_HEADERS, 1);
`MCM_API_AutoCheckBoxFns(USE_SIMPLE_HEADERS, 1);
`MCM_API_AutoCheckBoxFns(DISPLAY_SQUAD_ITEMS_BUTTON, 1);
`MCM_API_AutoCheckBoxFns(ALLOW_REPLACEMENT_ITEMS, 1);
`MCM_API_AutoCheckBoxFns(DISPLAY_SQUAD_SELECT_SHORTCUT, 1);
`MCM_API_AutoIndexDropdownFns(LOADOUT_FILTER_STATUS, 1)
`MCM_API_AutoSliderFns(MAX_LOADOUT_LIST_ITEMS,, 1)


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

	`MCM_API_AutoAddCheckBox(Group, SHOW_HEADERS, SHOW_HEADERS_ChangeHandler);
	`MCM_API_AutoAddCheckBox(Group, USE_SIMPLE_HEADERS);
	`MCM_API_AutoAddCheckBox(Group, ALLOW_MODIFIED_ITEMS);
	`MCM_API_AutoAddCheckBox(Group, ALLOW_REPLACEMENT_ITEMS);
	`MCM_API_AutoAddIndexDropdown(Group, LOADOUT_FILTER_STATUS);
	

	Group = Page.AddGroup('Group2', Group2Header);

	`MCM_API_AutoAddCheckBox(Group, DISPLAY_SQUAD_ITEMS_BUTTON, DISPLAY_SQUAD_ITEMS_BUTTON_ChangeHandler);
	`MCM_API_AutoAddSLider(Group, MAX_LOADOUT_LIST_ITEMS, 1, 99, 1);
	`MCM_API_AutoAddCheckBox(Group, DISPLAY_SQUAD_SELECT_SHORTCUT);

	Group = Page.AddGroup('Group3', Group3Header);

	`MCM_API_AutoAddCheckBox(Group, DEBUG_LOGGING);
	Group.AddLabel('Label_End', "Created by Iridar | www.patreon.com/Iridar", "Thank you for using my mods, I hope you enjoy! Please consider supporting me at Patreon so I can afford the time to make more awesome mods <3");

	Page.ShowSettings();
}

private function SHOW_HEADERS_ChangeHandler(MCM_API_Setting Setting, bool SettingValue)
{
	SHOW_HEADERS = SettingValue;
	Setting.GetParentGroup().GetSettingByName('USE_SIMPLE_HEADERS').SetEditable(SHOW_HEADERS);
}

private function DISPLAY_SQUAD_ITEMS_BUTTON_ChangeHandler(MCM_API_Setting Setting, bool SettingValue)
{
	DISPLAY_SQUAD_ITEMS_BUTTON = SettingValue;
	Setting.GetParentGroup().GetSettingByName('MAX_LOADOUT_LIST_ITEMS').SetEditable(DISPLAY_SQUAD_ITEMS_BUTTON);
}

simulated function LoadSavedSettings()
{
	SHOW_HEADERS = `GETMCMVAR(SHOW_HEADERS);
	USE_SIMPLE_HEADERS = `GETMCMVAR(USE_SIMPLE_HEADERS);
	DISPLAY_SQUAD_ITEMS_BUTTON = `GETMCMVAR(DISPLAY_SQUAD_ITEMS_BUTTON);
	ALLOW_MODIFIED_ITEMS = `GETMCMVAR(ALLOW_MODIFIED_ITEMS);
	ALLOW_REPLACEMENT_ITEMS = `GETMCMVAR(ALLOW_REPLACEMENT_ITEMS);
	DEBUG_LOGGING = `GETMCMVAR(DEBUG_LOGGING);
	DISPLAY_SQUAD_SELECT_SHORTCUT = `GETMCMVAR(DISPLAY_SQUAD_SELECT_SHORTCUT);
	LOADOUT_FILTER_STATUS = `GETMCMVAR(LOADOUT_FILTER_STATUS);
	MAX_LOADOUT_LIST_ITEMS = `GETMCMVAR(MAX_LOADOUT_LIST_ITEMS);
}

simulated function ResetButtonClicked(MCM_API_SettingsPage Page)
{
	`MCM_API_AutoReset(DISPLAY_SQUAD_ITEMS_BUTTON);
	`MCM_API_AutoReset(SHOW_HEADERS);
	`MCM_API_AutoReset(USE_SIMPLE_HEADERS);
	`MCM_API_AutoReset(ALLOW_MODIFIED_ITEMS);
	`MCM_API_AutoReset(ALLOW_REPLACEMENT_ITEMS);
	`MCM_API_AutoReset(DEBUG_LOGGING);
	`MCM_API_AutoReset(DISPLAY_SQUAD_SELECT_SHORTCUT);
	`MCM_API_AutoReset(MAX_LOADOUT_LIST_ITEMS);
	`MCM_API_AutoIndexReset(LOADOUT_FILTER_STATUS);
}

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	VERSION_CFG = `MCM_CH_GetCompositeVersion();
	SaveConfig();
}


