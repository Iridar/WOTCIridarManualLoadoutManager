class LoadoutObject extends Object;

var private IRILoadoutStruct	Loadout;
var private XComGameState_Unit	UnitState;
var private UIList				List;

var private XComGameState_HeadquartersXCom	XComHQ;
var private X2ItemTemplateManager			ItemMgr;

var private array<IRILoadoutItemStruct> EquippedLoadoutItems;
var private array<IRILoadoutItemStruct> NeedEquipLoadoutItems;
var private array<EInventorySlot>		AllSlots;

`include(WOTCIridarManualLoadoutManager\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

final function InitLoadout(const IRILoadoutStruct _Loadout, const XComGameState_Unit _UnitState, const UIList _List)
{
	local EInventorySlot				Slot;
	local array<XComGameState_Item>		EquippedItems;
	local array<IRILoadoutItemStruct>	LoadoutItems;

	Loadout = _Loadout;
	UnitState = _UnitState;
	List = _List;
	XComHQ = `XCOMHQ;
	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	class'CHItemSlot'.static.CollectSlots(class'CHItemSlot'.const.SLOT_ALL, AllSlots);
	
	// --- Finish initial init.

	foreach AllSlots(Slot)
	{
		LoadoutItems = GetLoadoutItemsForSlot(Slot);
		if (LoadoutItems.Length > 0)
		{
			AddSlotHeader(Slot);
		}
		EquippedItems = GetEquippedItemsInSlot(Slot);
		SeparateLoadoutItems(LoadoutItems, EquippedItems); // Separate LoadoutItems into EquippedLoadoutItems and NeedEquipLoadoutItems.
		DisplayLoadoutItemsForSlot(Slot);

		// Go to next slot.
	}

	if (List.ItemCount > 0)
	{
		//List.SetSelectedIndex(1);
		//SelectedItemChanged(List, 1);
		List.RealizeItems();
		List.RealizeList();
	}
}

private function DisplayLoadoutItemsForSlot(const out EInventorySlot Slot)
{
	local IRILoadoutItemStruct					LoadoutItem;
	local UIMechaListItem_LoadoutItem			SpawnedItem;
	//local array<UIMechaListItem_LoadoutItem>	SpawnedItems;

	foreach EquippedLoadoutItems(LoadoutItem)
	{
		if (LoadoutItem.Slot != Slot)
			continue;

		SpawnedItem = List.ParentPanel.Spawn(class'UIMechaListItem_LoadoutItem', List.itemContainer);
		SpawnedItem.bAnimateOnInit = false;
		SpawnedItem.bIsNavigable = true;
		SpawnedItem.InitListItem();
		
		SpawnedItem.InitLoadoutItem(LoadoutItem, ItemMgr, UnitState, XComHQ);
		SpawnedItem.OnCheckboxChangedFn = OnCheckboxChanged;
		SpawnedItem.SetStatus(eLIS_AlreadyEquipped);
		//SpawnedItems.AddItem(SpawnedItem);
		
	}

	foreach NeedEquipLoadoutItems(LoadoutItem)
	{
		if (LoadoutItem.Slot != Slot)
			continue;

		SpawnedItem = List.ParentPanel.Spawn(class'UIMechaListItem_LoadoutItem', List.itemContainer);
		SpawnedItem.bAnimateOnInit = false;
		SpawnedItem.bIsNavigable = true;
		SpawnedItem.InitListItem();
		
		if (SpawnedItem.InitLoadoutItem(LoadoutItem, ItemMgr, UnitState, XComHQ))
		{
			SpawnedItem.OnCheckboxChangedFn = OnCheckboxChanged;

			if (IsSlotAvailable(Slot, SpawnedItem.SlotDisabledReason))
			{
				SpawnedItem.SetStatus(eLIS_Normal);
			}
			else
			{
				SpawnedItem.SetStatus(eLIS_NoSlot);
			}

			//SpawnedItems.AddItem(SpawnedItem);
		}
	}
}

private function OnCheckboxChanged(UICheckbox CheckboxControl)
{
	local UIMechaListItem_LoadoutItem	ClickedItem;
	local UIMechaListItem_LoadoutItem	ListItem;
	local int i;

	ClickedItem = UIMechaListItem_LoadoutItem(CheckboxControl.GetParent(class'UIMechaListItem_LoadoutItem'));
	`AMLOG("Running for clicked item:" @ ClickedItem.LoadoutItem.Item @ ClickedItem.LoadoutItem.Slot);
	if (ClickedItem == none)
		return;

	ClickedItem.UpdateItem(true);

	for (i = 0; i < List.ItemCount; i++)
	{
		ListItem = UIMechaListItem_LoadoutItem(List.GetItem(i));
		if (ListItem != none && ListItem != ClickedItem && ListItem.Status > eLIS_Restricted)
		{
			`AMLOG("Looking at item:" @ ListItem.LoadoutItem.Item @ ListItem.LoadoutItem.Slot);

			if (!ShouldUpdateListItemsInSlot(ClickedItem.LoadoutItem.Slot, ListItem.LoadoutItem.Slot))
				continue;

			if (IsSlotAvailable(ListItem.LoadoutItem.Slot, ListItem.SlotDisabledReason))
			{	
				`AMLOG("Slot is available");
				ListItem.SetStatus(eLIS_Normal); // This will UpdateItem
			}
			else
			{
				`AMLOG("Slot is NOT available");
				ListItem.SetStatus(eLIS_NoSlot); // This will UpdateItem
			}

			//ListItem.UpdateItem();
		}
	}
}

private function bool ShouldUpdateListItemsInSlot(const out EInventorySlot ClickedSlot, const out EInventorySlot ListItemSlot)
{
	if (ClickedSlot == eInvSlot_Armor)
	{
		return ListItemSlot == eInvSlot_Utility || ListItemSlot == eInvSlot_HeavyWeapon;
	}

	return ClickedSlot == ListItemSlot;
}

private function AddSlotHeader(const out EInventorySlot Slot)
{
	local UIMechaListItem				SpawnedItem;
	local UIInventory_HeaderListItem	HeaderItem;

	if (!`GETMCMVAR(USE_SIMPLE_HEADERS))
	{
		HeaderItem = List.ParentPanel.Spawn(class'UIInventory_HeaderListItem', List.ItemContainer);
		HeaderItem.bIsNavigable = false;
		HeaderItem.bAnimateOnInit = false;
		HeaderItem.InitHeaderItem("", class'CHItemSlot'.static.SlotGetName(Slot));
		HeaderItem.ProcessMouseEvents(List.OnChildMouseEvent); // Enable scrolling
				
		`AMLOG("Adding fancy header for inventory slot:" @ Slot);
	}
	else
	{
		SpawnedItem = List.ParentPanel.Spawn(class'UIMechaListItem', List.ItemContainer);
		SpawnedItem.bIsNavigable = false;
		SpawnedItem.bAnimateOnInit = false;
		SpawnedItem.InitListItem();
		SpawnedItem.UpdateDataDescription(class'UIUtilities_Text'.static.GetColoredText(class'CHItemSlot'.static.SlotGetName(Slot), eUIState_Disabled));
		SpawnedItem.SetDisabled(true);

		`AMLOG("Adding simple header for inventory slot:" @ Slot);
	}
}

private function SeparateLoadoutItems(array<IRILoadoutItemStruct> LoadoutItems, const out array<XComGameState_Item> EquippedItems)
{
	local XComGameState_Item	EquippedItem;
	local IRILoadoutItemStruct	LoadoutItem;
	local int					Index;

	foreach EquippedItems(EquippedItem)
	{
		Index = LoadoutItems.Find('Item', EquippedItem.GetMyTemplateName());
		if (Index != INDEX_NONE)
		{
			EquippedLoadoutItems.AddItem(LoadoutItems[Index]);
			LoadoutItems.Remove(Index, 1);
		}
	}

	foreach LoadoutItems(LoadoutItem)
	{
		NeedEquipLoadoutItems.AddItem(LoadoutItem);
	}
}

private function array<XComGameState_Item> GetEquippedItemsInSlot(const out EInventorySlot Slot)
{
	local XComGameState_Item		EquippedItem;
	local array<XComGameState_Item> EquippedItems;

	if (class'CHItemSlot'.static.SlotIsMultiItem(Slot))
	{
		EquippedItems = UnitState.GetAllItemsInSlot(Slot);
	}
	else
	{	
		EquippedItem = UnitState.GetItemInSlot(Slot);
		if (EquippedItem != none)
		{
			EquippedItems.AddItem(EquippedItem);
		}
	}
	return EquippedItems;
}

private function array<IRILoadoutItemStruct> GetLoadoutItemsForSlot(const out EInventorySlot Slot)
{
	local IRILoadoutItemStruct			LoadoutItem;
	local array<IRILoadoutItemStruct>	LoadoutItems;

	foreach Loadout.LoadoutItems(LoadoutItem)
	{
		if (LoadoutItem.Slot == Slot)
		{
			LoadoutItems.AddItem(LoadoutItem);
		}
	}
	return LoadoutItems;
}

private function bool IsSlotAvailable(const out EInventorySlot Slot, out string SlotDisabledReason)
{
	local int SlotMaxItemCount;
	local int NumItemsInSlot;

	if (class'CHItemSlot'.static.SlotIsMultiItem(Slot))
	{
		SlotMaxItemCount = class'CHItemSlot'.static.SlotGetMaxItemCount(Slot, UnitState);

		switch (Slot)
		{
		case eInvSlot_Utility:
			if (DoesLoadoutContainArmorThatGrantsUtilitySlot())
			{
				SlotMaxItemCount++;
			}
			break;
		case eInvSlot_HeavyWeapon:
			if (DoesLoadoutContainArmorThatGrantsHeavyWeaponSlot())
			{
				SlotMaxItemCount++;
			}
			break;
		default:
			break;
		}

		NumItemsInSlot = GetNumSelectedListItemsForSlot(Slot);

		`AMLOG(`ShowVar(NumItemsInSlot) $ " < " $ `ShowVar(SlotMaxItemCount));

		return NumItemsInSlot < SlotMaxItemCount;
	}
	SlotDisabledReason = "";
	return class'CHItemSlot'.static.SlotAvailable(Slot, SlotDisabledReason, UnitState);
}

private function int GetNumSelectedListItemsForSlot(const out EInventorySlot Slot)
{
	local UIMechaListItem_LoadoutItem			ListItem;
	local int NumItems;
	local int i;

	for (i = 0; i < List.ItemCount; i++)
	{
		ListItem = UIMechaListItem_LoadoutItem(List.GetItem(i));
		if (ListItem != none && ListItem.LoadoutItem.Slot == Slot && ListItem.Checkbox != none && ListItem.Checkbox.bChecked && ListItem.ItemState != none)
		{
			NumItems++;
		}
	}
	return NumItems;
}

private function array<UIMechaListItem_LoadoutItem> GetSelectedListItems()
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

private function bool DoesLoadoutContainArmorThatGrantsUtilitySlot()
{
	local X2ArmorTemplate						ArmorTemplate;
	local UIMechaListItem_LoadoutItem			SelectedItem;
	local array<UIMechaListItem_LoadoutItem>	SelectedItems;

	SelectedItems = GetSelectedListItems();

	foreach SelectedItems(SelectedItem)
	{
		ArmorTemplate = X2ArmorTemplate(SelectedItem.ItemState.GetMyTemplate());
		if (ArmorTemplate != none)
		{
			return ArmorTemplate.bAddsUtilitySlot;
		}
	}
	return false;
}

private function bool DoesLoadoutContainArmorThatGrantsHeavyWeaponSlot()
{
	local X2ArmorTemplate						ArmorTemplate;
	local UIMechaListItem_LoadoutItem			SelectedItem;
	local array<UIMechaListItem_LoadoutItem>	SelectedItems;

	SelectedItems = GetSelectedListItems();

	foreach SelectedItems(SelectedItem)
	{
		ArmorTemplate = X2ArmorTemplate(SelectedItem.ItemState.GetMyTemplate());
		if (ArmorTemplate != none)
		{
			return ArmorTemplate.bHeavyWeapon;
		}
	}
	return false;
}
