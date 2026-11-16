# MarkdownHelper

AutoHotkey v2 helpers for a Hugo blog. Console actions use Git for Windows Bash.

## Terminal profiles

`MarkdownHelper.ini` lives beside the running script or compiled executable.
Missing settings for both profiles are created automatically.
Only the selected profile's executable is checked when a console action is requested.

```ini
[Terminal]
; Supported types: git-bash, alacritty-bash
Type=git-bash

[Terminal.git-bash]
Executable=C:\Program Files\Git\git-bash.exe
Arguments=

[Terminal.alacritty-bash]
Executable=C:\path\to\alacritty.exe
Arguments=--config-file "C:\path\to\git_bash_profile.toml"
```

Change `Type` to switch profiles without losing either configuration.
This selects the terminal for **all** console actions: opening a shell, creating content, running the dev server, and updating Hugo modules or package dependencies.
Unknown types and missing executables show an error; there is no fallback shell.
Use separate lines beginning with `;` for INI comments, not inline comments.

For Alacritty, replace the placeholder paths. For example:

```ini
[Terminal.alacritty-bash]
Executable=C:\path\to\alacritty.exe
Arguments=--config-file "C:\path\to\git_bash_profile.toml"
```

For standalone Alacritty use, its TOML can select Git for Windows Bash:

```toml
[terminal]
shell = { program = "C:/Program Files/Git/bin/bash.exe" }
```

MarkdownHelper uses Alacritty's `-e` interface to run Git for Windows Bash with `--login -i -c`. It finds `bin/bash.exe` beside the configured Git Bash launcher, then falls back to registered Git for Windows installations. No extra Bash path setting is needed.
A portable installation can be selected through `[Terminal.git-bash] Executable` even when Alacritty is active.
The inactive launcher's existence is not required; the selected terminal and Bash must exist.

The TOML's fonts, colors, dimensions, and other terminal preferences remain in effect, but its shell program/arguments are overridden for MarkdownHelper tasks. The TOML is neither edited nor parsed.
`Arguments` contains terminal options only; do not add `-e` or shell overrides.
Partial `terminal.shell.args` overrides are not used because Alacritty rejects them for its shell configuration type.

Login initialization runs before MarkdownHelper changes to the project root. If changing directory fails, the task is not executed.
Opening a terminal leaves an interactive shell there. `Keep Console Open=1` also leaves an interactive Bash after a task, including a dev-server Ctrl+C; `0` closes it.
Maintenance actions report failed commands while continuing the remaining steps. They always print the green `==== DONE ====` marker before waiting for a key and leaving a shell. A failed step also produces a red `==== COMPLETED WITH ERRORS ====` summary.

## Commands and development server

`CLI Command` and `[Dev Server] Arguments` are executable argument lists using Windows double-quote rules, not shell expressions. Quote paths containing spaces. Put complex shell logic in a Bash script. 
Use forward slashes for paths passed as arguments to Bash scripts.

For the blog's `.script/dev_server.sh`:

```ini
[Dev Server]
Executable=bash
Arguments=.script/dev_server.sh
```

The script runs inside the selected terminal's Git Bash environment.
It resolves the blog root from its own location, removes only generated `public` and `resources` entries there, and runs Hugo on port 44 in the foreground.
Ctrl+C stops the server.
Git Bash must provide the configured CLI tools on its PATH.
