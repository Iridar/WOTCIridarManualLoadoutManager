class X2LoadoutSafe extends Object;

var private array<IRILoadoutStruct> Loadouts;

const FilePath = "\\Documents\\my games\\XCOM2 War of the Chosen\\XComGame\\X2ManualLoadoutManager.bin";

static final function SaveLoadut_Static(const string LoadoutName, const array<XComGameState_Item> ItemStates, XComGameState_Unit UnitState)
{
	local X2LoadoutSafe Safe;

	Safe = LoadSafe();
	Safe.SaveLoadout(LoadoutName, ItemStates, UnitState);
	Safe.SaveSafe();
}

static final function DeleteLoadut_Static(const string LoadoutName)
{
	local X2LoadoutSafe Safe;

	Safe = LoadSafe();
	Safe.DeleteLoadout(LoadoutName);
	Safe.SaveSafe();
}

static private function X2LoadoutSafe LoadSafe()
{
	local X2LoadoutSafe Safe;

	Safe = new class'X2LoadoutSafe';

	class'Engine'.static.BasicLoadObject(Safe, class'Engine'.static.GetEnvironmentVariable("USERPROFILE") $ FilePath, false, 1);

	return Safe;
}

private function SaveSafe()
{
	local X2LoadoutSafe Safe;

	Safe = self;

	class'Engine'.static.BasicSaveObject(Safe, class'Engine'.static.GetEnvironmentVariable("USERPROFILE") $ FilePath, false, 1);
}

static final function array<string> GetLoadoutNames()
{	
	local X2LoadoutSafe Safe;
	local IRILoadoutStruct Loadout;
	local array<string> LoadoutNames;

	Safe = LoadSafe();
	foreach Safe.Loadouts(Loadout)
	{
		LoadoutNames.AddItem(Loadout.LoadoutName);
	}

	return LoadoutNames;
}

static final function array<IRILoadoutStruct> GetLoadouts()
{	
	local X2LoadoutSafe Safe;

	Safe = LoadSafe();
	return Safe.Loadouts;
}

private function SaveLoadout(const string LoadoutName, array<XComGameState_Item> ItemStates, XComGameState_Unit UnitState)
{
	local XComGameState_Item	ItemState;
	local IRILoadoutItemStruct	LoadoutItem;
	local IRILoadoutStruct		NewLoadout;
	local int Index;

	NewLoadout.LoadoutName = LoadoutName;
	NewLoadout.SoldierClassTemplate = UnitState.GetSoldierClassTemplateName();

	foreach ItemStates(ItemState)
	{	
		LoadoutItem.TemplateName = ItemState.GetMyTemplateName();
		LoadoutItem.InventorySlot = ItemState.InventorySlot;
		NewLoadout.LoadoutItems.AddItem(LoadoutItem);
	}

	Index = Loadouts.Find('LoadoutName', LoadoutName);
	if (Index != INDEX_NONE)
	{
		Loadouts[Index] = NewLoadout;
	}
	else
	{
		Loadouts.AddItem(NewLoadout);
	}
}


private function DeleteLoadout(const string LoadoutName)
{
	local int Index;

	Index = Loadouts.Find('LoadoutName', LoadoutName);
	if (Index != INDEX_NONE)
	{
		Loadouts.Remove(Index, 1);
	}
}
