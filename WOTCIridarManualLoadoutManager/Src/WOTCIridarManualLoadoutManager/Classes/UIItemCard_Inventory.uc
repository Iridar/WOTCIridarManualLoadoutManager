class UIItemCard_Inventory extends UIItemCard config(UI);

var XComGameState_Unit UnitState;

var private UIPanel ListContainer; // contains all controls bellow
var private UIList	List;

var config int RightPanelX;
var config int RightPanelY;
var config int RightPanelW;
var config int RightPanelH;

var private XComGameState_HeadquartersXCom	XComHQ;
var private IRILoadoutStruct				Loadout;
var private array<int>						LoadoutSlotMask;// How many items the loadout contain for each slot
//var private array<int>						UnitSlotMap;	// How many items the unit can equip in each slot. Estimated, cuz equipping items contained in the loadout can change it.
var private X2ItemTemplateManager			ItemMgr;


`include(WOTCIridarManualLoadoutManager\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

simulated function UIItemCard InitItemCard(optional name InitName)
{
	super.InitItemCard(InitName);

	PopulateData("", "", "", "");

	ListContainer = Spawn(class'UIPanel', self).InitPanel('ItemCard_InventoryContainer');
	ListContainer.SetX(ListContainer.X + RightPanelX);
	ListContainer.SetY(ListContainer.Y + RightPanelY);

	List = Spawn(class'UIList', ListContainer);
	List.InitList('ItemCard_InventoryList');
	List.bSelectFirstAvailable = true;
	List.bStickyHighlight = true;
	List.OnSelectionChanged = SelectedItemChanged;
	Navigator.SetSelected(ListContainer);
	ListContainer.Navigator.SetSelected(List);

	List.SetWidth(RightPanelW);
	List.SetHeight(RightPanelH);

	XComHQ = `XCOMHQ;

	return self;
}

simulated function SelectedItemChanged(UIList ContainerList, int ItemIndex)
{
	local UIMechaListItem_LoadoutItem	SpawnedItem;
	local X2ItemTemplate				ItemTemplate;

	SpawnedItem = UIMechaListItem_LoadoutItem(ContainerList.GetSelectedItem());
	if (SpawnedItem == none)
		return;

	if (SpawnedItem.ItemState != none)
	{
		SetItemImages(SpawnedItem.ItemState.GetMyTemplate(), SpawnedItem.ItemState.GetReference());
	}
	else
	{
		ItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(SpawnedItem.LoadoutItem.Item);
		if (ItemTemplate != none)
		{
			SetItemImages(ItemTemplate);
		}
		else SetItemImages();
	}	
}

simulated function PopulateLoadoutFromUnit()
{
	local UIMechaListItem_LoadoutItem	SpawnedItem;
	local UIInventory_HeaderListItem	HeaderItem;
	local array<XComGameState_Item>		ItemStates;
	local XComGameState_Item			ItemState;
	local EInventorySlot				PreviousSlot;
	local bool							bImageDisplayed;

	List.ClearItems();

	ItemStates = GetUnitInventory();
	foreach ItemStates(ItemState)
	{
		if (!bImageDisplayed)
		{
			SetItemImages(ItemState.GetMyTemplate(), ItemState.GetReference());
			bImageDisplayed = true;
		}

		if (ItemState.InventorySlot != PreviousSlot)
		{
			if (!`GETMCMVAR(USE_SIMPLE_HEADERS))
			{
				HeaderItem = Spawn(class'UIInventory_HeaderListItem', List.ItemContainer);
				HeaderItem.bIsNavigable = false;
				HeaderItem.InitHeaderItem("", class'CHItemSlot'.static.SlotGetName(ItemState.InventorySlot));
				HeaderItem.ProcessMouseEvents(List.OnChildMouseEvent); // So that scrolling works.
				
			}
			else
			{	
				SpawnedItem = Spawn(class'UIMechaListItem_LoadoutItem', List.ItemContainer);
				SpawnedItem.bIsNavigable = false;
				SpawnedItem.bAnimateOnInit = false;
				SpawnedItem.InitListItem();
				SpawnedItem.UpdateDataDescription(class'UIUtilities_Text'.static.GetColoredText(class'CHItemSlot'.static.SlotGetName(ItemState.InventorySlot), eUIState_Disabled));
				SpawnedItem.SetDisabled(true);
			}
		}

		SpawnedItem = Spawn(class'UIMechaListItem_LoadoutItem', List.itemContainer);
		SpawnedItem.bAnimateOnInit = false;
		SpawnedItem.InitListItem();
		SpawnedItem.ItemState = ItemState;
		SpawnedItem.UpdateDataCheckbox(ItemState.GetMyTemplate().GetItemFriendlyNameNoStats(), "", true,, SpawnedItem.OnLoadoutItemClicked);

		PreviousSlot = ItemState.InventorySlot;
	}

	if (List.ItemCount > 0)
	{
		//List.SetSelectedIndex(1);
		//SelectedItemChanged(List, 1);

		List.RealizeItems();
		List.RealizeList();
	}
}

private function array<XComGameState_Item> GetUnitInventory()
{
	local CHUIItemSlotEnumerator	En;
	local array<XComGameState_Item> ReturnArray;

	En = class'CHUIItemSlotEnumerator'.static.CreateEnumerator(UnitState);
	while (En.HasNext())
	{
		En.Next();
		if (!En.IsLocked && En.ItemState != none)
		{
			ReturnArray.AddItem(En.ItemState);
		}
	}

	return ReturnArray;
}

final function array<XComGameState_Item> GetSelectedItemStates()
{
	local UIMechaListItem_LoadoutItem	ListItem;
	local array<XComGameState_Item>		ReturnArray;
	local int i;

	for (i = 0; i < List.ItemCount; i++)
	{
		ListItem = UIMechaListItem_LoadoutItem(List.GetItem(i));
		if (ListItem != none && ListItem.ItemState != none && ListItem.Checkbox.bChecked)
		{
			ReturnArray.AddItem(ListItem.ItemState);
		}
	}
	return ReturnArray;
}

final function array<UIMechaListItem_LoadoutItem> GetSelectedListItems()
{
	local UIMechaListItem_LoadoutItem			ListItem;
	local array<UIMechaListItem_LoadoutItem>	ReturnArray;
	local int i;

	for (i = 0; i < List.ItemCount; i++)
	{
		ListItem = UIMechaListItem_LoadoutItem(List.GetItem(i));
		if (ListItem != none && ListItem.Checkbox != none && ListItem.Checkbox.bChecked && ListItem.ItemState != none)
		{
			ReturnArray.AddItem(ListItem);
		}
	}
	return ReturnArray;
}

// Всю эту функцию надо переделать. Сначала составить список где всё включено, кроме предметов без Template. А уже после этого обновить статус всех элементов, и обновлять каждый раз при клике на чекбокс.
final function PopulateLoadoutFromStruct(const IRILoadoutStruct _Loadout)
{
	local IRILoadoutItemStruct			LoadoutItem;
	local UIMechaListItem_LoadoutItem	SpawnedItem;
	local UIInventory_HeaderListItem	HeaderItem;
	local EInventorySlot				PreviousSlot;
	local bool							bImageDisplayed;
	local X2ItemTemplate				ItemTemplate;

	Loadout = _Loadout;
	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	//BuildUnitSlotMap();
	BuildLoadoutSlotMask();
	List.ClearItems();

	`AMLOG("==== BEGIN =====");
	`AMLOG("Loadout:" @ Loadout.LoadoutName @ ", items:" @ Loadout.LoadoutItems.Length);

	foreach Loadout.LoadoutItems(LoadoutItem)
	{
		ItemTemplate = ItemMgr.FindItemTemplate(LoadoutItem.Item);
		if (ItemTemplate != none && !bImageDisplayed)
		{
			SetItemImages(ItemTemplate);
			bImageDisplayed = true;
		}

		// Add inventory slot header, if necessary
		if (LoadoutItem.Slot != PreviousSlot)
		{
			if (!`GETMCMVAR(USE_SIMPLE_HEADERS))
			{
				HeaderItem = Spawn(class'UIInventory_HeaderListItem', List.ItemContainer);
				HeaderItem.bIsNavigable = false;
				HeaderItem.InitHeaderItem("", class'CHItemSlot'.static.SlotGetName(LoadoutItem.Slot));
				HeaderItem.ProcessMouseEvents(List.OnChildMouseEvent);
				
				`AMLOG("Adding fancy header for inventory slot:" @ LoadoutItem.Slot);
			}
			else
			{
				SpawnedItem = Spawn(class'UIMechaListItem_LoadoutItem', List.ItemContainer);
				SpawnedItem.bIsNavigable = false;
				SpawnedItem.bAnimateOnInit = false;
				SpawnedItem.InitListItem();
				SpawnedItem.UpdateDataDescription(class'UIUtilities_Text'.static.GetColoredText(class'CHItemSlot'.static.SlotGetName(LoadoutItem.Slot), eUIState_Disabled));
				SpawnedItem.SetDisabled(true);

				`AMLOG("Adding simple header for inventory slot:" @ LoadoutItem.Slot);
			}
		}
		PreviousSlot = LoadoutItem.Slot;

		// Add a list item for this loadout item.
		SpawnedItem = Spawn(class'UIMechaListItem_LoadoutItem', List.itemContainer);
		SpawnedItem.bAnimateOnInit = false;
		SpawnedItem.bIsNavigable = true;
		SpawnedItem.InitListItem();
		SpawnedItem.InitLoadoutItem(Loadout, LoadoutItem, ItemMgr, UnitState, XComHQ);
		SpawnedItem.UpdateItem();

		// Go to next loadout item.
	}

	if (List.ItemCount > 0)
	{
		//List.SetSelectedIndex(1);
		//SelectedItemChanged(List, 1);
		List.RealizeItems();
		List.RealizeList();
	}

	`AMLOG("==== END =====");
}


final function ClearListItems()
{
	List.ClearItems();
}
/*
private function BuildUnitSlotMap()
{
	local string DummyString;
	local int i;

	UnitSlotMap.Length = 0;
	UnitSlotMap.Add(eInvSlot_MAX);

	for (i = 0; i < eInvSlot_MAX; i++)
	{
		if (class'CHItemSlot'.static.SlotIsMultiItem(EInventorySlot(i)))
		{
			UnitSlotMap[i] = class'CHItemSlot'.static.SlotGetMaxItemCount(EInventorySlot(i), UnitState);
		}
		else if (class'CHItemSlot'.static.SlotAvailable(EInventorySlot(i), DummyString, UnitState))
		{
			UnitSlotMap[i] = 1;
		}
		else
		{
			UnitSlotMap[i] = 0;
		}
	}
	if (DoesLoadoutContainArmorThatGrantsUtilitySlot())
	{
		UnitSlotMap[eInvSlot_Utility]++; 
	}
	if (DoesLoadoutContainArmorThatGrantsHeavyWeaponSlot())
	{
		UnitSlotMap[eInvSlot_HeavyWeapon]++; 
	}
}*/

private function BuildLoadoutSlotMask()
{
	local IRILoadoutItemStruct LoadoutItem;

	LoadoutSlotMask.Length = 0;
	LoadoutSlotMask.Add(eInvSlot_MAX);

	foreach Loadout.LoadoutItems(LoadoutItem)
	{
		LoadoutSlotMask[LoadoutItem.Slot]++;
	}
}

/*
private function bool LoadoutContainsArmorThatGrantsHeavyWeaponSlot()
{
	local X2ArmorTemplate		ArmorTemplate;
	local IRILoadoutItemStruct	LoadoutItem;

	foreach Loadout.LoadoutItems(LoadoutItem)
	{
		ArmorTemplate = X2ArmorTemplate(ItemMgr.FindItemTemplate(LoadoutItem.Item));
		if (ArmorTemplate != none)
		{
			return ArmorTemplate.bHeavyWeapon;
		}
	}
	return false;
}*/
/*
final function array<UIMechaListItem_LoadoutItem> GetCheckedListItems()
{
	local UIMechaListItem_LoadoutItem			ListItem;
	local array<UIMechaListItem_LoadoutItem>	ReturnArray;
	local int i;

	for (i = 0; i < List.ItemCount; i++)
	{
		ListItem = UIMechaListItem_LoadoutItem(List.GetItem(i));
		if (ListItem != none && ListItem.Checkbox.bChecked)
		{
			ReturnArray.AddItem(ListItem);
		}
	}
	return ReturnArray;
}*/