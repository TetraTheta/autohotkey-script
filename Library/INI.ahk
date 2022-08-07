; %SCRIPT% : Variable for script name without extension
; IniGet(Section, Key, DefaultValue) : Reads and returns the key value from an INI file with the same name as the script.
;                                           If the key does not exist, create a new key with the provided default value.

SplitPath, A_ScriptName,,,,SCRIPT ; %SCRIPT%

IniGet(Section, Key, DefaultValue)
{
  ; Read from INI file and if the entry does not exists, create new one with default value
  Global SCRIPT
  IniRead, tempVar, %A_ScriptDir%\%SCRIPT%.ini, %Section%, %Key%
  If (tempVar = "ERROR")
  {
    IniWrite, %DefaultValue%, %A_ScriptDir%\%SCRIPT%.ini, %Section%, %Key%
    tempVar := DefaultValue
  }
  Return tempVar
}
