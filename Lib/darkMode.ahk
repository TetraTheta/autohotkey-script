/*
SetMenuAttr(MenuObj)
Set context menu to dark mode
SetWinAttr(GuiObj)
Set GUI object to dark mode
SetWinTheme(GuiObj)
Set window to dark mode
*/
; Source: https://www.autohotkey.com/boards/viewtopic.php?t=115952
DarkColors := Map("Background", "0x202020", "Controls", "0x404040", "Font", "0xE0E0E0")
TextBGBrush := DllCall("gdi32\CreateSolidBrush", "UInt", DarkColors["Background"], "Ptr")
SetMenuAttr(MenuObj) {
  global DarkColors
  if (VerCompare(A_OSVersion, "10.0.17763") >= 0) {
    DWMWA_USE_IMMERSIVE_DARK_MODE := 19
    if (VerCompare(A_OSVersion, "10.0.18985") >= 0) {
      DWMWA_USE_IMMERSIVE_DARK_MODE := 20
    }
    uxtheme := DllCall("kernel32\GetModuleHandle", "Str", "uxtheme", "Ptr")
    SetPreferredAppMode := DllCall("kernel32\GetProcAddress", "Ptr", uxtheme, "Ptr", 135, "Ptr")
    FlushMenuThemes := DllCall("kernel32\GetProcAddress", "Ptr", uxtheme, "Ptr", 136, "Ptr")

    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", A_ScriptHwnd, "Int", DWMWA_USE_IMMERSIVE_DARK_MODE, "Int*", True, "Int", 4)
    DllCall(SetPreferredAppMode, "Int", 2) ; 0=Default, 1=AllowDark, 2=ForceDark, 3=ForceLight, 4=Max
    DllCall(FlushMenuThemes)
  }
}
SetWinAttr(GuiObj) {
  global DarkColors
  if (VerCompare(A_OSVersion, "10.0.17763") >= 0) {
    DWMWA_USE_IMMERSIVE_DARK_MODE := 19
    if (VerCompare(A_OSVersion, "10.0.18985") >= 0) {
      DWMWA_USE_IMMERSIVE_DARK_MODE := 20
    }
    uxtheme := DllCall("kernel32\GetModuleHandle", "Str", "uxtheme", "Ptr")
    SetPreferredAppMode := DllCall("kernel32\GetProcAddress", "Ptr", uxtheme, "Ptr", 135, "Ptr")
    FlushMenuThemes := DllCall("kernel32\GetProcAddress", "Ptr", uxtheme, "Ptr", 136, "Ptr")

    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", GuiObj.Hwnd, "Int", DWMWA_USE_IMMERSIVE_DARK_MODE, "Int*", True, "Int", 4)
    DllCall(SetPreferredAppMode, "Int", 2) ; 0=Default, 1=AllowDark, 2=ForceDark, 3=ForceLight, 4=Max
    DllCall(FlushMenuThemes)
    GuiObj.BackColor := DarkColors["Background"]
  }
}
SetWinTheme(GuiObj) {
  static GWL_WNDPROC := -4
  static GWL_STYLE := -16
  static ES_MULTILINE := 0x0004
  static LVM_GETTEXTCOLOR := 0x1023
  static LVM_SETTEXTCOLOR := 0x1024
  static LVM_GETTEXTBKCOLOR := 0x1025
  static LVM_SETTEXTBKCOLOR := 0x1026
  static LVM_GETBKCOLOR := 0x1000
  static LVM_SETBKCOLOR := 0x1001
  static LVM_GETHEADER := 0x101F
  static GetWindowLong := A_PtrSize = 8 ? "GetWindowLongPtr" : "GetWindowLong"
  static SetWindowLong := A_PtrSize = 8 ? "SetWindowLongPtr" : "SetWindowLong"
  Init := False
  LV_Init := False

  Mode_Explorer := "DarkMode_Explorer"
  Mode_CFD := "DarkMode_CFD"
  Mode_ItemsView := "DarkMode_ItemsView"

  for hWnd, GuiCtrlObj in GuiObj {
    switch GuiCtrlObj.Type {
      case "Button", "CheckBox", "ListBox", "UpDown", "Text":
      {
        DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_Explorer, "Ptr", 0)
      }
      case "ComboBox", "DDL":
      {
        DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_CFD, "Ptr", 0)
      }
      case "Edit":
      {
        if (DllCall("user32\" . GetWindowLong, "Ptr", GuiCtrlObj.hWnd, "Int", GWL_STYLE) & ES_MULTILINE) {
          DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_Explorer, "Ptr", 0)
        } else {
          DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_CFD, "Ptr", 0)
        }
      }
      case "ListView":
      {
        if !(LV_Init) {
          static LV_TEXTCOLOR := SendMessage(LVM_GETTEXTCOLOR, 0, 0, GuiCtrlObj.hWnd)
          static LV_TEXTBKCOLOR := SendMessage(LVM_GETTEXTBKCOLOR, 0, 0, GuiCtrlObj.hWnd)
          static LV_BKCOLOR := SendMessage(LVM_GETBKCOLOR, 0, 0, GuiCtrlObj.hWnd)
          LV_Init := True
        }
        GuiCtrlObj.Opt("-Redraw")
        SendMessage(LVM_SETTEXTCOLOR, 0, DarkColors["Font"], GuiCtrlObj.hWnd)
        SendMessage(LVM_SETTEXTBKCOLOR, 0, DarkColors["Background"], GuiCtrlObj.hWnd)
        SendMessage(LVM_SETBKCOLOR, 0, DarkColors["Background"], GuiCtrlObj.hWnd)
        DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_Explorer, "Ptr", 0)
        ; To color the selection - scrollbar turns back to normal
        ;DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_ItemsView, "Ptr", 0)
        LV_Header := SendMessage(LVM_GETHEADER, 0, 0, GuiCtrlObj.hWnd)
        DllCall("uxtheme\SetWindowTheme", "Ptr", LV_Header, "Str", Mode_ItemsView, "Ptr", 0)
        GuiCtrlObj.Opt("+Redraw")
      }
    }
  }
  if !(Init) {
    ; https://www.autohotkey.com/docs/v2/lib/CallbackCreate.htm#ExSubclassGUI
    global WindowProcNew := CallbackCreate(WindowProc)  ; Avoid fast-mode for subclassing.
    global WindowProcOld := DllCall("user32\" . SetWindowLong, "Ptr", GuiObj.Hwnd, "Int", GWL_WNDPROC, "Ptr", WindowProcNew, "Ptr")
    Init := True
  }
}
WindowProc(hwnd, uMsg, wParam, lParam) {
  critical
  static WM_CTLCOLOREDIT := 0x0133
  static WM_CTLCOLORLISTBOX := 0x0134
  static WM_CTLCOLORBTN := 0x0135
  static WM_CTLCOLORSTATIC := 0x0138
  static DC_BRUSH := 18

  switch uMsg {
    case WM_CTLCOLOREDIT, WM_CTLCOLORLISTBOX:
    {
      DllCall("gdi32\SetTextColor", "Ptr", wParam, "UInt", DarkColors["Font"])
      DllCall("gdi32\SetBkColor", "Ptr", wParam, "UInt", DarkColors["Controls"])
      DllCall("gdi32\SetDCBrushColor", "Ptr", wParam, "UInt", DarkColors["Controls"], "UInt")
      return DllCall("gdi32\GetStockObject", "Int", DC_BRUSH, "Ptr")
    }
    case WM_CTLCOLORBTN:
    {
      DllCall("gdi32\SetDCBrushColor", "Ptr", wParam, "UInt", DarkColors["Background"], "UInt")
      return DllCall("gdi32\GetStockObject", "Int", DC_BRUSH, "Ptr")
    }
    case WM_CTLCOLORSTATIC:
    {
      DllCall("gdi32\SetTextColor", "Ptr", wParam, "UInt", DarkColors["Font"])
      DllCall("gdi32\SetBkColor", "Ptr", wParam, "UInt", DarkColors["Background"])
      return TextBGBrush
    }
  }
  return DllCall("user32\CallWindowProc", "Ptr", WindowProcOld, "Ptr", hwnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam)
}
