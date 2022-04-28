class X2LoadoutSafe extends Object config(LoadoutManager);

var private config array<IRILoadoutStruct> Loadouts;

//const FilePath = "\\Documents\\my games\\XCOM2 War of the Chosen\\XComGame\\X2ManualLoadoutManager.bin";

static final function SaveLoadut_Static(const string LoadoutName, const array<XComGameState_Item> ItemStates, XComGameState_Unit UnitState)
{
	local XComGameState_Item	ItemState;
	local IRILoadoutItemStruct	LoadoutItem;
	local IRILoadoutStruct		NewLoadout;
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


/*
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
*/