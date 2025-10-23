GetLanguageCode() {
  id := Map(
    "0012", "ko",
    "0412", "ko"
  )
  if id.Has(A_Language)
    return "ko"
  else
    return "en"
}

class I18N {
  __New(data, lang := GetLanguageCode()) {
    this.lang := lang
    if !IsObject(data)
      data := {}

    this._data := data
    this._keys := []
    this._populate()
  }

  _populate() {
    if !IsObject(this._data)
      this._data := {}

    ; Remove previously created dynamic properties
    for idx, k in this._keys {
      try this.DeleteProp(k)
      catch {
        try this[k] := ""
      }
    }
    this._keys := []

    for k, v in this._data {
      val := ""
      if IsObject(v) {
        if v.HasOwnProp(this.lang)
          val := v.GetOwnPropDesc(this.lang)
        else
          val := v.GetOwnPropDesc("en")
      } else
        val := v

      ; Assign dynamic properties
      this.DefineProp(k, val)
      this._keys.Push(k)
    }
  }

  SetLanguage(lang) {
    this.lang := this._mapLang(lang)
    this._populate()
    return this
  }

  Reload(data := "") {
    if IsObject(data)
      this._data := data
    this._populate()
    return this
  }

  Get(key) {
    try return this[key]
    catch Error {
      return ""
    }
  }

  ToObject() {
    obj := {}
    for _, k in this._keys {
      obj[k] := this[k]
    }
    return obj
  }
}
