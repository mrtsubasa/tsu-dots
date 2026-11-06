pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Micro & visio : mode visio, micro traité (EasyEffects) ou brut, vumètre,
// retour d'écoute, qui utilise le micro / la caméra / l'écran, caméra OBS.
ColumnLayout {
    id: root
    signal back()
    signal openInputs()
    spacing: Tokens.sectionGap

    Component.onCompleted: Mic.meterUsers++
    Component.onDestruction: {
        Mic.meterUsers = Math.max(0, Mic.meterUsers - 1);
        Mic.monitoring = false;
    }

    PageHeader {
        icon: "videocam"
        tone: Theme.signature
        Layout.fillWidth: true
        title: "Micro & visio"
        subtitle: Audio.sourceReady ? Audio.inputName : "Aucun micro"
        onBack: root.back()
    }

    // ---------------- mode visio ----------------
    Tile {
        Layout.fillWidth: true
        icon: "video_call"
        title: "Mode visio"
        subtitle: Mic.callMode ? "Actif · NPD, musique en pause, micro traité" : "Ne pas déranger + micro traité + musique en pause"
        active: Mic.callMode
        accent: Theme.success
        onClicked: Mic.setCallMode(!Mic.callMode)
    }

    // ---------------- micro ----------------
    SectionHeader { Layout.fillWidth: true; text: "Micro" }

    Pane {
        Layout.fillWidth: true
        implicitHeight: micCol.implicitHeight + 24
        level: 3
        glass: false
        radius: Tokens.rLg

        ColumnLayout {
            id: micCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 12

            // vumètre
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                IconButton {
                    icon: Audio.micMuted ? "mic_off" : "mic"
                    variant: Audio.micMuted ? "danger" : "tonal"
                    size: 34
                    tooltip: Audio.micMuted ? "Réactiver le micro" : "Couper le micro"
                    onClicked: Audio.toggleMic()
                }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 14
                    Rectangle {
                        anchors.fill: parent
                        radius: 7
                        color: Theme.s4
                    }
                    Rectangle {
                        height: parent.height
                        radius: 7
                        width: parent.width * (Audio.micMuted ? 0 : Math.min(1, Mic.level * 1.6))
                        color: Mic.level > 0.85 ? Theme.error : (Mic.level > 0.55 ? Theme.warning : Theme.success)
                        Behavior on width { NumberAnimation { duration: 60 } }
                    }
                    Rectangle {
                        visible: !Audio.micMuted && Mic.peakHold > 0.02
                        x: Math.min(parent.width - 2, parent.width * Math.min(1, Mic.peakHold * 1.6))
                        width: 2
                        height: parent.height
                        color: Theme.text
                        opacity: 0.8
                    }
                }
                Txt {
                    role: "mono"
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                    text: Audio.micMuted ? "muet" : Math.round(Mic.level * 100) + "%"
                    color: Theme.textSub
                }
            }

            SettingRow {
                Layout.fillWidth: true
                Layout.leftMargin: -14
                Layout.rightMargin: -14
                icon: "graphic_eq"
                title: "Micro traité (EasyEffects)"
                subtitle: Mic.starting ? "Démarrage d'EasyEffects…" : (Mic.processed ? "Réduction de bruit et filtres appliqués à toutes les applis" : (Mic.eeAvailable ? "Les applis reçoivent le micro brut" : "EasyEffects sera lancé en arrière-plan"))
                Spinner { visible: Mic.starting; size: 16 }
                Toggle {
                    checked: Mic.processed
                    disabled: Mic.starting
                    onToggled: v => Mic.setProcessed(v)
                }
            }

            SettingRow {
                Layout.fillWidth: true
                Layout.leftMargin: -14
                Layout.rightMargin: -14
                icon: "hearing"
                title: "M'écouter"
                subtitle: "Renvoie le micro dans la sortie pour régler son son (avec un casque)"
                Toggle {
                    checked: Mic.monitoring
                    onToggled: v => Mic.monitoring = v
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Slider {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    icon: "mic"
                    iconOff: "mic_off"
                    muted: Audio.micMuted
                    maximum: 1
                    value: Math.min(1, Audio.micVolume)
                    onMoved: v => Audio.setMicVolume(v)
                    onIconClicked: Audio.toggleMic()
                }
                Button {
                    variant: "secondary"
                    icon: "tune"
                    text: "Périphérique"
                    height_: 32
                    onClicked: root.openInputs()
                }
            }
        }
    }

    // ---------------- vie privée ----------------
    SectionHeader { Layout.fillWidth: true; text: "En cours d'utilisation" }

    Pane {
        Layout.fillWidth: true
        implicitHeight: privCol.implicitHeight + 16
        level: 3
        glass: false
        radius: Tokens.rLg

        ColumnLayout {
            id: privCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 0

            ListItem {
                Layout.fillWidth: true
                icon: "mic"
                title: "Micro"
                subtitle: Privacy.micInUse ? Privacy.micApps.join(", ") : "Aucune application"
                selected: Privacy.micInUse
            }
            ListItem {
                Layout.fillWidth: true
                icon: "videocam"
                title: "Caméra"
                subtitle: Privacy.cameraInUse ? Privacy.cameraApps.join(", ") : "Aucune application · seule la caméra virtuelle OBS est présente"
                selected: Privacy.cameraInUse
                Button {
                    variant: "ghost"
                    height_: 28
                    icon: "videocam"
                    text: "Caméra OBS"
                    onClicked: Mic.startVirtualCam()
                }
            }
            ListItem {
                Layout.fillWidth: true
                icon: "screen_share"
                title: "Partage d'écran"
                subtitle: Privacy.screenShare ? (Privacy.screenApps.join(", ") || "En cours") : "Inactif"
                selected: Privacy.screenShare
            }
            SettingRow {
                Layout.fillWidth: true
                Layout.leftMargin: -6
                Layout.rightMargin: -6
                icon: "do_not_disturb_on"
                title: "Ne pas déranger pendant un partage"
                subtitle: "Aucune notification ne s'affiche à l'écran partagé"
                Toggle {
                    checked: ShellCfg.dndOnShare
                    onToggled: v => ShellCfg.set("dndOnShare", v)
                }
            }
        }
    }
}
