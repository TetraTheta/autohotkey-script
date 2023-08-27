/**
 * TistoryEditorHelper v1.0.0 : Type predefined text quickly with hotkey
 */
#Requires AutoHotkey v2
#Include "..\Lib\ini.ahk"
#SingleInstance Force

; Information about executable
;@Ahk2Exe-AddResource icon_grey.ico, 206 ; Suspend icon
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright 2023. TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription Type predefined text quickly with hotkey
;@Ahk2Exe-SetFileVersion 1.0.0.0
;@Ahk2Exe-SetLanguage 0x0412
;@Ahk2Exe-SetMainIcon icon_normal.ico ; Default icon
;@Ahk2Exe-SetProductName TistoryEditorHelper

; Set tray icon stuff
A_IconTip := "TistoryEditorHelper" ; Tray icon tip
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
MenuTraySub.Add("List Variables`tV", ListVariables)
MenuTraySub.Add("Suspend Script`tS", SuspendScript)
; Menu
MenuTray.Add("&Hotstring List`tH", ShowHotstrings)
MenuTray.Default := "&Hotstring List`tH"
MenuTray.Add("Edit Hotstring List`tK", EditHotstrings)
MenuTray.Add() ; Create separator
MenuTray.Add("Advanced Menu`tA", MenuTraySub)
MenuTray.Add() ; Create separator
MenuTray.Add("Exit Script`tX", ExitScript)

; Read INI file for settings
EDITOR := IniGet("Setting", "Editor", "notepad.exe")

varA1 := IniGet("Hotstring List", "A1", "")
varA2 := IniGet("Hotstring List", "A2", "")
varA3 := IniGet("Hotstring List", "A3", "")
varA4 := IniGet("Hotstring List", "A4", "")
varA5 := IniGet("Hotstring List", "A5", "")
varA6 := IniGet("Hotstring List", "A6", "")
varA7 := IniGet("Hotstring List", "A7", "")
varA8 := IniGet("Hotstring List", "A8", "")
varA9 := IniGet("Hotstring List", "A9", "")
varA0 := IniGet("Hotstring List", "A0", "")
varS1 := IniGet("Hotstring List", "S1", "")
varS2 := IniGet("Hotstring List", "S2", "")
varS3 := IniGet("Hotstring List", "S3", "")
varS4 := IniGet("Hotstring List", "S4", "")
varS5 := IniGet("Hotstring List", "S5", "")
varS6 := IniGet("Hotstring List", "S6", "")
varS7 := IniGet("Hotstring List", "S7", "")
varS8 := IniGet("Hotstring List", "S8", "")
varS9 := IniGet("Hotstring List", "S9", "")
varS0 := IniGet("Hotstring List", "S0", "")

; Hotstring
; A
:z*:;;a1::{
  Send(varA1)
}
:*:;;a2::{
  Send(varA2)
}
:*:;;a3::{
  Send(varA3)
}
:*:;;a4::{
  Send(varA4)
}
:*:;;a5::{
  Send(varA5)
}
:*:;;a6::{
  Send(varA6)
}
:*:;;a7::{
  Send(varA7)
}
:*:;;a8::{
  Send(varA8)
}
:*:;;a9::{
  Send(varA9)
}
:*:;;a0::{
  Send(varA0)
}
; S
:*:;;s1::{
  Send(varS1)
}
:*:;;s2::{
  Send(varS2)
}
:*:;;s3::{
  Send(varS3)
}
:*:;;s4::{
  Send(varS4)
}
:*:;;s5::{
  Send(varS5)
}
:*:;;s6::{
  Send(varS6)
}
:*:;;s7::{
  Send(varS7)
}
:*:;;s8::{
  Send(varS8)
}
:*:;;s9::{
  Send(varS9)
}
:*:;;s0::{
  Send(varS0)
}


; Functions
ImeCheck() {
  defaultIMEWnd := DllCall("imm32\ImmGetDefaultIMEWnd", "UInt", WinGetID("A"))
  detectSaved := DetectHiddenWindows(True)
  res := SendMessage(0x0283, 5, 0, , "ahk_id" defaultIMEWnd)
  DetectHiddenWindows(detectSaved)
  return res
}
EditScript(ItemName, ItemPos, TheMenu) {
  ; Double check because A_ScriptFullPath will return EXE file if run at compiled script
  if (!A_IsCompiled) {
    ;@Ahk2Exe-IgnoreBegin
    RunWait("`"" . EDITOR . "`" `"" . A_ScriptFullPath . "`"")
    Reload()
    ;@Ahk2Exe-IgnoreEnd
  }
}
ReloadScript(ItemName, ItemPos, TheMenu) {
  Reload()
}
ListVariables(ItemName, ItemPos, TheMenu) {
  ListVars()
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
ShowHotStrings(ItemName, ItemPos, TheMenu) {
  ; ㅁ lines
  infoA := ""
  infoA := infoA . ";;A1 = " . varA1 . "`n"
  infoA := infoA . ";;A2 = " . varA2 . "`n"
  infoA := infoA . ";;A3 = " . varA3 . "`n"
  infoA := infoA . ";;A4 = " . varA4 . "`n"
  infoA := infoA . ";;A5 = " . varA5 . "`n"
  infoA := infoA . ";;A6 = " . varA6 . "`n"
  infoA := infoA . ";;A7 = " . varA7 . "`n"
  infoA := infoA . ";;A8 = " . varA8 . "`n"
  infoA := infoA . ";;A9 = " . varA9 . "`n"
  infoA := infoA . ";;A0 = " . varA0 . "`n"
  ; ㄴ lines
  infoS := ""
  infoS := infoS . ";;S1 = " . varS1 . "`n"
  infoS := infoS . ";;S2 = " . varS2 . "`n"
  infoS := infoS . ";;S3 = " . varS3 . "`n"
  infoS := infoS . ";;S4 = " . varS4 . "`n"
  infoS := infoS . ";;S5 = " . varS5 . "`n"
  infoS := infoS . ";;S6 = " . varS6 . "`n"
  infoS := infoS . ";;S7 = " . varS7 . "`n"
  infoS := infoS . ";;S8 = " . varS8 . "`n"
  infoS := infoS . ";;S9 = " . varS9 . "`n"
  infoS := infoS . ";;S0 = " . varS0 . "`n"

  ; Create GUI
  HotstringsGUI := Gui("+AlwaysOnTop -Resize -MinimizeBox -MaximizeBox", "QuickText List")
  HotstringsGUI.SetFont("s12", "D2Coding")
  HotstringsGUI.Add("Text", "x9 y9 w450 h275", infoA)
  HotstringsGUI.Add("Text", "x468 y9 w450 h275", infoS)
  HotstringsGUI.Show("w927 h402 AutoSize Restore")
}
EditHotStrings(ItemName, ItemPos, TheMenu) {
  RunWait("`"" . EDITOR . "`" `"" . A_ScriptDir . "\" . SCRIPT . ".ini`"")
  Reload()
}
ExitScript(ItemName, ItemPos, TheMenu) {
  ExitApp()
}
