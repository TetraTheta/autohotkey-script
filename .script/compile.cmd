@echo off
title AutoHotkey batch compile
set "c=C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
REM BlueStacksMultiClick
"%c%" /in ..\BlueStacksMultiClick\BlueStacksMultiClick.ahk /cp 65001 /compress 0 /silent verbose
move /Y ..\BlueStacksMultiClick\BlueStacksMultiClick.exe .
REM MarkdownHelper
"%c%" /in ..\MarkdownHelper\MarkdownHelper.ahk /cp 65001 /compress 0 /silent verbose
move /Y ..\MarkdownHelper\MarkdownHelper.exe .
REM MCAutoClicker
"%c%" /in ..\MCAutoClicker\MCAutoClicker.ahk /cp 65001 /compress 0 /silent verbose
move /Y ..\MCAutoClicker\MCAutoClicker.exe .
REM QuickTextInput
"%c%" /in ..\QuickTextInput\QuickTextInput.ahk /cp 65001 /compress 0 /silent verbose
move /Y ..\QuickTextInput\QuickTextInput.exe .
REM TistoryEditorHelper
"%c%" /in ..\TistoryEditorHelper\TistoryEditorHelper.ahk /cp 65001 /compress 0 /silent verbose
move /Y ..\TistoryEditorHelper\TistoryEditorHelper.exe .
REM TOFUtility
"%c%" /in ..\TOFUtility\TOFUtility.ahk /cp 65001 /compress 0 /silent verbose
move /Y ..\TOFUtility\TOFUtility.exe .
pause
