pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Éditeur de cadrage : positionne/zoome l'image dans le cadre de l'écran cible
// (glisser pour déplacer, molette ou curseur pour zoomer), puis rogne à la
// résolution exacte via Walls.applyCrop. « Remplir » recentre au zoom minimal.
Item {
    id: root
    anchors.fill: parent

    // écran cible : celui choisi, sinon le premier
    readonly property var scr: {
        const n = Walls.frameOutput;
        const s = Quickshell.screens;
        if (n.length) { const f = s.find(x => x.name === n); if (f) return f; }
        return s.length ? s[0] : null;
    }
    readonly property int tw: scr ? scr.width : 1920
    readonly property int th: scr ? scr.height : 1080
    readonly property real vpAspect: tw / th

    // voile
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.62)
        MouseArea { anchors.fill: parent; onClicked: Walls.cancelFrame() }
    }

    Pane {
        id: card
        anchors.centerIn: parent
        level: 2
        radius: Tokens.rXl
        width: Math.min(root.width - 80, 860)
        implicitHeight: col.implicitHeight + 36
        // absorbe les clics (ne ferme pas)
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Icon { name: "crop"; size: 20; color: Theme.accent }
                ColumnLayout {
                    spacing: 0
                    Txt { text: "Cadrer le fond d'écran"; role: "title" }
                    Txt {
                        role: "caption"
                        color: Theme.textFaint
                        text: (Walls.frameOutput.length ? Walls.frameOutput : "Tous les écrans")
                              + " · " + root.tw + "×" + root.th
                    }
                }
                Item { Layout.fillWidth: true }
                IconButton { icon: "close"; variant: "ghost"; onClicked: Walls.cancelFrame() }
            }

            // ---- viewport ----
            Item {
                id: vp
                Layout.fillWidth: true
                Layout.preferredHeight: width / root.vpAspect

                // dimensions image affichée (cover * zoom)
                property real imgAspect: img.implicitWidth > 0 ? img.implicitWidth / img.implicitHeight : root.vpAspect
                property real baseW: (imgAspect >= (width / height)) ? height * imgAspect : width
                property real dW: baseW * zoom
                property real dH: dW / imgAspect
                property real zoom: 1.0
                property real ox: (width - dW) / 2
                property real oy: (height - dH) / 2

                function clamp() {
                    ox = Math.min(0, Math.max(width - dW, ox));
                    oy = Math.min(0, Math.max(height - dH, oy));
                }
                function recenter() { zoom = 1.0; ox = (width - dW) / 2; oy = (height - dH) / 2; }
                function zoomAt(factor) {
                    const cx = width / 2, cy = height / 2;
                    const nz = Math.max(1, Math.min(4, zoom * factor));
                    if (nz === zoom) return;
                    const k = nz / zoom;
                    ox = cx - (cx - ox) * k;
                    oy = cy - (cy - oy) * k;
                    zoom = nz;
                    clamp();
                }
                onWidthChanged: clamp()
                onDWChanged: clamp()

                Rectangle {
                    anchors.fill: parent
                    radius: Tokens.rMd
                    color: Theme.s0
                    clip: true

                    Image {
                        id: img
                        x: vp.ox
                        y: vp.oy
                        width: vp.dW
                        height: vp.dH
                        source: Walls.framePath.length ? "file://" + Walls.framePath : ""
                        sourceSize.width: 1400
                        fillMode: Image.Stretch
                        asynchronous: true
                        cache: false
                    }

                    // tiers (repères de composition)
                    Repeater {
                        model: 2
                        Rectangle {
                            required property int index
                            width: 1; height: vp.height
                            x: vp.width * (index + 1) / 3
                            color: Qt.rgba(1, 1, 1, 0.18)
                        }
                    }
                    Repeater {
                        model: 2
                        Rectangle {
                            required property int index
                            height: 1; width: vp.width
                            y: vp.height * (index + 1) / 3
                            color: Qt.rgba(1, 1, 1, 0.18)
                        }
                    }

                    Spinner {
                        visible: img.status !== Image.Ready
                        anchors.centerIn: parent
                        color: Theme.textFaint
                    }

                    MouseArea {
                        id: drag
                        anchors.fill: parent
                        cursorShape: Qt.OpenHandCursor
                        property real px: 0
                        property real py: 0
                        onPressed: mouse => { px = mouse.x; py = mouse.y; cursorShape = Qt.ClosedHandCursor; }
                        onReleased: cursorShape = Qt.OpenHandCursor
                        onPositionChanged: mouse => {
                            vp.ox += mouse.x - px;
                            vp.oy += mouse.y - py;
                            px = mouse.x; py = mouse.y;
                            vp.clamp();
                        }
                        onWheel: wheel => vp.zoomAt(wheel.angleDelta.y > 0 ? 1.12 : 1 / 1.12)
                    }
                }
                // liseré
                Rectangle {
                    anchors.fill: parent
                    radius: Tokens.rMd
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.borderStrong
                }
            }

            // ---- zoom ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Icon { name: "zoom_out"; size: 16; color: Theme.textSub }
                Slider {
                    Layout.fillWidth: true
                    icon: "search"
                    value: (vp.zoom - 1) / 3            // 1..4 -> 0..1
                    valueText: Math.round(vp.zoom * 100) + "%"
                    onMoved: v => {
                        const nz = 1 + v * 3;
                        vp.zoomAt(nz / vp.zoom);
                    }
                }
                Icon { name: "zoom_in"; size: 16; color: Theme.textSub }
            }

            Txt {
                visible: Walls.frameError.length > 0
                Layout.fillWidth: true
                role: "caption"
                color: Theme.error
                wrapMode: Text.WordWrap
                text: Walls.frameError
            }

            // ---- actions ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Button { variant: "ghost"; text: "Annuler"; onClicked: Walls.cancelFrame() }
                Item { Layout.fillWidth: true }
                Button {
                    variant: "secondary"
                    icon: "fit_screen"
                    text: "Remplir"
                    onClicked: vp.recenter()
                }
                Button {
                    variant: "primary"
                    icon: "check"
                    text: Walls.framingBusy ? "Application…" : "Appliquer"
                    disabled: Walls.framingBusy || img.status !== Image.Ready
                    onClicked: {
                        const nx = Math.max(0, -vp.ox / vp.dW);
                        const ny = Math.max(0, -vp.oy / vp.dH);
                        const nw = Math.min(1 - nx, vp.width / vp.dW);
                        const nh = Math.min(1 - ny, vp.height / vp.dH);
                        Walls.applyCrop(nx, ny, nw, nh, root.tw, root.th);
                    }
                }
            }
        }

        // voile occupé
        Rectangle {
            anchors.fill: parent
            radius: Tokens.rXl
            visible: Walls.framingBusy
            color: Qt.rgba(0, 0, 0, 0.4)
            Spinner { anchors.centerIn: parent; size: 26; color: "white" }
        }
    }
}
