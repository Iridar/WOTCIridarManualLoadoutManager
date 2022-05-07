class UIMechaListItem_LoadoutItem extends UIMechaListItem;

// Used in several capacities.
// Overall, it's simply a UIMechaList item with some additional storage options.

var IRILoadoutStruct		Loadout;		// Used when displaying a list of loadouts in the UIScreen_Loadouts on the left.
var IRILoadoutItemStruct	LoadoutItem;	// Used when displaying items in a previously saved loadout in the UIScreen_Loadouts on the right when loading a loadout.

var XComGameState_Item		ItemState;		// Used when displaying items equipped on the unit in the UIScreen_Loadouts on the right when saving a loadout.
											// Used for storing the best replacement item in the displayed loadout in the ItemCard when loading a loadout.

var XComGameState_Unit		UnitState;		// Used when displaying a "Load Loadout" shortcut in squad select.

var X2ItemTemplate			ItemTemplate;			// Set when the ItemState contains a replacement item (so that it can be compared against ReplacemenTemplate)
var X2ItemTemplate			ReplacementTemplate;	// Set when the ItemState contains a replacement item.


var ELoadoutItemStatus		Status;			// Current status of the loadout item.
var string					SlotDisabledReason;
var string					CachedDisabledReason;


var ELoadoutItemStatus		PrevStatus;
var int						MappedSlotIndex;// Used for multi-item slots to figure which of the slots the item must be equipped into.

// Cached stuff
var private X2ItemTemplateManager			ItemMgr;
var private XComGameState_HeadquartersXCom	XComHQ;
var private XComGameStateHistory			History;
var private XGParamTag						LocTag;

var delegate<OnCheckboxChangedCallback> OnCheckboxChangedFn;

`include(WOTCIridarManualLoadoutManager\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

// Returns true if the item can be equipped on the unit if there's a slot for it.
final function bool InitLoadoutItem(IRILoadoutItemStruct _LoadoutItem, X2ItemTemplateManager _ItemMgr, XComGameState_Unit _UnitState, XComGameState_HeadquartersXCom _XComHQ)
{	
	LoadoutItem = _LoadoutItem;
	UnitState = _UnitState;
	ItemMgr = _ItemMgr;
	XComHQ = _XComHQ;
	History = `XCOMHISTORY;

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	ItemTemplate = ItemMgr.FindItemTemplate(LoadoutItem.Item);
	if (ItemTemplate == none)
	{
		SetStatus(eLIS_MissingTemplate);
		return false;
	}

	ItemState = GetItemState();
	if (ItemState == none)
	{
		SetStatus(eLIS_NotAvailable);
		return false;
	}

	SpawnImages();
		
	CachedDisabledReason = GetDisabledReason(ItemTemplate, ItemState);
	if (CachedDisabledReason != "")
	{
		SetStatus(eLIS_Restricted);
		return false;
	}

	return true;
}


simulated function SpawnImages()
{
	local private UIPanel			WeaponImageParent;
	local private array<UIImage>	WeaponImages;
	local private array<string>		strImagePaths;
	local private UIMask			ImageMask;
	local int i;

	strImagePaths = ItemState.GetWeaponPanelImages();
	if (strImagePaths.Length == 0)
		return;

	WeaponImageParent = Spawn(class'UIPanel', self);
	WeaponImageParent.bIsNavigable = false;
	WeaponImageParent.bAnimateOnInit = false;
	WeaponImageParent.InitPanel();
	WeaponImageParent.SetAlpha(0.5);

	for (i = 0; i < strImagePaths.Length; i++)
	{
		if (i == WeaponImages.Length)
		{
			WeaponImages.AddItem(Spawn(class'UIImage', WeaponImageParent));
			WeaponImages[i].bAnimateOnInit = false;
			WeaponImages[i].InitImage('');
		}
		// haxhaxhax -- primary weapons are bigger than the others, which is normally handled by the image stack
		// but we need to do it manually
		if (LoadoutItem.Slot == eInvSlot_PrimaryWeapon ||
			(X2WeaponTemplate(ItemTemplate) != none &&
				(X2WeaponTemplate(ItemTemplate).WeaponCat == 'pistol' ||
				 X2WeaponTemplate(ItemTemplate).WeaponCat == 'sidearm'))
		)
		{
			WeaponImages[i].SetPosition(102 + 70, -24);
			WeaponImages[i].SetSize(192, 96);
		}
		else
		{
			WeaponImages[i].SetPosition(70 + 70, -40);
			WeaponImages[i].SetSize(256, 128);
		}
		WeaponImages[i].LoadImage(strImagePaths[i]);
		WeaponImages[i].Show();
	}

	ImageMask = Spawn(class'UIMask', self);
	ImageMask.bAnimateOnInit = false;
	ImageMask.InitMask('', WeaponImageParent);
	ImageMask.SetPosition(2, 2);
	ImageMask.SetSize(Width - 4, Height - 4);

	Desc.MoveToHighestDepth();
}


final function SetStatus(const ELoadoutItemStatus NewStatus)
{
	Status = NewStatus;
	UpdateItem();
}


final function UpdateItem(optional bool bJustToggleCheckbox) // True when this function runs for clicking on this item.
{
	//UpdateItemStatus();

	if (IsCheckboxAvailable())
	{
		if (bJustToggleCheckbox)
		{
			UpdateDataCheckbox(GetColoredTitle(), "", Checkbox != none && Checkbox.bChecked, OnCheckboxChangedFn, OnLoadoutItemClicked);
		}
		else if (Status == eLIS_NoSlot)
		{
			UpdateDataCheckbox(GetColoredTitle(), "", Checkbox != none ? Checkbox.bChecked : false, OnCheckboxChangedFn, OnLoadoutItemClicked);
		}
		else
		{
			// If checkbox already exists, then we keep whatever setting it had. Otherwise, we default to enabling the checkbox.
			UpdateDataCheckbox(GetColoredTitle(), "", Checkbox != none ? Checkbox.bChecked : Status >= eLIS_Normal, OnCheckboxChangedFn, OnLoadoutItemClicked);
		}
	}
	else
	{
		UpdateDataDescription(GetColoredTitle());
	}
	
	SetTooltipText(GetTooltipText(),,,,,,, 0);
}

private function bool IsCheckboxAvailable()
{
	switch (Status)
	{
	case eLIS_Unknown:
	case eLIS_MissingTemplate:
	case eLIS_NotAvailable:
	case eLIS_Restricted:
		return false;
	case eLIS_NoSlot:
	case eLIS_Normal:
		return true;
	case eLIS_AlreadyEquipped:
		return class'CHItemSlot'.static.SlotIsMultiItem(LoadoutItem.Slot);
	default:
		return false;
	}
}

private function string ColorText(string Text)
{
	switch (Status)
	{
	case eLIS_Unknown:
		return class'UIUtilities_Text'.static.GetColoredText(Text, eUIState_Bad);
	case eLIS_MissingTemplate:
		return class'UIUtilities_Text'.static.GetColoredText(Text, eUIState_Disabled);
	case eLIS_NotAvailable:
	case eLIS_Restricted:	
		return class'UIUtilities_Text'.static.GetColoredText(Text, eUIState_Bad);
	case eLIS_NoSlot:
		return class'UIUtilities_Text'.static.GetColoredText(Text, eUIState_Warning);
	case eLIS_Normal:
		return Text; // defaults to normal color.
	case eLIS_AlreadyEquipped:
		return class'UIUtilities_Text'.static.GetColoredText(Text, eUIState_Good);
	default:
		return "Warning, unhandled Loadout Item Status:" @ Status;
	}
}


private function string GetColoredTitle()
{
	return ColorText(GetTitle());
}

private function string GetTitle()
{
	switch (Status)
	{
	case eLIS_Unknown:
		return ItemTemplate.GetItemFriendlyNameNoStats() @ "Unknown Loadout Item Status";
	case eLIS_MissingTemplate:
		return `GetLocalizedString('LIS_MissingTemplate') @ "'" $ LoadoutItem.Item $ "'";
	case eLIS_NotAvailable:
		return ItemTemplate.GetItemFriendlyNameNoStats();
	case eLIS_Restricted:
		return ItemTemplate.GetItemFriendlyNameNoStats() $ ": " $ CachedDisabledReason;
	case eLIS_NoSlot:
		if (SlotDisabledReason != "")
		{
			return ItemTemplate.GetItemFriendlyNameNoStats() $ ": " $ SlotDisabledReason;
		}
		else
		{
			return ItemTemplate.GetItemFriendlyNameNoStats() $ `GetLocalizedString('LIS_NoSlot');
		}
		
	case eLIS_Normal:
	case eLIS_AlreadyEquipped:
		return ItemTemplate.GetItemFriendlyNameNoStats();
	default:
		return  "Unhandled Loadout Item Status:" @ Status;
	}
}

private function OnLoadoutItemClicked()
{
	if (Checkbox != none)
	{
		Checkbox.SetChecked(!Checkbox.bChecked);
	}	
}




private function bool IsItemAlreadyEquipped(const X2ItemTemplate _ItemTemplate)
{
	local XComGameState_Item		EquippedItem;
	local array<XComGameState_Item>	EquippedItems;

	`AMLOG("Checking for item in slot:" @ LoadoutItem.Item @ LoadoutItem.Slot);

	if (class'CHItemSlot'.static.SlotIsMultiItem(LoadoutItem.Slot))
	{
		EquippedItems = UnitState.GetAllItemsInSlot(LoadoutItem.Slot);
		`AMLOG("It's a multi slot with this many items equipped:" @ EquippedItems.Length);

		foreach EquippedItems(EquippedItem)
		{
			`AMLOG("Equipped item:" @ EquippedItem.GetMyTemplateName() @ "comparing to:" @ _ItemTemplate.DataName);

			if (EquippedItem.GetMyTemplateName() == _ItemTemplate.DataName)
			{
				`AMLOG("Match found");
				return true;
			}
		}
	}
	else
	{
		EquippedItem = UnitState.GetItemInSlot(LoadoutItem.Slot);

		if (EquippedItem != none)
			`AMLOG("Equipped item:" @ EquippedItem.GetMyTemplateName());

		return EquippedItem != none && EquippedItem.GetMyTemplateName() == _ItemTemplate.DataName;
	}
	return false;
}

private function UpdateAllItems()
{
	local UIList						List;
	local UIMechaListItem_LoadoutItem	ListItem;
	//local array<int>					SlotMap;
	//local array<EInventorySlot>			Slots;
	local int i;

	`AMLOG("=================================================================");

	/*class'CHItemSlot'.static.CollectSlots(class'CHItemSlot'.const.SLOT_ALL, Slots);
	for (i = Slots.Length - 1; i >= 0; i--)
	{
		if (!class'CHItemSlot'.static.SlotIsMultiItem(Slots[i]))
		{
			Slots.Remove(i, 1);
		}
	}*/

	//MapSlotIndex_FirstPass(Slots);

	//SlotMap.Add(eInvSlot_MAX);
	List = UIList(GetParent(class'UIList'));

	for (i = 0; i < List.ItemCount; i++)
	{	
		ListItem = UIMechaListItem_LoadoutItem(List.GetItem(i));
		if (ListItem == none)
			continue;

		//SlotMap[ListItem.LoadoutItem.Slot]++;

		`AMLOG("Updating item:" @ ListItem.LoadoutItem.Item @ ListItem.Status);
		ListItem.UpdateItem(ListItem == self); // Force update items where slot was an issue
	}
}

// Already equipped items.
/*
private function MapSlotIndex_FirstPass(const out array<EInventorySlot> Slots)
{
	local UIList								List;
	local UIMechaListItem_LoadoutItem			ListItem;
	local array<UIMechaListItem_LoadoutItem>	ListItems;
	local EInventorySlot						Slot;
	local XComGameState_Item					EquippedItem;
	local array<XComGameState_Item>				EquippedItems;
	local bool									bItemFound;
	local int									SlotIndex;
	local int i;
	
	foreach Slots(Slot)
	{
		// Collecting all loadout items for this multi-item slot.
		ListItems.Length = 0;
		for (i = 0; i < List.ItemCount; i++)
		{	
			ListItem = UIMechaListItem_LoadoutItem(List.GetItem(i));
			if (ListItem == none)
				continue;

			if (ListItem.LoadoutItem.Slot == Slot)
			{
				ListItems.AddItem(ListItem);
			}
		}

		if (ListItems.Length == 0)
			continue; // to next slot

		// Cycle through all items equipped in this slot.
		SlotIndex = 0;
		EquippedItems = UnitState.GetAllItemsInSlot(Slot);
		foreach EquippedItems(EquippedItem, SlotIndex)
		{	
			// If any of them matches an item we want to equip, 
			// mark it as such.
			bItemFound = false;
			foreach ListItems(ListItem)
			{
				if (EquippedItem.GetMyTemplateName() == ListItem.LoadoutItem.Item)
				{
					ListItem.Status = eLIS_AlreadyEquipped;
					ListItem.MappedSlotIndex = SlotIndex;
					bItemFound = true;
					break;
				}
			}
			if (bItemFound)
				continue; // to next equipped item
		}
	}
}

// For unique-equip items
private function MapSlotIndex_SecondPass(const out array<EInventorySlot> Slots)
{
	local UIList								List;
	local UIMechaListItem_LoadoutItem			ListItem;
	local array<UIMechaListItem_LoadoutItem>	ListItems;
	local EInventorySlot						Slot;
	local XComGameState_Item					EquippedItem;
	local array<XComGameState_Item>				EquippedItems;
	local int									SlotIndex;
	local array<int>							UsedSlotIndices;
	local bool									bSlotFound;
	local int i;
	
	foreach Slots(Slot)
	{
		// Collecting all loadout items for this multi-item slot that are not equipped already.
		ListItems.Length = 0;
		UsedSlotIndices.Length = 0;
		for (i = 0; i < List.ItemCount; i++)
		{	
			ListItem = UIMechaListItem_LoadoutItem(List.GetItem(i));
			if (ListItem == none)
				continue;

			// Write down slot indices that were used for this stlo already by items that are already equipped.
			if (ListItem.Status == eLIS_AlreadyEquipped)
			{
				UsedSlotIndices.AddItem(ListItem.MappedSlotIndex);
				continue;
			}

			if (ListItem.LoadoutItem.Slot == Slot)
			{
				ListItems.AddItem(ListItem);
			}
		}

		if (ListItems.Length == 0)
			continue; // to next slot

		// Cycle through all items equipped in this slot.
		SlotIndex = 0;
		EquippedItems = UnitState.GetAllItemsInSlot(Slot);
		foreach EquippedItems(EquippedItem, SlotIndex)
		{	
			// Don't consider slots that we already know contain items that we want to keep.
			if (UsedSlotIndices.Find(SlotIndex) != INDEX_NONE)
				continue;

			// Check if the item is not mutually exclusive with any items
			if (UnitState.RespectsUniqueRule(ListItem.ItemTemplate, Slot,, EquippedItemState.ObjectID))
			{
				ListItem.Status = eLIS_AlreadyEquipped;
				ListItem.MappedSlotIndex = SlotIndex;
				UsedSlotIndices.AddItem(SlotIndex);
				bSlotFound = true;
				break;
			}
		}
	}
}*/



// Adjusted copy of eponymous function from UIArmory_Loadout.
private function string GetDisabledReason(const X2ItemTemplate _ItemTemplate, const XComGameState_Item Item)
{
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
	local string					DisabledReason;

	local array<X2DownloadableContentInfo> DLCInfos;
	local int UnusedOutInt;
	local int i;
	
	// Disable the weapon cannot be equipped by the current soldier class
	WeaponTemplate = X2WeaponTemplate(_ItemTemplate);
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

	ArmorTemplate = X2ArmorTemplate(_ItemTemplate);
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
	AmmoTemplate = X2AmmoTemplate(_ItemTemplate);
	if(AmmoTemplate != none)
	{
		WeaponTemplate = X2WeaponTemplate(UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon).GetMyTemplate());
		if (WeaponTemplate != none && !X2AmmoTemplate(_ItemTemplate).IsWeaponValidForAmmo(WeaponTemplate))
		{
			LocTag.StrValue0 = UnitState.GetPrimaryWeapon().GetMyTemplate().GetItemFriendlyName();
			DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strAmmoIncompatible));
		}
	}
	
	//start of Issue #50: add hook to UI to show disabled reason, if possible
	//start of Issue #114: added ItemState of what's being looked at for more expansive disabling purposes
	//issue #127: hook now fires all the time instead of a specific use case scenario
	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	for(i = 0; i < DLCInfos.Length; ++i)
	{
		if(!DLCInfos[i].CanAddItemToInventory_CH_Improved(UnusedOutInt, LoadoutItem.Slot, _ItemTemplate, Item.Quantity, UnitState, , DLCReason, Item))
		{
			DisabledReason = DLCReason;
		}
	}
	//end of Issue #50
	//end of issue #114


	// Here we deviate from how original GetDisabledReason() works, becaue we don't have the luxury of a specific index of the multi item slot to which want to equip the new item.
	// Proceed only if the item is mutually exclusive with some other item equipped on the soldier.
	if (DisabledReason == "" && class'Help'.static.IsItemUniqueEquipInSlot(ItemMgr, _ItemTemplate, LoadoutItem.Slot) && !UnitState.RespectsUniqueRule(_ItemTemplate, LoadoutItem.Slot))
	{
		`AMLOG(_ItemTemplate.DataName @ "is unique-equip in slot:" @ LoadoutItem.Slot); 
		// We can allow the item we want to equip to be mutually exclusive with *one* item in the target inventory slot, since EquipItems() is set up to replace it.

		// So for multi-item slots, look for items in that slot we're mutually exclusive with.
		// Provide a disabled reason if there is more than one such item in this slot,
		// or if there is still some other item on the soldier we're mutually exclusive with, even if they are in other slots.
		if (class'CHItemSlot'.static.SlotIsMultiItem(LoadoutItem.Slot))
		{
			EquippedItemStates = UnitState.GetAllItemsInSlot(LoadoutItem.Slot);
			iNumMutuallyExclusiveItems = 0;
			`AMLOG("This a multi-item slot is occupied by this many items:" @ EquippedItemStates.Length); 

			foreach EquippedItemStates(EquippedItemState)
			{
				`AMLOG("Slot is occupied by:" @ EquippedItemState.GetMyTemplateName()); 
				if (class'Help'.static.AreItemTemplatesMutuallyExclusive(_ItemTemplate, EquippedItemState.GetMyTemplate()))
				{
					`AMLOG("We're mutually exclusive with this item."); 
					iNumMutuallyExclusiveItems++;
					if (iNumMutuallyExclusiveItems > 1 || !UnitState.RespectsUniqueRule(_ItemTemplate, LoadoutItem.Slot, , EquippedItemState.ObjectID))
					{
						`AMLOG("More than one mutually exclusive item:" @ iNumMutuallyExclusiveItems @ "or we're still mutually exclusive with some other item besides this one, setting disabled reason, breaking off."); 
						LocTag.StrValue0 = _ItemTemplate.GetLocalizedCategory();
						DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strCategoryRestricted));
						break;
					}
				}
			}
		}
		else // Non-multi slots are handled by base game code well enough, which just checks if the item we want to equip is mutually exclusive with any of the times equipped on the unit
		{	 // besides the item equipped in the inventory slot itself, as *that* item will be removed from the unit before we attempt to equip a new one.
			EquippedItemState = UnitState.GetItemInSlot(LoadoutItem.Slot);
			`AMLOG("Slot is occupied by:" @ EquippedItemState.GetMyTemplateName()); 
			if (EquippedItemState != none && !UnitState.RespectsUniqueRule(_ItemTemplate, LoadoutItem.Slot, , EquippedItemState.ObjectID))
			{
				`AMLOG("Even if we ignore that item, the item we want to equip must be mutually exclusive with something else. Setting disabled reason."); 
				LocTag.StrValue0 = _ItemTemplate.GetLocalizedCategory();
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strCategoryRestricted));
			}
		}
	}
	
	return DisabledReason;
}

private function XComGameState_Item GetItemState()
{
	local StateObjectReference	ItemRef;

	foreach XComHQ.Inventory(ItemRef)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));

		// If item matches and (it has not been modified or we allow modified items).
		if (ItemState != none && ItemState.GetMyTemplateName() == LoadoutItem.Item && (!ItemState.HasBeenModified() || `GETMCMVAR(ALLOW_MODIFIED_ITEMS)))
		{
			return ItemState;
		}
	}
	// If we're still here, then there's no matching item. Seek replacement, if configured so.
	if (`GETMCMVAR(ALLOW_REPLACEMENT_ITEMS))
	{
		ItemState = FindBestReplacementItemForUnit(`GETMCMVAR(ALLOW_MODIFIED_ITEMS));
		if (ItemState != none)
		{
			ReplacementTemplate = ItemState.GetMyTemplate();
			return ItemState;
		}
	}

	return none;
}

private function XComGameState_Item FindBestReplacementItemForUnit(optional bool bAllowModified)
{
	local X2WeaponTemplate		OrigWeaponTemplate;
	local X2WeaponTemplate		WeaponTemplate;
	local X2ArmorTemplate		OrigArmorTemplate;
	local X2ArmorTemplate		ArmorTemplate;
	local X2EquipmentTemplate	OrigEquipmentTemplate;
	local X2EquipmentTemplate	EquipmentTemplate;
	local int					HighestTier;
	local XComGameState_Item	CycleItemState;
	local XComGameState_Item	BestItemState;
	local StateObjectReference	ItemRef;
	local string				DisabledReason;

	HighestTier = -999;

	OrigWeaponTemplate = X2WeaponTemplate(ItemTemplate);
	if (OrigWeaponTemplate != none)
	{
		foreach XComHQ.Inventory(ItemRef)
		{
			CycleItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
			if (CycleItemState == none || CycleItemState.HasBeenModified() && !bAllowModified || IsItemAlreadyEquipped(CycleItemState.GetMyTemplate()))
				continue;

			WeaponTemplate = X2WeaponTemplate(CycleItemState.GetMyTemplate());

			if (WeaponTemplate != none)
			{
				DisabledReason = GetDisabledReason(WeaponTemplate, CycleItemState);
				if (WeaponTemplate.WeaponCat == OrigWeaponTemplate.WeaponCat && DisabledReason == "")
				{
					if (WeaponTemplate.Tier > HighestTier)
					{
						HighestTier = WeaponTemplate.Tier;
						BestItemState = CycleItemState;
					}
				}
			}
		}
	}
	else
	{
		OrigArmorTemplate = X2ArmorTemplate(ItemTemplate);
		if (OrigArmorTemplate != none)
		{
			foreach XComHQ.Inventory(ItemRef)
			{
				CycleItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
				if (CycleItemState == none || CycleItemState.HasBeenModified() && !bAllowModified || IsItemAlreadyEquipped(CycleItemState.GetMyTemplate()))
					continue;

				ArmorTemplate = X2ArmorTemplate(CycleItemState.GetMyTemplate());

				if (ArmorTemplate != none)
				{
					DisabledReason = GetDisabledReason(ArmorTemplate, CycleItemState);
					if (ArmorTemplate.ArmorCat == OrigArmorTemplate.ArmorCat && ArmorTemplate.ArmorClass == OrigArmorTemplate.ArmorClass && DisabledReason == "")
					{
						if (ArmorTemplate.Tier > HighestTier)
						{
							HighestTier = ArmorTemplate.Tier;
							BestItemState = CycleItemState;
						}
					}
				}
			}
		}
		else
		{
			OrigEquipmentTemplate = X2EquipmentTemplate(ItemTemplate);
			if (OrigEquipmentTemplate != none)
			{
				foreach XComHQ.Inventory(ItemRef)
				{
					CycleItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
					if (CycleItemState == none || CycleItemState.HasBeenModified() && !bAllowModified || IsItemAlreadyEquipped(CycleItemState.GetMyTemplate()))
						continue;

					EquipmentTemplate = X2EquipmentTemplate(CycleItemState.GetMyTemplate());

					if (EquipmentTemplate != none)
					{
						DisabledReason = GetDisabledReason(EquipmentTemplate, CycleItemState);
						if (EquipmentTemplate.ItemCat == OrigEquipmentTemplate.ItemCat && DisabledReason == "")
						{
							if (EquipmentTemplate.Tier > HighestTier)
							{
								HighestTier = EquipmentTemplate.Tier;
								BestItemState = CycleItemState;
							}
						}
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

// ==================================================================
//						TOOLTIPS

private function string GetTooltipText()
{
	switch (Status)
	{
	case eLIS_Unknown:
		return "Warning, Loadout Item Status has not been set!";
	case eLIS_MissingTemplate:
		return `GetLocalizedString('LIS_MissingTemplate_Tooltip');
	case eLIS_NotAvailable:
		if (`GETMCMVAR(ALLOW_REPLACEMENT_ITEMS))
		{
			return `GetLocalizedString('LIS_NotAvailable_NoReplacement_Tooltip');
		}
		return `GetLocalizedString('LIS_NotAvailable_Tooltip');
	case eLIS_Restricted:
		return `GetLocalizedString('LIS_Restricted_Tooltip');
	case eLIS_NoSlot:
		return `GetLocalizedString('LIS_NoSlot_Tooltip');
	case eLIS_Normal:
		if (Checkbox.bChecked)
		{
			return `GetLocalizedString('LIS_Selected_Tooltip');
		}
		else
		{
			return `GetLocalizedString('LIS_NotSelected_Tooltip');
		}
	case eLIS_AlreadyEquipped:
		return `GetLocalizedString('LIS_AlreadyEquipped_Tooltip');
	default:
		return "Warning, unhandled Loadout Item Status:" @ Status;
	}
}

// Tooltips don't work out of the box for list items. I don't know why. I don't care why. Fox everything.
simulated function OnMouseEvent( int cmd, array<string> args )
{
	local UITooltip Tooltip; 

	super.OnMouseEvent(cmd, args);

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
			Tooltip = Movie.Pres.m_kTooltipMgr.GetTooltipByID(CachedTooltipId);
			if (Tooltip == none)
				return;
			Tooltip.bUsePartialPath = true;
			Movie.Pres.m_kTooltipMgr.ActivateTooltip(Tooltip);
			return;

		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE:
			Tooltip = Movie.Pres.m_kTooltipMgr.GetTooltipByID(CachedTooltipId);
			if (Tooltip == none)
				return;
			Tooltip.bUsePartialPath = true;
			Movie.Pres.m_kTooltipMgr.DeactivateTooltip(Tooltip, true);
			return;
	}
}


// ==================================================================
//						SQUAD SELECT SHORTCUT

final function UpdateDataDescriptionShortcut(XComGameState_Unit _UnitState)
{
	UnitState = _UnitState;
	UpdateDataDescription(`GetLocalizedString('EquipLoadout'), OnEquipLoadoutShortcutClicked);
}

// Called when clicking the EQUIP LOADOUT shortcut on squad select.
private function OnEquipLoadoutShortcutClicked()
{
	local XComHQPresentationLayer	HQPresLayer;
	local UIScreen_Loadouts			SaveLoadout;
	local UIArmory_Loadout			ArmoryScreen;

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
	HQPresLayer = `HQPRES;

	HQPresLayer.UIArmory_Loadout(UnitState.GetReference());

	// Bandaid hack. The UIArmory_Loadout screen is pushed to display unit pawn, and then immediately get replaced by UIScreen_Loadouts, so only the pawn remains.
	// And we tell the UIScreen_Loadouts to automatically close UIArmory_Loadout when it itself is closed.
	ArmoryScreen = UIArmory_Loadout(HQPresLayer.ScreenStack.GetFirstInstanceOf(class'UIArmory_Loadout'));

	`AMLOG(UnitState.GetFullName() @ ArmoryScreen.GetUnit().GetFullName());

	SaveLoadout = HQPresLayer.Spawn(class'UIScreen_Loadouts', HQPresLayer);
	SaveLoadout.UnitState = UnitState;
	SaveLoadout.UIArmoryLoadoutScreen = ArmoryScreen;
	SaveLoadout.bCloseArmoryScreenWhenClosing = true;
	HQPresLayer.ScreenStack.Push(SaveLoadout, HQPresLayer.Get3DMovie());
}

defaultproperties
{
	MappedSlotIndex = INDEX_NONE
}