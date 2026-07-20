; WARNING
; This script will overwrite existing Gui/Gui.Control classes.
; DO NOT USE WITH OTHER SCRIPT THAT DOES SAME THING OR YOU'LL GET NO ERROR MESSAGE ABOUT THAT

; apply common stuff to all gui controls
class GuiCtl_Ext extends Gui.Control {
  static __New() {
    ; cycle through methods/properties, and add them to super
    for p in this.Prototype.OwnProps()
      (p != "__Class") ? super.Prototype.DefineProp(p, this.Prototype.GetOwnPropDesc(p)) : "" ; don't modify super.__Class property
  }

  Destroy() => DllCall("DestroyWindow", "UPtr", this.Hwnd)

  ExStyle {
    get => ControlGetExStyle(this.Hwnd)
    set => ControlSetExStyle(Value, this.Hwnd)
  }

  Style {
    get => ControlGetStyle(this.Hwnd)
    set => ControlSetStyle(Value, this.Hwnd)
  }
}

class ComboBox_Ext extends Gui.ComboBox {
  static __New() {
    t := this.Prototype, s := super.prototype ; make it shorter
    t.DefineProp("_AutoComplete", { Value: 0 })
    t.DefineProp("_CurCueText", { Value: "" })
    t.DefineProp("CueOption", { Value: 0 })
    for p in t.OwnProps()
      (p != "__Class") ? s.DefineProp(p, t.GetOwnPropDesc(p)) : ""
  }

  AutoComplete {
    get => this._AutoComplete
    set => this.OnEvent("Change", ObjBindMethod(this, "AutoCompCb"), this._AutoComplete := Value)
  }

  CueText {
    get => this._CurCueText
    set => this.SetCueText(Value, this.CueOption)
  }

  Dropped => SendMessage(0x157, 0, 0, this.Hwnd) ; CB_GETDROPPEDSTATE

  FindItem(txt) => SendMessage(0x14C, 0, StrPtr(txt), this.Hwnd) + 1 ; CB_FINDSTRING

  FindItemExact(txt) => SendMessage(0x158, 0, StrPtr(txt), this.Hwnd) + 1 ; CB_FINDSTRINGEXACT

  GetCount() => SendMessage(0x146, 0, 0, this.Hwnd) ; CB_GETCOUNT

  GetItemHeight(row := 1) => SendMessage(0x154, row - 1, 0, this.Hwnd) ; CB_GETITEMHEIGHT

  GetItems() {
    result := []
    loop this.GetCount()
      result.Push(this.GetText(A_Index))
    return result
  }

  GetText(row) {
    buf := Buffer((this.ItemLen(row) + 1) * (StrLen(Chr(0xFFFF)) ? 2 : 1), 0)
    SendMessage(0x148, row - 1, buf.ptr, this.Hwnd) ; 0x148 > CB_GETLBTEXT
    return StrGet(buf)
  }

  Insert(row, txt) => SendMessage(0x14A, row - 1, StrPtr(txt), this.Hwnd) ; CB_INSERTSTRING

  ItemLen(row) => SendMessage(0x149, row - 1, 0, this.Hwnd) ; 0x149 > CB_GETLBTEXTLEN

  ListHeight(items) {
    this.GetPos(, , , &h) ; get edit height, including borders
    h := h + (this.GetItemHeight() * items) + (SysGet(6) * 2) ; edit height + list height + sys metrics
    this.Move(, , , h)
  }

  SelEnd => (this._SelText >> 16) & 0xFFFF

  SelStart => this._SelText & 0xFFFF

  SelText => SubStr(this.Text, this.SelStart + 1, this.SelEnd - this.SelStart)

  SetSel(start := 0, end := 0) => SendMessage(0x142, 0, (end << 16) | start, this.Hwnd) ; 0x142 = CB_SETEDITSEL

  ; thanks to AHK_user and iPhilip for this one: https://www.autohotkey.com/boards/viewtopic.php?p=426941#p426941
  SetCueText(txt := "", opt := false) => SendMessage(0x1703, this.CueOption := opt, StrPtr(this._CurCueText := txt), this.Hwnd) ; CB_SETCUEBANNER

  Show(show := "") => SendMessage(0x14F, (show = "") ? !this.Dropped : show, 0, this.Hwnd) ; CB_SHOWDROPDOWN

  TopIndex {
    get => SendMessage(0x15E, 0, 0, this.Hwnd) ; CB_GETTOPINDEX
    set => SendMessage(0x15C, Value - 1, 0) ; CB_SETTOPINDEX
  }

  ; ======================================================
  ; Internal use only
  ; ======================================================
  _SelText => SendMessage(0x140, 0, 0, this.Hwnd) ; CB_GETEDITSEL

  ; This callback performs the Auto-Complete
  AutoCompCb(ctl, info) {
    if this.AutoComplete && match := this.GetText(this.FindItem(ctl.Text)) { ; if enabled and match is found, continue
      len := StrLen(ctl.Text) ; record length before replacing text with match value
      ctl.Text := match     ; set text to match value
      ctl.SetSel(len, 0xFFFF)  ; set selection to continue expected behavior
    }
  }
}

class Edit_Ext extends Gui.Edit {
  static __New() {
    t := this.Prototype, s := super.prototype ; make it shorter
    t.DefineProp("_CurCueText", { Value: "" })
    t.DefineProp("CueOption", { Value: 0 })

    for _p in t.OwnProps()
      (_p != "__Class") ? s.DefineProp(_p, t.GetOwnPropDesc(_p)) : ""
  }

  Append(txt, top := false) {
    !top ? this.GoEnd() : this.GoStart() ; go to beginning or end of edit
    this.ReplaceSel(txt, false) ; append text
  }

  CueText {
    get => this._CurCueText
    set => this.SetCueText(Value, this.CueOption)
  }

  GoEnd() => this.SetSel(this.Length, this.Length)

  GoStart() => this.SetSel()

  GoSelEnd() => this.SetSel(-1, 0)

  GoSelStart() => this.SetSel(this.SelStart, this.SelStart)

  Length => SendMessage(0x000E, 0, 0, , this.Hwnd) ; WM_GETTEXTLENGTH

  ReplaceSel(txt := "", undo := true) => SendMessage(0x00C2, undo, StrPtr(txt), , this.Hwnd) ; EM_REPLACESEL (or insert at cursor)

  SelEnd => (this._SelText >> 16) & 0xFFFF

  SelStart => this._SelText & 0xFFFF

  SelText => SubStr(this.Text, this.SelStart + 1, this.SelEnd - this.SelStart)

  SetCueText(txt, opt := false) => ; thanks to AHK_user and iPhilip for this one ; Link: https://www.autohotkey.com/boards/viewtopic.php?p=426941#p426941
    SendMessage(0x1501, this.CueOption := opt, StrPtr(this._CurCueText := txt), this.Hwnd) ; opt = 1 > show cue even when control has focus

  SetSel(start := 0, end := 0) => SendMessage(0xB1, start, end, this.Hwnd) ; 0xB1 = EM_SETSEL

  ; ======================================================
  ; Internal use only
  ; ======================================================

  _SelText => SendMessage(0xB0, 0, 0, this.Hwnd) ; 0xB0 > EM_GETSEL
}

class ListBox_Ext extends Gui.ListBox {
  static __New() {
    for p in this.Prototype.OwnProps()
      (p != "__Class") ? super.Prototype.DefineProp(p, this.Prototype.GetOwnPropDesc(p)) : ""
  }

  GetCount() => (SendMessage(0x018B, 0, 0, this.Hwnd)) ; LB_GETCOUNT

  GetText(row) {
    buf := Buffer((this.ItemLen(row) + 1) * (StrLen(Chr(0xFFFF)) ? 2 : 1), 0)
    SendMessage(0x189, row - 1, buf.ptr, this.Hwnd) ; 0x189 > LB_GETTEXT
    return StrGet(buf)
  }

  GetItems() {
    result := []
    Loop this.GetCount()
      result.Push(this.GetText(A_Index))
    return result
  }

  Insert(row, txt) => SendMessage(0x181, row - 1, StrPtr(txt), this.Hwnd) ; LB_INSERTSTRING

  ItemLen(row) => SendMessage(0x18A, row - 1, 0, this.Hwnd) ; 0x18A > LB_GETTEXTLEN

  SelAll(sel := true) => SendMessage(0x185, sel, -1, this.Hwnd) ; LB_SETSEL

  SelRange(start, end, sel := true) => SendMessage(0x19B, sel, ((end - 1) << 16) | (start - 1), this.Hwnd) ; LB_SELITEMRANGE

  TopIndex {
    get => SendMessage(0x18E, 0, 0, this.Hwnd) ; LB_GETTOPINDEX
    set => SendMessage(0x197, Value - 1, 0, this.Hwnd) ; LB_SETTOPINDEX
  }
}

class ListView_Ext extends Gui.ListView {
  static __New() {
    for p in this.Prototype.OwnProps()
      (p != "__Class") ? super.Prototype.DefineProp(p, this.Prototype.GetOwnPropDesc(p)) : ""
  }

  Checked(row) => ; This was taken directly from the AutoHotkey help files.
    (SendMessage(4140, row - 1, 0xF000, , this.Hwnd) >> 12) - 1 ; VM_GETITEMSTATE = 4140 / LVIS_STATEIMAGEMASK = 0xF000

  IconIndex(row, col := 1) { ; from "just me" LV_EX ; Link: https://www.autohotkey.com/boards/viewtopic.php?f=76&t=69262&p=298308#p299057
    LVITEM := Buffer((A_PtrSize = 8) ? 56 : 40, 0)           ; create variable/structure
    NumPut("UInt", 0x2, "Int", row - 1, "Int", col - 1, LVITEM.ptr, 0)  ; LVif_IMAGE := 0x2 / iItem (row) / column num
    NumPut("Int", 0, LVITEM.ptr, (A_PtrSize = 8) ? 36 : 28)         ; iImage
    SendMessage(StrLen(Chr(0xFFFF)) ? 0x104B : 0x1005, 0, LVITEM.ptr, , "ahk_id " this.Hwnd) ; LVM_GETITEMA/W := 0x1005 / 0x104B
    return NumGet(LVITEM.ptr, (A_PtrSize = 8) ? 36 : 28, "Int") + 1 ;iImage
  }

  GetColWidth(n) => SendMessage(0x101D, n - 1, 0, this.Hwnd)
}

class PicButton extends Gui.Button {
  static __New() {
    Gui.Prototype.AddPicButton := this.AddPicButton
  }

  static AddPicButton(sOptions := "", sPicFile := "", sPicFileOpt := "", txt := "") {
    ctl := this.Add("Button", sOptions, txt)
    ctl.base := PicButton.Prototype
    if sPicFile
      ctl.SetImg(sPicFile, sPicFileOpt)
    return ctl
  }

  SetImg(sFile, sOptions := "") {   ; input params exact same as first 2 params of LoadPicture()
    static ImgType := 0     ; thanks to teadrinker: https://www.autohotkey.com/boards/viewtopic.php?p=299834#p299834
      , BS_ICON := 0x40, BS_BITMAP := 0x80, BM_SETIMAGE := 0xF7

    hImg := LoadPicture(sFile, sOptions, &_type)
    if !this.Text ; thanks to "just me" for advice on getting text and images to display
      ControlSetStyle((ControlGetStyle(this.Hwnd) | (!_type ? BS_BITMAP : BS_ICON)), this.Hwnd)
    hOldImg := SendMessage(BM_SETIMAGE, _type, hImg, this.Hwnd)

    (hOldImg && ImgType) ? DllCall("DestroyIcon", "UPtr", hOldImg) : DllCall("DeleteObject", "UPtr", hOldImg)
    ImgType := _type ; store current img type for next call/release
  }

  Type => "PicButton"
}

class SplitButton extends Gui.Button {
  static __New() {
    Gui.Prototype.AddSplitButton := this.AddSplitButton
  }

  static AddSplitButton(sOptions := "", sText := "", callback := "") {
    static BS_SPLITBUTTON := 0xC

    ctl := this.Add("Button", sOptions, sText)
    ctl.base := SplitButton.Prototype

    ControlSetStyle (ControlGetStyle(ctl.hwnd) | BS_SPLITBUTTON), ctl.hwnd
    if callback
      ctl.callback := callback
        , ctl.OnNotify(-1248, ObjBindMethod(ctl, "DropCallback"))

    return ctl
  }

  Drop() => this.DropCallback(this, 0)

  DropCallback(ctl, lParam) {
    ctl.GetPos(&x, &y, , &h)
    f := this.callback, f(ctl, { x: x, y: y + h })
  }

  SetImg(sFile, sOptions := "") { ; input params exact same as first 2 params of LoadPicture()
    static ImgType := 0     ; thanks to teadrinker: https://www.autohotkey.com/boards/viewtopic.php?p=299834#p299834
    static BS_ICON := 0x40, BS_BITMAP := 0x80, BM_SETIMAGE := 0xF7

    hImg := LoadPicture(sFile, sOptions, &_type)
    if !this.Text ; thanks to "just me" for advice on getting text and images to display
      ControlSetStyle (ControlGetStyle(this.Hwnd) | (!_type ? BS_BITMAP : BS_ICON)), this.Hwnd
    hOldImg := SendMessage(BM_SETIMAGE, _type, hImg, this.Hwnd)

    (hOldImg && ImgType) ? DllCall("DestroyIcon", "UPtr", hOldImg) : DllCall("DeleteObject", "UPtr", hOldImg)
    ImgType := _type ; store current img type for next call/release
  }

  Type => "SplitButton"
}

class StatusBar_Ext extends Gui.StatusBar {
  static __New() {
    for p in this.Prototype.OwnProps()
      (p != "__Class") ? super.Prototype.DefineProp(p, this.Prototype.GetOwnPropDesc(p)) : ""
  }

  RemoveIcon(part := 1) {
    if (hIcon := SendMessage(0x414, part - 1, 0, this.Hwnd))
      SendMessage(0x40F, part - 1, 0, this.Hwnd)
    return DllCall("DestroyIcon", "UPtr", hIcon)
  }
}

; TCif_IMAGE := 0x2
; TCif_PARAM := 0x8
; TCif_RTLREADING := 0x4
; TCif_STATE := 0x10
; TCif_TEXT := 0x1

; typedef struct tagTCITEMA { x86 / x64
; UINT   mask;      ;  0 /  0
; DWORD  dwState;     ;  4 /  4
; DWORD  dwStateMask;   ;  8 /  8
; LPSTR  pszText;     ;   12 / 16
; int  cchTextMax;    ;   16 / 24
; int  iImage;      ;   20 / 28
; LPARAM lParam;      ;   24 / 32
; } TCITEMA, *LPTCITEMA; size = 28 / 40

class Tab_Ext extends Gui.Tab {
  static __New() {
    for p in this.Prototype.OwnProps()
      (p != "__Class") ? super.Prototype.DefineProp(p, this.Prototype.GetOwnPropDesc(p)) : ""
    ; super.Prototype.DefineProp("a",{Value:(A_PtrSize=8)})     ; architecture check
    super.Prototype.DefineProp("u", { Value: StrLen(Chr(0xFFFF)) }) ; unicode check
  }

  GetCount() => SendMessage(0x1304, 0, 0, this.Hwnd) ; TCM_GETITEMCOUNT

  GetIcon(tab_num) => this._GetItem(tab_num - 1).Icon + 1 ; gets icon index in ImgList

  GetItems() { ; returns array of tab names
    o := []
    Loop this.GetCount()
      o.Push(this.GetName(A_Index))
    return o
  }

  GetName(tab_num, bSize := 128) => StrGet(this._GetItem(tab_num - 1, bSize).pszText)

  Insert(pos, name := "", icon := "") { ; TCM_INSERTITEM := 0x133E / TCM_INSERTITEMA := 0x1307
    TCITEM := Tab_Ext.TCITEM(), TCITEM.mask := 0x3 ; TCif_TEXT | TCif_IMAGE := 0x3
    TCITEM.pszText := StrPtr(name), TCITEM.Icon := icon - 1
    SendMessage(this.u ? 0x133E : 0x1307, pos - 1, TCITEM.ptr, this.Hwnd)
  }

  RowCount => SendMessage(0x132C, 0, 0, this.Hwnd) ; TCM_GETROWCOUNT

  SetIcon(tab_num, icon := 0) {
    TCITEM := Tab_Ext.TCITEM(), TCITEM.mask := 2 ; TCif_IMAGE:=2
    TCITEM.Icon := icon - 1, this._SetItem(tab_num - 1, TCITEM)
  }

  SetImageList(hList) => SendMessage(0x1303, 0, hList, this.Hwnd) ; TCM_SETIMAGELIST

  SetName(tab_num, name := "") {
    if (StrLen(name) > 127) ; not ideal, but seems to be necessary
      throw Error("Tab name too long.", -1)
    TCITEM := Tab_Ext.TCITEM(), TCITEM.mask := 1, TCITEM.pszText := StrPtr(name) ; TCif_TEXT:=1
    this._SetItem(tab_num - 1, TCITEM)
  }

  ; ======================================================
  ; Internal use only
  ; ======================================================

  _GetItem(i, bSize := 128) { ; TCM_GETITEM := 0x133C / TCM_GETITEMA := 0x1305
    if i >= this.GetCount()
      throw Error("Invalid tab specified.`n`nSpecified: " (i + 1), -1, "Max tabs: " this.GetCount())
    TCITEM := Tab_Ext.TCITEM(, bSize), TCITEM.mask := 0x3 ; get text and icon index
    return SendMessage(this.u ? 0x133C : 0x1305, i, TCITEM.ptr, this.Hwnd) ? TCITEM : ""
  }

  _SetItem(i, TCITEM) { ; TCM_SETITEM := 0x133D / TCM_SETITEMA := 0x1306
    SendMessage(this.u ? 0x133D : 0x1306, i, TCITEM.ptr, this.Hwnd)
    this.Redraw() ; this is needed, otherwise controls sometimes disappear
  }

  class TCITEM { ; props: dwState, dwStateMask, pszText, cchTextMax, iImage, lParam
    __New(ptr := 0, bSize := 128) {
      static a := (A_PtrSize = 8)
        , obj := { mask: { o: 0, t: "UInt" }
          , dwState: { o: 4, t: "UInt" }
          , dwStateMask: { o: 8, t: "UInt" }
          , pszText: { o: (!a ? 12 : 16), t: "UPtr" }
          , cchTextMax: { o: (!a ? 16 : 24), t: "Int" }
          , Icon: { o: (!a ? 20 : 28), t: "Int" }
          , lParam: { o: (!a ? 24 : 32), t: "UPtr" } }

      buf := (ptr ? { ptr: ptr } : Buffer((!a ? 28 : 40), 0)), this.DefineProp("buf", { Value: buf }) ; init struct buffer
      this.DefineProp("f", { Value: obj }) ; fields
      this.DefineProp("ptr", { Value: this.buf.ptr })
      textBuf := Buffer(bSize, 0), this.DefineProp("textBuf", { Value: textBuf }) ; init pszText buffer
      this.cchTextMax := bSize, this.pszText := textBuf.ptr
    }
    __Get(n, p) => NumGet(this.ptr, this.f.%n%.o, this.f.%n%.t)
    __Set(n, p, Value) => NumPut(this.f.%n%.t, Value, this.ptr, this.f.%n%.o)
    __Delete() => (this.textBuf := "") ; clean up text buffer, avoid memory leak
  }
}

class ToggleButton extends Gui.Checkbox {
  static __New() {
    for p in this.Prototype.OwnProps()
      (p != "__Class") ? super.Prototype.DefineProp(p, this.Prototype.GetOwnPropDesc(p)) : ""
    Gui.Prototype.AddToggleButton := this.AddToggleButton
  }

  static AddToggleButton(sOptions := "", sText := "") {
    ctl := this.Add("Checkbox", sOptions " +0x1000", sText)
    ctl.base := ToggleButton.Prototype
    return ctl
  }

  Type => "ToggleButton"
}

; ==================================================================
; Gui_Ext
; ==================================================================
class Gui_Ext extends Gui {
  static __New() {
    Gui.Prototype := this.Prototype
  }


  ; SendMsg 2nd param, 1 means ICON_BIG (vs. 0 for ICON_SMALL).
  /**
   * Sets the icon for the dialog.
   * @param {String} FileName
   * @param {Integer} Icon
   * @returns {Integer}
   */
  SetIcon(FileName := "shell32.dll", Icon := 1) => SendMessage(0x0080, 0, LoadPicture(FileName, "Icon" Icon " w" 32 " h" 32, &imgtype), this.Hwnd) ; 0x0080 is WM_SETICON

  Type => "Gui"
}
