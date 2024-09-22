/************************************************************************
 * @description Simple script for Garry's Mod
 * @author TetraTheta
 * @date 2024/09/06
 * @version 0.1.0
 ***********************************************************************/
#Requires AutoHotkey v2.0
#SingleInstance Force
InstallMouseHook(True, True)
DetectHiddenWindows(True)
;SetKeyDelay 50, 50

click_speed := 50
is_clicking := false
gmod_hwnd := 0

; ---------------------------------------------------------------------------
; Hotkey
; ---------------------------------------------------------------------------
#HotIf WinExist("ahk_exe gmod.exe")
MButton::ToggleClickRepeat()
#HotIf

ToggleClickRepeat() {
  global is_clicking, click_speed, gmod_hwnd
  if (is_clicking) {
    is_clicking := False
    SetTimer(ClickRepeat, 0)
    SoundPlay(A_WinDir . "/Media/Speech Off.wav", true)
  } else {
    is_clicking := True
    gmod_hwnd := WinGetID("Garry's Mod (x64)")
    SetTimer(ClickRepeat, click_speed)
    ClickRepeat()
    SoundPlay(A_WinDir . "/Media/Speech On.wav", true)
  }
}
ClickRepeat() {
  global gmod_hwnd
  SetControlDelay(-1)
  ControlClick(,"ahk_id " . gmod_hwnd,,,,"NA")
  ;ControlSend("q",, "ahk_id " . gmod_hwnd)
}
