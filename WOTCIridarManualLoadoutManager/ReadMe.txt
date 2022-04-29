X2ModBuildCommon v1.2.1 successfully installed. 
Edit .scripts\build.ps1 if you want to enable cooking. 
 
Enjoy making your mod, and may the odds be ever in your favor. 
 
 
Created with Enhanced Mod Project Template v1.0 
 
Get news and updates here: 
https://github.com/Iridar/EnhancedModProjectTemplate 


TODO: 


Loadouts:
- File autobackup
- don't store ItemState in config, find better way
- delete button too big, too left, and obscures text
- figure out automatic list item size realization maybe
- tooltips are broken again.
- use slot maps in GetDisabledReason(). One for loadout, one for soldier, adjusted by armor in the loadout.

Squad item list:
- max. height and scrolling.

localization pass
mod preview image

One day:
improve slot counting logic via slot map
PCS support
Weapon Upgrade support
IAM integration
XSkin integration?
Use Tac Armory UI inventory images
Different layout so there's more space for the soldier's inventory list
Hide shortcut when removing a soldier from squad in vanilla squad select
Replace IsWeaponAllowedByClass by IsWeaponAllowedByClass_CH

KNOWN ISSUES
When using vanilla squad select, the EQUIP LOADOUT shortcut will remain on screen even after the soldier is removed from that slot.