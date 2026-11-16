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
  c.TerminalType := StrLower(Trim(IniGet("Terminal", "Type", "git-bash")))
  profiles := Map(
    "git-bash", ["C:\Program Files\Git\git-bash.exe", ""],
    "alacritty-bash", ["C:\path\to\alacritty.exe", '--config-file "C:\path\to\git_bash_profile.toml"']
  )
  for terminalType, defaults in profiles {
    execPath := IniGet("Terminal." terminalType, "Executable", defaults[1])
    arguments := IniGet("Terminal." terminalType, "Arguments", defaults[2])
    if terminalType = "git-bash"
      c.GitBashExec := execPath
    if terminalType = c.TerminalType {
      c.TerminalExec := execPath
      c.TerminalArgs := arguments
    }
  }
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
  c.DetectedPM := DetectPackageManager(c.ProjectRootDir)
  ctx.C := c

  return ctx
}

/** Builds a command for the selected terminal without changing its profile file. */
BuildBashRunCommand(ctx, body := "", keepOpen := false) {
  c := ctx.C
  if c.TerminalType != "git-bash" and c.TerminalType != "alacritty-bash"
    throw Error(ctx.L.TERM_InvalidType " [Terminal] Type=" c.TerminalType)
  if !FileExist(c.TerminalExec) or InStr(FileExist(c.TerminalExec), "D")
    throw Error(ctx.L.TERM_MissingExecutable " [Terminal." c.TerminalType "] Executable=" c.TerminalExec)

  script := BuildBashScript(c.ProjectRootDir, body, keepOpen)
  command := QuoteWindowsArgument(c.TerminalExec)
  if Trim(c.TerminalArgs) != ""
    command .= " " c.TerminalArgs
  if c.TerminalType = "git-bash"
    return command " --cd=" QuoteWindowsArgument(c.ProjectRootDir) " -c " QuoteWindowsArgument(script)

  ; Alacritty cannot partially override its shell enum; use its command interface instead.
  bashExec := FindGitBashExecutable(c.GitBashExec)
  ; Windows Alacritty joins -e arguments raw, so quote again for its child process.
  return command " --working-directory " QuoteWindowsArgument(c.ProjectRootDir) . " -e " QuoteWindowsArgument(QuoteWindowsArgument(bashExec)) " --login -i -c " QuoteWindowsArgument(QuoteWindowsArgument(script))
}

/** Support portable Git beside git-bash.exe, then registered Git for Windows installs. */
FindGitBashExecutable(gitBashExec) {
  SplitPath(gitBashExec, , &gitDir)
  candidates := [gitDir "\bin\bash.exe"]
  for key in ["HKCU\Software\GitForWindows", "HKLM\Software\GitForWindows", "HKLM\Software\WOW6432Node\GitForWindows"] {
    installPath := RegRead(key, "InstallPath", "")
    if installPath != ""
      candidates.Push(installPath "\bin\bash.exe")
  }
  for _, candidate in candidates {
    if FileExist(candidate) and !InStr(FileExist(candidate), "D")
      return candidate
  }
  throw Error("Git for Windows bin\bash.exe was not found. Install Git for Windows or set [Terminal.git-bash] Executable to its git-bash.exe.")
}

/** Re-enter the project directory after login profiles have run. */
BuildBashScript(projectRootDir, body := "", keepOpen := false) {
  script := "cd -- " QuoteBashArgument(StrReplace(projectRootDir, "\", "/")) " || exit $?`n"
  ; Keep the launcher alive when Ctrl+C interrupts a foreground task.
  if keepOpen
    script .= "trap ':' INT`n"
  if body != ""
    script .= body "`nmh_status=$?`n"
  else
    script .= "mh_status=0`n"
  if keepOpen or body = ""
    script .= "exec bash -i"
  else
    script .= 'exit "$mh_status"'
  return script
}

/** Report launch errors without disabling unrelated GUI helpers. */
RunBash(ctx, body := "", keepOpen := false) {
  try Run(BuildBashRunCommand(ctx, body, keepOpen), ctx.C.ProjectRootDir)
  catch Error as err
    MsgBox(ctx.L.TERM_LaunchFailed "`n`n" err.Message, "MarkdownHelper", 48)
}

RunDevServer(ctx, *) {
  tokens := [StrReplace(ctx.C.DevExec, "\", "/")]
  for _, token in ParseWindowsCommandLine(ctx.C.DevArgs)
    tokens.Push(token)
  RunBash(ctx, BuildSafeBashCommand(tokens), ctx.C.KeepConsoleOpen)
}

GetIniIntOrDefault(section, key, defaultValue, minValue := 1) {
  value := IniGetAs("int", section, key, defaultValue)
  if value < minValue
    return defaultValue
  return value
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

GetPMDependenciesUpdateCommands(pm) {
  switch pm {
    case "pnpm":
      return ["pnpm outdated", "pnpm update", "pnpm install --lockfile-only"]
    case "yarn":
      return ["yarn outdated", "yarn up", "yarn install"]
    case "bun":
      return ["bun outdated", "bun update", "bun install --lockfile-only"]
    default:
      return ["npm outdated", "npm update", "npm install --package-lock-only"]
  }
}

/** Preserve the completion marker while reporting failed maintenance steps. */
BuildMaintenanceScript(title, commands) {
  script := "printf '\033]0;%s\007' " QuoteBashArgument(title) "`nmh_failed=0`n"
  for _, command in commands {
    script .= command "`nmh_step=$?`n"
    script .= "if (( mh_step != 0 )); then printf 'FAILED (%s): %s\n' "
      . '"$mh_step" ' QuoteBashArgument(command) " >&2; mh_failed=1; fi`n"
  }
  script .= "if (( mh_failed != 0 )); then printf '\033[31m==== COMPLETED WITH ERRORS ====\033[0m\n'; fi`n"
  script .= "printf '\033[32m==== DONE ====\033[0m\n'`n"
  script .= "read -r -n 1 -p 'Press any key to continue...' </dev/tty; printf '\n'`n"
  script .= '(exit "$mh_failed")'
  return script
}

RunMaintenance(ctx, title, commands) {
  RunBash(ctx, BuildMaintenanceScript(title, commands), true)
}

RunPMDependenciesUpdate(ctx, *) {
  pm := DetectPackageManager(ctx.C.ProjectRootDir)
  RunMaintenance(ctx, "Updating Dependencies (" pm ")...", GetPMDependenciesUpdateCommands(pm))
}
