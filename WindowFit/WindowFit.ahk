/************************************************************************
 * @description Manage Window Position and Size
 * @author TetraTheta
 * @date 2026/04/19
 * @version 1.0.0
 ***********************************************************************/
#Requires AutoHotkey v2.0
#SingleInstance Force
DetectHiddenWindows(false)
Persistent(true)

; Information about executable
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright (c) 2026. TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription Manage Window Position and Size
;@Ahk2Exe-SetFileVersion 1.0.0.0
;@Ahk2Exe-SetMainIcon icon\main.ico
;@Ahk2Exe-SetProductName WindowFit

; ------------------------------------------------------------------------------
; Constants
; ------------------------------------------------------------------------------
global EVENT_OBJECT_SHOW := 0x8002
global OBJID_WINDOW := 0
global MONITOR_DEFAULTTONEAREST := 0x00000002
global WINEVENT_OUTOFCONTEXT := 0x0000
global WINEVENT_SKIPOWNPROCESS := 0x0002

; ------------------------------------------------------------------------------
; Variables
; ------------------------------------------------------------------------------
global PendingWindows := Map()
global WinEventCallback := 0
global WinEventHook := 0

; ------------------------------------------------------------------------------
; Startup
; ------------------------------------------------------------------------------
if !SetupWinEventHook() {
  MsgBox("SetWinEventHook 실패")
  ExitApp()
}

; ------------------------------------------------------------------------------
; Tray Icon & Menu
; ------------------------------------------------------------------------------
A_IconTip := "WindowFit"
MainMenu := A_TrayMenu
MainMenu.Delete()
MainMenu.Add("Exit", (*) => ExitApp())
MainMenu.Default := "Exit"
OnExit(Cleanup)

; ------------------------------------------------------------------------------
; Functions (Core)
; ------------------------------------------------------------------------------
SetupWinEventHook() {
  global EVENT_OBJECT_SHOW, WINEVENT_OUTOFCONTEXT, WINEVENT_SKIPOWNPROCESS
  global WinEventCallback, WinEventHook

  WinEventCallback := CallbackCreate(WinEventProc, "Fast", 7)
  WinEventHook := DllCall("SetWinEventHook"
    , "uint", EVENT_OBJECT_SHOW
    , "uint", EVENT_OBJECT_SHOW
    , "ptr", 0
    , "ptr", WinEventCallback
    , "uint", 0
    , "uint", 0
    , "uint", WINEVENT_OUTOFCONTEXT | WINEVENT_SKIPOWNPROCESS
    , "ptr")

  return !!WinEventHook
}

WinEventProc(hWinEventHook, event, hwnd, idObject, idChild, idEventThread, eventTime) {
  global OBJID_WINDOW, PendingWindows

  if !hwnd
    return
  if (idObject != OBJID_WINDOW or idChild != 0)
    return
  if (hwnd = A_ScriptHwnd)
    return

  ; 중복 이벤트 폭주 방지: 창별 1회만 짧게 지연 후 처리
  if PendingWindows.Has(hwnd)
    return
  PendingWindows[hwnd] := true
  SetTimer(FixWindowLater.Bind(hwnd), -30)  ; one-shot (폴링 아님)
}

FixWindowLater(hwnd) {
  global PendingWindows
  if PendingWindows.Has(hwnd)
    PendingWindows.Delete(hwnd)
  FitWindowToWorkArea(hwnd)
}

FitWindowToWorkArea(hwnd) {
  ; 창 유효성/가시성 확인
  if !DllCall("IsWindow", "ptr", hwnd, "int")
    return
  if !DllCall("IsWindowVisible", "ptr", hwnd, "int")
    return

  winTitle := "ahk_id " hwnd

  ; 최소화/최대화 창 제외 (일반 상태 창만)
  try mm := WinGetMinMax(winTitle)
  catch
    return
  if (mm != 0)
    return

  ; 도구창/쉘창 일부 제외
  try ex := WinGetExStyle(winTitle)
  catch
    return
  if (ex & 0x80) ; WS_EX_TOOLWINDOW
    return

  try cls := WinGetClass(winTitle)
  catch
    return
  if (cls = "Progman" or cls = "WorkerW" or cls = "Shell_TrayWnd")
    return

  ; 창 위치/크기
  try WinGetPos(&x, &y, &w, &h, winTitle)
  catch
    return
  if (w <= 0 or h <= 0)
    return

  ; 현재(가장 가까운) 모니터 작업 영역 가져오기
  if !GetWorkAreaByHwnd(hwnd, &L, &T, &R, &B)
    return

  workW := R - L
  workH := B - T
  if (workW <= 1 or workH <= 1)
    return

  newW := w
  newH := h
  resized := false

  ; 1) 창 크기가 작업영역보다 크면 "미만"으로 축소
  if (w > workW) {
    newW := workW - 1
    resized := true
  }
  if (h > workH) {
    newH := workH - 1
    resized := true
  }

  if resized {
    try WinMove(x, y, newW, newH, winTitle)
    catch
      return
    w := newW
    h := newH
  }

  ; 2) 우상단 좌표가 작업영역 밖이면 현재 모니터 좌상단(L,T)으로 이동
  topRightX := x + w - 1
  topRightY := y

  if (topRightX < L or topRightX >= R or topRightY < T or topRightY >= B) {
    try WinMove(L, T, , , winTitle)
  }
}

; ------------------------------------------------------------------------------
; Functions (Helper)
; ------------------------------------------------------------------------------
GetWorkAreaByHwnd(hwnd, &L, &T, &R, &B) {
  global MONITOR_DEFAULTTONEAREST
  hMon := DllCall("MonitorFromWindow", "ptr", hwnd, "uint", MONITOR_DEFAULTTONEAREST, "ptr")
  if !hMon
    return false

  ; MONITORINFO: cbSize(4) + rcMonitor(16) + rcWork(16) + dwFlags(4) = 40
  mi := Buffer(40, 0)
  NumPut("uint", 40, mi, 0)

  ok := DllCall("GetMonitorInfo", "ptr", hMon, "ptr", mi.Ptr, "int")
  if !ok
    return false

  L := NumGet(mi, 20, "int")
  T := NumGet(mi, 24, "int")
  R := NumGet(mi, 28, "int")
  B := NumGet(mi, 32, "int")
  return true
}

; ------------------------------------------------------------------------------
; Event
; ------------------------------------------------------------------------------
Cleanup(*) {
  global WinEventHook, WinEventCallback
  if WinEventHook
    DllCall("UnhookWinEvent", "ptr", WinEventHook)
  if WinEventCallback
    CallbackFree(WinEventCallback)
}
