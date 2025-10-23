/************************************************************************
 * @description Helper for ShareX for taking screenshots from various games
 * @author TetraTheta
 * @date 2024/06/01
 * @version 1.1.0
 ***********************************************************************/
#Requires AutoHotkey v2.0
#Include "..\Lib\darkMode.ahk"
#Include "..\Lib\ini.ahk"
#SingleInstance Force

; Information about executable
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright 2024. TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription Helper for ShareX for taking screenshots from various games
;@Ahk2Exe-SetFileVersion 1.1.0.0
;@Ahk2Exe-SetMainIcon icon\sharex_helper_icon_normal.ico ; Default icon
;@Ahk2Exe-SetProductName ShareX Helper
;@Ahk2Exe-UpdateManifest 1 ; Require administrative privileges

; ------------------------------------------------------------------------------
; Class
; ------------------------------------------------------------------------------
class Game {
  __New(newName, newPath, newIconPath, newIconIndex, newAbsExe, newAbsTitle) {
    this.Name := newName
    this.Path := newPath
    this.IconPath := newIconPath
    this.IconIndex := newIconIndex
    this.AbsExe := newAbsExe
    this.AbsTitle := newAbsTitle
  }
}
; ------------------------------------------------------------------------------
; Hotkey
; ------------------------------------------------------------------------------
;XButton2::SendEvent("{Alt Down}{PrintScreen Down}{PrintScreen Up}{Alt Up}")
XButton2::TakeScreenshot()
; ------------------------------------------------------------------------------
; Variable
; ------------------------------------------------------------------------------
; Config variables
ExplorerPath := IniGet("Explorer", "Binary Path", "explorer.exe")
ExplorerArgument := IniGet("Explorer", "Binary Argument", "")
GameCount := IniGet("Setting", "Max Games", 5)
ShareXExec := IniGet("ShareX", "ShareX Executable", "")
RunShareXOnLaunch := IniGet("ShareX", "Launch ShareX on Launch", false)
CloseShareXOnExit := IniGet("ShareX", "Close ShareX on Exit", false)
HideTaskBar := IniGet("Taskbar", "Hide Taskbar on Game Launch", false)
GameList := []
Loop(GameCount) {
  NewName := IniGet("Game", "Game " . A_Index . " Name", "")
  NewPath := IniGet("Game", "Game " . A_Index . " Path", "")
  NewIconPath := IniGet("Game", "Game " . A_Index . " Icon Path", NewPath)
  NewIconIndex := IniGet("Game", "Game " . A_Index . " Icon Index", 1)
  NewAbsExe := IniGet("Game", "Game " . A_Index . " Absolute Exe File", "")
  NewAbsTitle := IniGet("Game", "Game " . A_Index . " Absolute Title", "")
  if (NewName != "") {
    GameList.Push(Game(NewName, NewPath, NewIconPath, NewIconIndex, NewAbsExe, NewAbsTitle))
  }
}
; Runtime variable
InitTBState := GetTBState() ; 0: Always on Top / 1: Auto-hide
TBState := InitTBState
; Sanitize variables
RunShareXOnLaunch := (IsNumber(RunShareXOnLaunch) && RunShareXOnLaunch == 0) ? false : true
CloseShareXOnExit := (IsNumber(CloseShareXOnExit) && CloseShareXOnExit == 0) ? false : true
HideTaskBar := (IsNumber(HideTaskBar) && HideTaskBar == 0) ? false : true
; Misc
DetectHiddenWindows(true)
SetKeyDelay(200, 50)
if (RunShareXOnLaunch) {
  OpenShareX()
}
; ------------------------------------------------------------------------------
; Tray Icon & Menu (+functions)
; ------------------------------------------------------------------------------
A_IconTip := "ShareX Helper" ; Tray icon tip
;@Ahk2Exe-IgnoreBegin
TraySetIcon("icon\sharex_helper_icon_normal.ico")
;@Ahk2Exe-IgnoreEnd
; Re-define tray menu
MenuTray := A_TrayMenu
MenuTray.Delete() ; Reset tray menu
MenuTray.Add("&Explorer`tE", OpenExplorer)
MenuTray.Add()
MenuTray.Add("Share&X`tX", OpenShareX)
MenuTray.Add()
Loop(GameList.Length) {
  NewTitle := "[&" . A_Index . "] " . GameList[A_Index].Name . "`t" . A_Index
  MenuTray.Add(NewTitle, RunGame)
  MenuTray.SetIcon(NewTitle, GameList[A_Index].IconPath, GameList[A_Index].IconIndex)
}
MenuTray.Add()
MenuTray.Add("AutoHide Taskbar", ToggleTB)
MenuTray.Add()
MenuTray.Add("Exit", (*) => ExitApp())
MenuTray.SetIcon("&Explorer`tE", ExplorerPath)
MenuTray.SetIcon("Share&X`tX", ShareXExec)
MenuTray.SetIcon("Exit", "imageres.dll", 85)
if (InitTBState == 1) {
  MenuTray.Check("AutoHide Taskbar")
}
; Set default entry
MenuTray.Default := "Exit" ; Default action is 'Exit'
; Menu function
OpenExplorer(*) {
  Run('"' . ExplorerPath . '" ' . ExplorerArgument)
}
OpenShareX(*) {
  Run('"' . ShareXExec . '"')
}
RunGame(ItemName, ItemPos, *) {
  global TBState
  if (HideTaskBar) {
    TBState := 0 ; Temporarily set it to 'Always on Top'
    ToggleTB("AutoHide Taskbar")
  }
  GameIndex := ItemPos - 4
  Path := GameList[GameIndex].Path
  if (SubStr(Path, 1, 1) != '"') {
    Path := '"' . Path . '"'
  }
  Run(Path)
}
ToggleTB(ItemName, *) {
  global TBState
  if (TBState) {
    TBState := false
    HideTB(false)
    MenuTray.Uncheck(ItemName)
  } else {
    TBState := true
    HideTB(true)
    MenuTray.Check(ItemName)
  }
}
; Dark Context Menu
SetMenuAttr()
; ------------------------------------------------------------------------------
; Function
; ------------------------------------------------------------------------------
GetTBState() {
  static ABM_GETSTATE := 0x4
  size := A_PtrSize * 3 + 24
  APPBARDATA := Buffer(size, 0)
  NumPut("UInt", size, APPBARDATA)
  return DllCall("Shell32\SHAppBarMessage", "UInt", ABM_GETSTATE, "Ptr", APPBARDATA, "Ptr")
}
HideTB(status) {
  static ABM_SETSTATE := 0xA, ABS_AUTOHIDE := 0x1, ABS_ALWAYSONTOP := 0x2
  size := A_PtrSize * 3 + 24
  APPBARDATA := Buffer(size, 0)
  NumPut("UInt", size, APPBARDATA)
  NumPut("Ptr", WinExist("ahk_class Shell_TrayWnd"), APPBARDATA, A_PtrSize)
  NumPut("UInt", status ? ABS_AUTOHIDE : ABS_ALWAYSONTOP, APPBARDATA, size - A_PtrSize)
  DllCall("Shell32\SHAppBarMessage", "UInt", ABM_SETSTATE, "Ptr", APPBARDATA)
}
TakeScreenshot() {
  local activeTitle := WinGetTitle("A")
  local activeExe := WinGetProcessName("A")
  for g in GameList {
    if (g.AbsExe == "") {
      continue
    }
    if (g.AbsExe == activeExe) {
      ; g.AbsExe == activeExe && g.AbsTitle == activeTitle
      SendEvent("!{PrintScreen}")
      return
    }
  }
  SendEvent("{XButton2}")
}
; ------------------------------------------------------------------------------
; Event
; ------------------------------------------------------------------------------
; OnExit : Play ding sound when exit by #SingleInstance Force
OnExitFunc(ExitReason, ExitCode) {
  if (ExitReason == "Single" || ExitReason == "Reload") {
    SoundPlay("*48")
  } else {
    if (HideTaskBar) {
      HideTB(InitTBState)
    }
    if (RunShareXOnLaunch && WinExist("ahk_exe ShareX.exe")) {
      WinClose("ahk_exe ShareX.exe")
      ProcessClose("ShareX.exe")
    }
  }
}
OnExit(OnExitFunc)
