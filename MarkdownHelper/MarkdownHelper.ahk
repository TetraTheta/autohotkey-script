/************************************************************************
 * @description My Hugo Blog Markdown Helper
 * @author TetraTheta
 * @date 2023/10/22
 * @version 3.0.0
 ***********************************************************************/
; No need to worry about multiple '#Include' usage of same file, because AutoHotkey will include it only once.
#Requires AutoHotkey v2.0
#Include "i18n.ahk"
#Include "locale.ahk"
#Include "..\Lib\darkMode.ahk"
#Include "..\Lib\extension.ahk"
#Include "..\Lib\ini.ahk"
#Include "..\Lib\orderedMap.ahk"
#SingleInstance Force

; Information about executable
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright (c) 2023. TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription My Hugo Blog Markdown Helper
;@Ahk2Exe-SetFileVersion 3.0.0.0
;@Ahk2Exe-SetLanguage 0x0412
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

; ------------------------------------------------------------------------------
; Internationalization
; ------------------------------------------------------------------------------
_scriptLang := GetLanguageCode()
; '/english' will force language to English
for _, arg in A_Args {
  if StrLower(arg) = "/english" {
    _scriptLang := "en"
    break
  }
}
; No need to use 'global L' in each function
L := I18N(MarkdownHelperIntlData, _scriptLang)

; ------------------------------------------------------------------------------
; New Post Category
; ------------------------------------------------------------------------------
N := GetCategoryMap(_scriptLang)
NK := []
for k, v in N
  NK.Push(k)

; ------------------------------------------------------------------------------
; Config
; ------------------------------------------------------------------------------
C := Map()
C.ProjectRootDir := IniGet("General", "Project Root Directory", A_ScriptDir)
C.KeepConsoleOpen := IniGet("General", "Keep Console Open", false)
C.TimeoutGallery := IniGet("Timeout", "Gallery", "15")
C.TimeoutImage := IniGet("Timeout", "Image", "15")
C.TimeoutNew := IniGet("Timeout", "New Post", "60")
C.ExplorerExec := IniGet("Explorer", "Executable", "explorer.exe")
C.ExplorerArgs := IniGet("Explorer", "Arguments", "")
C.TerminalExec := IniGet("Terminal", "Executable", A_ComSpec)
C.TerminalArgs := IniGet("Terminal", "Arguments", "/K cd /d C:\")
C.GitGUIExec := IniGet("Git GUI", "Executable", "C:\Program Files\Git\cmd\git-gui.exe")
C.GitGUIArgs := IniGet("Git GUI", "Arguments", A_ScriptDir)
C.DevExec := IniGet("Dev Server", "Executable", "hugo.exe")
C.DevArgs := IniGet("Dev Server", "Arguments", "")
C.WebBrowserExec := IniGet("Web Browser", "Executable", "chrome.exe")
C.WebBrowserArgs := IniGet("Web Browser", "Arguments", "")
C.RecentCategory := IniKey(, "Recent", "Category")
C.RecentTitle1 := IniKey(, "Recent", "Title 1")
C.RecentTitle2 := IniKey(, "Recent", "Title 2")
C.RecentTitle3 := IniKey(, "Recent", "Title 3")
C.RecentTitle4 := IniKey(, "Recent", "Title 4")
C.RecentTitle5 := IniKey(, "Recent", "Title 5")
; Sanitize config value
C.KeepConsoleOpen := C.KeepConsoleOpen ? true : false

; ------------------------------------------------------------------------------
; Variable
; ------------------------------------------------------------------------------
InputGUIHwnd := 0
InputTidyHwnd := 0

; ------------------------------------------------------------------------------
; Tray Icon & Menu
; ------------------------------------------------------------------------------
SetupMenu() {
  A_IconTip := "MarkdownHelper" ; Tray icon tip
  ;@Ahk2Exe-IgnoreBegin
  TraySetIcon("icon\main.ico")
  ;@Ahk2Exe-IgnoreEnd

  ; Submenu (Run Script)
  RunScriptMenu := Menu()
  RunScriptMenu.Add(L.MENU_NewContent, CreateNewContent)
  RunScriptMenu.Add()
  RunScriptMenu.Add(L.MENU_HugoModuleUpdate, (*) => Run("powershell.exe -Command `"$Host.UI.RawUI.WindowTitle='Updating Hugo Modules...';hugo mod get -u ./...;hugo mod tidy;Write-Host '==== DONE ====' -ForegroundColor Green;[void][System.Console]::ReadKey($false)`"", C.ProjectRootDir))
  RunScriptMenu.Add(L.MENU_BunDependenciesUpdate, (*) => Run("powershell.exe -Command `"$Host.UI.RawUI.WindowTitle='Updating Bun Dependencies...';bun outdated;bun update;bun install --lockfile-only;Write-Host '==== DONE ====' -ForegroundColor Green;[void][System.Console]::ReadKey($false)`"", C.ProjectRootDir))
  RunScriptMenu.Add()
  RunScriptMenu.Add(L.MENU_HugoModuleTidy, (*) => Run("powershell.exe -Command `"$Host.UI.RawUI.WindowTitle='Tidying Hugo Modules...';hugo mod tidy;Write-Host '==== DONE ====' -ForegroundColor Green;[void][System.Console]::ReadKey($false)`"", C.ProjectRootDir))
  /*@Ahk2Exe-Keep
  RunScriptMenu.SetIcon(L.MENU_NewContent, "HICON:" GetEmbeddedIcon(216, 16))
  RunScriptMenu.SetIcon(L.MENU_HugoModuleUpdate, "HICON:" GetEmbeddedIcon(211, 16))
  RunScriptMenu.SetIcon(L.MENU_BunDependenciesUpdate, "HICON:" GetEmbeddedIcon(211, 16))
  */
  ;@Ahk2Exe-IgnoreBegin
  RunScriptMenu.SetIcon(L.MENU_NewContent, "icon\new.ico")
  RunScriptMenu.SetIcon(L.MENU_HugoModuleUpdate, "icon\download.ico")
  RunScriptMenu.SetIcon(L.MENU_BunDependenciesUpdate, "icon\download.ico")
  ;@Ahk2Exe-IgnoreEnd

  ; Submenu (Misc)
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

  ; Main Menu
  MainMenu := A_TrayMenu
  MainMenu.Delete()
  MainMenu.Add(L.MENU_OpenExplorer, (*) => Run("`"" . C.ExplorerExec . "`" " . C.ExplorerArgs))
  MainMenu.Add(L.MENU_OpenTerminal, (*) => Run("`"" . C.TerminalExec . "`" " . C.TerminalArgs))
  MainMenu.Add(L.MENU_OpenGitGUI, (*) => Run("`"" . C.GitGUIExec . "`" " . C.GitGUIArgs, C.ProjectRootDir))
  MainMenu.Add()
  MainMenu.Add(L.MENU_StartHugoDev, (*) => Run("`"" . C.DevExec . "`" " . C.DevArgs, C.ProjectRootDir))
  MainMenu.Add(L.MENU_OpenTestPage, (*) => Run("`"" . C.WebBrowserExec . "`" " . C.WebBrowserArgs))
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
SetupMenu()
SetMenuAttr()

; ------------------------------------------------------------------------------
; Hotkey
; ------------------------------------------------------------------------------
; Ctrl + B : 「」
^B:: {
  sel := GetSelection()
  if StrLen(sel) > 0
    SendText("「" sel "」")
  else
    SendInput("「」{left}")
}
; Ctrl + Shift + C : Open Tidy GUI
^+C:: {
  i := TidyGUI()
  if i.Hwnd != TidyGUI.InstanceHwnd
    return
  i.Show()
}
; Ctrl + D : Insert single Markdown image
^D:: {
  i := ImageGUI(true)
  if i.Hwnd != ImageGUI.InstanceHwnd
    return
  i.ShowAndHideAfter(C.TimeoutImage)
}
; Ctrl + Shift + D : Insert multiple Markdown images in a row
^+D:: {
  i := ImageGUI(false)
  if i.Hwnd != ImageGUI.InstanceHwnd
    return
  i.ShowAndHideAfter(C.TimeoutImage)
}
; Ctrl + G: Insert 'gallery/image' shortcode with length of 2
^G:: {
  g := GalleryGUI(2)
  if g.Hwnd != GalleryGUI.InstanceHwnd
    return
  g.ShowAndHideAfter(C.TimeoutGallery)
}
; Ctrl + Shift + G: Insert 'gallery/image' shortcode with length of 3
^+G:: {
  g := GalleryGUI(3)
  if g.Hwnd != GalleryGUI.InstanceHwnd
    return
  g.ShowAndHideAfter(C.TimeoutGallery)
}
; Ctrl + Alt + N : New Content
^!N:: CreateNewContent()
; Ctrl + Q : Insert NBSP
^Q:: SendText("&nbsp;`n`n")

; ------------------------------------------------------------------------------
; Function (GUI)
; ------------------------------------------------------------------------------
#Include "gui.ahk"

CreateNewContent(*) {
  g := NewGUI()
  if g.Hwnd != NewGUI.InstanceHwnd
    return
  g.ShowAndHideAfter(C.TimeoutNew)
}

/**
 * Get handle of embedded icon (HICON) by its group id
 * @param resNum ID number of Icon Group (use Resource Hacker)
 * @param size Desired size of the icon
 * @return {Integer} HICON (ptr) or 0 on failure
 */
GetEmbeddedIcon(resNum := 209, size := 32) {
  static IMAGE_ICON := 1
  static LR_SHARED := 0x8000 ; Let system manage the lifetime (do not use DestroyIcon)
  static LR_DEFAULTSIZE := 0x40
  flags := LR_SHARED | LR_DEFAULTSIZE

  hMod := DllCall("GetModuleHandleW", "ptr", 0, "ptr")
  if !hMod
    return 0
  namePtr := resNum + 0
  hIcon := DllCall("LoadImageW", "ptr", hMod, "ptr", namePtr, "uint", IMAGE_ICON, "int", size, "int", size, "uint", flags, "ptr")
  return hIcon
}

/**
 * Enable Ctrl+Backspace feature on ComboBox control
 * @param hEdit HWND of ComboBox control
 * @param {Integer} option
 */
EnableAutoCompleteOnComboBox(hCombo, option := 0x20000000) {
  CBEM_GETEDITCONTROL := 0x0407 ; WM_USER + 7
  hEdit := DllCall("SendMessageW", "ptr", hCombo, "uint", CBEM_GETEDITCONTROL, "ptr", 0, "ptr", 0, "ptr")
  if !hEdit
    hEdit := DllCall("FindWindowExW", "ptr", hCombo, "ptr", 0, "wstr", "Edit", "wstr", "", "ptr")

  if !hEdit
    return

  EnableAutoCompleteOnEdit(hEdit, option)
}

/**
 * Enable Ctrl+Backspace feature on Edit control. Do not use with Multiline Edit.
 * @param hEdit HWND of Edit control
 * @param {Integer} option
 */
EnableAutoCompleteOnEdit(hEdit, option := -1) {
  SHACF_FILESYS_ONLY := 0x00000010
  SHACF_AUTOSUGGEST_FORCE_OFF := 0x20000000
  SHACF_AUTOAPPEND_FORCE_OFF := 0x80000000
  if option = -1
    option := SHACF_FILESYS_ONLY | SHACF_AUTOSUGGEST_FORCE_OFF | SHACF_AUTOAPPEND_FORCE_OFF
  ; https://devblogs.microsoft.com/oldnewthing/20071011-00/?p=24823
  ; https://learn.microsoft.com/en-us/windows/win32/api/shlwapi/nf-shlwapi-shautocomplete
  DllCall("ole32\CoInitialize", "uint", 0)
  DllCall("shlwapi\SHAutoComplete", "ptr", hEdit, "uint", option)
  DllCall("ole32\CoUninitialize")
}

/**
 * Shake given GUI
 * @param {Gui} targetGui GUI to shake
 * @param {Integer} iShakeCount Number of shake
 * @param {Integer} iRattleX Magnitude of shake, in X axis.
 * @param {Integer} iRattleY Magnitude of shake, in Y axis.
 */
ShakeGUI(targetGui, iShakeCount := 20, iRattleX := 3, iRattleY := 3) {
  if !(IsObject(targetGui) and targetGui is Gui)
    return
  oriX := 0, oriY := 0
  targetGui.GetPos(&oriX, &oriY)
  loop iShakeCount {
    rx := Random(oriX - iRattleX, oriX + iRattleX)
    ry := Random(oriY - iRattleY, oriY + iRattleY)
    targetGui.Move(rx, ry)
    Sleep(10)
  }
  targetGui.Move(oriX, oriY)
}

; ------------------------------------------------------------------------------
; Function (Helper)
; ------------------------------------------------------------------------------
/**
 * @param {String} inputStr
 * @param {Integer} count
 */
BuildGalleryString(inputStr, count) {
  arr := GetNumStringArray(inputStr, count)
  if arr.Length = 0
    return ""

  result := arr.Implode("|")
  return "{{< gallery/image src=`"" result "`" >}}"
}

/**
 * @param {String} inputStr
 * @param {Integer} count
 */
BuildMDImageString(inputStr, count) {
  arr := GetNumStringArray(inputStr, count)
  if arr.Length = 0
    return ""

  for i, v in arr {
    SplitPath(v, , , &ext)
    if ext = ""
      arr[i] := v ".webp"
  }

  result := arr.Implode(")`n`n![](")
  return "![](" result ")"
}

/*
; Example Category INI content
[ChitChat] ; Section name is not important
display.en=Chit Chat
display.ko=잡담
kind=chit-chat
*/
/**
 * Get category map data from <code>A_ScriptNameOnly</code>-Category.ini
 * @param {String} lang
 * @returns {OrderedMap}
 */
GetCategoryMap(lang := _scriptLang) {
  iniPath := GetIniPath(A_ScriptNameOnly "-Category")
  try content := FileRead(iniPath)
  catch {
    FileAppend("", iniPath)
    content := ""
  }
  if content = ""
    ; iniPath is not found or empty
    return OrderedMap()

  m := OrderedMap()
  displayKey := "display." lang

  curDisplay := ""
  curKind := ""

  for line in StrSplit(content, "`n") {
    line := Trim(line, "`t`r ")
    if line = "" or SubStr(line, 1, 1) = ";" or SubStr(line, 1, 1) = "#"
      continue

    if SubStr(line, 1, 1) = "[" {
      if (curDisplay != "" and curKind != "")
        m[curDisplay] := curKind
      curDisplay := ""
      curKind := ""
      continue
    }

    pos := InStr(line, "=")
    if !pos
      continue

    key := Trim(SubStr(line, 1, pos - 1))
    val := Trim(SubStr(line, pos + 1))

    if (key == displayKey)
      curDisplay := val
    else if (key == "kind")
      curKind := val
  }

  if curDisplay != "" and curKind != ""
    m[curDisplay] := curKind

  return m
}

/**
 * @param {String} inputStr
 * @param {Integer} count
 * @returns {Array}
 */
GetNumStringArray(inputStr, count) {
  if count <= 0
    return []

  ; Get extension if present
  s := String(inputStr)
  ext := ""
  if RegExMatch(s, "\.([A-Za-z0-9]+)$", &extM) {
    ext := "." extM.0
    base := SubStr(s, 1, StrLen(s) - StrLen(ext))
  } else
    base := s

  ; Detect number at front or end of 'base'
  if RegExMatch(base, "^\d+", &m) {
    numPart := m.0
    rest := SubStr(s, StrLen(numPart) + 1)
    pos := "front"
  } else if RegExMatch(base, "\d+$", &m) {
    numPart := m.0
    prefix := SubStr(base, 1, StrLen(s) - StrLen(numPart))
    pos := "end"
  } else {
    arr := []
    arr.Push(s)
    return arr
  }

  ; Determine zero-padding rule
  baseNum := numPart + 0
  origLen := StrLen(numPart)
  hasLeadingZero := (origLen > 1 and SubStr(numPart, 1, 1) = "0")
  isPureNumber := (pos = "front" and rest = "")

  width := 0
  zeroPad := false
  if isPureNumber {
    if hasLeadingZero
      width := origLen
    else {
      width := origLen
      if width < 3
        width := 3
    }
    zeroPad := true
  } else if hasLeadingZero {
    width := origLen
    zeroPad := true
  }

  ; Build array
  arr := []
  loop count {
    n := baseNum + A_Index - 1
    sNum := n . ""
    if zeroPad and (StrLen(sNum) < width) {
      zeros := ""
      toAdd := width - StrLen(sNum)
      loop toAdd
        zeros .= "0"
      sNum := zeros . sNum
    }
    out := (pos = "front") ? sNum . rest : prefix . sNum
    arr.Push(out)
  }
  return arr
}

/**
 * Returns currently selected text
 * @returns {String} Copied String
 */
GetSelection() {
  ; 1) Standard Edit/RichEdit controls via EM_GETSEL
  focused := ControlGetFocus("A")
  hwnd := 0
  if focused {
    try {
      if RegExMatch(focused, "^\d+$")
        hwnd := focused
      else
        hwnd := ControlGetHwnd(focused, "A")
    } catch {
      hwnd := 0
    }
  }
  if hwnd {
    EM_GETSEL := 0x00B0
    try {
      ret := SendMessage(EM_GETSEL, 0, 0, "", "ahk_id " hwnd)
      start := ret & 0xFFFF
      finish := (ret >> 16) & 0xFFFF
      if finish < start
        tmp := start, start := finish, finish := tmp
      if finish > start {
        full := ControlGetText("", "ahk_id " hwnd)
        return SubStr(full, start + 1, finish - start)
      }
    }
  }
  ; 2) UI Automation TextPattern for Modern apps and Web browsers
  try {
    uia := ComObject("UIAutomationClient.CUIAutomation")
    el := uia.GetFocusedElement()
    if el {
      try textPattern := el.GetCurrentPatternAs("TextPattern")
      catch {
        textPattern := el.GetCurrentPattern(10014) ; UIA_TextPatternId
      }
      if textPattern {
        ranges := textPattern.GetSelection()
        if IsObject(ranges) and ranges.Length > 0 {
          range := ranges.GetElement(0) ? ranges.GetElement(0) : ranges[0]
          sel := range.GetText(-1)
          if sel != ""
            return sel
        }
      }
    }
  }
  ; 3) Clipboard fallback
  prevClip := ClipboardAll()
  A_Clipboard := ""
  Sleep(10)
  Send("^c")
  if ClipWait(0.35) {
    sel := A_Clipboard
    A_Clipboard := prevClip
    Sleep(10)
    return sel
  }
}

; ------------------------------------------------------------------------------
; Event
; ------------------------------------------------------------------------------
; OnExit : Play ding sound when exit by #SingleInstance Force
OnExitFunc(ExitReason, ExitCode) {
  if ExitReason == "Single" || ExitReason == "Reload"
    SoundPlay("*48")
}
OnExit(OnExitFunc)
