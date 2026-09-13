const m = [
  ["Aztec", "M"],
  ["Codabar", "L"],
  ["Code39", "L"],
  ["Code93", "L"],
  ["Code128", "L"],
  ["DataBar", "L"],
  ["DataBarExpanded", "L"],
  ["DataMatrix", "M"],
  ["EAN-8", "L"],
  ["EAN-13", "L"],
  ["ITF", "L"],
  ["MaxiCode", "M"],
  ["PDF417", "M"],
  ["QRCode", "M"],
  ["UPC-A", "L"],
  ["UPC-E", "L"],
  ["MicroQRCode", "M"],
  ["rMQRCode", "M"],
  ["DXFilmEdge", "L"],
  ["DataBarLimited", "L"]
], O = m.map(([e]) => e), b = O.filter(
  (e, t) => m[t][1] === "L"
), L = O.filter(
  (e, t) => m[t][1] === "M"
);
function l(e) {
  switch (e) {
    case "Linear-Codes":
      return b.reduce((t, r) => t | l(r), 0);
    case "Matrix-Codes":
      return L.reduce((t, r) => t | l(r), 0);
    case "Any":
      return (1 << m.length) - 1;
    case "None":
      return 0;
    default:
      return 1 << O.indexOf(e);
  }
}
function w(e) {
  if (e === 0)
    return "None";
  const t = 31 - Math.clz32(e);
  return O[t];
}
function E(e) {
  return e.reduce((t, r) => t | l(r), 0);
}
const M = [
  "LocalAverage",
  "GlobalHistogram",
  "FixedThreshold",
  "BoolCast"
];
function x(e) {
  return M.indexOf(e);
}
const y = [
  "Unknown",
  "ASCII",
  "ISO8859_1",
  "ISO8859_2",
  "ISO8859_3",
  "ISO8859_4",
  "ISO8859_5",
  "ISO8859_6",
  "ISO8859_7",
  "ISO8859_8",
  "ISO8859_9",
  "ISO8859_10",
  "ISO8859_11",
  "ISO8859_13",
  "ISO8859_14",
  "ISO8859_15",
  "ISO8859_16",
  "Cp437",
  "Cp1250",
  "Cp1251",
  "Cp1252",
  "Cp1256",
  "Shift_JIS",
  "Big5",
  "GB2312",
  "GB18030",
  "EUC_JP",
  "EUC_KR",
  "UTF16BE",
  /**
   * UnicodeBig [[deprecated]]
   */
  "UTF16BE",
  "UTF8",
  "UTF16LE",
  "UTF32BE",
  "UTF32LE",
  "BINARY"
];
function B(e) {
  return e === "UnicodeBig" ? y.indexOf("UTF16BE") : y.indexOf(e);
}
const F = [
  "Text",
  "Binary",
  "Mixed",
  "GS1",
  "ISO15434",
  "UnknownECI"
];
function T(e) {
  return F[e];
}
const A = ["Ignore", "Read", "Require"];
function U(e) {
  return A.indexOf(e);
}
const R = ["Plain", "ECI", "HRI", "Hex", "Escaped"];
function p(e) {
  return R.indexOf(e);
}
const u = {
  formats: [],
  tryHarder: !0,
  tryRotate: !0,
  tryInvert: !0,
  tryDownscale: !0,
  tryDenoise: !1,
  binarizer: "LocalAverage",
  isPure: !1,
  downscaleFactor: 3,
  downscaleThreshold: 500,
  minLineCount: 2,
  maxNumberOfSymbols: 255,
  tryCode39ExtendedMode: !0,
  returnErrors: !1,
  eanAddOnSymbol: "Ignore",
  textMode: "HRI",
  characterSet: "Unknown"
};
function I(e) {
  return {
    ...e,
    formats: E(e.formats),
    binarizer: x(e.binarizer),
    eanAddOnSymbol: U(e.eanAddOnSymbol),
    textMode: p(e.textMode),
    characterSet: B(e.characterSet)
  };
}
function P(e) {
  return {
    ...e,
    format: w(e.format),
    contentType: T(e.contentType),
    eccLevel: e.ecLevel
  };
}
function _(e) {
  var t;
  return {
    ...e,
    image: (t = e.image && new Blob([new Uint8Array(e.image)], {
      type: "image/png"
    })) != null ? t : null
  };
}
const h = {
  format: "QRCode",
  readerInit: !1,
  forceSquareDataMatrix: !1,
  ecLevel: "",
  scale: 0,
  sizeHint: 0,
  rotate: 0,
  withHRT: !1,
  withQuietZones: !0,
  options: ""
};
function z(e) {
  return {
    ...e,
    format: l(e.format)
  };
}
const H = "2.2.4", N = "fba4e9503fee4518ca2e89510baeea9bcc36dc8d", W = {
  locateFile: (e, t) => {
    const r = e.match(/_(.+?)\.wasm$/);
    return r ? `https://fastly.jsdelivr.net/npm/zxing-wasm@2.2.4/dist/${r[1]}/${e}` : t + e;
  }
}, f = /* @__PURE__ */ new WeakMap();
function D(e, t) {
  return Object.is(e, t) || Object.keys(e).length === Object.keys(t).length && Object.keys(e).every(
    (r) => Object.hasOwn(t, r) && e[r] === t[r]
  );
}
function S(e, {
  overrides: t,
  equalityFn: r = D,
  fireImmediately: d = !1
} = {}) {
  var a;
  const [o, s] = (a = f.get(e)) != null ? a : [W], n = t != null ? t : o;
  let i;
  if (d) {
    if (s && (i = r(o, n)))
      return s;
    const c = e({
      ...n
    });
    return f.set(e, [n, c]), c;
  }
  (i != null ? i : r(o, n)) || f.set(e, [n]);
}
function v(e) {
  f.delete(e);
}
async function Z(e, t, r = u) {
  const d = {
    ...u,
    ...r
  }, o = await S(e, {
    fireImmediately: !0
  });
  let s, n;
  if ("width" in t && "height" in t && "data" in t) {
    const {
      data: a,
      data: { byteLength: c },
      width: g,
      height: C
    } = t;
    n = o._malloc(c), o.HEAPU8.set(a, n), s = o.readBarcodesFromPixmap(
      n,
      g,
      C,
      I(d)
    );
  } else {
    let a, c;
    if ("buffer" in t)
      [a, c] = [t.byteLength, t];
    else if ("byteLength" in t)
      [a, c] = [t.byteLength, new Uint8Array(t)];
    else if ("size" in t)
      [a, c] = [t.size, new Uint8Array(await t.arrayBuffer())];
    else
      throw new TypeError("Invalid input type");
    n = o._malloc(a), o.HEAPU8.set(c, n), s = o.readBarcodesFromImage(
      n,
      a,
      I(d)
    );
  }
  o._free(n);
  const i = [];
  for (let a = 0; a < s.size(); ++a)
    i.push(
      P(s.get(a))
    );
  return i;
}
async function X(e, t, r = h) {
  const d = {
    ...h,
    ...r
  }, o = z(
    d
  ), s = await S(e, {
    fireImmediately: !0
  });
  if (typeof t == "string")
    return _(
      s.writeBarcodeFromText(t, o)
    );
  const { byteLength: n } = t, i = s._malloc(n);
  s.HEAPU8.set(t, i);
  const a = s.writeBarcodeFromBytes(
    i,
    n,
    o
  );
  return s._free(i), _(a);
}
const j = {
  ...u,
  formats: [...u.formats]
}, G = { ...h };
export {
  N as Z,
  v as a,
  H as b,
  O as c,
  j as d,
  M as e,
  y as f,
  F as g,
  A as h,
  G as i,
  b as l,
  L as m,
  S as p,
  Z as r,
  R as t,
  X as w
};
