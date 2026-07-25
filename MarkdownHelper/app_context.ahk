#Include "i18n.ahk"
#Include "locale.ahk"
#Include "helpers.ahk"
#Include "..\Lib\ini.ahk"
#Include "..\Lib\orderedMap.ahk"

BuildAppContext(args) {
  lang := GetLanguageCode()
  for _, arg in args {
    if StrLower(arg) = "/english" {
      lang := "en"
      break
    }
  }

  ctx := Map()
  ctx.Lang := lang
  ctx.L := I18N(MarkdownHelperIntlData, lang)

  ctx.N := GetCategoryMap(lang)
  ctx.NK := []
  for k, _ in ctx.N
    ctx.NK.Push(k)

  c := Map()
  c.ProjectRootDir := IniGet("General", "Project Root Directory", A_ScriptDir)
  c.KeepConsoleOpen := IniGet("General", "Keep Console Open", false)
  c.CLICommand := Trim(IniGet("General", "CLI Command", ""))
  c.TimeoutGallery := GetIniIntOrDefault("Timeout", "Gallery", 15)
  c.TimeoutImage := GetIniIntOrDefault("Timeout", "Image", 15)
  c.TimeoutNew := GetIniIntOrDefault("Timeout", "New Post", 60)
  c.ExplorerExec := IniGet("Explorer", "Executable", "explorer.exe")
  c.ExplorerArgs := IniGet("Explorer", "Arguments", "")
  c.TerminalExec := IniGet("Terminal", "Executable", "pwsh.exe")
  c.TerminalArgs := IniGet("Terminal", "Arguments", '-NoLogo -NoProfile -NoExit -Command "[console]::WindowWidth=120;[console]::WindowHeight=30;Set-Location -LiteralPath `'C:\`'"')
  c.GitGUIExec := IniGet("Git GUI", "Executable", "C:\Program Files\Git\cmd\git-gui.exe")
  c.GitGUIArgs := IniGet("Git GUI", "Arguments", A_ScriptDir)
  c.DevExec := IniGet("Dev Server", "Executable", "hugo.exe")
  c.DevArgs := IniGet("Dev Server", "Arguments", "")
  c.WebBrowserExec := IniGet("Web Browser", "Executable", "chrome.exe")
  c.WebBrowserArgs := IniGet("Web Browser", "Arguments", "")
  c.RecentCategory := IniKey(, "Recent", "Category")
  c.RecentTitle1 := IniKey(, "Recent", "Title 1")
  c.RecentTitle2 := IniKey(, "Recent", "Title 2")
  c.RecentTitle3 := IniKey(, "Recent", "Title 3")
  c.RecentTitle4 := IniKey(, "Recent", "Title 4")
  c.RecentTitle5 := IniKey(, "Recent", "Title 5")
  c.KeepConsoleOpen := c.KeepConsoleOpen ? true : false
  c.TerminalArgs := NormalizePowerShellArgsToEncoded(c.TerminalExec, c.TerminalArgs)
  if InStr(StrLower(c.TerminalExec), "cmd.exe") or InStr(StrLower(c.TerminalExec), "command.com") {
    c.TerminalExec := "pwsh.exe"
    if RegExMatch(Trim(c.TerminalArgs), "^(?i)/(K|C)\b")
      c.TerminalArgs := BuildPowerShellArgs("[console]::WindowWidth=120;[console]::WindowHeight=30;Set-Location -LiteralPath " BuildSafePSSingleQuoted(c.ProjectRootDir), true)
    c.TerminalArgs := NormalizePowerShellArgsToEncoded(c.TerminalExec, c.TerminalArgs)
  }
  c.DetectedPM := DetectPackageManager(c.ProjectRootDir)
  ctx.C := c

  return ctx
}

GetPowerShellConsoleSizePrefix() {
  return "[console]::WindowWidth=120;[console]::WindowHeight=30;"
}

BuildPowerShellRunArgs(psBody, keepOpen := false) {
  return "pwsh.exe " BuildPowerShellArgs(GetPowerShellConsoleSizePrefix() psBody, keepOpen)
}

BuildPowerShellArgs(psBody, keepOpen := false) {
  encoded := ToBase64UTF16LE(String(psBody))
  if keepOpen
    return "-NoLogo -NoProfile -NoExit -EncodedCommand " encoded
  return "-NoLogo -NoProfile -EncodedCommand " encoded
}

NormalizePowerShellArgsToEncoded(execPath, args) {
  execLower := StrLower(String(execPath))
  if !InStr(execLower, "pwsh.exe") and !InStr(execLower, "pwsh.exe")
    return args

  argText := Trim(String(args))
  if argText = ""
    return args
  if InStr(StrLower(argText), "-EncodedCommand")
    return argText

  keepOpen := RegExMatch(argText, "(?i)(^|\s)-NoExit(\s|$)")

  psBody := ExtractPowerShellCommandBody(argText, &hasCommand)
  if hasCommand
    return BuildPowerShellArgs(psBody, keepOpen)
  return args
}

ExtractPowerShellCommandBody(argText, &hasCommand := false) {
  hasCommand := false
  if !RegExMatch(argText, "(?i)-Command\b", &m)
    return ""
  hasCommand := true

  body := Trim(SubStr(argText, m.Pos + m.Len), " `t`r`n")
  if body = ""
    return ""

  dq := Chr(34)
  sq := Chr(39)
  tick := Chr(96)

  loop 4 {
    n := StrLen(body)
    if n < 2
      break

    first1 := SubStr(body, 1, 1)
    last1 := SubStr(body, n, 1)
    first2 := n >= 2 ? SubStr(body, 1, 2) : ""
    last2 := n >= 2 ? SubStr(body, n - 1, 2) : ""

    if (first2 = tick dq and last2 = tick dq) {
      body := SubStr(body, 3, n - 4)
      continue
    }
    if (first2 = tick dq and last1 = dq) {
      body := SubStr(body, 3, n - 3)
      continue
    }
    if (first1 = dq and last2 = tick dq) {
      body := SubStr(body, 2, n - 3)
      continue
    }
    if (first1 = dq and last1 = dq) {
      body := SubStr(body, 2, n - 2)
      continue
    }
    if (first1 = sq and last1 = sq) {
      body := SubStr(body, 2, n - 2)
      continue
    }
    break
  }

  body := StrReplace(body, tick dq, dq)
  body := StrReplace(body, dq dq, dq)
  return body
}

BuildPowerShellInvokeRaw(execPath, args := "") {
  argText := Trim(String(args))
  cmd := "& " BuildSafePSSingleQuoted(execPath)
  if argText != ""
    cmd .= " " argText
  return cmd
}

GetIniIntOrDefault(section, key, defaultValue, minValue := 1) {
  value := IniGetAs("int", section, key, defaultValue)
  if value < minValue
    return defaultValue
  return value
}

ToBase64UTF16LE(text) {
  s := String(text)
  ; Encode exactly StrLen(s) UTF-16 code units (no trailing null/padding).
  charCount := StrLen(s)
  utf16Buf := Buffer((charCount + 1) * 2, 0)
  StrPut(s, utf16Buf, charCount + 1, "UTF-16")
  dataByteCount := charCount * 2

  needed := 0
  if !DllCall("Crypt32\CryptBinaryToStringW"
    , "ptr", utf16Buf.Ptr
    , "uint", dataByteCount
    , "uint", 0x40000001
    , "ptr", 0
    , "uint*", &needed)
    throw Error("CryptBinaryToStringW failed (size query).")

  out := Buffer(needed * 2, 0)
  if !DllCall("Crypt32\CryptBinaryToStringW"
    , "ptr", utf16Buf.Ptr
    , "uint", dataByteCount
    , "uint", 0x40000001
    , "ptr", out.Ptr
    , "uint*", &needed)
    throw Error("CryptBinaryToStringW failed.")

  return StrGet(out.Ptr)
}

BuildQuotedCommand(execPath, args := "") {
  argText := Trim(String(args))
  if argText = ""
    return "`"" String(execPath) "`""
  return "`"" String(execPath) "`" " argText
}

BuildTerminalLaunchCommand(ctx) {
  return BuildQuotedCommand(ctx.C.TerminalExec, ctx.C.TerminalArgs)
}

GetCategoryMap(lang) {
  iniPath := GetIniPath(A_ScriptNameOnly "-Category")
  try content := FileRead(iniPath)
  catch {
    FileAppend("", iniPath)
    content := ""
  }
  if content = ""
    return OrderedMap()

  m := OrderedMap()
  displayKey := "display." lang
  curDisplay := ""
  curKind := ""

  for line in StrSplit(content, "`n") {
    line := Trim(line, "`t`r ")
    if line = "" or SubStr(line, 1, 1) = ";" or SubStr(line, 1, 1) = "#"
      continue

    if SubStr(line, 1, 1) = "[" {
      if (curDisplay != "" and curKind != "")
        m[curDisplay] := curKind
      curDisplay := ""
      curKind := ""
      continue
    }

    pos := InStr(line, "=")
    if !pos
      continue

    key := Trim(SubStr(line, 1, pos - 1))
    val := Trim(SubStr(line, pos + 1))

    if (key == displayKey)
      curDisplay := val
    else if (key == "kind")
      curKind := val
  }

  if curDisplay != "" and curKind != ""
    m[curDisplay] := curKind

  return m
}

DetectPackageManager(projectRootDir) {
  if FileExist(projectRootDir "\pnpm-lock.yaml")
    return "pnpm"
  if FileExist(projectRootDir "\yarn.lock")
    return "yarn"
  if FileExist(projectRootDir "\bun.lock") or FileExist(projectRootDir "\bun.lockb")
    return "bun"
  if FileExist(projectRootDir "\package-lock.json")
    return "npm"
  return "npm"
}

GetDefaultCLICommand(pm) {
  switch pm {
    case "pnpm":
      return "pnpm --filter @tetralog/cli run cli"
    case "yarn":
      return "yarn --cwd .script cli"
    case "bun":
      return "bun run --cwd .script cli"
    case "npm":
      return "npm --prefix .script run cli --"
    default:
      return "npm --prefix .script run cli --"
  }
}

GetCLIBaseCommand(ctx) {
  if ctx.C.CLICommand != ""
    return ctx.C.CLICommand
  return GetDefaultCLICommand(ctx.C.DetectedPM)
}

GetPMDependenciesUpdatePSCommand(pm) {
  switch pm {
    case "pnpm":
      return "$Host.UI.RawUI.WindowTitle='Updating Dependencies (pnpm)...';pnpm outdated;pnpm update;pnpm install --lockfile-only;Write-Host '==== DONE ====' -ForegroundColor Green;[void][System.Console]::ReadKey($false)"
    case "yarn":
      return "$Host.UI.RawUI.WindowTitle='Updating Dependencies (yarn)...';yarn outdated;yarn up;yarn install;Write-Host '==== DONE ====' -ForegroundColor Green;[void][System.Console]::ReadKey($false)"
    case "bun":
      return "$Host.UI.RawUI.WindowTitle='Updating Dependencies (bun)...';bun outdated;bun update;bun install --lockfile-only;Write-Host '==== DONE ====' -ForegroundColor Green;[void][System.Console]::ReadKey($false)"
    case "npm":
      return "$Host.UI.RawUI.WindowTitle='Updating Dependencies (npm)...';npm outdated;npm update;npm install --package-lock-only;Write-Host '==== DONE ====' -ForegroundColor Green;[void][System.Console]::ReadKey($false)"
    default:
      return "$Host.UI.RawUI.WindowTitle='Updating Dependencies (npm)...';npm outdated;npm update;npm install --package-lock-only;Write-Host '==== DONE ====' -ForegroundColor Green;[void][System.Console]::ReadKey($false)"
  }
}

RunPMDependenciesUpdate(ctx, *) {
  pm := DetectPackageManager(ctx.C.ProjectRootDir)
  psCommand := GetPMDependenciesUpdatePSCommand(pm)
  Run(BuildPowerShellRunArgs(psCommand, true), ctx.C.ProjectRootDir)
}
