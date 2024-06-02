/************************************************************************
 * @description Helper for ShareX for taking screenshots from various games
 * @file ShareX-Helper.ahk
 * @author TetraTheta
 * @date 2024/06/01
 * @version 1.0.0
 ***********************************************************************/
#Requires AutoHotkey v2.0
#Include "..\Lib\darkMode.ahk"
#Include "..\Lib\ini.ahk"
#Include "..\Lib\KV.ahk"
#SingleInstance Force

; Information about executable
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright 2024. TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription Helper for ShareX for taking screenshots from various games
;@Ahk2Exe-SetFileVersion 1.0.0.0
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
ShareXExec := IniGet("Setting", "ShareX Executable", "")
RunShareXOnLaunch := IniGet("Setting", "Launch ShareX on Launch", false)
GameCount := IniGet("Setting", "Max Games", 5)
;
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
; Sanitize variables
RunShareXOnLaunch := (IsNumber(RunShareXOnLaunch) && RunShareXOnLaunch == 0) ? false : true
; Misc
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
MenuTray.Add("Share&X`tX", OpenShareX)
MenuTray.Add()
Loop(GameList.Length) {
  NewTitle := "[&" . A_Index . "] " . GameList[A_Index].Name . "`t" . A_Index
  MenuTray.Add(NewTitle, RunGame)
  MenuTray.SetIcon(NewTitle, GameList[A_Index].IconPath, GameList[A_Index].IconIndex)
}
MenuTray.Add()
MenuTray.Add("Exit", ExitScript)
MenuTray.SetIcon("Share&X`tX", ShareXExec)
MenuTray.SetIcon("Exit", "imageres.dll", 85)
; Set default entry
MenuTray.Default := "Exit" ; Default action is 'Exit'
; Menu function
OpenShareX(*) {
  Run("`"" . ShareXExec . "`"")
}
ExitScript(*) {
  ExitApp()
}
RunGame(ItemName, ItemPos, *) {
  GameIndex := ItemPos - 2
  local runcmd := ""
  if (InStr(GameList[GameIndex].Path, "`"") == 1) {
    runcmd := GameList[GameIndex].Path
  } else {
    runcmd := "`"" . GameList[GameIndex].Path . "`""
  }
  Run(GameList[GameIndex].Path)
}
; Dark Context Menu
SetMenuAttr()
; ------------------------------------------------------------------------------
; Function
; ------------------------------------------------------------------------------
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
