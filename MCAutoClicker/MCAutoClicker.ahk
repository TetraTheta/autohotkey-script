/**
 * MCAutoClicker v2.0.1 : Auto clicker for Minecraft
 */
#Requires AutoHotkey v2
#Include "..\Lib\ini.ahk"
#SingleInstance Force
InstallMouseHook(True, True)
DetectHiddenWindows(True)

; Information about executable
;@Ahk2Exe-AddResource icon_grey.ico, 206 ; Suspend icon - Gray
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright 2023. TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription Auto clicker for Minecraft
;@Ahk2Exe-SetFileVersion 2.0.1.0
;@Ahk2Exe-SetLanguage 0x0412
;@Ahk2Exe-SetMainIcon icon_normal.ico ; Default icon
;@Ahk2Exe-SetProductName MCAutoClicker

; Set tray icon stuff
A_IconTip := "MCAutoClicker" ; Tray icon tip
;@Ahk2Exe-IgnoreBegin
TraySetIcon("icon_normal.ico")
;@Ahk2Exe-IgnoreEnd

; Create menu
MenuTray := A_TrayMenu ; Main tray menu
MenuTray.Delete() ; Reset default tray menu
MenuTraySub := Menu() ; Sub tray menu
; Submenu
if (!A_IsCompiled) {
  MenuTraySub.Add("Edit Script`tE", EditScript)
}
MenuTraySub.Add("Reload Script`tR", ReloadScript)
MenuTraySub.Add() ; Create separator
MenuTraySub.Add("Suspend Script`tS", SuspendScript)
; Menu
MenuTray.Add("&Hotkey List`tH", ShowHotkey)
MenuTray.Default := "&Hotkey List`tH"
MenuTray.Add() ; Create separator
MenuTray.Add("Advanced Menu`tA", MenuTraySub)
MenuTray.Add() ; Create separator
MenuTray.Add("Exit Script`tX", ExitScript)

; Read INI file for settings
beep := IniGet("General", "Beep", 0)
click_interval := IniGet("Minecraft", "Click Interval", 1000)
game_title := IniGet("Minecraft", "Window Title", "Minecraft* (version hidden from driver) - Multiplayer (3rd-party Server)")
toggle_keep_click := False
toggle_repeat_click := False

minecraft_hwnd := "" ; Temporary variable because SetTimer can't execute function with parameter :(

#HotIf WinExist(game_title)
XButton1::
F10::
{
  ToggleClickKeep()
}
XButton2::
F11::
{
  ToggleClickRepeat()
}
#HotIf

; Functions
EditScript(ItemName, ItemPos, TheMenu) {
  ; Double check because A_ScriptFullPath will return EXE file if run at compiled script
  if (!A_IsCompiled) {
    ;@Ahk2Exe-IgnoreBegin
    RunWait("`"notepad.exe`" `"" . A_ScriptFullPath . "`"")
    Reload()
    ;@Ahk2Exe-IgnoreEnd
  }
}
ReloadScript(ItemName, ItemPos, TheMenu) {
  Reload()
}
SuspendScript(ItemName, ItemPos, TheMenu) {
  Suspend(-1)
  if (A_IsSuspended) {
    ; Script is now suspended
    ; Change menu item name
    MenuTraySub.Rename("Suspend Script`tS", "Resume Script`tS")
    ; Change Icon
    if (A_IsCompiled) {
      TraySetIcon(A_ScriptFullPath, -206)
    } else {
      ;@Ahk2Exe-IgnoreBegin
      TraySetIcon("icon_grey.ico")
      ;@Ahk2Exe-IgnoreEnd
    }
  } else {
    ; Script is now active
    ; Change menu item name
    MenuTraySub.Rename("Resume Script`tS", "Suspend Script`tS")
    ; Change Icon
    if (A_IsCompiled) {
      TraySetIcon(A_ScriptFullPath, -159)
    } else {
      ;@Ahk2Exe-IgnoreBegin
      TraySetIcon("icon_normal.ico")
      ;@Ahk2Exe-IgnoreEnd
    }
  }
}
ShowHotkey(ItemName, ItemPos, TheMenu) {
  ListHotkeys()
}
ExitScript(ItemName, ItemPos, TheMenu) {
  ExitApp()
}
; Code related to click multiple times
ToggleClickRepeat() {
  global toggle_repeat_click, click_interval, minecraft_hwnd
  if (toggle_repeat_click) {
    ; toggle_repeat_click is On
    toggle_repeat_click := False
    SetTimer(ClickRepeat, 0)
  } else {
    ; toggle_repeat_click is Off
    toggle_repeat_click := True
    minecraft_hwnd := WinGetID(game_title)
    SetTimer(ClickRepeat, click_interval)
    ClickRepeat()
  }
}
ClickRepeat() {
  global beep, minecraft_hwnd
  SetControlDelay(-1)
  ControlClick(,"ahk_id " . minecraft_hwnd,,,,"NA")
  if (beep = True) {
    SoundBeep(1500)
  }
}
; Code related to keep click state
ToggleClickKeep() {
  global toggle_keep_click, game_title
  if (!InStr(WinGetTitle("A"), game_title) || !(WinGetProcessName("A") == "javaw.exe")) {
    Click("X1")
    return
  } else {
    if (toggle_keep_click) {
      ; toggle_keep_click is On
      toggle_keep_click := False
      Click("Left Up")
    } else {
      ; toggle_keep_click is Off
      toggle_keep_click := True
      Click("Left Down")
    }
  }
}
