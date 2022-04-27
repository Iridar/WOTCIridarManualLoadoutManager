class UIItemCard_Inventory extends UIItemCard config(UI);

var XComGameState_Unit UnitState;

var private UIPanel ListContainer; // contains all controls bellow
var private UIList	List;

var config int RightPanelX;
var config int RightPanelY;
var config int RightPanelW;
var config int RightPanelH;
var config int ListItemWidth;

var private XComGameState_HeadquartersXCom	XComHQ;
var private IRILoadoutStruct				Loadout;
var private X2ItemTemplateManager			ItemMgr;
var private XGParamTag						LocTag;

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

	// send mouse scroll events to the list
	self.ProcessMouseEvents(List.OnChildMouseEvent);

	XComHQ = `XCOMHQ;
	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

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
	local array<IRILoadoutItemStruct>	ReturnArray;
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
	local string						DisabledReason;

	Loadout = _Loadout;
	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	List.ClearItems();

	`AMLOG("==== BEGIN =====");
	`AMLOG("Loadout:" @ Loadout.LoadoutName @ ", items:" @ Loadout.LoadoutItems.Length);

	foreach Loadout.LoadoutItems(LoadoutItem)
	{
		ItemTemplate = ItemMgr.FindItemTemplate(LoadoutItem.TemplateName);
		if (ItemTemplate != none && !bImageDisplayed)
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
				HeaderItem.ProcessMouseEvents(List.OnChildMouseEvent);

				`AMLOG("Adding fancy header for inventory slot:" @ LoadoutItem.InventorySlot);
			}
			else
			{
				SpawnedItem = Spawn(class'UIMechaListItem_LoadoutItem', List.ItemContainer);
				SpawnedItem.bIsNavigable = false;
				SpawnedItem.bAnimateOnInit = false;
				SpawnedItem.InitListItem();
				SpawnedItem.UpdateDataDescription(class'UIUtilities_Text'.static.GetColoredText(class'CHItemSlot'.static.SlotGetName(LoadoutItem.InventorySlot), eUIState_Disabled));
				SpawnedItem.SetDisabled(true);

				`AMLOG("Adding simple header for inventory slot:" @ LoadoutItem.InventorySlot);
			}
		}

		SpawnedItem = Spawn(class'UIMechaListItem_LoadoutItem', List.itemContainer);
		SpawnedItem.bAnimateOnInit = false;
		SpawnedItem.InitListItem();
		SpawnedItem.LoadoutItem = LoadoutItem;
		SpawnedItem.bIsNavigable = true;

		if (ItemTemplate == none)
		{
			SpawnedItem.UpdateDataDescription(class'UIUtilities_Text'.static.GetColoredText(`GetLocalizedString('MissingItemTemplate') @ "'" $ LoadoutItem.TemplateName $ "'", eUIState_Disabled));
			SpawnedItem.SetTooltipText(`GetLocalizedString('MissingItemTemplate_Tooltip'),,,,,,, 0);
		}
		else if (ItemIsAlreadyEquipped(ItemTemplate, LoadoutItem.InventorySlot))
		{
			SpawnedItem.UpdateDataDescription(class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetItemFriendlyNameNoStats(), eUIState_Good));
			SpawnedItem.SetTooltipText(`GetLocalizedString('ItemAlreadyEquipped'),,,,,,, 0);
		}
		else 
		{
			ItemState = GetDesiredItemState(ItemTemplate.DataName, LoadoutItem.InventorySlot);
			if (ItemState == none)
			{
				`AMLOG("Did not find desired item state:" @ ItemTemplate.DataName @ ", replacements allowed:" @ `GETMCMVAR(ALLOW_REPLACEMENT_ITEMS));
				if (`GETMCMVAR(ALLOW_REPLACEMENT_ITEMS))
				{
					ItemState = GetReplacementItemState(ItemTemplate.DataName, LoadoutItem.InventorySlot);
					if (ItemState == none)
					{
						SpawnedItem.UpdateDataDescription(class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetItemFriendlyNameNoStats(), eUIState_Bad));
						SpawnedItem.SetTooltipText(`GetLocalizedString('ItemNotFoundInInventoryAndNoReplacement'),,,,,,, 0);
					}
					else
					{
						SpawnedItem.UpdateDataCheckbox(class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetItemFriendlyNameNoStats() @ "->" @ ItemState.GetMyTemplate().GetItemFriendlyNameNoStats(), eUIState_Warning), "", false);
						SpawnedItem.SetTooltipText(`GetLocalizedString('ItemNotFoundInInventoryButReplacementFound'),,,,,,, 0);
						SpawnedItem.ItemState = ItemState;
					}
				}
				else
				{
					SpawnedItem.UpdateDataDescription(class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetItemFriendlyNameNoStats(), eUIState_Bad));
					SpawnedItem.SetTooltipText(`GetLocalizedString('ItemNotFoundInInventory'),,,,,,, 0);
				}
			}
			else 
			{
				DisabledReason = GetDisabledReason(ItemTemplate, LoadoutItem.InventorySlot, ItemState);
				`AMLOG("Found desired item state:" @ ItemState.GetMyTemplateName() @ `ShowVar(DisabledReason));
				if (DisabledReason != "")
				{
					SpawnedItem.UpdateDataDescription(class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetItemFriendlyNameNoStats() $ ": " $ DisabledReason, eUIState_Warning));
					SpawnedItem.SetTooltipText(`GetLocalizedString('UnitCannotEquipItem'),,,,,,, 0);
				}
				else
				{
					SpawnedItem.UpdateDataCheckbox(class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetItemFriendlyNameNoStats(), eUIState_Normal), "", true);
					SpawnedItem.SetTooltipText(`GetLocalizedString('ItemWillBeEquipped'),,,,,,, 0);
					SpawnedItem.ItemState = ItemState;
				}
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

	`AMLOG("==== END =====");
}

private function bool ItemIsAlreadyEquipped(const X2ItemTemplate ItemTemplate, const EInventorySlot Slot)
{
	local XComGameState_Item		EquippedItem;
	local array<XComGameState_Item>	EquippedItems;

	`AMLOG("Checking for item in slot:" @ ItemTemplate.DataName @ Slot);

	if (class'CHItemSlot'.static.SlotIsMultiItem(Slot))
	{
		EquippedItems = UnitState.GetAllItemsInSlot(Slot);
		`AMLOG("It's a multi slot with this many items equipped:" @ EquippedItems.Length);

		foreach EquippedItems(EquippedItem)
		{
			`AMLOG("Equipped item:" @ EquippedItem.GetMyTemplateName());

			if (EquippedItem.GetMyTemplateName() == ItemTemplate.DataName)
			{
				return true;
			}
		}
	}
	else
	{
		EquippedItem = UnitState.GetItemInSlot(Slot);

		`AMLOG("Equipped item:" @ EquippedItem.GetMyTemplateName());

		return EquippedItem != none && EquippedItem.GetMyTemplateName() == ItemTemplate.DataName;
	}
	return false;
}

// Adjusted copy of eponymous function from UIArmory_Loadout.
private function string GetDisabledReason(const X2ItemTemplate ItemTemplate, EInventorySlot Slot, XComGameState_Item Item)
{
	local string					DisabledReason;
	local X2AmmoTemplate			AmmoTemplate;
	local X2WeaponTemplate			WeaponTemplate;
	local X2ArmorTemplate			ArmorTemplate;
	local X2SoldierClassTemplate	AllowedSoldierClassTemplate;
	local X2SoldierClassTemplate	SoldierClassTemplate;
	local XComGameState_Item		EquippedItemState;
	local array<XComGameState_Item>	EquippedItemStates;
	local XComOnlineProfileSettings	ProfileSettings;
	local int						HighScore;
	local int						BronzeScore;	
	local string					DLCReason;
	local int						iNumMutuallyExclusiveItems;

	local array<X2DownloadableContentInfo> DLCInfos;
	local int UnusedOutInt;
	local int i;
	
	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	
	// Disable the weapon cannot be equipped by the current soldier class
	WeaponTemplate = X2WeaponTemplate(ItemTemplate);
	if(WeaponTemplate != none)
	{
		SoldierClassTemplate = UnitState.GetSoldierClassTemplate();
		if(SoldierClassTemplate != none && !SoldierClassTemplate.IsWeaponAllowedByClass(WeaponTemplate))
		{
			AllowedSoldierClassTemplate = class'UIUtilities_Strategy'.static.GetAllowedClassForWeapon(WeaponTemplate);
			if(AllowedSoldierClassTemplate == none)
			{
				DisabledReason = class'UIArmory_Loadout'.default.m_strMissingAllowedClass;
			}
			else if(AllowedSoldierClassTemplate.DataName == class'X2SoldierClassTemplateManager'.default.DefaultSoldierClass)
			{
				LocTag.StrValue0 = SoldierClassTemplate.DisplayName;
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strUnavailableToClass));
			}
			else
			{
				LocTag.StrValue0 = AllowedSoldierClassTemplate.DisplayName;
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strNeedsSoldierClass));
			}
		}

		// TLE Weapons are locked out unless ladder 1 is completed to a BronzeMedal
		if ((DisabledReason == "") && (WeaponTemplate.ClassThatCreatedUs.Name == 'X2Item_TLE_Weapons'))
		{
			ProfileSettings = `XPROFILESETTINGS;
			BronzeScore = class'XComGameState_LadderProgress'.static.GetLadderMedalThreshold( 1, 0 );
			HighScore = ProfileSettings.Data.GetLadderHighScore( 1 );

			if (BronzeScore > HighScore)
			{
				LocTag.StrValue0 = class'XComGameState_LadderProgress'.default.NarrativeLadderNames[ 1 ];
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strNeedsLadderUnlock));
			}
		}
	}

	ArmorTemplate = X2ArmorTemplate(ItemTemplate);
	if (ArmorTemplate != none)
	{
		SoldierClassTemplate = UnitState.GetSoldierClassTemplate();
		if (SoldierClassTemplate != none && !SoldierClassTemplate.IsArmorAllowedByClass(ArmorTemplate))
		{
			AllowedSoldierClassTemplate = class'UIUtilities_Strategy'.static.GetAllowedClassForArmor(ArmorTemplate);
			if (AllowedSoldierClassTemplate == none)
			{
				DisabledReason = class'UIArmory_Loadout'.default.m_strMissingAllowedClass;
			}
			else if (AllowedSoldierClassTemplate.DataName == class'X2SoldierClassTemplateManager'.default.DefaultSoldierClass)
			{
				LocTag.StrValue0 = SoldierClassTemplate.DisplayName;
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strUnavailableToClass));
			}
			else
			{
				LocTag.StrValue0 = AllowedSoldierClassTemplate.DisplayName;
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strNeedsSoldierClass));
			}
		}

		// TLE Armor is locked unless ladder 2 is completed to a Bronze Medal
		if ((DisabledReason == "") && (ArmorTemplate.ClassThatCreatedUs.Name == 'X2Item_TLE_Armor'))
		{
			ProfileSettings = `XPROFILESETTINGS;
			BronzeScore = class'XComGameState_LadderProgress'.static.GetLadderMedalThreshold( 2, 0 );
			HighScore = ProfileSettings.Data.GetLadderHighScore( 2 );

			if (BronzeScore > HighScore)
			{
				LocTag.StrValue0 = class'XComGameState_LadderProgress'.default.NarrativeLadderNames[ 2 ];
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strNeedsLadderUnlock));
			}
		}
	}

	// Disable if the ammo is incompatible with the current primary weapon
	AmmoTemplate = X2AmmoTemplate(ItemTemplate);
	if(AmmoTemplate != none)
	{
		WeaponTemplate = X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon).GetMyTemplate());
		if (WeaponTemplate != none && !X2AmmoTemplate(ItemTemplate).IsWeaponValidForAmmo(WeaponTemplate))
		{
			LocTag.StrValue0 = UnitState.GetPrimaryWeapon().GetMyTemplate().GetItemFriendlyName();
			DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strAmmoIncompatible));
		}
	}
	
	//start of Issue #50: add hook to UI to show disabled reason, if possible
	//start of Issue #114: added ItemState of what's being looked at for more expansive disabling purposes
	//issue #127: hook now fires all the time instead of a specific use case scenario
	for(i = 0; i < DLCInfos.Length; ++i)
	{
		if(!DLCInfos[i].CanAddItemToInventory_CH_Improved(UnusedOutInt, Slot, ItemTemplate, Item.Quantity, UnitState, , DLCReason, Item))
		{
			DisabledReason = DLCReason;
		}
	}
	//end of Issue #50
	//end of issue #114
	
	// Here we deviate from how original GetDisabledReason() works, becaue we don't have the luxury of a specific index of the multi item slot to which want to equip the new item.
	if(DisabledReason == "" && class'Help'.static.IsItemUniqueEquipInSlot(ItemMgr, ItemTemplate, Slot))
	{
		// When dealing with multi-item slots, we can allow *one* item in that slot to be mutually exclusive with the item we want to equip, 
		// cuz we're gonna be replacing that one when we'll be actually equipping the item (handled in UIScreen_Loadouts::EquipItems());
		if (class'CHItemSlot'.static.SlotIsMultiItem(Slot))
		{
			EquippedItemStates = UnitState.GetAllItemsInSlot(Slot);
			iNumMutuallyExclusiveItems = 0;
			foreach EquippedItemStates(EquippedItemState)
			{
				if (!UnitState.RespectsUniqueRule(ItemTemplate, Slot, , EquippedItemState.ObjectID))
				{
					iNumMutuallyExclusiveItems++;
					if (iNumMutuallyExclusiveItems > 1)
					{
						LocTag.StrValue0 = ItemTemplate.GetLocalizedCategory();
						DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strCategoryRestricted));
						break;
					}
				}
			}
		}
		else // Non-multi slots are handled by base game code well enough, which just checks if the item we want to equip is mutually exclusive with any of the times equipped on the unit
		{	 // besides the item equipped in the inventory slot itself, as *that* item will be removed from the unit before we attempt to equip a new one.
			EquippedItemState = UnitState.GetItemInSlot(Slot);
			if (EquippedItemState != none && !UnitState.RespectsUniqueRule(ItemTemplate, Slot, , EquippedItemState.ObjectID))
			{
				LocTag.StrValue0 = ItemTemplate.GetLocalizedCategory();
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strCategoryRestricted));
			}
		}
	}
	
	return DisabledReason;
}



private function XComGameState_Item GetDesiredItemState(const name TemplateName, EInventorySlot Slot)
{
	local StateObjectReference	ItemRef;
	local XComGameState_Item	ItemState;

	foreach XComHQ.Inventory(ItemRef)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));

		if (ItemState != none && ItemState.GetMyTemplateName() == TemplateName && !ItemState.HasBeenModified())
		{
			return ItemState;
		}
	}

	if (`GETMCMVAR(ALLOW_MODIFIED_ITEMS))
	{
		foreach XComHQ.Inventory(ItemRef)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));

			if (ItemState != none && ItemState.GetMyTemplateName() == TemplateName)
			{
				return ItemState;
			}
		}
	}	

	return ItemState;
}

private function XComGameState_Item GetReplacementItemState(const name TemplateName, EInventorySlot Slot)
{
	local XComGameState_Item ItemState;

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
				if (WeaponTemplate.WeaponCat == OrigWeaponTemplate.WeaponCat && 
					GetDisabledReason(WeaponTemplate, eSlot, ItemState) == "")
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
					GetDisabledReason(WeaponTemplate, eSlot, ItemState) == "")
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
					GetDisabledReason(WeaponTemplate, eSlot, ItemState) == "")
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

final function ClearListItems()
{
	List.ClearItems();
}

/*
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