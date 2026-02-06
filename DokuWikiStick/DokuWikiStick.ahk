/************************************************************************
 * @description DokuWiki on a Stick Helper
 * @author TetraTheta
 * @date 2026/02/03
 * @version 1.1.0
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
;@Ahk2Exe-SetFileVersion 1.1.0.0
;@Ahk2Exe-SetMainIcon icon\main.ico ; Default icon
;@Ahk2Exe-SetProductName DokuWikiStick

; ------------------------------------------------------------------------------
; Config
; ------------------------------------------------------------------------------
BrowserDelay := Number(IniGet("Browser", "Delay", "2000"))
BrowserOpen := Boolean(IniGet("Browser", "Open", "true"))
BrowserPath := IniGet("Browser", "Path", "")
BrowserPort := Number(IniGet("Browser", "Port", "8800"))

; Expand Environment Variable of BrowserPath
_browserPath := Buffer(32768)
DllCall("ExpandEnvironmentStrings", "str", BrowserPath, "ptr", _browserPath, "uint", 32768)
BrowserPath := StrGet(_browserPath)
_browserPath := ""

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
  ServerStopSilent()
  ExitApp()
}

HideTrayTip() {
  TrayTip()
  if SubStr(A_OSVersion, 1, 3) = "10." {
    A_IconHidden := true
    Sleep 10
    A_IconHidden := false
  }
}

OpenWiki(*) {
  url := "http://localhost:" BrowserPort
  if BrowserPath and FileExist(BrowserPath)
    Run("`"" BrowserPath "`" " url)
  else
    Run(url)
}

ServerRestart(*) {
  ShowTrayTip(, "Restarting MicroApache Server")
  ServerStopSilent()
  Sleep(1000)
  ServerStartSilent()
}

ServerStart(*) {
  ShowTrayTip(, "Starting MicroApache Server")
  ServerStartSilent()
}

ServerStartSilent(*) {
  Run(A_ScriptDir "\server\mapache.exe", A_ScriptDir "\server", "Hide")
}

ServerStop(*) {
  ShowTrayTip(, "Stopping MicroApache Server")
  ServerStartSilent()
}

ServerStopSilent(*) {
  ; AutoHotkey cannot kill process tree
  Run("taskkill.exe /IM mapache.exe /F /T", , "Hide")
  FileDelete("server\logs\httpd.pid")
}

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

ShowTrayTip(message := "", title := "", duration := 3000) {
  TrayTip(message, title)
  SetTimer(() => HideTrayTip(), -duration)
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

; ------------------------------------------------------------------------------
; Event
; ------------------------------------------------------------------------------
; OnExit : Play ding sound when exit by #SingleInstance Force
OnExitFunc(ExitReason, ExitCode) {
  if ExitReason == "Single" or ExitReason == "Reload"
    SoundPlay("*48")
}
OnExit(OnExitFunc)
