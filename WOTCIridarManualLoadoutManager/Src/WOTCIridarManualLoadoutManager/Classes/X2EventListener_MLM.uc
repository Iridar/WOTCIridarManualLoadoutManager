class X2EventListener_MLM extends X2EventListener config(UI);

var config int ListItemWidth;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(SquadSelectListener());

	return Templates;
}

static function CHEventListenerTemplate SquadSelectListener()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'IRI_X2EventListener_MLM_SquadSelect');

	Template.RegisterInTactical = false;
	Template.RegisterInStrategy = true;

	Template.AddCHEvent('UISquadSelect_NavHelpUpdate', OnSquadSelectNavHelpUpdate, ELD_Immediate, 50);
	
	return Template;
}

static function EventListenerReturn OnSquadSelectNavHelpUpdate(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
	local UISquadSelect						SquadSelect;
	local UISquadSelect_ListItem			ListItem;
	local array<UIPanel>					ChildrenPanels;
	local UIPanel							ChildPanel;
	local XComGameState_Unit				UnitState;
	local XComGameState_HeadquartersXCom	XComHQ;
	local XComGameStateHistory				History;
	local UIMechaListItem_LoadoutItem		Shortcut;

	SquadSelect = UISquadSelect(EventSource);
	if (SquadSelect == none)
		return ELR_NoInterrupt;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if (XComHQ == none)
		return ELR_NoInterrupt;

	SquadSelect.GetChildrenOfType(class'UISquadSelect_ListItem', ChildrenPanels);

	`AMLOG("Running");

	foreach ChildrenPanels(ChildPanel)
	{
		ListItem = UISquadSelect_ListItem(ChildPanel);
		//if (ListItem.SlotIndex < 0 || ListItem.SlotIndex > XComHQ.Squad.Length || XComHQ.Squad[ListItem.SlotIndex].ObjectID == 0)
		//	continue;

		if (ListItem.GetChildByName('IRI_MLM_LoadLoadout_SquadSelect_Shortcut') != none || ListItem.bDisabled)
			continue;

		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ListItem.GetUnitRef().ObjectID));
		//UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[ListItem.SlotIndex].ObjectID));
		if (UnitState == none)
			continue;

		`AMLOG("Looking at soldier:" @ UnitState.GetFullName());

		Shortcut = ListItem.Spawn(class'UIMechaListItem_LoadoutItem', ListItem);
		Shortcut.bAnimateOnInit = false;
		Shortcut.InitListItem('IRI_MLM_LoadLoadout_SquadSelect_Shortcut');
		Shortcut.UpdateDataDescriptionShortcut(UnitState);
		Shortcut.SetWidth(default.ListItemWidth);
		Shortcut.Desc.SetWidth(Shortcut.Width - 10);

		if (ListItem.IsA('robojumper_UISquadSelect_ListItem'))
		{
			Shortcut.SetY(ListItem.Height + robojumper_UISquadSelect_ListItem(ListItem).GetExtraHeight());
			ListItem.SetY(ListItem.Y - Shortcut.Height - 10);
		}
		else
		{
			Shortcut.SetY(362);
			ListItem.SetY(ListItem.Y - Shortcut.Height);
		}
	}
	return ELR_NoInterrupt;
}