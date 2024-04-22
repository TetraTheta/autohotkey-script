/**
 * QuickTextInput v2.0.0 : Type predefined text quickly with hotkey
 */
#Requires AutoHotkey v2
#Include "..\..\Lib\ini.ahk"
#SingleInstance Force

; Information about executable
;@Ahk2Exe-AddResource icon_grey.ico, 206 ; Suspend icon
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright 2023. TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription Type predefined text quickly with hotkey
;@Ahk2Exe-SetFileVersion 2.0.0.0
;@Ahk2Exe-SetLanguage 0x0412
;@Ahk2Exe-SetMainIcon icon_normal.ico ; Default icon
;@Ahk2Exe-SetProductName QuickTextInput

; Set tray icon stuff
A_IconTip := "QuickTextInput" ; Tray icon tip
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
MenuTray.Add("&Hotkey List`tH", ShowQuickText)
MenuTray.Default := "&Hotkey List`tH"
MenuTray.Add("Edit Hotkey List`tK", EditQuickText)
MenuTray.Add("Open Memo File`tO", OpenMemoFile)
MenuTray.Add() ; Create separator
MenuTray.Add("Advanced Menu`tA", MenuTraySub)
MenuTray.Add() ; Create separator
MenuTray.Add("Exit Script`tX", ExitScript)

; Read INI file for settings
EDITOR := IniGet("Setting", "Editor", "notepad.exe")
MEMO := IniGet("Setting", "Memo File", "")

varCD := IniGet("Text List", "Ctrl + NumpadDot", "") ; Ctrl + NumpadDot
varC0 := IniGet("Text List", "Ctrl + Numpad0", "")   ; Ctrl + Numpad0
varC1 := IniGet("Text List", "Ctrl + Numpad1", "")   ; Ctrl + Numpad1
varC2 := IniGet("Text List", "Ctrl + Numpad2", "")   ; Ctrl + Numpad2
varC3 := IniGet("Text List", "Ctrl + Numpad3", "")   ; Ctrl + Numpad3
varC4 := IniGet("Text List", "Ctrl + Numpad4", "")   ; Ctrl + Numpad4
varC5 := IniGet("Text List", "Ctrl + Numpad5", "")   ; Ctrl + Numpad5
varC6 := IniGet("Text List", "Ctrl + Numpad6", "")   ; Ctrl + Numpad6
varC7 := IniGet("Text List", "Ctrl + Numpad7", "")   ; Ctrl + Numpad7
varC8 := IniGet("Text List", "Ctrl + Numpad8", "")   ; Ctrl + Numpad8
varC9 := IniGet("Text List", "Ctrl + Numpad9", "")   ; Ctrl + Numpad9
varAD := IniGet("Text List", "Alt + NumpadDot", "")  ; Alt + NumpadDot
varA0 := IniGet("Text List", "Alt + Numpad0", "")    ; Alt + Numpad0
varA1 := IniGet("Text List", "Alt + Numpad1", "")    ; Alt + Numpad1
varA2 := IniGet("Text List", "Alt + Numpad2", "")    ; Alt + Numpad2
varA3 := IniGet("Text List", "Alt + Numpad3", "")    ; Alt + Numpad3
varA4 := IniGet("Text List", "Alt + Numpad4", "")    ; Alt + Numpad4
varA5 := IniGet("Text List", "Alt + Numpad5", "")    ; Alt + Numpad5
varA6 := IniGet("Text List", "Alt + Numpad6", "")    ; Alt + Numpad6
varA7 := IniGet("Text List", "Alt + Numpad7", "")    ; Alt + Numpad7
varA8 := IniGet("Text List", "Alt + Numpad8", "")    ; Alt + Numpad8
varA9 := IniGet("Text List", "Alt + Numpad9", "")    ; Alt + Numpad9

; Hotkey
^NumpadDot:: SendText(varCD) ; Ctrl + NumpadDot
^Numpad0:: Send(varC0)       ; Ctrl + Numpad0
^Numpad1:: Send(varC1)       ; Ctrl + Numpad1
^Numpad2:: Send(varC2)       ; Ctrl + Numpad2
^Numpad3:: Send(varC3)       ; Ctrl + Numpad3
^Numpad4:: Send(varC4)       ; Ctrl + Numpad4
^Numpad5:: Send(varC5)       ; Ctrl + Numpad5
^Numpad6:: Send(varC6)       ; Ctrl + Numpad6
^Numpad7:: Send(varC7)       ; Ctrl + Numpad7
^Numpad8:: Send(varC8)       ; Ctrl + Numpad8
^Numpad9:: Send(varC9)       ; Ctrl + Numpad9
!NumpadDot:: Send(varAD)     ; Alt + NumpadDot
!Numpad0:: Send(varA0)       ; Alt + Numpad0
!Numpad1:: Send(varA1)       ; Alt + Numpad1
!Numpad2:: Send(varA2)       ; Alt + Numpad2
!Numpad3:: Send(varA3)       ; Alt + Numpad3
!Numpad4:: Send(varA4)       ; Alt + Numpad4
!Numpad5:: Send(varA5)       ; Alt + Numpad5
!Numpad6:: Send(varA6)       ; Alt + Numpad6
!Numpad7:: Send(varA7)       ; Alt + Numpad7
!Numpad8:: Send(varA8)       ; Alt + Numpad8
!Numpad9:: Send(varA9)       ; Alt + Numpad9

; Functions
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
ShowQuickText(ItemName, ItemPos, TheMenu) {
  ; Ctrl lines
  infoCtrl := ""
  infoCtrl := infoCtrl . "Ctrl + NumpadDot = " . varCD . "`n"
  infoCtrl := infoCtrl . "Ctrl + Numpad0   = " . varC0 . "`n"
  infoCtrl := infoCtrl . "Ctrl + Numpad1   = " . varC1 . "`n"
  infoCtrl := infoCtrl . "Ctrl + Numpad2   = " . varC2 . "`n"
  infoCtrl := infoCtrl . "Ctrl + Numpad3   = " . varC3 . "`n"
  infoCtrl := infoCtrl . "Ctrl + Numpad4   = " . varC4 . "`n"
  infoCtrl := infoCtrl . "Ctrl + Numpad5   = " . varC5 . "`n"
  infoCtrl := infoCtrl . "Ctrl + Numpad6   = " . varC6 . "`n"
  infoCtrl := infoCtrl . "Ctrl + Numpad7   = " . varC7 . "`n"
  infoCtrl := infoCtrl . "Ctrl + Numpad8   = " . varC8 . "`n"
  infoCtrl := infoCtrl . "Ctrl + Numpad9   = " . varC9 . "`n"
  ; Alt lines
  infoAlt := ""
  infoAlt := infoAlt . "Alt + NumpadDot = " . varAD . "`n"
  infoAlt := infoAlt . "Alt + Numpad0   = " . varA0 . "`n"
  infoAlt := infoAlt . "Alt + Numpad1   = " . varA1 . "`n"
  infoAlt := infoAlt . "Alt + Numpad2   = " . varA2 . "`n"
  infoAlt := infoAlt . "Alt + Numpad3   = " . varA3 . "`n"
  infoAlt := infoAlt . "Alt + Numpad4   = " . varA4 . "`n"
  infoAlt := infoAlt . "Alt + Numpad5   = " . varA5 . "`n"
  infoAlt := infoAlt . "Alt + Numpad6   = " . varA6 . "`n"
  infoAlt := infoAlt . "Alt + Numpad7   = " . varA7 . "`n"
  infoAlt := infoAlt . "Alt + Numpad8   = " . varA8 . "`n"
  infoAlt := infoAlt . "Alt + Numpad9   = " . varA9 . "`n"

  ; Create GUI
  QuickTextGUI := Gui("+AlwaysOnTop -Resize -MinimizeBox -MaximizeBox", "QuickText List")
  QuickTextGUI.SetFont("s12", "D2Coding")
  QuickTextGUI.Add("Text", "x9 y9 w450 h275", infoCtrl)
  QuickTextGUI.Add("Text", "x468 y9 w450 h275", infoAlt)
  QuickTextGUI.Show("w927 h402 AutoSize Restore")
}
EditQuickText(ItemName, ItemPos, TheMenu) {
  RunWait("`"" . EDITOR . "`" `"" . GetIniPath() . "`"")
  Reload()
}
OpenMemoFile(ItemName, ItemPos, TheMenu) {
  Run("`"" . EDITOR . "`" `"" . A_ScriptDir . "\" . MEMO . "`"")
}
ExitScript(ItemName, ItemPos, TheMenu) {
  ExitApp()
}
