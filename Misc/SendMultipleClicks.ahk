; SendMultipleClicks - Send multiple 'Click' key stroke to BlueStacks window
; Because BlueStacks' own Multiple click forces long interval

#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%
DetectHiddenWindows On
#Include ..\Library\INI.ahk

;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright 2022. TetraTheta. All rights reserved.
;@Ahk2Exe-SetProductName SendMultipleClicks
;@Ahk2Exe-SetDescription Send multiple 'Click' key stroke to BlueStacks window
;@Ahk2Exe-SetFileVersion 1.0.0.0
;@Ahk2Exe-SetLanguage 0x0412

window_title := IniGet("BlueStacks", "Window Title", "N64")
click_key := GetKeyName(IniGet("BlueStacks", "Click Key", "Numpad0"))
multiple_click_key := GetKeyName(IniGet("General", "Multiple Click Key", "NumpadDot"))
press_interval := IniGet("General", "Multiple Click Interval", 100)
press_count := IniGet("General", "Click Count", 2)

Hotkey, % multiple_click_key, SendMultipleClicks

Return

SendMultipleClicks:
hwnd := WinExist(widow_title . " ahk_exe HD-Player.exe")
If(hwnd) {
  ; Comparing hwnd with WinActive(widow_title . " ahk_exe HD-Player.exe") fails. Why?
  SetKeyDelay, % press_interval
  delay := press_interval - 10
  Loop, % press_count {
    ; ControlSend doesn't work on BlueStacks
    Send, {%click_key% down}
    Sleep, % delay
    Send, {%click_key% up}
  }
}
Return
