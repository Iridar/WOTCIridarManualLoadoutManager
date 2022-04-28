class UISL_MLM extends UIStrategyScreenListener config(UI);

// Add Save Loadout and Load Loadout buttons to UIArmory_Loadout. 

struct IRIDisplayLoadoutItemStruct
{
	var name			TemplateName;
	var string			LocalizedName;
	var int				Quantity;
	var array<string>	SoldierNames;

	structdefaultproperties
	{
		Quantity = 1;
	}
};

var config int SaveLoadout_OffsetX;
var config int SaveLoadout_OffsetY;

var config int LockLoadout_OffsetX;
var config int LockLoadout_OffsetY;

var localized string strSaveLoadout;
var localized string strLockLoadout;

var private bool bCHLPresent;
var private bool bLoadoutVisible;
var private bool bLoadoutSpawned;
var private string PathToButton;
var private bool bRJSSPresent;

const RJSS_List_VerticalOffset = 70;
const List_VerticalOffset = 35;
const ListBG_Padding = 5;
const ListBG_Alpha = 50;
const ListBG_ItemHeight = 28.7f;
const ListWidth = 250;
const HorizontalPaddingBetweenLists = 15;

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
	local IRIDisplayLoadoutItemStruct Item;

	Item.TemplateName = ItemState.GetMyTemplateName();
	Item.LocalizedName = ItemState.GetMyTemplate().GetItemFriendlyNameNoStats();
	Item.SoldierNames.AddItem(UnitState.GetName(eNameType_FullNick));

	return Item;
}

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
	else if (UISquadSelect(Screen) != none)
	{
		AddSquadButtons(UISquadSelect(Screen));
	}
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

	SquadLoadoutButton = Screen.Spawn(class'UIButton', Screen).InitButton('IRI_SquadLoadoutButton_Weapons', `GetLocalizedString('SquadItems'), OnCategoryButtonClicked_Weapons, eUIButtonStyle_NONE);
	if (Screen.Class != class'UISquadSelect') // Basially check if RJSS or derivatives is active.
	{
		bRJSSPresent = true;
		SquadLoadoutButton.SetPosition(100, 5); 
	}
	else
	{
		SquadLoadoutButton.SetPosition(0, 5);
	}
	
	SquadLoadoutButton.AnchorTopCenter();
	SquadLoadoutButton.AnimateIn(0);	

	PathToButton = PathName(SquadLoadoutButton);	
}

private function OnCategoryButtonClicked_Weapons(UIButton btn_clicked)
{
	local UIList	List;
	local UIBGBox	ListBG;
	local int		InitX;
	local int		InitY;

	if (!bLoadoutSpawned)
	{	
		InitX = -622;
		InitY = bRJSSPresent ? RJSS_List_VerticalOffset : List_VerticalOffset;

		// Armor
		ListBG = CreateListBG('IRI_SquadLoadoutList_Armor_BG',	InitX, InitY, btn_clicked);
		List = CreateList('IRI_SquadLoadoutList_Armor',			InitX, InitY, btn_clicked);

		FillListOfType(List, class'CHItemSlot'.const.SLOT_ARMOR,, eInvSlot_HeavyWeapon); // Apparently heavy weapons are armor as far as the game is concerned :shrug: Exclude them here, non-primary weapons will pick them up.
		RealizeListBG(List, ListBG);
		
		// Primary Weapons
		InitX += ListWidth + HorizontalPaddingBetweenLists;

		ListBG = CreateListBG('IRI_SquadLoadoutList_Weapon_Primary_BG',	InitX, InitY, btn_clicked);
		List = CreateList('IRI_SquadLoadoutList_Weapon_Primary',		InitX, InitY, btn_clicked);

		FillListOfType(List, class'CHItemSlot'.const.SLOT_WEAPON, eInvSlot_PrimaryWeapon); // Only primaries
		RealizeListBG(List, ListBG);

		// Secondary and other weapons
		InitX += ListWidth + HorizontalPaddingBetweenLists;

		ListBG = CreateListBG('IRI_SquadLoadoutList_Weapon_Other_BG',	InitX, InitY, btn_clicked);
		List = CreateList('IRI_SquadLoadoutList_Weapon_Other',			InitX, InitY, btn_clicked);

		FillListOfType(List, class'CHItemSlot'.const.SLOT_WEAPON,, eInvSlot_PrimaryWeapon); // Only non-primaries
		RealizeListBG(List, ListBG);

		// Grenades and other items
		InitX += ListWidth + HorizontalPaddingBetweenLists;

		ListBG = CreateListBG('IRI_SquadLoadoutList_Item_BG',	InitX, InitY, btn_clicked);
		List = CreateList('IRI_SquadLoadoutList_Item',			InitX, InitY, btn_clicked);
		
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
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Armor').Hide();
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Weapon_Primary').Hide();
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Weapon_Other').Hide();
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Item').Hide();

			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Armor_BG').Hide();
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Weapon_Primary_BG').Hide();
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Weapon_Other_BG').Hide();
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Item_BG').Hide();
		}
		else
		{
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Armor_BG').Show();
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Weapon_Primary_BG').Show();
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Weapon_Other_BG').Show();
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Item_BG').Show();

			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Armor').Show();
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Weapon_Primary').Show();
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Weapon_Other').Show();
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Item').Show();

			UpdateListData();

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
	ListBG.SetHeight(List.ItemCount * ListBG_ItemHeight);
}

private function UpdateListData()
{
	local UIButton	SquadLoadoutButton;
	local UIList	List;
	local UIBGBox	ListBG;

	SquadLoadoutButton = UIButton(FindObject(PathToButton, class'UIButton'));
	if (SquadLoadoutButton == none)
	{
		`AMLOG("No button!");
		return;
	}

	// Armor
	List = UIList(SquadLoadoutButton.GetChildByName('IRI_SquadLoadoutList_Armor'));
	ListBG = UIBGBox(SquadLoadoutButton.GetChildByName('IRI_SquadLoadoutList_Armor_BG'));

	FillListOfType(List, class'CHItemSlot'.const.SLOT_ARMOR,, eInvSlot_HeavyWeapon);
	RealizeListBG(List, ListBG);

	// Primary Weapons
	List = UIList(SquadLoadoutButton.GetChildByName('IRI_SquadLoadoutList_Weapon_Primary'));
	ListBG = UIBGBox(SquadLoadoutButton.GetChildByName('IRI_SquadLoadoutList_Weapon_Primary_BG'));

	FillListOfType(List, class'CHItemSlot'.const.SLOT_WEAPON, eInvSlot_PrimaryWeapon);
	RealizeListBG(List, ListBG);

	// Secondary and other weapons
	List = UIList(SquadLoadoutButton.GetChildByName('IRI_SquadLoadoutList_Weapon_Other'));
	ListBG = UIBGBox(SquadLoadoutButton.GetChildByName('IRI_SquadLoadoutList_Weapon_Other_BG'));

	FillListOfType(List, class'CHItemSlot'.const.SLOT_WEAPON,, eInvSlot_PrimaryWeapon);
	RealizeListBG(List, ListBG);

	// Grenades and other items
	List = UIList(SquadLoadoutButton.GetChildByName('IRI_SquadLoadoutList_Item'));
	ListBG = UIBGBox(SquadLoadoutButton.GetChildByName('IRI_SquadLoadoutList_Item_BG'));

	FillListOfType(List, class'CHItemSlot'.const.SLOT_ITEM);
	RealizeListBG(List, ListBG);
}

private function FillListOfType(UIList List, const int SlotMask, optional EInventorySlot ForceSlot = eInvSlot_Unknown, optional EInventorySlot ExcludeSlot = eInvSlot_Unknown)
{
	local UIButton								ListItem;
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
		ListItem.SetText(strText);
		ListItem.SetTooltipText(DisplayItem.SoldierNames[0]);
	}	

	`AMLOG("All done. Realizing list.");
	List.RealizeList();

	`AMLOG("All done. Realizing items.");
	List.RealizeItems();
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

	return ReturnArray;
}

private function UIButton GetListItem(UIList List, int ItemIndex)
{
	local UIButton ListItem;
	local UIPanel Item;

	if (List.ItemCount <= ItemIndex)
	{
		ListItem = List.Spawn(class'UIButton', List.ItemContainer);
		ListItem.InitButton();
		ListItem.bAnimateOnInit = false;
		//ListItem.SetHeight(ListItem.Height - 5);
	}
	else
	{
		Item = List.GetItem(ItemIndex);
		ListItem = UIButton(Item);
	}

	return ListItem;
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
		UpdateListData();
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