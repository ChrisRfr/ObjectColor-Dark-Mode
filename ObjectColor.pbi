;- Top
; -------------------------------------------------------------------------------------------------
;        Name: ObjectColor.pbi
; Description: Set the Gadget Background and Text Colors automatically based on the window's color or parent container's color.
;              Using #PB_Auto as a parameter for the background color, it automatically uses the parent container's color.
;              Using #PB_Auto as a parameter for the text color, it uses white or black color depending on the color of the parent container, light or dark.
;              The theme "Explorer" or "DarkMode_Explorer" (Windows 10 and up) is automatically applied according to the background color of each Gadget for
;                  ComboBox, Editor, ExplorerList, ExplorerTree, ListIcon, ListView, ScrollArea, ScrollBar, Tree
;      Author: ChrisR
;     Version: 1.5.1
;        Date: 2024-05-02   (Creation Date: 2022-04-14)
;  PB-Version: 5.73 - 6.10 x64/x86
;          OS: Windows only
;      Credit: PB Forum, Rashad for his help: ComboBox WM_DRAWITEM example, Colored ListIcon Header,...
;       Forum: https://www.purebasic.fr/english/viewtopic.php?t=78966
; -------------------------------------------------------------------------------------------------
; Supported gadget: Canvas Container, Calendar, CheckBox, ComboBox, Container, Date, Editor, ExplorerList, ExplorerTree, Frame, HyperLink, ListIcon, ListView,
;            Option, Panel, ProgressBar, ScrollArea, Spin, Splitter, String, Text, TrackBar, Tree
;
; Notes: For the ComboBoxGadget, #CBS_HASSTRINGS and #CBS_OWNERDRAWFIXED must be added at Combobox creation time, ex: ComboBoxGadget(#Combo,X,Y,W,H,#CBS_HASSTRINGS|#CBS_OWNERDRAWFIXED)
;        To receive its events in the Window Callback and be drawn with the chosen colors.
;        It does not work for ComboBox with #PB_ComboBox_Image constant, in this case do Not add the constants #CBS_HASSTRINGS|#CBS_OWNERDRAWFIXED
;
; For ButtonGadget, you can use JellyButtons.pbi to get nice colored buttons. It is included in IceDesign GUI Designer.
;
; -------------------------------------------------------------------------------------------------
; Add: XIncludeFile "ObjectColor.pbi"
;
;- Usages:
;
;   SetObjectColor([#Window, #Gadget, BackColor, TextColor])
;
;     #Window     | #PB_All = All Window (Default).
;                 | The Window number to use.
;                 |
;     #Gadget     | #PB_All = All Supported Gadgets (Default).
;                 | The Gadget number to use.
;                 |
;     BackColor   | #PB_Auto = Same as parent container's color (Default).
;                 | The new backgound color. RGB() can be used to get a valid color value.
;                 | #PB_Default = to go back to the default system backgound color.
;                 |
;     TextColor   | #PB_Auto = White or Black depending on whether the background color is dark or light (Default).
;                 | The new text color. RGB() can be used to get a valid color value.
;                 | #PB_Default: to go back to the default system text color.
;
;     For all gadgets with automatic background color and text color use: SetObjectColor()
;
; ---------------------------------------------
;
;   SetObjectColorType([Type.s])   Optional
;                 |
;     Type.s:     | Without Type for all supported Gadget. It is done automatically if SetObjectColorType() is not used.
;                 | "NoEdit" for all supported Gadget except String and Editor.
;                 | "ColorStatic" for CheckBox, Frame, Option and TrackBar only (WM_CTLCOLORSTATIC).
;                 | 1 or multiple #PB_GadgetType_xxxxx separated by comma. The parameter is a String, so between quotes. Ex: SetObjectColorType("#PB_GadgetType_CheckBox, #PB_GadgetType_Option").
;
;
; ---------------------------------------------
;
;   The theme "Explorer" or "DarkMode_Explorer" (Windows 10 and up) is automatically applied according to the Background Color of each Gadget.
;       Gadget supported: ComboBox, Editor, ExplorerList, ExplorerTree, ListIcon, ListView, ScrollArea, ScrollBar, Tree
;   However, after calling SetObjectColor(), you can change the applied theme by using one of the 2 macros below:
;       For example, if you have a window With a Dark Background Color And a ScrollArea With a Light Color,
;       By default, the Light Theme will be applied for the ScollArea and its ScrollBars related to the ScrollArea Color.
;       But you may want to change it to a Dark Theme to match the Window which is in Dark Color. It would be like this
;           SetObjectColor(#PB_All, #PB_All, #Black)
;           SetObjectColor(#Windows, #ScrollArea, #Gray)
;           SetDarkTheme(#ScrollArea)
;   
;   SetDarkTheme(Gadget)           Optional
;      Apply the "DarkMode_Explorer" Theme if OSVersion >= Windows_10, otherwise the "Explorer" theme is applied
;
;   SetExplorerTheme(Gadget)       Optional
;      Apply the "Explorer" Theme if OSVersion >= Vista
;
; ---------------------------------------------
;
;   To Debug with the hierarchical list of gadgets with their colors, change the constant #DebugON = #True 
;
; -------------------------------------------------------------------------------------------------

EnableExplicit

#DebugON         = #False   ; #True

#EditAccentColor = #True    ; #False
#UseUxGripper    = #False   ; #False = Custom, #True = Uxtheme. For Splitter 
#LargeGripper    = #True    ; #False
#SplitterBorder  = #True    ; #False

#PB_Auto = -2
#PB_None = -3

; Add: XIncludeFile "JellyButtons.pbi"  in your main code to add nice buttons

Structure SObjectC
  Level.i             ; If Level = 1, Parent is a Window else a Gadget
  ObjectID.i
  Type.i
  IsContainer.b
  ParentObject.i
  ParentObjectID.i
  GParentObjectID.i   ; Temporary Loaded for ScrollArea and Panel, it is then reset to 0 or used to store the Splitter gripper image 
  BackMode.i
  BackColor.i
  TextMode.i
  TextColor.i
  OldProc.i
EndStructure

Global NewMap ObjectC.SObjectC()
Global NewMap ObjectCType()
Global NewMap ObjectCBrush()
Global Dim    WinObjectC(1, 0)

CompilerIf Not (Defined(PB_Globals, #PB_Structure))
  Structure PB_Globals
    CurrentWindow.i
    FirstOptionGadget.i
    DefaultFont.i
    *PanelStack
    PanelStackIndex.l
    PanelStackSize.l
    ToolTipWindow.i
  EndStructure
CompilerEndIf

Import ""
  CompilerIf Not(Defined(PB_Object_Count, #PB_Procedure))            : PB_Object_Count(PB_Gadget_Objects)                          : CompilerEndIf
  CompilerIf Not(Defined(PB_Object_EnumerateAll, #PB_Procedure))     : PB_Object_EnumerateAll(Object, *Object, ObjectData)         : CompilerEndIf
  CompilerIf Not(Defined(PB_Object_EnumerateStart, #PB_Procedure))   : PB_Object_EnumerateStart(PB_Gadget_Objects)                 : CompilerEndIf
  CompilerIf Not(Defined(PB_Object_EnumerateNext, #PB_Procedure))    : PB_Object_EnumerateNext(PB_Gadget_Objects, *Object.Integer) : CompilerEndIf
  CompilerIf Not(Defined(PB_Object_EnumerateAbort, #PB_Procedure))   : PB_Object_EnumerateAbort(PB_Gadget_Objects)                 : CompilerEndIf
  CompilerIf Not (Defined(PB_Object_GetThreadMemory, #PB_Procedure)) : PB_Object_GetThreadMemory(*Mem)                             : CompilerEndIf
  CompilerIf Not(Defined(PB_Gadget_Objects, #PB_Variable))           : PB_Gadget_Objects.i                                         : CompilerEndIf
  CompilerIf Not(Defined(PB_Window_Objects, #PB_Variable))           : PB_Window_Objects.i                                         : CompilerEndIf
  CompilerIf Not (Defined(PB_Gadget_Globals, #PB_Variable))          : PB_Gadget_Globals.i                                         : CompilerEndIf
EndImport

; GetParent
Declare   IsContainerOC(Gadget)
Declare   CountWinObjectC()
Declare   ObjectCB(Object, *Object, ObjectData)
Declare   WinHierarchy(ParentObjectID, ParentObject, FirstPassDone = #False)
Declare   CleanUpCanvas()
Declare   LoadObjectC()
Declare   GetParent(Gadget)
Declare   GetParentBackColor(Gadget)
Declare   GetWindowRoot(Gadget)
Declare   GetParentID(Gadget)
Declare   ParentIsWindow(Gadget)
Declare   ParentIsGadget(Gadget)
Declare   CountChildGadgets(ParentObject, GrandChildren = #False, FirstPassDone = #False)
Declare   EnumWinChildColor(ParentObject, FirstPassDone = #False)
Declare   EnumChildColor(Window = #PB_All)
; ObjectColor
Declare   IsDarkColorOC(Color)
Declare   AccentColorOC(Color, AddColorValue)
Declare   FadeColorOC(Color, Percent, FadeColor = $808080)
Declare   ReverseColorOC(Color)
Declare   BackDefaultColor()
Declare   TextDefaultColor()
Declare   SplitterCalc(hWnd, *rc.RECT)
Declare   SplitterPaint(hWnd, hdc, *rc.RECT, BackColor, Gripper)
Declare   SplitterProc(hWnd, uMsg, wParam, lParam)
Declare   ListIconProc(hWnd, uMsg, wParam, lParam)
Declare   PanelProc(hWnd, uMsg, wParam, lParam)
Declare   CalendarProc(hWnd, uMsg, wParam, lParam)
Declare   EditorProc(hWnd, uMsg, wParam, lParam)
Declare   WinCallback(hWnd, uMsg, wParam, lParam)
Declare   SetObjectTheme(Gadget, Theme.s)
Declare   ToolTipHandleOC()
Declare.s GadgetTypeToString(Gadget)
Declare   TypetoValue(Type.s)
Declare   SetObjectColorType(Type.s = "", Value = 1)
Declare   ObjectColor(Gadget, BackGroundColor, ParentBackColor, FrontColor)
Declare   LoopObjectColor(Window, ParentObject, BackGroundColor, FrontColor, FirstPassDone = #False)
Declare   SetObjectColor(Window = #PB_All, Gadget = #PB_All, BackGroundColor = #PB_Auto, FrontColor = #PB_Auto)

Macro SetDarkTheme(_Gadget_)
  If OSVersion() >= #PB_OS_Windows_10
    SetObjectTheme(_Gadget_, "DarkMode_Explorer")
  ElseIf OSVersion() >= #PB_OS_Windows_Vista
    SetObjectTheme(_Gadget_, "Explorer")
  EndIf
EndMacro

Macro SetExplorerTheme(_Gadget_)
  If OSVersion() >= #PB_OS_Windows_Vista
    SetObjectTheme(_Gadget_, "Explorer")
  EndIf
EndMacro

Macro ProcedureReturnIf(Cond, ReturnVal = 0)
  If Cond
    ProcedureReturn ReturnVal
  EndIf
EndMacro

;-
;- ----- Private  GetParent -----
Procedure IsContainerOC(Gadget)
  ; Procedure IsContainer based on procedure IsCanvasContainer by mk-soft: https://www.purebasic.fr/english/viewtopic.php?t=79002
  Select GadgetType(Gadget)
    Case #PB_GadgetType_Container, #PB_GadgetType_Panel, #PB_GadgetType_ScrollArea, #PB_GadgetType_Splitter
      ProcedureReturn #True
    Case #PB_GadgetType_Canvas
      CompilerSelect #PB_Compiler_OS
        CompilerCase #PB_OS_Windows
          If GetWindowLongPtr_(GadgetID(Gadget), #GWL_STYLE) & #WS_CLIPCHILDREN
            ProcedureReturn #True
          EndIf
        CompilerCase #PB_OS_MacOS
          Protected sv, count
          sv    = CocoaMessage(0, GadgetID(Gadget), "subviews")
          count = CocoaMessage(0, sv, "count")
          ProcedureReturn count
        CompilerCase #PB_OS_Linux
          Protected GList, count
          GList = gtk_container_get_children_(GadgetID(Gadget))
          If GList
            count = g_list_length_(GList)
            g_list_free_(GList)
            ProcedureReturn count
          EndIf
      CompilerEndSelect
  EndSelect
  ProcedureReturn #False
EndProcedure

Procedure CountWinObjectC()
  Protected CountWinObjectC, I
  For I = 0 To ArraySize(WinObjectC(), 2)
    If WinObjectC(1, I)
      CountWinObjectC + 1
    EndIf
  Next
  ProcedureReturn CountWinObjectC
EndProcedure

Procedure ObjectCB(Object, *Object, ObjectData)
  If FindMapElement(ObjectC(), Str(Object)) = 0
    With ObjectC(Str(Object))
      \ObjectID        = GadgetID(Object)
      \Type            = GadgetType(Object)
      \IsContainer     = IsContainerOC(Object)
      \ParentObjectID  = GetParent_(\ObjectID)
      \GParentObjectID = GetParent_(\ParentObjectID)
      \BackMode        = #PB_None
      \TextMode        = #PB_None
      \BackColor       = #PB_None
      \TextColor       = #PB_None
    EndWith
  EndIf
  ProcedureReturn #True
EndProcedure

Procedure WinHierarchy(ParentObjectID, ParentObject, FirstPassDone = #False)
  Static Level
  Protected ObjectType
  If FirstPassDone = #False
    Level          = 0
    FirstPassDone  = #True
  EndIf
  
  Level + 1
  PushMapPosition(ObjectC())
  ResetMap(ObjectC())
  With ObjectC()
    While NextMapElement(ObjectC())
      If Level > 1 And IsGadget(ParentObject) : ObjectType = GadgetType(ParentObject) : Else : ObjectType = 0 : EndIf
      If \ParentObjectID = ParentObjectID Or (\GParentObjectID = ParentObjectID And (ObjectType = #PB_GadgetType_Panel Or ObjectType = #PB_GadgetType_ScrollArea))
        \Level        = Level
        \ParentObject = ParentObject
        If Not(\ParentObjectID = ParentObjectID)
          \ParentObjectID   = \GParentObjectID
        EndIf
        If \OldProc = 0    ; To keep the gripper for Splitter saved in GParentObjectID in case of a new enumeration
          \GParentObjectID  = 0
        EndIf
        If \IsContainer
          WinHierarchy(\ObjectID, Val(MapKey(ObjectC())), FirstPassDone)
          Level - 1
        EndIf
      EndIf
    Wend
  EndWith
  PopMapPosition(ObjectC())
EndProcedure

Procedure CleanUpCanvas()
  PushMapPosition(ObjectC())
  ResetMap(ObjectC())
  With ObjectC()
    While NextMapElement(ObjectC())
      If \Type = #PB_GadgetType_Canvas And \IsContainer = #False
        DeleteMapElement(ObjectC())
      EndIf
    Wend
  EndWith
  PopMapPosition(ObjectC())
EndProcedure

Procedure LoadObjectC()
  Protected window, CountWinObjectC, I
  CountWinObjectC = PB_Object_Count(PB_Window_Objects)
  ProcedureReturnIf(CountWinObjectC = 0)
  ReDim WinObjectC(1, CountWinObjectC - 1)
  
  CountWinObjectC = 0
  PB_Object_EnumerateStart(PB_Window_Objects)
  While PB_Object_EnumerateNext(PB_Window_Objects, @window)
    WinObjectC(0, CountWinObjectC) = Window
    WinObjectC(1, CountWinObjectC) = WindowID(Window)
    CountWinObjectC + 1
  Wend
  PB_Object_EnumerateAbort(PB_Window_Objects)
  
  PB_Object_EnumerateAll(PB_Gadget_Objects, @ObjectCB(), 0)
  
  CleanUpCanvas()
  If MapSize(ObjectC()) > 0
    ; Pass through the hierarchy for each window
    CountWinObjectC = CountWinObjectC() - 1
    For I = 0 To CountWinObjectC
      WinHierarchy(WinObjectC(1, I), WinObjectC(0, I))
    Next
  Else
    ProcedureReturn #False
  EndIf
  ProcedureReturn #True
EndProcedure
;- ----- Private GetParent -----

;-
;- ----- Public GetParent -----
Procedure GetParent(Gadget)
  Protected ParentObject = #PB_Default
  If MapSize(ObjectC()) = 0 : LoadObjectC() : ProcedureReturnIf(CountWinObjectC() = 0) : EndIf
  
  With ObjectC()
    PushMapPosition(ObjectC())
    If FindMapElement(ObjectC(), Str(Gadget))
      ParentObject = \ParentObject
    EndIf
    PopMapPosition(ObjectC())
  EndWith
  
  ProcedureReturn ParentObject
EndProcedure

Procedure GetParentBackColor(Gadget)
  Protected ParentObject, ParentIsWindow, BackColor = #PB_Default
  
  With ObjectC()
    PushMapPosition(ObjectC())
    If FindMapElement(ObjectC(), Str(Gadget))
      If \Level = 1 : ParentIsWindow = #True : EndIf
      ParentObject = \ParentObject
    EndIf
    
    If ParentIsWindow
      BackColor = GetWindowColor(ParentObject)
    ElseIf FindMapElement(ObjectC(), Str(ParentObject))
      BackColor = \BackColor
    EndIf
    PopMapPosition(ObjectC())
    If BackColor = #PB_Default : BackColor = BackDefaultColor() : EndIf
  EndWith
  
  ProcedureReturn BackColor
EndProcedure

Procedure GetWindowRoot(Gadget)
  Protected ParentObject = Gadget
  If MapSize(ObjectC()) = 0 : LoadObjectC() : ProcedureReturnIf(CountWinObjectC() = 0) : EndIf
  
  With ObjectC()
    PushMapPosition(ObjectC())
    Repeat
      If FindMapElement(ObjectC(), Str(ParentObject))
        ParentObject = \ParentObject
      Else
        ParentObject = #PB_Default
        Break   ; It should not happen
      EndIf
    Until \Level = 1
    PopMapPosition(ObjectC())
  EndWith
  
  ProcedureReturn ParentObject
EndProcedure

Procedure GetParentID(Gadget)
  Protected ParentObjectID = #PB_Default
  If MapSize(ObjectC()) = 0 : LoadObjectC() : ProcedureReturnIf(CountWinObjectC() = 0) : EndIf
  
  With ObjectC()
    PushMapPosition(ObjectC())
    If FindMapElement(ObjectC(), Str(Gadget))
      If \Level = 1
        ParentObjectID = WindowID(\ParentObject)
      Else
        ParentObjectID = GadgetID(\ParentObject)
      EndIf
    EndIf
    PopMapPosition(ObjectC())
  EndWith
  
  ProcedureReturn ParentObjectID
EndProcedure

Procedure ParentIsWindow(Gadget)
  Protected Result = #PB_Default
  If MapSize(ObjectC()) = 0 : LoadObjectC() : ProcedureReturnIf(CountWinObjectC() = 0) : EndIf
  
  With ObjectC()
    PushMapPosition(ObjectC())
    If FindMapElement(ObjectC(), Str(Gadget))
      If \Level = 1
        Result = #True
      Else
        Result = #False
      EndIf
    EndIf
    PopMapPosition(ObjectC())
  EndWith
  
  ProcedureReturn Result
EndProcedure

Procedure ParentIsGadget(Gadget)
  Protected Result = #PB_Default
  If MapSize(ObjectC()) = 0 : LoadObjectC() : ProcedureReturnIf(CountWinObjectC() = 0) : EndIf
  
  With ObjectC()
    PushMapPosition(ObjectC())
    If FindMapElement(ObjectC(), Str(Gadget))
      If \Level > 1
        Result = #True
      Else
        Result = #False
      EndIf
    EndIf
    PopMapPosition(ObjectC())
  EndWith
  
  ProcedureReturn Result
EndProcedure

Procedure CountChildGadgets(ParentObject, GrandChildren = #False, FirstPassDone = #False)
  Static Level, Count
  Protected ReturnVal
  
  With ObjectC()
    If FirstPassDone = 0
      If MapSize(ObjectC()) = 0 : LoadObjectC() : ProcedureReturnIf(CountWinObjectC() = 0) : EndIf
      If IsWindow(ParentObject)
        Level = 0
      ElseIf IsGadget(ParentObject)
        PushMapPosition(ObjectC())
        If FindMapElement(ObjectC(), Str(ParentObject))
          If Not(\IsContainer)
            ReturnVal = #True
          EndIf
          Level = \Level
        EndIf
        PopMapPosition(ObjectC())
      EndIf
      Count         = 0
      FirstPassDone = #True
    EndIf
    
    If ReturnVal
      ProcedureReturn #PB_Default
    EndIf
    
    Level + 1
    PushMapPosition(ObjectC())
    ResetMap(ObjectC())
    While NextMapElement(ObjectC())
      If \Level = Level And \ParentObject = ParentObject
        Count + 1
        If GrandChildren And \IsContainer
          CountChildGadgets(Val(MapKey(ObjectC())), GrandChildren, FirstPassDone)
          Level - 1
        EndIf
      EndIf
    Wend
    PopMapPosition(ObjectC())
  EndWith
  
  ProcedureReturn Count
EndProcedure

Procedure EnumWinChildColor(ParentObject, FirstPassDone = #False)
  Static Level
  Protected BackColor, ReturnVal
  
  If FirstPassDone = 0
    If MapSize(ObjectC()) = 0 : LoadObjectC() : ProcedureReturnIf(CountWinObjectC() = 0) : EndIf
    If IsWindow(ParentObject)
      Level     = 0
      BackColor = GetWindowColor(ParentObject)
      Debug "Enum Child Gadget of Window " + LSet(Str(ParentObject), 10) + "| WindowID " + LSet(Str(WindowID(ParentObject)), 10) + "(Level = 0)" +
            " - BackColor  RGB(" + Red(BackColor) + "," + Green(BackColor) + "," + Blue(BackColor) + ")"
    Else
      ProcedureReturn #PB_Default
    EndIf
    FirstPassDone = #True
  EndIf
  
  Level + 1
  PushMapPosition(ObjectC())
  ResetMap(ObjectC())
  With ObjectC()
    While NextMapElement(ObjectC())
      If \Level = Level And \ParentObject = ParentObject
        Debug LSet("", \Level * 4 , " ") + LSet(GadgetTypeToString(Val(MapKey(ObjectC()))), 14) + LSet(MapKey(ObjectC()), 10) + "ParentGadget " + LSet(Str(\ParentObject), 10)  + "| GadgetID " + LSet(Str(\ObjectID), 10) + "ParentGadgetID " + LSet(Str(\ParentObjectID), 10) + "(Level = " + Str(\Level) + ")" +
              " - BackMode: " +Str(\BackMode) + " RGB(" + Red(\BackColor) + "," + Green(\BackColor) + "," + Blue(\BackColor) + ")" +
              " - TextMode: " +Str(\TextMode) + " RGB(" + Red(\TextColor) + "," + Green(\TextColor) + "," + Blue(\TextColor) + ")"
        If \IsContainer
          EnumWinChildColor(Val(MapKey(ObjectC())), FirstPassDone)
          Level - 1
        EndIf
      EndIf
    Wend
  EndWith
  PopMapPosition(ObjectC())
EndProcedure

Procedure EnumChildColor(Window = #PB_All)
  ProcedureReturnIf(MapSize(ObjectC()) = 0)
  Protected I
  If Window = #PB_All
    Protected CountWinObjectC = CountWinObjectC() - 1
    For I = 0 To CountWinObjectC
      EnumWinChildColor(WinObjectC(0, I))
      Debug ""
    Next
  Else
    If IsWindow(Window)
      EnumWinChildColor(Window)
    EndIf
  EndIf
EndProcedure

;- ----- Public GetParent -----
;-
;- ----- Play with Colors -----
Procedure IsDarkColorOC(Color)
  If Red(Color)*0.299 + Green(Color)*0.587 +Blue(Color)*0.114 < 128   ; Based on Human perception of color, following the RGB values (0.299, 0.587, 0.114)
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure AccentColorOC(Color, AddColorValue)
  Protected R, G, B
  R = Red(Color)   + AddColorValue : If R > 255 : R = 255 : EndIf : If R < 0 : R = 0 : EndIf
  G = Green(Color) + AddColorValue : If G > 255 : G = 255 : EndIf : If G < 0 : G = 0 : EndIf
  B = Blue(Color)  + AddColorValue : If B > 255 : B = 255 : EndIf : If B < 0 : B = 0 : EndIf
  ProcedureReturn RGB(R, G, B)
EndProcedure

Procedure FadeColorOC(Color, Percent, FadeColor = $808080)
  Protected R, G, B
  R = Red(FadeColor)   * Percent / 100 + Red(Color)   * (100 - Percent) / 100 : If R > 255 : R = 255 : EndIf
  G = Green(FadeColor) * Percent / 100 + Green(Color) * (100 - Percent) / 100 : If G > 255 : G = 255 : EndIf
  B = Blue(FadeColor)  * Percent / 100 + Blue(Color)  * (100 - Percent) / 100 : If B > 255 : B = 255 : EndIf
  ProcedureReturn RGB(R, G, B)
EndProcedure

Procedure ReverseColorOC(Color)
  ProcedureReturn RGB(255 - Red(Color), 255 - Green(Color), 255 - Blue(Color))
EndProcedure

Procedure BackDefaultColor()
  If OSVersion() < #PB_OS_Windows_10
    ProcedureReturn GetSysColor_(#COLOR_BTNFACE)
  Else
    ProcedureReturn GetSysColor_(#COLOR_3DFACE)
  EndIf
EndProcedure

Procedure TextDefaultColor()
  ProcedureReturn GetSysColor_(#COLOR_BTNTEXT)
EndProcedure
;- ----- End Colors -----
;-
;- ----- CallBack -----

Procedure SplitterCalc(hWnd, *rc.RECT)
  Protected hWnd1, hWnd2, r1.RECT, r2.RECT
  hWnd1 = GadgetID(GetGadgetAttribute(GetDlgCtrlID_(hWnd), #PB_Splitter_FirstGadget))
  hWnd2 = GadgetID(GetGadgetAttribute(GetDlgCtrlID_(hWnd), #PB_Splitter_SecondGadget))
  GetWindowRect_(hWnd1, r1)
  OffsetRect_(r1, -r1\left, -r1\top)
  If IsRectEmpty_(r1) = 0
    MapWindowPoints_(hWnd1, hWnd, r1, 2)
    SubtractRect_(*rc, *rc, r1)
  EndIf
  GetWindowRect_(hWnd2, r2)
  OffsetRect_(r2, -r2\left, -r2\top)
  If IsRectEmpty_(r2) = 0
    MapWindowPoints_(hWnd2, hWnd, r2, 2)
    SubtractRect_(*rc, *rc, r2)
  EndIf
EndProcedure

Procedure SplitterPaint(hWnd, hdc, *rc.RECT, BackColor, Gripper)
  CompilerIf #SplitterBorder
    If IsDarkColorOC(BackColor) : SetDCBrushColor_(hdc, AccentColorOC(BackColor, 60)) : Else : SetDCBrushColor_(hdc, AccentColorOC(BackColor, -60)) : EndIf
  CompilerElse
    If IsDarkColorOC(BackColor) : BackColor = AccentColorOC(BackColor, 60) : Else : BackColor = AccentColorOC(BackColor, -60) : EndIf
    SetDCBrushColor_(hdc, BackColor)
  CompilerEndIf
  FrameRect_(hdc, *rc, GetStockObject_(#DC_BRUSH))
  InflateRect_(*rc, -1, -1)
  SetDCBrushColor_(hdc, BackColor)
  FillRect_(hdc, *rc, GetStockObject_(#DC_BRUSH))
  
  CompilerIf #UseUxGripper
    Protected htheme = OpenThemeData_(hWnd, "Rebar")
    If htheme
      If *rc\right-*rc\left < *rc\bottom-*rc\top
        CompilerIf #LargeGripper
          InflateRect_(*rc, (*rc\bottom-*rc\top-5)/2, -(*rc\bottom-*rc\top-1)/2+14)
        CompilerElse
          InflateRect_(*rc, (*rc\bottom-*rc\top-5)/2, -(*rc\bottom-*rc\top-1)/2+9)
        CompilerEndIf
        DrawThemeBackground_(htheme, hdc, 1, 0, *rc, 0)
      Else
        CompilerIf #LargeGripper
          InflateRect_(*rc, -(*rc\right-*rc\left-1)/2+14, (*rc\bottom-*rc\top-5)/2)
        CompilerElse
          InflateRect_(*rc, -(*rc\right-*rc\left-1)/2+9, (*rc\bottom-*rc\top-5)/2)
        CompilerEndIf
        DrawThemeBackground_(htheme, hdc, 2, 0, *rc, 0)
      EndIf
      CloseThemeData_(htheme)
    EndIf
  CompilerElse
    If *rc\right-*rc\left < *rc\bottom-*rc\top
      CompilerIf #LargeGripper
        InflateRect_(*rc, (*rc\right-*rc\left-5)/2, -(*rc\bottom-*rc\top-1)/2+14)
      CompilerElse
        InflateRect_(*rc, (*rc\right-*rc\left-5)/2, -(*rc\bottom-*rc\top-1)/2+9)
      CompilerEndIf
    Else
      CompilerIf #LargeGripper
        InflateRect_(*rc, -(*rc\right-*rc\left-1)/2+14, (*rc\bottom-*rc\top-5)/2)
      CompilerElse
        InflateRect_(*rc, -(*rc\right-*rc\left-1)/2+9, (*rc\bottom-*rc\top-5)/2)
      CompilerEndIf
    EndIf
    SetBrushOrgEx_(hdc, *rc\left, *rc\top, 0)
    FillRect_(hdc, *rc, Gripper)
    SetBrushOrgEx_(hdc, 0, 0, 0)
  CompilerEndIf
EndProcedure

Procedure SplitterProc(hWnd, uMsg, wParam, lParam)
  Protected Gadget = GetDlgCtrlID_(hWnd), BackColor, Gripper, Found, ps.PAINTSTRUCT
  Protected OldSplitterProc = ObjectC(Str(Gadget))\OldProc
  
  With ObjectC()
    Select uMsg
        
      Case #WM_NCDESTROY
        If FindMapElement(ObjectC(), Str(Gadget))
          If \GParentObjectID : DeleteObject_(\GParentObjectID) : EndIf   ; Delete the  Pattern Brush stored in GParentObjectID field
          If \OldProc
            SetWindowLongPtr_(hWnd, #GWLP_WNDPROC, \OldProc)
          EndIf
          DeleteMapElement(ObjectC())
        EndIf
        ; Delete map element for all children's gadgets that no longer exist
        If MapSize(ObjectC()) > 0
          ResetMap(ObjectC())
          While NextMapElement(ObjectC())
            If Not(IsGadget(Val(MapKey(ObjectC()))))
              If \OldProc
                SetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC, \OldProc)
              EndIf
              DeleteMapElement(ObjectC())
            EndIf
          Wend
        EndIf
        ;ProcedureReturn #False
        
      Case #WM_PAINT
        ;PushMapPosition(ObjectC())
        If FindMapElement(ObjectC(), Str(Gadget))
          If Not(\BackMode = #PB_Default And \TextMode = #PB_Default)
            BackColor = \BackColor
            Gripper   = \GParentObjectID
            Found     = #True
          EndIf
        EndIf
        ;PopMapPosition(ObjectC())
        If Found = #False Or BackColor = #PB_None : ProcedureReturn CallWindowProc_(OldSplitterProc, hWnd, uMsg, wParam, lParam) : EndIf
        
        If #DebugON : Debug LSet(GadgetTypeToString(Gadget) + ": ", 22) + LSet(Str(Gadget), 10) + " - Back RGB(" + Str(Red(BackColor)) + ", " + Str(Green(BackColor)) + ", " + Str(Blue(BackColor)) + ")" : EndIf
        BeginPaint_(hWnd, ps)
        SplitterCalc(hWnd, ps\rcPaint)
        SplitterPaint(hWnd, ps\hdc, ps\rcPaint, BackColor, Gripper)
        EndPaint_(hWnd, ps)
        ProcedureReturn #False
        
      Case #WM_ERASEBKGND
        ProcedureReturn #True
        
      Case #WM_LBUTTONDBLCLK
        PostEvent(#PB_Event_Gadget, EventWindow(), Gadget, #PB_EventType_LeftDoubleClick)
        
    EndSelect
  EndWith
  
  ProcedureReturn CallWindowProc_(OldSplitterProc, hWnd, uMsg, wParam, lParam)
EndProcedure


Procedure ListIconProc(hWnd, uMsg, wParam, lParam)
  Protected BackColor, TextColor, Text.s, Found
  Protected Gadget = GetDlgCtrlID_(hWnd), *pnmHDR.NMHDR, *pnmCDraw.NMCUSTOMDRAW
  Protected Result = CallWindowProc_(ObjectC(Str(Gadget))\OldProc, hWnd, uMsg, wParam, lParam)
  
  With ObjectC()
    Select uMsg
      Case #WM_NCDESTROY
        If FindMapElement(ObjectC(), Str(Gadget))
          If \OldProc
            SetWindowLongPtr_(hWnd, #GWLP_WNDPROC, \OldProc)
          EndIf
          DeleteMapElement(ObjectC())
        EndIf
        ;ProcedureReturn #False
        
      Case #WM_NOTIFY
        *pnmHDR = lparam
        If *pnmHDR\code = #NM_CUSTOMDRAW   ; Get handle to ListIcon and ExplorerList Header Control
          
          ;PushMapPosition(ObjectC())
          If FindMapElement(ObjectC(), Str(Gadget))
            If Not(\BackMode = #PB_Default And \TextMode = #PB_Default)
              BackColor = \BackColor
              TextColor = \TextColor
              Found     = #True
            EndIf
          EndIf
          ;PopMapPosition(ObjectC())
          If Found = #False Or BackColor = #PB_None : ProcedureReturn Result : EndIf
          
          *pnmCDraw = lparam
          Select *pnmCDraw\dwDrawStage   ; Determine drawing stage
            Case #CDDS_PREPAINT
              Result = #CDRF_NOTIFYITEMDRAW
              
            Case #CDDS_ITEMPREPAINT
              If #DebugON : Debug LSet(GadgetTypeToString(Gadget) + " Header: ", 22) + LSet(Str(Gadget), 10) + " - Back RGB(" + Str(Red(BackColor)) + ", " + Str(Green(BackColor)) + ", " + Str(Blue(BackColor)) + ")" +
                                  " - Text RGB(" + Str(Red(TextColor)) + ", " + Str(Green(TextColor)) + ", " + Str(Blue(TextColor)) + ")" : EndIf
              Text = GetGadgetItemText(Gadget, -1, *pnmCDraw\dwItemSpec)
              If *pnmCDraw\uItemState & #CDIS_SELECTED
                DrawFrameControl_(*pnmCDraw\hdc, *pnmCDraw\rc, #DFC_BUTTON, #DFCS_BUTTONPUSH | #DFCS_PUSHED)
                *pnmCDraw\rc\left + 1 : *pnmCDraw\rc\top + 1
              Else
                DrawFrameControl_(*pnmCDraw\hdc, *pnmCDraw\rc, #DFC_BUTTON, #DFCS_BUTTONPUSH)
              EndIf
              *pnmCDraw\rc\bottom - 1 : *pnmCDraw\rc\right - 1
              SetBkMode_(*pnmCDraw\hdc, #TRANSPARENT)
              If IsDarkColorOC(BackColor) : BackColor = AccentColorOC(BackColor, 40) : Else : BackColor = AccentColorOC(BackColor, -40) : EndIf
              If Not(FindMapElement(ObjectCBrush(), Str(BackColor)))
                ObjectCBrush(Str(BackColor)) = CreateSolidBrush_(BackColor)
              EndIf
              ;Debug Str(Gadget) + ": " + Str(DesktopScaledX(GadgetWidth(Gadget))) + " - (" + Str(*pnmCDraw\rc\left) + ", " + Str(*pnmCDraw\rc\top) + ", " + Str(*pnmCDraw\rc\right) + ", " + Str(*pnmCDraw\rc\bottom) + ")"
              ;If *pnmCDraw\rc\right < DesktopScaledX(GadgetWidth(Gadget))
              ;  *pnmCDraw\rc\right = DesktopScaledX(GadgetWidth(Gadget))
              ;EndIf
              FillRect_(*pnmCDraw\hdc, *pnmCDraw\rc, ObjectCBrush(Str(BackColor)))
              If IsWindowEnabled_(GadgetID(Gadget)) = #False
                If IsDarkColorOC(TextColor) : TextColor = $909090 : Else : TextColor = $707070 : EndIf
              EndIf
              SetTextColor_(*pnmCDraw\hdc, TextColor)
              If *pnmCDraw\rc\right > *pnmCDraw\rc\left
                DrawText_(*pnmCDraw\hdc, @Text, Len(Text), *pnmCDraw\rc, #DT_CENTER | #DT_VCENTER | #DT_SINGLELINE | #DT_END_ELLIPSIS)
              EndIf
              Result = #CDRF_SKIPDEFAULT
              
          EndSelect
        EndIf
        
    EndSelect
  EndWith
  
  ProcedureReturn Result
EndProcedure

Procedure PanelProc(hWnd, uMsg, wParam, lParam)
  Protected BackColor, ParentBackColor, Found
  Protected Gadget = GetDlgCtrlID_(hWnd), *DrawItem.DRAWITEMSTRUCT, Rect.Rect 
  Protected OldPanelProc = ObjectC(Str(Gadget))\OldProc
  
  With ObjectC()
    Select uMsg
      Case #WM_NCDESTROY
        If FindMapElement(ObjectC(), Str(Gadget))
          If \OldProc
            SetWindowLongPtr_(hWnd, #GWLP_WNDPROC, \OldProc)
          EndIf
          DeleteMapElement(ObjectC())
        EndIf
        ; Delete map element for all children's gadgets that no longer exist
        If MapSize(ObjectC()) > 0
          ResetMap(ObjectC())
          While NextMapElement(ObjectC())
            If Not(IsGadget(Val(MapKey(ObjectC()))))
              If \OldProc
                SetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC, \OldProc)
              EndIf
              DeleteMapElement(ObjectC())
            EndIf
          Wend
        EndIf
        ;ProcedureReturn #False
        
      Case #WM_ENABLE
        InvalidateRect_(hWnd, #Null, #True)
        ProcedureReturn #True
        
      Case #WM_ERASEBKGND
        ;PushMapPosition(ObjectC())
        If FindMapElement(ObjectC(), Str(Gadget))
          If Not(\BackMode = #PB_Default And \TextMode = #PB_Default)
            BackColor = \BackColor
            Found     = #True
          EndIf
        EndIf
        ;PopMapPosition(ObjectC())
        If Found = #False Or BackColor = #PB_None : ProcedureReturn CallWindowProc_(OldPanelProc, hWnd, uMsg, wParam, lParam) : EndIf
        
        ;If #DebugON : Debug "WM_ERASEBKGND " + LSet(GadgetTypeToString(Gadget) + ": ", 22) + LSet(Str(Gadget), 10) + " - Back RGB(" + Str(Red(BackColor)) + ", " + Str(Green(BackColor)) + ", " + Str(Blue(BackColor)) + ")" : EndIf
        *DrawItem.DRAWITEMSTRUCT = wParam
        ; Protected PanelImgList = SendMessage_(hWnd, #TCM_GETIMAGELIST, 0, 0)
        GetClientRect_(hWnd, Rect)
        If Not(FindMapElement(ObjectCBrush(), Str(BackColor)))
          ObjectCBrush(Str(BackColor)) = CreateSolidBrush_(BackColor)
        EndIf
        FillRect_(wParam, @Rect, ObjectCBrush(Str(BackColor)))
        ParentBackColor  = GetParentBackColor(Gadget)
        If Not(FindMapElement(ObjectCBrush(), Str(ParentBackColor)))
          ObjectCBrush(Str(ParentBackColor)) = CreateSolidBrush_(ParentBackColor)
        EndIf
        Rect\top = 0 : Rect\bottom = GetGadgetAttribute(Gadget, #PB_Panel_TabHeight)
        FillRect_(wParam, @Rect, ObjectCBrush(Str(ParentBackColor)))
        ProcedureReturn #True
        
    EndSelect
  EndWith
  
  ProcedureReturn CallWindowProc_(OldPanelProc, hWnd, uMsg, wParam, lParam)
EndProcedure

Procedure CalendarProc(hWnd, uMsg, wParam, lParam)
  Protected Gadget = GetDlgCtrlID_(hWnd), TextColor, Found
  Protected Result = CallWindowProc_(ObjectC(Str(Gadget))\OldProc, hWnd, uMsg, wParam, lParam)
  
  With ObjectC()
    Select uMsg
      Case #WM_NCDESTROY
        If FindMapElement(ObjectC(), Str(Gadget))
          If \OldProc
            SetWindowLongPtr_(hWnd, #GWLP_WNDPROC, \OldProc)
          EndIf
          DeleteMapElement(ObjectC())
        EndIf
        ;ProcedureReturn #False
        
      Case #WM_ENABLE
        ;PushMapPosition(ObjectC())
        If FindMapElement(ObjectC(), Str(Gadget))
          If Not(\BackMode = #PB_Default And \TextMode = #PB_Default)
            TextColor = \TextColor
            Found = #True
          EndIf
        EndIf
        ;PopMapPosition(ObjectC())
        If Found = #False Or TextColor = #PB_None : ProcedureReturn Result : EndIf
        
        If wParam = #False
          If IsDarkColorOC(TextColor) : TextColor = $909090 : Else : TextColor = $707070 : EndIf
        EndIf
        SendMessage_(hWnd, #MCM_SETCOLOR, #MCSC_TEXT, TextColor)
        SendMessage_(hWnd, #MCM_SETCOLOR, #MCSC_TITLETEXT, TextColor)
        SendMessage_(hWnd, #MCM_SETCOLOR, #MCSC_TRAILINGTEXT, TextColor)
        ProcedureReturn #False
        
    EndSelect
  EndWith
  
  ProcedureReturn Result
EndProcedure

Procedure EditorProc(hWnd, uMsg, wParam, lParam)
  Protected Gadget = GetDlgCtrlID_(hWnd), BackColor, TextColor, Found, Rect.RECT
  Protected Result = CallWindowProc_(ObjectC(Str(Gadget))\OldProc, hWnd, uMsg, wParam, lParam)
  
  With ObjectC()
    Select uMsg
      Case #WM_NCDESTROY
        If FindMapElement(ObjectC(), Str(Gadget))
          If \OldProc
            SetWindowLongPtr_(hWnd, #GWLP_WNDPROC, \OldProc)
          EndIf
          DeleteMapElement(ObjectC())
        EndIf
        ;ProcedureReturn #False
        
      Case #WM_ENABLE
        ;PushMapPosition(ObjectC())
        If FindMapElement(ObjectC(), Str(Gadget))
          If Not(\BackMode = #PB_Default And \TextMode = #PB_Default)
            TextColor = \TextColor
            Found = #True
          EndIf
        EndIf
        ;PopMapPosition(ObjectC())
        If Found = #False Or TextColor = #PB_None : ProcedureReturn Result : EndIf
        
        If wParam
          SetWindowLongPtr_(GadgetID(Gadget), #GWL_EXSTYLE, GetWindowLongPtr_(GadgetID(Gadget), #GWL_EXSTYLE) &~ #WS_EX_TRANSPARENT)
          SetGadgetColor(Gadget, #PB_Gadget_FrontColor, TextColor)
        Else
          SetWindowLongPtr_(GadgetID(Gadget), #GWL_EXSTYLE, GetWindowLongPtr_(GadgetID(Gadget), #GWL_EXSTYLE) | #WS_EX_TRANSPARENT)
          If IsDarkColorOC(TextColor) : SetGadgetColor(Gadget, #PB_Gadget_FrontColor, $909090) : Else : SetGadgetColor(Gadget, #PB_Gadget_FrontColor, $707070) : EndIf
        EndIf
        ProcedureReturn #False
        
      Case #WM_ERASEBKGND
        ;PushMapPosition(ObjectC())
        If FindMapElement(ObjectC(), Str(Gadget))
          If Not(\BackMode = #PB_Default And \TextMode = #PB_Default)
            BackColor = \BackColor
            Found     = #True
          EndIf
        EndIf
        ;PopMapPosition(ObjectC())
        If Found = #False Or BackColor = #PB_None : ProcedureReturn Result : EndIf
        
        CompilerIf #EditAccentColor
          If IsDarkColorOC(BackColor) : BackColor = AccentColorOC(BackColor, 10) : Else : BackColor = AccentColorOC(BackColor, -10) : EndIf
        CompilerEndIf
        If #DebugON : Debug LSet(GadgetTypeToString(Gadget) + ": ", 22) + LSet(Str(Gadget), 10) + " - Back RGB(" + Str(Red(BackColor)) + ", " + Str(Green(BackColor)) + ", " + Str(Blue(BackColor)) + ")" : EndIf
        GetClientRect_(hWnd, Rect)
        If Not(FindMapElement(ObjectCBrush(), Str(BackColor)))
          ObjectCBrush(Str(BackColor)) = CreateSolidBrush_(BackColor)
        EndIf
        FillRect_(wParam, @Rect, ObjectCBrush(Str(BackColor)))
        ProcedureReturn #True
        
    EndSelect
  EndWith
  
  ProcedureReturn Result
EndProcedure

Procedure WinCallback(hWnd, uMsg, wParam, lParam)
  Protected Result = #PB_ProcessPureBasicEvents
  Protected Gadget, ParentGadget, Buffer.s, Text.s, BackColor, TextColor, Color_HightLight, FadeGrayColor, Found, I
  Protected *NMDATETIMECHANGE.NMDATETIMECHANGE, *DrawItem.DRAWITEMSTRUCT, *lvCD.NMLVCUSTOMDRAW
  
  With ObjectC()
    Select uMsg
      Case #WM_CLOSE
        PostEvent(#PB_Event_Gadget, GetDlgCtrlID_(hWnd), 0, #PB_Event_CloseWindow)   ; Required to manage it with #PB_Event_CloseWindow event, if the window is minimized and closed from the taskbar (Right CLick)
        
      Case #WM_NCDESTROY
        ; Delete map element for all children's gadgets that no longer exist after CloseWindow(). Useful in case of multiple windows
        If MapSize(ObjectC()) > 0
          ResetMap(ObjectC())
          While NextMapElement(ObjectC())
            If Not(IsGadget(Val(MapKey(ObjectC()))))
              If \OldProc
                SetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC, \OldProc)
              EndIf
              DeleteMapElement(ObjectC())
            EndIf
          Wend
        EndIf
        ; Delete all brushes and map element. If there are used brushes in other windows, they will be recreated
        If MapSize(ObjectCBrush()) > 0
          ResetMap(ObjectCBrush())
          While NextMapElement(ObjectCBrush())
            DeleteObject_(ObjectCBrush())
            DeleteMapElement(ObjectCBrush())
          Wend
        EndIf
        ;ProcedureReturn #False
        
        ; Case #WM_SIZE
        ;   If wParam = #SIZE_RESTORED   ; Not sure if there is a need to RedrawWindow()
        ;     For I = 0 To CountWinObjectC() - 1
        ;       If WinObjectC(1, I) = hWnd
        ;         RedrawWindow_(hWnd, #Null, #Null, #RDW_INVALIDATE | #RDW_ERASE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
        ;         Break
        ;       EndIf
        ;     Next
        ;   EndIf
        
        ; Case #WM_ACTIVATE              ; Not sure if there is a need to RedrawWindow()
        ;   If wParam
        ;     For I = 0 To CountWinObjectC() - 1
        ;       If WinObjectC(1, I) = hWnd
        ;         RedrawWindow_(hWnd, #Null, #Null, #RDW_INVALIDATE | #RDW_ERASE | #RDW_ALLCHILDREN | #RDW_UPDATENOW)
        ;         Break
        ;       EndIf
        ;     Next
        ;   EndIf
        
      Case #WM_CTLCOLORSTATIC   ; For CheckBoxGadget, FrameGadget, OptionGadget, TextGadget, TrackBarGadget
        Gadget = GetDlgCtrlID_(lparam)
        If IsGadget(Gadget)
          ;PushMapPosition(ObjectC())
          If FindMapElement(ObjectC(), Str(Gadget))
            If Not(\BackMode = #PB_Default And \TextMode = #PB_Default)
              BackColor = \BackColor
              TextColor = \TextColor
              Found     = #True
            EndIf
          EndIf
          ;PopMapPosition(ObjectC())
          If Found = #False Or BackColor = #PB_None : ProcedureReturn Result : EndIf
          
          If #DebugON : Debug LSet(GadgetTypeToString(Gadget) + ": ", 22) + LSet(Str(Gadget), 10) + " - Back RGB(" + Str(Red(BackColor)) + ", " + Str(Green(BackColor)) + ", " + Str(Blue(BackColor)) + ")" +
                              " - Text RGB(" + Str(Red(TextColor)) + ", " + Str(Green(TextColor)) + ", " + Str(Blue(TextColor)) + ")" : EndIf
          
          If IsWindowEnabled_(GadgetID(Gadget)) = #False
            If IsDarkColorOC(TextColor) : TextColor = $909090 : Else : TextColor = $707070 : EndIf
          EndIf
          SetTextColor_(wParam, TextColor)
          SetBkMode_(wParam, #TRANSPARENT)
          If Not(FindMapElement(ObjectCBrush(), Str(BackColor)))
            ObjectCBrush(Str(BackColor)) = CreateSolidBrush_(BackColor)
          EndIf
          ProcedureReturn ObjectCBrush(Str(BackColor))
        EndIf
        
        ; Case #WM_CTLCOLORBTN         ; Button
        ; Case #WM_CTLCOLORDLG
        ; Case #WM_CTLCOLOREDIT        ; Combo, Spin, String
        ; Case #WM_CTLCOLORLISTBOX     ; ListView
        ; Case #WM_CTLCOLORSCROLLBAR   ; Scrlbar
        
      Case #WM_CTLCOLOREDIT
        Gadget = GetDlgCtrlID_(lparam)
        If IsGadget(Gadget) And GadgetType(Gadget) = #PB_GadgetType_ComboBox
          ;PushMapPosition(ObjectC())
          If FindMapElement(ObjectC(), Str(Gadget))
            If Not(\BackMode = #PB_Default And \TextMode = #PB_Default)
              BackColor = \BackColor
              TextColor = \TextColor
              Found     = #True
            EndIf
          EndIf
          ;PopMapPosition(ObjectC())
          If Found = #False Or BackColor = #PB_None : ProcedureReturn Result : EndIf
        Else
          ParentGadget = GetParent_(lParam)
          Buffer = Space(64)
          If GetClassName_(ParentGadget, @Buffer, 64)
            If Buffer = "ComboBox"
              Gadget = GetDlgCtrlID_(ParentGadget)
              If IsGadget(Gadget)
                ;PushMapPosition(ObjectC())
                If FindMapElement(ObjectC(), Str(Gadget))
                  If Not(\BackMode = #PB_Default And \TextMode = #PB_Default)
                    BackColor = \BackColor
                    TextColor = \TextColor
                    Found     = #True
                  EndIf
                EndIf
                ;PopMapPosition(ObjectC())
                If Found = #False Or BackColor = #PB_None : ProcedureReturn Result : EndIf
              EndIf
            EndIf
          EndIf
        EndIf
        
        If Found
          CompilerIf #EditAccentColor
            If IsDarkColorOC(BackColor) : BackColor = AccentColorOC(BackColor, 10) : Else : BackColor = AccentColorOC(BackColor, -10) : EndIf
          CompilerEndIf
          If #DebugON : Debug LSet(GadgetTypeToString(Gadget) + ": ", 22) + LSet(Str(Gadget), 10) + " - Back RGB(" + Str(Red(BackColor)) + ", " + Str(Green(BackColor)) + ", " + Str(Blue(BackColor)) + ")" +
                              " - Text RGB(" + Str(Red(TextColor)) + ", " + Str(Green(TextColor)) + ", " + Str(Blue(TextColor)) + ")" : EndIf
          If IsWindowEnabled_(GadgetID(Gadget)) = #False
            If IsDarkColorOC(TextColor) : TextColor = $909090 : Else : TextColor = $707070 : EndIf
          EndIf
          If Gadget <> GetActiveGadget()
            Protected low, high
            SendMessage_(lParam, #EM_GETSEL, @low, @high)
            If low <> high
              SendMessage_(lParam, #EM_SETSEL, -1, 0)   ; Deselect the ComboBox editable string if not the active Gadget
            EndIf
          EndIf
          SetTextColor_(wParam, TextColor)
          SetBkMode_(wParam, #TRANSPARENT)
          ;SetBkColor_(wParam, BackColor)
          If Not(FindMapElement(ObjectCBrush(), Str(BackColor)))
            ObjectCBrush(Str(BackColor)) = CreateSolidBrush_(BackColor)
          EndIf
          ProcedureReturn ObjectCBrush(Str(BackColor))
        EndIf
        
      Case #WM_DRAWITEM   ; For ComboBoxGadget and PanelGadget
        *DrawItem.DRAWITEMSTRUCT = lParam
        If *DrawItem\CtlType = #ODT_COMBOBOX
          Gadget = wParam
          If IsGadget(Gadget)
            ;PushMapPosition(ObjectC())
            If FindMapElement(ObjectC(), Str(Gadget))
              If Not(\BackMode = #PB_Default And \TextMode = #PB_Default)
                BackColor = \BackColor
                TextColor = \TextColor
                Found     = #True
              EndIf
            EndIf
            ;PopMapPosition(ObjectC())
            If Found = #False Or BackColor = #PB_None : ProcedureReturn Result : EndIf
            
            If *DrawItem\itemID <> -1
              If #DebugON : Debug LSet(GadgetTypeToString(Gadget) + ": ", 22) + LSet(Str(Gadget), 10) + " - Back RGB(" + Str(Red(BackColor)) + ", " + Str(Green(BackColor)) + ", " + Str(Blue(BackColor)) + ")" +
                                  " - Text RGB(" + Str(Red(TextColor)) + ", " + Str(Green(TextColor)) + ", " + Str(Blue(TextColor)) + ")" : EndIf
              If *DrawItem\itemstate & #ODS_SELECTED
                Color_HightLight = GetSysColor_(#COLOR_HIGHLIGHT)
                If Not(FindMapElement(ObjectCBrush(), Str(Color_HightLight)))
                  ObjectCBrush(Str(Color_HightLight)) = CreateSolidBrush_(Color_HightLight)
                EndIf
                FillRect_(*DrawItem\hDC, *DrawItem\rcitem, ObjectCBrush(Str(Color_HightLight)))
              Else
                If Not(FindMapElement(ObjectCBrush(), Str(BackColor)))
                  ObjectCBrush(Str(BackColor)) = CreateSolidBrush_(BackColor)
                EndIf
                FillRect_(*DrawItem\hDC, *DrawItem\rcitem, ObjectCBrush(Str(BackColor)))
              EndIf
              
              SetBkMode_(*DrawItem\hDC, #TRANSPARENT)
              ;If *DrawItem\itemID = 0 : ; Example for Icon : DrawIconEx_(*DrawItem\hDC, *DrawItem\rcItem\left + 2, *DrawItem\rcItem\top + 6, icon1, iconsize, iconsize, 0, 0, #DI_NORMAL) : EndIf
              If IsWindowEnabled_(GadgetID(Gadget)) = #False
                If IsDarkColorOC(TextColor) : TextColor = $909090 : Else : TextColor = $707070 : EndIf
              EndIf
              SetTextColor_(*DrawItem\hDC, TextColor)
              Text = GetGadgetItemText(*DrawItem\CtlID, *DrawItem\itemID)
              *DrawItem\rcItem\left + DesktopScaledX(4)
              DrawText_(*DrawItem\hDC, Text, Len(Text), *DrawItem\rcItem, #DT_LEFT | #DT_SINGLELINE | #DT_VCENTER)
            EndIf
          EndIf
        EndIf
        
        If *DrawItem\CtlType = #ODT_TAB   ;PanelGadget
          Gadget = GetDlgCtrlID_(*DrawItem\hwndItem)
          If IsGadget(Gadget)
            ;PushMapPosition(ObjectC())
            If FindMapElement(ObjectC(), Str(Gadget))
              If Not(\BackMode = #PB_Default And \TextMode = #PB_Default)
                BackColor = \BackColor
                TextColor = \TextColor
                Found     = #True
              EndIf
            EndIf
            ;PopMapPosition(ObjectC())
            If Found = #False Or BackColor = #PB_None : ProcedureReturn Result : EndIf
            
            If #DebugON : Debug LSet(GadgetTypeToString(Gadget) + ": ", 22) + LSet(Str(Gadget), 10) + " - Back RGB(" + Str(Red(BackColor)) + ", " + Str(Green(BackColor)) + ", " + Str(Blue(BackColor)) + ")" +
                                " - Text RGB(" + Str(Red(TextColor)) + ", " + Str(Green(TextColor)) + ", " + Str(Blue(TextColor)) + ")" : EndIf
            If *DrawItem\itemState
              If Not(FindMapElement(ObjectCBrush(), Str(BackColor)))
                ObjectCBrush(Str(BackColor)) = CreateSolidBrush_(BackColor)
              EndIf
              *DrawItem\rcItem\left + 2
              FillRect_(*DrawItem\hDC, *DrawItem\rcItem, ObjectCBrush(Str(BackColor)))
            Else
              If IsDarkColorOC(BackColor)
                FadeGrayColor = FadeColorOC(BackColor, 40, AccentColorOC(BackColor, 80))
              Else
                FadeGrayColor = FadeColorOC(BackColor, 40, AccentColorOC(BackColor, -80))
              EndIf
              If Not(FindMapElement(ObjectCBrush(), Str(FadeGrayColor)))
                ObjectCBrush(Str(FadeGrayColor)) = CreateSolidBrush_(FadeGrayColor)
              EndIf
              *DrawItem\rcItem\top + 2 : *DrawItem\rcItem\bottom + 3   ; Default: \rcItem\bottom + 2 . +3 to decrease the size of the bottom line
              FillRect_(*DrawItem\hDC, *DrawItem\rcItem, ObjectCBrush(Str(FadeGrayColor)))
            EndIf
            
            SetBkMode_(*DrawItem\hDC, #TRANSPARENT)
            If IsWindowEnabled_(GadgetID(Gadget)) = #False
              If IsDarkColorOC(TextColor) : TextColor = $909090 : Else : TextColor = $707070 : EndIf
            EndIf
            SetTextColor_(*DrawItem\hDC, TextColor)
            Text = GetGadgetItemText(Gadget, *DrawItem\itemID)
            *DrawItem\rcItem\left + DesktopScaledX(4)
            ;TextOut_(*DrawItem\hDC, *DrawItem\rcItem\left, *DrawItem\rcItem\top, Text, Len(Text))
            DrawText_(*DrawItem\hDC, @Text, Len(Text), @*DrawItem\rcItem, #DT_LEFT | #DT_VCENTER | #DT_SINGLELINE)
            ProcedureReturn #True
          EndIf
        EndIf
        
      Case #WM_NOTIFY   ; For DateGadget
        *NMDATETIMECHANGE.NMDATETIMECHANGE = lParam
        If *NMDATETIMECHANGE\nmhdr\code = #DTN_DROPDOWN
          Gadget = GetDlgCtrlID_(*NMDATETIMECHANGE\nmhdr\hwndfrom)
          If GadgetType(Gadget) = #PB_GadgetType_Date
            ;PushMapPosition(ObjectC())
            If FindMapElement(ObjectC(), Str(Gadget))
              If Not(\BackMode = #PB_Default And \TextMode = #PB_Default)
                BackColor = \BackColor
                Found     = #True
              EndIf
            EndIf
            ;PopMapPosition(ObjectC())
            If Found = #False Or BackColor = #PB_None : ProcedureReturn Result : EndIf
            
            If #DebugON : Debug LSet(GadgetTypeToString(Gadget) + ": ", 22) + LSet(Str(Gadget), 10) + " - Back RGB(" + Str(Red(BackColor)) + ", " + Str(Green(BackColor)) + ", " + Str(Blue(BackColor)) + ")" : EndIf
            SetWindowTheme_(FindWindowEx_(FindWindow_("DropDown", 0), #Null, "SysMonthCal32", #Null), "", "")
          EndIf
        EndIf
        
        ; ListIcon and ExplorerList
        *lvCD.NMLVCUSTOMDRAW = lParam
        If *lvCD\nmcd\hdr\code = #NM_CUSTOMDRAW
          Gadget = GetDlgCtrlID_(*lvCD\nmcd\hdr\hWndFrom)
          If IsGadget(Gadget)
            If IsWindowEnabled_(GadgetID(Gadget)) = #False
              If GadgetType(Gadget) = #PB_GadgetType_ListIcon Or GadgetType(Gadget) = #PB_GadgetType_ExplorerList
                ;PushMapPosition(ObjectC())
                If FindMapElement(ObjectC(), Str(Gadget))
                  If Not(\BackMode = #PB_Default And \TextMode = #PB_Default)
                    BackColor = \BackColor
                    TextColor = \TextColor
                    Found     = #True
                  EndIf
                EndIf
                ;PopMapPosition(ObjectC())
                If Found = #False Or BackColor = #PB_None : ProcedureReturn Result : EndIf
                
                If #DebugON : Debug LSet(GadgetTypeToString(Gadget) + ": ", 22) + LSet(Str(Gadget), 10) + " - Back RGB(" + Str(Red(BackColor)) + ", " + Str(Green(BackColor)) + ", " + Str(Blue(BackColor)) + ")" +
                                    " - Text RGB(" + Str(Red(TextColor)) + ", " + Str(Green(TextColor)) + ", " + Str(Blue(TextColor)) + ")" : EndIf
                Select *lvCD\nmcd\dwDrawStage
                  Case #CDDS_PREPAINT
                    If Not(FindMapElement(ObjectCBrush(), Str(BackColor)))
                      ObjectCBrush(Str(BackColor)) = CreateSolidBrush_(BackColor)
                    EndIf
                    ;*lvCD\nmcd\rc\right = DesktopScaledX(GadgetWidth(Gadget))
                    FillRect_(*lvCD\nmcd\hDC, *lvCD\nmcd\rc, ObjectCBrush(Str(BackColor)))
                    ProcedureReturn #CDRF_NOTIFYITEMDRAW
                  Case #CDDS_ITEMPREPAINT
                    ;DrawIconEx_(*lvCD\nmcd\hDC, subItemRect\left + 5, (subItemRect\top + subItemRect\bottom - GetSystemMetrics_(#SM_CYSMICON)) / 2, hIcon, 16, 16, 0, 0, #DI_NORMAL)
                    If IsWindowEnabled_(GadgetID(Gadget)) = #False
                      If IsDarkColorOC(TextColor) : TextColor = $909090 : Else : TextColor = $707070 : EndIf
                    EndIf
                    *lvCD\clrText   = TextColor
                    *lvCD\clrTextBk = BackColor
                    ProcedureReturn #CDRF_DODEFAULT
                EndSelect
              EndIf
            EndIf
          EndIf
        EndIf
        
    EndSelect
  EndWith
  
  ProcedureReturn Result
EndProcedure
;- ----- End CallBack -----
;-
;- ----- Object Color -----
Procedure SetObjectTheme(Gadget, Theme.s)
  Protected ChildGadget, Buffer.s
  If FindMapElement(ObjectC(), Str(Gadget))
    With ObjectC()
      Select \Type
        Case #PB_GadgetType_Editor, #PB_GadgetType_ExplorerList, #PB_GadgetType_ExplorerTree, #PB_GadgetType_ListIcon, #PB_GadgetType_ListView,
             #PB_GadgetType_ScrollArea, #PB_GadgetType_ScrollBar, #PB_GadgetType_Tree
          SetWindowTheme_(\ObjectID, @Theme, 0)
          
        Case #PB_GadgetType_ComboBox
          Buffer = Space(64)
          If GetClassName_(\ObjectID, @Buffer, 64)
            If Buffer = "ComboBox"
              If OSVersion() >= #PB_OS_Windows_10 And Theme = "DarkMode_Explorer"
                SetWindowTheme_(\ObjectID, "DarkMode_CFD", "Combobox")
              Else
                SetWindowTheme_(\ObjectID, @Theme, 0)
              EndIf
            EndIf
          EndIf
          ChildGadget = GetWindow_(\ObjectID, #GW_CHILD)
          If ChildGadget
            Buffer = Space(64)
            If GetClassName_(ChildGadget, @Buffer, 64)
              If Buffer = "ComboBox"
                If OSVersion() >= #PB_OS_Windows_10 And Theme = "DarkMode_Explorer"
                  SetWindowTheme_(ChildGadget, "DarkMode_CFD", "Combobox")
                Else
                  SetWindowTheme_(ChildGadget, @Theme, 0)
                EndIf
              EndIf
            EndIf
          EndIf
          
      EndSelect
    EndWith
  EndIf
EndProcedure

Procedure ToolTipHandleOC() 
  Protected *PBGadget.PB_Globals 
  *PBGadget = PB_Object_GetThreadMemory(PB_Gadget_Globals) 
  ProcedureReturn *PBGadget\ToolTipWindow 
EndProcedure

Macro _ToolTipHandleOC()
  Tooltip = ToolTipHandleOC()
  If Tooltip
    SetWindowTheme_(Tooltip, @"", @"")
    ;SendMessage_(Tooltip, #TTM_SETDELAYTIME, #TTDT_INITIAL, 250) : SendMessage_(Tooltip, #TTM_SETDELAYTIME,#TTDT_AUTOPOP, 5000) : SendMessage_(Tooltip, #TTM_SETDELAYTIME,#TTDT_RESHOW, 250)
    Protected TmpBackColor = GetWindowColor(GetWindowRoot(Gadget))   ; GetParentBackColor(Gadget)
    SendMessage_(Tooltip, #TTM_SETTIPBKCOLOR, TmpBackColor, 0)
    If IsDarkColorOC(TmpBackColor)
      SendMessage_(Tooltip, #TTM_SETTIPTEXTCOLOR, #White, 0)
    Else
      SendMessage_(Tooltip, #TTM_SETTIPTEXTCOLOR, #Black, 0)
    EndIf
    SendMessage_(Tooltip, #WM_SETFONT, 0, 0)
    SendMessage_(Tooltip, #TTM_SETMAXTIPWIDTH, 0, 460) 
  EndIf
EndMacro

Procedure.s GadgetTypeToString(Gadget)
  Select GadgetType(Gadget)
    Case #PB_GadgetType_Button          : ProcedureReturn "Button"
    Case #PB_GadgetType_ButtonImage     : ProcedureReturn "Buttonimage"
    Case #PB_GadgetType_Calendar        : ProcedureReturn "Calendar"
    Case #PB_GadgetType_Canvas          : ProcedureReturn "Canvas"
    Case #PB_GadgetType_CheckBox        : ProcedureReturn "CheckBox"
    Case #PB_GadgetType_ComboBox        : ProcedureReturn "ComboBox"
    Case #PB_GadgetType_Container       : ProcedureReturn "Container"
    Case #PB_GadgetType_Date            : ProcedureReturn "Date"
    Case #PB_GadgetType_Editor          : ProcedureReturn "Editor"
    Case #PB_GadgetType_ExplorerCombo   : ProcedureReturn "ExplorerCombo"
    Case #PB_GadgetType_ExplorerList    : ProcedureReturn "ExplorerList"
    Case #PB_GadgetType_ExplorerTree    : ProcedureReturn "ExplorerTree"
    Case #PB_GadgetType_Frame           : ProcedureReturn "Frame"
    Case #PB_GadgetType_HyperLink       : ProcedureReturn "Hyperlink"
    Case #PB_GadgetType_IPAddress       : ProcedureReturn "IPaddress"
    Case #PB_GadgetType_Image           : ProcedureReturn "image"
    Case #PB_GadgetType_ListIcon        : ProcedureReturn "ListIcon"
    Case #PB_GadgetType_ListView        : ProcedureReturn "ListView"
    Case #PB_GadgetType_MDI             : ProcedureReturn "Mdi"
    Case #PB_GadgetType_OpenGL          : ProcedureReturn "Opengl"
    Case #PB_GadgetType_Option          : ProcedureReturn "Option"
    Case #PB_GadgetType_Panel           : ProcedureReturn "Panel"
    Case #PB_GadgetType_ProgressBar     : ProcedureReturn "ProgressBar"
    Case #PB_GadgetType_ScrollArea      : ProcedureReturn "ScrollArea"
    Case #PB_GadgetType_ScrollBar       : ProcedureReturn "ScrollBar"
    Case #PB_GadgetType_Spin            : ProcedureReturn "Spin"
    Case #PB_GadgetType_Splitter        : ProcedureReturn "Splitter"
    Case #PB_GadgetType_String          : ProcedureReturn "String"
    Case #PB_GadgetType_Text            : ProcedureReturn "Text"
    Case #PB_GadgetType_TrackBar        : ProcedureReturn "TrackBar"
    Case #PB_GadgetType_Tree            : ProcedureReturn "Tree"
    Case #PB_GadgetType_Web             : ProcedureReturn "Web"
  EndSelect
EndProcedure

Procedure TypetoValue(Type.s)
  Select LCase(Right(Type, Len(type) - 15))
    Case "button"           : ProcedureReturn #PB_GadgetType_Button
    Case "buttonimage"      : ProcedureReturn #PB_GadgetType_ButtonImage
    Case "calendar"         : ProcedureReturn #PB_GadgetType_Calendar
    Case "canvas"           : ProcedureReturn #PB_GadgetType_Canvas
    Case "checkbox"         : ProcedureReturn #PB_GadgetType_CheckBox
    Case "combobox"         : ProcedureReturn #PB_GadgetType_ComboBox
    Case "container"        : ProcedureReturn #PB_GadgetType_Container
    Case "date"             : ProcedureReturn #PB_GadgetType_Date
    Case "editor"           : ProcedureReturn #PB_GadgetType_Editor
    Case "explorercombo"    : ProcedureReturn #PB_GadgetType_ExplorerCombo
    Case "explorerlist"     : ProcedureReturn #PB_GadgetType_ExplorerList
    Case "explorertree"     : ProcedureReturn #PB_GadgetType_ExplorerTree
    Case "frame"            : ProcedureReturn #PB_GadgetType_Frame
    Case "hyperlink"        : ProcedureReturn #PB_GadgetType_HyperLink
    Case "ipaddress"        : ProcedureReturn #PB_GadgetType_IPAddress
    Case "image"            : ProcedureReturn #PB_GadgetType_Image
    Case "listicon"         : ProcedureReturn #PB_GadgetType_ListIcon
    Case "listview"         : ProcedureReturn #PB_GadgetType_ListView
    Case "mdi"              : ProcedureReturn #PB_GadgetType_MDI
    Case "opengl"           : ProcedureReturn #PB_GadgetType_OpenGL
    Case "option"           : ProcedureReturn #PB_GadgetType_Option
    Case "panel"            : ProcedureReturn #PB_GadgetType_Panel
    Case "progressbar"      : ProcedureReturn #PB_GadgetType_ProgressBar
    Case "scrollarea"       : ProcedureReturn #PB_GadgetType_ScrollArea
    Case "scrollbar"        : ProcedureReturn #PB_GadgetType_ScrollBar
    Case "spin"             : ProcedureReturn #PB_GadgetType_Spin
    Case "splitter"         : ProcedureReturn #PB_GadgetType_Splitter
    Case "string"           : ProcedureReturn #PB_GadgetType_String
    Case "text"             : ProcedureReturn #PB_GadgetType_Text
    Case "trackbar"         : ProcedureReturn #PB_GadgetType_TrackBar
    Case "tree"             : ProcedureReturn #PB_GadgetType_Tree
    Case "web"              : ProcedureReturn #PB_GadgetType_Web
  EndSelect
EndProcedure

Procedure SetObjectColorType(Type.s = "", Value = 1)
  Protected iType, Count, I
  Select UCase(Type)
    Case ""
      Restore AllType
      For I = 0 To 99     ; Loop break if 99
        Read.l iType
        If iType = 99 : Break : EndIf
        ObjectCType(Str(iType)) = Value
      Next
    Case "COLORSTATIC"
      SetObjectColorType("", 0)
      Restore ColorStaticType
      For I = 0 To 99     ; Loop break if 99
        Read.l iType
        If iType = 99 : Break : EndIf
        ObjectCType(Str(iType)) = Value
      Next
    Case "NOEDIT"
      SetObjectColorType("", 0)
      Restore NoEditType
      For I = 0 To 99     ; Loop break if 99
        Read.l iType
        If iType = 99 : Break : EndIf
        ObjectCType(Str(iType)) = Value
      Next
    Default   ; 1 or multiple #PB_GadgetType_xxxxx separated by comma. Ex: SetObjectColorType("#PB_GadgetType_CheckBox, #PB_GadgetType_Option").
      SetObjectColorType("", 0)
      Count = CountString(Type, ",") + 1
      For I = 1 To Count
        iType = TypetoValue(Trim(StringField(Type, I, ",")))
        If FindMapElement(ObjectCType(), Str(iType))
          ObjectCType(Str(iType)) = Value
        EndIf
      Next
      ; Let the User Add or Not the Containers to Color the Children.
      ; ObjectCType(Str(#PB_GadgetType_Canvas)) = Value
      ; ObjectCType(Str(#PB_GadgetType_Container)) = Value
      ; ObjectCType(Str(#PB_GadgetType_Panel)) = Value
      ; ObjectCType(Str(#PB_GadgetType_ScrollArea)) = Value
      ; ObjectCType(Str(#PB_GadgetType_Splitter)) = Value
  EndSelect
  
  DataSection
    AllType:
    Data.l  #PB_GadgetType_Calendar, #PB_GadgetType_Canvas, #PB_GadgetType_CheckBox, #PB_GadgetType_ComboBox, #PB_GadgetType_Container, #PB_GadgetType_Date,
            #PB_GadgetType_Editor, #PB_GadgetType_ExplorerList, #PB_GadgetType_ExplorerTree, #PB_GadgetType_Frame, #PB_GadgetType_HyperLink, #PB_GadgetType_ListIcon,
            #PB_GadgetType_ListView, #PB_GadgetType_Option, #PB_GadgetType_Panel, #PB_GadgetType_ProgressBar, #PB_GadgetType_ScrollArea, #PB_GadgetType_ScrollBar,
            #PB_GadgetType_Spin, #PB_GadgetType_Splitter, #PB_GadgetType_String, #PB_GadgetType_Text, #PB_GadgetType_TrackBar, #PB_GadgetType_Tree, 99
    NoEditType:
    Data.l  #PB_GadgetType_Calendar, #PB_GadgetType_Canvas, #PB_GadgetType_CheckBox, #PB_GadgetType_ComboBox, #PB_GadgetType_Container, #PB_GadgetType_Date,
            #PB_GadgetType_ExplorerList, #PB_GadgetType_ExplorerTree, #PB_GadgetType_Frame, #PB_GadgetType_HyperLink, #PB_GadgetType_ListIcon, #PB_GadgetType_ListView,
            #PB_GadgetType_Option, #PB_GadgetType_Panel, #PB_GadgetType_ProgressBar, #PB_GadgetType_ScrollArea, #PB_GadgetType_Splitter, #PB_GadgetType_Spin,
            #PB_GadgetType_Text, #PB_GadgetType_TrackBar, #PB_GadgetType_Tree, 99
    ColorStaticType:
    Data.l  #PB_GadgetType_Canvas, #PB_GadgetType_CheckBox, #PB_GadgetType_Container, #PB_GadgetType_Frame, #PB_GadgetType_Option, #PB_GadgetType_Panel,
            #PB_GadgetType_ScrollArea, #PB_GadgetType_Splitter, #PB_GadgetType_Text, #PB_GadgetType_TrackBar, 99
  EndDataSection
EndProcedure

Procedure ObjectColor(Gadget, BackGroundColor, ParentBackColor, FrontColor)
  Protected BackColor, OldBackColor, OldTextColor, SplitterImg, Tooltip
  
  If FindMapElement(ObjectC(), Str(Gadget))
    With ObjectC()
      OldBackColor = \BackColor : OldTextColor = \TextColor
      \BackMode = BackGroundColor : \TextMode = FrontColor
      
      _ToolTipHandleOC()
      
      ; ----- BackColor -----
      Select \BackMode
        Case #PB_Auto
          \BackColor = ParentBackColor
          
        Case #PB_Default
          Select \Type
            Case #PB_GadgetType_CheckBox, #PB_GadgetType_ComboBox, #PB_GadgetType_Frame, #PB_GadgetType_Option, #PB_GadgetType_Panel, #PB_GadgetType_TrackBar
              \BackColor = BackDefaultColor()
            Default
              \BackColor = #PB_Default
          EndSelect
          
        Default
          \BackColor = BackGroundColor
      EndSelect
      
      If \BackColor
        If IsDarkColorOC(\BackColor)
          SetDarkTheme(Gadget)
        Else
          SetExplorerTheme(Gadget)
        EndIf
      EndIf
      
      ; ----- TextColor -----
      Select \TextMode
        Case #PB_Auto
          If \BackMode = #PB_Default
            Select \Type
              Case #PB_GadgetType_CheckBox, #PB_GadgetType_ComboBox, #PB_GadgetType_Frame, #PB_GadgetType_Option, #PB_GadgetType_Panel, #PB_GadgetType_TrackBar
                If IsDarkColorOC(\BackColor) : \TextColor = #White : Else : \TextColor = #Black : EndIf
              Default
                \TextColor = #PB_Default
            EndSelect
          Else
            If IsDarkColorOC(\BackColor) : \TextColor = #White : Else : \TextColor = #Black : EndIf
          EndIf
          
        Case #PB_Default
          Select \Type
            Case #PB_GadgetType_CheckBox, #PB_GadgetType_ComboBox, #PB_GadgetType_Frame, #PB_GadgetType_Option, #PB_GadgetType_Panel, #PB_GadgetType_TrackBar
              \TextColor = TextDefaultColor()
            Default
              \TextColor = #PB_Default
          EndSelect
          
        Default
          \TextColor = FrontColor
      EndSelect
      
      ; ----- Specific ProgressBar Color -----
      If \Type = #PB_GadgetType_ProgressBar
        Select \BackMode
          Case #PB_Auto
            If IsDarkColorOC(\BackColor) : \BackColor = AccentColorOC(\BackColor, 40) : Else : \BackColor = AccentColorOC(\BackColor, -40) : EndIf
            Select \TextMode
              Case #PB_Auto, #PB_Default
                If IsDarkColorOC(\BackColor) : \TextColor = AccentColorOC(\BackColor, 100) : Else : \TextColor = AccentColorOC(\BackColor, -100) : EndIf
                ;If IsDarkColorOC(\BackColor) : \TextColor = #White : Else : \TextColor = #Black : EndIf
            EndSelect
            
          Case #PB_Default
            Select \TextMode
              Case #PB_Auto, #PB_Default
                \TextColor = #PB_Default
            EndSelect
            
          Default
            Select \TextMode
              Case #PB_Auto, #PB_Default
                If IsDarkColorOC(\BackColor) : \TextColor = AccentColorOC(\BackColor, 100) : Else : \TextColor = AccentColorOC(\BackColor, -100) : EndIf
                ;If IsDarkColorOC(\BackColor) : \TextColor = #White : Else : \TextColor = #Black : EndIf
            EndSelect
            
        EndSelect
      EndIf
      
      ; ----- SetGadgetColor, Theme, Gwl_WndProc -----
      If OldBackColor <> \BackColor Or OldTextColor <> \TextColor
        Select \Type
          Case #PB_GadgetType_CheckBox, #PB_GadgetType_Frame, #PB_GadgetType_Option, #PB_GadgetType_TrackBar, #PB_GadgetType_Text
            SendMessage_(\ObjectID, #WM_ENABLE, IsWindowEnabled_(\ObjectID), 0)
            Select \Type
              Case #PB_GadgetType_CheckBox, #PB_GadgetType_Option, #PB_GadgetType_TrackBar
                If IsWindowEnabled_(\ObjectID)
                  SetWindowTheme_(\ObjectID, "", "")
                Else
                  SetWindowTheme_(\ObjectID, "", 0)
                EndIf
              Case #PB_GadgetType_Frame
                SetWindowTheme_(\ObjectID, "", "")
              Case #PB_GadgetType_Text
                SetWindowTheme_(\ObjectID, "", 0)
            EndSelect
            
          Case #PB_GadgetType_ComboBox
            RedrawWindow_(\ObjectID, #Null, #Null, #RDW_INVALIDATE | #RDW_ERASE | #RDW_UPDATENOW)
            
          Case #PB_GadgetType_Container, #PB_GadgetType_ScrollArea
            SetGadgetColor(Gadget, #PB_Gadget_BackColor, \BackColor)
            
          Case #PB_GadgetType_ScrollBar
            
          Case #PB_GadgetType_ExplorerTree, #PB_GadgetType_HyperLink
            SetGadgetColor(Gadget, #PB_Gadget_BackColor, \BackColor)
            SetGadgetColor(Gadget, #PB_Gadget_FrontColor, \TextColor)
            
          Case #PB_GadgetType_Editor
            If  \BackMode = #PB_Default And \TextMode = #PB_Default
              If FindMapElement(ObjectC(), Str(Gadget))
                If \OldProc
                  SetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC, \OldProc)
                  \OldProc = 0
                EndIf
              EndIf
            Else
              If FindMapElement(ObjectC(), Str(Gadget))
                If Not \OldProc
                  \OldProc = GetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC)
                  SetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC, @EditorProc())
                EndIf
              EndIf
            EndIf
            If IsDarkColorOC(\BackColor) : BackColor = AccentColorOC(\BackColor, 20) : Else : BackColor = AccentColorOC(\BackColor, -20) : EndIf
            SetGadgetColor(Gadget, #PB_Gadget_BackColor, BackColor)
            SetGadgetColor(Gadget, #PB_Gadget_FrontColor, \TextColor)
            SendMessage_(\ObjectID, #WM_ENABLE, IsWindowEnabled_(\ObjectID), 0)
            
          Case #PB_GadgetType_Spin, #PB_GadgetType_String
            ;SetWindowLongPtr_(\ObjectID, #GWL_EXSTYLE, GetWindowLongPtr_(\ObjectID, #GWL_EXSTYLE) &~ #WS_EX_CLIENTEDGE)
            ;SetWindowLongPtr_(\ObjectID, #GWL_STYLE, GetWindowLongPtr_(\ObjectID, #GWL_STYLE) | #WS_BORDER)
            CompilerIf #EditAccentColor
              If IsDarkColorOC(\BackColor) : BackColor = AccentColorOC(\BackColor, 10) : Else : BackColor = AccentColorOC(\BackColor, -10) : EndIf
              SetGadgetColor(Gadget, #PB_Gadget_BackColor, BackColor)
            CompilerElse
              SetGadgetColor(Gadget, #PB_Gadget_BackColor, \BackColor)
            CompilerEndIf
            SetGadgetColor(Gadget, #PB_Gadget_FrontColor, \TextColor)
            
          Case #PB_GadgetType_ListView
            SetWindowLongPtr_(\ObjectID, #GWL_EXSTYLE, GetWindowLongPtr_(\ObjectID, #GWL_EXSTYLE) &~ #WS_EX_CLIENTEDGE)
            SetWindowLongPtr_(\ObjectID, #GWL_STYLE, GetWindowLongPtr_(\ObjectID, #GWL_STYLE) | #WS_BORDER)
            SetGadgetColor(Gadget, #PB_Gadget_BackColor, \BackColor)
            SetGadgetColor(Gadget, #PB_Gadget_FrontColor, \TextColor)
            
          Case #PB_GadgetType_ProgressBar
            SetWindowTheme_(\ObjectID, "", "")
            SetGadgetColor(Gadget, #PB_Gadget_BackColor, \BackColor)
            SetGadgetColor(Gadget, #PB_Gadget_FrontColor, \TextColor)
            
          Case #PB_GadgetType_Tree
            SetGadgetColor(Gadget, #PB_Gadget_BackColor, \BackColor)
            SetGadgetColor(Gadget, #PB_Gadget_FrontColor, \TextColor)
            SetGadgetColor(Gadget, #PB_Gadget_LineColor, \TextColor)
            ;SetGadgetItemColor(Gadget, #PB_All, #PB_Gadget_BackColor, \BackColor, #PB_All)
            ;SetGadgetItemColor(Gadget, #PB_All, #PB_Gadget_FrontColor, \TextColor, #PB_All)
            
          Case #PB_GadgetType_Date
            SetGadgetColor(Gadget, #PB_Gadget_BackColor, \BackColor)
            SetGadgetColor(Gadget, #PB_Gadget_FrontColor, \TextColor)
            SetGadgetColor(Gadget, #PB_Gadget_TitleBackColor, \BackColor)
            SetGadgetColor(Gadget, #PB_Gadget_TitleFrontColor, \TextColor)
            ;SetGadgetColor(Gadget, #PB_Gadget_GrayTextColor, \TextColor)
            
          Case #PB_GadgetType_Calendar
            If  \BackMode = #PB_Default And \TextMode = #PB_Default
              If FindMapElement(ObjectC(), Str(Gadget))
                If \OldProc
                  SetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC, \OldProc)
                  \OldProc = 0
                EndIf
              EndIf
            Else
              If FindMapElement(ObjectC(), Str(Gadget))
                If Not \OldProc
                  \OldProc = GetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC)
                  SetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC, @CalendarProc())
                EndIf
              EndIf
            EndIf
            SetWindowTheme_(\ObjectID, "", "")
            SetGadgetColor(Gadget, #PB_Gadget_BackColor, \BackColor)
            SetGadgetColor(Gadget, #PB_Gadget_FrontColor, \TextColor)
            SetGadgetColor(Gadget, #PB_Gadget_TitleBackColor, \BackColor)
            SetGadgetColor(Gadget, #PB_Gadget_TitleFrontColor, \TextColor)
            ;SetGadgetColor(Gadget, #PB_Gadget_GrayTextColor, \TextColor)
            SendMessage_(\ObjectID, #WM_ENABLE, IsWindowEnabled_(\ObjectID), 0)
            
          Case #PB_GadgetType_Panel
            If  \BackMode = #PB_Default And \TextMode = #PB_Default
              If FindMapElement(ObjectC(), Str(Gadget))
                SetWindowLongPtr_(\ObjectID, #GWL_STYLE, GetWindowLongPtr_(\ObjectID, #GWL_STYLE) &~ #TCS_OWNERDRAWFIXED)
                If \OldProc
                  SetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC, \OldProc)
                  \OldProc = 0
                EndIf
              EndIf
            Else
              If FindMapElement(ObjectC(), Str(Gadget))
                SetWindowLongPtr_(\ObjectID, #GWL_STYLE, GetWindowLongPtr_(\ObjectID, #GWL_STYLE) | #TCS_OWNERDRAWFIXED)
                If Not \OldProc
                  \OldProc = GetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC)
                  SetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC, @PanelProc())
                EndIf
              EndIf
            EndIf
            
          Case #PB_GadgetType_ListIcon, #PB_GadgetType_ExplorerList
            If  \BackMode = #PB_Default And \TextMode = #PB_Default
              If FindMapElement(ObjectC(), Str(Gadget))
                If \OldProc
                  SetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC, \OldProc)
                  \OldProc = 0
                EndIf
              EndIf
            Else
              If FindMapElement(ObjectC(), Str(Gadget))
                If Not \OldProc
                  \OldProc = GetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC)
                  SetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC, @ListIconProc())
                EndIf
              EndIf
            EndIf
            SetGadgetColor(Gadget, #PB_Gadget_BackColor, \BackColor)
            SetGadgetColor(Gadget, #PB_Gadget_FrontColor, \TextColor)
            SetGadgetColor(Gadget, #PB_Gadget_LineColor, \TextColor)
            ;SetGadgetItemColor(Gadget, #PB_All, #PB_Gadget_BackColor, \BackColor, #PB_All)
            ;SetGadgetItemColor(Gadget, #PB_All, #PB_Gadget_FrontColor, \TextColor, #PB_All)
            
          Case  #PB_GadgetType_Splitter
            If  \BackMode = #PB_Default And \TextMode = #PB_Default
              If FindMapElement(ObjectC(), Str(Gadget))
                SetClassLongPtr_(\ObjectID, #GWL_STYLE, GetWindowLongPtr_(\ObjectID, #GWL_STYLE) &~ #CS_DBLCLKS)
                SetWindowLongPtr_(\ObjectID, #GWL_STYLE, GetWindowLongPtr_(\ObjectID, #GWL_STYLE) &~ #WS_CLIPCHILDREN)
                If \OldProc
                  SetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC, \OldProc)
                  \OldProc = 0
                EndIf
              EndIf
            Else
              If FindMapElement(ObjectC(), Str(Gadget))
                SetClassLongPtr_(\ObjectID, #GCL_STYLE, GetClassLongPtr_(\ObjectID, #GCL_STYLE) | #CS_DBLCLKS)
                SetWindowLongPtr_(\ObjectID, #GWL_STYLE, GetWindowLongPtr_(\ObjectID, #GWL_STYLE) | #WS_CLIPCHILDREN)
                If Not \OldProc
                  \OldProc = GetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC)
                  SetWindowLongPtr_(\ObjectID, #GWLP_WNDPROC, @SplitterProc())
                EndIf
              EndIf
            EndIf
            CompilerIf #UseUxGripper = 0
              If \GParentObjectID : DeleteObject_(\GParentObjectID) : EndIf   ; Delete the  Pattern Brush stored in GParentObjectID field
              CompilerIf #SplitterBorder
                If IsDarkColorOC(\BackColor)
                  SplitterImg = CreateImage(#PB_Any, 5, 5, 24, AccentColorOC(\BackColor, 40))
                Else
                  SplitterImg = CreateImage(#PB_Any, 5, 5, 24, AccentColorOC(\BackColor, -40))
                EndIf
              CompilerElse
                SplitterImg = CreateImage(#PB_Any, 5, 5, 24, \BackColor)
              CompilerEndIf
              If StartDrawing(ImageOutput(SplitterImg))
                RoundBox(1, 1, 3, 3, 1, 1, \TextColor)
                StopDrawing()
              EndIf
              \GParentObjectID = CreatePatternBrush_(ImageID(SplitterImg))   ; Use the empty GParentObjectID field to save the Pattern Brush
              FreeImage(SplitterImg)
            CompilerEndIf
            RedrawWindow_(\ObjectID, #Null, #Null, #RDW_INVALIDATE | #RDW_ERASE | #RDW_UPDATENOW)
            
          Case #PB_GadgetType_Canvas  ; for Canvas Container
            
          Default
            Debug "It should not happen!"
            SetGadgetColor(Gadget, #PB_Gadget_BackColor, \BackColor)
            SetGadgetColor(Gadget, #PB_Gadget_FrontColor, \TextColor)
            
        EndSelect
      EndIf
      
      ;Debug LSet("", \Level*3 , " ") + "Gadget " + LSet(Str(Gadget), 10) + "BackColor(" + Str(Red(\BackColor)) + ", " + Str(Green(\BackColor)) + ", " + Str(Blue(\BackColor)) + ") - TextColor(" + Str(Red(\TextColor)) + ", " + Str(Red(\TextColor)) + ", " + Str(Red(\TextColor)) + ")"
    EndWith
  EndIf
EndProcedure

Procedure LoopObjectColor(Window, ParentObject, BackGroundColor, FrontColor, FirstPassDone = #False)
  Static Level
  Protected Gadget, ParentBackColor, ProgressBackColor
  
  With ObjectC()
    If FirstPassDone = 0
      If ParentObject = #PB_All
        Level        = 0
        ParentObject = Window
        Select BackGroundColor
          Case #PB_Auto
            ParentBackColor = GetWindowColor(Window)
          Case #PB_Default
            ParentBackColor = GetSysColor_(#COLOR_WINDOW)
          Default
            ParentBackColor = BackGroundColor
            ;If GetWindowColor(Window) = #PB_Default : SetWindowColor(Window, ParentBackColor) : EndIf
            SetWindowColor(Window, ParentBackColor)
        EndSelect
        If ParentBackColor = #PB_Default : ParentBackColor = BackDefaultColor() : EndIf
      ElseIf FindMapElement(ObjectC(), Str(ParentObject))
        Level = \Level
        Select BackGroundColor
          Case #PB_Auto
            ParentBackColor = GetParentBackColor(ParentObject)
          Case #PB_Default
            ParentBackColor = GetSysColor_(#COLOR_WINDOW)
          Default
            ParentBackColor = BackGroundColor
        EndSelect
        If ParentBackColor = #PB_Default : ParentBackColor = BackDefaultColor() : EndIf
        ObjectColor(ParentObject, BackGroundColor, ParentBackColor, FrontColor)
      Else
        ProcedureReturn #PB_Default
      EndIf
      FirstPassDone = #True
    Else
      If FindMapElement(ObjectC(), Str(ParentObject))
        ParentBackColor = \BackColor
        If ParentBackColor = #PB_Default : ParentBackColor = BackDefaultColor() : EndIf
      EndIf
    EndIf
    
    Level + 1
    PushMapPosition(ObjectC())
    ResetMap(ObjectC())
    While NextMapElement(ObjectC())
      If \Level = Level And \ParentObject = ParentObject
        Gadget = Val(MapKey(ObjectC()))
        If Not(IsGadget(Gadget)) : DeleteMapElement(ObjectC()) : Continue : EndIf
        If Not(ObjectCType(Str(GadgetType(Gadget)))) : Continue : EndIf
        
        If \Type = #PB_GadgetType_ProgressBar
          If IsDarkColorOC(ParentBackColor)   ; ----- Specific ProgressBar Color
            ProgressBackColor = AccentColorOC(ParentBackColor, 40)
          Else
            ProgressBackColor = AccentColorOC(ParentBackColor, -40)
          EndIf
          ObjectColor(Gadget, ProgressBackColor, ProgressBackColor, FrontColor)
        Else
          ObjectColor(Gadget, BackGroundColor, ParentBackColor, FrontColor)
        EndIf
        
        If \IsContainer
          LoopObjectColor(Window, Gadget, BackGroundColor, FrontColor, FirstPassDone)
          Level - 1
        EndIf
      EndIf
    Wend
    PopMapPosition(ObjectC())
    
  EndWith
EndProcedure

Procedure SetObjectColor(Window = #PB_All, Gadget = #PB_All, BackGroundColor = #PB_Auto, FrontColor = #PB_Auto)
  Protected ParentWindow, ParentBackColor, I
  If MapSize(ObjectCType()) = 0 : SetObjectColorType()                               : EndIf
  LoadObjectC()
  ProcedureReturnIf(CountWinObjectC() = 0)
  
  If Gadget = #PB_All
    If Window = #PB_All
      SetWindowCallback(@WinCallback())
      Protected CountWinObjectC = CountWinObjectC() - 1
      For I = 0 To CountWinObjectC
        LoopObjectColor(WinObjectC(0, I), #PB_All, BackGroundColor, FrontColor)
        If #DebugON : Debug "" : Debug "----------" : EnumWinChildColor(WinObjectC(0, I)) : Debug  "----------" : Debug "" : EndIf
      Next
    Else
      If IsWindow(Window)
        SetWindowCallback(@WinCallback(), Window)
        LoopObjectColor(Window, #PB_All, BackGroundColor, FrontColor)
        If #DebugON : Debug "" : Debug "----------" : EnumWinChildColor(Window) : Debug "----------" : Debug "" : EndIf
      EndIf
    EndIf
  Else
    If IsGadget(Gadget)
      ParentWindow = GetWindowRoot(Gadget)
      If (Window = #PB_All Or ParentWindow = Window)
        If FindMapElement(ObjectC(), Str(Gadget))
          SetWindowCallback(@WinCallback(), ParentWindow)
          If ObjectC(Str(Gadget))\IsContainer
            LoopObjectColor(ParentWindow, Gadget, BackGroundColor, FrontColor)
            If #DebugON : Debug "" : Debug "----------" : EnumWinChildColor(ParentWindow) : Debug "----------" : Debug "" : EndIf
          Else
            Select BackGroundColor
              Case #PB_Auto
                ParentBackColor = GetParentBackColor(Gadget)
                If ParentBackColor = #PB_Default : ParentBackColor = BackDefaultColor() : EndIf
              Case #PB_Default
                ParentBackColor = GetSysColor_(#COLOR_WINDOW)
              Default
                ParentBackColor = BackGroundColor
            EndSelect
            ObjectColor(Gadget, BackGroundColor, ParentBackColor, FrontColor)
          EndIf
        EndIf
      EndIf
    EndIf
  EndIf
  
EndProcedure
