/************************************************************************
 * @description DokuWiki on a Stick Helper
 * @author TetraTheta
 * @date 2026/02/03
 * @version 1.0.0
 ***********************************************************************/
#Requires AutoHotkey v2.0
#Include "..\Lib\darkMode.ahk"
#Include "..\Lib\ini.ahk"
#SingleInstance Force
DetectHiddenWindows(true)
Persistent(true)

; Information about executable
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright (c) 2026. TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription DokuWiki on a Stick Helper
;@Ahk2Exe-SetFileVersion 1.0.0.0
;@Ahk2Exe-SetMainIcon icon\main.ico ; Default icon
;@Ahk2Exe-SetProductName DokuWikiStick

; ------------------------------------------------------------------------------
; Config
; ------------------------------------------------------------------------------
BrowserDelay := Number(IniGet("Browser", "Delay", "2000"))
BrowserOpen := Boolean(IniGet("Browser", "Open", "true"))
BrowserPath := IniGet("Browser", "Path", "")
BrowserPort := Number(IniGet("Browser", "Port", "8800"))

; ------------------------------------------------------------------------------
; Command-line Parsing
; ------------------------------------------------------------------------------
if A_Args.Length > 0 {
  for arg in A_Args {
    al := StrLower(arg)
    ; /delay:X
    if SubStr(al, 1, 7) = "/delay:" {
      delayVal := SubStr(al, 8)
      if delayVal ~= "^\d+$" and delayVal >= 0 and delayVal <= 10 {
        BrowserDelay := Number(delayVal) * 1000
      }
      ; Use default value if parsing failed
    }
    ; /nb
    else if al = "/nb" {
      BrowserOpen := false
    }
    ; Show help
    else {
      ShowHelp()
    }
  }
}

; ------------------------------------------------------------------------------
; Tray Icon & Menu
; ------------------------------------------------------------------------------
SetupMenu() {
  A_IconTip := "DokuWikiStick" ; Tray icon tip
  ;@Ahk2Exe-IgnoreBegin
  TraySetIcon("icon\main.ico")
  ;@Ahk2Exe-IgnoreEnd

  MainMenu := A_TrayMenu
  MainMenu.Delete()
  MainMenu.Add("Browse DokuWikiStick &Website`tW", OpenWiki)
  MainMenu.Add("&Restart MicroApache Server`tR", ServerRestart)
  MainMenu.Add("Explore DokuWikiStick &Directory`tD", (*) => Run(A_ScriptDir))
  MainMenu.Add()
  MainMenu.Add("E&xit`tX", Exit)

  MainMenu.Default := "E&xit`tX"
}
SetupMenu()
SetMenuAttr()

; ------------------------------------------------------------------------------
; Function (GUI)
; ------------------------------------------------------------------------------
Exit(*) {
  ServerStop()
  ExitApp()
}

OpenWiki(*) {
  url := "http://localhost:" BrowserPort
  if BrowserPath and FileExist(BrowserPath)
    Run("`"" BrowserPath "`" " url)
  else
    Run(url)
}

ServerRestart(*) {
  TrayTip(, "Restarting MicroApache Server")
  ServerStop()
  Sleep(1000)
  ServerStart()
}

ServerStart(*) {
  Run(A_ScriptDir "\server\mapache.exe", A_ScriptDir "\server", "Hide")
}

ServerStop(*) {
  ; AutoHotkey cannot kill process tree
  Run("taskkill.exe /IM mapache.exe /F /T", , "Hide")
}

Startup(*) {
  if !DirExist("server") {
    MsgBox("Could not locate 'server' directory.`nAre you sure that you're running the program in DokuWikiStick directory?", "Directory not found", "Iconx")
    ExitApp()
  }

  ServerStart()
  Sleep(BrowserDelay)
  if BrowserOpen
    OpenWiki()
}

Startup()

; ------------------------------------------------------------------------------
; Function (Helper)
; ------------------------------------------------------------------------------
Boolean(value) {
  switch String(value), false {
    case "1", "true", "yes", "on":
      return true
    case "0", "false", "no", "off", "":
      return false
    default:
      return false
  }
}

; Script function
ShowHelp() {
  help := (
    "DokuWikiStick.exe [options]`n`n"
    "[options]:`n"
    "/delay:n = Pause n seconds (0 to 10) between MicroApache start and Web Browser start`n"
    "/nb = Don't launch Web Browser`n`n"
    "Default: Web Browser opens after 2 seconds after MicroApache server starts"
  )
  MsgBox(help, "Help", 64)
  ExitApp()
}

; ------------------------------------------------------------------------------
; Event
; ------------------------------------------------------------------------------
; OnExit : Play ding sound when exit by #SingleInstance Force
OnExitFunc(ExitReason, ExitCode) {
  if ExitReason == "Single" or ExitReason == "Reload"
    SoundPlay("*48")
}
OnExit(OnExitFunc)
