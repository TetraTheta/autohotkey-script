/*
IniGet(Section, Key, DefaultValue)
Reads and returns the value of the given key from INI file which has same name of the script.
If the key doesn't exist, it will be created with provide default value.
Note that INI files are written with UTF-16 (or ANSI).
*/
SCRIPT := "" ; Variable for storing script file name
SplitPath(A_ScriptName,,,,&SCRIPT)

IniGet(Section, Key, DefaultValue)
{
  ; Read from INI file and if the entry does not exists, create new one with default value
  global SCRIPT
  iniPath := A_ScriptDir . "\" . SCRIPT . ".ini"
  try {
    ; Get value of the key
    ; Will throw Error instead of OSError if key doesn't exist
    tempVar := IniRead(iniPath, Section, Key)
  } catch Error as e {
    ; Value doesn't exist
    IniWrite(DefaultValue, iniPath, Section, Key)
    tempVar := DefaultValue
  }
  return tempVar
}
GetIniPath() {
  return A_ScriptDir . "\" . SCRIPT . ".ini"
}
