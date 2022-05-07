EnableExplicit

Enumeration Window
  #Window_0
EndEnumeration

Enumeration Gadgets
  #ScrollArea_1
  #Checkbox_1
  #Option_1
  #Option_2
  #Combo_1
  #Editor_1
  #PickColor
EndEnumeration

XIncludeFile  "ObjectColor.pbi"     ; <== to Add
;XIncludeFile "JellyButtons.pbi"   ; Optional, to Add Nice Colored Buttons 

Procedure Open_Window_0(X = 0, Y = 0, Width = 440, Height = 300)
  If OpenWindow(#Window_0, X, Y, Width, Height, "Demo ObjectColor Simple", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    SetWindowColor(#Window_0, RGB(8, 8, 64))
    ScrollAreaGadget(#ScrollArea_1, 20, 20, 400, 200, 1200, 800, 10, #PB_ScrollArea_Flat)
      CheckBoxGadget(#Checkbox_1, 20, 10, 170, 30, "Checkbox_1")
      OptionGadget(#Option_1, 240, 10, 110, 30, "Option_1")
      OptionGadget(#Option_2, 240, 40, 110, 30, "Option_2")      
      ComboBoxGadget(#Combo_1, 20, 40, 170, 28, #CBS_HASSTRINGS | #CBS_OWNERDRAWFIXED)   ; <== Specific ComboBox, Add the 2 Constants for it to be drawn
        AddGadgetItem(#Combo_1, -1, "Combo_Element_1") : AddGadgetItem(#Combo_1, -1, "Combo_Element_2")
        SetGadgetState(#Combo_1, 0)
      EditorGadget(#Editor_1, 20, 80, 330, 80)
        AddGadgetItem(#Editor_1, -1, "Editor Line 1")
        AddGadgetItem(#Editor_1, -1, "Editor Line 2")
        AddGadgetItem(#Editor_1, -1, "Editor Line 3")
        CloseGadgetList()   ; #ScrollArea_1
        CompilerIf Defined(JellyButton, #PB_Procedure)
          JellyButton(#PickColor, 20, 230, 400, 50, "Choose Color", GetWindowColor(#Window_0), #White)
        CompilerElse
          ButtonGadget(#PickColor, 20, 230, 400, 50, "Choose Color")
        CompilerEndIf
    
    SetObjectColor()                    ; <== to Add
  EndIf
EndProcedure

Open_Window_0()

Repeat
  Select WaitWindowEvent()
    Case #PB_Event_CloseWindow
      Break
    Case #PB_Event_Gadget
      Select EventGadget()
        Case #PickColor
          SetWindowColor(#Window_0, ColorRequester(GetWindowColor(#Window_0)))
          SetObjectColor()
          ;Set_Jelly_Color(#PickColor, GetWindowColor(#Window_0))
      EndSelect
  EndSelect
ForEver

; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; Folding = -
; EnableXP