/************************************************************************
 * @description Sigil Transmute Shortcut for Granblue Fantasy: Relink
 * @author TetraTheta
 * @date 2024/05/11
 * @version 1.0.0
 ***********************************************************************/
#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook(True, True)
InstallMouseHook(True, True)
DetectHiddenWindows(True)
SetControlDelay(-1)

target_title := "Granblue Fantasy: Relink"
target_exe := "granblue_fantasy_relink.exe"

#HotIf WinExist(target_title)
$Numpad0::Transmute()
#HotIf

FindWindow(title, exe) {
  try {
    local thwnd := WinGetID("ahk_class " . title . " ahk_exe " . exe)
    return True
  } catch TargetError {
    return False
  }
}
Transmute() {
  global target_title, target_exe
  if (FindWindow(target_title, target_exe)) {
    Press("LButton")
    Press("LButton")
    Press("Down")
    Press("LButton")
    Press("LButton")
    Sleep(1400)
    Press("LButton")
    SoundPlay("*16")
  } else {
    SoundPlay("*16")
  }
}
Press(key) {
  SendEvent("{" . key . " Down}")
  Sleep(20)
  SendEvent("{" . key . " Up}")
  Sleep(100)
}
