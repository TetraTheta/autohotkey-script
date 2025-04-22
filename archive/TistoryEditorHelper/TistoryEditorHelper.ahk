/**
 * TistoryEditorHelper v2.0.0 : Type predefined text quickly with hotstring
 */
#Requires AutoHotkey v2
#Include "..\..\Lib\ini.ahk"
#SingleInstance Force

; Information about executable
;@Ahk2Exe-AddResource icon_grey.ico, 206 ; Suspend icon
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright 2023. TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription Type predefined text quickly with hotstring
;@Ahk2Exe-SetFileVersion 2.0.0.0
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
  MenuTraySub.Add("Edit Script`tE", ScriptEdit)
}
MenuTraySub.Add("Reload Script`tR", (*) => Reload())
MenuTraySub.Add() ; Create separator
MenuTraySub.Add("List Variables`tV", ListVariables)
MenuTraySub.Add("Suspend Script`tS", ScriptSuspend)
; Menu
MenuTray.Add("&Hotstring List`tH", ShowHotstrings)
MenuTray.Default := "&Hotstring List`tH"
MenuTray.Add("Edit Hotstring List`tK", EditHotstrings)
MenuTray.Add() ; Create separator
MenuTray.Add("Advanced Menu`tA", MenuTraySub)
MenuTray.Add() ; Create separator
MenuTray.Add("Exit Script`tX", (*) => ExitApp())

; Read INI file for settings
EDITOR := IniGet("Setting", "Editor", "notepad.exe")
LIMIT := IniGet("Setting", "Hotstring Limit", 30)
; Reset LIMIT if exceeds 260
if (LIMIT > 260) {
  IniWrite(260, GetIniPath(), "Setting", "Hotstring Limit")
  LIMIT := 260
}

hotstrings := Map()

RegisterHotstrings(LIMIT)

; Functions
RegisterHotstrings(LIMIT) {
  loop Integer(LIMIT) {
    ; Hard limit of loop is 260.
    if A_Index > 260
      break
    identifier := Format("{:04}", A_Index)
    hkey := GetAlphaNumber(A_Index)
    key := IniGet("Hotstring List", identifier "-key", ";" hkey)
    value := IniGet("Hotstring List", identifier "-value", " {left}")
    hotstrings[key] := value
  }
  for key, value in hotstrings {
    ; Hotstrings will be immediately replaced
    Hotstring(":*:" . key, value, True)
  }
}
GetAlphaNumber(num) {
  if (num >= 1 && num <= 260) {
    ab := "abcdefghijklmnopqrstuvwxyz"
    aIndex := Ceil(num / 10)
    nIndex := Mod(num - 1, 10)
    if (aIndex <= 26) {
      a := SubStr(ab, aIndex, 1)
      return a . nIndex
    }
  }
  ; Another failsafe
  return ""
}
ListVariables(ItemName, ItemPos, TheMenu) {
  ListVars()
}
ScriptEdit(ItemName, ItemPos, TheMenu) {
  ; Double check because A_ScriptFullPath will return EXE file if run at compiled script
  if (!A_IsCompiled) {
    ;@Ahk2Exe-IgnoreBegin
    RunWait("`"" . EDITOR . "`" `"" . A_ScriptFullPath . "`"")
    Reload()
    ;@Ahk2Exe-IgnoreEnd
  }
}
ScriptSuspend(ItemName, ItemPos, TheMenu) {
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
  global hotstrings
  ; Create GUI
  HotstringsGUI := Gui("+AlwaysOnTop -Resize -MinimizeBox -MaximizeBox", "Hotstring List")
  HotstringsGUI.SetFont("s12", "Malgun Gothic")
  LV := HotstringsGUI.AddListView("R11 +Report -Multi +LV0x1 -LV0x10", ["Trigger", "Replacement"])
  LV.Opt("-Redraw")
  for key, value in hotstrings {
    LV.Add(, key, value)
  }
  LV.ModifyCol(1, "AutoHdr")
  LV.ModifyCol(2, "AutoHdr")
  LV.Opt("+Redraw")
  HotstringsGUI.Show("w927 h402 AutoSize Restore")
}
EditHotStrings(ItemName, ItemPos, TheMenu) {
  RunWait("`"" . EDITOR . "`" `"" . GetIniPath() . "`"")
  Reload()
}
