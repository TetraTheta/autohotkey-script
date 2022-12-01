; CopyDecode: When copy link from 'https://bluearchive.wikiru.jp/', decode its URL encoded string
; If not in use, turn off this script!

#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

OnClipboardChange("CheckURL")
return

CheckURL(Type) {
  If (Type == 1) {
    If (InStr(Clipboard, "https://bluearchive.wikiru.jp/") == 1) {
      new_clip := SubStr(Clipboard, 32)
      Clipboard := URLDecode(new_clip)
      Sleep, 20
    }
  }
}

; source: https://github.com/ahkscript/libcrypt.ahk/blob/master/src/URI.ahk
URLDecode(Uri, Encoding:="UTF-8") {
  Pos := 1
  While Pos := RegExMatch(Uri, "i)(%[\da-f]{2})+", Code, Pos) {
    VarSetCapacity(Var, StrLen(Code) // 3, 0), Code := SubStr(Code, 2)
    Loop, Parse, Code, `%
      NumPut("0x" A_LoopField, Var, A_Index - 1, "UChar")
    Decoded := StrGet(&Var, Encoding)
    Uri := SubStr(Uri, 1, Pos - 1) . Decoded . SubStr(Uri, Pos + StrLen(Code) + 1)
    Pos += StrLen(Decoded) + 1
  }
  Return, Uri
}
