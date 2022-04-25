class UIItemCard_Inventory extends UIItemCard config(UI);

var XComGameState_Unit UnitState;

var private UIPanel ListContainer; // contains all controls bellow
var private UIList	List;
var private UIPanel ListBG;

var config int RightPanelX;
var config int RightPanelY;
var config int RightPanelW;
var config int RightPanelH;
var config int ListItemWidth;

var private XComGameState_HeadquartersXCom	XComHQ;
var private IRILoadoutStruct				Loadout;
var private X2ItemTemplateManager			ItemMgr;

`include(WOTCIridarManualLoadoutManager\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

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
	local UIMechaListItem_LoadoutItem	SpawnedItem;
	local X2ItemTemplate				ItemTemplate;

	SpawnedItem = UIMechaListItem_LoadoutItem(ContainerList.GetSelectedItem());

	if (SpawnedItem.ItemState != none)
	{
		SetItemImages(SpawnedItem.ItemState.GetMyTemplate(), SpawnedItem.ItemState.GetReference());
	}
	else
	{
		ItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(SpawnedItem.LoadoutItem.TemplateName);
		if (ItemTemplate != none)
		{
			SetItemImages(ItemTemplate);
		}
	}	
}

final function array<UIMechaListItem_LoadoutItem> GetCheckedItemStatess()
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
			HeaderItem = Spawn(class'UIInventory_HeaderListItem', List.ItemContainer);
			HeaderItem.bIsNavigable = false;
			HeaderItem.InitHeaderItem("", class'CHItemSlot'.static.SlotGetName(ItemState.InventorySlot));
		}

		SpawnedItem = Spawn(class'UIMechaListItem_LoadoutItem', List.itemContainer);
		SpawnedItem.bAnimateOnInit = false;
		SpawnedItem.InitListItem();
		SpawnedItem.ItemState = ItemState;
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

final function array<IRILoadoutItemStruct> GetSelectedLoadoutItems()
{
	local UIMechaListItem_LoadoutItem	ListItem;
	local array<IRILoadoutItemStruct>		ReturnArray;
	local int i;

	for (i = 0; i < List.ItemCount; i++)
	{
		ListItem = UIMechaListItem_LoadoutItem(List.GetItem(i));
		if (ListItem != none && ListItem.Checkbox.bChecked && ListItem.ItemState != none)
		{
			ListItem.LoadoutItem.ItemState = ListItem.ItemState;
			ReturnArray.AddItem(ListItem.LoadoutItem);
		}
	}
	return ReturnArray;
}

final function PopulateLoadoutFromStruct(const IRILoadoutStruct _Loadout)
{
	local IRILoadoutItemStruct			LoadoutItem;
	local UIMechaListItem_LoadoutItem	SpawnedItem;
	local UIInventory_HeaderListItem	HeaderItem;
	local EInventorySlot				PreviousSlot;
	local XComGameState_Item			ItemState;
	local bool							bImageDisplayed;
	local X2ItemTemplate				ItemTemplate;

	Loadout = _Loadout;
	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	List.ClearItems();

	foreach Loadout.LoadoutItems(LoadoutItem)
	{
		ItemTemplate = ItemMgr.FindItemTemplate(LoadoutItem.TemplateName);
		if (ItemTemplate == none)
			continue;

		if (!bImageDisplayed)
		{
			SetItemImages(ItemTemplate);
			bImageDisplayed = true;
		}

		if (LoadoutItem.InventorySlot != PreviousSlot)
		{
			if (!`GETMCMVAR(USE_SIMPLE_HEADERS))
			{
				HeaderItem = Spawn(class'UIInventory_HeaderListItem', List.ItemContainer);
				HeaderItem.bIsNavigable = false;
				HeaderItem.InitHeaderItem("", class'CHItemSlot'.static.SlotGetName(LoadoutItem.InventorySlot));
			}
			else
			{
				SpawnedItem = Spawn(class'UIMechaListItem_LoadoutItem', List.ItemContainer);
				SpawnedItem.bIsNavigable = false;
				SpawnedItem.bAnimateOnInit = false;
				SpawnedItem.InitListItem();
				SpawnedItem.UpdateDataDescription(class'CHItemSlot'.static.SlotGetName(LoadoutItem.InventorySlot));
				SpawnedItem.SetDisabled(true);
			}
		}

		SpawnedItem = Spawn(class'UIMechaListItem_LoadoutItem', List.itemContainer);
		SpawnedItem.bAnimateOnInit = false;
		SpawnedItem.InitListItem();
		SpawnedItem.LoadoutItem = LoadoutItem;
		SpawnedItem.bProcessesMouseEvents = true;
		SpawnedItem.bIsNavigable = true;


		if (ItemTemplate == none)
		{
			SpawnedItem.UpdateDataDescription(class'UIUtilities_Text'.static.GetColoredText(`GetLocalizedString('MissingItemTemplate') @ "'" $ LoadoutItem.TemplateName $ "'", eUIState_Disabled));
			SpawnedItem.SetTooltipText("Item template not found.");
		}
		else if (ItemIsAlreadyEquipped(ItemTemplate, LoadoutItem.InventorySlot))
		{
			SpawnedItem.UpdateDataDescription(class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetItemFriendlyNameNoStats(), eUIState_Good));
			SpawnedItem.SetTooltipText("This item is already equipped.");
		}
		else 
		{
			ItemState = GetDesiredItemState(ItemTemplate.DataName, LoadoutItem.InventorySlot);
			if (ItemState == none)
			{
				if (`GETMCMVAR(ALLOW_REPLACEMENT_ITEMS))
				{
					ItemState = GetReplacementItemState(ItemTemplate.DataName, LoadoutItem.InventorySlot);
					if (ItemState == none)
					{
						SpawnedItem.UpdateDataDescription(class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetItemFriendlyNameNoStats(), eUIState_Bad));
						SpawnedItem.SetTooltipText("Desired item not found. Replacement item not found.");
					}
					else
					{
						SpawnedItem.UpdateDataCheckbox(class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetItemFriendlyNameNoStats() @ "->" @ ItemState.GetMyTemplate().GetItemFriendlyNameNoStats(), eUIState_Warning), "", false);
						SpawnedItem.SetTooltipText("Desired item not found, but you may try this replacement.");
						SpawnedItem.ItemState = ItemState;
					}
				}
				else
				{
					SpawnedItem.UpdateDataDescription(class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetItemFriendlyNameNoStats(), eUIState_Bad));
					SpawnedItem.SetTooltipText("Desired item not found. Replacements are not allowed.");
				}
			}
			else if (!CanAddItemToInventory(ItemTemplate, LoadoutItem.InventorySlot, ItemState))
			{
				SpawnedItem.UpdateDataCheckbox(class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetItemFriendlyNameNoStats(), eUIState_Warning), "", false);
				SpawnedItem.SetTooltipText("This unit cannot equip this item, but you may still try.");
				SpawnedItem.ItemState = ItemState;
			}
			else
			{
				SpawnedItem.UpdateDataCheckbox(class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetItemFriendlyNameNoStats(), eUIState_Normal), "", true);
				SpawnedItem.SetTooltipText("All normal, item will be equipped.");
				SpawnedItem.ItemState = ItemState;
			}
		}

		PreviousSlot = LoadoutItem.InventorySlot;
	}

	if (List.ItemCount > 0)
	{
		//List.SetSelectedIndex(1);
		//SelectedItemChanged(List, 1);

		List.RealizeItems();
		List.RealizeList();
	}
}

private function bool ItemIsAlreadyEquipped(const X2ItemTemplate ItemTemplate, const EInventorySlot Slot)
{
	local XComGameState_Item		EquippedItem;
	local array<XComGameState_Item>	EquippedItems;

	if (class'CHItemSlot'.static.SlotIsMultiItem(Slot))
	{
		EquippedItems = UnitState.GetAllItemsInSlot(Slot,, true);
		foreach EquippedItems(EquippedItem)
		{
			if (EquippedItem.GetMyTemplateName() == ItemTemplate.DataName)
			{
				return true;
			}
		}
	}
	else
	{
		EquippedItem = UnitState.GetItemInSlot(Slot);
		return EquippedItem != none && EquippedItem.GetMyTemplateName() == ItemTemplate.DataName;
	}
	return false;
}

private function bool CanAddItemToInventory(const X2ItemTemplate ItemTemplate, const EInventorySlot Slot, optional XComGameState_Item ItemState)
{
	local X2WeaponTemplate					WeaponTemplate;
	local X2GrenadeTemplate					GrenadeTemplate;
	local X2ArmorTemplate					ArmorTemplate;
	local array<X2DownloadableContentInfo>	DLCInfos;
	local string							DLCReason;
	local int UnusedOutInt;
	local int i;

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; ++i)
	{
		if (!DLCInfos[i].CanAddItemToInventory_CH_Improved(UnusedOutInt, Slot, ItemTemplate, 1, UnitState, , DLCReason, ItemState))
		{
			return false;
		}
	}
	
	WeaponTemplate = X2WeaponTemplate(ItemTemplate);
	ArmorTemplate = X2ArmorTemplate(ItemTemplate);
	GrenadeTemplate = X2GrenadeTemplate(ItemTemplate);

	if (class'X2TacticalGameRulesetDataStructures'.static.InventorySlotIsEquipped(Slot))
	{
		if (WeaponTemplate != none)
		{
			if (!UnitState.GetSoldierClassTemplate().IsWeaponAllowedByClass(WeaponTemplate)) // TODO: Replace with IsWeaponAllowedByClass_CH
				return false;
		}

		if (ArmorTemplate != none)
		{
			if (!UnitState.GetSoldierClassTemplate().IsArmorAllowedByClass(ArmorTemplate))
				return false;
		}

		if (!UnitState.IsMPCharacter() && !UnitState.RespectsUniqueRule(ItemTemplate, Slot))
			return false;
	}

	switch(Slot)
	{
	case eInvSlot_Loot:
	case eInvSlot_Backpack: 
	case eInvSlot_Mission:
		return true;
	case eInvSlot_Utility:
		return UnitState.GetCurrentStat(eStat_UtilityItems) > 0;
	case eInvSlot_GrenadePocket:
		return GrenadeTemplate != none && UnitState.HasGrenadePocket();
	case eInvSlot_AmmoPocket:
		return ItemTemplate.ItemCat == 'ammo' && UnitState.HasAmmoPocket();
	case eInvSlot_HeavyWeapon:
		return WeaponTemplate != none && 
			(UnitState.GetNumHeavyWeapons() > 0 || 
			LoadoutContainsArmorThatGrantsHeavyWeaponSlot() ||
			UnitState.HasAnyOfTheAbilitiesFromAnySource(class'X2AbilityTemplateManager'.default.AbilityUnlocksHeavyWeapon));
	case eInvSlot_CombatSim:
		return ItemTemplate.ItemCat == 'combatsim' && UnitState.GetCurrentStat(eStat_CombatSims) > 0;
	default:
		if (class'CHItemSlot'.static.SlotIsTemplated(Slot))
		{
			return class'CHItemSlot'.static.GetTemplateForSlot(Slot).CanAddItemToSlot(UnitState, ItemTemplate);
		}
		return true;
	}
	
	return false;
}

private function bool LoadoutContainsArmorThatGrantsHeavyWeaponSlot()
{
	local X2ArmorTemplate		ArmorTemplate;
	local IRILoadoutItemStruct	LoadoutItem;

	foreach Loadout.LoadoutItems(LoadoutItem)
	{
		ArmorTemplate = X2ArmorTemplate(ItemMgr.FindItemTemplate(LoadoutItem.TemplateName));
		if (ArmorTemplate != none)
		{
			return ArmorTemplate.bHeavyWeapon;
		}
	}
	return false;
}


private function XComGameState_Item GetDesiredItemState(const name TemplateName, EInventorySlot Slot)
{
	local StateObjectReference	ItemRef;
	local XComGameState_Item	ItemState;

	foreach XComHQ.Inventory(ItemRef)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));

		if (ItemState.GetMyTemplateName() == TemplateName && !ItemState.HasBeenModified())
		{
			return ItemState;
		}
	}

	if (`GETMCMVAR(ALLOW_MODIFIED_ITEMS))
	{
		foreach XComHQ.Inventory(ItemRef)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));

			if (ItemState.GetMyTemplateName() == TemplateName)
			{
				return ItemState;
			}
		}
	}	

	return ItemState;
}

private function XComGameState_Item GetReplacementItemState(const name TemplateName, EInventorySlot Slot)
{
	local XComGameState_Item	ItemState;

	ItemState = FindBestReplacementItemForUnit(ItemMgr.FindItemTemplate(TemplateName), Slot);
	if (ItemState == none && `GETMCMVAR(ALLOW_MODIFIED_ITEMS))
	{
		ItemState = FindBestReplacementItemForUnit(ItemMgr.FindItemTemplate(TemplateName), Slot, true);
	}
	
	return ItemState;
}

private function XComGameState_Item FindBestReplacementItemForUnit(const X2ItemTemplate OrigItemTemplate, const EInventorySlot eSlot, optional bool bAllowModified)
{
	local X2WeaponTemplate		OrigWeaponTemplate;
	local X2WeaponTemplate		WeaponTemplate;
	local X2ArmorTemplate		OrigArmorTemplate;
	local X2ArmorTemplate		ArmorTemplate;
	local X2EquipmentTemplate	OrigEquipmentTemplate;
	local X2EquipmentTemplate	EquipmentTemplate;
	local int					HighestTier;
	local XComGameState_Item	ItemState;
	local XComGameState_Item	BestItemState;
	local StateObjectReference	ItemRef;

	HighestTier = -999;

	OrigWeaponTemplate = X2WeaponTemplate(OrigItemTemplate);
	if (OrigWeaponTemplate != none)
	{
		foreach XComHQ.Inventory(ItemRef)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
			if (ItemState == none || ItemState.HasBeenModified() && !bAllowModified)
				continue;

			WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());

			if (WeaponTemplate != none)
			{
				if (WeaponTemplate.WeaponCat == OrigWeaponTemplate.WeaponCat && /*WeaponTemplate.InventorySlot == OrigWeaponTemplate.InventorySlot && */	//	Removing this for the sake of compatibility with new PS. CanAddItemToInventory should handle this, in theory.
					CanAddItemToInventory(WeaponTemplate, eSlot, ItemState))
				{
					if (WeaponTemplate.Tier > HighestTier)
					{
						HighestTier = WeaponTemplate.Tier;
						BestItemState = ItemState;
					}
				}
			}
		}
	}
	OrigArmorTemplate = X2ArmorTemplate(OrigItemTemplate);
	if (OrigArmorTemplate != none)
	{
		foreach XComHQ.Inventory(ItemRef)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
			if (ItemState == none || ItemState.HasBeenModified() && !bAllowModified)
				continue;

			ArmorTemplate = X2ArmorTemplate(ItemState.GetMyTemplate());

			if (ArmorTemplate != none)
			{
				if (ArmorTemplate.ArmorCat == OrigArmorTemplate.ArmorCat && ArmorTemplate.ArmorClass == OrigArmorTemplate.ArmorClass &&
					ArmorTemplate.bInfiniteItem &&
					CanAddItemToInventory(WeaponTemplate, eSlot, ItemState))
				{
					if (ArmorTemplate.Tier > HighestTier)
					{
						HighestTier = ArmorTemplate.Tier;
						BestItemState = ItemState;
					}
				}
			}
		}
	}
	OrigEquipmentTemplate = X2EquipmentTemplate(OrigItemTemplate);
	if (OrigEquipmentTemplate != none)
	{
		foreach XComHQ.Inventory(ItemRef)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
			if (ItemState == none || ItemState.HasBeenModified() && !bAllowModified)
				continue;

			EquipmentTemplate = X2EquipmentTemplate(ItemState.GetMyTemplate());

			if (EquipmentTemplate != none)
			{
				if (EquipmentTemplate.ItemCat == OrigEquipmentTemplate.ItemCat && EquipmentTemplate.bInfiniteItem &&
					CanAddItemToInventory(WeaponTemplate, eSlot, ItemState))
				{
					if (EquipmentTemplate.Tier > HighestTier)
					{
						HighestTier = EquipmentTemplate.Tier;
						BestItemState = ItemState;
					}
				}
			}
		}
	}
	if (HighestTier != -999)
	{
		return BestItemState;
	}
	else
	{
		return none;
	}
}