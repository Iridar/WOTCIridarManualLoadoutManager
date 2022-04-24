class UIScreen_Loadouts extends UIInventory_XComDatabase;

var UIArmory_Loadout	UIArmoryLoadoutScreen;
var XComGameState_Unit	UnitState;
var bool				bForSaving;

var config(UI) int NewX;
var config(UI) int ListItemWidthMod;

var private UILargeButton EquipLoadoutButton;
var private string CachedNewLoadoutName;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super(UIInventory).InitScreen(InitController, InitMovie, InitName);

	self.SetX(self.X - NewX);
	
	SetCategory("");
	
	SetInventoryLayout();
	PopulateData();
	/*
	if (XComHQPresentationLayer(Movie.Pres) != none)
	{
		class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, 0);
		MC.FunctionVoid("setArchiveLayout");
		`XCOMGRI.DoRemoteEvent('RewardsRecap');
	}*/
	UIArmoryLoadoutScreen.Hide();
	UIArmoryLoadoutScreen.NavHelp.Show();
}

simulated function BuildScreen()
{
	TitleHeader = Spawn(class'UIX2PanelHeader', self);
	TitleHeader.InitPanelHeader('TitleHeader', `GetLocalizedString('LoadoutListTitle'), `GetLocalizedString('LoadoutListSubTitle'));
	TitleHeader.SetHeaderWidth( 580 );
	//if( m_strTitle == "" && m_strSubTitleTitle == "" )
	//	TitleHeader.Hide();

	ListContainer = Spawn(class'UIPanel', self).InitPanel('InventoryContainer');

	ItemCard = Spawn(class'UIItemCard_Inventory', ListContainer).InitItemCard('ItemCard');
	ItemCard.SetX(ItemCard.X + 1200);

	ListBG = Spawn(class'UIPanel', ListContainer);
	ListBG.InitPanel('InventoryListBG'); 
	ListBG.bShouldPlayGenericUIAudioEvents = false;
	ListBG.Show();

	List = Spawn(class'UIList', ListContainer);
	List.InitList(InventoryListName);
	List.bSelectFirstAvailable = bSelectFirstAvailable;
	List.bStickyHighlight = true;
	List.OnSelectionChanged = SelectedItemChanged;
	Navigator.SetSelected(ListContainer);
	ListContainer.Navigator.SetSelected(List);

	if (!bForSaving)
	{
		EquipLoadoutButton = Spawn(class'UILargeButton', `HQPRES.m_kAvengerHUD.NavHelp.Screen);
		EquipLoadoutButton.LibID = 'X2ContinueButton';
		EquipLoadoutButton.bHideUntilRealized = true;
		EquipLoadoutButton.InitLargeButton(, `GetLocalizedString('EquipLoadout'));
		EquipLoadoutButton.DisableNavigation();
		EquipLoadoutButton.AnchorBottomCenter();
		EquipLoadoutButton.OffsetY = -10;
		EquipLoadoutButton.OnClickedDelegate = OnEquipLoadoutClicked;
		EquipLoadoutButton.Show();
		EquipLoadoutButton.ShowBG(true);
		//EquipLoadoutButton.SetPosition(10, 10);
	}

	m_strTotalLabel = "";
	SetBuiltLabel(m_strTotalLabel);

	// send mouse scroll events to the list
	ListBG.ProcessMouseEvents(List.OnChildMouseEvent);

	if( bIsIn3D )
		class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, OverrideInterpTime != -1 ? OverrideInterpTime : `HQINTERPTIME);
}

private function OnEquipLoadoutClicked(UIButton Button)
{
	local array<XComGameState_Item> ItemStates;

	ItemStates = UIItemCard_Inventory(ItemCard).GetSelectedItems();
	if (ItemStates.Length == 0)
	{
		ShowInfoPopup(`GetLocalizedString('InvalidLoadoutNameTitle'), `GetLocalizedString('NoItemsInLoadoutText_Equip'), eDialog_Warning);
		return;
	}

	EquipItems(ItemStates);
	CloseScreen();
}

private function EquipItems(array<XComGameState_Item> ItemStates)
{
}

simulated function PopulateData()
{
	local UIMechaListItem_LoadoutItem	SpawnedItem;
	local array<IRILoadoutStruct>		Loadouts;
	local IRILoadoutStruct				Loadout;

	List.ClearItems();

	if (bForSaving)
	{
		SpawnedItem = Spawn(class'UIMechaListItem_LoadoutItem', List.itemContainer);
		SpawnedItem.bAnimateOnInit = false;
		SpawnedItem.InitListItem();
		SpawnedItem.Loadout = Loadout;
		SpawnedItem.ListItemWidthMod = ListItemWidthMod;
		SpawnedItem.UpdateDataDescription(`GetLocalizedString('CreateNewLoadoutButton'), OnCreateLoadoutClicked);
		
		UIItemCard_Inventory(ItemCard).PopulateLoadoutFromUnit(UnitState);
	}

	Loadouts = class'X2LoadoutSafe'.static.GetLoadouts();
	foreach Loadouts(Loadout)
	{
		SpawnedItem = Spawn(class'UIMechaListItem_LoadoutItem', List.itemContainer);
		SpawnedItem.bAnimateOnInit = false;
		SpawnedItem.InitListItem();
		SpawnedItem.Loadout = Loadout;
		SpawnedItem.ListItemWidthMod = ListItemWidthMod;

		if (bForSaving)
		{
			SpawnedItem.UpdateDataButton(Loadout.LoadoutName, class'UIMPShell_SquadLoadoutList'.default.m_strDeleteSet, OnDeleteLoadoutClicked, OnSaveSelectedLoadoutClicked);
			
		}
		else
		{
			SpawnedItem.UpdateDataCheckbox(Loadout.LoadoutName, "", false, none, OnLoadSelectedLoadoutClicked);
			SpawnedItem.Checkbox.OnMouseEventDelegate = CheckboxMouseEvent;
		}
	}

	if (List.ItemCount > 0)
	{
		List.SetSelectedIndex(1);
		
		if (bForSaving) 
		{	
			SelectedItemChanged(List, 1);
		}
		else
		{
			SelectedItemChanged(List, 0);
			SelectListItem(0);
		}
		List.Navigator.SelectFirstAvailable();

		List.RealizeItems();
		List.RealizeList();
	}
}

private function CheckboxMouseEvent(UIPanel Panel, int Cmd)
{
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
		//OnMouseEventDelegate(self, cmd);
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
		//OnMouseEventDelegate(self, cmd);
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:
		SelectListItem(List.GetItemIndex(Panel.GetParent(class'UIMechaListItem_LoadoutItem')));
		break;
	}
}

private function OnLoadSelectedLoadoutClicked()
{
	SelectListItem(List.GetItemIndex(List.GetSelectedItem()));
}

private function OnDeleteLoadoutClicked(UIButton ButtonSource)
{
	local UIMechaListItem_LoadoutItem	SelectedLoadout;
	local TDialogueBoxData				kDialogData;

	SelectedLoadout = UIMechaListItem_LoadoutItem(ButtonSource.GetParent(class'UIMechaListItem_LoadoutItem'));
	CachedNewLoadoutName = SelectedLoadout.Loadout.LoadoutName;

	kDialogData.strTitle = `GetLocalizedString('ConfirmDeleteLoadoutTitle');
	kDialogData.eType = eDialog_Warning;
	kDialogData.strText = Repl(`GetLocalizedString('ConfirmDeleteLoadoutText'), "%LoadoutName%", CachedNewLoadoutName);
	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;
	kDialogData.fnCallback = OnDeleteLoadoutClickedCallback;
	Movie.Pres.UIRaiseDialog(kDialogData);
}

private function OnDeleteLoadoutClickedCallback(Name eAction)
{
	if (eAction == 'eUIAction_Accept')
	{
		class'X2LoadoutSafe'.static.DeleteLoadut_Static(CachedNewLoadoutName);
		PopulateData();
	}
}

private function OnSaveSelectedLoadoutClicked()
{
	local UIMechaListItem_LoadoutItem	SelectedLoadout;
	local array<XComGameState_Item>		ItemStates;
	local TDialogueBoxData				kDialogData;

	ItemStates = UIItemCard_Inventory(ItemCard).GetSelectedItems();
	if (ItemStates.Length == 0)
	{
		ShowInfoPopup(`GetLocalizedString('InvalidLoadoutTitle'), `GetLocalizedString('NoItemsInLoadoutText'), eDialog_Warning);
		return;
	}

	SelectedLoadout = UIMechaListItem_LoadoutItem(List.GetSelectedItem());
	CachedNewLoadoutName = SelectedLoadout.Loadout.LoadoutName;

	kDialogData.strTitle = `GetLocalizedString('ConfirmOverwriteLoadoutTitle');
	kDialogData.eType = eDialog_Warning;
	kDialogData.strText = Repl(`GetLocalizedString('ConfirmOverwriteLoadoutText'), "%LoadoutName%", CachedNewLoadoutName);
	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;
	kDialogData.fnCallback = OnOverwriteLoadoutClickedCallback;
	Movie.Pres.UIRaiseDialog(kDialogData);
}

private function OnOverwriteLoadoutClickedCallback(Name eAction)
{
	local array<XComGameState_Item> ItemStates;

	if (eAction == 'eUIAction_Accept')
	{
		ItemStates = UIItemCard_Inventory(ItemCard).GetSelectedItems();
		class'X2LoadoutSafe'.static.SaveLoadut_Static(CachedNewLoadoutName, ItemStates);
		CloseScreen();
	}
}

private function OnCreateLoadoutClicked()
{
	local array<XComGameState_Item>	ItemStates;
	local TInputDialogData			kData;

	ItemStates = UIItemCard_Inventory(ItemCard).GetSelectedItems();
	if (ItemStates.Length == 0)
	{
		ShowInfoPopup(`GetLocalizedString('InvalidLoadoutTitle'), `GetLocalizedString('NoItemsInLoadoutText'), eDialog_Warning);
		return;
	}

	kData.strTitle = `CAPS(`GetLocalizedString('EnterLoadoutName'));
	kData.iMaxChars = 99;
	kData.strInputBoxText = `GetLocalizedString('PlaceholderLoadoutName');
	kData.fnCallback = OnCreateLoadoutInputBoxAccepted;

	Movie.Pres.UIInputDialog(kData);
}

simulated function CloseScreen()
{
	UIArmoryLoadoutScreen.Show();
	super.CloseScreen();
}

simulated function OnRemoved()
{
	if (EquipLoadoutButton != none) EquipLoadoutButton.Remove();
}
simulated function Show()
{
	super.Show();
	if (EquipLoadoutButton != none) EquipLoadoutButton.Show();
}

simulated function Hide()
{
	super.Hide();
	if (EquipLoadoutButton != none) EquipLoadoutButton.Hide();
}

private function OnCreateLoadoutInputBoxAccepted(string LoadoutName)
{
	local TDialogueBoxData			kDialogData;
	local array<string>				LoadoutNames;
	local array<XComGameState_Item> ItemStates;

	if (LoadoutName == "")
	{
		// No empty preset names
		ShowInfoPopup(`GetLocalizedString('InvalidLoadoutNameTitle'), `GetLocalizedString('InvalidLoadoutNameText'), eDialog_Warning);
		return;
	}

	LoadoutNames = class'X2LoadoutSafe'.static.GetLoadoutNames();
	if (LoadoutNames.Find(LoadoutName) != INDEX_NONE)
	{
		CachedNewLoadoutName = LoadoutName;

		kDialogData.strTitle = `GetLocalizedString('LoadoutAlreadyExistsTitle');
		kDialogData.eType = eDialog_Warning;
		kDialogData.strText = `GetLocalizedString('LoadoutAlreadyExistsText');
		kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
		kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;
		kDialogData.fnCallback = OnClickedCallback;
		Movie.Pres.UIRaiseDialog(kDialogData);
	}
	else
	{
		ItemStates = UIItemCard_Inventory(ItemCard).GetSelectedItems();
		class'X2LoadoutSafe'.static.SaveLoadut_Static(LoadoutName, ItemStates);
		CloseScreen();
	}
}

private function OnClickedCallback(Name eAction)
{
	local array<XComGameState_Item> ItemStates;

	if (eAction == 'eUIAction_Accept')
	{
		ItemStates = UIItemCard_Inventory(ItemCard).GetSelectedItems();
		class'X2LoadoutSafe'.static.SaveLoadut_Static(CachedNewLoadoutName, ItemStates);
		CloseScreen();
	}
}

private function ShowInfoPopup(string strTitle, string strText, optional EUIDialogBoxDisplay eType)
{
	local TDialogueBoxData kDialogData;

	kDialogData.strTitle = strTitle;
	kDialogData.strText = strText;
	kDialogData.eType = eType;
	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericOK;

	Movie.Pres.UIRaiseDialog(kDialogData);
}

simulated function SelectedItemChanged(UIList ContainerList, int ItemIndex)
{

	//local UIMechaListItem_Bounty ListItem;
	//local array<string> LoadoutNames;

	//ListItem = UIMechaListItem_Bounty(ContainerList.GetItem(ItemIndex));
	//if (ListItem != none)
	//{
	//	ItemCard.PopulateData(ListItem.GetBountyUnitName(), ListItem.GetBountyCard(), "" /*string Requirements*/, ListItem.GetBountyCardImage());
	//	DisplayAbilities(ListItem.BountyInfo.GrantedAbilities);
	//}
	//LoadoutNames = class'X2LoadoutSafe'.static.GetLoadoutNames();
	if (bForSaving)
	{
		//ItemCard.PopulateData(LoadoutNames[ItemIndex - 2], "wow loadout description", "", "");
		//UIItemCard_Inventory(ItemCard).PopulateLoadoutFromUnit(UnitState);
	}
	else
	{
		//ItemCard.PopulateData(LoadoutNames[ItemIndex - 1], "wow loadout description", "", "");
		//UIItemCard_Inventory(ItemCard).PopulateLoadoutCard();

		
	}
}

private function SelectListItem(const int ItemIndex)
{
	local UIMechaListItem_LoadoutItem ListItem;
	local int i;

	List.SetSelectedIndex(ItemIndex);

	for (i = 0; i < List.ItemCount; i++)
	{
		ListItem = UIMechaListItem_LoadoutItem(List.GetItem(i));
		if (ListItem != none)
		{
			if (i == ItemIndex)
			{
				ListItem.Checkbox.SetChecked(true, false);
				UIItemCard_Inventory(ItemCard).DisplayLoadout(ListItem.Loadout, UnitState);
			}
			else
			{
				ListItem.Checkbox.SetChecked(false, false);
			}
		}
	}
}

/*
private function DisplayAbilities(const out array<SoldierClassAbilityType> Abilities)
{
	local UIListItemAbility_Bounty	ListItem;
	local X2AbilityTemplateManager	AbilityMgr;
	local X2AbilityTemplate			AbilityTemplate;
	local SoldierClassAbilityType	AbilityType;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	LeftPanelBG = Spawn(class'UIBGBox', self);
    LeftPanelBG.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
    LeftPanelBG.InitBG('ShowLeftPanelText_LeftPanelText_BG');
	LeftPanelBG.SetPosition(default.LeftPanelX, default.LeftPanelY);
    LeftPanelBG.SetSize(default.LeftPanelW, default.LeftPanelH);

	 //setup the text panel to the same size and position
    LeftPanelText = Spawn(class'UIPanel', self);
	LeftPanelText.bAnimateOnInit = false;
    LeftPanelText.InitPanel('ShowLeftPanelText_LeftPanelText');
	LeftPanelText.SetPosition(default.LeftPanelX, default.LeftPanelY);
    LeftPanelText.SetSize(default.LeftPanelW, default.LeftPanelH);

	LeftPanelList = Spawn(class'UIList', self);
	LeftPanelList.InitList('List', default.LeftPanelX +10, default.LeftPanelY + 70, default.LeftPanelW -40, default.LeftPanelH -90, false, false, '' );
	LeftPanelList.ItemPadding = 8;
	LeftPanelList.bStickyHighlight = false; //so the elements only highlight when over
	LeftPanelBG.ProcessMouseEvents(LeftPanelList.OnChildMouseEvent);	//so the list scrolls

	//setup the text panel title
	LeftPanelTextHeader = Spawn(class'UIX2PanelHeader', LeftPanelText);
	LeftPanelTextHeader.bAnimateOnInit = false;
	LeftPanelTextHeader.InitPanelHeader('ShowLeftPanelText_LeftPanelTextTitle', "", "");
	LeftPanelTextHeader.SetHeaderWidth(LeftPanelText.Width - 20);
	LeftPanelTextHeader.bRealizeOnSetText = true;	//allows recolouring of the title
	LeftPanelTextHeader.SetText(class'UIUtilities_Text'.static.GetColoredText(class'XLocalizedData'.default.TacticalTextAbilitiesHeader, eUIState_Warning, 28), "");
	LeftPanelTextHeader.SetPosition(LeftPanelTextHeader.X + 10, LeftPanelTextHeader.Y + 10);

	//setup a 'linebreak'
	LeftPanelSplitLine = Spawn(class'UIPanel', LeftPanelText);
	LeftPanelSplitLine.InitPanel('', class'UIUtilities_Controls'.const.MC_GenericPixel);
    LeftPanelSplitLine.SetColor( class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR );
	LeftPanelSplitLine.SetSize( 420, 2 );
    LeftPanelSplitLine.SetAlpha( 15 );
	LeftPanelSplitLine.SetPosition(LeftPanelTextHeader.X + 5, LeftPanelTextHeader.Y + 40);

	i = 0;
	`AMLOG("Running for abilities:" @ Abilities.Length);
	foreach Abilities(AbilityType)
	{
		
		AbilityTemplate = AbilityMgr.FindAbilityTemplate(AbilityType.AbilityName);
		if (AbilityTemplate == none)
			continue;

		ListItem = UIListItemAbility_Bounty(LeftPanelList.GetItem(i++));
		if (ListItem == none)
		{
			ListItem = Spawn(class'UIListItemAbility_Bounty', LeftPanelList.ItemContainer);
			ListItem.InitListItemPerk();
		}

		ListItem.SetAbility(AbilityTemplate);
	}

	SetTimer(0.1f,, nameof(OnLeftPanelItemRealized), self);
	//OnLeftPanelItemRealized();
}
*/
//update list size elements
// (correct padding between list elements to account for ability description length)
/*
simulated function OnLeftPanelItemRealized()
{
	local UIListItemAbility_Bounty ListItem;
	local int i;

	for (i = 0 ; i < LeftPanelList.GetItemCount() ; i++)
	{
		ListItem = UIListItemAbility_Bounty(LeftPanelList.GetItem(i));
		if(!ListItem.bSizeRealized) 
		{
			SetTimer(0.1f,, nameof(OnLeftPanelItemRealized), self);
			return; 
		}
	}

	LeftPanelList.RealizeItems();
	LeftPanelList.RealizeList();
}*/

defaultproperties
{
	bIsIn3D = true
	DisplayTag = "UIBlueprint_Promotion"
	CameraTag = "UIBlueprint_Promotion"
}