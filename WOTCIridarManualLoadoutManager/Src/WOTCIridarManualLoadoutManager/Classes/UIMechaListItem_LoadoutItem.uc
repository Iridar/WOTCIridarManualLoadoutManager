class UIMechaListItem_LoadoutItem extends UIMechaListItem;

// Used in several capacities.
// Overall, it's simply a UIMechaList item with some additional storage options.

var IRILoadoutStruct		Loadout;		// Used when displaying a list of loadouts in the UIScreen_Loadouts on the left.
var XComGameState_Item		ItemState;		// Used when displaying items equipped on the unit in the UIScreen_Loadouts on the right when saving a loadout.
											// Used for storing the best replacement item in the displayed loadout in the ItemCard when loading a loadout.
var IRILoadoutItemStruct	LoadoutItem;	// Used when displaying items in a previously saved loadout in the UIScreen_Loadouts on the right when loading a loadout.
var XComGameState_Unit		UnitState;		// Used when displaying a "Load Loadout" shortcut in squad select.

// Bandaid fix for incoherent list width.
var int						ListItemWidthMod;

//var private UITextContainer	Tooltip;

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

	`AMLOG(UnitState.GetFullName() @ ArmoryScreen.GetUnit().GetFullName());

	SaveLoadout = HQPresLayer.Spawn(class'UIScreen_Loadouts', HQPresLayer);
	SaveLoadout.UnitState = UnitState;
	SaveLoadout.UIArmoryLoadoutScreen = ArmoryScreen;
	SaveLoadout.bCloseArmoryScreenWhenClosing = true;
	HQPresLayer.ScreenStack.Push(SaveLoadout, HQPresLayer.Get3DMovie());
}


/*
simulated function UIMechaListItem InitListItem(optional name InitName, optional int defaultWidth = -1, optional int textWidth = 250)
{
	super.InitListItem(InitName, defaultWidth, textWidth);

	Tooltip = Spawn(class'UITooltip', self); 
	Tooltip.InitTooltip('UITooltipInventoryItemInfo');

	Tooltip.bUsePartialPath = true;
	Tooltip.targetPath = string(MCPath); 
	//Tooltip.RequestItem = TooltipRequestItemFromPath; 

	Tooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( Tooltip );
	Tooltip.tDelay = 0; // instant tooltips!

	return self;
}


simulated function bool OnUnrealCommand(int cmd, int arg)
{
	

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
		ShowTooltip();
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
		HideTooltip();
		break;
	}
	return super.OnUnrealCommand(cmd, arg);
}
*/
/*
private function OnMouseEventFn(UIPanel Panel, int Cmd)
{
	`AMLOG(cmd);

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
		ShowTooltip();
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE:
		HideTooltip();
		break;
	}
}

private function ShowTooltip()
{
	`AMLOG(bHasTooltip);
	if (bHasTooltip)
	{
		Tooltip.Show();
		Tooltip.MoveToHighestDepth();

		Tooltip.text.Show();
		Tooltip.text.MoveToHighestDepth();
	}
}

private function HideTooltip()
{
	`AMLOG(bHasTooltip);
	if (bHasTooltip)
	{
		Tooltip.text.Hide();
		Tooltip.Hide();
	}
}

simulated function SetTooltipText(string Text, 
								  optional string Title,
								  optional float OffsetX,
								  optional float OffsetY, 
								  optional bool bRelativeLocation   = class'UITextTooltip'.default.bRelativeLocation,
								  optional int TooltipAnchor        = class'UITextTooltip'.default.Anchor, 
								  optional bool bFollowMouse        = class'UITextTooltip'.default.bFollowMouse,
								  optional float Delay              = class'UITextTooltip'.default.tDelay)
{
	bHasTooltip = true;
	OnMouseEventDelegate = OnMouseEventFn;

	Tooltip = Spawn(class'UITextContainer', self); 
	Tooltip.InitTextContainer('', Text, -310, 0, 300, 75, true,, true);
	//Tooltip.InitTextContainer('', Text, -310, 0, 300, 75, true, class'UIUtilities_Controls'.const.MC_X2Background, true);
	//Tooltip.SetHTMLText(class'UIUtilities_Text'.static.GetColoredText(, , 10));
	Tooltip.Hide();
}

*/


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