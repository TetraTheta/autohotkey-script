; Example
/*
c := OrderedMap()
c[3] := 7
c[2] := 9
c[7] := 1
c[1] := 22
c[78] := 52
OutputDebug(c[3])
OutputDebug(c[7])
OutputDebug(c[78])
c[7] := 985
OutputDebug(c[7])
OutputDebug(c.Count)

for k, x in c {
  OutputDebug(k '   ' x)
  c.Delete(k)
}
for k, x in c {
  OutputDebug(37)
}
OutputDebug(32)
*/

class OrderedMap extends Map {
  __New() {
    super.__New()
    this.eleFirst := this.eleLast := 0
  }

  class Ele {
  }

  __Enum(num) {
    EnHasNext := 1
    En := EnBegin

    return (ele := this.eleFirst) ? En%num% : noth
      static noth(*) => 0
      EnBegin() {
        En := EnNomal
      }
      EnNomal() {
        (ele0 := ele.next) ? (ele := ele0) : (EnHasNext := 0)
      }
      En1(&x) {
        En()
        x := ele.value
        return EnHasNext
      }
      En2(&ky, &x) {
        En()
        ky := ele.key
        x := ele.value
        return EnHasNext
      }
  }

  __Item[key] {
    get => super[key].value
    set {
      static prt := OrderedMap.Ele.Prototype
      (val0 := super.Get(key, 0)) ? (val0.value := Value) : (
        super.Count ? (
          prev := this.eleLast, ele := { prev: prev, next: 0, value: Value, key: key, base: prt }, super[key] := ele, this.eleLast := ele, prev.next := ele
        ) : (
          ele := { prev: 0, next: 0, value: Value, key: key, base: prt }, super[key] := ele, this.eleLast := this.eleFirst := ele
        )
      )
    }
  }

  Delete(key) {
    Dlt(ele) {
      pr := (prev := ele.prev) ? 1 : 0
      nx := (next := ele.next) ? 1 : 0

      f%pr nx%()

      f11() {
        prev.next := next
          , next.prev := prev
      }

      f01() {
        next.prev := 0
        this.eleFirst := next
      }

      f10() {
        prev.next := 0
        this.eleLast := prev
      }

      f00() {
        this.eleFirst := 0
        this.eleLast := 0
      }
    }

    Dlt(super.Delete(key))
  }

  Get(key, default?) => super.Get(key, default).value

  Set() {
    throw Error('not implemented yet')
  }
}
