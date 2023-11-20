/**
 * MarkdownHelper v1.0.0 : My Hugo Blog Markdown Helper
 */
#Requires AutoHotkey v2.0
#Include "..\Lib\ini.ahk"
#SingleInstance Force

; Information about executable
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright 2023. TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription My Hugo Blog Markdown Helper
;@Ahk2Exe-SetFileVersion 1.1.0.0
;@Ahk2Exe-SetLanguage 0x0412
;@Ahk2Exe-SetMainIcon icon_normal.ico ; Default icon
;@Ahk2Exe-SetProductName MarkdownHelper

; Hack - Fix tray menu not recognizing keyboard input
WinActivate A_ScriptHwnd
Send "{Alt Up}"

; ---------------------------------------------------------------------------
; Hotkey
; ---------------------------------------------------------------------------
; Ctrl + B : 「」
^B::
{
  Send("「」{left}")
}
; Ctrl + D : Insert single image
^D::
{
  res := SimpleInput("Markdown - Single Image Helper", "Input image name.`nYou can omit extension and it will default to 'webp'.", , 128)
  if (res != "") {
    if (IsNumber(res)) {
      resNum := Number(res)
      output := "![](" . Format("{:03}", resNum) . ".webp)`n`n"
    } else {
      output := "![](" . res . ".webp)`n`n"
    }
    SendText(output)
  }
}
; Ctrl + Shift + D : Insert multiple images
^+D::
{
  res := SimpleInput("Markdown - Multiple Image Helper", "Input last image name.`nYou can omit extension and it will default to 'webp'.", , 319)
  if (res != "") {
    num := ""
    ext := "webp"
    if (!IsNumber(res)) {
      SplitPath(res, , , &ext, &num)
      if (!IsNumber(num)) {
        MsgBox("Given file name cannot be batch processed.`nAborting.", "ERROR", "OK Iconx T3")
        return
      }
      num := Number(num)
    } else {
      num := Number(res)
    }

    output := ""
    Loop num {
      output .= "![](" . Format("{:03}", A_Index) . "." . ext . ")`n`n`n`n"
    }

    A_Clipboard := output
    Sleep(10)
    Send("^v")
  }
}
; Ctrl + G : Insert gallery/image with two sources, with given numbers
^G::
{
  res := SimpleInput("Markdown - Gallery Image (Two) Helper", "Input first image name`nYou can omit extension and it will default to 'webp'.", , 128)
  if (res != "") {
    if (!IsNumber(res)) {
      MsgBox("Given file name cannot be batch processed.`nAborting.", "ERROR", "OK Iconx T3")
      return
    }
    num := Number(res)

    SendText("{{< gallery/image src=`"" . Format("{:03}", num) . ":" . Format("{:03}", num + 1) . "`" >}}`n`n")
  }
}
; Ctrl + Shift + G : Insert gallery/image with three sources and caption
^+G::
{
  res := SimpleInput("Markdown - Gallery Image (Three) Helper", "Input first image name`nYou can omit extension and it will default to 'webp'.", , 319)

  if (res != "") {
    if !(IsNumber(res)) {
      MsgBox("Given file name cannot be batch processed.`nAborting.", "ERROR", "OK Iconx T3")
      return
    }
    num := Number(res)

    SendText("{{< gallery/image src=`"" . Format("{:03}", num) . ":" . Format("{:03}", num + 1) . ":" . Format("{:03}", num + 2) . "`" >}}`n`n")
  }
}
; Win + G : Insert gallery/image with two sources
#G::
{
  SendText("{{< gallery/image src=`":`" >}}`n`n")
}
; Win + Shift + G : Insert gallery/image with three sources
#+G::
{
  SendText("{{< gallery/image src=`"::`" >}}`n`n")
}
; Ctrl + Q : Insert NBSP
^Q::
{
  SendText("&nbsp;`n`n")
}
; Ctrl + Alt + N : New Post
^!N::
{
  global LastIndex, LastTitle
  res := AdvInput("New Hugo Post", "Select new post's directory and its name", LastIndex, LastTitle, , 2)

  if (res[1] != "") {
    LastIndex := res[3]
    LastTitle := res[1]
    IniWrite(LastIndex, GetIniPath(), "New Post", "Last Index")
    IniWrite(LastTitle, GetIniPath(), "New Post", "Last Title")
    if (KeepConsole) {
      cmdSwitch := "/k"
    } else {
      cmdSwitch := "/c"
    }
    args := A_ComSpec . " " . cmdSwitch . " cd `"" . WorkingDir . "`" && npm run new " . res[2] . " " . res[1]
    Run(args, WorkingDir)
  }
}
; ---------------------------------------------------------------------------
; Variable
; ---------------------------------------------------------------------------
; Config variables
WorkingDir := IniGet("Setting", "Blog Repository Root", A_ScriptDir)
KeepConsole := IniGet("Setting", "Keep Console Open", false)
ExplorerExec := IniGet("Open Explorer", "Executable", "explorer.exe")
ExplorerArgs := IniGet("Open Explorer", "Arguments", "")
TestServerDir := IniGet("Start Hugo Test Server", "Start Directory", "")
TestServerExec := IniGet("Start Hugo Test Server", "Executable", "")
TestServerArgs := IniGet("Start Hugo Test Server", "Arguments", "")
TestPageExec := IniGet("Open Test Page", "Browser Executable", "firefox.exe")
TestPageArgs := IniGet("Open Test Page", "Arguments", "")
; Runtime variables (will be written back to INI)
LastIndex := IniGet("New Post", "Last Index", "3")
LastTitle := IniGet("New Post", "Last Title", "")
; Sanitize variables
KeepConsole := (IsNumber(KeepConsole) && KeepConsole == 0) ? 0 : 1
LastIndex := IsNumber(LastIndex) ? Number(LastIndex) : 3
; ---------------------------------------------------------------------------
; Tray Icon & Menu (+functions)
; ---------------------------------------------------------------------------
A_IconTip := "MarkdownHelper" ; Tray icon tip
;@Ahk2Exe-IgnoreBegin
TraySetIcon("icon_normal.ico")
;@Ahk2Exe-IgnoreEnd
MenuTray := A_TrayMenu
MenuTray.Delete() ; Reset tray menu
MenuTray.Add("Open &Explorer`tE", OpenExplorer)
MenuTray.Add("Start Hugo Test &Server`tS", RunServer)
MenuTray.Add("Open Test &Page`tP", OpenPage)
MenuTray.Add()
MenuTray.AddStandard()
; Modify keyboard shortcut of standard menu items
;@Ahk2Exe-IgnoreBegin
MenuTray.Rename("&Open", "Open")
MenuTray.Rename("&Help", "Help")
MenuTray.Rename("&Window Spy", "Window Spy")
MenuTray.Rename("&Reload Script", "Reload Script")
MenuTray.Rename("&Edit Script", "Edit Script")
;@Ahk2Exe-IgnoreEnd
MenuTray.Rename("&Suspend Hotkeys", "Suspend Hotkeys")
MenuTray.Rename("&Pause Script", "Pause Script")
MenuTray.Rename("E&xit", "E&xit`tX")
; Set default entry
MenuTray.Default := "E&xit`tX" ; Default action is 'Exit'
; Set menu item icon
MenuTray.SetIcon("Open &Explorer`tE", "imageres.dll", 4)
MenuTray.SetIcon("Start Hugo Test &Server`tS", "imageres.dll", 264)
MenuTray.SetIcon("Open Test &Page`tP", "netshell.dll", 86)
; Menu function
OpenExplorer(ItemName, ItemPos, MyMenu) {
  Run("`"" . ExplorerExec . "`" " . ExplorerArgs)
}
RunServer(ItemName, ItemPos, MyMenu) {
  Run("`"" . TestServerExec . "`" " . TestServerArgs, TestServerDir)
}
OpenPage(ItemName, ItemPos, MyMenu) {
  Run("`"" . TestPageExec . "`" " . TestPageArgs)
}
; Dark Context Menu
SetMenuAttr(MenuTray)
; ---------------------------------------------------------------------------
; Function
; ---------------------------------------------------------------------------
; SimpleInput : Show GUI and return value of Gui.Edit
SimpleInput(aTitle := A_ScriptName, aMessage := "", aIconFile := "shell32.dll", aIconIndex := 1, aTimeout := 10) {
  ResEdit := ""

  ; Set GUI icon (hack)
  TraySetIcon(aIconFile, aIconIndex)
  MyGui := Gui(, aTitle)
  /*@Ahk2Exe-Keep
  TraySetIcon("*")
  */
  ;@Ahk2Exe-IgnoreBegin
  TraySetIcon("icon_normal.ico")
  ;@Ahk2Exe-IgnoreEnd

  ; GUI option
  MyGui.Opt("+AlwaysOnTop -MaximizeBox -MinimizeBox -Resize +OwnDialogs")
  MyGui.OnEvent("Escape", (*) => (MyGui.Destroy()))

  ; GUI elements
  Gui_BtnCancel := MyGui.AddButton("x247 y129 w75 h23", "Cancel")
  Gui_BtnOK := MyGui.AddButton("x166 y129 w75 h23 +Default", "OK")
  Gui_Edit := MyGui.AddEdit("x12 y102 w310 h21 -Multi")
  Gui_Icon := MyGui.AddPicture("x12 y12 w32 h-1 Icon" . aIconIndex, aIconFile)
  Gui_Msg := MyGui.AddText("x50 y12 w272 h87", aMessage)
  Gui_Timer := MyGui.AddText("x20 y47 w17 h12", Format("{:02}", aTimeout))

  ; GUI event
  Gui_BtnOK.OnEvent("Click", (*) => (
    (Gui_Edit.Value == "") ? (Shake(MyGui)) : (
      ResEdit := Gui_Edit.Value, MyGui.Destroy()
    )
  ))
  Gui_BtnCancel.OnEvent("Click", (*) => (MyGui.Destroy()))

  ; Dark mode
  SetWinAttr(MyGui)
  SetWinTheme(MyGui)

  ; Show GUI
  MyGui.Show("AutoSize Center")
  Gui_Edit.Focus()

  ; Start timer
  GuiHwnd := MyGui.hwnd
  SetTimer(CountDown, 1000)
  WinWaitClose(GuiHwnd)
  return ResEdit

  CountDown() {
    if (WinExist("ahk_id" GuiHwnd)) {
      Gui_Timer.Text := Format("{:02}", --aTimeout)
    }
    if (!aTimeout) {
      MyGui.Destroy()
      ResEdit := ""
      SetTimer(, 0)
    }
  }
}
; AdvInput : Show GUI and return value of Gui.Edit and Gui.DDL
AdvInput(aTitle := A_ScriptName, aMessage := "", aDDLIndex := 3, aEditDefault := "", aIconFile := "shell32.dll", aIconIndex := 1, aTimeout := 30) {
  DDL_Key := ["Archon Quests (Genshin)", "Blue Archive", "Chit Chat", "Default", "Event Quests (Genshin)", "Game Misc", "Genshin Misc", "Honkai: Star Rail", "Minecraft", "Music", "Story Quests (Genshin)", "The Division", "World Quests (Genshin)"]
  DDL_Val := ["genshin-archon", "blue-archive", "chit-chat", "default", "genshin-event", "game-misc", "genshin-misc", "honkai-star-rail", "minecraft", "music", "genshin-story", "the-division", "genshin-world"]

  ResEdit := ""
  ResDDL := ""
  ResDDLIndex := aDDLIndex

  ; Set GUI icon (hack)
  TraySetIcon(aIconFile, aIconIndex)
  MyGui := Gui(, aTitle)
  /*@Ahk2Exe-Keep
  TraySetIcon("*")
  */
  ;@Ahk2Exe-IgnoreBegin
  TraySetIcon("icon_normal.ico")
  ;@Ahk2Exe-IgnoreEnd

  ; GUI option
  MyGui.Opt("+AlwaysOnTop -MaximizeBox -MinimizeBox -Resize +OwnDialogs")
  MyGui.OnEvent("Escape", (*) => (MyGui.Destroy()))

  ; GUI elements
  Gui_BtnCancel := MyGui.AddButton("x247 y129 w75 h23", "Cancel")
  Gui_BtnOK := MyGui.AddButton("x166 y129 w75 h23 +Default", "OK")
  Gui_Edit := MyGui.AddEdit("x12 y102 w310 h21 -Multi", aEditDefault)
  Gui_Icon := MyGui.AddPicture("x12 y12 w32 h-1 Icon" . aIconIndex, aIconFile)
  Gui_Msg := MyGui.AddText("x50 y12 w272 h83", aMessage)
  Gui_Timer := MyGui.AddText("x20 y47 w17 h12", Format("{:02}", aTimeout))
  Gui_DDL := MyGui.AddDropDownList("x12 y72 w310 h20 vPostDir Choose" . aDDLIndex . " R200", DDL_Key)

  ; Increase font size of DDL
  Gui_DDL.SetFont("s14")

  ; GUI event
  Gui_BtnOK.OnEvent("Click", (*) => (
    (Gui_Edit.Value == "") ? (Shake(MyGui)) : (
      ResEdit := Gui_Edit.Value, ResDDL := DDL_Val[Gui_DDL.Value], ResDDLIndex := Gui_DDL.Value, MyGui.Destroy()
    )
  ))
  Gui_BtnCancel.OnEvent("Click", (*) => (MyGui.Destroy()))

  ; Dark mode
  SetWinAttr(MyGui)
  SetWinTheme(MyGui)

  ; Show GUI
  MyGui.Show("AutoSize Center")
  Gui_Edit.Focus()

  ; Start timer
  GuiHwnd := MyGui.hwnd
  SetTimer(CountDown, 1000)
  WinWaitClose(GuiHwnd)
  return [ResEdit, ResDDL, ResDDLIndex]

  CountDown() {
    if (WinExist("ahk_id" GuiHwnd)) {
      Gui_Timer.Text := Format("{:02}", --aTimeout)
    }
    if (!aTimeout) {
      MyGui.Destroy()
      ResEdit := ""
      SetTimer(, 0)
    }
  }
}
; Shake: Shake given GUI
Shake(targetGui, aShakes := 20, aRattleX := 3, aRattleY := 3) {
  if (!IsObject(targetGui)) {
    return
  }
  oriX := 0, oriY := 0
  targetGui.GetPos(&oriX, &oriY)
  Loop aShakes {
    rx := Random(oriX - aRattleX, oriX + aRattleX)
    ry := Random(oriY - aRattleY, oriY + aRattleY)
    targetGui.Move(rx, ry)
    Sleep(10)
  }
  targetGui.Move(oriX, oriY)
}
; ---------------------------------------------------------------------------
; Dark Mode Function
; ---------------------------------------------------------------------------
; Source: https://www.autohotkey.com/boards/viewtopic.php?t=115952
DarkColors := Map("Background", "0x202020", "Controls", "0x404040", "Font", "0xE0E0E0")
TextBGBrush := DllCall("gdi32\CreateSolidBrush", "UInt", DarkColors["Background"], "Ptr")
SetMenuAttr(MenuObj) {
  global DarkColors
  if (VerCompare(A_OSVersion, "10.0.17763") >= 0) {
    DWMWA_USE_IMMERSIVE_DARK_MODE := 19
    if (VerCompare(A_OSVersion, "10.0.18985") >= 0) {
      DWMWA_USE_IMMERSIVE_DARK_MODE := 20
    }
    uxtheme := DllCall("kernel32\GetModuleHandle", "Str", "uxtheme", "Ptr")
    SetPreferredAppMode := DllCall("kernel32\GetProcAddress", "Ptr", uxtheme, "Ptr", 135, "Ptr")
    FlushMenuThemes := DllCall("kernel32\GetProcAddress", "Ptr", uxtheme, "Ptr", 136, "Ptr")

    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", A_ScriptHwnd, "Int", DWMWA_USE_IMMERSIVE_DARK_MODE, "Int*", True, "Int", 4)
    DllCall(SetPreferredAppMode, "Int", 2) ; 0=Default, 1=AllowDark, 2=ForceDark, 3=ForceLight, 4=Max
    DllCall(FlushMenuThemes)
  }
}
SetWinAttr(GuiObj) {
  global DarkColors
  if (VerCompare(A_OSVersion, "10.0.17763") >= 0) {
    DWMWA_USE_IMMERSIVE_DARK_MODE := 19
    if (VerCompare(A_OSVersion, "10.0.18985") >= 0) {
      DWMWA_USE_IMMERSIVE_DARK_MODE := 20
    }
    uxtheme := DllCall("kernel32\GetModuleHandle", "Str", "uxtheme", "Ptr")
    SetPreferredAppMode := DllCall("kernel32\GetProcAddress", "Ptr", uxtheme, "Ptr", 135, "Ptr")
    FlushMenuThemes := DllCall("kernel32\GetProcAddress", "Ptr", uxtheme, "Ptr", 136, "Ptr")

    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", GuiObj.Hwnd, "Int", DWMWA_USE_IMMERSIVE_DARK_MODE, "Int*", True, "Int", 4)
    DllCall(SetPreferredAppMode, "Int", 2) ; 0=Default, 1=AllowDark, 2=ForceDark, 3=ForceLight, 4=Max
    DllCall(FlushMenuThemes)
    GuiObj.BackColor := DarkColors["Background"]
  }
}
SetWinTheme(GuiObj) {
  static GWL_WNDPROC := -4
  static GWL_STYLE := -16
  static ES_MULTILINE := 0x0004
  static LVM_GETTEXTCOLOR := 0x1023
  static LVM_SETTEXTCOLOR := 0x1024
  static LVM_GETTEXTBKCOLOR := 0x1025
  static LVM_SETTEXTBKCOLOR := 0x1026
  static LVM_GETBKCOLOR := 0x1000
  static LVM_SETBKCOLOR := 0x1001
  static LVM_GETHEADER := 0x101F
  static GetWindowLong := A_PtrSize = 8 ? "GetWindowLongPtr" : "GetWindowLong"
  static SetWindowLong := A_PtrSize = 8 ? "SetWindowLongPtr" : "SetWindowLong"
  Init := False
  LV_Init := False

  Mode_Explorer := "DarkMode_Explorer"
  Mode_CFD := "DarkMode_CFD"
  Mode_ItemsView := "DarkMode_ItemsView"

  for hWnd, GuiCtrlObj in GuiObj {
    switch GuiCtrlObj.Type {
      case "Button", "CheckBox", "ListBox", "UpDown", "Text":
      {
        DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_Explorer, "Ptr", 0)
      }
      case "ComboBox", "DDL":
      {
        DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_CFD, "Ptr", 0)
      }
      case "Edit":
      {
        if (DllCall("user32\" . GetWindowLong, "Ptr", GuiCtrlObj.hWnd, "Int", GWL_STYLE) & ES_MULTILINE) {
          DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_Explorer, "Ptr", 0)
        } else {
          DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_CFD, "Ptr", 0)
        }
      }
      case "ListView":
      {
        if !(LV_Init) {
          static LV_TEXTCOLOR := SendMessage(LVM_GETTEXTCOLOR, 0, 0, GuiCtrlObj.hWnd)
          static LV_TEXTBKCOLOR := SendMessage(LVM_GETTEXTBKCOLOR, 0, 0, GuiCtrlObj.hWnd)
          static LV_BKCOLOR := SendMessage(LVM_GETBKCOLOR, 0, 0, GuiCtrlObj.hWnd)
          LV_Init := True
        }
        GuiCtrlObj.Opt("-Redraw")
        SendMessage(LVM_SETTEXTCOLOR, 0, DarkColors["Font"], GuiCtrlObj.hWnd)
        SendMessage(LVM_SETTEXTBKCOLOR, 0, DarkColors["Background"], GuiCtrlObj.hWnd)
        SendMessage(LVM_SETBKCOLOR, 0, DarkColors["Background"], GuiCtrlObj.hWnd)
        DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_Explorer, "Ptr", 0)
        ; To color the selection - scrollbar turns back to normal
        ;DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_ItemsView, "Ptr", 0)
        LV_Header := SendMessage(LVM_GETHEADER, 0, 0, GuiCtrlObj.hWnd)
        DllCall("uxtheme\SetWindowTheme", "Ptr", LV_Header, "Str", Mode_ItemsView, "Ptr", 0)
        GuiCtrlObj.Opt("+Redraw")
      }
    }
  }
  if !(Init) {
    ; https://www.autohotkey.com/docs/v2/lib/CallbackCreate.htm#ExSubclassGUI
    global WindowProcNew := CallbackCreate(WindowProc)  ; Avoid fast-mode for subclassing.
    global WindowProcOld := DllCall("user32\" . SetWindowLong, "Ptr", GuiObj.Hwnd, "Int", GWL_WNDPROC, "Ptr", WindowProcNew, "Ptr")
    Init := True
  }
}
WindowProc(hwnd, uMsg, wParam, lParam) {
  critical
  static WM_CTLCOLOREDIT := 0x0133
  static WM_CTLCOLORLISTBOX := 0x0134
  static WM_CTLCOLORBTN := 0x0135
  static WM_CTLCOLORSTATIC := 0x0138
  static DC_BRUSH := 18

  switch uMsg {
    case WM_CTLCOLOREDIT, WM_CTLCOLORLISTBOX:
    {
      DllCall("gdi32\SetTextColor", "Ptr", wParam, "UInt", DarkColors["Font"])
      DllCall("gdi32\SetBkColor", "Ptr", wParam, "UInt", DarkColors["Controls"])
      DllCall("gdi32\SetDCBrushColor", "Ptr", wParam, "UInt", DarkColors["Controls"], "UInt")
      return DllCall("gdi32\GetStockObject", "Int", DC_BRUSH, "Ptr")
    }
    case WM_CTLCOLORBTN:
    {
      DllCall("gdi32\SetDCBrushColor", "Ptr", wParam, "UInt", DarkColors["Background"], "UInt")
      return DllCall("gdi32\GetStockObject", "Int", DC_BRUSH, "Ptr")
    }
    case WM_CTLCOLORSTATIC:
    {
      DllCall("gdi32\SetTextColor", "Ptr", wParam, "UInt", DarkColors["Font"])
      DllCall("gdi32\SetBkColor", "Ptr", wParam, "UInt", DarkColors["Background"])
      return TextBGBrush
    }
  }
  return DllCall("user32\CallWindowProc", "Ptr", WindowProcOld, "Ptr", hwnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam)
}
; ---------------------------------------------------------------------------
; Event
; ---------------------------------------------------------------------------
; OnExit : Play ding sound when exit by #SingleInstance Force
OnExitFunc(ExitReason, ExitCode) {
  if (ExitReason == "Single" || ExitReason == "Reload") {
    SoundPlay "*-48"
  }
}
OnExit(OnExitFunc)
