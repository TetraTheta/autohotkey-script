#Requires AutoHotkey v2
#SingleInstance Force

; ------------------------------------------------------------------------------
; Hotkeys
; Ctrl + B : 「」
^B::
{
  Send("「」{left}")
}
; Ctrl + D : Insert single image
^D::
{
  input := MyInputBox("Input image name.`nYou can omit extension and it will default to 'webp'.", "Markdown - Single Image Helper", , , "shell32.dll", 128)

  if (input != "") {
    if (IsNumber(input)) {
      inputNumber := Number(input)
      output := "![](" . Format("{:03}", inputNumber) . ".webp)`n`n"
    } else {
      output := "![](" . input . ".webp)`n`n"
    }
    SendText(output)
  }
}
; Ctrl + Shift + D : Insert multiple images
^+D::
{
  input := MyInputBox("Input last image name.`nYou can omit extension and it will default to 'webp'.", "Markdown - Multiple Image Helper", , , "shell32.dll", 319)

  if (input != "") {
    num := ""
    extension := "webp"

    if !(IsNumber(input)) {
      SplitPath(input, , , &extension, &num)
      if !(IsNumber(num)) {
        MsgBox("Given file name cannot be batch processed.`nAborting.", "ERROR", "OK Iconx T3")
        return
      }
      num := Number(num)
    } else {
      num := Number(input)
    }

    output := ""
    Loop num {
      output .= "![](" . Format("{:03}", A_Index) . "." . extension . ")`n`n`n`n"
    }
    
    clipTemp := A_Clipboard
    A_Clipboard := output
    Send("^v")
    Sleep(10)
    A_Clipboard := clipTemp
  }
}
; Ctrl + G : Insert gallery/image with two sources, with given numbers
^G::
{
  input := MyInputBox("Input first image name`nYou can omit extension and it will default to 'webp'.", "Markdown - Gallery Image (Two) Helper", , , "shell32.dll", 128)

  if (input != "") {
    if !(IsNumber(input)) {
      MsgBox("Given file name cannot be batch processed.`nAborting.", "ERROR", "OK Iconx T3")
      return
    }
    num := Number(input)

    SendText("{{< gallery/image src=`"" . Format("{:03}", num) . ":" . Format("{:03}", num+1) . "`" >}}`n`n")
  }
}
; Ctrl + Shift + G : Insert gallery/image with three sources and caption
^+G::
{
  input := MyInputBox("Input first image name`nYou can omit extension and it will default to 'webp'.", "Markdown - Gallery Image (Three) Helper", , , "shell32.dll", 128)

  if (input != "") {
    if !(IsNumber(input)) {
      MsgBox("Given file name cannot be batch processed.`nAborting.", "ERROR", "OK Iconx T3")
      return
    }
    num := Number(input)

    SendText("{{< gallery/image src=`"" . Format("{:03}", num) . ":" . Format("{:03}", num+1) . ":" . Format("{:03}", num+2) . "`" >}}`n`n")
  }
}
; Win + G : Insert gallery/image with two sources
#G::
{
  SendText("{{< gallery/image src=`":`" >}}`n`n")
}
; Win + Shift + G : Insert gallery/image with three sources
#+G::
{
  SendText("{{< gallery/image src=`"::`" >}}`n`n")
}
; Ctrl + Q : Insert NBSP
^Q::
{
  SendText("&nbsp;`n`n")
}
; ------------------------------------------------------------------------------
; Configure tray menu
MenuTray := A_TrayMenu
MenuTray.Default := "10&" ; Default action is 'Exit'
; ------------------------------------------------------------------------------
; Functions
MyInputBox(aPrompt := "", aTitle := A_ScriptName, aDefault := "", aTimeout := 10, aIconFile := "", aIconIndex := 1) {
  Result := ""

  ; Set GUI icon (hack)
  if (aIconFile != "") {
    TraySetIcon(aIconFile, aIconIndex)
    MyGui := Gui(, aTitle)
  } else {
    MyGui := Gui(, aTitle)
  }

  MyGui.Opt("+AlwaysOnTop -MaximizeBox -MinimizeBox -Resize +OwnDialogs")
  MyGui.OnEvent("Escape", (*) => (MyGui.Destroy()))

  Gui_Edit := MyGui.AddEdit("x5 y114 w358 h26 -Multi", aDefault)
  Gui_Button_OK := MyGui.AddButton("x51 y145 w88 h26 +Default", "OK")
  Gui_Button_Cancel := MyGui.AddButton("x230 y145 w88 h26", "Cancel")

  Gui_Button_OK.OnEvent("Click", (*) => (Result := Gui_Edit.Value, MyGui.Destroy()))
  Gui_Button_Cancel.OnEvent("Click", (*) => (MyGui.Destroy()))

  if (aIconFile != "") {
    if (StrLower(aIconFile) == "ddores.dll")
      aIconFile := "C:\Windows\System32\DDORes.dll"
    else if (StrLower(aIconFile) == "imageres.dll")
      aIconFile := "C:\Windows\System32\imageres.dll"
    else if (StrLower(aIconFile) == "shell32.dll")
      aIconFile := "C:\Windows\System32\shell32.dll"

    IconIndex := "Icon" . aIconIndex

    Gui_Icon := MyGui.AddPicture("x5 y5 w32 h-1 " . IconIndex, aIconFile)
    Gui_Prompt := MyGui.AddText("x42 y5 w321 h104", aPrompt)
  } else {
    Gui_Prompt := MyGui.AddText("x5 y5 w358 h104", aPrompt)
  }

  MyGui.Show("AutoSize Center")

  TraySetIcon("*") ; Reset tray icon

  if (!WinWaitClose(MyGui,, aTimeout)) {
    MyGui.Destroy()
    return Result
  } else return Result
}
