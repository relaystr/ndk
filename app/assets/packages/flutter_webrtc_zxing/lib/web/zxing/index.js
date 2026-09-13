import { p as pi, a as hi, r as _i, w as gi } from "../share.js";
import { Z as ki, b as Oi, c as Wi, e as ji, f as Ei, g as Di, d as Mi, i as Ui, h as Ii, l as Vi, m as Hi, t as Bi } from "../share.js";
async function _r(C = {}) {
  var A, N, gr, c = C, ke = !!globalThis.window, Oe = typeof Bun < "u", Dr = !!globalThis.WorkerGlobalScope;
  !((N = globalThis.process) === null || N === void 0 || (N = N.versions) === null || N === void 0) && N.node && ((gr = globalThis.process) === null || gr === void 0 ? void 0 : gr.type) != "renderer";
  var Mr = "./this.program", We, yr = "";
  function je(r) {
    return c.locateFile ? c.locateFile(r, yr) : yr + r;
  }
  var Ur, mr;
  if (ke || Dr || Oe) {
    try {
      yr = new URL(".", We).href;
    } catch {
    }
    Dr && (mr = (r) => {
      var e = new XMLHttpRequest();
      return e.open("GET", r, !1), e.responseType = "arraybuffer", e.send(null), new Uint8Array(e.response);
    }), Ur = async (r) => {
      var e = await fetch(r, {
        credentials: "same-origin"
      });
      if (e.ok)
        return e.arrayBuffer();
      throw new Error(e.status + " : " + e.url);
    };
  }
  var Ir = console.log.bind(console), x = console.error.bind(console), X, Vr = !1, Hr, Br, U, W, tr, G, q, m, Nr, xr, zr = !1;
  function Zr() {
    var r = dr.buffer;
    U = new Int8Array(r), tr = new Int16Array(r), c.HEAPU8 = W = new Uint8Array(r), G = new Uint16Array(r), q = new Int32Array(r), m = new Uint32Array(r), Nr = new Float32Array(r), xr = new Float64Array(r);
  }
  function Ee() {
    if (c.preRun)
      for (typeof c.preRun == "function" && (c.preRun = [c.preRun]); c.preRun.length; )
        Ze(c.preRun.shift());
    Lr(Gr);
  }
  function De() {
    zr = !0, rr.Da();
  }
  function Me() {
    if (c.postRun)
      for (typeof c.postRun == "function" && (c.postRun = [c.postRun]); c.postRun.length; )
        ze(c.postRun.shift());
    Lr(Xr);
  }
  function br(r) {
    var e, t;
    (e = c.onAbort) === null || e === void 0 || e.call(c, r), r = "Aborted(" + r + ")", x(r), Vr = !0, r += ". Build with -sASSERTIONS for more info.";
    var n = new WebAssembly.RuntimeError(r);
    throw (t = Br) === null || t === void 0 || t(n), n;
  }
  var z;
  function Ue() {
    return je("zxing_full.wasm");
  }
  function Ie(r) {
    if (r == z && X)
      return new Uint8Array(X);
    if (mr)
      return mr(r);
    throw "both async and sync fetching of the wasm failed";
  }
  async function Ve(r) {
    if (!X)
      try {
        var e = await Ur(r);
        return new Uint8Array(e);
      } catch {
      }
    return Ie(r);
  }
  async function He(r, e) {
    try {
      var t = await Ve(r), n = await WebAssembly.instantiate(t, e);
      return n;
    } catch (i) {
      x(`failed to asynchronously prepare wasm: ${i}`), br(i);
    }
  }
  async function Be(r, e, t) {
    if (!r && WebAssembly.instantiateStreaming)
      try {
        var n = fetch(e, {
          credentials: "same-origin"
        }), i = await WebAssembly.instantiateStreaming(n, t);
        return i;
      } catch (a) {
        x(`wasm streaming compile failed: ${a}`), x("falling back to ArrayBuffer instantiation");
      }
    return He(e, t);
  }
  function Ne() {
    var r = {
      a: kn
    };
    return r;
  }
  async function xe() {
    function r(a, s) {
      return rr = a.exports, Sn(rr), Zr(), rr;
    }
    function e(a) {
      return r(a.instance);
    }
    var t = Ne();
    if (c.instantiateWasm)
      return new Promise((a, s) => {
        c.instantiateWasm(t, (o, u) => {
          a(r(o));
        });
      });
    z != null || (z = Ue());
    var n = await Be(X, z, t), i = e(n);
    return i;
  }
  var Lr = (r) => {
    for (; r.length > 0; )
      r.shift()(c);
  }, Xr = [], ze = (r) => Xr.push(r), Gr = [], Ze = (r) => Gr.push(r), p = (r) => _e(r), h = () => ge(), nr = [], ir = 0, Le = (r) => {
    var e = new wr(r);
    return e.get_caught() || (e.set_caught(!0), ir--), e.set_rethrown(!1), nr.push(e), me(r), pe(r);
  }, j = 0, Xe = () => {
    d(0, 0);
    var r = nr.pop();
    ye(r.excPtr), j = 0;
  };
  class wr {
    constructor(e) {
      this.excPtr = e, this.ptr = e - 24;
    }
    set_type(e) {
      m[this.ptr + 4 >> 2] = e;
    }
    get_type() {
      return m[this.ptr + 4 >> 2];
    }
    set_destructor(e) {
      m[this.ptr + 8 >> 2] = e;
    }
    get_destructor() {
      return m[this.ptr + 8 >> 2];
    }
    set_caught(e) {
      e = e ? 1 : 0, U[this.ptr + 12] = e;
    }
    get_caught() {
      return U[this.ptr + 12] != 0;
    }
    set_rethrown(e) {
      e = e ? 1 : 0, U[this.ptr + 13] = e;
    }
    get_rethrown() {
      return U[this.ptr + 13] != 0;
    }
    init(e, t) {
      this.set_adjusted_ptr(0), this.set_type(e), this.set_destructor(t);
    }
    set_adjusted_ptr(e) {
      m[this.ptr + 16 >> 2] = e;
    }
    get_adjusted_ptr() {
      return m[this.ptr + 16 >> 2];
    }
  }
  var ar = (r) => he(r), $r = (r) => {
    var e = j;
    if (!e)
      return ar(0), 0;
    var t = new wr(e);
    t.set_adjusted_ptr(e);
    var n = t.get_type();
    if (!n)
      return ar(0), e;
    for (var i of r) {
      if (i === 0 || i === n)
        break;
      var a = t.ptr + 16;
      if (be(i, n, a))
        return ar(i), e;
    }
    return ar(n), e;
  }, Ge = () => $r([]), qe = (r) => $r([r]), Ye = (r, e) => $r([r, e]), Ke = () => {
    var r = nr.pop();
    r || br("no exception to throw");
    var e = r.excPtr;
    throw r.get_rethrown() || (nr.push(r), r.set_rethrown(!0), r.set_caught(!1), ir++), j = e, j;
  }, Je = (r, e, t) => {
    var n = new wr(r);
    throw n.init(e, t), j = r, ir++, j;
  }, Qe = () => ir, rt = (r) => {
    throw j || (j = r), j;
  }, qr = globalThis.TextDecoder && new TextDecoder(), Yr = (r, e, t, n) => {
    var i = e + t;
    if (n) return i;
    for (; r[e] && !(e >= i); ) ++e;
    return e;
  }, Kr = function(r) {
    let e = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : 0, t = arguments.length > 2 ? arguments[2] : void 0, n = arguments.length > 3 ? arguments[3] : void 0;
    var i = Yr(r, e, t, n);
    if (i - e > 16 && r.buffer && qr)
      return qr.decode(r.subarray(e, i));
    for (var a = ""; e < i; ) {
      var s = r[e++];
      if (!(s & 128)) {
        a += String.fromCharCode(s);
        continue;
      }
      var o = r[e++] & 63;
      if ((s & 224) == 192) {
        a += String.fromCharCode((s & 31) << 6 | o);
        continue;
      }
      var u = r[e++] & 63;
      if ((s & 240) == 224 ? s = (s & 15) << 12 | o << 6 | u : s = (s & 7) << 18 | o << 12 | u << 6 | r[e++] & 63, s < 65536)
        a += String.fromCharCode(s);
      else {
        var f = s - 65536;
        a += String.fromCharCode(55296 | f >> 10, 56320 | f & 1023);
      }
    }
    return a;
  }, et = (r, e, t) => r ? Kr(W, r, e, t) : "";
  function tt(r, e, t) {
    return 0;
  }
  function nt(r, e, t) {
    return 0;
  }
  var it = (r, e, t) => {
  };
  function at(r, e, t, n) {
  }
  var st = (r, e) => {
  }, ot = () => br(""), sr = {}, Tr = (r) => {
    for (; r.length; ) {
      var e = r.pop(), t = r.pop();
      t(e);
    }
  };
  function Y(r) {
    return this.fromWireType(m[r >> 2]);
  }
  var Z = {}, I = {}, or = {}, ut = class extends Error {
    constructor(e) {
      super(e), this.name = "InternalError";
    }
  }, ur = (r) => {
    throw new ut(r);
  }, V = (r, e, t) => {
    r.forEach((o) => or[o] = e);
    function n(o) {
      var u = t(o);
      u.length !== r.length && ur("Mismatched type converter count");
      for (var f = 0; f < r.length; ++f)
        k(r[f], u[f]);
    }
    var i = new Array(e.length), a = [], s = 0;
    {
      const o = e;
      for (let u = 0; u < o.length; ++u) {
        const f = o[u];
        I.hasOwnProperty(f) ? i[u] = I[f] : (a.push(f), Z.hasOwnProperty(f) || (Z[f] = []), Z[f].push(() => {
          i[u] = I[f], ++s, s === a.length && n(i);
        }));
      }
    }
    a.length === 0 && n(i);
  }, ft = (r) => {
    var e = sr[r];
    delete sr[r];
    var t = e.rawConstructor, n = e.rawDestructor, i = e.fields, a = i.map((s) => s.getterReturnType).concat(i.map((s) => s.setterArgumentType));
    V([r], a, (s) => {
      var o = {};
      {
        const u = i;
        for (let f = 0; f < u.length; ++f) {
          const l = u[f], v = s[f], y = l.getter, w = l.getterContext, P = s[f + i.length], T = l.setter, $ = l.setterContext;
          o[l.fieldName] = {
            read: (b) => v.fromWireType(y(w, b)),
            write: (b, B) => {
              var F = [];
              T($, b, P.toWireType(F, B)), Tr(F);
            },
            optional: v.optional
          };
        }
      }
      return [{
        name: e.name,
        fromWireType: (u) => {
          var f = {};
          for (var l in o)
            f[l] = o[l].read(u);
          return n(u), f;
        },
        toWireType: (u, f) => {
          for (var l in o)
            if (!(l in f) && !o[l].optional)
              throw new TypeError(`Missing field: "${l}"`);
          var v = t();
          for (l in o)
            o[l].write(v, f[l]);
          return u !== null && u.push(n, v), v;
        },
        readValueFromPointer: Y,
        destructorFunction: n
      }];
    });
  }, ct = (r, e, t, n, i) => {
  }, R = (r) => {
    for (var e = ""; ; ) {
      var t = W[r++];
      if (!t) return e;
      e += String.fromCharCode(t);
    }
  }, K = class extends Error {
    constructor(e) {
      super(e), this.name = "BindingError";
    }
  }, g = (r) => {
    throw new K(r);
  };
  function lt(r, e) {
    let t = arguments.length > 2 && arguments[2] !== void 0 ? arguments[2] : {};
    var n = e.name;
    if (r || g(`type "${n}" must have a positive integer typeid pointer`), I.hasOwnProperty(r)) {
      if (t.ignoreDuplicateRegistrations)
        return;
      g(`Cannot register type '${n}' twice`);
    }
    if (I[r] = e, delete or[r], Z.hasOwnProperty(r)) {
      var i = Z[r];
      delete Z[r], i.forEach((a) => a());
    }
  }
  function k(r, e) {
    let t = arguments.length > 2 && arguments[2] !== void 0 ? arguments[2] : {};
    return lt(r, e, t);
  }
  var vt = (r, e, t, n) => {
    e = R(e), k(r, {
      name: e,
      fromWireType: function(i) {
        return !!i;
      },
      toWireType: function(i, a) {
        return a ? t : n;
      },
      readValueFromPointer: function(i) {
        return this.fromWireType(W[i]);
      },
      destructorFunction: null
    });
  }, dt = (r) => ({
    count: r.count,
    deleteScheduled: r.deleteScheduled,
    preservePointerOnDelete: r.preservePointerOnDelete,
    ptr: r.ptr,
    ptrType: r.ptrType,
    smartPtr: r.smartPtr,
    smartPtrType: r.smartPtrType
  }), Pr = (r) => {
    function e(t) {
      return t.$$.ptrType.registeredClass.name;
    }
    g(e(r) + " instance already deleted");
  }, Cr = !1, Jr = (r) => {
  }, pt = (r) => {
    r.smartPtr ? r.smartPtrType.rawDestructor(r.smartPtr) : r.ptrType.registeredClass.rawDestructor(r.ptr);
  }, Qr = (r) => {
    r.count.value -= 1;
    var e = r.count.value === 0;
    e && pt(r);
  }, J = (r) => globalThis.FinalizationRegistry ? (Cr = new FinalizationRegistry((e) => {
    Qr(e.$$);
  }), J = (e) => {
    var t = e.$$, n = !!t.smartPtr;
    if (n) {
      var i = {
        $$: t
      };
      Cr.register(e, i, e);
    }
    return e;
  }, Jr = (e) => Cr.unregister(e), J(r)) : (J = (e) => e, r), ht = () => {
    let r = fr.prototype;
    Object.assign(r, {
      isAliasOf(t) {
        if (!(this instanceof fr) || !(t instanceof fr))
          return !1;
        var n = this.$$.ptrType.registeredClass, i = this.$$.ptr;
        t.$$ = t.$$;
        for (var a = t.$$.ptrType.registeredClass, s = t.$$.ptr; n.baseClass; )
          i = n.upcast(i), n = n.baseClass;
        for (; a.baseClass; )
          s = a.upcast(s), a = a.baseClass;
        return n === a && i === s;
      },
      clone() {
        if (this.$$.ptr || Pr(this), this.$$.preservePointerOnDelete)
          return this.$$.count.value += 1, this;
        var t = J(Object.create(Object.getPrototypeOf(this), {
          $$: {
            value: dt(this.$$)
          }
        }));
        return t.$$.count.value += 1, t.$$.deleteScheduled = !1, t;
      },
      delete() {
        this.$$.ptr || Pr(this), this.$$.deleteScheduled && !this.$$.preservePointerOnDelete && g("Object already scheduled for deletion"), Jr(this), Qr(this.$$), this.$$.preservePointerOnDelete || (this.$$.smartPtr = void 0, this.$$.ptr = void 0);
      },
      isDeleted() {
        return !this.$$.ptr;
      },
      deleteLater() {
        return this.$$.ptr || Pr(this), this.$$.deleteScheduled && !this.$$.preservePointerOnDelete && g("Object already scheduled for deletion"), this.$$.deleteScheduled = !0, this;
      }
    });
    const e = Symbol.dispose;
    e && (r[e] = r.delete);
  };
  function fr() {
  }
  var Rr = (r, e) => Object.defineProperty(e, "name", {
    value: r
  }), re = {}, ee = (r, e, t) => {
    if (r[e].overloadTable === void 0) {
      var n = r[e];
      r[e] = function() {
        for (var i = arguments.length, a = new Array(i), s = 0; s < i; s++)
          a[s] = arguments[s];
        return r[e].overloadTable.hasOwnProperty(a.length) || g(`Function '${t}' called with an invalid number of arguments (${a.length}) - expects one of (${r[e].overloadTable})!`), r[e].overloadTable[a.length].apply(this, a);
      }, r[e].overloadTable = [], r[e].overloadTable[n.argCount] = n;
    }
  }, te = (r, e, t) => {
    c.hasOwnProperty(r) ? ((t === void 0 || c[r].overloadTable !== void 0 && c[r].overloadTable[t] !== void 0) && g(`Cannot register public name '${r}' twice`), ee(c, r, r), c[r].overloadTable.hasOwnProperty(t) && g(`Cannot register multiple overloads of a function with the same number of arguments (${t})!`), c[r].overloadTable[t] = e) : (c[r] = e, c[r].argCount = t);
  }, _t = 48, gt = 57, yt = (r) => {
    r = r.replace(/[^a-zA-Z0-9_]/g, "$");
    var e = r.charCodeAt(0);
    return e >= _t && e <= gt ? `_${r}` : r;
  };
  function mt(r, e, t, n, i, a, s, o) {
    this.name = r, this.constructor = e, this.instancePrototype = t, this.rawDestructor = n, this.baseClass = i, this.getActualType = a, this.upcast = s, this.downcast = o, this.pureVirtualFunctions = [];
  }
  var Fr = (r, e, t) => {
    for (; e !== t; )
      e.upcast || g(`Expected null or instance of ${t.name}, got an instance of ${e.name}`), r = e.upcast(r), e = e.baseClass;
    return r;
  }, Ar = (r) => {
    if (r === null)
      return "null";
    var e = typeof r;
    return e === "object" || e === "array" || e === "function" ? r.toString() : "" + r;
  };
  function bt(r, e) {
    if (e === null)
      return this.isReference && g(`null is not a valid ${this.name}`), 0;
    e.$$ || g(`Cannot pass "${Ar(e)}" as a ${this.name}`), e.$$.ptr || g(`Cannot pass deleted object as a pointer of type ${this.name}`);
    var t = e.$$.ptrType.registeredClass, n = Fr(e.$$.ptr, t, this.registeredClass);
    return n;
  }
  function wt(r, e) {
    var t;
    if (e === null)
      return this.isReference && g(`null is not a valid ${this.name}`), this.isSmartPointer ? (t = this.rawConstructor(), r !== null && r.push(this.rawDestructor, t), t) : 0;
    (!e || !e.$$) && g(`Cannot pass "${Ar(e)}" as a ${this.name}`), e.$$.ptr || g(`Cannot pass deleted object as a pointer of type ${this.name}`), !this.isConst && e.$$.ptrType.isConst && g(`Cannot convert argument of type ${e.$$.smartPtrType ? e.$$.smartPtrType.name : e.$$.ptrType.name} to parameter type ${this.name}`);
    var n = e.$$.ptrType.registeredClass;
    if (t = Fr(e.$$.ptr, n, this.registeredClass), this.isSmartPointer)
      switch (e.$$.smartPtr === void 0 && g("Passing raw pointer to smart pointer is illegal"), this.sharingPolicy) {
        case 0:
          e.$$.smartPtrType === this ? t = e.$$.smartPtr : g(`Cannot convert argument of type ${e.$$.smartPtrType ? e.$$.smartPtrType.name : e.$$.ptrType.name} to parameter type ${this.name}`);
          break;
        case 1:
          t = e.$$.smartPtr;
          break;
        case 2:
          if (e.$$.smartPtrType === this)
            t = e.$$.smartPtr;
          else {
            var i = e.clone();
            t = this.rawShare(t, O.toHandle(() => i.delete())), r !== null && r.push(this.rawDestructor, t);
          }
          break;
        default:
          g("Unsupporting sharing policy");
      }
    return t;
  }
  function $t(r, e) {
    if (e === null)
      return this.isReference && g(`null is not a valid ${this.name}`), 0;
    e.$$ || g(`Cannot pass "${Ar(e)}" as a ${this.name}`), e.$$.ptr || g(`Cannot pass deleted object as a pointer of type ${this.name}`), e.$$.ptrType.isConst && g(`Cannot convert argument of type ${e.$$.ptrType.name} to parameter type ${this.name}`);
    var t = e.$$.ptrType.registeredClass, n = Fr(e.$$.ptr, t, this.registeredClass);
    return n;
  }
  var ne = (r, e, t) => {
    if (e === t)
      return r;
    if (t.baseClass === void 0)
      return null;
    var n = ne(r, e, t.baseClass);
    return n === null ? null : t.downcast(n);
  }, Tt = {}, Pt = (r, e) => {
    for (e === void 0 && g("ptr should not be undefined"); r.baseClass; )
      e = r.upcast(e), r = r.baseClass;
    return e;
  }, Ct = (r, e) => (e = Pt(r, e), Tt[e]), cr = (r, e) => {
    (!e.ptrType || !e.ptr) && ur("makeClassHandle requires ptr and ptrType");
    var t = !!e.smartPtrType, n = !!e.smartPtr;
    return t !== n && ur("Both smartPtrType and smartPtr must be specified"), e.count = {
      value: 1
    }, J(Object.create(r, {
      $$: {
        value: e,
        writable: !0
      }
    }));
  };
  function Rt(r) {
    var e = this.getPointee(r);
    if (!e)
      return this.destructor(r), null;
    var t = Ct(this.registeredClass, e);
    if (t !== void 0) {
      if (t.$$.count.value === 0)
        return t.$$.ptr = e, t.$$.smartPtr = r, t.clone();
      var n = t.clone();
      return this.destructor(r), n;
    }
    function i() {
      return this.isSmartPointer ? cr(this.registeredClass.instancePrototype, {
        ptrType: this.pointeeType,
        ptr: e,
        smartPtrType: this,
        smartPtr: r
      }) : cr(this.registeredClass.instancePrototype, {
        ptrType: this,
        ptr: r
      });
    }
    var a = this.registeredClass.getActualType(e), s = re[a];
    if (!s)
      return i.call(this);
    var o;
    this.isConst ? o = s.constPointerType : o = s.pointerType;
    var u = ne(e, this.registeredClass, o.registeredClass);
    return u === null ? i.call(this) : this.isSmartPointer ? cr(o.registeredClass.instancePrototype, {
      ptrType: o,
      ptr: u,
      smartPtrType: this,
      smartPtr: r
    }) : cr(o.registeredClass.instancePrototype, {
      ptrType: o,
      ptr: u
    });
  }
  var Ft = () => {
    Object.assign(lr.prototype, {
      getPointee(r) {
        return this.rawGetPointee && (r = this.rawGetPointee(r)), r;
      },
      destructor(r) {
        var e;
        (e = this.rawDestructor) === null || e === void 0 || e.call(this, r);
      },
      readValueFromPointer: Y,
      fromWireType: Rt
    });
  };
  function lr(r, e, t, n, i, a, s, o, u, f, l) {
    this.name = r, this.registeredClass = e, this.isReference = t, this.isConst = n, this.isSmartPointer = i, this.pointeeType = a, this.sharingPolicy = s, this.rawGetPointee = o, this.rawConstructor = u, this.rawShare = f, this.rawDestructor = l, !i && e.baseClass === void 0 ? n ? (this.toWireType = bt, this.destructorFunction = null) : (this.toWireType = $t, this.destructorFunction = null) : this.toWireType = wt;
  }
  var ie = (r, e, t) => {
    c.hasOwnProperty(r) || ur("Replacing nonexistent public symbol"), c[r].overloadTable !== void 0 && t !== void 0 ? c[r].overloadTable[t] = e : (c[r] = e, c[r].argCount = t);
  }, D = {}, At = (r, e, t) => {
    r = r.replace(/p/g, "i");
    var n = D[r];
    return n(e, ...t);
  }, ae = [], _ = (r) => {
    var e = ae[r];
    return e || (ae[r] = e = Te.get(r)), e;
  }, St = function(r, e) {
    let t = arguments.length > 2 && arguments[2] !== void 0 ? arguments[2] : [];
    if (r.includes("j"))
      return At(r, e, t);
    var n = _(e), i = n(...t);
    function a(s) {
      return s;
    }
    return i;
  }, kt = function(r, e) {
    let t = arguments.length > 2 && arguments[2] !== void 0 ? arguments[2] : !1;
    return function() {
      for (var n = arguments.length, i = new Array(n), a = 0; a < n; a++)
        i[a] = arguments[a];
      return St(r, e, i, t);
    };
  }, S = function(r, e) {
    r = R(r);
    function t() {
      if (r.includes("j"))
        return kt(r, e);
      var i = _(e);
      return i;
    }
    var n = t();
    return typeof n != "function" && g(`unknown function pointer with signature ${r}: ${e}`), n;
  };
  class Ot extends Error {
  }
  var se = (r) => {
    var e = de(r), t = R(e);
    return M(e), t;
  }, vr = (r, e) => {
    var t = [], n = {};
    function i(a) {
      if (!n[a] && !I[a]) {
        if (or[a]) {
          or[a].forEach(i);
          return;
        }
        t.push(a), n[a] = !0;
      }
    }
    throw e.forEach(i), new Ot(`${r}: ` + t.map(se).join([", "]));
  }, Wt = (r, e, t, n, i, a, s, o, u, f, l, v, y) => {
    l = R(l), a = S(i, a), o && (o = S(s, o)), f && (f = S(u, f)), y = S(v, y);
    var w = yt(l);
    te(w, function() {
      vr(`Cannot construct ${l} due to unbound types`, [n]);
    }), V([r, e, t], n ? [n] : [], (P) => {
      P = P[0];
      var T, $;
      n ? (T = P.registeredClass, $ = T.instancePrototype) : $ = fr.prototype;
      var b = Rr(l, function() {
        if (Object.getPrototypeOf(this) !== B)
          throw new K(`Use 'new' to construct ${l}`);
        if (F.constructor_body === void 0)
          throw new K(`${l} has no accessible constructor`);
        for (var Re = arguments.length, pr = new Array(Re), hr = 0; hr < Re; hr++)
          pr[hr] = arguments[hr];
        var Fe = F.constructor_body[pr.length];
        if (Fe === void 0)
          throw new K(`Tried to invoke ctor of ${l} with invalid number of parameters (${pr.length}) - expected (${Object.keys(F.constructor_body).toString()}) parameters instead!`);
        return Fe.apply(this, pr);
      }), B = Object.create($, {
        constructor: {
          value: b
        }
      });
      b.prototype = B;
      var F = new mt(l, b, B, y, T, a, o, f);
      if (F.baseClass) {
        var E, er;
        (er = (E = F.baseClass).__derivedClasses) !== null && er !== void 0 || (E.__derivedClasses = []), F.baseClass.__derivedClasses.push(F);
      }
      var di = new lr(l, F, !0, !1, !1), Pe = new lr(l + "*", F, !1, !1, !1), Ce = new lr(l + " const*", F, !1, !0, !1);
      return re[r] = {
        pointerType: Pe,
        constPointerType: Ce
      }, ie(w, b), [di, Pe, Ce];
    });
  }, Sr = (r, e) => {
    for (var t = [], n = 0; n < r; n++)
      t.push(m[e + n * 4 >> 2]);
    return t;
  };
  function jt(r) {
    for (var e = 1; e < r.length; ++e)
      if (r[e] !== null && r[e].destructorFunction === void 0)
        return !0;
    return !1;
  }
  function kr(r, e, t, n, i, a) {
    var s = e.length;
    s < 2 && g("argTypes array size mismatch! Must at least get return value and 'this' types!");
    var o = e[1] !== null && t !== null, u = jt(e), f = !e[0].isVoid, l = s - 2, v = new Array(l), y = [], w = [], P = function() {
      w.length = 0;
      var T;
      y.length = o ? 2 : 1, y[0] = i, o && (T = e[1].toWireType(w, this), y[1] = T);
      for (var $ = 0; $ < l; ++$)
        v[$] = e[$ + 2].toWireType(w, $ < 0 || arguments.length <= $ ? void 0 : arguments[$]), y.push(v[$]);
      var b = n(...y);
      function B(F) {
        if (u)
          Tr(w);
        else
          for (var E = o ? 1 : 2; E < e.length; E++) {
            var er = E === 1 ? T : v[E - 2];
            e[E].destructorFunction !== null && e[E].destructorFunction(er);
          }
        if (f)
          return e[0].fromWireType(F);
      }
      return B(b);
    };
    return Rr(r, P);
  }
  var Et = (r, e, t, n, i, a) => {
    var s = Sr(e, t);
    i = S(n, i), V([], [r], (o) => {
      o = o[0];
      var u = `constructor ${o.name}`;
      if (o.registeredClass.constructor_body === void 0 && (o.registeredClass.constructor_body = []), o.registeredClass.constructor_body[e - 1] !== void 0)
        throw new K(`Cannot register multiple constructors with identical number of parameters (${e - 1}) for class '${o.name}'! Overload resolution is currently only performed using the parameter count, not actual type info!`);
      return o.registeredClass.constructor_body[e - 1] = () => {
        vr(`Cannot construct ${o.name} due to unbound types`, s);
      }, V([], s, (f) => (f.splice(1, 0, null), o.registeredClass.constructor_body[e - 1] = kr(u, f, null, i, a), [])), [];
    });
  }, oe = (r) => {
    r = r.trim();
    const e = r.indexOf("(");
    return e === -1 ? r : r.slice(0, e);
  }, Dt = (r, e, t, n, i, a, s, o, u, f) => {
    var l = Sr(t, n);
    e = R(e), e = oe(e), a = S(i, a), V([], [r], (v) => {
      v = v[0];
      var y = `${v.name}.${e}`;
      e.startsWith("@@") && (e = Symbol[e.substring(2)]), o && v.registeredClass.pureVirtualFunctions.push(e);
      function w() {
        vr(`Cannot call ${y} due to unbound types`, l);
      }
      var P = v.registeredClass.instancePrototype, T = P[e];
      return T === void 0 || T.overloadTable === void 0 && T.className !== v.name && T.argCount === t - 2 ? (w.argCount = t - 2, w.className = v.name, P[e] = w) : (ee(P, e, y), P[e].overloadTable[t - 2] = w), V([], l, ($) => {
        var b = kr(y, $, v, a, s);
        return P[e].overloadTable === void 0 ? (b.argCount = t - 2, P[e] = b) : P[e].overloadTable[t - 2] = b, [];
      }), [];
    });
  }, ue = [], H = [0, 1, , 1, null, 1, !0, 1, !1, 1], Or = (r) => {
    r > 9 && --H[r + 1] === 0 && (H[r] = void 0, ue.push(r));
  }, O = {
    toValue: (r) => (r || g(`Cannot use deleted val. handle = ${r}`), H[r]),
    toHandle: (r) => {
      switch (r) {
        case void 0:
          return 2;
        case null:
          return 4;
        case !0:
          return 6;
        case !1:
          return 8;
        default: {
          const e = ue.pop() || H.length;
          return H[e] = r, H[e + 1] = 1, e;
        }
      }
    }
  }, fe = {
    name: "emscripten::val",
    fromWireType: (r) => {
      var e = O.toValue(r);
      return Or(r), e;
    },
    toWireType: (r, e) => O.toHandle(e),
    readValueFromPointer: Y,
    destructorFunction: null
  }, Mt = (r) => k(r, fe), Ut = (r, e) => {
    switch (e) {
      case 4:
        return function(t) {
          return this.fromWireType(Nr[t >> 2]);
        };
      case 8:
        return function(t) {
          return this.fromWireType(xr[t >> 3]);
        };
      default:
        throw new TypeError(`invalid float width (${e}): ${r}`);
    }
  }, It = (r, e, t) => {
    e = R(e), k(r, {
      name: e,
      fromWireType: (n) => n,
      toWireType: (n, i) => i,
      readValueFromPointer: Ut(e, t),
      destructorFunction: null
    });
  }, Vt = (r, e, t, n, i, a, s, o) => {
    var u = Sr(e, t);
    r = R(r), r = oe(r), i = S(n, i), te(r, function() {
      vr(`Cannot call ${r} due to unbound types`, u);
    }, e - 1), V([], u, (f) => {
      var l = [f[0], null].concat(f.slice(1));
      return ie(r, kr(r, l, null, i, a), e - 1), [];
    });
  }, Ht = (r, e, t) => {
    switch (e) {
      case 1:
        return t ? (n) => U[n] : (n) => W[n];
      case 2:
        return t ? (n) => tr[n >> 1] : (n) => G[n >> 1];
      case 4:
        return t ? (n) => q[n >> 2] : (n) => m[n >> 2];
      default:
        throw new TypeError(`invalid integer width (${e}): ${r}`);
    }
  }, Bt = (r, e, t, n, i) => {
    e = R(e);
    const a = n === 0;
    let s = (u) => u;
    if (a) {
      var o = 32 - 8 * t;
      s = (u) => u << o >>> o, i = s(i);
    }
    k(r, {
      name: e,
      fromWireType: s,
      toWireType: (u, f) => f,
      readValueFromPointer: Ht(e, t, n !== 0),
      destructorFunction: null
    });
  }, Nt = (r, e, t) => {
    var n = [Int8Array, Uint8Array, Int16Array, Uint16Array, Int32Array, Uint32Array, Float32Array, Float64Array], i = n[e];
    function a(s) {
      var o = m[s >> 2], u = m[s + 4 >> 2];
      return new i(U.buffer, u, o);
    }
    t = R(t), k(r, {
      name: t,
      fromWireType: a,
      readValueFromPointer: a
    }, {
      ignoreDuplicateRegistrations: !0
    });
  }, xt = Object.assign({
    optional: !0
  }, fe), zt = (r, e) => {
    k(r, xt);
  }, Zt = (r, e, t, n) => {
    if (!(n > 0)) return 0;
    for (var i = t, a = t + n - 1, s = 0; s < r.length; ++s) {
      var o = r.codePointAt(s);
      if (o <= 127) {
        if (t >= a) break;
        e[t++] = o;
      } else if (o <= 2047) {
        if (t + 1 >= a) break;
        e[t++] = 192 | o >> 6, e[t++] = 128 | o & 63;
      } else if (o <= 65535) {
        if (t + 2 >= a) break;
        e[t++] = 224 | o >> 12, e[t++] = 128 | o >> 6 & 63, e[t++] = 128 | o & 63;
      } else {
        if (t + 3 >= a) break;
        e[t++] = 240 | o >> 18, e[t++] = 128 | o >> 12 & 63, e[t++] = 128 | o >> 6 & 63, e[t++] = 128 | o & 63, s++;
      }
    }
    return e[t] = 0, t - i;
  }, L = (r, e, t) => Zt(r, W, e, t), ce = (r) => {
    for (var e = 0, t = 0; t < r.length; ++t) {
      var n = r.charCodeAt(t);
      n <= 127 ? e++ : n <= 2047 ? e += 2 : n >= 55296 && n <= 57343 ? (e += 4, ++t) : e += 3;
    }
    return e;
  }, Lt = (r, e) => {
    e = R(e), k(r, {
      name: e,
      fromWireType(t) {
        var n = m[t >> 2], i = t + 4, a;
        return a = et(i, n, !0), M(t), a;
      },
      toWireType(t, n) {
        n instanceof ArrayBuffer && (n = new Uint8Array(n));
        var i, a = typeof n == "string";
        a || ArrayBuffer.isView(n) && n.BYTES_PER_ELEMENT == 1 || g("Cannot pass non-string to std::string"), a ? i = ce(n) : i = n.length;
        var s = Er(4 + i + 1), o = s + 4;
        return m[s >> 2] = i, a ? L(n, o, i + 1) : W.set(n, o), t !== null && t.push(M, s), s;
      },
      readValueFromPointer: Y,
      destructorFunction(t) {
        M(t);
      }
    });
  }, le = globalThis.TextDecoder ? new TextDecoder("utf-16le") : void 0, Xt = (r, e, t) => {
    var n = r >> 1, i = Yr(G, n, e / 2, t);
    if (i - n > 16 && le) return le.decode(G.subarray(n, i));
    for (var a = "", s = n; s < i; ++s) {
      var o = G[s];
      a += String.fromCharCode(o);
    }
    return a;
  }, Gt = (r, e, t) => {
    if (t != null || (t = 2147483647), t < 2) return 0;
    t -= 2;
    for (var n = e, i = t < r.length * 2 ? t / 2 : r.length, a = 0; a < i; ++a) {
      var s = r.charCodeAt(a);
      tr[e >> 1] = s, e += 2;
    }
    return tr[e >> 1] = 0, e - n;
  }, qt = (r) => r.length * 2, Yt = (r, e, t) => {
    for (var n = "", i = r >> 2, a = 0; !(a >= e / 4); a++) {
      var s = m[i + a];
      if (!s && !t) break;
      n += String.fromCodePoint(s);
    }
    return n;
  }, Kt = (r, e, t) => {
    if (t != null || (t = 2147483647), t < 4) return 0;
    for (var n = e, i = n + t - 4, a = 0; a < r.length; ++a) {
      var s = r.codePointAt(a);
      if (s > 65535 && a++, q[e >> 2] = s, e += 4, e + 4 > i) break;
    }
    return q[e >> 2] = 0, e - n;
  }, Jt = (r) => {
    for (var e = 0, t = 0; t < r.length; ++t) {
      var n = r.codePointAt(t);
      n > 65535 && t++, e += 4;
    }
    return e;
  }, Qt = (r, e, t) => {
    t = R(t);
    var n, i, a;
    e === 2 ? (n = Xt, i = Gt, a = qt) : (n = Yt, i = Kt, a = Jt), k(r, {
      name: t,
      fromWireType: (s) => {
        var o = m[s >> 2], u = n(s + 4, o * e, !0);
        return M(s), u;
      },
      toWireType: (s, o) => {
        typeof o != "string" && g(`Cannot pass non-string to C++ string type ${t}`);
        var u = a(o), f = Er(4 + u + e);
        return m[f >> 2] = u / e, i(o, f + 4, u + e), s !== null && s.push(M, f), f;
      },
      readValueFromPointer: Y,
      destructorFunction(s) {
        M(s);
      }
    });
  }, rn = (r, e, t, n, i, a) => {
    sr[r] = {
      name: R(e),
      rawConstructor: S(t, n),
      rawDestructor: S(i, a),
      fields: []
    };
  }, en = (r, e, t, n, i, a, s, o, u, f) => {
    sr[r].fields.push({
      fieldName: R(e),
      getterReturnType: t,
      getter: S(n, i),
      getterContext: a,
      setterArgumentType: s,
      setter: S(o, u),
      setterContext: f
    });
  }, tn = (r, e) => {
    e = R(e), k(r, {
      isVoid: !0,
      name: e,
      fromWireType: () => {
      },
      toWireType: (t, n) => {
      }
    });
  }, Wr = [], nn = (r) => {
    var e = Wr.length;
    return Wr.push(r), e;
  }, an = (r, e) => {
    var t = I[r];
    return t === void 0 && g(`${e} has unknown type ${se(r)}`), t;
  }, sn = (r, e) => {
    for (var t = new Array(r), n = 0; n < r; ++n)
      t[n] = an(m[e + n * 4 >> 2], `parameter ${n}`);
    return t;
  }, on = (r, e, t) => {
    var n = [], i = r(n, t);
    return n.length && (m[e >> 2] = O.toHandle(n)), i;
  }, un = {}, ve = (r) => {
    var e = un[r];
    return e === void 0 ? R(r) : e;
  }, fn = (r, e, t) => {
    var n = 8, [i, ...a] = sn(r, e), s = i.toWireType.bind(i), o = a.map((v) => v.readValueFromPointer.bind(v));
    r--;
    var u = new Array(r), f = (v, y, w, P) => {
      for (var T = 0, $ = 0; $ < r; ++$)
        u[$] = o[$](P + T), T += n;
      var b;
      switch (t) {
        case 0:
          b = O.toValue(v).apply(null, u);
          break;
        case 2:
          b = Reflect.construct(O.toValue(v), u);
          break;
        case 3:
          b = u[0];
          break;
        case 1:
          b = O.toValue(v)[ve(y)](...u);
          break;
      }
      return on(s, w, b);
    }, l = `methodCaller<(${a.map((v) => v.name)}) => ${i.name}>`;
    return nn(Rr(l, f));
  }, cn = (r) => r ? (r = ve(r), O.toHandle(globalThis[r])) : O.toHandle(globalThis), ln = (r) => {
    r > 9 && (H[r + 1] += 1);
  }, vn = (r, e, t, n, i) => Wr[r](e, t, n, i), dn = (r) => {
    var e = O.toValue(r);
    Tr(e), Or(r);
  }, pn = (r, e, t, n) => {
    var i = (/* @__PURE__ */ new Date()).getFullYear(), a = new Date(i, 0, 1), s = new Date(i, 6, 1), o = a.getTimezoneOffset(), u = s.getTimezoneOffset(), f = Math.max(o, u);
    m[r >> 2] = f * 60, q[e >> 2] = +(o != u);
    var l = (w) => {
      var P = w >= 0 ? "-" : "+", T = Math.abs(w), $ = String(Math.floor(T / 60)).padStart(2, "0"), b = String(T % 60).padStart(2, "0");
      return `UTC${P}${$}${b}`;
    }, v = l(o), y = l(u);
    u < o ? (L(v, t, 17), L(y, n, 17)) : (L(v, n, 17), L(y, t, 17));
  }, hn = () => 2147483648, _n = (r, e) => Math.ceil(r / e) * e, gn = (r) => {
    var e = dr.buffer.byteLength, t = (r - e + 65535) / 65536 | 0;
    try {
      return dr.grow(t), Zr(), 1;
    } catch {
    }
  }, yn = (r) => {
    var e = W.length;
    r >>>= 0;
    var t = hn();
    if (r > t)
      return !1;
    for (var n = 1; n <= 4; n *= 2) {
      var i = e * (1 + 0.2 / n);
      i = Math.min(i, r + 100663296);
      var a = Math.min(t, _n(Math.max(r, i), 65536)), s = gn(a);
      if (s)
        return !0;
    }
    return !1;
  }, jr = {}, mn = () => Mr || "./this.program", Q = () => {
    if (!Q.strings) {
      var r = (typeof navigator == "object" && navigator.language || "C").replace("-", "_") + ".UTF-8", e = {
        USER: "web_user",
        LOGNAME: "web_user",
        PATH: "/",
        PWD: "/",
        HOME: "/home/web_user",
        LANG: r,
        _: mn()
      };
      for (var t in jr)
        jr[t] === void 0 ? delete e[t] : e[t] = jr[t];
      var n = [];
      for (var t in e)
        n.push(`${t}=${e[t]}`);
      Q.strings = n;
    }
    return Q.strings;
  }, bn = (r, e) => {
    var t = 0, n = 0;
    for (var i of Q()) {
      var a = e + t;
      m[r + n >> 2] = a, t += L(i, a, 1 / 0) + 1, n += 4;
    }
    return 0;
  }, wn = (r, e) => {
    var t = Q();
    m[r >> 2] = t.length;
    var n = 0;
    for (var i of t)
      n += ce(i) + 1;
    return m[e >> 2] = n, 0;
  }, $n = (r) => 52, Tn = (r, e, t, n) => 52;
  function Pn(r, e, t, n, i) {
    return 70;
  }
  var Cn = [null, [], []], Rn = (r, e) => {
    var t = Cn[r];
    e === 0 || e === 10 ? ((r === 1 ? Ir : x)(Kr(t)), t.length = 0) : t.push(e);
  }, Fn = (r, e, t, n) => {
    for (var i = 0, a = 0; a < t; a++) {
      var s = m[e >> 2], o = m[e + 4 >> 2];
      e += 8;
      for (var u = 0; u < o; u++)
        Rn(r, W[s + u]);
      i += o;
    }
    return m[n >> 2] = i, 0;
  }, An = (r) => r;
  if (ht(), Ft(), c.noExitRuntime && c.noExitRuntime, c.print && (Ir = c.print), c.printErr && (x = c.printErr), c.wasmBinary && (X = c.wasmBinary), c.arguments && c.arguments, c.thisProgram && (Mr = c.thisProgram), c.preInit)
    for (typeof c.preInit == "function" && (c.preInit = [c.preInit]); c.preInit.length > 0; )
      c.preInit.shift()();
  var de, M, Er, pe, d, he, _e, ge, ye, me, be, we, $e, dr, Te;
  function Sn(r) {
    de = r.Ea, M = c._free = r.Fa, Er = c._malloc = r.Ha, pe = r.Ia, d = r.Ja, he = r.Ka, _e = r.La, ge = r.Ma, ye = r.Na, me = r.Oa, be = r.Pa, D.viijii = r.Qa, we = D.iiijj = r.Ra, D.jiji = r.Sa, $e = D.jiiii = r.Ta, D.iiiiij = r.Ua, D.iiiiijj = r.Va, D.iiiiiijj = r.Wa, dr = r.Ca, Te = r.Ga;
  }
  var kn = {
    s: Le,
    v: Xe,
    a: Ge,
    j: qe,
    m: Ye,
    S: Ke,
    q: Je,
    W: Qe,
    d: rt,
    Z: tt,
    ma: nt,
    ka: it,
    na: at,
    ja: st,
    ea: ot,
    za: ft,
    da: ct,
    ua: vt,
    xa: Wt,
    wa: Et,
    I: Dt,
    sa: Mt,
    $: It,
    O: Vt,
    y: Bt,
    t: Nt,
    ya: zt,
    ta: Lt,
    T: Qt,
    C: rn,
    Aa: en,
    va: tn,
    N: fn,
    Ba: Or,
    F: cn,
    U: ln,
    M: vn,
    oa: dn,
    fa: pn,
    ia: yn,
    ga: bn,
    ha: wn,
    X: $n,
    la: Tn,
    ba: Pn,
    Y: Fn,
    K: Qn,
    D: ti,
    P: Un,
    V: ui,
    r: qn,
    b: Dn,
    G: Jn,
    qa: ii,
    c: In,
    pa: ai,
    h: Mn,
    i: Bn,
    p: Zn,
    R: Kn,
    w: Xn,
    E: Gn,
    L: Yn,
    z: ni,
    J: fi,
    ca: ci,
    aa: li,
    g: Vn,
    k: On,
    e: En,
    f: jn,
    Q: oi,
    l: Wn,
    ra: ri,
    o: Ln,
    A: Nn,
    u: ei,
    _: zn,
    B: si,
    n: Hn,
    H: xn,
    x: An
  };
  function On(r, e) {
    var t = h();
    try {
      _(r)(e);
    } catch (n) {
      if (p(t), n !== n + 0) throw n;
      d(1, 0);
    }
  }
  function Wn(r, e, t, n, i) {
    var a = h();
    try {
      _(r)(e, t, n, i);
    } catch (s) {
      if (p(a), s !== s + 0) throw s;
      d(1, 0);
    }
  }
  function jn(r, e, t, n) {
    var i = h();
    try {
      _(r)(e, t, n);
    } catch (a) {
      if (p(i), a !== a + 0) throw a;
      d(1, 0);
    }
  }
  function En(r, e, t) {
    var n = h();
    try {
      _(r)(e, t);
    } catch (i) {
      if (p(n), i !== i + 0) throw i;
      d(1, 0);
    }
  }
  function Dn(r, e) {
    var t = h();
    try {
      return _(r)(e);
    } catch (n) {
      if (p(t), n !== n + 0) throw n;
      d(1, 0);
    }
  }
  function Mn(r, e, t, n) {
    var i = h();
    try {
      return _(r)(e, t, n);
    } catch (a) {
      if (p(i), a !== a + 0) throw a;
      d(1, 0);
    }
  }
  function Un(r, e, t, n, i, a) {
    var s = h();
    try {
      return _(r)(e, t, n, i, a);
    } catch (o) {
      if (p(s), o !== o + 0) throw o;
      d(1, 0);
    }
  }
  function In(r, e, t) {
    var n = h();
    try {
      return _(r)(e, t);
    } catch (i) {
      if (p(n), i !== i + 0) throw i;
      d(1, 0);
    }
  }
  function Vn(r) {
    var e = h();
    try {
      _(r)();
    } catch (t) {
      if (p(e), t !== t + 0) throw t;
      d(1, 0);
    }
  }
  function Hn(r, e, t, n, i, a, s, o, u, f, l) {
    var v = h();
    try {
      _(r)(e, t, n, i, a, s, o, u, f, l);
    } catch (y) {
      if (p(v), y !== y + 0) throw y;
      d(1, 0);
    }
  }
  function Bn(r, e, t, n, i) {
    var a = h();
    try {
      return _(r)(e, t, n, i);
    } catch (s) {
      if (p(a), s !== s + 0) throw s;
      d(1, 0);
    }
  }
  function Nn(r, e, t, n, i, a, s) {
    var o = h();
    try {
      _(r)(e, t, n, i, a, s);
    } catch (u) {
      if (p(o), u !== u + 0) throw u;
      d(1, 0);
    }
  }
  function xn(r, e, t, n, i, a, s, o, u, f, l, v, y, w, P, T) {
    var $ = h();
    try {
      _(r)(e, t, n, i, a, s, o, u, f, l, v, y, w, P, T);
    } catch (b) {
      if (p($), b !== b + 0) throw b;
      d(1, 0);
    }
  }
  function zn(r, e, t, n, i, a, s, o, u) {
    var f = h();
    try {
      _(r)(e, t, n, i, a, s, o, u);
    } catch (l) {
      if (p(f), l !== l + 0) throw l;
      d(1, 0);
    }
  }
  function Zn(r, e, t, n, i, a) {
    var s = h();
    try {
      return _(r)(e, t, n, i, a);
    } catch (o) {
      if (p(s), o !== o + 0) throw o;
      d(1, 0);
    }
  }
  function Ln(r, e, t, n, i, a) {
    var s = h();
    try {
      _(r)(e, t, n, i, a);
    } catch (o) {
      if (p(s), o !== o + 0) throw o;
      d(1, 0);
    }
  }
  function Xn(r, e, t, n, i, a, s) {
    var o = h();
    try {
      return _(r)(e, t, n, i, a, s);
    } catch (u) {
      if (p(o), u !== u + 0) throw u;
      d(1, 0);
    }
  }
  function Gn(r, e, t, n, i, a, s, o) {
    var u = h();
    try {
      return _(r)(e, t, n, i, a, s, o);
    } catch (f) {
      if (p(u), f !== f + 0) throw f;
      d(1, 0);
    }
  }
  function qn(r) {
    var e = h();
    try {
      return _(r)();
    } catch (t) {
      if (p(e), t !== t + 0) throw t;
      d(1, 0);
    }
  }
  function Yn(r, e, t, n, i, a, s, o, u) {
    var f = h();
    try {
      return _(r)(e, t, n, i, a, s, o, u);
    } catch (l) {
      if (p(f), l !== l + 0) throw l;
      d(1, 0);
    }
  }
  function Kn(r, e, t, n, i, a, s) {
    var o = h();
    try {
      return _(r)(e, t, n, i, a, s);
    } catch (u) {
      if (p(o), u !== u + 0) throw u;
      d(1, 0);
    }
  }
  function Jn(r, e, t, n) {
    var i = h();
    try {
      return _(r)(e, t, n);
    } catch (a) {
      if (p(i), a !== a + 0) throw a;
      d(1, 0);
    }
  }
  function Qn(r, e, t, n) {
    var i = h();
    try {
      return _(r)(e, t, n);
    } catch (a) {
      if (p(i), a !== a + 0) throw a;
      d(1, 0);
    }
  }
  function ri(r, e, t, n, i, a, s, o) {
    var u = h();
    try {
      _(r)(e, t, n, i, a, s, o);
    } catch (f) {
      if (p(u), f !== f + 0) throw f;
      d(1, 0);
    }
  }
  function ei(r, e, t, n, i, a, s, o) {
    var u = h();
    try {
      _(r)(e, t, n, i, a, s, o);
    } catch (f) {
      if (p(u), f !== f + 0) throw f;
      d(1, 0);
    }
  }
  function ti(r, e, t, n, i, a) {
    var s = h();
    try {
      return _(r)(e, t, n, i, a);
    } catch (o) {
      if (p(s), o !== o + 0) throw o;
      d(1, 0);
    }
  }
  function ni(r, e, t, n, i, a, s, o, u, f) {
    var l = h();
    try {
      return _(r)(e, t, n, i, a, s, o, u, f);
    } catch (v) {
      if (p(l), v !== v + 0) throw v;
      d(1, 0);
    }
  }
  function ii(r, e, t) {
    var n = h();
    try {
      return _(r)(e, t);
    } catch (i) {
      if (p(n), i !== i + 0) throw i;
      d(1, 0);
    }
  }
  function ai(r, e, t, n, i) {
    var a = h();
    try {
      return _(r)(e, t, n, i);
    } catch (s) {
      if (p(a), s !== s + 0) throw s;
      d(1, 0);
    }
  }
  function si(r, e, t, n, i, a, s, o, u, f) {
    var l = h();
    try {
      _(r)(e, t, n, i, a, s, o, u, f);
    } catch (v) {
      if (p(l), v !== v + 0) throw v;
      d(1, 0);
    }
  }
  function oi(r, e, t, n, i, a, s) {
    var o = h();
    try {
      _(r)(e, t, n, i, a, s);
    } catch (u) {
      if (p(o), u !== u + 0) throw u;
      d(1, 0);
    }
  }
  function ui(r, e, t, n) {
    var i = h();
    try {
      return _(r)(e, t, n);
    } catch (a) {
      if (p(i), a !== a + 0) throw a;
      d(1, 0);
    }
  }
  function fi(r, e, t, n, i, a, s, o, u, f, l, v) {
    var y = h();
    try {
      return _(r)(e, t, n, i, a, s, o, u, f, l, v);
    } catch (w) {
      if (p(y), w !== w + 0) throw w;
      d(1, 0);
    }
  }
  function ci(r, e, t, n, i, a, s) {
    var o = h();
    try {
      return we(r, e, t, n, i, a, s);
    } catch (u) {
      if (p(o), u !== u + 0) throw u;
      d(1, 0);
    }
  }
  function li(r, e, t, n, i) {
    var a = h();
    try {
      return $e(r, e, t, n, i);
    } catch (s) {
      if (p(a), s !== s + 0) throw s;
      d(1, 0);
    }
  }
  function vi() {
    Ee();
    function r() {
      var e, t;
      c.calledRun = !0, !Vr && (De(), (e = Hr) === null || e === void 0 || e(c), (t = c.onRuntimeInitialized) === null || t === void 0 || t.call(c), Me());
    }
    c.setStatus ? (c.setStatus("Running..."), setTimeout(() => {
      setTimeout(() => c.setStatus(""), 1), r();
    }, 1)) : r();
  }
  var rr;
  return rr = await xe(), vi(), zr ? A = c : A = new Promise((r, e) => {
    Hr = r, Br = e;
  }), A;
}
function Ae(C) {
  return pi(_r, C);
}
function wi() {
  return hi(_r);
}
function $i(C) {
  return Ae({
    overrides: C,
    equalityFn: Object.is,
    fireImmediately: !0
  });
}
function Ti(C) {
  Ae({
    overrides: C,
    equalityFn: Object.is,
    fireImmediately: !1
  });
}
async function Se(C, A) {
  return _i(_r, C, A);
}
async function Pi(C, A) {
  return Se(C, A);
}
async function Ci(C, A) {
  return Se(C, A);
}
async function Ri(C, A) {
  return gi(_r, C, A);
}
const Fi = "2302c4d909b4be43b81971b77ea5695d85d9cf09df3031140ddee9bf0539cfd3";
export {
  ki as ZXING_CPP_COMMIT,
  Fi as ZXING_WASM_SHA256,
  Oi as ZXING_WASM_VERSION,
  Wi as barcodeFormats,
  ji as binarizers,
  Ei as characterSets,
  Di as contentTypes,
  Mi as defaultReaderOptions,
  Ui as defaultWriterOptions,
  Ii as eanAddOnSymbols,
  $i as getZXingModule,
  Vi as linearBarcodeFormats,
  Hi as matrixBarcodeFormats,
  Ae as prepareZXingModule,
  wi as purgeZXingModule,
  Se as readBarcodes,
  Ci as readBarcodesFromImageData,
  Pi as readBarcodesFromImageFile,
  Ti as setZXingModuleOverrides,
  Bi as textModes,
  Ri as writeBarcode
};
