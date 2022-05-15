#NoEnv
#SingleInstance Force
#InstallMouseHook
SendMode Input
SetWorkingDir %A_ScriptDir%
DetectHiddenWindows On
#Include ..\Library\INI.ahk

;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright 2022. TetraTheta. All rights reserved.
;@Ahk2Exe-SetProductName MCAutoClicker
;@Ahk2Exe-SetDescription Auto clicker for Minecraft
;@Ahk2Exe-SetFileVersion 1.0.0.0
;@Ahk2Exe-SetLanguage 0x0412

;@Ahk2Exe-SetMainIcon MCAutoClicker.ico ; Default Icon
;@Ahk2Exe-AddResource MCAutoClicker_Gray.ico, 160 ; Suspend Icon - Gray
;;@Ahk2Exe-AddResource MCAutoClicker_Red.ico, 207 ; Pause Icon - Red
Menu, Tray, NoStandard
;@Ahk2Exe-IgnoreBegin
Menu, Tray, Icon, MCAutoClicker.ico
;@Ahk2Exe-IgnoreEnd
Menu, Tray, Tip, MCAutoClicker
Menu, Tray, Add, Hotkey Information`t&I, ShowInformation
Menu, Tray, Add ; Separator
If (!A_IsCompiled)
{
	Menu, Submenu, Add, Edit Script`t&E, EditScript
}
Menu, Submenu, Add, Reload Script`t&R, ReloadScript
Menu, Submenu, Add ; Separator
Menu, Submenu, Add, Suspend Script`t&S, SuspendScript
Menu, Tray, Add, Advanced Menu`t&A, :Submenu
Menu, Tray, Add ; Separator
Menu, Tray, Add, Exit Script`t&X, ExitScript
Menu, Tray, Default, Hotkey Information`t&I

beep := IniGet("General", "Beep", 0)
click_interval := IniGet("Minecraft", "Click Interval", 1000)
game_title := IniGet("Minecraft", "Window Title", "Minecraft")
toggle_keep_click = 0
toggle_repeat_click = 0

#If WinExist(game_title)
F10::GoSub, RepeatClickToggle
XButton1::GoSub, KeepClickToggle
F11::GoSub, KeepClickToggle
#If

EditScript:
	Edit
Return

ExitScript:
	ExitApp
Return

KeepClickToggle:
	If (toggle_keep_click := !toggle_keep_click)
	{
		MouseClick, Left,,,,,D
		SetTimer, KeepClick, 100
	}
	Else
	{
		MouseClick, Left,,,,,U
		SetTimer, KeepClick, Off
	}
Return

KeepClick:
	WinGetTitle, current_window_title, A
	If (GetKeyState("LButton") And !GetKeyState("LButton","P") And (current_window_title != game_title))
	{
		toggle_keep_click := !toggle_keep_click
		MouseClick, Left,,,,,U
	}
Return

ReloadScript:
	Reload
Return

RepeatClickToggle:
	If (toggle_repeat_click := !toggle_repeat_click)
	{
		ControlGet, MHWND, Hwnd,,, %game_title%
		SetTimer, RepeatClick, %click_interval%
		GoSub, RepeatClick
	}
	Else
	{
		SetTimer, RepeatClick, Off
	}
Return

RepeatClick:
	SetControlDelay -1
	ControlClick,, ahk_id %MHWND%,,,,NA
	If (beep = 1)
	{
		SoundBeep, 1500
	}
Return

ShowInformation:
	ListHotkeys
Return

SuspendScript:
	Suspend, Toggle
	If (A_IsSuspended) {
		Menu, Submenu, Rename, Suspend Script`t&S, Resume Script`t&S
		;@Ahk2Exe-IgnoreBegin
		Menu, Tray, Icon, MCAutoClicker_Gray.ico,,1
		;@Ahk2Exe-IgnoreEnd
		/*@Ahk2Exe-Keep
		Menu, Tray, Icon, %A_ScriptName%, -160, 1
		*/
	}
	Else
	{
		Menu, Submenu, Rename, Resume Script`t&S, Suspend Script`t&S
		;@Ahk2Exe-IgnoreBegin
		Menu, Tray, Icon, MCAutoClicker.ico,,1
		;@Ahk2Exe-IgnoreEnd
		/*@Ahk2Exe-Keep
		Menu, Tray, Icon, %A_ScriptName%, -159, 1
		*/
	}
Return
