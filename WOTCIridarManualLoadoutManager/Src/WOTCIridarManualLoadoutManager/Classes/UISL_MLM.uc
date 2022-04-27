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

private function AddSquadButtons(UISquadSelect Screen)
{
	local UIButton SquadLoadoutButton;

	SquadLoadoutButton = Screen.Spawn(class'UIButton', Screen).InitButton('IRI_SquadLoadoutButton_Weapons', "SQUAD ITEMS", OnCategoryButtonClicked_Weapons, eUIButtonStyle_NONE); // TODO: Localize
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
	local UIList List;

	if (!bLoadoutSpawned)
	{
		List = btn_clicked.Spawn(class'UIList', btn_clicked);
		List.InitList('IRI_SquadLoadoutList_Armor', /*initX*/,/*initY*/,/*initWidth*/,/*initHeight*/,/*horizontalList*/, true, /*optional name bgLibID */);
		List.SetPosition(-300, bRJSSPresent ? 60 : 30);
		List.bAnimateOnInit = false;
		FillListOfType(List, class'CHItemSlot'.const.SLOT_ARMOR);

		List = btn_clicked.Spawn(class'UIList', btn_clicked);
		List.InitList('IRI_SquadLoadoutList_Weapon', /*initX*/,/*initY*/,/*initWidth*/,/*initHeight*/,/*horizontalList*/, true, /*optional name bgLibID */);
		List.SetPosition(0, bRJSSPresent ? 60 : 30);
		List.bAnimateOnInit = false;
		FillListOfType(List, class'CHItemSlot'.const.SLOT_WEAPON);

		List = btn_clicked.Spawn(class'UIList', btn_clicked);
		List.InitList('IRI_SquadLoadoutList_Item', /*initX*/,/*initY*/,/*initWidth*/,/*initHeight*/,/*horizontalList*/, true, /*optional name bgLibID */);
		List.SetPosition(300, bRJSSPresent ? 60 : 30);
		List.bAnimateOnInit = false;
		FillListOfType(List, class'CHItemSlot'.const.SLOT_ITEM);

		bLoadoutSpawned = true;
		bLoadoutVisible = true;

		btn_clicked.SetTimer(1.0f, true, nameof(UpdateListData), self);
	}
	else
	{
		if (bLoadoutVisible)
		{
			bLoadoutVisible = false;
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Armor').Hide();
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Weapon').Hide();
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Item').Hide();

			btn_clicked.ClearTimer(nameof(UpdateListData), self);
		}
		else
		{
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Armor').Show();
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Weapon').Show();
			btn_clicked.GetChildByName('IRI_SquadLoadoutList_Item').Show();

			bLoadoutVisible = true;

			btn_clicked.SetTimer(1.0f, true, nameof(UpdateListData), self);
		}
	}
}

private function UpdateListData()
{
	local UIButton	SquadLoadoutButton;
	local UIList	List;

	SquadLoadoutButton = UIButton(FindObject(PathToButton, class'UIButton'));
	if (SquadLoadoutButton == none)
	{
		`AMLOG("No button!");
		return;
	}

	List = UIList(SquadLoadoutButton.GetChildByName('IRI_SquadLoadoutList_Armor'));
	FillListOfType(List, class'CHItemSlot'.const.SLOT_ARMOR);

	List = UIList(SquadLoadoutButton.GetChildByName('IRI_SquadLoadoutList_Weapon'));
	FillListOfType(List, class'CHItemSlot'.const.SLOT_WEAPON);

	List = UIList(SquadLoadoutButton.GetChildByName('IRI_SquadLoadoutList_Item'));
	FillListOfType(List, class'CHItemSlot'.const.SLOT_ITEM);
}

private function FillListOfType(UIList List, const int SlotMask)
{
	local UIText								ListItem;
	local array<IRIDisplayLoadoutItemStruct>	DisplayItems;
	local IRIDisplayLoadoutItemStruct			DisplayItem;
	local string								strText;
	local int i;

	DisplayItems = GetDisplayItemsOfType(SlotMask);

	if (List.ItemCount > DisplayItems.Length)
	{	
		List.ClearItems();
	}

	foreach DisplayItems(DisplayItem, i)
	{
		ListItem = GetListItem(List, i);
		ListItem.bAnimateOnInit = false;

		strText = DisplayItem.LocalizedName;
		if (DisplayItem.Quantity > 1)
		{
			strText @= "(" $ DisplayItem.Quantity $ ")";
		}
		ListItem.SetText(strText);
	}	

	List.RealizeList();
	List.RealizeItems();
}

private function array<IRIDisplayLoadoutItemStruct> GetDisplayItemsOfType(const int SlotMask)
{
	local array<XComGameState_Unit>				UnitStates;
	local XComGameState_Unit					UnitState;
	local array<EInventorySlot>					Slots;
	local EInventorySlot						Slot;
	local array<IRIDisplayLoadoutItemStruct>	ReturnArray;
	local IRIDisplayLoadoutItemStruct			DisplayItem;
	local array<XComGameState_Item>				ItemStates;
	local XComGameState_Item					ItemState;

	`AMLOG("Called for SlotMask:" @ SlotMask);

	class'CHItemSlot'.static.CollectSlots(SlotMask, Slots);
	UnitStates = class'Help'.static.GetSquadUnitStates();
	
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

private function UIText GetListItem(UIList List, int ItemIndex)
{
	local UIText ListItem;
	local UIPanel Item;

	if (List.ItemCount <= ItemIndex)
	{
		ListItem = List.Spawn(class'UIText', List.ItemContainer);
		ListItem.InitText();
		ListItem.bAnimateOnInit = false;
	}
	else
	{
		Item = List.GetItem(ItemIndex);
		ListItem = UIText(Item);
	}

	return ListItem;
}

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

private function OnCategoryButtonClicked_Armor(UIButton btn_clicked)
{
}

private function OnCategoryButtonClicked_Items(UIButton btn_clicked)
{
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
