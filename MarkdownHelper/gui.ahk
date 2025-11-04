; ##################
; #    FUNCTION    #
; ##################
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

; ###############
; #    CLASS    #
; ###############

class GalleryGUI extends Gui {
  static InstanceHwnd := 0 ; Track if there is already an existing Window
  _OnTickFunc := this.OnTick.Bind(this)
  EditValue := ""
  GalNumValue := ""
  OkPressed := false
  TimeLeft := 0

  __New(imageNum := 3) {
    if GalleryGUI.InstanceHwnd {
      try WinActivate("ahk_id " GalleryGUI.InstanceHwnd)
      return GalleryGUI.InstanceHwnd
    }

    ; Set GUI icon (hack)
    /*@Ahk2Exe-Keep
    TraySetIcon("HICON:" GetEmbeddedIcon(214, 32))
    */
    ;@Ahk2Exe-IgnoreBegin
    TraySetIcon("icon\gallery.ico")
    ;@Ahk2Exe-IgnoreEnd
    super.__New(, L.GAL_Title)
    /*@Ahk2Exe-Keep
    TraySetIcon("*")
    */
    ;@Ahk2Exe-IgnoreBegin
    TraySetIcon("icon\main.ico")
    ;@Ahk2Exe-IgnoreEnd

    ; Save HWND
    GalleryGUI.InstanceHwnd := this.Hwnd

    ; GUI option
    this.Opt("+AlwaysOnTop -MaximizeBox -MinimizeBox -Resize +OwnDialogs")
    this.OnEvent("Escape", this.Destroy)
    this.OnEvent("Close", this.Destroy)
    this.SetFont("s10", "Segoe UI")

    ; GUI element (order matters for tabstop)
    /*@Ahk2Exe-Keep
    this.AddPicture("x12 y12 w32 h-1", "HICON:" GetEmbeddedIcon(214, 32))
    */
    ;@Ahk2Exe-IgnoreBegin
    this.AddPicture("x12 y12 w32 h-1", "icon\gallery.ico") ; Picture
    ;@Ahk2Exe-IgnoreEnd
    this.Timer := this.AddText("x22 y51 w25 h22", Format("{:02}", C.TimeoutGallery)) ; Timer
    this.AddText("x50 y12 w372 h32", L.GAL_Message . imageNum) ; Message
    this.AddText("x12 y73 w410 h22", L.GAL_LabelEdit) ; Label Edit
    this.Edit := this.AddEdit("x12 y98 w364 h25 -Multi") ; Edit
    this.GalNum := this.AddDDL("x382 y98 w40 h25 vGalNum Choose" imageNum " R3", ["1", "2", "3"]) ; Gallery Number
    this.AddButton("x266 y141 w75 h33 +Default", L.BTN_OK).OnEvent("Click", (*) => this.OnOK()) ; OK
    this.AddButton("x347 y141 w75 h33", L.BTN_Cancel).OnEvent("Click", (*) => this.OnCancel()) ; Cancel
    this.AddButton("x12 y141 w75 h33", L.BTN_Help).OnEvent("Click", (*) => this.OnHelp()) ; Help

    ; Enable AutoComplete on Edit to use Ctrl+Backspace
    EnableAutoCompleteOnEdit(this.Edit.Hwnd)

    ; GUI event
    this.OnEvent("Close", (*) => this.OnCancel())

    SetWinAttr(this)
    SetWinTheme(this)
  }

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

  Destroy() {
    SetTimer(this._OnTickFunc, 0)
    h := this.Hwnd
    super.Destroy()
    if GalleryGUI.InstanceHwnd = h
      GalleryGUI.InstanceHwnd := 0
    if this.OkPressed
      this.SendText()
  }

  DestroyWithoutAction() {
    this.OkPressed := false
    this.Destroy()
  }

  OnOK() {
    if this.Edit.Value = "" {
      ShakeGUI(this)
    } else {
      SetTimer(this._OnTickFunc, 0)
      this.OkPressed := true
      this.EditValue := this.Edit.Value
      this.GalNumValue := this.GalNum.Text
      this.Destroy()
    }
  }

  OnCancel() {
    SetTimer(this._OnTickFunc, 0)
    this.DestroyWithoutAction()
  }

  OnHelp() {
    MsgBox(L.GAL_Help, L.BTN_Help, 4096)
  }

  OnTick() {
    this.TimeLeft -= 1
    if this.TimeLeft <= 0 {
      this.OnTimeout()
      return
    }
    this.UpdateTimerText()
  }

  OnTimeout() {
    SetTimer(this._OnTickFunc, 0)
    this.DestroyWithoutAction()
  }

  SendText() {
    SendText(this.BuildGalleryString(this.EditValue, Integer(this.GalNumValue)) "`n`n")
  }

  ShowAndHideAfter(seconds) {
    if GalleryGUI.InstanceHwnd and GalleryGUI.InstanceHwnd != this.Hwnd {
      try WinActivate("ahk_id " GalleryGUI.InstanceHwnd)
      return
    }

    this.TimeLeft := seconds
    this.UpdateTimerText()
    this.Show("w434 h186 Center")
    this.Edit.Focus()

    SetTimer(this._OnTickFunc, 1000)
  }

  UpdateTimerText() {
    this.Timer.Text := Format("{:02}", this.TimeLeft)
  }
}

class ImageGUI extends Gui {
  static InstanceHwnd := 0 ; Track if there is already an existing Window
  _OnTickFunc := this.OnTick.Bind(this)
  isSingle := false
  EditValue := ""
  ImgNumValue := ""
  OkPressed := false
  TimeLeft := 0

  __New(isSingle := false) {
    this.isSingle := isSingle
    if ImageGUI.InstanceHwnd {
      try WinActivate("ahk_id " ImageGUI.InstanceHwnd)
      return ImageGUI.InstanceHwnd
    }

    ; Set GUI icon (hack)
    /*@Ahk2Exe-Keep
    TraySetIcon("HICON:" GetEmbeddedIcon(215, 32))
    */
    ;@Ahk2Exe-IgnoreBegin
    TraySetIcon("icon\image.ico")
    ;@Ahk2Exe-IgnoreEnd
    super.__New(, L.IMG_Title)
    /*@Ahk2Exe-Keep
    TraySetIcon("*")
    */
    ;@Ahk2Exe-IgnoreBegin
    TraySetIcon("icon\main.ico")
    ;@Ahk2Exe-IgnoreEnd

    ; Save HWND
    ImageGUI.InstanceHwnd := this.Hwnd

    ; GUI option
    this.Opt("+AlwaysOnTop -MaximizeBox -MinimizeBox -Resize +OwnDialogs")
    this.OnEvent("Escape", this.Destroy)
    this.OnEvent("Close", this.Destroy)
    this.SetFont("s10", "Segoe UI")

    ; GUI element (order matters for tabstop)
    /*@Ahk2Exe-Keep
    this.AddPicture("x12 y12 w32 h-1", "HICON:" GetEmbeddedIcon(215, 32))
    */
    ;@Ahk2Exe-IgnoreBegin
    this.AddPicture("x12 y12 w32 h-1", "icon\image.ico") ; Picture
    ;@Ahk2Exe-IgnoreEnd
    this.Timer := this.AddText("x22 y51 w25 h22", Format("{:02}", C.TimeoutGallery)) ; Timer
    this.AddText("x50 y12 w372 h32", isSingle ? L.IMG_MessageSingle : L.IMG_MessageMulti) ; Message
    this.AddText("x12 y73 w410 h22", isSingle ? L.IMG_LabelSingle : L.IMG_LabelMulti) ; Label Edit
    if isSingle {
      this.Edit := this.AddEdit("x12 y98 w410 h25 -Multi") ; Edit (Text)
    } else {
      this.Edit := this.AddEdit("x12 y98 w324 h25 -Multi") ; Edit (Text)
      this.ImgNum := this.AddEdit("x342 y98 w80 h25") ; Image Number
      this.AddUpDown("Range1-65535")
    }
    this.AddButton("x266 y141 w75 h33 +Default", L.BTN_OK).OnEvent("Click", (*) => this.OnOK()) ; OK
    this.AddButton("x347 y141 w75 h33", L.BTN_Cancel).OnEvent("Click", (*) => this.OnCancel()) ; Cancel
    this.AddButton("x12 y141 w75 h33", L.BTN_Help).OnEvent("Click", (*) => this.OnHelp()) ; Help

    ; Enable AutoComplete on Edit to use Ctrl+Backspace
    EnableAutoCompleteOnEdit(this.Edit.Hwnd)

    ; GUI event
    this.OnEvent("Close", (*) => this.OnCancel())

    SetWinAttr(this)
    SetWinTheme(this)
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

  Destroy() {
    SetTimer(this._OnTickFunc, 0)
    h := this.Hwnd
    super.Destroy()
    if ImageGUI.InstanceHwnd = h
      ImageGUI.InstanceHwnd := 0
    if this.OkPressed
      this.SendText()
  }

  DestroyWithoutAction() {
    this.OkPressed := false
    this.Destroy()
  }

  OnOK() {
    if this.Edit.Value = "" {
      ShakeGUI(this)
    } else {
      SetTimer(this._OnTickFunc, 0)
      this.OkPressed := true
      this.EditValue := this.Edit.Value
      this.ImgNumValue := this.isSingle ? 1 : this.ImgNum.Value
      this.Destroy()
    }
  }

  OnCancel() {
    SetTimer(this._OnTickFunc, 0)
    this.DestroyWithoutAction()
  }

  OnHelp() {
    MsgBox(L.IMG_Help, L.BTN_Help, 4096)
  }

  OnTick() {
    this.TimeLeft -= 1
    if this.TimeLeft <= 0 {
      this.OnTimeout()
      return
    }
    this.UpdateTimerText()
  }

  OnTimeout() {
    SetTimer(this._OnTickFunc, 0)
    this.DestroyWithoutAction()
  }

  SendText() {
    ; SendText() lags, so use clipboard instead
    prevClip := ClipboardAll()
    A_Clipboard := this.BuildMDImageString(this.EditValue, Integer(this.ImgNumValue)) "`n`n"
    Sleep(10)
    Send("^v")
    Sleep(10)
    A_Clipboard := prevClip
  }

  ShowAndHideAfter(seconds) {
    if ImageGUI.InstanceHwnd and ImageGUI.InstanceHwnd != this.Hwnd {
      try WinActivate("ahk_id " ImageGUI.InstanceHwnd)
      return
    }

    this.TimeLeft := seconds
    this.UpdateTimerText()
    this.Show("w434 h186 Center")
    this.Edit.Focus()

    SetTimer(this._OnTickFunc, 1000)
  }

  UpdateTimerText() {
    this.Timer.Text := Format("{:02}", this.TimeLeft)
  }
}

class NewGUI extends Gui {
  static InstanceHwnd := 0 ; Track if there is already an existing Window
  _OnTickFunc := this.OnTick.Bind(this)
  CategoryValue := ""
  NewTitleValue := ""
  OkPressed := false
  TimeLeft := 0

  __New() {
    if NewGUI.InstanceHwnd {
      try WinActivate("ahk_id " NewGUI.InstanceHwnd)
      return NewGUI.InstanceHwnd
    }

    ; Set GUI icon (hack)
    /*@Ahk2Exe-Keep
    TraySetIcon("HICON:" GetEmbeddedIcon(216, 32))
    */
    ;@Ahk2Exe-IgnoreBegin
    TraySetIcon("icon\new.ico")
    ;@Ahk2Exe-IgnoreEnd
    super.__New(, L.NEW_Title)
    /*@Ahk2Exe-Keep
    TraySetIcon("*")
    */
    ;@Ahk2Exe-IgnoreBegin
    TraySetIcon("icon\main.ico")
    ;@Ahk2Exe-IgnoreEnd

    ; Save HWND
    NewGUI.InstanceHwnd := this.Hwnd

    ; GUI option
    this.Opt("+AlwaysOnTop -MaximizeBox -MinimizeBox -Resize +OwnDialogs")
    this.OnEvent("Escape", this.Destroy)
    this.OnEvent("Close", this.Destroy)
    this.SetFont("s10", "Segoe UI")

    ; GUI element (order matters for tabstop)
    /*@Ahk2Exe-Keep
    this.AddPicture("x12 y12 w32 h-1", "HICON:" GetEmbeddedIcon(216, 32))
    */
    ;@Ahk2Exe-IgnoreBegin
    this.AddPicture("x12 y12 w32 h-1", "icon\new.ico") ; Picture
    ;@Ahk2Exe-IgnoreEnd
    this.Timer := this.AddText("x22 y51 w25 h22", Format("{:02}", C.TimeoutGallery)) ; Timer
    this.AddText("x50 y12 w372 h32", L.NEW_Message) ; Message
    this.AddText("x12 y73 w410 h22", L.NEW_Category) ; Label Category
    this.Category := this.AddDDL("x12 y98 w410 h25 R10", NK) ; DDL Category
    this.AddText("x12 y126 w410 h22", L.NEW_NewTitle) ; Label Title
    this.NewTitle := this.AddComboBox("x12 y151 w410 h25 R5", [C.RecentTitle1.Value, C.RecentTitle2.Value, C.RecentTitle3.Value, C.RecentTitle4.Value, C.RecentTitle5.Value]) ; ComboBox Title
    this.AddButton("x266 y191 w75 h33 +Default", L.BTN_OK).OnEvent("Click", (*) => this.OnOK()) ; OK
    this.AddButton("x347 y191 w75 h33", L.BTN_Cancel).OnEvent("Click", (*) => this.OnCancel()) ; Cancel
    this.AddButton("x12 y191 w75 h33", L.BTN_Help).OnEvent("Click", (*) => this.OnHelp()) ; Help

    ; Choose last selected Category
    this.Category.Choose(C.RecentCategory.Value)

    ; Enable AutoComplete on Edit to use Ctrl+Backspace
    EnableAutoCompleteOnComboBox(this.NewTitle.Hwnd)

    ; Set item height
    ; PostMessage(0x0153, 0, 30, this.Category)
    ; PostMessage(0x0153, 0, 30, this.NewTitle)

    ; GUI event
    this.OnEvent("Close", (*) => this.OnCancel())

    SetWinAttr(this)
    SetWinTheme(this)
  }

  CreateNewContent() {
    args := A_ComSpec " " (C.KeepConsoleOpen ? "/K" : "/C") " cd /d `"" C.ProjectRootDir "`" && bun run cli new -k " N[this.CategoryValue] " `"" this.NewTitleValue "`""
    Run(args, C.ProjectRootDir)
  }

  Destroy() {
    SetTimer(this._OnTickFunc, 0)
    h := this.Hwnd
    super.Destroy()
    if NewGUI.InstanceHwnd = h
      NewGUI.InstanceHwnd := 0
    if this.OkPressed
      this.CreateNewContent()
  }

  DestroyWithoutAction() {
    this.OkPressed := false
    this.Destroy()
  }

  OnOK() {
    global C
    if this.NewTitle.Value = "" {
      ShakeGUI(this)
    } else {
      SetTimer(this._OnTickFunc, 0)
      this.OkPressed := true
      this.CategoryValue := this.Category.Text
      this.NewTitleValue := this.NewTitle.Text

      ; Modify Config
      if this.CategoryValue != C.RecentCategory.Value
        C.RecentCategory.Value := this.CategoryValue
      if this.NewTitleValue != C.RecentTitle1.Value {
        C.RecentTitle5.Value := C.RecentTitle4.Value
        C.RecentTitle4.Value := C.RecentTitle3.Value
        C.RecentTitle3.Value := C.RecentTitle2.Value
        C.RecentTitle2.Value := C.RecentTitle1.Value
        C.RecentTitle1.Value := this.NewTitleValue
      }

      this.Destroy()
    }
  }

  OnCancel() {
    SetTimer(this._OnTickFunc, 0)
    this.DestroyWithoutAction()
  }

  OnHelp() {
    MsgBox(L.GAL_Help, L.BTN_Help, 4096)
  }

  OnTick() {
    this.TimeLeft -= 1
    if this.TimeLeft <= 0 {
      this.OnTimeout()
      return
    }
    this.UpdateTimerText()
  }

  OnTimeout() {
    SetTimer(this._OnTickFunc, 0)
    this.DestroyWithoutAction()
  }

  ShowAndHideAfter(seconds) {
    if NewGUI.InstanceHwnd and NewGUI.InstanceHwnd != this.Hwnd {
      try WinActivate("ahk_id " NewGUI.InstanceHwnd)
      return
    }

    this.TimeLeft := seconds
    this.UpdateTimerText()
    this.Show("w434 h236 Center")
    this.NewTitle.Focus()

    SetTimer(this._OnTickFunc, 1000)
  }

  UpdateTimerText() {
    this.Timer.Text := Format("{:02}", this.TimeLeft)
  }
}

class TidyGUI extends Gui {
  static InstanceHwnd := 0 ; Track if there is already an existing Window

  __New() {
    if TidyGUI.InstanceHwnd {
      try WinActivate("ahk_id " TidyGUI.InstanceHwnd)
      return TidyGUI.InstanceHwnd
    }

    ; Set GUI icon (hack)
    /*@Ahk2Exe-Keep
    TraySetIcon("HICON:" GetEmbeddedIcon(210, 32))
    */
    ;@Ahk2Exe-IgnoreBegin
    TraySetIcon("icon\document.ico")
    ;@Ahk2Exe-IgnoreEnd
    super.__New(, L.TIDY_Title)
    /*@Ahk2Exe-Keep
    TraySetIcon("*")
    */
    ;@Ahk2Exe-IgnoreBegin
    TraySetIcon("icon\main.ico")
    ;@Ahk2Exe-IgnoreEnd

    ; Save HWND
    TidyGUI.InstanceHwnd := this.Hwnd

    ; GUI option
    this.Opt("+AlwaysOnTop -MaximizeBox -MinimizeBox -Resize +OwnDialogs")
    this.OnEvent("Escape", this.Destroy)
    this.OnEvent("Close", this.Destroy)
    this.SetFont("s10", "Segoe UI")

    ; GUI element (order matters for tabstop)
    sel := GetSelection()
    ;this.Edit := this.AddEdit("x12 y12 w560 h474 +Multi +Wrap", sel)
    this.Edit := MultiEdit(this.AddEdit("x12 y12 w560 h474 +Multi +Wrap", sel))
    this.TextLength := this.AddText("x12 y491 w560 h22", L.TIDY_Length . StrLen(sel))
    this.AddButton("x12 y516 w277 h33", L.BTN_Tidy).OnEvent("Click", (*) => this.OnTidy()) ; Tidy
    this.AddButton("x295 y516 w277 h33", L.BTN_TidyCopy).OnEvent("Click", (*) => this.OnTidyCopy()) ; Tidy & Copy

    ; Enable AutoComplete on Edit to use Ctrl+Backspace
    ;EnableAutoCompleteOnEdit(this.Edit.Hwnd) ; AutoComplete doesn't work with Multiline

    ; GUI event
    this.OnEvent("Close", (*) => this.Destroy())
    This.Edit.OnEvent("Change", (*) => this.OnEditChange())

    SetWinAttr(this)
    SetWinTheme(this)
  }

  CountFlatLen(text) {
    flatText := StrReplace(text, "`n", "")
    return StrLen(flatText)
  }

  Destroy() {
    h := this.Hwnd
    c := this.Edit.Value
    super.Destroy()
    if TidyGUI.InstanceHwnd = h
      TidyGUI.InstanceHwnd := 0
  }

  OnEditChange() {
    this.RecalcLength()
  }

  OnTidy() {
    newText := this.Tidy(this.Edit.Value)
    this.Edit.Value := newText
    this.RecalcLength()
  }

  OnTidyCopy() {
    newText := this.Tidy(this.Edit.Value)
    this.Edit.Value := newText
    flatLen := this.RecalcLength()

    if flatLen <= 1000 {
      A_Clipboard := newText
      this.Destroy()
    } else
      ShakeGUI(this)
  }

  RecalcLength() {
    flatLen := this.CountFlatLen(this.Edit.Value)
    this.TextLength.Value := L.TIDY_Length . flatLen
    return flatLen
  }

  Show() {
    if TidyGUI.InstanceHwnd and TidyGUI.InstanceHwnd != this.Hwnd {
      try WinActivate("ahk_id " TidyGUI.InstanceHwnd)
      return
    }

    super.Show("w584 h561 Center")
    this.Edit.Focus()
  }

  Tidy(oldText) {
    newText := RegExReplace(oldText, "(\s*[\r\n]){2,}", "`n`n")
    newText := LTrim(newText, "`n")
    newText := RTrim(newText, "`n")
    return newText
  }
}

class MultiEdit {
  ctrl := ""
  parent := ""
  parentHwnd := ""
  ClassNN := ""
  hotIfFunc := ""
  handler := ""

  /**
   * @param {Gui.Edit} editObj
   */
  __New(editObj) {
    if not IsObject(editObj)
      throw "MultiEdit.__New expects Gui.Edit control"
    this.ctrl := editObj
    this.parent := editObj.Gui
    this.parentHwnd := editObj.Gui.Hwnd
    this.ClassNN := editObj.ClassNN

    this.hotIfFunc := this._HotIfCallback.Bind(this)
    this.handler := this._OnCtrlBS.Bind(this)

    HotIf(this.hotIfFunc)
    Hotkey("^BackSpace", this.handler)
    HotIf()

    try this.ctrl.Gui.OnEvent("Close", this._OnGuiClose.Bind(this))
  }

  _HotIfcallback(*) {
    if not this.parentHwnd or not this.classNN
      return false
    return WinActive("ahk_id " this.parentHwnd) and ControlGetFocus() = this.ctrl.Hwnd
  }

  _OnCtrlBS(*) {
    while GetKeyState("Ctrl", "P") and GetKeyState("Backspace", "P") {
      Send("{Ctrl down}{Shift down}{Left}{Shift up}{Ctrl up}{Backspace}")
      Sleep(100)
    }
  }

  _OnGuiclose(*) {
    this.__Delete()
  }

  __Delete() {
    try {
      HotIf(this.hotIfFunc)
      Hotkey("^Backspace", "Off")
      HotIf()
    }
    try {
      if IsObject(this.parent)
        this.parent.OnEvent("Close", "")
    }

    this.ctrl := ""
    this.parent := ""
    this.parentHwnd := ""
    this.ClassNN := ""
    this.hotIfFunc := ""
    this.handler := ""
  }

  OnEvent(eventName, handler) {
    this.ctrl.OnEvent(eventName, handler)
  }

  Focus() {
    this.ctrl.Focus()
  }

  Value {
    get => this.ctrl.Value
    set => this.ctrl.Value := value
  }
}
