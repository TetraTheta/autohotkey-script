/************************************************************************
 * @description Extract character name from URL copied from Blue Archive Wiki
 * @file CopyDecode.ahk
 * @author TetraTheta
 * @date 2022/12/01
 * @version 1.0.0
 ***********************************************************************/
; When copy link from 'https://bluearchive.wikiru.jp/', extract name part and decode it
; Turn this script off if it is not in use!

#Requires AutoHotkey v2
#SingleInstance Force
Persistent()

OnClipboardChange(CheckURL)
return

CheckURL(Type) {
  if (Type != 1) {
    Return
  }
  ; Check if copied text starts with 'https://bluearchive.wikiru.jp/'
  if (InStr(A_Clipboard, "https://bluearchive.wikiru.jp/") == 1) {
    ; Remove 'https://bluearchive.wikiru.jp/' part
    ori_clip := A_Clipboard
    cut_clip := SubStr(A_Clipboard, 32)
    new_clip := URLDecode(cut_clip)
    A_Clipboard := new_clip
    TrayTip("Detected: " . cut_clip . "`nConverted: " . new_clip, "Conversion Result", 1)
    Sleep(20)
  }
}

; Source: https://www.autohotkey.com/boards/viewtopic.php?t=112741#p502115
URLDecode(Uri, Encoding := "UTF-8") {
  pos := 1
  While pos := RegExMatch(Uri, "i)(%[\da-f]{2})+", &code, pos) {
    var := Buffer(StrLen(code[0]) // 3, 0)
    code := SubStr(code[0], 2)
    Loop Parse, code, "%" {
      NumPut("UChar", "0x" A_LoopField, var, A_Index - 1)
    }
    decoded := StrGet(var, Encoding)
    Uri := SubStr(Uri, 1, pos - 1) . decoded . SubStr(Uri, pos + StrLen(code) + 1)
    pos += StrLen(decoded) + 1
  }
  Return (Uri)
}
