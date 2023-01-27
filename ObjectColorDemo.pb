;- Top
; -------------------------------------------------------------------------------------------------
;        Name: ObjectColorDemo.pb
; Description: It uses "ObjectColor.pbi" to Set Gadget Background and Text Colors automatically based on the window's color or parent container's color.
;              Using #PB_Auto as a parameter for the background color, it automatically uses the parent container's color.
;              Using #PB_Auto as a parameter for the text color, it uses white or black color depending on the color of the parent container, light or dark.
;      Author: ChrisR
;        Date: 2023-01-24
;  PB-Version: 5.73 6.0 x64/x86
;          OS: Windows only
;       Forum: https://www.purebasic.fr/english/viewtopic.php?t=78966
; -------------------------------------------------------------------------------------------------
; More informations and usage ObjectColor.pbi header
; -------------------------------------------------------------------------------------------------

EnableExplicit

;- ---> Add XIncludeFile "ObjectColor.pbi"
XIncludeFile "ObjectColor.pbi"

; Uncomment to Test with nice colored buttons. JellyButtons.pbi must be next to
;XIncludeFile "JellyButtons.pbi"

UsePNGImageDecoder()

Enumeration Window
  #Window_1
  #Window_2
EndEnumeration

Enumeration Gadgets
  #Cont_1
  #Txt_2
  #Check_1
  #Opt_1
  #Opt_2
  #Edit_1
  #ExpList_1
  #ExpTree_1
  #Date_1
  #Frame_1
  #ListIcon_1
  #ListView_1
  #Hyper_1
  #Progres_1
  #Spin_1
  #String_1
  #Txt_1
  #Scrlbar_1
  #Splitter_1
  #Track_1
  #Tree_1
  #String_2
  #Panel_1
  #ScrlArea_1
  #Cont_2
  #Calend_1
  #Combo_1
  #Combo_2
  #Combo_3
  #PickColor_1
  #PickColor_2
EndEnumeration

Enumeration Font
  #Font
EndEnumeration

LoadFont(#Font, "Segoe UI Semibold", 10)

Enumeration Image
  #Imag
EndEnumeration

LoadImage(#Imag, #PB_Compiler_Home + "examples/sources/Data/world.png")

Define Color, I

Procedure ProgressBarDemo(Gadget)
  ProcedureReturnIf(GadgetType(Gadget) <> #PB_GadgetType_ProgressBar)
  Protected I
  For I = 0 To 100
    SetGadgetState(Gadget, I)
    Delay(10)
  Next
  SetGadgetState(Gadget, 66)
EndProcedure

Procedure Open_Window_1(X = 20, Y = 20, Width = 580, Height = 450)
  Protected I
  If OpenWindow(#Window_1, X, Y, Width, Height, "Demo ObjectColor Window_1", #PB_Window_MinimizeGadget | #PB_Window_SystemMenu)
    SetWindowColor(#Window_1, $080820)
    
    CompilerIf Defined(JellyButton, #PB_Procedure)
      JellyButton(#PickColor_1, 20, 380, 540, 50, "Choose Color Window_1", $040416, #White, #PB_Button_Default)
    CompilerElse
      ButtonGadget(#PickColor_1, 20, 380, 540, 50, "Choose Color Window_1", #PB_Button_Default)
    CompilerEndIf
    
    ContainerGadget(#Cont_1, 20, 20, 320, 70, #PB_Container_Flat)
    TextGadget(#Txt_2, 5, 5, 150, 20, "Container")
    CheckBoxGadget(#Check_1, 20, 20, 130, 30, "Disable Gadgets")
    OptionGadget(#Opt_1, 170, 10, 130, 24, "Option_1")
    OptionGadget(#Opt_2, 170, 35, 130, 24, "Option_2")
    CloseGadgetList()   ; #Cont_1
    
    EditorGadget(#Edit_1, 360, 20, 200, 60)
    For I = 1 To 5 : AddGadgetItem(#Edit_1, -1, "Editor Line " + Str(I)) : Next
    ListIconGadget(#ListIcon_1, 360, 90, 200, 80, "ListIcon", 120)
    AddGadgetColumn(#ListIcon_1, 1, "Column 2", 140)
    For I = 1 To 5 : AddGadgetItem(#ListIcon_1, -1, "ListIcon Element " + Str(I) +Chr(10)+ "Column 2 Element " + Str(I)) : Next
    SplitterGadget(#Splitter_1, 360, 20, 200, 150, #Edit_1, #ListIcon_1, #PB_Splitter_Separator)
    SetGadgetState(#Splitter_1, 70)
    
    FrameGadget(#Frame_1, 20, 100, 150, 60, "Frame_1");  : DisableGadget(#Frame_1, #True)
    TextGadget(#Txt_1, 40, 125, 100, 20, "This is a Text"); : DisableGadget(#Txt_1, #True)
    HyperLinkGadget(#Hyper_1, 190, 100, 150, 20, "https://www.purebasic.com/", RGB(0,0,128), #PB_HyperLink_Underline)
    DateGadget(#Date_1, 190, 130, 110, 30, "%yyyy-%mm-%dd", 0)
    CalendarGadget(#Calend_1, 20, 180, 240, 180)
    
    PanelGadget(#Panel_1, 280, 180, 280, 180)
    AddGadgetItem(#Panel_1, -1, "Tab_0", ImageID(#Imag))
    ProgressBarGadget(#Progres_1, 20, 20, 160, 16, 0, 100)
    SetGadgetState(#Progres_1, 66)
    SpinGadget(#Spin_1, 20, 56, 80, 26, 0, 100, #PB_Spin_Numeric)
    SetGadgetState(#Spin_1, 66)
    StringGadget(#String_1, 110, 56, 150, 26, "String_1")
    
    ComboBoxGadget(#Combo_1, 20, 102, 180, 28, #PB_ComboBox_Editable | #CBS_HASSTRINGS | #CBS_OWNERDRAWFIXED)
    SendMessage_(GadgetID(#Combo_1), #CB_SETMINVISIBLE, 5, 0)   ; Only 5 elements visible to display the ScrollBar for the Dark or Explorer theme
    For I = 1 To 10 : AddGadgetItem(#Combo_1, -1, "Combo Editable Element " + Str(I)) : Next
    SetGadgetState(#Combo_1, 0)
    
    AddGadgetItem(#Panel_1, -1, "Tab_1", ImageID(#Imag))
    AddGadgetItem(#Panel_1, -1, "Tab_2", ImageID(#Imag))
    CloseGadgetList()   ; #Panel_1
  EndIf
EndProcedure

Procedure Open_Window_2(X = 620, Y = 20, Width = 420, Height = 450)
  Protected I
  If OpenWindow(#Window_2, X, Y, Width, Height, "Demo ObjectColor Window_2", #PB_Window_MinimizeGadget | #PB_Window_SystemMenu)
    SetWindowColor(#Window_2, $180204)
    
    CompilerIf Defined(JellyButton, #PB_Procedure)
      JellyButton(#PickColor_2, 20, 380, 380, 50, "Choose Color Window_2", $180204, #White, #PB_Button_Default)
    CompilerElse
      ButtonGadget(#PickColor_2, 20, 380, 380, 50, "Choose Color Window_2", #PB_Button_Default)
    CompilerEndIf
    
    ExplorerTreeGadget(#ExpTree_1, 20, 20, 180, 60, "")
    ExplorerListGadget(#ExpList_1, 220, 20, 180, 100, "")
    ListViewGadget(#ListView_1, 20, 100, 180, 60)
    For I = 1 To 5 : AddGadgetItem(#ListView_1, -1, "ListView Element " + Str(I)) : Next
    
    ComboBoxGadget(#Combo_2, 220, 132, 180, 28, #PB_ComboBox_Image)   ; Partially Draw, only the selected item and not the list item 
    SendMessage_(GadgetID(#Combo_2), #CB_SETMINVISIBLE, 5, 0)         ; Does not work here ComboBox_Image! else Only 5 elements visible to display the ScrollBar for the Dark or Explorer theme
    For I = 1 To 10 : AddGadgetItem(#Combo_2, -1, "Combo Image Elem " + Str(I), ImageID(#Imag)) : Next
    SetGadgetState(#Combo_2, 0)
    
    ScrollAreaGadget(#ScrlArea_1, 20, 180, 380, 180, 540, 300, 10, #PB_ScrollArea_Flat)
    ContainerGadget(#Cont_2, 10, 15, 340, 50, #PB_Container_Flat)
    TrackBarGadget(#Track_1, 10, 10, 150, 30, 0, 100)
    SetGadgetState(#Track_1, 66)
    ScrollBarGadget(#Scrlbar_1, 170, 10, 150, 20, 0, 100, 10)
    CloseGadgetList()   ; #Cont_2
    TreeGadget(#Tree_1, 10, 80, 180, 60)
    AddGadgetItem(#Tree_1, -1, "Element 1", 0,  0)
    AddGadgetItem(#Tree_1, -1, "Node", 0,  0)
    AddGadgetItem(#Tree_1, -1, "Sub-element", 0,  1)
    AddGadgetItem(#Tree_1, -1, "Element 2", 0,  0)
    SetGadgetItemState(#Tree_1, 1, #PB_Tree_Expanded)
    StringGadget(#String_2, 200, 80, 150, 25, "String_2")
    
    ComboBoxGadget(#Combo_3, 200, 112, 150, 28, #CBS_HASSTRINGS | #CBS_OWNERDRAWFIXED)
    SendMessage_(GadgetID(#Combo_3), #CB_SETMINVISIBLE, 5, 0)   ; Only 5 elements visible to display the ScrollBar for the Dark or Explorer theme
    For I = 1 To 10 : AddGadgetItem(#Combo_3, -1, "Combo Element " + Str(I)) : Next
    SetGadgetState(#Combo_3, 0)
    
    CloseGadgetList()   ; #ScrlArea_1
  EndIf
EndProcedure

; Uncomment for Testing with a Font 
;       SetGadgetFont(#PB_Default, FontID(#Font))

Open_Window_1()
;Open_Window_2()  ; Window_2 is opened at the 1st closing of Window_1, to test with a second SetObjectColor() call, enumeration

;- ---> Add Optional SetObjectColorType() 
;       SetObjectColorType()                                                   ; All supported Gadget. Done by default if no other SetObjectColorType done
;       SetObjectColorType("NoEdit")                                           ; All supported Gadget Except String and Editor
;       SetObjectColorType("ColorStatic")                                      ; CheckBox, Frame, Option and TrackBar only
;       SetObjectColorType("#PB_GadgetType_CheckBox, #PB_GadgetType_Option")   ; Parameter is a String, so between Quotes. With #PB_GadgetType_xxxxx separated by Commas

;- ---> Add SetObjectColor()
SetObjectColor()

; Uncomment for Testing other Color, Text Color, Container with Childs Colors
;       SetObjectColor(#PB_All, #PB_All, #PB_Auto, #Red)                       ; Text Color in Red
;       SetObjectColor(#Window_1, #PB_All, $200820)                            ; If the background color is defined (Not #PB_Auto), SetWindowColor(#Window, Color) is done
;       SetObjectColor(#PB_All, #Cont_1, $3A3A52)                              ; Container with a custom Background Color
;       SetObjectColor(#PB_All, #Panel_1, $3A3A52, #Green)                     ; Panel with a custom Background Color and Text Color

Repeat
  Select WaitWindowEvent()
    Case #PB_Event_CloseWindow
      If Not IsWindow(#Window_2)
        Open_Window_2()
        SetObjectColor(#Window_2)
        SetObjectColor(#Window_2, #ScrlArea_1, $D8BABA, #Blue)                 ; #ScrlArea_1 with a Light Background Color and a Blue Text Color
        SetDarkTheme(#ScrlArea_1)                                              ; Apply the Dark Theme for the ScrollBars color 
      Else
        Break
      EndIf
      
    Case #PB_Event_Gadget
      Select EventGadget()
        Case #Check_1                             ; For Testing Disabled Gadgets
          If IsWindowEnabled_(GadgetID(#Txt_1))
            ;DisableGadget(#Cont_1, #True)
            DisableGadget(#Txt_1, #True) : DisableGadget(#Txt_2, #True) : DisableGadget(#Opt_1, #True) : DisableGadget(#Opt_2, #True) : DisableGadget(#Edit_1, #True)
            DisableGadget(#Date_1, #True) : DisableGadget(#Frame_1, #True) : DisableGadget(#ListIcon_1, #True) : DisableGadget(#Hyper_1, #True)
            DisableGadget(#Progres_1, #True) : DisableGadget(#Spin_1, #True) : DisableGadget(#String_1, #True) : DisableGadget(#Splitter_1, #True)
            DisableGadget(#Panel_1, #True) : DisableGadget(#Calend_1, #True) : DisableGadget(#Combo_1, #True) : DisableGadget(#PickColor_1, #True)
            If IsWindow(#Window_2)
              DisableGadget(#ExpList_1, #True) : DisableGadget(#ExpTree_1, #True) : DisableGadget(#ListView_1, #True) : DisableGadget(#Combo_2, #True)
              DisableGadget(#ScrlArea_1, #True) : DisableGadget(#Cont_2, #True) : DisableGadget(#Track_1, #True) : DisableGadget(#Scrlbar_1, #True)
              DisableGadget(#Tree_1, #True) : DisableGadget(#String_2, #True) : DisableGadget(#Combo_3, #True) : DisableGadget(#PickColor_2, #True)
            EndIf
          Else
            ;DisableGadget(#Cont_1, #False)
            DisableGadget(#Txt_1, #False) : DisableGadget(#Txt_2, #False) : DisableGadget(#Opt_1, #False) : DisableGadget(#Opt_2, #False) : DisableGadget(#Edit_1, #False)
            DisableGadget(#Date_1, #False) : DisableGadget(#Frame_1, #False) : DisableGadget(#ListIcon_1, #False) : DisableGadget(#Hyper_1, #False)
            DisableGadget(#Progres_1, #False) : DisableGadget(#Spin_1, #False) : DisableGadget(#String_1, #False) : DisableGadget(#Splitter_1, #False)
            DisableGadget(#Panel_1, #False) : DisableGadget(#Calend_1, #False) : DisableGadget(#Combo_1, #False) : DisableGadget(#PickColor_1, #False)
            If IsWindow(#Window_2)
              DisableGadget(#ExpList_1, #False) : DisableGadget(#ExpTree_1, #False) : DisableGadget(#ListView_1, #False) : DisableGadget(#Combo_2, #False)
              DisableGadget(#ScrlArea_1, #False) : DisableGadget(#Cont_2, #False) : DisableGadget(#Track_1, #False) : DisableGadget(#Scrlbar_1, #False)
              DisableGadget(#Tree_1, #False) : DisableGadget(#String_2, #False) : DisableGadget(#Combo_3, #False) : DisableGadget(#PickColor_2, #False)
            EndIf
          EndIf
          
        Case #PickColor_1
          Color = ColorRequester(GetWindowColor(#Window_1))
          SetWindowColor(#Window_1, Color)
          SetObjectColor(#Window_1)
          ; Uncomment for Testing other Color for Containers
          ;      If IsDarkColorOC(Color)
          ;        Color = AccentColorOC(Color, 50)
          ;      Else
          ;        Color = AccentColorOC(Color, -50)
          ;      EndIf
          ;      SetObjectColor(#Window_1, #Cont_1, Color)
          ;      SetObjectColor(#Window_1, #Panel_1, Color, #Blue)
          ; ProgressBarDemo(#Progres_1)
          
        Case #PickColor_2
          Color = ColorRequester(GetWindowColor(#Window_2))
          SetWindowColor(#Window_2, Color)
          SetObjectColor(#Window_2)
          ; Uncomment for Testing other Color for Containers
          ;      If IsDarkColorOC(Color)
          ;        Color = AccentColorOC(Color, 50)
          ;      Else
          ;        Color = AccentColorOC(Color, -50)
          ;      EndIf
          ;      SetObjectColor(#Window_2, #ScrlArea_1, Color)
          ;      SetObjectColor(#Window_2, #Cont_2, GetWindowColor(#Window_2))
          ;      SetObjectColor(#Window_2, #Tree_1, GetWindowColor(#Window_2), #Red)
          
      EndSelect
  EndSelect
ForEver 

; IDE Options = PureBasic 6.00 LTS (Windows - x64)
; EnableXP
; DPIAware