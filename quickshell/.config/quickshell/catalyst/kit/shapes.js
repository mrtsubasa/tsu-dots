.pragma library

// Formes d'avatar : chemins SVG calculés pour une boîte w×h. Polygones aux
// coins arrondis (Bézier cubiques) ou formes polaires échantillonnées.
var list = [
    { id: "circle", label: "Cercle" },
    { id: "squircle", label: "Squircle" },
    { id: "soft", label: "Doux" },
    { id: "square", label: "Carré" },
    { id: "hexagon", label: "Hexagone" },
    { id: "octagon", label: "Octogone" },
    { id: "diamond", label: "Losange" },
    { id: "cookie", label: "Cookie" },
    { id: "clover", label: "Trèfle" },
    { id: "flower", label: "Fleur" },
    { id: "blob", label: "Goutte" }
];

function f(n) {
    return (Math.round(n * 100) / 100).toString();
}

// polygone dont chaque sommet est adouci : la courbe part à `t` (fraction de
// l'arête) avant le sommet et se termine à `t` après
function roundedPoly(pts, t) {
    var n = pts.length, d = "", k = 0.55;
    for (var i = 0; i < n; i++) {
        var p = pts[(i + n - 1) % n], v = pts[i], q = pts[(i + 1) % n];
        var a = [v[0] + (p[0] - v[0]) * t, v[1] + (p[1] - v[1]) * t];
        var b = [v[0] + (q[0] - v[0]) * t, v[1] + (q[1] - v[1]) * t];
        var c1 = [a[0] + (v[0] - a[0]) * k, a[1] + (v[1] - a[1]) * k];
        var c2 = [b[0] + (v[0] - b[0]) * k, b[1] + (v[1] - b[1]) * k];
        d += (i === 0 ? "M " : "L ") + f(a[0]) + " " + f(a[1])
            + " C " + f(c1[0]) + " " + f(c1[1]) + " " + f(c2[0]) + " " + f(c2[1]) + " " + f(b[0]) + " " + f(b[1]) + " ";
    }
    return d + "Z";
}

// polygone régulier inscrit, étiré pour remplir la boîte
function regular(n, rot, w, h, t) {
    var pts = [], minx = 1, maxx = -1, miny = 1, maxy = -1;
    for (var i = 0; i < n; i++) {
        var th = rot + i * 2 * Math.PI / n;
        var x = Math.cos(th), y = Math.sin(th);
        pts.push([x, y]);
        minx = Math.min(minx, x); maxx = Math.max(maxx, x);
        miny = Math.min(miny, y); maxy = Math.max(maxy, y);
    }
    var s = Math.min(w / (maxx - minx), h / (maxy - miny));
    var ox = (w - (maxx - minx) * s) / 2 - minx * s, oy = (h - (maxy - miny) * s) / 2 - miny * s;
    return roundedPoly(pts.map(function (p) { return [ox + p[0] * s, oy + p[1] * s]; }), t);
}

function rect(w, h, r) {
    return roundedPoly([[0, 0], [w, 0], [w, h], [0, h]], Math.min(0.5, r));
}

// forme polaire : rayon(θ) ∈ ]0, 1], mise à l'échelle de la boîte
function polar(fn, w, h) {
    var N = 240, d = "", max = 0, i, rs = [];
    for (i = 0; i < N; i++) {
        rs.push(fn(i * 2 * Math.PI / N));
        max = Math.max(max, rs[i]);
    }
    for (i = 0; i < N; i++) {
        var th = i * 2 * Math.PI / N - Math.PI / 2, r = rs[i] / max;
        d += (i === 0 ? "M " : "L ") + f(w / 2 + Math.cos(th) * r * w / 2) + " " + f(h / 2 + Math.sin(th) * r * h / 2) + " ";
    }
    return d + "Z";
}

function path(shape, w, h) {
    if (w <= 0 || h <= 0)
        return "";
    switch (shape) {
    case "square": return rect(w, h, 0.14);
    case "soft": return rect(w, h, 0.3);
    case "squircle":
        // superellipse |x|^3.2 + |y|^3.2 = 1
        var N = 160, d = "";
        for (var i = 0; i < N; i++) {
            var t = i * 2 * Math.PI / N, c = Math.cos(t), s = Math.sin(t);
            var x = Math.sign(c) * Math.pow(Math.abs(c), 0.625), y = Math.sign(s) * Math.pow(Math.abs(s), 0.625);
            d += (i === 0 ? "M " : "L ") + f(w / 2 + x * w / 2) + " " + f(h / 2 + y * h / 2) + " ";
        }
        return d + "Z";
    case "hexagon": return regular(6, -Math.PI / 2, w, h, 0.2);
    case "octagon": return regular(8, Math.PI / 8, w, h, 0.22);
    case "diamond": return regular(4, -Math.PI / 2, w, h, 0.2);
    case "cookie": return polar(function (t) { return 1 + 0.06 * Math.cos(9 * t); }, w, h);
    case "clover": return polar(function (t) { return 0.72 + 0.28 * Math.pow(Math.abs(Math.cos(2 * t)), 0.6); }, w, h);
    case "flower": return polar(function (t) { return 0.8 + 0.2 * Math.cos(6 * t); }, w, h);
    case "blob": return polar(function (t) { return 1 + 0.07 * Math.cos(3 * t + 0.6) + 0.05 * Math.sin(2 * t); }, w, h);
    }
    // cercle : deux arcs
    return "M 0 " + f(h / 2) + " A " + f(w / 2) + " " + f(h / 2) + " 0 1 1 " + f(w) + " " + f(h / 2)
        + " A " + f(w / 2) + " " + f(h / 2) + " 0 1 1 0 " + f(h / 2) + " Z";
}
