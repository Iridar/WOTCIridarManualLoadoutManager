TODO: 

mod preview image

One day:
preview loadout changes
PCS support
Weapon Upgrade support
IAM integration
XSkin integration?
Hide shortcut when removing a soldier from squad in vanilla squad select
Replace IsWeaponAllowedByClass by IsWeaponAllowedByClass_CH
Special handle grenade pocket to allow equipping the grenade into utility slot, if one is available


[WOTC] Iridar's Loadout Manager

Adds new functionality to Loadout and Squad Select screens to save and equip units' loadouts.

[h1]Loadout Screen[/h1]

Adds two buttons to the armory Loadout screen:

[b]Save Loadout[/b] - clicking this button will bring you to the Save Loadout screen, where you will see the list of previously saved loadouts on the left, and the list of items currently equipped on the unit on the right. You can toggle checkboxes near each item to decide whether you want to save that particular item in the loadout. Then you can click the top element in the loadout list to save it as a new loadout, or you can click an existing loadout to overwrite it. You can also delete previously saved loadouts on this screeen.

When entering loadout name, it's highly recommended that you use only English letters, numbers and empty spaces. Avoid fancy characters like quotes or slashes.

[b]Equip Loadout[/b] - clicking this button will bring you to the Equip Loadout screen, where you will see the list of previously saved loadouts on the left, and the list of items contained in the currently selected loadout on the right. You can toggle checkboxes near each item to decide whether you want to equip that particular item on the unit. Then you can click the "equip loadout" button at the bottom of the screen to equip the selected items.

If the item saved in the loadout is not currently available, the mod may attempt to suggest a replacement item.

If there are any issues with loadout items, the item name will be highlighted in a different color, and you can put your mouse over the item to display a tooltip that will explain the issue.

[b]Filters and Search[/b] - both Save Loadout and Equip Loadout screens have a button in the lower right corner that can be used to cycle through different loadout filters. You can filter loadouts by soldier class, by weapon restrictions, or disable the filter entirely to see all of the loadouts. Near the Filters button there is a Search button, which can be used to filter out loadouts by loadout name.

[h1]Squad Select[/h1]

[b]Equip Loadout[/b] button is added under each soldier's panel on the Squad Select screen. Known issue: when not using robojumper's Squad Select, the "Equip Loadout" button may linger under the soldier panel even after the soldier is removed from the squad.

[b]Squad Items[/b] button is added to the top middle part of the screen. Clicking it will toggle the list of all items equipped on the entire squad, so you can check at a glance how many medikits you have on the mission, or whatever.

[h1]REQUIREMENTS[/h1]
[list]
[*] [url=https://steamcommunity.com/workshop/filedetails/?id=1134256495][b]X2 WOTC Community Highlander[/b][/url] is required.
[*] [url=https://steamcommunity.com/sharedfiles/filedetails/?id=667104300][b][WotC] Mod Config Menu[/b][/url] is supported, but not a hard requirement.
[*]Safe to add or remove mid-campaign.[/list]

[h1]COMPATIBILITY[/h1]

[url=https://steamcommunity.com/sharedfiles/filedetails/?id=1882809714][b][WOTC] Automated Loadout Manager[/b][/url] - these two mods are technically compatible, but they add new buttons into the same place on the Armory Loadout screen, so you would have to reposition them manually through config.

Other than that, should be compatible with anything and everything.

[h1]CONFIGURATION[/h1]

Many of the mod's features are configurable through Mod Config Menu.

[code]Positioning of some of the UI elements:
..\steamapps\workshop\content\268500\2664422411\Config\XComUI.ini

Default MCM settings:
..\steamapps\workshop\content\268500\2664422411\Config\XComWOTCIridarManualLoadoutManager_DEFAULT.ini

You might want to back up these files when deleting User Config folder:

MCM settings:
..\Documents\my games\XCOM2 War of the Chosen\XComGame\Config\XComWOTCIridarManualLoadoutManager.ini

Saved loadouts:
..\Documents\my games\XCOM2 War of the Chosen\XComGame\Config\XComLoadoutManager.ini[/code]

[h1]Automated Backups[/h1]

Since saved loadouts are stored in a config file, and deleting the User Config folder is a common troubleshooting step, in order to protect you from accidentally deleting your loadouts, the mod automatically backs them up into a binary file:
[code]..\Documents\my games\XCOM2 War of the Chosen\XComGame\X2LoadoutManagerBackup.bin[/code]

The backup is saved every time you save a loadout. When you start the game after a config wipe, you will get a popup message asking whether you want to restore saved loadouts from backup.

[h1]CREDITS[/h1]

Code responsible for displaying fancy inventory images copied from Tactical Armory UI by [b]Musashi[/b].
Thanks to [b]Xymanek (Astral Descend)[/b] for consultations and controller support.
Shoutout to [b][url=https://www.twitch.tv/beagsandjam/videos/all]Beaglerush[/url][/b] for showcasing this mod during his streams.

Please [b][url=https://www.patreon.com/Iridar]support me on Patreon[/url][/b] if you require tech support, have a suggestion for a feature, or simply wish to help me create more awesome mods.