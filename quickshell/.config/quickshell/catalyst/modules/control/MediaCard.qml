pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.rice
import qs.kit

// Carte média MPRIS « Catalyst » : la pochette floutée sert de décor, sa
// couleur dominante teinte la carte (progression, lecture, égaliseur) ; titre
// défilant s'il est trop long, temps restant, sélection du lecteur quand il y
// en a plusieurs. Gère l'absence de métadonnées et de pochette ; la position
// et les animations ne tournent que si la carte est visible.
Pane {
    id: root

    property bool large: false
    level: 3
    glass: false
    radius: Tokens.rLg
    implicitHeight: col.implicitHeight + 28

    readonly property bool live: visible && Players.playing

    // ---- teinte tirée de la pochette ----
    // ColorQuantizer ne lit que des fichiers locaux : la pochette (souvent
    // distante) est rendue en petit puis enregistrée dans le runtime dir.
    property color tint: Theme.accent
    Behavior on tint { ColorAnimation { duration: Motion.dur(Motion.themeDuration) } }

    function _pickTint(colors) {
        let best = null, score = -1;
        for (let i = 0; i < colors.length; i++) {
            const c = colors[i];
            const sc = c.hslSaturation * (0.35 + c.hslLightness);
            if (sc > score) { score = sc; best = c; }
        }
        if (!best || best.hslSaturation < 0.12)
            return Theme.accent;   // pochette grise : on garde l'accent du thème
        // lisible sur fond sombre, jamais criard
        return Qt.hsla(best.hslHue, Math.min(0.85, Math.max(0.45, best.hslSaturation)),
                       Math.min(0.76, Math.max(0.64, best.hslLightness)), 1);
    }

    ColorQuantizer {
        id: quant
        depth: 3
        rescaleSize: 48
        onColorsChanged: root.tint = root._pickTint(colors)
    }
    Image {
        id: probe
        width: 48
        height: 48
        opacity: 0.001          // doit être rendue pour grabToImage
        source: Players.artUrl
        sourceSize.width: 48
        sourceSize.height: 48
        asynchronous: true
        property string _done: ""
        function grab() {
            // seulement une fois affichée (sinon pas de fenêtre où rendre)
            if (status !== Image.Ready || !root.visible || !Window.window || _done === source.toString())
                return;
            const key = source.toString();
            const path = Quickshell.env("XDG_RUNTIME_DIR") + "/catalyst-art-" + Qt.md5(key) + ".png";
            if (grabToImage(r => {
                if (r.saveToFile(path))
                    quant.source = "file://" + path;
            }))
                _done = key;
        }
        onStatusChanged: grab()
    }
    onVisibleChanged: {
        _watch(visible);
        if (visible)
            Qt.callLater(probe.grab);
    }
    Connections {
        target: Players
        function onArtUrlChanged() {
            if (!Players.artUrl.length)
                root.tint = Theme.accent;
        }
    }

    // ---- décor : pochette floutée + voile de nuit ----
    Image {
        id: backdrop
        anchors.fill: parent
        source: Players.artUrl
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 160
        sourceSize.height: 160
        asynchronous: true
        visible: false
    }
    Rectangle {
        id: shape
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: parent
        source: backdrop
        visible: backdrop.status === Image.Ready
        opacity: 0.6
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        saturation: 0.15
        brightness: -0.08
        maskEnabled: true
        maskSource: shape
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.alpha(Theme.s1, 0.94) }
            GradientStop { position: 0.55; color: Qt.alpha(Theme.s1, 0.78) }
            GradientStop { position: 1.0; color: Qt.alpha(Theme.s1, 0.5) }
        }
    }
    // reflet de teinte en bas, très léger
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * 0.6
        radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.alpha(root.tint, 0.1) }
        }
    }
    // arête haute : fil de lumière à la teinte du morceau
    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - root.radius * 2
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.alpha(root.tint, 0.55) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // la position n'est rafraîchie que pendant que la carte est visible
    property bool _counted: false
    function _watch(on) {
        if (on === _counted)
            return;
        _counted = on;
        Players.posWatchers = Math.max(0, Players.posWatchers + (on ? 1 : -1));
    }
    Component.onCompleted: _watch(visible)
    Component.onDestruction: _watch(false)

    function fmt(s) {
        if (!(s > 0))
            return "0:00";
        const m = Math.floor(s / 60);
        const ss = Math.floor(s % 60);
        return m + ":" + (ss < 10 ? "0" : "") + ss;
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            // pochette : ombre douce + liseré, légère respiration en lecture
            Item {
                Layout.preferredWidth: root.large ? 84 : 68
                Layout.preferredHeight: Layout.preferredWidth
                Layout.alignment: Qt.AlignTop

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 6
                    radius: Tokens.rMd
                    color: Qt.alpha(root.tint, 0.35)
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: 1.0
                        blurMax: 24
                    }
                }
                Art {
                    id: cover
                    anchors.fill: parent
                    source: Players.artUrl
                    radius: Tokens.rMd
                    fallbackIcon: "music_note"
                    scale: root.live ? 1.0 : 0.96
                    Behavior on scale { NumberAnimation { duration: Motion.dur(Motion.slow); easing.type: Easing.OutCubic } }
                }
                Rectangle {
                    anchors.fill: cover
                    scale: cover.scale
                    radius: Tokens.rMd
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.alpha("white", 0.08)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 3

                // lecteur + état (égaliseur vivant / en pause)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 7

                    Row {
                        id: eq
                        spacing: 2
                        Layout.preferredHeight: 10
                        Repeater {
                            model: [0.55, 1.0, 0.7, 0.85]
                            Rectangle {
                                id: bar
                                required property var modelData
                                required property int index
                                width: 2
                                radius: 1
                                y: 10 - height
                                height: root.live ? 10 * modelData : 2
                                color: root.tint
                                Behavior on height { enabled: !root.live; NumberAnimation { duration: Motion.dur(Motion.base) } }
                                SequentialAnimation on height {
                                    running: root.live
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 3; duration: 260 + bar.index * 70; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 10 * bar.modelData; duration: 300 + bar.index * 50; easing.type: Easing.InOutSine }
                                }
                            }
                        }
                    }
                    Txt {
                        Layout.fillWidth: true
                        role: "overline"
                        text: (Players.identity || "Lecteur") + (Players.playing ? "" : "  ·  en pause")
                        color: root.tint
                    }
                    IconButton {
                        visible: Players.playerCount > 1
                        icon: "swap_horiz"
                        size: 24
                        iconSize: 15
                        tooltip: "Lecteur suivant (" + Players.playerCount + ")"
                        onClicked: Players.cycle()
                    }
                    IconButton {
                        visible: Players.canRaise
                        icon: "open_in_new"
                        size: 24
                        iconSize: 14
                        tooltip: "Afficher le lecteur"
                        onClicked: {
                            Players.raise();
                            PanelService.hide();
                        }
                    }
                }

                // titre : défile une fois en aller-retour s'il dépasse
                Item {
                    id: titleBox
                    Layout.fillWidth: true
                    implicitHeight: titleTxt.implicitHeight
                    clip: true

                    readonly property real overflow: Math.max(0, titleTxt.implicitWidth - width)

                    Text {
                        id: titleTxt
                        text: Players.title.length ? Players.title : "Aucun titre"
                        color: Theme.text
                        font.family: Theme.displayFont
                        font.pixelSize: root.large ? 21 : 18
                        font.weight: Font.DemiBold
                        font.letterSpacing: -0.3
                        textFormat: Text.PlainText
                        onTextChanged: x = 0

                        SequentialAnimation on x {
                            running: root.visible && titleBox.overflow > 0
                            loops: Animation.Infinite
                            PauseAnimation { duration: 2600 }
                            NumberAnimation { to: -titleBox.overflow; duration: Math.max(1200, titleBox.overflow * 28); easing.type: Easing.InOutSine }
                            PauseAnimation { duration: 1800 }
                            NumberAnimation { to: 0; duration: 700; easing.type: Easing.OutCubic }
                        }
                    }
                }
                Txt {
                    Layout.fillWidth: true
                    role: "caption"
                    text: {
                        const a = Players.artist, b = Players.album;
                        if (a.length && b.length && b !== Players.title)
                            return a + "  ·  " + b;
                        return a.length ? a : (b.length ? b : "Artiste inconnu");
                    }
                }
            }
        }

        // progression : temps écoulé · barre · temps restant
        RowLayout {
            Layout.fillWidth: true
            visible: Players.length > 0
            spacing: 10

            Txt {
                role: "mono"
                text: root.fmt(seek.pressed ? seek.dragFrac * Players.length : Players.position)
                color: Theme.textSub
                font.pixelSize: 10
                Layout.preferredWidth: 30
            }
            Item {
                Layout.fillWidth: true
                implicitHeight: 14

                readonly property real frac: Math.max(0, Math.min(1, seek.pressed ? seek.dragFrac : Players.position / Math.max(1, Players.length)))

                Rectangle {
                    id: trackBg
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: seek.containsMouse || seek.pressed ? 6 : 4
                    radius: height / 2
                    color: Qt.alpha(Theme.text, 0.1)
                    Behavior on height { NumberAnimation { duration: Motion.dur(Motion.fast) } }

                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        width: Math.max(parent.height, parent.width * parent.parent.frac)
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.alpha(root.tint, 0.55) }
                            GradientStop { position: 1.0; color: root.tint }
                        }
                    }
                }
                // tête de lecture : apparaît au survol
                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width * parent.frac - width / 2
                    color: Theme.text
                    border.width: 2
                    border.color: root.tint
                    opacity: seek.containsMouse || seek.pressed ? 1 : 0
                    scale: seek.pressed ? 1.15 : 1
                    Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.fast) } }
                    Behavior on scale { NumberAnimation { duration: Motion.dur(Motion.instant) } }
                }

                MouseArea {
                    id: seek
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    enabled: Players.canSeek
                    cursorShape: Players.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
                    property real dragFrac: 0
                    onPressed: mouse => dragFrac = Math.max(0, Math.min(1, (mouse.x - 4) / (width - 8)))
                    onPositionChanged: mouse => {
                        if (pressed)
                            dragFrac = Math.max(0, Math.min(1, (mouse.x - 4) / (width - 8)));
                    }
                    onReleased: Players.seekTo(dragFrac * Players.length)
                }
            }
            Txt {
                role: "mono"
                text: "-" + root.fmt(Players.length - (seek.pressed ? seek.dragFrac * Players.length : Players.position))
                color: Theme.textSub
                font.pixelSize: 10
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 34
            }
        }

        // contrôles
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            IconButton {
                visible: Players.shuffleSupported
                icon: "shuffle"
                size: 30
                iconSize: 17
                iconColor: Players.shuffled ? root.tint : Theme.textSub
                Rectangle {
                    z: -1
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.alpha(root.tint, Players.shuffled ? 0.16 : 0)
                }
                tooltip: "Aléatoire"
                onClicked: Players.toggleShuffle()
            }
            Item { Layout.fillWidth: true }
            IconButton {
                icon: "skip_previous"
                size: 36
                iconSize: 22
                disabled: !Players.canPrev
                tooltip: "Précédent"
                onClicked: Players.prev()
            }

            // lecture / pause : pastille pleine à la teinte, halo discret
            Item {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48

                Rectangle {
                    anchors.centerIn: parent
                    width: 48
                    height: 48
                    radius: 24
                    color: root.tint
                    opacity: root.live ? 0.35 : 0
                    layer.enabled: true
                    layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 20 }
                    Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.slow) } }
                }
                Rectangle {
                    id: playBtn
                    anchors.centerIn: parent
                    width: 46
                    height: 46
                    radius: 23
                    color: root.tint
                    scale: playArea.pressed ? 0.92 : (playArea.containsMouse ? 1.05 : 1)
                    Behavior on scale { NumberAnimation { duration: Motion.dur(Motion.fast); easing.type: Easing.OutBack } }

                    Icon {
                        anchors.centerIn: parent
                        name: Players.playing ? "pause" : "play_arrow"
                        size: 26
                        fill: 1
                        color: Theme.surfaceDim
                    }
                    MouseArea {
                        id: playArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Players.playPause()
                    }
                }
                Tip {
                    target: playBtn
                    text: Players.playing ? "Pause" : "Lecture"
                    active: playArea.containsMouse && !playArea.pressed
                }
            }

            IconButton {
                icon: "skip_next"
                size: 36
                iconSize: 22
                disabled: !Players.canNext
                tooltip: "Suivant"
                onClicked: Players.next()
            }
            Item { Layout.fillWidth: true }
            IconButton {
                visible: Players.loopSupported
                icon: Players.loop === MprisLoopState.Track ? "repeat_one" : "repeat"
                size: 30
                iconSize: 17
                iconColor: Players.looping ? root.tint : Theme.textSub
                // pastille de teinte plutôt que le fond « actif » du thème
                Rectangle {
                    z: -1
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.alpha(root.tint, Players.looping ? 0.16 : 0)
                }
                tooltip: "Répéter"
                onClicked: Players.cycleLoop()
            }
        }
    }
}
