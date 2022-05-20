class UIScreen_Loadouts extends UIInventory_XComDatabase;

// Used in two capacities. 

// 1. When saving a loadout (bForSaving = true), the list on the left shows previously saved loadouts. At the top of the list is a "create new loadout" element.
// Each previously saved loadout has a "delete" button on it. Clicking on one of the loadouts allows overwriting it.
// The ItemCard on the right shows items currently equipped on the unit, allowing to select which of those items will be saved into the loadout.
// 2. When equipping a previously saved loadout, (bForSaving = false), the list on the left has checkboxes to indiciate which of the loadouts is currently selected.
// The ItemCard on the right shows items in that loadout, allowing to select which of those items should be equipped on the unit.
// The big "equip loadout" green button appears on this screen.

var UIArmory_Loadout		UIArmoryLoadoutScreen;
var bool					bCloseArmoryScreenWhenClosing;
var XComGameState_Unit		UnitState;
var bool					bForSaving;

var config(UI) int LeftListOffset;
var config(UI) int RightListOffset;
var config(UI) int ListItemWidthMod;

var private UILargeButton			EquipLoadoutButton;
var private string					CachedNewLoadoutName;
var private X2ItemTemplateManager	ItemMgr;
var private string					SearchText;
var private int						LoadoutFilterStatus;
var private X2SoldierClassTemplate	SoldierClassTemplate;
var private X2SoldierClassTemplateManager	ClassMgr;

`include(WOTCIridarManualLoadoutManager\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	LoadoutFilterStatus = `GETMCMVAR(LOADOUT_FILTER_STATUS);
	if (LoadoutFilterStatus > eLFS_ButtonHidden)
	{
		SoldierClassTemplate = UnitState.GetSoldierClassTemplate();
	}

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ClassMgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	super(UIInventory).InitScreen(InitController, InitMovie, InitName);

	self.SetX(self.X + LeftListOffset);
	
	UIArmoryLoadoutScreen.Hide();
	UIArmoryLoadoutScreen.NavHelp.Show();	
	
	UIMouseGuard_RotatePawn(MouseGuardInst).SetActorPawn(UIArmoryLoadoutScreen.ActorPawn);

	SetCategory("");
	SetInventoryLayout();

	// Delay is required to have the "Delete" buttons in the right position. Don't ask why.
	Screen.SetTimer(0.25f, false, nameof(PopulateData), self);
}

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;
	
	super.UpdateNavHelp();
	
	//UIArmoryLoadoutScreen.UpdateNavHelp();

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	`AMLOG(LoadoutFilterStatus @ `ShowVar(LoadoutFilterStatus));

	if (LoadoutFilterStatus > eLFS_ButtonHidden)
	{
		`AMLOG("Adding right help:" @ class'WOTCIridarManualLoadoutManager_MCMScreen'.default.LOADOUT_FILTER_STATUS_Strings[LoadoutFilterStatus] @ class'WOTCIridarManualLoadoutManager_MCMScreen'.default.LOADOUT_FILTER_STATUS_Tooltips[LoadoutFilterStatus]);

		NavHelp.AddRightHelp(`GetLocalizedString('FilterButtonTitle') $ ": " $ class'WOTCIridarManualLoadoutManager_MCMScreen'.default.LOADOUT_FILTER_STATUS_Strings[LoadoutFilterStatus],
				class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_RT_R2, 
				OnFilterButtonClicked,
				false,
				class'WOTCIridarManualLoadoutManager_MCMScreen'.default.LOADOUT_FILTER_STATUS_Tooltips[LoadoutFilterStatus],
				class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);
	}

	NavHelp.AddRightHelp(SearchText == "" ? `GetLocalizedString('SearchButtonTitle') : `GetLocalizedString('SearchButtonTitle') $ ": " $ SearchText,			
			class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_RT_R2, 
			OnSearchButtonClicked,
			false,
			`GetLocalizedString('SearchButtonTooltip'),
			class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);

	if (UIArmoryLoadoutScreen.bWeaponsStripped && UIArmoryLoadoutScreen.bGearStripped && UIArmoryLoadoutScreen.bItemsStripped)
	{
		NavHelp.AddRightHelp(`GetLocalizedString('MakeItemsAvailable_Title'), 
			"", 
			none, 
			true,
			`GetLocalizedString('MakeItemsAvailable_Tooltip_Disabled'),
			class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);
	}
	else
	{
		NavHelp.AddRightHelp(`GetLocalizedString('MakeItemsAvailable_Title'),			
			class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_RT_R2, 
			OnMakeItemsAvailableClicked,
			false,
			`GetLocalizedString('MakeItemsAvailable_Tooltip'),
			class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);
	}
}

private function OnMakeItemsAvailableClicked()
{
	if (!UIArmoryLoadoutScreen.bWeaponsStripped)	UIArmoryLoadoutScreen.OnStripWeaponsDialogCallback('eUIAction_Accept');
	if (!UIArmoryLoadoutScreen.bGearStripped)		UIArmoryLoadoutScreen.OnStripGearDialogCallback('eUIAction_Accept');
	if (!UIArmoryLoadoutScreen.bItemsStripped)		UIArmoryLoadoutScreen.OnStripItemsDialogCallback('eUIAction_Accept');

	UpdateNavHelp();
	PopulateData();
}

private function OnFilterButtonClicked()
{
	LoadoutFilterStatus++; 

	if (LoadoutFilterStatus >= eLFS_MAX)
	{
		LoadoutFilterStatus = eLFS_ButtonHidden + 1;
	}
	`AMLOG("New LoadoutFilterStatus:" @ LoadoutFilterStatus);
	UpdateNavHelp();
	PopulateData();
}

private function OnSearchButtonClicked()
{
	local TInputDialogData kData;

	if (SearchText != "")
	{
		SearchText = "";
		PopulateData();
	}
	else
	{
		kData.strTitle = `GetLocalizedString('SearchFieldTitle');
		kData.iMaxChars = 99;
		kData.strInputBoxText = SearchText;
		kData.fnCallback = OnSearchInputBoxAccepted;

		Movie.Pres.UIInputDialog(kData);
	}
}

function OnSearchInputBoxAccepted(string text)
{
	SearchText = text;
	PopulateData();
}


simulated function BuildScreen()
{
	TitleHeader = Spawn(class'UIX2PanelHeader', self);
	if (bForSaving)
	{
		TitleHeader.InitPanelHeader('TitleHeader', `GetLocalizedString('LoadoutListTitleSave'), `GetLocalizedString('LoadoutListSubTitleSave'));
	}
	else
	{
		TitleHeader.InitPanelHeader('TitleHeader', `GetLocalizedString('LoadoutListTitleLoad'), `GetLocalizedString('LoadoutListSubTitleLoad'));
	}
	TitleHeader.SetHeaderWidth( 580 );
	//if( m_strTitle == "" && m_strSubTitleTitle == "" )
	//	TitleHeader.Hide();

	ListContainer = Spawn(class'UIPanel', self).InitPanel('InventoryContainer');

	ItemCard = Spawn(class'UIItemCard_Inventory', ListContainer).InitItemCard('ItemCard');
	ItemCard.SetX(ItemCard.X + RightListOffset);
	UIItemCard_Inventory(ItemCard).UnitState = UnitState;

	ListBG = Spawn(class'UIPanel', ListContainer);
	ListBG.InitPanel('InventoryListBG'); 
	ListBG.bShouldPlayGenericUIAudioEvents = false;
	//ListBG.SetWidth(TitleHeader.headerWidth + 30);
	ListBG.Show();

	List = Spawn(class'UIList', ListContainer);
	List.InitList(InventoryListName);
	List.bSelectFirstAvailable = bSelectFirstAvailable;
	List.bStickyHighlight = true;
	List.OnSelectionChanged = SelectedItemChanged;
	//List.SetWidth(TitleHeader.headerWidth - 60);
	Navigator.SetSelected(ListContainer);
	ListContainer.Navigator.SetSelected(List);

	if (!bForSaving)
	{
		EquipLoadoutButton = Spawn(class'UILargeButton', `HQPRES.m_kAvengerHUD.NavHelp.Screen);
		EquipLoadoutButton.LibID = 'X2ContinueButton';
		EquipLoadoutButton.bHideUntilRealized = true;
		EquipLoadoutButton.InitLargeButton(, `GetLocalizedString('EquipLoadout'));
		EquipLoadoutButton.DisableNavigation();
		EquipLoadoutButton.AnchorBottomCenter();
		EquipLoadoutButton.OffsetY = -10;
		EquipLoadoutButton.OnClickedDelegate = OnEquipLoadoutClicked;
		EquipLoadoutButton.Show();
		EquipLoadoutButton.ShowBG(true);
		//EquipLoadoutButton.SetPosition(10, 10);
	}

	m_strTotalLabel = "";
	SetBuiltLabel(m_strTotalLabel);

	// send mouse scroll events to the list
	ListBG.ProcessMouseEvents(List.OnChildMouseEvent);

	if( bIsIn3D )
		class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, OverrideInterpTime != -1 ? OverrideInterpTime : `HQINTERPTIME);
}

private function OnEquipLoadoutClicked(UIButton Button)
{
	local array<UIMechaListItem_LoadoutItem> LoadoutItems;

	LoadoutItems = UIItemCard_Inventory(ItemCard).GetSelectedListItems();
	if (LoadoutItems.Length == 0)
	{
		ShowInfoPopup(`GetLocalizedString('InvalidLoadoutNameTitle'), `GetLocalizedString('NoItemsInLoadoutText_Equip'), eDialog_Warning);
		return;
	}

	EquipItems(LoadoutItems);
	CloseScreen();
}

simulated function PopulateData()
{
	local UIMechaListItem_LoadoutItem	ListItem;
	local array<IRILoadoutStruct>		Loadouts;
	local IRILoadoutStruct				Loadout;

	List.ClearItems();

	if (bForSaving)
	{
		ListItem = Spawn(class'UIMechaListItem_LoadoutItem', List.itemContainer);
		ListItem.bAnimateOnInit = false;
		ListItem.SetWidth(TitleHeader.headerWidth - 65);
		ListItem.InitListItem()/*.ProcessMouseEvents(List.OnChildMouseEvent)*/;
		ListItem.Loadout = Loadout;
		ListItem.UpdateDataDescription(`GetLocalizedString('CreateNewLoadoutButton'), OnCreateLoadoutClicked);
				
		UIItemCard_Inventory(ItemCard).PopulateLoadoutFromUnit();
	}

	Loadouts = class'X2LoadoutSafe'.static.GetLoadouts();
	foreach Loadouts(Loadout)
	{
		if (!LoadoutPassesFilters(Loadout))
			continue;

		ListItem = Spawn(class'UIMechaListItem_LoadoutItem', List.itemContainer);
		ListItem.bAnimateOnInit = false;
		ListItem.SetWidth(TitleHeader.headerWidth - 65);
		ListItem.InitListItem()/*.ProcessMouseEvents(List.OnChildMouseEvent)*/;
		ListItem.Loadout = Loadout;

		if (bForSaving)
		{
			ListItem.UpdateDataButton(GetLoadoutDisplayName(Loadout), class'UIMPShell_SquadLoadoutList'.default.m_strDeleteSet, OnDeleteLoadoutClicked, OnSaveSelectedLoadoutClicked);
		}
		else
		{
			ListItem.UpdateDataCheckbox(GetLoadoutDisplayName(Loadout), "", false, OnCheckboxChanged, OnLoadSelectedLoadoutClicked);
		}
	}

	if (bForSaving)
	{
		if (List.ItemCount > 0)
		{
			List.SetSelectedIndex(1); // To account for the "create new loadout" 0th list item.
			SelectedItemChanged(List, 1);

			List.RealizeItems();
			List.RealizeList();
		}
	}
	else
	{
		if (List.ItemCount > 0)
		{
			if (List.ItemCount == 1) // Select the first loadout in the list if it's the only one.
			{
				SelectListItem(0);
			}

			List.SetSelectedIndex(0);
			SelectedItemChanged(List, 0);
			EquipLoadoutButton.SetDisabled(false);

			List.RealizeItems();
			List.RealizeList();
		}
		else
		{
			UIItemCard_Inventory(ItemCard).ClearListItems(); // Clear loadout preview from the list on the right.
			EquipLoadoutButton.SetDisabled(true);
		}
	}
}

private function string GetLoadoutDisplayName(const out IRILoadoutStruct Loadout)
{
	local string						DisplayName;
	local X2SoldierClassTemplate		ClassTemplate;
	
	DisplayName = Loadout.LoadoutName;
	
	if (LoadoutFilterStatus == eLFS_Class && Loadout.SoldierClass != '')
	{
		ClassTemplate = ClassMgr.FindSoldierClassTemplate(Loadout.SoldierClass);
		if (ClassTemplate != none)
		{
			DisplayName = ClassTemplate.DisplayName $ ": " $ DisplayName;
		}
	}

	return DisplayName;
}

private function bool LoadoutPassesFilters(const IRILoadoutStruct Loadout)
{
	if (SearchText != "" && InStr(Loadout.LoadoutName, SearchText,, true) == INDEX_NONE)
		return false;

	`AMLOG("Filter status:" @ LoadoutFilterStatus @ Loadout.LoadoutName @ Loadout.SoldierClass);

	switch (LoadoutFilterStatus)
	{
	case eLFS_NoFilter:
		break;
	case eLFS_Class:
		if (Loadout.SoldierClass != UnitState.GetSoldierClassTemplateName())
			return false;
		break;
	case eLFS_Equipment:
		if (!LoadoutPassesClassRestrictionsForSlot(Loadout, eInvSlot_Armor) || 
			!LoadoutPassesClassRestrictionsForSlot(Loadout, eInvSlot_PrimaryWeapon) ||
			!LoadoutPassesClassRestrictionsForSlot(Loadout, eInvSlot_SecondaryWeapon))
		{
			`AMLOG("Doesn't pass primary check:" @ !LoadoutPassesClassRestrictionsForSlot(Loadout, eInvSlot_PrimaryWeapon) @ ", doesn't pass secondary check:" @ !LoadoutPassesClassRestrictionsForSlot(Loadout, eInvSlot_SecondaryWeapon));
			return false;
		}
		break;
	case eLFS_PrimaryWeapon:
		if (!LoadoutPassesClassRestrictionsForSlot(Loadout, eInvSlot_PrimaryWeapon))
			return false;
		break;
	case eLFS_SecondaryWeapon:
		if (!LoadoutPassesClassRestrictionsForSlot(Loadout, eInvSlot_SecondaryWeapon))
			return false;
		break;
	default:
		`AMLOG("WARNING :: Unrecognized filter status:" @ LoadoutFilterStatus);
		break;
	}

	return true;
}

private function bool LoadoutPassesClassRestrictionsForSlot(const IRILoadoutStruct Loadout, const EInventorySlot Slot)
{
	local IRILoadoutItemStruct LoadoutItem;

	foreach Loadout.LoadoutItems(LoadoutItem)
	{
		if (LoadoutItem.Slot == Slot)
		{
			if (!IsItemAllowedByClassInSlot(LoadoutItem.Item, Slot))
			{
				`AMLOG(LoadoutItem.Item @ "is not allowed in slot:" @ Slot @ "by soldier class:" @ SoldierClassTemplate.DataName);
				return false;
			}
		}
	}
	return true;
}

private function bool IsItemAllowedByClassInSlot(const name TemplateName, const EInventorySlot Slot)
{
	local X2ItemTemplate	ItemTemplate;
	local X2ArmorTemplate	ArmorTemplate;
	local X2WeaponTemplate	WeaponTemplate;
	local EInventorySlot	OriginalSlot;
	local bool				bCheckPassed;
	
	ItemTemplate = ItemMgr.FindItemTemplate(TemplateName);
	if (ItemTemplate == none)
		return false;

	WeaponTemplate = X2WeaponTemplate(ItemTemplate);
	ArmorTemplate = X2ArmorTemplate(ItemTemplate);
	if	(WeaponTemplate != none)
	{
		OriginalSlot = WeaponTemplate.InventorySlot;
		WeaponTemplate.InventorySlot = Slot; // HAAAAX: Temporarily replace inventory slot in the template so that IsWeaponAllowedByClass can support PS / TPS
		bCheckPassed = SoldierClassTemplate.IsWeaponAllowedByClass(WeaponTemplate); // TODO: Replace by IsWeaponAllowedByClass_CH
		WeaponTemplate.InventorySlot = OriginalSlot;
	}
	else if (ArmorTemplate != none)
	{
		bCheckPassed = SoldierClassTemplate.IsArmorAllowedByClass(ArmorTemplate);
	}
	else return true; // Not a weapon, not an armor, presumably not affected by soldier class restrictions

	return bCheckPassed;
}

// Clicking on the list item or the checkbox toggles the checkbox and unchecks checkboxes on all other items.
private function OnLoadSelectedLoadoutClicked()
{
	local UIMechaListItem_LoadoutItem ClickedItem;

	ClickedItem = UIMechaListItem_LoadoutItem(List.GetSelectedItem());

	if (ClickedItem != none && ClickedItem.Checkbox != none)
	{
		ClickedItem.Checkbox.SetChecked(!ClickedItem.Checkbox.bChecked, true);
		UIItemCard_Inventory(ItemCard).PopulateLoadoutFromStruct(ClickedItem.Loadout);
	}	
}
private function OnCheckboxChanged(UICheckbox CheckboxControl)
{
	local UIMechaListItem_LoadoutItem ListItem;
	local int i;

	for (i = 0; i < List.ItemCount; i++)
	{
		ListItem = UIMechaListItem_LoadoutItem(List.GetItem(i));
		if (ListItem == none || ListItem.Checkbox == none)
			continue;

		if (ListItem.Checkbox != CheckboxControl)
		{	
			ListItem.Checkbox.SetChecked(false, false);
		}
	}
}

private function OnDeleteLoadoutClicked(UIButton ButtonSource)
{
	local UIMechaListItem_LoadoutItem	SelectedLoadout;
	local TDialogueBoxData				kDialogData;

	SelectedLoadout = UIMechaListItem_LoadoutItem(ButtonSource.GetParent(class'UIMechaListItem_LoadoutItem'));
	CachedNewLoadoutName = SelectedLoadout.Loadout.LoadoutName;

	kDialogData.strTitle = `GetLocalizedString('ConfirmDeleteLoadoutTitle');
	kDialogData.eType = eDialog_Warning;
	kDialogData.strText = Repl(`GetLocalizedString('ConfirmDeleteLoadoutText'), "%LoadoutName%", CachedNewLoadoutName);
	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;
	kDialogData.fnCallback = OnDeleteLoadoutClickedCallback;
	Movie.Pres.UIRaiseDialog(kDialogData);
}

private function OnDeleteLoadoutClickedCallback(Name eAction)
{
	if (eAction == 'eUIAction_Accept')
	{
		class'X2LoadoutSafe'.static.DeleteLoadut_Static(CachedNewLoadoutName);
		PopulateData();
	}
}

private function OnSaveSelectedLoadoutClicked()
{
	local UIMechaListItem_LoadoutItem	SelectedLoadout;
	local array<XComGameState_Item>		ItemStates;
	local TDialogueBoxData				kDialogData;

	ItemStates = UIItemCard_Inventory(ItemCard).GetSelectedItemStates();
	if (ItemStates.Length == 0)
	{
		ShowInfoPopup(`GetLocalizedString('InvalidLoadoutTitle'), `GetLocalizedString('NoItemsInLoadoutText'), eDialog_Warning);
		return;
	}

	SelectedLoadout = UIMechaListItem_LoadoutItem(List.GetSelectedItem());
	CachedNewLoadoutName = SelectedLoadout.Loadout.LoadoutName;

	kDialogData.strTitle = `GetLocalizedString('ConfirmOverwriteLoadoutTitle');
	kDialogData.eType = eDialog_Warning;
	kDialogData.strText = Repl(`GetLocalizedString('ConfirmOverwriteLoadoutText'), "%LoadoutName%", CachedNewLoadoutName);
	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;
	kDialogData.fnCallback = OnOverwriteLoadoutClickedCallback;
	Movie.Pres.UIRaiseDialog(kDialogData);
}

private function OnOverwriteLoadoutClickedCallback(Name eAction)
{
	local array<XComGameState_Item> ItemStates;

	if (eAction == 'eUIAction_Accept')
	{
		ItemStates = UIItemCard_Inventory(ItemCard).GetSelectedItemStates();
		class'X2LoadoutSafe'.static.SaveLoadut_Static(CachedNewLoadoutName, ItemStates, UnitState);
		CloseScreen();
	}
}

private function OnCreateLoadoutClicked()
{
	local array<XComGameState_Item>	ItemStates;
	local TInputDialogData			kData;

	ItemStates = UIItemCard_Inventory(ItemCard).GetSelectedItemStates();
	if (ItemStates.Length == 0)
	{
		ShowInfoPopup(`GetLocalizedString('InvalidLoadoutTitle'), `GetLocalizedString('NoItemsInLoadoutText'), eDialog_Warning);
		return;
	}

	kData.strTitle = `CAPS(`GetLocalizedString('EnterLoadoutName'));
	kData.iMaxChars = 99;
	kData.strInputBoxText = `GetLocalizedString('PlaceholderLoadoutName');
	kData.fnCallback = OnCreateLoadoutInputBoxAccepted;

	Movie.Pres.UIInputDialog(kData);
}

simulated function CloseScreen()
{	
	if (UIArmoryLoadoutScreen != none)
	{
		if (bCloseArmoryScreenWhenClosing)
		{
			UIArmoryLoadoutScreen.CloseScreen();
		}
		else
		{
			UIArmoryLoadoutScreen.UpdateData(true);
			UIArmoryLoadoutScreen.Show();
			UIMouseGuard_RotatePawn(UIArmoryLoadoutScreen.MouseGuardInst).SetActorPawn(UIArmoryLoadoutScreen.ActorPawn);
		}
	}
	super.CloseScreen();
}

simulated function OnRemoved()
{
	if (EquipLoadoutButton != none) EquipLoadoutButton.Remove();
}
simulated function Show()
{
	super.Show();
	if (EquipLoadoutButton != none) EquipLoadoutButton.Show();
}

simulated function Hide()
{
	super.Hide();
	if (EquipLoadoutButton != none) EquipLoadoutButton.Hide();
}

private function OnCreateLoadoutInputBoxAccepted(string LoadoutName)
{
	local TDialogueBoxData			kDialogData;
	local array<string>				LoadoutNames;
	local array<XComGameState_Item> ItemStates;

	if (LoadoutName == "")
	{
		// No empty preset names
		ShowInfoPopup(`GetLocalizedString('InvalidLoadoutNameTitle'), `GetLocalizedString('InvalidLoadoutNameText'), eDialog_Warning);
		return;
	}

	LoadoutNames = class'X2LoadoutSafe'.static.GetLoadoutNames();
	if (LoadoutNames.Find(LoadoutName) != INDEX_NONE)
	{
		CachedNewLoadoutName = LoadoutName;

		kDialogData.strTitle = `GetLocalizedString('LoadoutAlreadyExistsTitle');
		kDialogData.eType = eDialog_Warning;
		kDialogData.strText = `GetLocalizedString('LoadoutAlreadyExistsText');
		kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
		kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;
		kDialogData.fnCallback = OnCreateLoadoutClickedCallback;
		Movie.Pres.UIRaiseDialog(kDialogData);
	}
	else
	{
		ItemStates = UIItemCard_Inventory(ItemCard).GetSelectedItemStates();
		class'X2LoadoutSafe'.static.SaveLoadut_Static(LoadoutName, ItemStates, UnitState);
		CloseScreen();
	}
}

private function OnCreateLoadoutClickedCallback(Name eAction)
{
	local array<XComGameState_Item> ItemStates;

	if (eAction == 'eUIAction_Accept')
	{
		ItemStates = UIItemCard_Inventory(ItemCard).GetSelectedItemStates();
		class'X2LoadoutSafe'.static.SaveLoadut_Static(CachedNewLoadoutName, ItemStates, UnitState);
		CloseScreen();
	}
}

private function ShowInfoPopup(string strTitle, string strText, optional EUIDialogBoxDisplay eType)
{
	local TDialogueBoxData kDialogData;

	kDialogData.strTitle = strTitle;
	kDialogData.strText = strText;
	kDialogData.eType = eType;
	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericOK;

	Movie.Pres.UIRaiseDialog(kDialogData);
}

simulated function SelectedItemChanged(UIList ContainerList, int ItemIndex)
{
	local UIMechaListItem_LoadoutItem ListItem;

	ListItem = UIMechaListItem_LoadoutItem(ContainerList.GetItem(ItemIndex));
	if (ListItem == none)
		return;

	// Update loadout contents on the right only if no checkbox is checked in the list on the left.
	if (!bForSaving && !IsAnyLoadoutSelected())
	{
		UIItemCard_Inventory(ItemCard).PopulateLoadoutFromStruct(ListItem.Loadout);
	}
}

private function bool IsAnyLoadoutSelected()
{
	local UIMechaListItem_LoadoutItem ListItem;
	local int i;

	for (i = 0; i < List.ItemCount; i++)
	{
		ListItem = UIMechaListItem_LoadoutItem(List.GetItem(i));
		if (ListItem != none && ListItem.Checkbox.bChecked)
		{ 
			return true;
		}
	}
	return false;
}

private function SelectListItem(const int ItemIndex)
{
	local UIMechaListItem_LoadoutItem ListItem;
	local int i;

	List.SetSelectedIndex(ItemIndex);

	for (i = 0; i < List.ItemCount; i++)
	{
		ListItem = UIMechaListItem_LoadoutItem(List.GetItem(i));
		if (ListItem != none)
		{
			if (i == ItemIndex)
			{
				ListItem.Checkbox.SetChecked(!ListItem.Checkbox.bChecked, false);
				if (ListItem.Checkbox.bChecked)
				{
					UIItemCard_Inventory(ItemCard).PopulateLoadoutFromStruct(ListItem.Loadout);
				}
			}
			else
			{
				ListItem.Checkbox.SetChecked(false, false);
			}
		}
	}
}

private function EquipItems(array<UIMechaListItem_LoadoutItem> LoadoutItems)
{
	local UIMechaListItem_LoadoutItem		LoadoutListItem;
	local IRILoadoutItemStruct				LoadoutItem;
	local XComGameState						NewGameState;
	local bool								bChangedSomething;
	local XComGameState_Item				ItemState;
	local X2ItemTemplate					ItemTemplate;
	local XComGameState_Item				EquippedItem;
	local array<XComGameState_Item>			EquippedItems;
	local bool								bSoundPlayed;
	local array<int>						SlotMap;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Loading Loadout For Unit" @ UnitState.GetFullName());
	XComHQ = class'Help'.static.GetAndPrepXComHQ(NewGameState);
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
	SlotMap.Add(eInvSlot_MAX);

	`AMLOG("==== BEGIN ====");
	`AMLOG("Loadout Items:" @ LoadoutItems.Length @ "and unit:" @ UnitState.GetFullName() @ UnitState.GetSoldierClassTemplateName());

	foreach LoadoutItems(LoadoutListItem)
	{
		LoadoutItem = LoadoutListItem.LoadoutItem;
		ItemState = LoadoutListItem.ItemState;
		XComHQ.GetItemFromInventory(NewGameState, ItemState.GetReference(), ItemState);

		`AMLOG("Loadout Item:" @ ItemState.GetMyTemplateName() @ LoadoutItem.Slot);
		if (ItemState == none)
			continue;

		`AMLOG("Found item state to equip.");

		ItemTemplate = ItemState.GetMyTemplate();
		
		if (!UnitState.CanAddItemToInventory(ItemTemplate, LoadoutItem.Slot, NewGameState, ItemState.Quantity, ItemState))
		{
			`AMLOG("Can't equip the item. Assuming this is because slot is occupied.");

			// For multi-item slots, 
			if (class'CHItemSlot'.static.SlotIsMultiItem(LoadoutItem.Slot))
			{
				// if there are any items in the slot,
				EquippedItems = UnitState.GetAllItemsInSlot(LoadoutItem.Slot, NewGameState,, true);
				`AMLOG("This is a multi item slot, this many items in it:" @ EquippedItems.Length);
				if (EquippedItems.Length > 0)
				{
					if (class'Help'.static.IsItemUniqueEquipInSlot(ItemMgr, ItemTemplate, LoadoutItem.Slot))
					{
						foreach EquippedItems(EquippedItem)
						{	
							// Check if the item we want to equip is mutually exclusive with any other item in that slot
							// I.e. it matches item category or weapon category
							if (class'Help'.static.AreItemTemplatesMutuallyExclusive(ItemTemplate, EquippedItem.GetMyTemplate()))
							{
								// Stop cycling when we find a match, at which point the mutually exclusive item should be in EquippedItem.
								// Or at least it will hold the last item in the slot.
								`AMLOG("Item we want to equip is mutually exclusive with:" @ EquippedItem.GetMyTemplateName());
								break;
							}
						}
					}

					// If we haven't found an item we're mutually exclusive with, then simply use the first item in slot we haven't equipped here.
					if (EquippedItem == none)
					{
						EquippedItem = EquippedItems[SlotMap[LoadoutItem.Slot]];
					}
				}
			}
			else // For regular slots, just take the item that is equipped in the slot. We'll attempt to remove it below.
			{
				EquippedItem = UnitState.GetItemInSlot(LoadoutItem.Slot, NewGameState);
			}
		}

		// If we found an item to replace with the restored equipment, it will be stored in ItemState, and we need to put it back into the inventory
		if (EquippedItem != none)
		{
			`AMLOG("Slot is occupied by:" @ EquippedItem.GetMyTemplateName());
			EquippedItem = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', EquippedItem.ObjectID));
					
			// Try to remove the item we want to replace from our inventory
			if (!UnitState.RemoveItemFromInventory(EquippedItem, NewGameState))
			{
				// Removing the item failed, so add the item we wanted to equip back to the HQ inventory
				`AMLOG("Failed to remove the item occupying the slot. Skipping to next loadout item.");
				XComHQ.PutItemInInventory(NewGameState, ItemState);
				continue; // Go to next loadout item
			}
		}

		// If we still can't add the restored item to our inventory, put it back into the HQ inventory where we found it and move on
		if (!UnitState.CanAddItemToInventory(ItemTemplate, LoadoutItem.Slot, NewGameState, ItemState.Quantity, ItemState))
		{
			`AMLOG("Still can't equip the item. Putting it back into HQ inventory.");
			XComHQ.PutItemInInventory(NewGameState, ItemState);

			if (EquippedItem != none)
			{
				`AMLOG("Slot was previously occupied by:" @ EquippedItem.GetMyTemplateName() @ "attempting to equip it back.");
				if (UnitState.AddItemToInventory(EquippedItem, LoadoutItem.Slot, NewGameState))
				{
					`AMLOG("Successfully equipped old item.");
				}
				else
				{
					`AMLOG("ERROR, failed to equip the old item. Putting it into HQ inventory.");
					XComHQ.PutItemInInventory(NewGameState, EquippedItem);
				}
			}
			
			`AMLOG("Skipping to next loadout item.");
			continue;
		}

		// Add the restored item to our inventory
		if (UnitState.AddItemToInventory(ItemState, LoadoutItem.Slot, NewGameState, true))
		{
			SlotMap[LoadoutItem.Slot]++;

			`AMLOG("Successfully equipped loadout item.");
			if (!bSoundPlayed && X2EquipmentTemplate(ItemTemplate).EquipSound != "")
			{
				`XSTRATEGYSOUNDMGR.PlaySoundEvent(X2EquipmentTemplate(ItemTemplate).EquipSound);
				bSoundPlayed = true;
			}

			if (X2WeaponTemplate(ItemTemplate) != none)
			{
				if (LoadoutItem.Slot == eInvSlot_PrimaryWeapon)
					ItemState.ItemLocation = eSlot_RightHand;
				else
					ItemState.ItemLocation = X2WeaponTemplate(ItemTemplate).StowedLocation;
			}

			if (EquippedItem != none)
			{	
				`AMLOG("Slot was previously occupied by:" @ EquippedItem.GetMyTemplateName() @ "Putting it into HQ inventory.");
				XComHQ.PutItemInInventory(NewGameState, EquippedItem);
				EquippedItem = none;
			}
			bChangedSomething = true;

			// Validate loadout after every equipped item, because it can change status of slots on the soldier.
			UnitState.ValidateLoadout(NewGameState);
		}		
		else
		{
			`AMLOG("Failed to equip the loadout item! Putting it back to HQ inventory.");
			XComHQ.PutItemInInventory(NewGameState, ItemState);

			`AMLOG("Attempting to equip previously equipped item.");
			if (UnitState.AddItemToInventory(EquippedItem, LoadoutItem.Slot, NewGameState))
			{
				`AMLOG("Successfully equipped old item.");
			}
			else
			{
				`AMLOG("ERROR, failed to equip the old item. Putting it into HQ inventory.");
				XComHQ.PutItemInInventory(NewGameState, EquippedItem);
			}
		}
	}

	if (bChangedSomething)
	{
		`GAMERULES.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	`AMLOG("==== END ====");
}

defaultproperties
{
	bIsIn3D = true
	DisplayTag = "UIBlueprint_Promotion"
	CameraTag = "UIBlueprint_Promotion"
	MouseGuardClass = class'UIMouseGuard_RotatePawn';
}