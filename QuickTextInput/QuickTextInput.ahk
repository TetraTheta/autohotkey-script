#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%
#Include ..\Library\INI.ahk

; Information about executable
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright 2022. TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription Type predefined text quickly with hotkey
;@Ahk2Exe-SetFileVersion 1.0.0.0
;@Ahk2Exe-SetLanguage 0x0412
;@Ahk2Exe-SetProductName Quick Text Input

;@Ahk2Exe-SetMainIcon QuickTextInput.ico ; Default Icon
;@Ahk2Exe-AddResource QuickTextInput_Gray.ico, 160 ; Suspend Icon
;;@Ahk2Exe-AddResource QuickTextInput_Red.ico, 207 ; Pause Icon
Menu, Tray, NoStandard
;@Ahk2Exe-IgnoreBegin
Menu, Tray, Icon, QuickTextInput.ico
;@Ahk2Exe-IgnoreEnd
Menu, Tray, Tip, Quick Text Input
Menu, Tray, Add, Hotkey List`t&H, ShowInformation
Menu, Tray, Add, Open Memo File`t&O, OpenTitleFile
Menu, Tray, Add ; Separator
If (!A_IsCompiled)
{
	Menu, Submenu, Add, Edit Script`t&E, EditScript
}
Menu, Submenu, Add, Reload Script`t&R, ReloadScript
Menu, Submenu, Add ; Separator
Menu, Submenu, Add, List Variables`t&V, ListVariables
Menu, Submenu, Add, Suspend Script`t&S, SuspendScript
Menu, Tray, Add, Advanced Menu`t&A, :Submenu
Menu, Tray, Add ; Separator
Menu, Tray, Add, Exit Script`t&X, ExitScript
Menu, Tray, Default, Hotkey List`t&H

; Read INI file for settings
EDITOR := IniGet("Setting", "Editor", "notepad.exe")
TITLE := IniGet("Setting", "Memo File", "")

varCD := IniGet("Text List", "Ctrl + NumpadDot", "") ; Ctrl + NumpadDot
varC0 := IniGet("Text List", "Ctrl + Numpad0", "") ; Ctrl + Numpad0
varC1 := IniGet("Text List", "Ctrl + Numpad1", "") ; Ctrl + Numpad1
varC2 := IniGet("Text List", "Ctrl + Numpad2", "") ; Ctrl + Numpad2
varC3 := IniGet("Text List", "Ctrl + Numpad3", "") ; Ctrl + Numpad3
varC4 := IniGet("Text List", "Ctrl + Numpad4", "") ; Ctrl + Numpad4
varC5 := IniGet("Text List", "Ctrl + Numpad5", "") ; Ctrl + Numpad5
varC6 := IniGet("Text List", "Ctrl + Numpad6", "") ; Ctrl + Numpad6
varC7 := IniGet("Text List", "Ctrl + Numpad7", "") ; Ctrl + Numpad7
varC8 := IniGet("Text List", "Ctrl + Numpad8", "") ; Ctrl + Numpad8
varC9 := IniGet("Text List", "Ctrl + Numpad9", "") ; Ctrl + Numpad9
;varCAD := IniGet("Text List", "Ctrl + Alt + NumpadDot", "")
;Ctrl + Alt + NumpadDot ; Disabled - Will act as Ctrl + Alt + Del
varCA0 := IniGet("Text List", "Ctrl + Alt + Numpad0", "") ; Ctrl + Alt + Numpad0
varCA1 := IniGet("Text List", "Ctrl + Alt + Numpad1", "") ; Ctrl + Alt + Numpad1
varCA2 := IniGet("Text List", "Ctrl + Alt + Numpad2", "") ; Ctrl + Alt + Numpad2
varCA3 := IniGet("Text List", "Ctrl + Alt + Numpad3", "") ; Ctrl + Alt + Numpad3
varCA4 := IniGet("Text List", "Ctrl + Alt + Numpad4", "") ; Ctrl + Alt + Numpad4
varCA5 := IniGet("Text List", "Ctrl + Alt + Numpad5", "") ; Ctrl + Alt + Numpad5
varCA6 := IniGet("Text List", "Ctrl + Alt + Numpad6", "") ; Ctrl + Alt + Numpad6
varCA7 := IniGet("Text List", "Ctrl + Alt + Numpad7", "") ; Ctrl + Alt + Numpad7
varCA8 := IniGet("Text List", "Ctrl + Alt + Numpad8", "") ; Ctrl + Alt + Numpad8
varCA9 := IniGet("Text List", "Ctrl + Alt + Numpad9", "") ; Ctrl + Alt + Numpad9

; Hotkey
^NumpadDot::  Send, {Text}%varCD% ; Ctrl + NumpadDot
^Numpad0::    Send, {Text}%varC0% ; Ctrl + Numpad0
^Numpad1::    Send, {Text}%varC1% ; Ctrl + Numpad1
^Numpad2::    Send, {Text}%varC2% ; Ctrl + Numpad2
^Numpad3::    Send, {Text}%varC3% ; Ctrl + Numpad3
^Numpad4::    Send, {Text}%varC4% ; Ctrl + Numpad4
^Numpad5::    Send, {Text}%varC5% ; Ctrl + Numpad5
^Numpad6::    Send, {Text}%varC6% ; Ctrl + Numpad6
^Numpad7::    Send, {Text}%varC7% ; Ctrl + Numpad7
^Numpad8::    Send, {Text}%varC8% ; Ctrl + Numpad8
^Numpad9::    Send, {Text}%varC9% ; Ctrl + Numpad9
;^!NumpadDot:: Send, {Text}%varCAD%
; Ctrl + Alt + NumpadDot ; Disabled - Will act as Ctrl + Alt + Del
^!Numpad0::   Send, {Text}%varCA0% ; Ctrl + Alt + Numpad0
^!Numpad1::   Send, {Text}%varCA1% ; Ctrl + Alt + Numpad1
^!Numpad2::   Send, {Text}%varCA2% ; Ctrl + Alt + Numpad2
^!Numpad3::   Send, {Text}%varCA3% ; Ctrl + Alt + Numpad3
^!Numpad4::   Send, {Text}%varCA4% ; Ctrl + Alt + Numpad4
^!Numpad5::   Send, {Text}%varCA5% ; Ctrl + Alt + Numpad5
^!Numpad6::   Send, {Text}%varCA6% ; Ctrl + Alt + Numpad6
^!Numpad7::   Send, {Text}%varCA7% ; Ctrl + Alt + Numpad7
^!Numpad8::   Send, {Text}%varCA8% ; Ctrl + Alt + Numpad8
^!Numpad9::   Send, {Text}%varCA9% ; Ctrl + Alt + Numpad9

^Insert::     Gosub, ReplaceNBSP
^Del::        Gosub, AppendRuby

; Labels & Functions
AppendRuby:
	SendEvent, ^x
	ClipWait
	clipboard := "<ruby>" . clipboard . "<rt></rt></ruby>"
	Sleep, 100
	SendEvent, ^v
	Sleep, 100
	clipboard := ""
Return

EditScript:
	Edit
Return

ExitScript:
	ExitApp
Return

GenerateInformation()
{
	Global info1, info2, info3
	Global varCD, varC0, varC1, varC2, varC3, varC4, varC5, varC6, varC7, varC8, varC9
	Global varCAD, varCA0, varCA1, varCA2, varCA3, varCA4, varCA5, varCA6, varCA7, varCA8, varCA9
	
	info1 := ""
	info1 := info1 . "Ctrl + NumpadDot = " . varCD . "`n"
	info1 := info1 . "Ctrl + Numpad0 = " . varC0 . "`n"
	info1 := info1 . "Ctrl + Numpad1 = " . varC1 . "`n"
	info1 := info1 . "Ctrl + Numpad2 = " . varC2 . "`n"
	info1 := info1 . "Ctrl + Numpad3 = " . varC3 . "`n"
	info1 := info1 . "Ctrl + Numpad4 = " . varC4 . "`n"
	info1 := info1 . "Ctrl + Numpad5 = " . varC5 . "`n"
	info1 := info1 . "Ctrl + Numpad6 = " . varC6 . "`n"
	info1 := info1 . "Ctrl + Numpad7 = " . varC7 . "`n"
	info1 := info1 . "Ctrl + Numpad8 = " . varC8 . "`n"
	info1 := info1 . "Ctrl + Numpad9 = " . varC9 . "`n"
	
	info2 := ""
	info2 := info2 . "Ctrl + Alt + NumpadDot = " . "[DISABLED]" . "`n"
	info2 := info2 . "Ctrl + Alt + Numpad0 = " . varCA0 . "`n"
	info2 := info2 . "Ctrl + Alt + Numpad1 = " . varCA1 . "`n"
	info2 := info2 . "Ctrl + Alt + Numpad2 = " . varCA2 . "`n"
	info2 := info2 . "Ctrl + Alt + Numpad3 = " . varCA3 . "`n"
	info2 := info2 . "Ctrl + Alt + Numpad4 = " . varCA4 . "`n"
	info2 := info2 . "Ctrl + Alt + Numpad5 = " . varCA5 . "`n"
	info2 := info2 . "Ctrl + Alt + Numpad6 = " . varCA6 . "`n"
	info2 := info2 . "Ctrl + Alt + Numpad7 = " . varCA7 . "`n"
	info2 := info2 . "Ctrl + Alt + Numpad8 = " . varCA8 . "`n"
	info2 := info2 . "Ctrl + Alt + Numpad9 = " . varCA9 . "`n"
	
	info3 := ""
	info3 := info3 . "Ctrl + Insert = Replace NBSP to Space`n"
	info3 := info3 . "Ctrl + Del = Append Ruby Tag to Selection`n"
	
	Return
}

InformationEscape:
	Gui, Destroy
Return

InformationClose:
	Gui, Destroy
Return

ListVariables:
	ListVars
Return

OpenTitleFile:
	Run, %EDITOR% %TITLE%
Return

ReloadScript:
	Reload
Return

ReplaceNBSP:
	SendEvent, ^x
	ClipWait
	clipboard := StrReplace(clipboard, "&nbsp;", " ")
	Sleep, 100
	SendEvent, ^v
	Sleep, 100
	clipboard := ""
Return

ShowInformation:
	GenerateInformation()
	Gui, New, +LabelInformation -Resize -MinimizeBox -MaximizeBox +AlwaysOnTop
	Gui, Font, s12, Tahoma
	Gui, Add, Text, x9 y9 w450 h275, %info1%
	Gui, Add, Text, x468 y9 w450 h275, %info2%
	Gui, Add, Text, x9 y293 w909 h100, %info3%
	Gui, Show, w927 h402, Hotkey List
Return

SuspendScript:
	Suspend, Toggle
	If (A_IsSuspended) {
		Menu, Submenu, Rename, Suspend Script`t&S, Resume Script`t&S
		;@Ahk2Exe-IgnoreBegin
		Menu, Tray, Icon, QuickTextInput_Gray.ico,,1
		;@Ahk2Exe-IgnoreEnd
		/*@Ahk2Exe-Keep
		Menu, Tray, Icon, %A_ScriptName%, -160, 1
		*/
	}
	Else
	{
		Menu, Submenu, Rename, Resume Script`t&S, Suspend Script`t&S
		;@Ahk2Exe-IgnoreBegin
		Menu, Tray, Icon, QuickTextInput.ico,,1
		;@Ahk2Exe-IgnoreEnd
		/*@Ahk2Exe-Keep
		Menu, Tray, Icon, %A_ScriptName%, -159, 1
		*/
	}
Return
