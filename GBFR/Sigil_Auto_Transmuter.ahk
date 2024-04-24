/************************************************************************
 * @description Automatically transmute sigils
 * @file Sigil_Auto_Transmuter.ahk
 * @author TetraTheta
 * @date 2024/04/22
 * @version 1.0.0
 ***********************************************************************/
/**
 * TODO:
 * * Find a way to use 'ControlClick' or 'ControlSend' (both hook doesn't work)
 * * Find a reliable way to specify repeat count (Loop XXX is dumb)
 */
#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook(True, True)
InstallMouseHook(True, True)
DetectHiddenWindows(True)
SetControlDelay(-1)

target_hwnd := 0
target_title := "Granblue Fantasy: Relink"
target_exe := "granblue_fantasy_relink.exe"

#HotIf WinExist(target_title)
$F2::RepeatKey()
$F3::StopKey()
#HotIf

FindWindow(title, exe) {
  global target_hwnd
  try {
    local thwnd := WinGetID("ahk_class " . title . " ahk_exe " . exe)
    target_hwnd := thwnd
    return True
  } catch TargetError {
    target_hwnd := 0
    return False
  }
}
RepeatKey() {
  global target_title, target_exe, target_hwnd
  if (FindWindow(target_title, target_exe)) {
    Loop 600 {
      if (!PressKey(target_hwnd)) {
        Sleep(200)
      } else {
        break
      }
    }
  } else {
    SoundPlay("*16")
  }
}
PressKey(hwnd) {
  SendEvent("{LButton Down}")
  Sleep(20)
  SendEvent("{LButton Up}")
  ; try {
    ; ControlClick(,"ahk_id " . hwnd,,,, "D")
    ; Sleep(20)
    ; ControlClick(,"ahk_id " . hwnd,,,, "U")
    ; return True
  ; } catch Error as err {
    ; SoundPlay("*16")
    ; MsgBox(Format("{1}: {2}.`n`nFile:`t{3}`nLine:`t{4}`nWhat:`t{5}`nStack:`n{6}", type(err), err.Message, err.File, err.Line, err.What, err.Stack))
    ; return False
  ; }
}
StopKey() {
  SendEvent("{LButton Up}")
  Sleep(5)
  SoundPlay("*16")
  Reload()
}
