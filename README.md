# ObjectColor - Dark-Mode
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/donate/?cmd=_s-xclick&hosted_button_id=9WZ5EDAMPH6SE)

Set Gadget Background and Text Colors automatically based on the window's color or parent container's color.<br>
<br>
**PureBasic, Windows only**<br><br>
![Alt text](/Object-Color-Demo.png?raw=true "Object-Color-Demo")<br>
<br>
**Supported gadget:** Calendar, CheckBox, ComboBox, Container, Date, Editor, ExplorerList, ExplorerTree, Frame, HyperLink, ListIcon, ListView, Option, Panel, ProgressBar, ScrollArea, Spin, String, Text, TrackBar, Tree<br><br>
**Notes:** For the ComboBoxGadget, #CBS_HASSTRINGS and #CBS_OWNERDRAWFIXED must be added at Combobox creation time<br> 
   ex: ComboBoxGadget(#Gasdget,X,Y,W,H,#CBS_HASSTRINGS|#CBS_OWNERDRAWFIXED)<br>
   To receive its events in the Window Callback and be drawn with the chosen colors.<br>
<br>
**For ButtonGadget**, you can use JellyButtons.pbi to get nice colored buttons. It is included in [IceDesign GUI Designer](https://github.com/ChrisRfr/IceDesign)<br>
<br><br>
**__Usage:__**<br>
<br>
Add: XIncludeFile ObjectColor.pbi<br>
Add: SetWindowCallback(@WinCallback()[, #Window]) to associates a callback to all open windows or for a specific window only.<br>
 - **SetDarkTheme()**     : Enable DarkMode_Explorer Theme (> Windows 10) for: Editor, ExplorerList, ExplorerTree, ListIcon, ListView, ScrollArea, ScrollBar, Tree<br> 
 - **SetExplorerTheme()** : Enable Explorer Theme (> Vista) for the same Gadgets<br><br>
 - **SetObjectColorType([Type.s])**<br>
> Type:<br>
>  -- Without Type for all supported Gadget. It is done automatically if SetObjectColorType() is not used.<br>
>  -- "NoEdit" for all supported Gadget except String and Editor.<br>
> -- "ColorStatic" for CheckBox, Frame, Option and TrackBar only (WM_CTLCOLORSTATIC).<br>
> -- 1 or multiple #PB_GadgetType_xxxxx separated by comma. The parameter is a String, so between quotes. Ex: SetObjectColorType("#PB_GadgetType_CheckBox, #PB_GadgetType_Option").<br><br>
 - **SetObjectColor([#Window, #Gadget, BackColor, TextColor])**<br>
> #Window:<br>
>  -- #PB_All = All Window (Default).<br>
>  -- The Window number to use.<br><br>
> #Gadget:<br>
>  -- #PB_All = All Supported Gadgets (Default).<br>
>  -- The Gadget number to use.<br><br>
> BackColor:<br>
>  -- #PB_Auto = Same as parent container's color (Default).<br>
>  -- The new backgound color. RGB() can be used to get a valid color value.<br>
>  -- #PB_Default = to go back to the default system backgound color.<br><br>
> TextColor:<br>
>  -- #PB_Auto = White or Black depending on whether the background color is dark or light (Default).<br>
>  -- The new text color. RGB() can be used to get a valid color value.<br>
>  -- #PB_Default = to go back to the default system text color.<br><br>
For all gadgets with automatic background color and text color use: SetObjectColor()
