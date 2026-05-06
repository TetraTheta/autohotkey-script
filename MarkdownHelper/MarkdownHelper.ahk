/************************************************************************
 * @description My Hugo Blog Markdown Helper
 * @author TetraTheta
 * @date 2023/10/22
 * @version 3.1.0
 ***********************************************************************/
; No need to worry about multiple '#Include' usage of same file, because AutoHotkey will include it only once.
#Requires AutoHotkey v2.0
#Include "..\Lib\darkMode.ahk"
#Include "..\Lib\extension.ahk"
#Include "..\Lib\ini.ahk"
#Include "..\Lib\orderedMap.ahk"
#Include "app_context.ahk"
#Include "gui.ahk"
#Include "helpers.ahk"
#Include "i18n.ahk"
#Include "locale.ahk"
#SingleInstance Force

; Information about executable
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright (c) 2023. TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription My Hugo Blog Markdown Helper
;@Ahk2Exe-SetFileVersion 3.1.0.0
;@Ahk2Exe-SetMainIcon icon\main.ico ; Default icon
;@Ahk2Exe-SetProductName MarkdownHelper

; Embed icons (index starts with 209)
;@Ahk2Exe-AddResource *14 icon\cmd.ico ;209
;@Ahk2Exe-AddResource *14 icon\document.ico ;210
;@Ahk2Exe-AddResource *14 icon\download.ico ;211
;@Ahk2Exe-AddResource *14 icon\exit.ico ;212
;@Ahk2Exe-AddResource *14 icon\explorer.ico ;213
;@Ahk2Exe-AddResource *14 icon\gallery.ico ;214
;@Ahk2Exe-AddResource *14 icon\image.ico ;215
;@Ahk2Exe-AddResource *14 icon\new.ico ;216
;@Ahk2Exe-AddResource *14 icon\reload.ico ;217
;@Ahk2Exe-AddResource *14 icon\web.ico ;218

ctx := BuildAppContext(A_Args)
SetupMenu(ctx)
SetMenuAttr()
RegisterHotkeys(ctx)

SetupMenu(ctx) {
  L := ctx.L
  C := ctx.C

  A_IconTip := "MarkdownHelper"
  ;@Ahk2Exe-IgnoreBegin
  TraySetIcon("icon\main.ico")
  ;@Ahk2Exe-IgnoreEnd

  RunScriptMenu := Menu()
  menuPMDependenciesUpdate := Format(L.MENU_PMDependenciesUpdate, C.DetectedPM)
  RunScriptMenu.Add(L.MENU_NewContent, (*) => CreateNewContent(ctx))
  RunScriptMenu.Add()
  RunScriptMenu.Add(L.MENU_HugoModuleUpdate, (*) => Run(BuildPowerShellRunArgs("$Host.UI.RawUI.WindowTitle='Updating Hugo Modules...';hugo mod get -u ./...;hugo mod tidy;Write-Host '==== DONE ====' -ForegroundColor Green;[void][System.Console]::ReadKey($false)", true), C.ProjectRootDir))
  RunScriptMenu.Add(menuPMDependenciesUpdate, (*) => RunPMDependenciesUpdate(ctx))
  RunScriptMenu.Add()
  RunScriptMenu.Add(L.MENU_HugoModuleTidy, (*) => Run(BuildPowerShellRunArgs("$Host.UI.RawUI.WindowTitle='Tidying Hugo Modules...';hugo mod tidy;Write-Host '==== DONE ====' -ForegroundColor Green;[void][System.Console]::ReadKey($false)", true), C.ProjectRootDir))
  /*@Ahk2Exe-Keep
  RunScriptMenu.SetIcon(L.MENU_NewContent, "HICON:" GetEmbeddedIcon(216, 16))
  RunScriptMenu.SetIcon(L.MENU_HugoModuleUpdate, "HICON:" GetEmbeddedIcon(211, 16))
  RunScriptMenu.SetIcon(menuPMDependenciesUpdate, "HICON:" GetEmbeddedIcon(211, 16))
  */
  ;@Ahk2Exe-IgnoreBegin
  RunScriptMenu.SetIcon(L.MENU_NewContent, "icon\new.ico")
  RunScriptMenu.SetIcon(L.MENU_HugoModuleUpdate, "icon\download.ico")
  RunScriptMenu.SetIcon(menuPMDependenciesUpdate, "icon\download.ico")
  ;@Ahk2Exe-IgnoreEnd

  MiscMenu := Menu()
  MiscMenu.Add(L.MENU_Reload, (*) => Reload())
  MiscMenu.Add(L.MENU_ListHotkeys, (*) => ListHotkeys())
  /*@Ahk2Exe-Keep
  MiscMenu.SetIcon(L.MENU_Reload, "HICON:" GetEmbeddedIcon(217, 16))
  MiscMenu.SetIcon(L.MENU_ListHotkeys, "HICON:" GetEmbeddedIcon(210, 16))
  */
  ;@Ahk2Exe-IgnoreBegin
  MiscMenu.SetIcon(L.MENU_Reload, "icon\reload.ico")
  MiscMenu.SetIcon(L.MENU_ListHotkeys, "icon\document.ico")
  ;@Ahk2Exe-IgnoreEnd

  MainMenu := A_TrayMenu
  MainMenu.Delete()
  MainMenu.Add(L.MENU_OpenExplorer, (*) => Run("`"" . C.ExplorerExec . "`" " . C.ExplorerArgs))
  MainMenu.Add(L.MENU_OpenTerminal, (*) => (
    termCmd := BuildTerminalLaunchCommand(ctx),
    Run(termCmd, C.ProjectRootDir)
  ))
  MainMenu.Add(L.MENU_OpenGitGUI, (*) => Run("`"" . C.GitGUIExec . "`" " . C.GitGUIArgs, C.ProjectRootDir))
  MainMenu.Add()
  MainMenu.Add(L.MENU_StartHugoDev, (*) => (
    devCmd := BuildPowerShellRunArgs(BuildPowerShellInvokeRaw(C.DevExec, C.DevArgs), C.KeepConsoleOpen),
    Run(devCmd, C.ProjectRootDir)
  ))
  MainMenu.Add(L.MENU_OpenTestPage, (*) => OpenTestPage(ctx))
  MainMenu.Add()
  MainMenu.Add(L.MENU_RunScript, RunScriptMenu)
  MainMenu.Add()
  MainMenu.Add(L.MENU_Misc, MiscMenu)
  MainMenu.Add()
  MainMenu.Add(L.MENU_Exit, (*) => ExitApp())
  MainMenu.SetIcon(L.MENU_OpenGitGUI, C.GitGUIExec, 0)
  /*@Ahk2Exe-Keep
  MainMenu.SetIcon(L.MENU_OpenExplorer, "HICON:" GetEmbeddedIcon(213, 16))
  MainMenu.SetIcon(L.MENU_OpenTerminal, "HICON:" GetEmbeddedIcon(209, 16))
  MainMenu.SetIcon(L.MENU_StartHugoDev, "HICON:" GetEmbeddedIcon(209, 16))
  MainMenu.SetIcon(L.MENU_OpenTestPage, "HICON:" GetEmbeddedIcon(218, 16))
  MainMenu.SetIcon(L.MENU_Exit, "HICON:" GetEmbeddedIcon(212, 16))
  */
  ;@Ahk2Exe-IgnoreBegin
  MainMenu.SetIcon(L.MENU_OpenExplorer, "icon\explorer.ico")
  MainMenu.SetIcon(L.MENU_OpenTerminal, "icon\cmd.ico")
  MainMenu.SetIcon(L.MENU_StartHugoDev, "icon\cmd.ico")
  MainMenu.SetIcon(L.MENU_OpenTestPage, "icon\web.ico")
  MainMenu.SetIcon(L.MENU_Exit, "icon\exit.ico")
  ;@Ahk2Exe-IgnoreEnd

  MainMenu.Default := L.MENU_Exit
}

RegisterHotkeys(ctx) {
  Hotkey("^B", (*) => HandleQuoteWrap())
  Hotkey("^+C", (*) => ShowTidyGUI(ctx))
  Hotkey("^D", (*) => ShowImageGUI(ctx, true))
  Hotkey("^+D", (*) => ShowImageGUI(ctx, false))
  Hotkey("^G", (*) => ShowGalleryGUI(ctx, 2))
  Hotkey("^+G", (*) => ShowGalleryGUI(ctx, 3))
  Hotkey("^!N", (*) => CreateNewContent(ctx))
  Hotkey("^Q", (*) => SendText("&nbsp;`n`n"))
}

HandleQuoteWrap() {
  sel := GetSelection()
  if StrLen(sel) > 0
    SendText("「" sel "」")
  else
    SendInput("「」{left}")
}

ShowTidyGUI(ctx) {
  i := TidyGUI(ctx)
  if i.Hwnd != TidyGUI.InstanceHwnd
    return
  i.Show()
}

ShowImageGUI(ctx, isSingle) {
  i := ImageGUI(ctx, isSingle)
  if i.Hwnd != ImageGUI.InstanceHwnd
    return
  i.ShowAndHideAfter(ctx.C.TimeoutImage)
}

ShowGalleryGUI(ctx, imageNum) {
  g := GalleryGUI(ctx, imageNum)
  if g.Hwnd != GalleryGUI.InstanceHwnd
    return
  g.ShowAndHideAfter(ctx.C.TimeoutGallery)
}

CreateNewContent(ctx, *) {
  g := NewGUI(ctx)
  if g.Hwnd != NewGUI.InstanceHwnd
    return
  g.ShowAndHideAfter(ctx.C.TimeoutNew)
}

OpenTestPage(ctx) {
  execPath := ctx.C.WebBrowserExec
  args := ctx.C.WebBrowserArgs
  try {
    Run("`"" . execPath . "`" " . args)
  } catch Error {
    msg := "웹 브라우저를 실행할 수 없습니다.`n설정된 실행 파일 경로를 확인하세요.`n`n실행 파일: " execPath
    MsgBox(msg, "MarkdownHelper", 48)
  }
}

OnExitFunc(ExitReason, _) {
  if ExitReason == "Single" || ExitReason == "Reload"
    SoundPlay("*48")
}
OnExit(OnExitFunc)
