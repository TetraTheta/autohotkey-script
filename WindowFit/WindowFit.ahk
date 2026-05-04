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
  ; WS_POPUP + no WS_CAPTION 조합은 컨텍스트/트레이 메뉴 등 메뉴형 팝업이 많아 제외
  try style := WinGetStyle(winTitle)
  catch
    return
  try ex := WinGetExStyle(winTitle)
  catch
    return
  if ((style & 0x80000000) and !(style & 0x00C00000)) ; WS_POPUP && !WS_CAPTION
    return
  if (ex & 0x80) ; WS_EX_TOOLWINDOW
    return

  try cls := WinGetClass(winTitle)
  catch
    return
  if (cls = "Progman" or cls = "WorkerW" or cls = "Shell_TrayWnd" or cls = "#32768")
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

  ; 1) 네 모서리 중 하나라도 작업영역 밖이면 현재 모니터 좌상단(L,T)으로 이동
  left := x
  top := y
  right := x + w - 1
  bottom := y + h - 1

  if (left < L or left >= R
    or top < T or top >= B
    or right < L or right >= R
    or bottom < T or bottom >= B) {
    try WinMove(L, T, , , winTitle)
    catch
      return
    NudgeWindowToWorkTopLeftByExtendedFrame(hwnd, winTitle, L, T)
    x := L
    y := T
  }

  newW := w
  newH := h
  resized := false

  ; 2) 창 크기가 작업영역보다 크면 "10픽셀 작게" 축소
  if (w > workW) {
    newW := workW - 10
    resized := true
  }
  if (h > workH) {
    newH := workH - 10
    resized := true
  }

  if resized {
    ; 위치 우선 규칙 유지: 현재 위치(x, y)에서 크기만 조정
    try WinMove(x, y, newW, newH, winTitle)
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

NudgeWindowToWorkTopLeftByExtendedFrame(hwnd, winTitle, targetL, targetT) {
  if !GetExtendedFrameBounds(hwnd, &extL, &extT, &extR, &extB)
    return

  dx := targetL - extL
  dy := targetT - extT
  if (dx = 0 and dy = 0)
    return

  try WinGetPos(&curX, &curY, , , winTitle)
  catch
    return

  try WinMove(curX + dx, curY + dy, , , winTitle)
}

GetExtendedFrameBounds(hwnd, &L, &T, &R, &B) {
  ; DWMWA_EXTENDED_FRAME_BOUNDS = 9
  rect := Buffer(16, 0) ; RECT: left, top, right, bottom (int32 x 4)
  hr := DllCall("dwmapi\DwmGetWindowAttribute"
    , "ptr", hwnd
    , "uint", 9
    , "ptr", rect.Ptr
    , "uint", 16
    , "int")
  if (hr != 0)
    return false

  L := NumGet(rect, 0, "int")
  T := NumGet(rect, 4, "int")
  R := NumGet(rect, 8, "int")
  B := NumGet(rect, 12, "int")
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
