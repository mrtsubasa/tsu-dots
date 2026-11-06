import QtQuick
import qs.rice

// Tracé d'historique 0..1 (ligne + aire en fondu) pour le dashboard ;
// les valeurs arrivent par la droite, `capacity` = nombre de points visibles.
Canvas {
    id: sp
    property var values: []
    property int capacity: 48
    property color tone: Theme.accent

    onValuesChanged: requestPaint()
    onToneChanged: requestPaint()
    onWidthChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const v = values, n = v.length;
        if (n < 2)
            return;
        const step = width / (capacity - 1);
        const x0 = width - (n - 1) * step;
        const y = k => height - 1 - Math.max(0, Math.min(1, v[k])) * (height - 2);
        ctx.beginPath();
        ctx.moveTo(x0, y(0));
        for (let k = 1; k < n; k++)
            ctx.lineTo(x0 + k * step, y(k));
        ctx.lineWidth = 1.5;
        ctx.strokeStyle = tone;
        ctx.stroke();
        ctx.lineTo(x0 + (n - 1) * step, height);
        ctx.lineTo(x0, height);
        ctx.closePath();
        const g = ctx.createLinearGradient(0, 0, 0, height);
        g.addColorStop(0, Qt.alpha(tone, 0.28));
        g.addColorStop(1, Qt.alpha(tone, 0));
        ctx.fillStyle = g;
        ctx.fill();
    }
}
