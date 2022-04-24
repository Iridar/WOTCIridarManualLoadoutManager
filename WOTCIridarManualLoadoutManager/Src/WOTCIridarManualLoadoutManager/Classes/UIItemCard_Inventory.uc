class UIItemCard_Inventory extends UIItemCard config(UI);

var UIPanel ListContainer; // contains all controls bellow
var UIList	List;
var UIPanel ListBG;

var config int RightPanelX;
var config int RightPanelY;
var config int RightPanelW;
var config int RightPanelH;
var config int ListItemWidth;

var private XComGameState_HeadquartersXCom XComHQ;

simulated function UIItemCard InitItemCard(optional name InitName)
{
	super.InitItemCard(InitName);

	PopulateData("", "", "", "");

	ListContainer = Spawn(class'UIPanel', self).InitPanel('ItemCard_InventoryContainer');
	ListContainer.SetX(ListContainer.X + RightPanelX);
	ListContainer.SetY(ListContainer.Y + RightPanelY);

	ListBG = Spawn(class'UIPanel', ListContainer);
	ListBG.InitPanel('ItemCard_InventoryListBG'); 
	ListBG.bShouldPlayGenericUIAudioEvents = false;
	ListBG.Show();

	List = Spawn(class'UIList', ListContainer);
	List.InitList('ItemCard_InventoryList');
	List.bSelectFirstAvailable = true;
	List.bStickyHighlight = true;
	List.OnSelectionChanged = SelectedItemChanged;
	Navigator.SetSelected(ListContainer);
	ListContainer.Navigator.SetSelected(List);

	List.SetWidth(RightPanelW);
	List.SetHeight(RightPanelH);

	// send mouse scroll events to the list
	ListBG.ProcessMouseEvents(List.OnChildMouseEvent);

	XComHQ = `XCOMHQ;

	return self;
}

simulated function SelectedItemChanged(UIList ContainerList, int ItemIndex)
{
	local UIMechaListItem_LoadoutItem SpawnedItem;

	SpawnedItem = UIMechaListItem_LoadoutItem(ContainerList.GetSelectedItem());

	SetItemImages(SpawnedItem.ItemState.GetMyTemplate(), SpawnedItem.ItemState.GetReference());
}

simulated function PopulateLoadoutFromUnit(XComGameState_Unit UnitState)
{
	local UIMechaListItem_LoadoutItem	SpawnedItem;
	local UIInventory_HeaderListItem	HeaderItem;
	local array<XComGameState_Item>		ItemStates;
	local XComGameState_Item			ItemState;
	local EInventorySlot				PreviousSlot;
	local bool							bImageDisplayed;

	List.ClearItems();

	ItemStates = GetInventory(UnitState);
	foreach ItemStates(ItemState)
	{
		if (!bImageDisplayed)
		{
			SetItemImages(ItemState.GetMyTemplate(), ItemState.GetReference());
			bImageDisplayed = true;
		}

		if (ItemState.InventorySlot != PreviousSlot)
		{
			HeaderItem = Spawn(class'UIInventory_HeaderListItem', List.ItemContainer);
			HeaderItem.bIsNavigable = false;
			HeaderItem.InitHeaderItem("", class'CHItemSlot'.static.SlotGetName(ItemState.InventorySlot));
		}

		SpawnedItem = Spawn(class'UIMechaListItem_LoadoutItem', List.itemContainer);
		SpawnedItem.bAnimateOnInit = false;
		SpawnedItem.InitListItem();
		SpawnedItem.ItemState = ItemState;
		SpawnedItem.InventorySlot = ItemState.InventorySlot;
		SpawnedItem.UpdateDataCheckbox(ItemState.GetMyTemplate().GetItemFriendlyNameNoStats(), "", true);

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

private function array<XComGameState_Item> GetInventory(XComGameState_Unit UnitState)
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

final function array<XComGameState_Item> GetSelectedItems()
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

final function DisplayLoadout(const IRILoadoutStruct Loadout, XComGameState_Unit UnitState)
{
	local IRILoadoutItemStruct			LoadoutItem;
	local UIMechaListItem_LoadoutItem	SpawnedItem;
	local UIInventory_HeaderListItem	HeaderItem;
	local XComGameState_Item			ItemState;
	local EInventorySlot				PreviousSlot;
	local EUIState						ItemStatus;
	local bool							bImageDisplayed;

	List.ClearItems();

	foreach Loadout.LoadoutItems(LoadoutItem)
	{
		ItemState = GetItemOfTemplate(LoadoutItem.TemplateName);
		ItemStatus = GetItemStatus(ItemState, LoadoutItem, UnitState);

		if (ItemState != none && !bImageDisplayed)
		{
			SetItemImages(ItemState.GetMyTemplate(), ItemState.GetReference());
			bImageDisplayed = true;
		}

		if (LoadoutItem.InventorySlot != PreviousSlot)
		{
			HeaderItem = Spawn(class'UIInventory_HeaderListItem', List.ItemContainer);
			HeaderItem.bIsNavigable = false;
			HeaderItem.InitHeaderItem("", class'CHItemSlot'.static.SlotGetName(LoadoutItem.InventorySlot));
		}

		SpawnedItem = Spawn(class'UIMechaListItem_LoadoutItem', List.itemContainer);
		SpawnedItem.bAnimateOnInit = false;
		SpawnedItem.InitListItem();
		SpawnedItem.ItemState = ItemState;
		SpawnedItem.InventorySlot = LoadoutItem.InventorySlot;
		SpawnedItem.UpdateDataCheckbox(class'UIUtilities_Text'.static.GetColoredText(ItemState.GetMyTemplate().GetItemFriendlyNameNoStats(), ItemStatus), "", true);

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

private function XComGameState_Item GetItemOfTemplate(const name TemplateName)
{
	local XComGameState_Item ItemState;

	ItemState = XComHQ.GetItemByName(TemplateName);

	return ItemState;
}

private function EUIState GetItemStatus(XComGameState_Item ItemState, IRILoadoutItemStruct LoadoutItem, XComGameState_Unit UnitState)
{
	//local XComGameState_Item		EquippedItem;
	//local array<XComGameState_Item> EquippedItems;

	//if (UnitState.GetItemInSlot(LoadoutItem.InventorySlot)

	return eUIState_Normal;
}