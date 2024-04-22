/**
 * BlueStacksMultiClick v1.0.0 : Send multiple 'Click' key stroke to BlueStacks windows
 */
; BlueStacks' own Multiple Click cannot be configured to click in short interval and that's why this script does exist

#Requires AutoHotkey v2
#Include "..\..\Lib\ini.ahk"
#SingleInstance Force
DetectHiddenWindows(True)

; Information about executable
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright 2023. TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription Send multiple 'Click' key stroke to BlueStacks window
;@Ahk2Exe-SetFileVersion 1.0.0.0
;@Ahk2Exe-SetLanguage 0x0412
;@Ahk2Exe-SetMainIcon icon_normal.ico ; Default icon
;@Ahk2Exe-SetProductName BlueStacksMultiClick

; Set tray icon stuff
A_IconTip := "BlueStacksMultiClick" ; Tray icon tip
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
MenuTray.Add("&Help`tH", ShowHelp)
MenuTray.Default := "&Help`tH"
MenuTray.Add() ; Create separator
MenuTray.Add("Advanced Menu`tA", MenuTraySub)
MenuTray.Add() ; Create separator
MenuTray.Add("Exit Script`tX", ExitScript)

; Read INI file for settings
window_title := IniGet("BlueStacks", "Window Title", "N64")
click_key := GetKeyName(IniGet("BlueStacks", "Click Key", "Numpad0"))
multiple_click_key := GetKeyName(IniGet("General", "Multiple Click Key", "NumpadDot"))
press_interval := IniGet("General", "Multiple Click Interval", 100)
press_count := IniGet("General", "Click Count", 2)

; Hotkey
Hotkey(multiple_click_key, SendMultipleClicks)

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
ShowHelp(ItemName, ItemPos, TheMenu) {

}
ExitScript(ItemName, ItemPos, TheMenu) {
  ExitApp()
}
SendMultipleClicks(HotkeyName) {
  global window_title, press_interval, press_count, click_key
  hwnd := WinExist(window_title . " ahk_exe HD-Player.exe")
  if (hwnd) {
    ; Comparing hwnd with WinActive(widow_title . " ahk_exe HD-Player.exe") fails. Why?
    SetKeyDelay(press_interval)
    delay := press_interval - 10
    Loop(press_count) {
      ; ControlSend doesn't work on BlueStacks
      Send("{" . click_key . " down}")
      Sleep(delay)
      Send("{" . click_key . " up}")
    }
  }
}
