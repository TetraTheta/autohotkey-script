/************************************************************************
 * @description Utility for ONE GameLoop
 * @author TetraTheta
 * @date 2025/04/15
 * @version 1.0.0
 ***********************************************************************/
#Requires AutoHotkey v2.0
#Include "..\Lib\darkMode.ahk"
#SingleInstance Force
DetectHiddenWindows(True)
DetectHiddenText(True)
SetDefaultMouseSpeed(0)

; Information about executable
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright (c) TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription Utility for ONE GameLoop
;@Ahk2Exe-SetFileVersion 1.0.0.0
;@Ahk2Exe-SetLanguage 0x0412
;@Ahk2Exe-SetProductName ONE-GameLoop-Helper
;@Ahk2Exe-UpdateManifest 1 ; Require administrative privileges

; ---------------------------------------------------------------------------
; Hotkey
; ---------------------------------------------------------------------------
; ESC : Back
$Escape::
{
  if (WinActive("ahk_exe AndroidEmulatorEx.exe")) {
    OriX := 0, OriY := 0
    CoordMode("Mouse", "Screen")
    MouseGetPos(&OriX, &OriY)
    CoordMode("Mouse", "Client")
    SendInput("{Click 983 25}")
    CoordMode("Mouse", "Screen")
    MouseMove(OriX, OriY, 0)
    CoordMode("Mouse", "Client")
  } else {
    SendInput("{Escape}")
  }
}
; F9 : Take screenshot
$F9::
{
  if (WinActive("ahk_exe AndroidEmulatorEx.exe")) {
    OriX := 0, OriY := 0
    CoordMode("Mouse", "Screen")
    MouseGetPos(&OriX, &OriY)
    CoordMode("Mouse", "Client")
    SendInput("{Click 1095 25}")
    Sleep(10)
    SendInput("{Click 20 120}")
    CoordMode("Mouse", "Screen")
    MouseMove(OriX, OriY, 0)
    CoordMode("Mouse", "Client")
  } else {
    SendInput("{F9}")
  }
}
; ---------------------------------------------------------------------------
; Variable
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; Tray Icon & Menu (+functions)
; ---------------------------------------------------------------------------
A_IconTip := "ONE GameLoop Helper"
MenuTray := A_TrayMenu
MenuTray.Delete()
;@Ahk2Exe-IgnoreBegin
MenuTray.Add("Rel&oad`tL", (*) => Reload())
MenuTray.Add()
;@Ahk2Exe-IgnoreEnd
MenuTray.Add("E&xit Program`tX", (*) => ExitApp())
MenuTray.Default := "E&xit Program`tX"
; Dark Context Menu
SetMenuAttr()
; ---------------------------------------------------------------------------
; Function
; ---------------------------------------------------------------------------

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
