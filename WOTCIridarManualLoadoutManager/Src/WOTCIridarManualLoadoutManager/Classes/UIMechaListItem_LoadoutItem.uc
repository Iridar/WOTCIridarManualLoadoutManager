class UIMechaListItem_LoadoutItem extends UIMechaListItem;

// Used in several capacities.
// Overall, it's simply a UIMechaList item with some additional storage options.

var IRILoadoutStruct		Loadout;		// Used when displaying a list of loadouts in the UIScreen_Loadouts on the left.
var XComGameState_Item		ItemState;		// Used when displaying items equipped on the unit in the UIScreen_Loadouts on the right when saving a loadout.
var IRILoadoutItemStruct	LoadoutItem;	// Used when displaying items in a previously saved loadout in the UIScreen_Loadouts on the right when loading a loadout.
var XComGameState_Unit		UnitState;		// Used when displaying a "Load Loadout" shortcut in squad select.

// Bandaid fix for incoherent list width.
var int						ListItemWidthMod;

simulated function SetWidth(float NewWidth)
{
	NewWidth += ListItemWidthMod;

	super.SetWidth(NewWidth);

	if (BG != none) BG.SetWidth(NewWidth);
	if (Checkbox != none) Checkbox.SetX(NewWidth - 34);
	if (Desc != none) Desc.SetWidth(NewWidth - 36);
}

final function UpdateDataDescriptionShortcut(XComGameState_Unit _UnitState)
{
	UnitState = _UnitState;
	UpdateDataDescription(`GetLocalizedString('EquipLoadout'), OnEquipLoadoutShortcutClicked);
}

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

	SaveLoadout = HQPresLayer.Spawn(class'UIScreen_Loadouts', HQPresLayer);
	SaveLoadout.UnitState = UnitState;
	SaveLoadout.UIArmoryLoadoutScreen = ArmoryScreen;
	SaveLoadout.bCloseArmoryScreenWhenClosing = true;
	HQPresLayer.ScreenStack.Push(SaveLoadout, HQPresLayer.Get3DMovie());
}
/*
simulated function UIMechaListItem UpdateDataButton(string _Desc,
								 	 string _ButtonLabel,
								 	 delegate<OnButtonClickedCallback> _OnButtonClicked = none,
									 optional delegate<OnClickDelegate> _OnClickDelegate = none)
{
	SetWidgetType(EUILineItemType_Button);

	if (Button == none)
	{
		Button = Spawn(class'UIButton', self);
		Button.bAnimateOnInit = false;
		Button.bIsNavigable = false;
		Button.InitButton('ButtonMC', "", OnButtonClickDelegate);
		//Button.SetX(width - 150 - 25); // Added some offset
		Button.SetY(0);
		Button.SetHeight(34);
		Button.MC.SetNum("textY", 2);
		Button.OnSizeRealized = UpdateButtonX;
	}

	Button.SetText(_ButtonLabel);
	RefreshButtonVisibility();

	//Desc.SetWidth(width - 150 - 25); // Added some offset
	Desc.SetHTMLText(_Desc);
	Desc.Show();

	OnClickDelegate = _OnClickDelegate;
	OnButtonClickedCallback = _OnButtonClicked;

	return self;
}*/