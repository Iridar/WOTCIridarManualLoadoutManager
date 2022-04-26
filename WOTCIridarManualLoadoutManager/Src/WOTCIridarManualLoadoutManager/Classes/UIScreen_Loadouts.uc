class UIScreen_Loadouts extends UIInventory_XComDatabase;

// Used in two capacities. 

// 1. When saving a loadout (bForSaving = true), the list on the left shows previously saved loadouts. At the top of the list is a "create new loadout" element.
// Each previously saved loadout has a "delete" button on it. Clicking on one of the loadouts allows overwriting it.
// The ItemCard on the right shows items currently equipped on the unit, allowing to select which of those items will be saved into the loadout.
// 2. When equipping a previously saved loadout, (bForSaving = false), the list on the left has checkboxes to indiciate which of the loadouts is currently selected.
// The ItemCard on the right shows items in that loadout, allowing to select which of those items should be equipped on the unit.
// The big "equip loadout" green button appears on this screen.

var UIArmory_Loadout	UIArmoryLoadoutScreen;
var bool				bCloseArmoryScreenWhenClosing;
var XComGameState_Unit	UnitState;
var bool				bForSaving;

var config(UI) int LeftListOffset;
var config(UI) int RightListOffset;
var config(UI) int ListItemWidthMod;

var private UILargeButton	EquipLoadoutButton;
var private string			CachedNewLoadoutName;
var private X2ItemTemplateManager	ItemMgr;
var private string			SearchText;

`include(WOTCIridarManualLoadoutManager\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super(UIInventory).InitScreen(InitController, InitMovie, InitName);

	self.SetX(self.X + LeftListOffset);
	
	SetCategory("");
	
	SetInventoryLayout();
	PopulateData();

	UIArmoryLoadoutScreen.Hide();
	UIArmoryLoadoutScreen.NavHelp.Show();

	UIMouseGuard_RotatePawn(MouseGuardInst).SetActorPawn(UIArmoryLoadoutScreen.ActorPawn);
}

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;
	
	super.UpdateNavHelp();

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
	
	NavHelp.AddRightHelp(SearchText == "" ? `GetLocalizedString('SearchButtonTitle') : `GetLocalizedString('SearchButtonTitle') $ ": " $ SearchText,			
				class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_RT_R2, 
				OnSearchButtonClicked,
				false,
				`GetLocalizedString('SearchButtonTooltip'),
				class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);
}

simulated private function OnSearchButtonClicked()
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
	ListBG.Show();

	List = Spawn(class'UIList', ListContainer);
	List.InitList(InventoryListName);
	List.bSelectFirstAvailable = bSelectFirstAvailable;
	List.bStickyHighlight = true;
	List.OnSelectionChanged = SelectedItemChanged;
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
	local array<IRILoadoutItemStruct> LoadoutItems;

	LoadoutItems = UIItemCard_Inventory(ItemCard).GetSelectedLoadoutItems();
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
	local UIMechaListItem_LoadoutItem	SpawnedItem;
	local array<IRILoadoutStruct>		Loadouts;
	local IRILoadoutStruct				Loadout;

	List.ClearItems();

	if (bForSaving)
	{
		SpawnedItem = Spawn(class'UIMechaListItem_LoadoutItem', List.itemContainer);
		SpawnedItem.bAnimateOnInit = false;
		SpawnedItem.InitListItem().ProcessMouseEvents(List.OnChildMouseEvent);
		SpawnedItem.Loadout = Loadout;
		SpawnedItem.ListItemWidthMod = ListItemWidthMod;
		SpawnedItem.UpdateDataDescription(`GetLocalizedString('CreateNewLoadoutButton'), OnCreateLoadoutClicked);
		
		UIItemCard_Inventory(ItemCard).PopulateLoadoutFromUnit();
	}

	Loadouts = class'X2LoadoutSafe'.static.GetLoadouts();
	foreach Loadouts(Loadout)
	{
		if (SearchText != "" && InStr(Loadout.LoadoutName, SearchText,, true) == INDEX_NONE)
			continue;

		SpawnedItem = Spawn(class'UIMechaListItem_LoadoutItem', List.itemContainer);
		SpawnedItem.bAnimateOnInit = false;
		SpawnedItem.InitListItem().ProcessMouseEvents(List.OnChildMouseEvent);
		SpawnedItem.Loadout = Loadout;
		SpawnedItem.ListItemWidthMod = ListItemWidthMod;

		if (bForSaving)
		{
			SpawnedItem.UpdateDataButton(Loadout.LoadoutName, class'UIMPShell_SquadLoadoutList'.default.m_strDeleteSet, OnDeleteLoadoutClicked, OnSaveSelectedLoadoutClicked);
			
		}
		else
		{
			SpawnedItem.UpdateDataCheckbox(Loadout.LoadoutName, "", false, none, OnLoadSelectedLoadoutClicked);
			SpawnedItem.Checkbox.OnMouseEventDelegate = CheckboxMouseEvent;
		}
	}

	if (List.ItemCount > 0)
	{
		List.SetSelectedIndex(1);
		
		if (bForSaving) 
		{	
			SelectedItemChanged(List, 1);
		}
		else
		{
			SelectedItemChanged(List, 0);
			SelectListItem(0);
		}
		List.Navigator.SelectFirstAvailable();

		List.RealizeItems();
		List.RealizeList();
	}
}

private function CheckboxMouseEvent(UIPanel Panel, int Cmd)
{
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
		//OnMouseEventDelegate(self, cmd);
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
		//OnMouseEventDelegate(self, cmd);
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:
		SelectListItem(List.GetItemIndex(Panel.GetParent(class'UIMechaListItem_LoadoutItem')));
		break;
	}
}

private function OnLoadSelectedLoadoutClicked()
{
	SelectListItem(List.GetItemIndex(List.GetSelectedItem()));
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
	if (bForSaving)
	{
	}
	else
	{
	}
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
				ListItem.Checkbox.SetChecked(true, false);
				UIItemCard_Inventory(ItemCard).PopulateLoadoutFromStruct(ListItem.Loadout);
			}
			else
			{
				ListItem.Checkbox.SetChecked(false, false);
			}
		}
	}
}

private function EquipItems(array<IRILoadoutItemStruct> LoadoutItems)
{
	local IRILoadoutItemStruct				LoadoutItem;
	local XComGameState						NewGameState;
	local bool								bChangedSomething;
	local XComGameState_Item				ItemState;
	local X2ItemTemplate					ItemTemplate;
	local XComGameState_Item				EquippedItem;
	local array<XComGameState_Item>			EquippedItems;
	local bool								bSoundPlayed;

	History = `XCOMHISTORY;
	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Loading Loadout For Unit" @ UnitState.GetFullName());
	XComHQ = class'Help'.static.GetAndPrepXComHQ(NewGameState);
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));

	foreach LoadoutItems(LoadoutItem)
	{
		`AMLOG("Loadout Item:" @ LoadoutItem.TemplateName @ LoadoutItem.InventorySlot);

		ItemState = LoadoutItem.ItemState;
		XComHQ.GetItemFromInventory(NewGameState, ItemState.GetReference(), ItemState);
		if (ItemState == none)
			continue;

		`AMLOG("Found item state to equip.");

		ItemTemplate = ItemState.GetMyTemplate();
		
		if (!UnitState.CanAddItemToInventory(ItemTemplate, LoadoutItem.InventorySlot, NewGameState, ItemState.Quantity, ItemState))
		{
			`AMLOG("Can't equip the item. Assuming this is because slot is occupied.");

			if (class'CHItemSlot'.static.SlotIsMultiItem(LoadoutItem.InventorySlot))
			{
				EquippedItems = UnitState.GetAllItemsInSlot(LoadoutItem.InventorySlot, NewGameState,, true);
				if (EquippedItems.Length > 0)
				{
					EquippedItem = EquippedItems[EquippedItems.Length - 1];
					`AMLOG("This is a multi slot, attempting to replace the last item:" @ EquippedItem.GetMyTemplateName());
				}
			}
			else
			{
				EquippedItem = UnitState.GetItemInSlot(LoadoutItem.InventorySlot, NewGameState);
			}
		}

		// If we found an item to replace with the restored equipment, it will be stored in ItemState, and we need to put it back into the inventory
		if (EquippedItem != none)
		{
			`AMLOG("Slot is already occupied by:" @ EquippedItem.GetMyTemplateName());
			EquippedItem = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', EquippedItem.ObjectID));
					
			// Try to remove the item we want to replace from our inventory
			if (!UnitState.RemoveItemFromInventory(EquippedItem, NewGameState))
			{
				// Removing the item failed, so add our restored item back to the HQ inventory
				`AMLOG("Failed to remove the item occupying the slot. Skipping to next loadout item.");
				XComHQ.PutItemInInventory(NewGameState, ItemState);
				continue;
			}
		}

		// If we still can't add the restored item to our inventory, put it back into the HQ inventory where we found it and move on
		if (!UnitState.CanAddItemToInventory(ItemTemplate, LoadoutItem.InventorySlot, NewGameState, ItemState.Quantity, ItemState))
		{
			`AMLOG("Still can't equip the item. Putting it back into HQ inventory.");
			XComHQ.PutItemInInventory(NewGameState, ItemState);

			if (EquippedItem != none)
			{
				`AMLOG("Slot was previously occupied by:" @ EquippedItem.GetMyTemplateName() @ "attempting to equip it back.");
				if (UnitState.AddItemToInventory(EquippedItem, LoadoutItem.InventorySlot, NewGameState))
				{
					`AMLOG("Success");
				}
				else
				{
					`AMLOG("Epic fail.");
				}
			}
			
			`AMLOG("Skipping to next loadout item.");
			continue;
		}

		// Add the restored item to our inventory
		if (UnitState.AddItemToInventory(ItemState, LoadoutItem.InventorySlot, NewGameState))
		{
			`AMLOG("Successfully equipped loadout item.");
			if (!bSoundPlayed && X2EquipmentTemplate(ItemTemplate).EquipSound != "")
			{
				`XSTRATEGYSOUNDMGR.PlaySoundEvent(X2EquipmentTemplate(ItemTemplate).EquipSound);
				bSoundPlayed = true;
			}

			if (X2WeaponTemplate(ItemTemplate) != none)
			{
				if (LoadoutItem.InventorySlot == eInvSlot_PrimaryWeapon)
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
		}		
		else
		{
			`AMLOG("Failed to equip the loadout item! Putting it back to HQ inventory.");
			XComHQ.PutItemInInventory(NewGameState, ItemState);

			`AMLOG("Attempting to equip previously equipped item.");
			if (UnitState.AddItemToInventory(EquippedItem, LoadoutItem.InventorySlot, NewGameState))
			{
				`AMLOG("Success");
			}
			else
			{
				`AMLOG("Epic fail.");
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
}



defaultproperties
{
	bIsIn3D = true
	DisplayTag = "UIBlueprint_Promotion"
	CameraTag = "UIBlueprint_Promotion"
	MouseGuardClass = class'UIMouseGuard_RotatePawn';
}