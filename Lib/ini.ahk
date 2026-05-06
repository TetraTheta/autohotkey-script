A_ScriptNameOnly := "" ; Variable for storing script file name
SplitPath(A_ScriptName, , , , &A_ScriptNameOnly)

/**
 * Reads and returns the value of the given key from INI file which has same name of the script.<br>
 * If the key doesn't exist, it will be created with provide default value.<br>
 * Note that INI files are written with UTF-16 (or ANSI).
 * @param Section Section name
 * @param Key Key name
 * @param DefaultValue Default value if the value does not exist
 * @returns {String} Value of the Key in the Section, or `DefaultValue`
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
 * Reads INI value and converts it to specified type.
 * If conversion fails, writes and returns DefaultValue.
 * Supported types: "string", "int", "float", "bool"
 * @param typeName Target type name
 * @param Section Section name
 * @param Key Key name
 * @param DefaultValue Default value if key is missing or conversion fails
 * @returns Converted value or DefaultValue
 */
IniGetAs(typeName, Section, Key, DefaultValue) {
  iniPath := GetIniPath()
  try {
    raw := IniRead(iniPath, Section, Key)
  } catch {
    IniWrite(DefaultValue, iniPath, Section, Key)
    return DefaultValue
  }

  ok := false
  converted := IniConvertValue(typeName, raw, &ok)
  if ok
    return converted

  IniWrite(DefaultValue, iniPath, Section, Key)
  return DefaultValue
}

IniConvertValue(typeName, rawValue, &ok := false) {
  ok := true
  typeKey := StrLower(Trim(String(typeName)))
  s := Trim(String(rawValue))

  switch typeKey {
    case "string", "str":
      return s
    case "int", "integer":
      if RegExMatch(s, "^[+-]?\d+$")
        return Integer(s)
      ok := false
      return ""
    case "float", "double", "number":
      if RegExMatch(s, "^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$")
        return Float(s)
      ok := false
      return ""
    case "bool", "boolean":
      low := StrLower(s)
      if low = "1" or low = "true" or low = "yes" or low = "on"
        return true
      if low = "0" or low = "false" or low = "no" or low = "off"
        return false
      ok := false
      return ""
    default:
      ok := false
      return ""
  }
}

/**
 * Returns absolute path of INI file.
 * @returns {String} Absolute path of INI file
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
