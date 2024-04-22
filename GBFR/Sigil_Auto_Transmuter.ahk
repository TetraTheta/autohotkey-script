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

target_hwnd := 0
target_title := "Granblue Fantasy: Relink"

#HotIf WinExist(target_title)
$F2::RepeatKey()
$F3::StopKey()
#HotIf

FindWindow() {
  global target_title, target_hwnd
  try {
    local thwnd := WinGetID(target_title)
    target_hwnd := thwnd
    return True
  } catch TargetError {
    target_hwnd := 0
    return False
  }
}
RepeatKey() {
  global target_title, target_hwnd
  if (FindWindow()) {
    Loop 600 {
      PressKey()
      Sleep(200)
    }
  } else {
    SoundPlay("*16")
  }
}
PressKey() {
  ;global target_hwnd
  SendEvent("{LButton Down}")
  Sleep(20)
  SendEvent("{LButton Up}")
  /*
  try {
    ControlClick(target_hwnd,,,,, "D")
    Sleep(20)
    ControlClick(target_hwnd,,,,, "U")
  } catch Error as err {
    MsgBox(err)
  }
  */
}
StopKey() {
  SendEvent("{LButton Up}")
  Sleep(5)
  SoundPlay("*16")
  Reload()
}
