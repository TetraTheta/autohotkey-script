/**
 * Get handle of embedded icon (HICON) by its group id
 * @param resNum ID number of Icon Group (use Resource Hacker)
 * @param size Desired size of the icon
 * @return {Integer} HICON (ptr) or 0 on failure
 */
GetEmbeddedIcon(resNum := 209, size := 32) {
  static IMAGE_ICON := 1
  static LR_SHARED := 0x8000
  static LR_DEFAULTSIZE := 0x40
  flags := LR_SHARED | LR_DEFAULTSIZE

  hMod := DllCall("GetModuleHandleW", "ptr", 0, "ptr")
  if !hMod
    return 0
  namePtr := resNum + 0
  hIcon := DllCall("LoadImageW", "ptr", hMod, "ptr", namePtr, "uint", IMAGE_ICON, "int", size, "int", size, "uint", flags, "ptr")
  return hIcon
}

/**
 * @param {String} inputStr
 * @param {Integer} count
 * @returns {Array}
 */
GetNumStringArray(inputStr, count) {
  if count <= 0
    return []

  s := String(inputStr)
  ext := ""
  if RegExMatch(s, "\.([A-Za-z0-9]+)$", &extM) {
    ext := "." extM.0
    base := SubStr(s, 1, StrLen(s) - StrLen(ext))
  } else
    base := s

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

BuildSafePSSingleQuoted(s) {
  return "'" StrReplace(String(s), "'", "''") "'"
}

BuildSafePSCommand(tokens) {
  if tokens.Length = 0
    return ""
  cmd := "& "
  for i, t in tokens {
    if i > 1
      cmd .= " "
    cmd .= BuildSafePSSingleQuoted(t)
  }
  return cmd
}

ParseWindowsCommandLine(text) {
  s := String(text)
  tokens := []
  len := StrLen(s)
  i := 1

  while i <= len {
    while i <= len {
      ch := SubStr(s, i, 1)
      if (ch = " " or ch = "`t")
        i += 1
      else
        break
    }
    if i > len
      break

    token := ""
    inQuote := false
    sawQuote := false
    while i <= len {
      ch := SubStr(s, i, 1)
      if !inQuote and (ch = " " or ch = "`t")
        break

      if ch = "\" {
        bsStart := i
        while i <= len and SubStr(s, i, 1) = "\"
          i += 1
        bsCount := i - bsStart
        if i <= len and SubStr(s, i, 1) = '"' {
          slashCount := Floor(bsCount / 2)
          loop slashCount
            token .= "\"
          if Mod(bsCount, 2) = 1 {
            token .= '"'
            i += 1
          } else {
            inQuote := !inQuote
            sawQuote := true
            i += 1
          }
        } else {
          loop bsCount
            token .= "\"
        }
        continue
      }

      if ch = '"' {
        inQuote := !inQuote
        sawQuote := true
        i += 1
        continue
      }

      token .= ch
      i += 1
    }

    if token != "" or sawQuote
      tokens.Push(token)
  }

  return tokens
}
