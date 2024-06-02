class KeyValue {
  __New() {
    this.keys := []
    this.values := []
  }
  Add(key, value) {
    this.keys.Push(key)
    this.values.Push(value)
  }
  Get(key) {
    index := this.keys.Index.Has(key)
    if (index != 0) {
      return this.values[index]
    } else {
      throw IndexError("key not found")
    }
  }
  Length {
    Get {
      return this.keys.Length
    }
  }
}
