#Include "..\Lib\darkMode.ahk"
#Include "..\Lib\extension.ahk"
#Include "app_context.ahk"
#Include "helpers.ahk"

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
  try {
    A_Clipboard := ""
    Sleep(10)
    Send("^c")
    if ClipWait(0.35) {
      sel := A_Clipboard
      return sel
    }
  } finally {
    try A_Clipboard := prevClip
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
  hwnd := targetGui.Hwnd
  if !hwnd
    return

  SWP_NOSIZE := 0x0001
  SWP_NOZORDER := 0x0004
  SWP_NOACTIVATE := 0x0010
  SWP_FLAGS := SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE

  oriX := 0, oriY := 0
  WinGetPos(&oriX, &oriY, , , "ahk_id " hwnd)
  loop iShakeCount {
    rx := Random(oriX - iRattleX, oriX + iRattleX)
    ry := Random(oriY - iRattleY, oriY + iRattleY)
    DllCall("SetWindowPos", "ptr", hwnd, "ptr", 0, "int", rx, "int", ry, "int", 0, "int", 0, "uint", SWP_FLAGS)
    Sleep(5)
  }
  DllCall("SetWindowPos", "ptr", hwnd, "ptr", 0, "int", oriX, "int", oriY, "int", 0, "int", 0, "uint", SWP_FLAGS)
}

; ###############
; #    CLASS    #
; ###############

class TimedModalGui extends Gui {
  _OnTickFunc := this.OnTick.Bind(this)
  OkPressed := false
  Timer := ""
  TimeLeft := 0

  __New(title) {
    existingHwnd := this.GetInstanceHwnd()
    if existingHwnd {
      try WinActivate("ahk_id " existingHwnd)
      return existingHwnd
    }
    super.__New(, title)
    this.SetInstanceHwnd(this.Hwnd)
  }

  Destroy() {
    SetTimer(this._OnTickFunc, 0)
    h := this.Hwnd
    super.Destroy()
    if this.GetInstanceHwnd() = h
      this.SetInstanceHwnd(0)
    if this.OkPressed
      this.OnConfirm()
  }

  DestroyWithoutAction() {
    this.OkPressed := false
    this.Destroy()
  }

  ConfirmAndClose() {
    SetTimer(this._OnTickFunc, 0)
    this.OkPressed := true
    this.Destroy()
  }

  CancelAndClose() {
    SetTimer(this._OnTickFunc, 0)
    this.DestroyWithoutAction()
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

  ShowAndHideAfter(seconds, showOpt := "") {
    existingHwnd := this.GetInstanceHwnd()
    if existingHwnd and existingHwnd != this.Hwnd {
      try WinActivate("ahk_id " existingHwnd)
      return
    }

    this.TimeLeft := seconds
    this.UpdateTimerText()
    super.Show(showOpt)
    this.FocusPrimary()
    SetTimer(this._OnTickFunc, 1000)
  }

  UpdateTimerText() {
    if IsObject(this.Timer)
      this.Timer.Text := Format("{:02}", this.TimeLeft)
  }

  ; virtual methods
  OnConfirm() {
  }

  FocusPrimary() {
  }

  GetInstanceHwnd() {
    return 0
  }

  SetInstanceHwnd(hwnd) {
  }
}

class GalleryGUI extends TimedModalGui {
  static InstanceHwnd := 0 ; Track if there is already an existing Window
  ctx := ''
  EditValue := ""
  GalNumValue := ""

  __New(ctx, imageNum := 3) {
    this.ctx := ctx

    ; Set GUI icon (hack)
    /*@Ahk2Exe-Keep
    TraySetIcon("HICON:" GetEmbeddedIcon(214, 32))
    */
    ;@Ahk2Exe-IgnoreBegin
    TraySetIcon("icon\gallery.ico")
    ;@Ahk2Exe-IgnoreEnd
    super.__New(this.ctx.L.GAL_Title)
    /*@Ahk2Exe-Keep
    TraySetIcon("*")
    */
    ;@Ahk2Exe-IgnoreBegin
    TraySetIcon("icon\main.ico")
    ;@Ahk2Exe-IgnoreEnd

    ; Save HWND
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
    this.Timer := this.AddText("x22 y51 w25 h22", Format("{:02}", this.ctx.C.TimeoutGallery)) ; Timer
    this.AddText("x50 y12 w372 h32", this.ctx.L.GAL_Message . imageNum) ; Message
    this.AddText("x12 y73 w410 h22", this.ctx.L.GAL_LabelEdit) ; Label Edit
    this.Edit := this.AddEdit("x12 y98 w364 h25 -Multi") ; Edit
    this.GalNum := this.AddDDL("x382 y98 w40 h25 vGalNum Choose" imageNum " R3", ["1", "2", "3"]) ; Gallery Number
    this.AddButton("x266 y141 w75 h33 +Default", this.ctx.L.BTN_OK).OnEvent("Click", (*) => this.OnOK()) ; OK
    this.AddButton("x347 y141 w75 h33", this.ctx.L.BTN_Cancel).OnEvent("Click", (*) => this.OnCancel()) ; Cancel
    this.AddButton("x12 y141 w75 h33", this.ctx.L.BTN_Help).OnEvent("Click", (*) => this.OnHelp()) ; Help

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

  OnOK() {
    if this.Edit.Value = "" {
      ShakeGUI(this)
    } else {
      this.EditValue := this.Edit.Value
      this.GalNumValue := this.GalNum.Text
      this.ConfirmAndClose()
    }
  }

  OnCancel() {
    this.CancelAndClose()
  }

  OnHelp() {
    MsgBox(this.ctx.L.GAL_Help, this.ctx.L.BTN_Help, 4096)
  }

  OnConfirm() {
    SendText(this.BuildGalleryString(this.EditValue, Integer(this.GalNumValue)) "`n`n")
  }

  FocusPrimary() {
    this.Edit.Focus()
  }

  ShowAndHideAfter(seconds) {
    super.ShowAndHideAfter(seconds, "w434 h186 Center")
  }

  GetInstanceHwnd() {
    return GalleryGUI.InstanceHwnd
  }

  SetInstanceHwnd(hwnd) {
    GalleryGUI.InstanceHwnd := hwnd
  }
}

class ImageGUI extends TimedModalGui {
  static InstanceHwnd := 0 ; Track if there is already an existing Window
  ctx := ''
  isSingle := false
  EditValue := ""
  ImgNumValue := ""

  __New(ctx, isSingle := false) {
    this.ctx := ctx
    this.isSingle := isSingle

    ; Set GUI icon (hack)
    /*@Ahk2Exe-Keep
    TraySetIcon("HICON:" GetEmbeddedIcon(215, 32))
    */
    ;@Ahk2Exe-IgnoreBegin
    TraySetIcon("icon\image.ico")
    ;@Ahk2Exe-IgnoreEnd
    super.__New(this.ctx.L.IMG_Title)
    /*@Ahk2Exe-Keep
    TraySetIcon("*")
    */
    ;@Ahk2Exe-IgnoreBegin
    TraySetIcon("icon\main.ico")
    ;@Ahk2Exe-IgnoreEnd

    ; Save HWND
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
    this.Timer := this.AddText("x22 y51 w25 h22", Format("{:02}", this.ctx.C.TimeoutImage)) ; Timer
    this.AddText("x50 y12 w372 h32", isSingle ? this.ctx.L.IMG_MessageSingle : this.ctx.L.IMG_MessageMulti) ; Message
    this.AddText("x12 y73 w410 h22", isSingle ? this.ctx.L.IMG_LabelSingle : this.ctx.L.IMG_LabelMulti) ; Label Edit
    if isSingle {
      this.Edit := this.AddEdit("x12 y98 w410 h25 -Multi") ; Edit (Text)
    } else {
      this.Edit := this.AddEdit("x12 y98 w324 h25 -Multi") ; Edit (Text)
      this.ImgNum := this.AddEdit("x342 y98 w80 h25") ; Image Number
      this.AddUpDown("Range1-65535")
      this.ImgNum.OnEvent("Change", (*) => this.SanitizeImgNumInput())
      this.ImgNum.Value := "1"
    }
    this.AddButton("x266 y141 w75 h33 +Default", this.ctx.L.BTN_OK).OnEvent("Click", (*) => this.OnOK()) ; OK
    this.AddButton("x347 y141 w75 h33", this.ctx.L.BTN_Cancel).OnEvent("Click", (*) => this.OnCancel()) ; Cancel
    this.AddButton("x12 y141 w75 h33", this.ctx.L.BTN_Help).OnEvent("Click", (*) => this.OnHelp()) ; Help

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

  OnOK() {
    if this.Edit.Value = "" {
      ShakeGUI(this)
    } else {
      if !this.isSingle
        this.SanitizeImgNumInput()
      this.EditValue := this.Edit.Value
      this.ImgNumValue := this.isSingle ? 1 : this.ImgNum.Value
      this.ConfirmAndClose()
    }
  }

  OnCancel() {
    this.CancelAndClose()
  }

  SanitizeImgNumInput() {
    if this.isSingle || !IsObject(this.ImgNum)
      return
    raw := this.ImgNum.Value . ""
    digits := RegExReplace(raw, "\D")
    if digits = ""
      normalized := "1"
    else {
      digits := RegExReplace(digits, "^0+(?=\d)", "")
      valueNum := Integer(digits)
      if valueNum < 1
        valueNum := 1
      if valueNum > 65535
        valueNum := 65535
      normalized := valueNum . ""
    }
    if this.ImgNum.Value != normalized
      this.ImgNum.Value := normalized
  }

  OnHelp() {
    MsgBox(this.ctx.L.IMG_Help, this.ctx.L.BTN_Help, 4096)
  }

  OnConfirm() {
    ; SendText() lags, so use clipboard instead
    prevClip := ClipboardAll()
    A_Clipboard := this.BuildMDImageString(this.EditValue, Integer(this.ImgNumValue)) "`n`n"
    Sleep(10)
    Send("^v")
    Sleep(10)
    A_Clipboard := prevClip
  }

  FocusPrimary() {
    this.Edit.Focus()
  }

  ShowAndHideAfter(seconds) {
    super.ShowAndHideAfter(seconds, "w434 h186 Center")
  }

  GetInstanceHwnd() {
    return ImageGUI.InstanceHwnd
  }

  SetInstanceHwnd(hwnd) {
    ImageGUI.InstanceHwnd := hwnd
  }
}

class NewGUI extends TimedModalGui {
  static InstanceHwnd := 0 ; Track if there is already an existing Window
  ctx := ''
  CategoryValue := ""
  NewTitleValue := ""

  __New(ctx) {
    this.ctx := ctx

    ; Set GUI icon (hack)
    /*@Ahk2Exe-Keep
    TraySetIcon("HICON:" GetEmbeddedIcon(216, 32))
    */
    ;@Ahk2Exe-IgnoreBegin
    TraySetIcon("icon\new.ico")
    ;@Ahk2Exe-IgnoreEnd
    super.__New(this.ctx.L.NEW_Title)
    /*@Ahk2Exe-Keep
    TraySetIcon("*")
    */
    ;@Ahk2Exe-IgnoreBegin
    TraySetIcon("icon\main.ico")
    ;@Ahk2Exe-IgnoreEnd

    ; Save HWND
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
    this.Timer := this.AddText("x22 y51 w25 h22", Format("{:02}", this.ctx.C.TimeoutNew)) ; Timer
    this.AddText("x50 y12 w372 h32", this.ctx.L.NEW_Message) ; Message
    this.AddText("x12 y73 w410 h22", this.ctx.L.NEW_Category) ; Label Category
    this.Category := this.AddDDL("x12 y98 w410 h25 R10", this.ctx.NK) ; DDL Category
    this.AddText("x12 y126 w410 h22", this.ctx.L.NEW_NewTitle) ; Label Title
    this.NewTitle := this.AddComboBox("x12 y151 w410 h25 R5", [this.ctx.C.RecentTitle1.Value, this.ctx.C.RecentTitle2.Value, this.ctx.C.RecentTitle3.Value, this.ctx.C.RecentTitle4.Value, this.ctx.C.RecentTitle5.Value]) ; ComboBox Title
    this.AddButton("x266 y191 w75 h33 +Default", this.ctx.L.BTN_OK).OnEvent("Click", (*) => this.OnOK()) ; OK
    this.AddButton("x347 y191 w75 h33", this.ctx.L.BTN_Cancel).OnEvent("Click", (*) => this.OnCancel()) ; Cancel
    this.AddButton("x12 y191 w75 h33", this.ctx.L.BTN_Help).OnEvent("Click", (*) => this.OnHelp()) ; Help

    ; Choose last selected Category (supports either index or text)
    recentCategory := this.ctx.C.RecentCategory.Value
    if recentCategory != "" {
      recentCategory := recentCategory . ""
      if RegExMatch(recentCategory, "^\d+$") {
        idx := Integer(recentCategory)
        if idx >= 1 and idx <= this.ctx.NK.Length
          this.Category.Choose(idx)
      } else {
        for idx, name in this.ctx.NK {
          if name = recentCategory {
            this.Category.Choose(idx)
            break
          }
        }
      }
    }

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
    cliCommand := GetCLIBaseCommand(this.ctx)
    if this.CategoryValue = "" || !this.ctx.N.Has(this.CategoryValue) {
      MsgBox(this.ctx.L.NEW_Category " is invalid.", this.ctx.L.NEW_Title, 4096)
      return
    }

    cliTokens := ParseWindowsCommandLine(cliCommand)
    if cliTokens.Length = 0 {
      MsgBox("CLI Command is invalid.", this.ctx.L.NEW_Title, 4096)
      return
    }

    kind := this.ctx.N[this.CategoryValue]
    title := this.NewTitleValue
    cliTokens.Push("new")
    cliTokens.Push("-k")
    cliTokens.Push(kind)
    cliTokens.Push(title)

    psBody := BuildSafePSCommand(cliTokens)
    args := BuildPowerShellRunArgs(psBody, this.ctx.C.KeepConsoleOpen)
    Run(args, this.ctx.C.ProjectRootDir)
  }

  OnOK() {
    titleText := Trim(this.NewTitle.Text)
    if titleText = "" {
      ShakeGUI(this)
    } else {
      this.CategoryValue := Trim(this.Category.Text)
      this.NewTitleValue := titleText

      if this.CategoryValue = "" || !this.ctx.N.Has(this.CategoryValue) {
        this.OkPressed := false
        MsgBox(this.ctx.L.NEW_Category " is invalid.", this.ctx.L.NEW_Title, 4096)
        ShakeGUI(this)
        return
      }

      ; Modify Config
      if this.CategoryValue != this.ctx.C.RecentCategory.Value
        this.ctx.C.RecentCategory.Value := this.CategoryValue
      if this.NewTitleValue != this.ctx.C.RecentTitle1.Value {
        this.ctx.C.RecentTitle5.Value := this.ctx.C.RecentTitle4.Value
        this.ctx.C.RecentTitle4.Value := this.ctx.C.RecentTitle3.Value
        this.ctx.C.RecentTitle3.Value := this.ctx.C.RecentTitle2.Value
        this.ctx.C.RecentTitle2.Value := this.ctx.C.RecentTitle1.Value
        this.ctx.C.RecentTitle1.Value := this.NewTitleValue
      }

      this.ConfirmAndClose()
    }
  }

  OnCancel() {
    this.CancelAndClose()
  }

  OnHelp() {
    MsgBox(this.ctx.L.NEW_Help, this.ctx.L.BTN_Help, 4096)
  }

  FocusPrimary() {
    this.NewTitle.Focus()
  }

  OnConfirm() {
    this.CreateNewContent()
  }

  ShowAndHideAfter(seconds) {
    super.ShowAndHideAfter(seconds, "w434 h236 Center")
  }

  GetInstanceHwnd() {
    return NewGUI.InstanceHwnd
  }

  SetInstanceHwnd(hwnd) {
    NewGUI.InstanceHwnd := hwnd
  }
}

class TidyGUI extends Gui {
  static InstanceHwnd := 0 ; Track if there is already an existing Window
  ctx := ''

  __New(ctx) {
    if TidyGUI.InstanceHwnd {
      try WinActivate("ahk_id " TidyGUI.InstanceHwnd)
      return TidyGUI.InstanceHwnd
    }

    this.ctx := ctx

    ; Set GUI icon (hack)
    /*@Ahk2Exe-Keep
    TraySetIcon("HICON:" GetEmbeddedIcon(210, 32))
    */
    ;@Ahk2Exe-IgnoreBegin
    TraySetIcon("icon\document.ico")
    ;@Ahk2Exe-IgnoreEnd
    super.__New(, this.ctx.L.TIDY_Title)
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
    this.TextLength := this.AddText("x12 y491 w560 h22", this.ctx.L.TIDY_Length . StrLen(sel))
    this.AddButton("x12 y516 w277 h33", this.ctx.L.BTN_Tidy).OnEvent("Click", (*) => this.OnTidy()) ; Tidy
    this.AddButton("x295 y516 w277 h33", this.ctx.L.BTN_TidyCopy).OnEvent("Click", (*) => this.OnTidyCopy()) ; Tidy & Copy

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
    this.TextLength.Value := this.ctx.L.TIDY_Length . flatLen
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

  _HotIfCallback(*) {
    if not this.parentHwnd or not this.ClassNN
      return false
    focused := ControlGetFocus("A")
    if focused = ""
      return false
    try focusedHwnd := ControlGetHwnd(focused, "A")
    catch
      return false
    return WinActive("ahk_id " this.parentHwnd) and focusedHwnd = this.ctrl.Hwnd
  }

  _OnCtrlBS(*) {
    while GetKeyState("Ctrl", "P") and GetKeyState("Backspace", "P") {
      Send("{Ctrl down}{Shift down}{Left}{Shift up}{Ctrl up}{Backspace}")
      Sleep(100)
    }
  }

  _OnGuiClose(*) {
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
