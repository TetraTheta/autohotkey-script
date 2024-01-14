/**
 * MarkdownHelper v1.0.0 : My Hugo Blog Markdown Helper
 */
#Requires AutoHotkey v2.0
#Include "..\Lib\ini.ahk"
#Include "..\Lib\darkMode.ahk"
#SingleInstance Force

; Information about executable
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright 2023. TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription My Hugo Blog Markdown Helper
;@Ahk2Exe-SetFileVersion 1.1.0.0
;@Ahk2Exe-SetLanguage 0x0412
;@Ahk2Exe-SetMainIcon icon_normal.ico ; Default icon
;@Ahk2Exe-SetProductName MarkdownHelper

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
; Ctrl + Shift + C : Show Tidy GUI
^+C::
{
  TidyInput()
}
; ---------------------------------------------------------------------------
; Variable
; ---------------------------------------------------------------------------
; Config variables
WorkingDir := IniGet("Setting", "Blog Repository Root", A_ScriptDir)
KeepConsole := IniGet("Setting", "Keep Console Open", false)
ExplorerExec := IniGet("Open Explorer", "Executable", "explorer.exe")
ExplorerArgs := IniGet("Open Explorer", "Arguments", "")
CmdExec := IniGet("Open Terminal", "Executable", A_ComSpec)
CmdArgs := IniGet("Open Terminal", "Arguments", "/K cd /d C:\")
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
MenuTray.Add("Open &Terminal`tT", OpenTerminal)
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
MenuTray.SetIcon("Open &Terminal`tT", "imageres.dll", 264)
MenuTray.SetIcon("Start Hugo Test &Server`tS", "imageres.dll", 264)
MenuTray.SetIcon("Open Test &Page`tP", "netshell.dll", 86)
; Menu function
OpenExplorer(ItemName, ItemPos, MyMenu) {
  Run("`"" . ExplorerExec . "`" " . ExplorerArgs)
}
OpenTerminal(ItemName, ItemPos, MyMenu) {
  Run("`"" . CmdExec . "`" " . CmdArgs)
}
RunServer(ItemName, ItemPos, MyMenu) {
  Run("`"" . TestServerExec . "`" " . TestServerArgs, TestServerDir)
}
OpenPage(ItemName, ItemPos, MyMenu) {
  Run("`"" . TestPageExec . "`" " . TestPageArgs)
}
; Dark Context Menu
SetMenuAttr()
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
  DDL_Key := ["Archon Quests (Genshin)", "Blue Archive", "Chit Chat", "Default", "Event Quests (Genshin)", "Game Misc", "Genshin Misc", "Honkai: Star Rail", "Minecraft", "Music", "Story Quests (Genshin)", "The Division", "Tower of Fantasy", "World Quests (Genshin)"]
  DDL_Val := ["genshin-archon", "blue-archive", "chit-chat", "default", "genshin-event", "game-misc", "genshin-misc", "honkai-star-rail", "minecraft", "music", "genshin-story", "the-division", "tower-of-fantasy", "genshin-world"]

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
; TidyInput: Show GUI which removes excessive line breaks
TidyInput() {
  TraySetIcon("shell32.dll", 2)
  MyGui := Gui(, "Tidy Text")
  /*@Ahk2Exe-Keep
  TraySetIcon("*")
  */
  ;@Ahk2Exe-IgnoreBegin
  TraySetIcon("icon_normal.ico")
  ;@Ahk2Exe-IgnoreEnd

  ; GUI option
  MyGui.Opt("-MaximizeBox -MinimizeBox -Resize +OwnDialogs")
  MyGui.OnEvent("Escape", (*) => (MyGui.Destroy()))

  ; GUI elements
  Gui_Input := MyGui.AddEdit("x12 y12 w600 h600 +Multi +Wrap")
  Gui_Tidy := MyGui.AddButton("x12 y618 w600 h23", "Tidy && Copy")

  ; GUI event
  Gui_Tidy.OnEvent("Click", (*) => (
    (Gui_Input.Value == "") ? (Shake(MyGui)) : (
      Gui_Input.Value := TidyCopyText(Gui_Input.Value), MyGui.Destroy()
    )
  ))

  ; Dark mode
  SetWinAttr(MyGui)
  SetWinTheme(MyGui)

  ; Show GUI
  MyGui.Show("AutoSize Center")
  Gui_Input.Focus()
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
; TidyCopyText: Tidy the text and copy it to clipboard
TidyCopyText(input) {
  output := RegExReplace(input, "(\s*[\r\n]){2,}", "`n`n")
  output := LTrim(output, "`n")
  output := RTrim(output, "`n")
  
  A_Clipboard := output
  return output
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
