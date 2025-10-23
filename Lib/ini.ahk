A_ScriptNameOnly := "" ; Variable for storing script file name
SplitPath(A_ScriptName,,,,&A_ScriptNameOnly)

/**
 * Reads and returns the value of the given key from INI file which has same name of the script.<br>
 * If the key doesn't exist, it will be created with provide default value.<br>
 * Note that INI files are written with UTF-16 (or ANSI).
 * @param Section Section name
 * @param Key Key name
 * @param DefaultValue Default value if the value does not exist
 * @returns Value of the Key in the Section, or `DefaultValue`
 */
IniGet(Section, Key, DefaultValue) {
  iniPath := GetIniPath()
  try {
    ; Get value of the key
    ; Will throw Error instead of OSError if key doesn't exist
    tempVar := IniRead(iniPath, Section, Key)
  } catch {
    ; Value doesn't exist
    IniWrite(DefaultValue, iniPath, Section, Key)
    tempVar := DefaultValue
  }
  return tempVar
}

/**
 * Returns absolute path of INI file.
 * @returns Absolute path of INI file
 */
GetIniPath(fileName := A_ScriptNameOnly) {
  return A_ScriptDir . "\" fileName ".ini"
}

class IniKey {
  iniPath := ""
  section := ""
  key := ""
  defaultValue := ""

  __New(iniPath := GetIniPath(), section := "", key := "", default := "") {
    this.iniPath := iniPath
    this.section := section
    this.key := key
    this.defaultValue := default
  }

  Value {
    get {
      try {
        return IniRead(this.iniPath, this.section, this.key)
      } catch {
        return this.defaultValue
      }
    }
    set => IniWrite(value, this.iniPath, this.section, this.key)
  }
}
