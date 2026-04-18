/************************************************************************
 * @description Create New Folder in Explorer and Enter Rename Mode
 * @author TetraTheta
 * @date 2026/04/19
 * @version 1.0.0
 ***********************************************************************/
#Requires AutoHotkey v2.0
#SingleInstance Force

; Information about executable
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright (c) 2026. TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription Create New Folder in Explorer and Enter Rename Mode
;@Ahk2Exe-SetFileVersion 1.0.0.0
;@Ahk2Exe-SetProductName NewFolder

; ------------------------------------------------------------------------------
; Startup
; ------------------------------------------------------------------------------
targetDir := ResolveTargetDirectory(A_Args)
if !targetDir {
  MsgBox("유효한 대상 경로를 찾을 수 없습니다.", "NewFolder", "Iconx")
  ExitApp(1)
}

newName := FindAvailableFolderName(targetDir)
if !newName {
  MsgBox("사용 가능한 폴더 이름을 찾지 못했습니다.`n검색 범위: 새 폴더 ~ 새 폴더 (1000)", "NewFolder", "Iconx")
  ExitApp(1)
}

newPath := targetDir "\" newName

if !TryCreateDirectory(newPath) {
  if A_IsAdmin {
    MsgBox("폴더를 생성하지 못했습니다.`n경로: " newPath, "NewFolder", "Iconx")
    ExitApp(1)
  }

  if !RelaunchAsAdmin(targetDir) {
    MsgBox("관리자 권한으로 다시 실행하지 못했습니다.", "NewFolder", "Iconx")
    ExitApp(1)
  }
  ExitApp()
}

if !EnterRenameMode(targetDir, newName, newPath)
  MsgBox("새 폴더는 생성되었지만 이름 변경 모드 진입에 실패했습니다.`n경로: " newPath, "NewFolder", "Icon!")

; ------------------------------------------------------------------------------
; Functions (Core)
; ------------------------------------------------------------------------------

ResolveTargetDirectory(args) {
  if args.Length < 1
    return ""

  target := Trim(args[1], "`" `t`r`n")
  if target = ""
    return ""

  ; Context Menu %V 값이 상대경로로 넘어오는 경우를 대비
  if !InStr(target, ":\") and SubStr(target, 1, 2) != "\\"
    target := A_WorkingDir "\" target

  if !DirExist(target)
    return ""

  return target
}

FindAvailableFolderName(targetDir) {
  baseName := "새 폴더"
  firstCandidate := targetDir "\" baseName
  if !FileExist(firstCandidate)
    return baseName

  Loop 999 {
    idx := A_Index + 1
    candidate := baseName " (" idx ")"
    candidatePath := targetDir "\" candidate
    if !FileExist(candidatePath)
      return candidate
  }

  return ""
}

TryCreateDirectory(path) {
  try {
    DirCreate(path)
    return true
  } catch {
    return false
  }
}

RelaunchAsAdmin(targetDir) {
  if A_IsCompiled {
    cmd := "*RunAs " Quote(A_ScriptFullPath) " " Quote(targetDir)
  } else {
    cmd := "*RunAs " Quote(A_AhkPath) " " Quote(A_ScriptFullPath) " " Quote(targetDir)
  }

  try {
    Run(cmd)
    return true
  } catch {
    return false
  }
}

EnterRenameMode(targetDir, folderName, fullPath) {
  ; 1) Windows Shell API (권장)
  if SelectItemInExplorer(fullPath, true)
    return true

  Sleep(50)

  ; 2) Shell COM rename verb 시도
  if InvokeRenameVerb(targetDir, folderName)
    return true

  Sleep(50)

  ; 3) 최후의 방법: API로 선택 후 F2
  if SelectItemInExplorer(fullPath, false) {
    Sleep(80)
    Send("{F2}")
    return true
  }

  return false
}

InvokeRenameVerb(targetDir, folderName) {
  try {
    shell := ComObject("Shell.Application")
    ns := shell.NameSpace(targetDir)
    if !ns
      return false

    item := ns.ParseName(folderName)
    if !item
      return false

    item.InvokeVerb("rename")
    return true
  } catch {
    return false
  }
}

SelectItemInExplorer(fullPath, editMode := false) {
  pidlAbs := DllCall("shell32\ILCreateFromPathW", "wstr", fullPath, "ptr")
  if !pidlAbs
    return false

  pidlParent := DllCall("shell32\ILClone", "ptr", pidlAbs, "ptr")
  if !pidlParent {
    DllCall("shell32\ILFree", "ptr", pidlAbs)
    return false
  }

  if !DllCall("shell32\ILRemoveLastID", "ptr", pidlParent, "int") {
    DllCall("shell32\ILFree", "ptr", pidlParent)
    DllCall("shell32\ILFree", "ptr", pidlAbs)
    return false
  }

  pidlChild := DllCall("shell32\ILFindLastID", "ptr", pidlAbs, "ptr")
  if !pidlChild {
    DllCall("shell32\ILFree", "ptr", pidlParent)
    DllCall("shell32\ILFree", "ptr", pidlAbs)
    return false
  }

  apidl := Buffer(A_PtrSize, 0)
  NumPut("ptr", pidlChild, apidl, 0)

  flags := editMode ? 0x0001 : 0x0000 ; OFASI_EDIT
  hr := DllCall("shell32\SHOpenFolderAndSelectItems"
    , "ptr", pidlParent
    , "uint", 1
    , "ptr", apidl.Ptr
    , "uint", flags
    , "int")

  DllCall("shell32\ILFree", "ptr", pidlParent)
  DllCall("shell32\ILFree", "ptr", pidlAbs)
  return hr >= 0
}

; ------------------------------------------------------------------------------
; Functions (Helper)
; ------------------------------------------------------------------------------
Quote(text) {
  return "`"" text "`""
}
