class X2LoadoutSafe extends Object config(LoadoutManager);

var private config array<IRILoadoutStruct> Loadouts;

var private array<IRILoadoutStruct> BackupLoadouts;

const FilePath = "\\Documents\\my games\\XCOM2 War of the Chosen\\XComGame\\X2LoadoutManagerBackup.bin";

static final function SaveLoadut_Static(const string LoadoutName, const array<XComGameState_Item> ItemStates, XComGameState_Unit UnitState)
{
	local XComGameState_Item	ItemState;
	local IRILoadoutItemStruct	LoadoutItem;
	local IRILoadoutStruct		NewLoadout;
	local X2LoadoutSafe			Safe;
	local int Index;

	NewLoadout.LoadoutName = LoadoutName;
	NewLoadout.SoldierClass = UnitState.GetSoldierClassTemplateName();

	foreach ItemStates(ItemState)
	{	
		LoadoutItem.Item = ItemState.GetMyTemplateName();
		LoadoutItem.Slot = ItemState.InventorySlot;
		NewLoadout.LoadoutItems.AddItem(LoadoutItem);
	}

	Index = default.Loadouts.Find('LoadoutName', LoadoutName);
	if (Index != INDEX_NONE)
	{
		default.Loadouts[Index] = NewLoadout;
	}
	else
	{
		default.Loadouts.AddItem(NewLoadout);
	}

	StaticSaveConfig();

	Safe = LoadSafe();
	Safe.BackupLoadouts = default.Loadouts;
	SaveSafe(Safe);
}

static final function DeleteLoadut_Static(const string LoadoutName)
{
	local int Index;

	Index = default.Loadouts.Find('LoadoutName', LoadoutName);
	if (Index != INDEX_NONE)
	{
		default.Loadouts.Remove(Index, 1);
	}
	StaticSaveConfig();
}


static final function array<string> GetLoadoutNames()
{	
	local IRILoadoutStruct	Loadout;
	local array<string>		LoadoutNames;

	foreach default.Loadouts(Loadout)
	{
		LoadoutNames.AddItem(Loadout.LoadoutName);
	}

	return LoadoutNames;
}

static final function array<IRILoadoutStruct> GetLoadouts()
{
	return default.Loadouts;
}


static private function X2LoadoutSafe LoadSafe()
{
	local X2LoadoutSafe Safe;

	Safe = new class'X2LoadoutSafe';

	class'Engine'.static.BasicLoadObject(Safe, class'Engine'.static.GetEnvironmentVariable("USERPROFILE") $ FilePath, false, 1);

	return Safe;
}

static private function SaveSafe(X2LoadoutSafe Safe)
{
	class'Engine'.static.BasicSaveObject(Safe, class'Engine'.static.GetEnvironmentVariable("USERPROFILE") $ FilePath, false, 1);
}

static final function bool ShouldLoadBackup()
{
	local X2LoadoutSafe Safe;

	Safe = LoadSafe();

	return Safe.BackupLoadouts.Length > default.Loadouts.Length;
}

static final function RaiseLoadBackupPopup()
{
	local X2LoadoutSafe		Safe;
	local TDialogueBoxData	kDialogData;
	local string			PopupText;

	Safe = LoadSafe();

	kDialogData.strTitle = `GetLocalizedString('ConfirmDeleteLoadoutTitle');
	kDialogData.eType = eDialog_Warning;

	PopupText = `GetLocalizedString('ConfirmLoadBackup');
	PopupText = Repl(PopupText, "%CurrentNumLoadouts%", default.Loadouts.Length);
	PopupText = Repl(PopupText, "%BackupNumLoadouts%", Safe.BackupLoadouts.Length);

	kDialogData.strText = PopupText;
	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;
	kDialogData.fnCallback = OnLoadBackupClickedCallback;
	`PRESBASE.UIRaiseDialog(kDialogData);

	default.Loadouts = Safe.BackupLoadouts;
	StaticSaveConfig();
}

static private function OnLoadBackupClickedCallback(Name eAction)
{
	local X2LoadoutSafe Safe;

	if (eAction == 'eUIAction_Accept')
	{
		Safe = LoadSafe();
		default.Loadouts = Safe.BackupLoadouts;
		StaticSaveConfig();
	}
}
