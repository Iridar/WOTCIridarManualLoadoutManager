class UISL_MLM extends UIStrategyScreenListener config(UI);

// Add Save Loadout and Load Loadout buttons to UIArmory_Loadout. 

struct IRIDisplayLoadoutItemStruct
{
	var name			TemplateName;
	var string			LocalizedName;
	var int				Quantity;
	var array<string>	SoldierNames;
	var name			ItemCat;
	var name			ArmorWeaponCat; // Stores ArmorCat+ArmorClass or WeaponCat depending on kind of item

	structdefaultproperties
	{
		Quantity = 1;
	}
};

var config int SaveLoadout_OffsetX;
var config int SaveLoadout_OffsetY;

var config int LoadLoadout_OffsetX;
var config int LoadLoadout_OffsetY;

var localized string strSaveLoadout;
var localized string strLoadLoadout;

var private bool bCHLPresent;
var private bool bLoadoutVisible;
var private bool bLoadoutSpawned;
var private string PathToButton;
var private bool bRJSSPresent;

const RJSS_List_VerticalOffset = 70;
const List_VerticalOffset = 40;
const ListBG_Padding = 5;
const ListBG_Alpha = 50;
const ListBG_ItemHeight = 28.0f;
const ListWidth = 250;
const HorizontalPaddingBetweenLists = 15;

`include(WOTCIridarManualLoadoutManager\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

// This event is triggered after a screen is initialized
event OnInit(UIScreen Screen)
{
	if (UIArmory_Loadout(Screen) != none)
	{
		AddLoadoutButtons(UIArmory_Loadout(Screen));
		
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
	else if (`GETMCMVAR(DISPLAY_SQUAD_ITEMS_BUTTON) && UISquadSelect(Screen) != none)
	{
		AddSquadButtons(UISquadSelect(Screen));
	}
	else if (UIShell(Screen) != none && class'X2LoadoutSafe'.static.ShouldLoadBackup())
	{
		Screen.SetTimer(3.1f, false, nameof(RaiseLoadBackupPopupDelayed), self);
	}
}

private function RaiseLoadBackupPopupDelayed()
{
	class'X2LoadoutSafe'.static.RaiseLoadBackupPopup();
}

event OnRemoved(UIScreen screen)
{
	if (UISquadSelect(Screen) != none)
	{
		bLoadoutSpawned = false;
	}
}

//event OnLoseFocus(UIScreen Screen)

private function AddSquadButtons(UISquadSelect Screen)
{
	local UIButton SquadLoadoutButton;

	SquadLoadoutButton = Screen.Spawn(class'UIButton', Screen).InitButton('IRI_SquadLoadoutButton', `GetLocalizedString('SquadItems'), OnCategoryButtonClicked_Weapons, eUIButtonStyle_NONE);
	if (Screen.Class != class'UISquadSelect') // Basially check if RJSS or derivatives is active.
	{
		bRJSSPresent = true;
		SquadLoadoutButton.SetPosition(-250, 5); 
	}
	else
	{
		SquadLoadoutButton.SetPosition(0, 5);
	}
	
	SquadLoadoutButton.AnchorTopCenter();
	SquadLoadoutButton.AnimateIn(0);	
	SquadLoadoutButton.SetTooltipText("Button tooltip text tastes just like raisins");
}

private function OnCategoryButtonClicked_Weapons(UIButton btn_clicked)
{
	local UIList	List;
	local UIBGBox	ListBG;
	local int		InitX;
	local int		InitY;

	if (!bLoadoutSpawned)
	{	
		InitX = 430;
		InitY = bRJSSPresent ? RJSS_List_VerticalOffset : List_VerticalOffset;

		// Armor
		ListBG = CreateListBG('IRI_SquadLoadoutList_Armor_BG',	InitX, InitY, btn_clicked.ParentPanel);
		List = CreateList('IRI_SquadLoadoutList_Armor',			InitX + 5, InitY, btn_clicked.ParentPanel);

		FillListOfType(List, class'CHItemSlot'.const.SLOT_ARMOR,, eInvSlot_HeavyWeapon); // Apparently heavy weapons are armor as far as the game is concerned :shrug: Exclude them here, non-primary weapons will pick them up.
		RealizeListBG(List, ListBG);
		
		// Primary Weapons
		InitX += ListWidth + HorizontalPaddingBetweenLists;

		ListBG = CreateListBG('IRI_SquadLoadoutList_Weapon_Primary_BG',	InitX, InitY, btn_clicked.ParentPanel);
		List = CreateList('IRI_SquadLoadoutList_Weapon_Primary',		InitX + 5, InitY, btn_clicked.ParentPanel);

		FillListOfType(List, class'CHItemSlot'.const.SLOT_WEAPON, eInvSlot_PrimaryWeapon); // Only primaries
		RealizeListBG(List, ListBG);

		// Secondary and other weapons
		InitX += ListWidth + HorizontalPaddingBetweenLists;

		ListBG = CreateListBG('IRI_SquadLoadoutList_Weapon_Other_BG',	InitX, InitY, btn_clicked.ParentPanel);
		List = CreateList('IRI_SquadLoadoutList_Weapon_Other',			InitX + 5, InitY, btn_clicked.ParentPanel);

		FillListOfType(List, class'CHItemSlot'.const.SLOT_WEAPON,, eInvSlot_PrimaryWeapon); // Only non-primaries
		RealizeListBG(List, ListBG);

		// Grenades and other items
		InitX += ListWidth + HorizontalPaddingBetweenLists;

		ListBG = CreateListBG('IRI_SquadLoadoutList_Item_BG',	InitX, InitY, btn_clicked.ParentPanel);
		List = CreateList('IRI_SquadLoadoutList_Item',			InitX + 5, InitY, btn_clicked.ParentPanel);
		
		FillListOfType(List, class'CHItemSlot'.const.SLOT_ITEM);
		RealizeListBG(List, ListBG);

		bLoadoutSpawned = true;
		bLoadoutVisible = true;
	}
	else
	{
		if (bLoadoutVisible)
		{
			bLoadoutVisible = false;
			btn_clicked.ParentPanel.GetChildByName('IRI_SquadLoadoutList_Armor').Hide();
			btn_clicked.ParentPanel.GetChildByName('IRI_SquadLoadoutList_Weapon_Primary').Hide();
			btn_clicked.ParentPanel.GetChildByName('IRI_SquadLoadoutList_Weapon_Other').Hide();
			btn_clicked.ParentPanel.GetChildByName('IRI_SquadLoadoutList_Item').Hide();

			btn_clicked.ParentPanel.GetChildByName('IRI_SquadLoadoutList_Armor_BG').Hide();
			btn_clicked.ParentPanel.GetChildByName('IRI_SquadLoadoutList_Weapon_Primary_BG').Hide();
			btn_clicked.ParentPanel.GetChildByName('IRI_SquadLoadoutList_Weapon_Other_BG').Hide();
			btn_clicked.ParentPanel.GetChildByName('IRI_SquadLoadoutList_Item_BG').Hide();
		}
		else
		{
			btn_clicked.ParentPanel.GetChildByName('IRI_SquadLoadoutList_Armor_BG').Show();
			btn_clicked.ParentPanel.GetChildByName('IRI_SquadLoadoutList_Weapon_Primary_BG').Show();
			btn_clicked.ParentPanel.GetChildByName('IRI_SquadLoadoutList_Weapon_Other_BG').Show();
			btn_clicked.ParentPanel.GetChildByName('IRI_SquadLoadoutList_Item_BG').Show();

			btn_clicked.ParentPanel.GetChildByName('IRI_SquadLoadoutList_Armor').Show();
			btn_clicked.ParentPanel.GetChildByName('IRI_SquadLoadoutList_Weapon_Primary').Show();
			btn_clicked.ParentPanel.GetChildByName('IRI_SquadLoadoutList_Weapon_Other').Show();
			btn_clicked.ParentPanel.GetChildByName('IRI_SquadLoadoutList_Item').Show();

			UpdateListData(UISquadSelect(btn_clicked.ParentPanel));

			bLoadoutVisible = true;
		}
	}
}

private function UIList CreateList(name InitName, float initX, float initY, UIPanel ParentPanel)
{
	local UIList List;

	List = ParentPanel.Spawn(class'UIList', ParentPanel);
	List.InitList(InitName, initX, initY, ListWidth);
	List.bAnimateOnInit = false;
	List.ItemPadding = -10;

	return List;
}

private function UIBGBox CreateListBG(name InitName, float initX, float initY, UIPanel ParentPanel)
{
	local UIBGBox ListBG;

	ListBG = ParentPanel.Spawn(class'UIBGBox', ParentPanel);
	ListBG.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
	ListBG.InitBG(InitName, initX - ListBG_Padding, initY - ListBG_Padding, ListWidth + ListBG_Padding * 2);
	ListBG.bAnimateOnInit = false;
	ListBG.SetAlpha(ListBG_Alpha);

	return ListBG;
}

private function RealizeListBG(UIList List, UIBGBox ListBG)
{
	ListBG.SetHeight(15 + List.ItemCount * ListBG_ItemHeight);
	if (List.ItemCount > `GETMCMVAR(MAX_LOADOUT_LIST_ITEMS))
	{
		List.SetHeight(`GETMCMVAR(MAX_LOADOUT_LIST_ITEMS) * ListBG_ItemHeight);
		ListBG.SetHeight(List.Height + 15);
	}
}

private function UpdateListData(UISquadSelect Screen)
{
	local UIList	List;
	local UIBGBox	ListBG;

	// Armor
	List = UIList(Screen.GetChildByName('IRI_SquadLoadoutList_Armor'));
	ListBG = UIBGBox(Screen.GetChildByName('IRI_SquadLoadoutList_Armor_BG'));

	FillListOfType(List, class'CHItemSlot'.const.SLOT_ARMOR,, eInvSlot_HeavyWeapon);
	RealizeListBG(List, ListBG);

	// Primary Weapons
	List = UIList(Screen.GetChildByName('IRI_SquadLoadoutList_Weapon_Primary'));
	ListBG = UIBGBox(Screen.GetChildByName('IRI_SquadLoadoutList_Weapon_Primary_BG'));

	FillListOfType(List, class'CHItemSlot'.const.SLOT_WEAPON, eInvSlot_PrimaryWeapon);
	RealizeListBG(List, ListBG);

	// Secondary and other weapons
	List = UIList(Screen.GetChildByName('IRI_SquadLoadoutList_Weapon_Other'));
	ListBG = UIBGBox(Screen.GetChildByName('IRI_SquadLoadoutList_Weapon_Other_BG'));

	FillListOfType(List, class'CHItemSlot'.const.SLOT_WEAPON,, eInvSlot_PrimaryWeapon);
	RealizeListBG(List, ListBG);

	// Grenades and other items
	List = UIList(Screen.GetChildByName('IRI_SquadLoadoutList_Item'));
	ListBG = UIBGBox(Screen.GetChildByName('IRI_SquadLoadoutList_Item_BG'));

	FillListOfType(List, class'CHItemSlot'.const.SLOT_ITEM);
	RealizeListBG(List, ListBG);
}

private function FillListOfType(UIList List, const int SlotMask, optional EInventorySlot ForceSlot = eInvSlot_Unknown, optional EInventorySlot ExcludeSlot = eInvSlot_Unknown)
{
	local UISquadLoadoutListItem				ListItem;
	local array<IRIDisplayLoadoutItemStruct>	DisplayItems;
	local IRIDisplayLoadoutItemStruct			DisplayItem;
	local string								strText;
	local int i;

	DisplayItems = GetDisplayItemsOfType(SlotMask, ForceSlot, ExcludeSlot);

	`AMLOG("Current list item count:" @ List.ItemCount @ ", Display items:" @ DisplayItems.Length);

	if (List.ItemCount > DisplayItems.Length)
	{	
		`AMLOG("Clearing list.");
		List.ClearItems();
	}

	foreach DisplayItems(DisplayItem, i)
	{
		`AMLOG(i @ "Display item:" @ DisplayItem.LocalizedName @ DisplayItem.Quantity);

		ListItem = GetListItem(List, i);

		strText = DisplayItem.LocalizedName;
		if (DisplayItem.Quantity > 1)
		{
			strText @= "(" $ DisplayItem.Quantity $ ")";
		}
		`AMLOG("Setting display text:" @ strText);
		ListItem.UpdateDataDescription(class'UIUtilities_Text'.static.GetColoredText(strText, eUIState_Normal)); // This is the default color used anyway, but specifying it directly prevents flash from changing it to black when hovering over the list item.
		ListItem.SetTooltipText(JoinStrings(DisplayItem.SoldierNames, "\n"),,,,,,, 0);
	}	

	`AMLOG("All done. Realizing list.");
	List.RealizeList();

	`AMLOG("All done. Realizing items.");
	List.RealizeItems();
}

private function string JoinStrings(array<string> Arr, string Delim)
{
	local string ReturnString;
	local int i;

	// Handle it this way so there's no delim after the final member.
	for (i = 0; i < Arr.Length - 1; i++)
	{
		ReturnString $= Arr[i] $ Delim;
	}
	if (Arr.Length > 0)
	{
		ReturnString $= Arr[Arr.Length - 1];
	}
	return ReturnString;
}

private function array<IRIDisplayLoadoutItemStruct> GetDisplayItemsOfType(const int SlotMask, optional EInventorySlot ForceSlot = eInvSlot_Unknown, optional EInventorySlot ExcludeSlot = eInvSlot_Unknown)
{
	local array<XComGameState_Unit>				UnitStates;
	local XComGameState_Unit					UnitState;
	local array<EInventorySlot>					Slots;
	local EInventorySlot						Slot;
	local array<IRIDisplayLoadoutItemStruct>	ReturnArray;
	local IRIDisplayLoadoutItemStruct			DisplayItem;
	local array<XComGameState_Item>				ItemStates;
	local XComGameState_Item					ItemState;

	`AMLOG("Called for SlotMask:" @ SlotMask @ ForceSlot @ ExcludeSlot);
	UnitStates = class'Help'.static.GetSquadUnitStates();
	if (ForceSlot != eInvSlot_Unknown)
	{
		Slots.AddItem(ForceSlot);
	}
	else
	{
		class'CHItemSlot'.static.CollectSlots(SlotMask, Slots);
		Slots.RemoveItem(ExcludeSlot);
	}	
	foreach Slots(Slot)
	{	
		`AMLOG("Begin for slot:" @ Slot);
		foreach UnitStates(UnitState)
		{
			if (class'CHItemSlot'.static.SlotIsMultiItem(Slot))
			{
				ItemStates = UnitState.GetAllItemsInSlot(Slot);
				foreach ItemStates(ItemState)
				{	
					if (ItemState.GetMyTemplate().iItemSize <= 0)
						continue;

					`AMLOG(UnitState.GetFullName() @ "item in multi item slot:" @ ItemState.GetMyTemplateName());

					DisplayItem = ConvertStatesIntoStruct(ItemState, UnitState);
					AddDisplayItem(ReturnArray, DisplayItem);
				}

			}
			else
			{
				ItemState = UnitState.GetItemInSlot(Slot);
				if (ItemState != none)
				{
					`AMLOG(UnitState.GetFullName() @ "item in slot:" @ ItemState.GetMyTemplateName());

					DisplayItem = ConvertStatesIntoStruct(ItemState, UnitState);
					AddDisplayItem(ReturnArray, DisplayItem);
				}
			}
		}
	}

	`AMLOG("Collected this many display items:" @ ReturnArray.Length);

	
	ReturnArray.Sort(SortDisplayItemsByArmorWeaponCat);
	ReturnArray.Sort(SortDisplayItemsByItemCat);

	return ReturnArray;
}

private function UISquadLoadoutListItem GetListItem(UIList List, int ItemIndex)
{
	local UISquadLoadoutListItem ListItem;
	local UIPanel Item;

	if (List.ItemCount <= ItemIndex)
	{
		ListItem = List.Spawn(class'UISquadLoadoutListItem', List.ItemContainer);
		ListItem.InitListItem();
		ListItem.bAnimateOnInit = false;
		ListItem.bIsNavigable = false;
		ListItem.BG.SetAlpha(0);
	}
	else
	{
		Item = List.GetItem(ItemIndex);
		ListItem = UISquadLoadoutListItem(Item);
	}

	return ListItem;
}

private function AddDisplayItem(out array<IRIDisplayLoadoutItemStruct> Items, const out IRIDisplayLoadoutItemStruct Item)
{
	local int Index;

	Index = Items.Find('TemplateName', Item.TemplateName);
	if (Index != INDEX_NONE)
	{
		Items[Index].Quantity++;
		Items[Index].SoldierNames.AddItem(Item.SoldierNames[0]);
	}
	else
	{
		Items.AddItem(Item);
	}
}

private function IRIDisplayLoadoutItemStruct ConvertStatesIntoStruct(const XComGameState_Item ItemState, const XComGameState_Unit UnitState)
{
	local IRIDisplayLoadoutItemStruct	Item;
	local X2ArmorTemplate				ArmorTemplate;

	Item.TemplateName = ItemState.GetMyTemplateName();
	Item.LocalizedName = ItemState.GetMyTemplate().GetItemFriendlyNameNoStats();
	Item.SoldierNames.AddItem(UnitState.GetName(eNameType_FullNick));
	Item.ItemCat = ItemState.GetMyTemplate().ItemCat;
	ArmorTemplate = X2ArmorTemplate(ItemState.GetMyTemplate());
	if (ArmorTemplate != none)
	{
		Item.ArmorWeaponCat = name(ArmorTemplate.ArmorCat $ ArmorTemplate.ArmorClass); // Store armor class for sorting purposes as well.
	}
	else
	{
		Item.ArmorWeaponCat = ItemState.GetWeaponCategory();
	}

	return Item;
}

private function int SortDisplayItemsByItemCat(IRIDisplayLoadoutItemStruct ItemA, IRIDisplayLoadoutItemStruct ItemB)
{
	if (string(ItemA.ItemCat) < string(ItemB.ItemCat))
	{
		return 1;
	}
	else if (string(ItemA.ItemCat) > string(ItemB.ItemCat))
	{
		return -1;
	}
	return 0;
}
private function int SortDisplayItemsByArmorWeaponCat(IRIDisplayLoadoutItemStruct ItemA, IRIDisplayLoadoutItemStruct ItemB)
{
	if (string(ItemA.ArmorWeaponCat) < string(ItemB.ArmorWeaponCat))
	{
		return 1;
	}
	else if (string(ItemA.ArmorWeaponCat) > string(ItemB.ArmorWeaponCat))
	{
		return -1;
	}
	return 0;
}

private final function int SortItemsBySlot(XComGameState_Item ItemA, XComGameState_Item ItemB)
{
	if (ItemA.InventorySlot < ItemB.InventorySlot)
	{
		return 1;
	}
	else if (ItemA.InventorySlot > ItemB.InventorySlot)
	{
		return -1;
	}
	return 0;
}

// This event is triggered after a screen receives focus
event OnReceiveFocus(UIScreen Screen)
{
	if (UIArmory_Loadout(Screen) != none)
	{
		AddLoadoutButtons(UIArmory_Loadout(Screen)); // Mr. Nice: Not sure this is required? It's not like NavHelp which gets flushed on pratically any kind of refresh/update...

		if (bCHLPresent)
		{
			`SCREENSTACK.SubscribeToOnInput(OnArmoryLoadoutInput);
		}
	}
	else if (UISquadSelect(Screen) != none && bLoadoutVisible)
	{
		UpdateListData(UISquadSelect(Screen));
	}
}

event OnLoseFocus(UIScreen Screen)
{
	if (UIArmory_Loadout(Screen) != none && bCHLPresent)
	{
		`SCREENSTACK.UnsubscribeFromOnInput(OnArmoryLoadoutInput);
	}
}

private function AddLoadoutButtons(UIArmory_Loadout Screen)
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

	ToggleLoadoutLockButton.SetText(default.strLoadLoadout);
	ToggleLoadoutLockButton.SetPosition(default.LoadLoadout_OffsetX - 108.65, default.LoadLoadout_OffsetY - 121);
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


/*
private function array<XComGameState_Item> GetItemsOfType(const int SlotMask)
{
	local array<XComGameState_Unit>			UnitStates;
	local XComGameState_Unit				UnitState;
	local array<EInventorySlot>				Slots;
	local EInventorySlot					Slot;
	local array<XComGameState_Item>			ReturnArray;
	local array<XComGameState_Item>			ItemStates;
	local XComGameState_Item				ItemState;

	class'CHItemSlot'.static.CollectSlots(SlotMask, Slots);

	UnitStates = class'Help'.static.GetSquadUnitStates();
	foreach UnitStates(UnitState)
	{
		foreach Slots(Slot)
		{
			if (class'CHItemSlot'.static.SlotIsMultiItem(Slot))
			{
				ItemStates = UnitState.GetAllItemsInSlot(Slot,, true);
				MergeArrays(ReturnArray, ItemStates);
			}
			else
			{
				ItemState = UnitState.GetItemInSlot(Slot);
				if (ItemState != none)
				{
					ReturnArray.AddItem(ItemState);
				}
			}
		}
	}
	ReturnArray.Sort(SortItemsBySlot);

	return ReturnArray;
}

private final function int SortItemsBySlot(XComGameState_Item ItemA, XComGameState_Item ItemB)
{
	if (ItemA.InventorySlot < ItemB.InventorySlot)
	{
		return 1;
	}
	else if (ItemA.InventorySlot > ItemB.InventorySlot)
	{
		return -1;
	}
	return 0;
}

private function MergeArrays(out array<XComGameState_Item> Acceptor, const array<XComGameState_Item> Donor)
{
	local XComGameState_Item Member;

	foreach Donor(Member)
	{
		Acceptor.AddItem(Member);
	}
}

*/