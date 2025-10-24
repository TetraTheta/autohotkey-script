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
    this.AddButton("x266 y141 w75 h33 +Default", L.GUI_OK).OnEvent("Click", (*) => this.OnOK()) ; OK
    this.AddButton("x347 y141 w75 h33", L.GUI_Cancel).OnEvent("Click", (*) => this.OnCancel()) ; Cancel
    this.AddButton("x12 y141 w75 h33", L.GUI_Help).OnEvent("Click", (*) => this.OnHelp()) ; Help

    ; Enable AutoComplete on Edit to use Ctrl+Backspace
    EnableAutoCompleteOnEdit(this.Edit.Hwnd)

    ; GUI event
    this.OnEvent("Close", (*) => this.OnCancel())

    SetWinAttr(this)
    SetWinTheme(this)
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
    MsgBox(L.GAL_Help, L.GUI_Help, 4096)
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
    SendText(BuildGalleryString(this.EditValue, Integer(this.GalNumValue)) "`n`n")
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
    this.AddButton("x266 y141 w75 h33 +Default", L.GUI_OK).OnEvent("Click", (*) => this.OnOK()) ; OK
    this.AddButton("x347 y141 w75 h33", L.GUI_Cancel).OnEvent("Click", (*) => this.OnCancel()) ; Cancel
    this.AddButton("x12 y141 w75 h33", L.GUI_Help).OnEvent("Click", (*) => this.OnHelp()) ; Help

    ; Enable AutoComplete on Edit to use Ctrl+Backspace
    EnableAutoCompleteOnEdit(this.Edit.Hwnd)

    ; GUI event
    this.OnEvent("Close", (*) => this.OnCancel())

    SetWinAttr(this)
    SetWinTheme(this)
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
      this.ImgNumValue := this.isSingle ? 1 :this.ImgNum.Value
      this.Destroy()
    }
  }

  OnCancel() {
    SetTimer(this._OnTickFunc, 0)
    this.DestroyWithoutAction()
  }

  OnHelp() {
    MsgBox(L.IMG_Help, L.GUI_Help, 4096)
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
    A_Clipboard := BuildMDImageString(this.EditValue, Integer(this.ImgNumValue)) "`n`n"
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
    this.AddButton("x266 y191 w75 h33 +Default", L.GUI_OK).OnEvent("Click", (*) => this.OnOK()) ; OK
    this.AddButton("x347 y191 w75 h33", L.GUI_Cancel).OnEvent("Click", (*) => this.OnCancel()) ; Cancel
    this.AddButton("x12 y191 w75 h33", L.GUI_Help).OnEvent("Click", (*) => this.OnHelp()) ; Help

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
    MsgBox(L.GAL_Help, L.GUI_Help, 4096)
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
