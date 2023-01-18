/*
MChangul : Automatic IME mode changer
*/

#SingleInstance, Force
#NoEnv
#InstallKeybdHook
SendMode Input

if(MCCheck() = 0) {
  TrayTip,Minecraft is not running!,You need to run Minecraft to use this script!,2,48
  Sleep 2000
  HideTT()
}
Hotkey, Enter, On
isOn := true

Enter::ENT()

ENT() {
  WinGet,wTitle,ProcessName,A
  ; MsgBox,%wTitle%
  if (wTitle == "javaw.exe") {
    ck := IMECHECK("A")
    if (ck = 0) { ; 0 is English mode
      Send,{Enter}
    }
    if (ck <> 0){
      Send,{vk15sc138}
      Send,{Enter}
    }
  }
  else Send,{Enter}
}
MCCheck() {
  Process,Exist,"javaw.exe"
  Return ErrorLevel
}
HideTT() {
  TrayTip
  if SubStr(A_OSVersion,1,3) = "10." {
    Menu Tray, NoIcon
    Sleep 10
    Menu Tray, Icon
  }
}
IMECHECK(WinTitle) {
  WinGet,hWnd,ID,%WinTitle%
  Return Send_ImeControl(ImmGetDefaultIMEWnd(hWnd),0x005,"")
}
Send_ImeControl(DefaultIMEWnd, wParam, lParam) {
    DetectSave := A_DetectHiddenWindows       
    DetectHiddenWindows,ON                          

     SendMessage 0x283, wParam,lParam,,ahk_id %DefaultIMEWnd%
    if (DetectSave <> A_DetectHiddenWindows)
        DetectHiddenWindows,%DetectSave%
    return ErrorLevel
}
ImmGetDefaultIMEWnd(hWnd) {
    return DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hWnd, Uint)
}
