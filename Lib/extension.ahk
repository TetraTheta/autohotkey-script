ArrayImplode(arr, delim := ", ") {
  result := ""
  isFirst := true
  for , val in arr {
    if !isFirst
      result .= delim
    result .= val
    isFirst := false
  }
  return result
}

ObjectToString(obj, depth := 0, visited := "") {
  if !IsObject(obj)
    return _FormatPrimitive(obj)

  if visited = ""
    visited := Map()

  if visited.Has(Obj)
    return "<circular " _TypeName(obj) ">"

  visited[obj] := true

  indent := ""
  loop depth
    indent .= "  "

  nextIndent := indent . "  "
  lines := []

  ; Map
  if obj is Map {
    for k, v in obj {
      kStr := IsObject(k) ? k.ToString(depth + 1, visited) : _FormatPrimitive(k)
      vStr := IsObject(v) ? v.ToString(depth + 1, visited) : _FormatPrimitive(v)
      lines.Push(nextIndent . kStr . ": " . vStr)
    }
    result := _TypeName(obj) . "("
    if (lines.Length)
      result .= "`n" . ArrayImplode(lines, "`n") . "`n" . indent
    result .= ")"
    visited.Delete(obj)
    return result
  }

  if obj is Array {
    idx := 1
    for i, v in obj {
      vStr := IsObject(v) ? v.ToString(depth + 1, visited) : _FormatPrimitive(v)
      lines.Push(nextIndent . vStr)
      idx++
    }
    result := "["
    if (lines.Length)
      result .= "`n" . ArrayImplode(lines, "`n") . "`n" . indent
    result .= "]"
    visited.Delete(obj)
    return result
  }

  for k, v in obj {
    kStr := IsObject(k) ? k.ToString(depth + 1, visited) : _FormatPrimitive(k)
    vStr := IsObject(v) ? v.ToString(depth + 1, visited) : _FormatPrimitive(v)
    lines.Push(nextIndent . kStr . ": " . vStr)
  }
  result := "{"
  if (lines.Length())
    result .= "`n" . ArrayImplode(lines, "`n") . "`n" . indent
  result .= "}"
  visited.Delete(obj)
  return result
}

_TypeName(obj) {
  if (obj is Map)
    return "Map"
  if (obj is Array)
    return "Array"
  return "Object"
}

_FormatPrimitive(v) {
  if IsObject(v)
    return v.ToString()

  if (v is Number)
    return v

  s := StrReplace(String(v), "'", "''")
  s := StrReplace(s, "`n", "\\n")
  s := StrReplace(s, "`r", "\\r")
  return "'" s "'"
}

Array.Prototype.DefineProp("Implode", { Call: ArrayImplode })
Array.Prototype.DefineProp("ToString", { Call: ObjectToString })
Map.Prototype.DefineProp("ToString", { Call: ObjectToString })
Object.Prototype.DefineProp("ToString", { Call: ObjectToString })
