/************************************************************************
 * @description Utility for Tower of Fantasy
 * @file TOFUtility.ahk
 * @author TetraTheta
 * @date 2024/02/26
 * @version 1.0.0
 ***********************************************************************/
#Requires AutoHotkey v2.0
#Include "..\Lib\darkMode.ahk"
#SingleInstance Force
;@Ahk2Exe-UpdateManifest 1 ; Require administrative privileges

; Information about executable
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright (c) TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription Utility for Tower of Fantasy
;@Ahk2Exe-SetFileVersion 1.0.0.0
;@Ahk2Exe-SetLanguage 0x0412
;@Ahk2Exe-SetMainIcon icon\tofutility_icon_normal.ico ; Default icon
;@Ahk2Exe-SetProductName TOFUtility

; ---------------------------------------------------------------------------
; Hotkey
; ---------------------------------------------------------------------------
; Mouse3 : Keep attacking
MButton::
{
  global click_repeat_toggle, game_hwnd
  if (WinActive("ahk_exe QRSL.exe")) {
    if (click_repeat_toggle) {
      ; Turn off repeat clicking
      click_repeat_toggle := false
      SetTimer(RepeatClick, 0)
      SoundPlay(A_WinDir . "/Media/Speech Off.wav", true)
    } else {
      ; Turn on repeat clicking
      click_repeat_toggle := true
      game_hwnd := WinGetID("ahk_exe QRSL.exe")
      SetTimer(RepeatClick, 350)
      RepeatClick()
      SoundPlay(A_WinDir . "/Media/Speech On.wav", true)
    }
  } else {
    SendInput("{MButton}")
  }
}
; Mouse4 : Guren Blade Super Jump
XButton1::
{
  if (WinActive("ahk_exe QRSL.exe")) {
    SendInput("{click down}")
    Sleep(1)
    SendInput("{click up}")
    Sleep(300)
    SendInput("{click down}")
    Sleep(1)
    SendInput("{click up}")
    Sleep(270)
    SendInput("{q down}")
    Sleep(1)
    SendInput("{q up}")
    Sleep(1)
    SendInput("{q down}")
    Sleep(1)
    SendInput("{q up}")
    Sleep(1)
  } else {
    SendInput("{XButton1}")
  }
}
; Mouse5 : Take screenshot
XButton2::
{
  if (WinActive("ahk_exe QRSL.exe")) {
    SendInput("{LAlt down}{PrintScreen down}{PrintScreen up}{LAlt up}")
  } else {
    SendInput("{XButton2}")
  }
}
; ---------------------------------------------------------------------------
; Variable
; ---------------------------------------------------------------------------
click_repeat_toggle := false
game_hwnd := WinExist("ahk_exe QRSL.exe") ? WinGetID("ahk_exe QRSL.exe") : 0
; ---------------------------------------------------------------------------
; Tray Icon & Menu (+functions)
; ---------------------------------------------------------------------------
A_IconTip := "TOF Utility"
;@Ahk2Exe-IgnoreBegin
TraySetIcon("icon\tofutility_icon_normal.ico")
;@Ahk2Exe-IgnoreEnd
MenuTray := A_TrayMenu
MenuTray.Delete()
MenuTray.Add("E&xit Program`tX", ExitScript)
MenuTray.Default := "E&xit Program`tX"
ExitScript(*) {
  ExitApp()
}
; Dark Context Menu
SetMenuAttr()
; ---------------------------------------------------------------------------
; Function
; ---------------------------------------------------------------------------
RepeatClick() {
  global game_hwnd
  SetControlDelay(-1)
  if (!GetKeyState("w", "P") && !GetKeyState("a", "P") && !GetKeyState("s", "P") && !GetKeyState("d", "P")) {
    ControlClick(,"ahk_id" . game_hwnd,,,,"NA")
  }
}
; ---------------------------------------------------------------------------
; Event
; ---------------------------------------------------------------------------
; OnExit : Play ding sound when exit by #SingleInstance Force
OnExitFunc(ExitReason, ExitCode) {
  if (ExitReason == "Single" || ExitReason == "Reload") {
    SoundPlay("*48")
  }
}
OnExit(OnExitFunc)
