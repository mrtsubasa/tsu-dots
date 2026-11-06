pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Conteneurs : état réel (Podman / Docker), démarrer, arrêter, redémarrer,
// journaux et shell dans un terminal.
FocusScope {
    id: root

    property real maxHeight: 640
    implicitWidth: 640
    implicitHeight: Math.min(maxHeight, col.implicitHeight + 36)

    Component.onCompleted: {
        Containers.users++;
        forceActiveFocus();
    }
    Component.onDestruction: Containers.users = Math.max(0, Containers.users - 1)
    Keys.onEscapePressed: PanelService.hide()

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        PanelHead {
            Layout.fillWidth: true
            icon: "deployed_code"
            overline: Containers.running + " actif" + (Containers.running > 1 ? "s" : "") + " · " + Containers.items.length + " au total"
            title: "Conteneurs"
            tone: Theme.accent2
            Button {
                variant: "ghost"
                icon: "deployed_code"
                text: "lazydocker"
                height_: 30
                onClicked: {
                    PanelService.hide();
                    Quickshell.execDetached(["alacritty", "-e", "lazydocker"]);
                }
            }
            Button {
                variant: "ghost"
                icon: "dns"
                text: "VM"
                height_: 30
                onClicked: PanelService.show("vm")
            }
            IconButton { icon: "close"; size: 30; iconSize: 17; tooltip: "Fermer"; onClicked: PanelService.hide() }
        }

        Banner {
            Layout.fillWidth: true
            visible: Containers.dockerDenied
            icon: "lock"
            text: "Docker : accès au socket refusé. Pour gérer Docker ici : sudo usermod -aG docker $USER (puis reconnexion). Podman est géré normalement."
        }

        Repeater {
            model: Containers.items

            Rectangle {
                id: card
                required property var modelData
                readonly property bool on: modelData.running
                readonly property color tone: modelData.engine === "podman" ? Theme.accent2 : Theme.accent
                Layout.fillWidth: true
                implicitHeight: 64
                radius: Tokens.rLg
                color: on ? Qt.alpha(Theme.success, 0.05) : Theme.s2
                border.width: 1
                border.color: on ? Qt.alpha(Theme.success, 0.25) : Theme.border

                Rectangle {
                    visible: card.on
                    x: 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: 28
                    radius: 1
                    color: Theme.success
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 12

                    // médaillon moteur + pastille d'état
                    Item {
                        implicitWidth: 38
                        implicitHeight: 38
                        Rectangle {
                            anchors.fill: parent
                            radius: Tokens.rMd
                            color: Qt.alpha(card.tone, card.on ? 0.16 : 0.07)
                            border.width: 1
                            border.color: Qt.alpha(card.tone, card.on ? 0.35 : 0.15)
                            Icon { anchors.centerIn: parent; name: "deployed_code"; size: 19; fill: card.on ? 1 : 0; color: card.on ? card.tone : Theme.textFaint }
                        }
                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: -2
                            width: 11
                            height: 11
                            radius: 5.5
                            color: card.on ? Theme.success : Theme.textFaint
                            border.width: 2
                            border.color: Theme.s2
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            spacing: 8
                            Txt { role: "heading"; text: card.modelData.name; Layout.maximumWidth: 240 }
                            Rectangle {
                                implicitHeight: 18
                                implicitWidth: engTxt.implicitWidth + 12
                                radius: 9
                                color: Qt.alpha(card.tone, 0.12)
                                border.width: 1
                                border.color: Qt.alpha(card.tone, 0.35)
                                Txt { id: engTxt; anchors.centerIn: parent; role: "overline"; font.pixelSize: 9; text: card.modelData.engine; color: card.tone }
                            }
                        }
                        Txt {
                            Layout.fillWidth: true
                            role: "mono"
                            font.pixelSize: 10
                            color: Theme.textSub
                            text: card.modelData.image + "  ·  " + card.modelData.status + (card.modelData.ports.length ? "  ·  " + card.modelData.ports : "")
                        }
                    }

                    // actions groupées
                    Rectangle {
                        implicitHeight: 34
                        implicitWidth: acts.implicitWidth + 6
                        radius: 17
                        color: Qt.alpha(Theme.text, 0.04)
                        border.width: 1
                        border.color: Theme.border
                        Row {
                            id: acts
                            anchors.centerIn: parent
                            IconButton {
                                icon: card.on ? "stop" : "play_arrow"
                                size: 30
                                iconSize: 17
                                iconColor: card.on ? Theme.error : Theme.success
                                tooltip: card.on ? "Arrêter" : "Démarrer"
                                onClicked: Containers.act(card.modelData, card.on ? "stop" : "start")
                            }
                            IconButton {
                                visible: card.on
                                icon: "restart_alt"
                                size: 30
                                iconSize: 17
                                tooltip: "Redémarrer"
                                onClicked: Containers.act(card.modelData, "restart")
                            }
                            IconButton {
                                icon: "article"
                                size: 30
                                iconSize: 17
                                tooltip: "Journaux (terminal)"
                                onClicked: Containers.logs(card.modelData)
                            }
                            IconButton {
                                visible: card.on
                                icon: "terminal"
                                size: 30
                                iconSize: 17
                                tooltip: "Shell dans le conteneur"
                                onClicked: Containers.shell(card.modelData)
                            }
                        }
                    }
                }
            }
        }

        EmptyState {
            Layout.fillWidth: true
            visible: Containers.items.length === 0
            icon: "deployed_code"
            title: "Aucun conteneur"
            text: Containers.hasPodman || Containers.hasDocker ? "Les conteneurs Podman et Docker apparaîtront ici." : "Ni Podman ni Docker n'est installé."
        }
    }
}
