class X2EventListener_MLM extends X2EventListener config(UI);

var config int ListItemWidth;

`include(WOTCIridarManualLoadoutManager\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	//if (!`ISCONTROLLERACTIVE)
	//{
		Templates.AddItem(SquadSelectListener());
	//}
	return Templates;
}

static function CHEventListenerTemplate SquadSelectListener()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'IRI_X2EventListener_MLM_SquadSelect');

	Template.RegisterInTactical = false;
	Template.RegisterInStrategy = true;

	Template.AddCHEvent('UISquadSelect_NavHelpUpdate', OnSquadSelectNavHelpUpdate, ELD_Immediate, 50);
	Template.AddCHEvent('rjSquadSelect_UpdateData', OnSquadSelectNavHelpUpdate, ELD_Immediate, 50);

	return Template;
}

static function EventListenerReturn OnSquadSelectNavHelpUpdate(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
	local UISquadSelect						SquadSelect;
	local UISquadSelect_ListItem			ListItem;
	local XComGameState_Unit				UnitState;
	local XComGameState_HeadquartersXCom	XComHQ;
	local XComGameStateHistory				History;
	local UIMechaListItem_LoadoutItem		Shortcut;
	local int j;

	if (!`GETMCMVAR(USE_SQUAD_SELECT_SHORTCUT))
		return ELR_NoInterrupt;

	SquadSelect = UISquadSelect(EventSource);
	if (SquadSelect == none)
	{
		// When running for 'rjSquadSelect_UpdateData'
		SquadSelect = UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect'));
	}
	if (SquadSelect == none)
		return ELR_NoInterrupt;

	`AMLOG("Running with Item Count:" @ SquadSelect.m_kSlotList.ItemCount @ "Total slots:" @ SquadSelect.GetTotalSlots());

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if (XComHQ == none)
		return ELR_NoInterrupt;

	if (SquadSelect.IsA('robojumper_UISquadSelect') || SquadSelect.m_kSlotList.ItemCount == 0) // Latter is an alternative chceck for RJSS in case some funny mod author reuploads RJSS with different class name.
	{
		for (j = 0; j < SquadSelect.GetTotalSlots(); ++j)
		{
			ListItem = UISquadSelect_ListItem(robojumper_UISquadSelect(SquadSelect).SquadList.GetItem(j));
			if (ListItem == none || ListItem.bDisabled || !ListItem.bIsVisible)
				continue;

			UnitState = robojumper_UISquadSelect_ListItem(ListItem).GetUnit();

			`AMLOG("Looking at soldier:" @ UnitState.GetFullName());

			// In RJSS, list items don't get init'ed instantly, and we need to check for a pre-existing shortcut.
			Shortcut = UIMechaListItem_LoadoutItem(ListItem.GetChildByName('IRI_MLM_LoadLoadout_SquadSelect_Shortcut', false));
			if (Shortcut != none)
			{
				if (UnitState == none)
				{
					Shortcut.Hide();
				}
				else
				{
					Shortcut.UpdateDataDescriptionShortcut(UnitState);
					Shortcut.SetWidth(default.ListItemWidth);
					Shortcut.Desc.SetWidth(Shortcut.Width - 10);
					Shortcut.Show();
				}
			}
			else if (UnitState != none)
			{
				Shortcut = ListItem.Spawn(class'UIMechaListItem_LoadoutItem', ListItem);
				Shortcut.InitListItem('IRI_MLM_LoadLoadout_SquadSelect_Shortcut').bAnimateOnInit = false;
				Shortcut.UpdateDataDescriptionShortcut(UnitState);
				Shortcut.SetWidth(default.ListItemWidth);
				Shortcut.Desc.SetWidth(Shortcut.Width - 10);

				Shortcut.SetY(ListItem.Height + robojumper_UISquadSelect_ListItem(ListItem).GetExtraHeight());
				ListItem.SetY(ListItem.Y - Shortcut.Height - 10);
			}			
		}
	}
	else
	{
		for (j = 0; j < SquadSelect.m_kSlotList.ItemCount; ++j)
		{
			ListItem = UISquadSelect_ListItem(SquadSelect.m_kSlotList.GetItem(j));
			if (ListItem == none || ListItem.bDisabled || !ListItem.bIsVisible)
				continue;

			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ListItem.GetUnitRef().ObjectID));

			`AMLOG("Looking at soldier:" @ UnitState.GetFullName());

			Shortcut = UIMechaListItem_LoadoutItem(ListItem.GetChildByName('IRI_MLM_LoadLoadout_SquadSelect_Shortcut', false));
			if (Shortcut != none)
			{
				if (UnitState == none)
				{
					Shortcut.Hide();
				}
				else
				{
					Shortcut.UpdateDataDescriptionShortcut(UnitState);
					Shortcut.SetWidth(default.ListItemWidth);
					Shortcut.Desc.SetWidth(Shortcut.Width - 10);
					Shortcut.Show();
				}
			}
			else if (UnitState != none)
			{
				Shortcut = ListItem.Spawn(class'UIMechaListItem_LoadoutItem', ListItem);
				Shortcut.InitListItem('IRI_MLM_LoadLoadout_SquadSelect_Shortcut').bAnimateOnInit = false;
				Shortcut.UpdateDataDescriptionShortcut(UnitState);
				Shortcut.SetWidth(default.ListItemWidth);
				Shortcut.Desc.SetWidth(Shortcut.Width - 10);

				Shortcut.SetY(362);
				ListItem.SetY(ListItem.Y - Shortcut.Height);
			}
		}
	}

	return ELR_NoInterrupt;
}