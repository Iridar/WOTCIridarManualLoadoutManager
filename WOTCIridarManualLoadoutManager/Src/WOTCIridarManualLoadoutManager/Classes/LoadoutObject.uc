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
	RemoveSlotDuplicates(); // CollectSlots() adds some slots multiple times, like Heavy Weapon.

	// --- Finish initial init.
	`AMLOG("========================================================");
	`AMLOG("           BEGIN LOADOUT DISPLAY");

	foreach AllSlots(Slot)
	{
		LoadoutItems = GetLoadoutItemsForSlot(Slot);
		`AMLOG("=== Slot:" @ Slot @ "has this many loadout items:" @ LoadoutItems.Length);
		if (LoadoutItems.Length > 0)
		{
			class'Help'.static.AddSlotHeader(List, Slot);

			EquippedItems = GetEquippedItemsInSlot(Slot);		// Needed to check if some of the items in the loadout are already equipped on the unit.
			SeparateLoadoutItems(LoadoutItems, EquippedItems);	// Separate LoadoutItems into EquippedLoadoutItems and NeedEquipLoadoutItems.
			DisplayLoadoutItemsForSlot(Slot);
		}
		// Go to next slot.
	}

	`AMLOG("           END LOADOUT DISPLAY");
	`AMLOG("========================================================");


	if (List.ItemCount > 0)
	{
		List.RealizeItems();
		List.RealizeList();
	}
}

private function RemoveSlotDuplicates()
{
	local array<EInventorySlot> NonDuplicateSlots;
	local EInventorySlot		Slot;

	foreach AllSlots(Slot)
	{
		if (NonDuplicateSlots.Find(Slot) == INDEX_NONE)
		{
			NonDuplicateSlots.AddItem(Slot);
		}
	}
	AllSlots = NonDuplicateSlots;
}

private function DisplayLoadoutItemsForSlot(const out EInventorySlot Slot)
{
	local IRILoadoutItemStruct					LoadoutItem;
	local UIMechaListItem_LoadoutItem			ListItem;

	foreach EquippedLoadoutItems(LoadoutItem)
	{
		if (LoadoutItem.Slot != Slot)
			continue;

		ListItem = List.ParentPanel.Spawn(class'UIMechaListItem_LoadoutItem', List.itemContainer);
		ListItem.bAnimateOnInit = false;
		ListItem.bIsNavigable = true;
		ListItem.InitListItem();
		
		ListItem.InitLoadoutItem(LoadoutItem, ItemMgr, UnitState, XComHQ);
		ListItem.OnCheckboxChangedFn = OnCheckboxChanged;
		ListItem.bAlreadyEqupped = true;
		ListItem.SetStatus(eLIS_Normal);
		//ListItems.AddItem(ListItem);
		
	}

	foreach NeedEquipLoadoutItems(LoadoutItem)
	{
		if (LoadoutItem.Slot != Slot)
			continue;

		ListItem = List.ParentPanel.Spawn(class'UIMechaListItem_LoadoutItem', List.itemContainer);
		ListItem.bAnimateOnInit = false;
		ListItem.bIsNavigable = true;
		ListItem.InitListItem();
		
		if (ListItem.InitLoadoutItem(LoadoutItem, ItemMgr, UnitState, XComHQ))
		{
			ListItem.OnCheckboxChangedFn = OnCheckboxChanged;

			if (IsSlotAvailable(ListItem))
			{
				ListItem.SetStatus(eLIS_Normal);
			}
			else
			{
				ListItem.SetStatus(eLIS_NoSlot);
			}

			//ListItems.AddItem(ListItem);
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

	for (i = List.ItemCount - 1; i >= 0; i--)
	{
		ListItem = UIMechaListItem_LoadoutItem(List.GetItem(i));
		if (ListItem != none && ListItem != ClickedItem && ListItem.Status > eLIS_Restricted)
		{
			`AMLOG("Looking at item:" @ ListItem.LoadoutItem.Item @ ListItem.LoadoutItem.Slot);

			if (!ShouldUpdateListItemsInSlot(ClickedItem.LoadoutItem.Slot, ListItem.LoadoutItem.Slot))
				continue;

			if (IsSlotAvailable(ListItem))
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

private function bool IsSlotAvailable(out UIMechaListItem_LoadoutItem ListItem)
{
	local int SlotMaxItemCount;
	local int NumItemsInSlot;
	
	if (class'CHItemSlot'.static.SlotIsMultiItem(ListItem.LoadoutItem.Slot))
	{
		SlotMaxItemCount = class'CHItemSlot'.static.SlotGetMaxItemCount(ListItem.LoadoutItem.Slot, UnitState);

		switch (ListItem.LoadoutItem.Slot)
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

		NumItemsInSlot = GetNumSelectedListItemsForSlot(ListItem);

		`AMLOG(`ShowVar(NumItemsInSlot) $ " < " $ `ShowVar(SlotMaxItemCount));

		return NumItemsInSlot < SlotMaxItemCount;
	}
	ListItem.SlotDisabledReason = "";
	return class'CHItemSlot'.static.SlotAvailable(ListItem.LoadoutItem.Slot, ListItem.SlotDisabledReason, UnitState);
}

private function int GetNumSelectedListItemsForSlot(const out UIMechaListItem_LoadoutItem ExcludeListItem)
{
	local UIMechaListItem_LoadoutItem ListItem;
	local int NumItems;
	local int i;
	
	for (i = 0; i < List.ItemCount; i++)
	{
		ListItem = UIMechaListItem_LoadoutItem(List.GetItem(i));
		if (ListItem != none && ListItem != ExcludeListItem &&					// Ignore the list item we're running the calculation for
			ListItem.LoadoutItem.Slot == ExcludeListItem.LoadoutItem.Slot && 
			ListItem.Checkbox != none && ListItem.Checkbox.bChecked && 
			ListItem.ItemState != none)
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
