#Requires AutoHotkey v2.0
#SingleInstance Force

MButton::
{
  static on := False
  if on := !on {
    SetTimer(Click, 10), Click()
  } else {
    SetTimer(Click, 0)
  }
}
