import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.rice
import qs.kit

// Lecteur « disque » : pochette circulaire avec arc de progression autour,
// titre/artiste et contrôles (MPRIS via Players). Style caelestia.
Item {
    id: root
    property string wid: ""

    readonly property real prog: Players.length > 0 ? Math.min(1, Players.position / Players.length) : 0

    // suit la position seulement quand le widget est affiché
    property bool _counted: false
    function _watch(on) {
        if (on === _counted)
            return;
        _counted = on;
        Players.posWatchers = Math.max(0, Players.posWatchers + (on ? 1 : -1));
    }
    onVisibleChanged: _watch(visible)
    Component.onCompleted: _watch(visible)
    Component.onDestruction: _watch(false)

    function fmt(us) {
        const s = Math.max(0, Math.floor(us / 1000000));
        const m = Math.floor(s / 60);
        return m + ":" + String(s % 60).padStart(2, "0");
    }

    EmptyState {
        anchors.centerIn: parent
        visible: !Players.has
        icon: "music_off"
        title: "Aucune lecture"
    }

    RowLayout {
        anchors.fill: parent
        visible: Players.has
        spacing: 18

        // --- disque + arc ---
        Item {
            id: disc
            Layout.preferredWidth: Math.min(root.height, root.width * 0.46)
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter

            readonly property real ringW: Math.max(4, width * 0.045)

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Qt.alpha(Theme.accent, 0.18)
                    strokeWidth: disc.ringW
                    fillColor: "transparent"
                    PathAngleArc {
                        centerX: disc.width / 2; centerY: disc.height / 2
                        radiusX: (disc.width - disc.ringW) / 2; radiusY: radiusX
                        startAngle: 0; sweepAngle: 360
                    }
                }
                ShapePath {
                    strokeColor: Theme.accent
                    strokeWidth: disc.ringW
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: disc.width / 2; centerY: disc.height / 2
                        radiusX: (disc.width - disc.ringW) / 2; radiusY: radiusX
                        startAngle: -90
                        sweepAngle: 360 * root.prog
                        Behavior on sweepAngle { NumberAnimation { duration: Motion.dur(Motion.fast); easing.type: Easing.OutCubic } }
                    }
                }
            }

            // pochette ronde (vinyle qui tourne doucement en lecture)
            Art {
                id: cover
                anchors.fill: parent
                anchors.margins: disc.ringW + 4
                source: Players.artUrl
                radius: width / 2
                fallbackIcon: "music_note"

                RotationAnimator on rotation {
                    from: 0; to: 360; duration: 14000; loops: Animation.Infinite
                    running: Players.playing && !Motion.reduced && root.visible
                }
                onRotationChanged: {}   // garde l'anim active
            }
            // moyeu central (trou du vinyle)
            Rectangle {
                anchors.centerIn: parent
                width: disc.width * 0.12; height: width; radius: width / 2
                color: Theme.s2
                border.width: 2; border.color: Qt.alpha(Theme.bg, 0.6)
            }

            // clic sur le disque = lecture / pause
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Players.playPause()
            }
        }

        // --- infos + contrôles ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2
            Txt { role: "overline"; text: Players.identity || "Lecteur"; color: Theme.accent; Layout.fillWidth: true; elide: Text.ElideRight }
            Txt { role: "title"; text: Players.title || "Sans titre"; Layout.fillWidth: true; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap }
            Txt { role: "caption"; text: Players.artist || "Artiste inconnu"; Layout.fillWidth: true; elide: Text.ElideRight }
            Item { Layout.fillHeight: true }

            Txt {
                visible: Players.length > 0
                role: "mono"
                text: root.fmt(Players.position) + " / " + root.fmt(Players.length)
                color: Theme.textFaint
                font.pixelSize: 11
            }
            RowLayout {
                spacing: 4
                Layout.topMargin: 4
                IconButton { icon: "skip_previous"; size: 32; onClicked: Players.prev() }
                IconButton { icon: Players.playing ? "pause" : "play_arrow"; variant: "filled"; size: 40; onClicked: Players.playPause() }
                IconButton { icon: "skip_next"; size: 32; onClicked: Players.next() }
            }
        }
    }
}
