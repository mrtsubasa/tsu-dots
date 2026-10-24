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

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Txt { role: "overline"; text: "// " + ShellCfg.brand; color: Theme.accent }
                Txt { role: "title"; text: "Conteneurs" }
            }
            Txt { role: "caption"; text: Containers.running + " actif(s) · " + Containers.items.length + " au total" }
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

        Rectangle {
            Layout.fillWidth: true
            visible: Containers.dockerDenied
            implicitHeight: dn.implicitHeight + 16
            radius: Tokens.rMd
            color: Qt.alpha(Theme.warning, 0.12)
            RowLayout {
                id: dn
                anchors.fill: parent
                anchors.margins: 8
                anchors.leftMargin: 12
                spacing: 8
                Icon { name: "lock"; size: 16; color: Theme.warning }
                Txt {
                    Layout.fillWidth: true
                    role: "caption"
                    wrapMode: Text.WordWrap
                    color: Theme.warning
                    text: "Docker : accès au socket refusé. Pour gérer Docker ici : sudo usermod -aG docker $USER (puis reconnexion). Podman est géré normalement."
                }
            }
        }

        Repeater {
            model: Containers.items

            Pane {
                id: card
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 62
                level: 3
                glass: false
                radius: Tokens.rLg

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 8
                    spacing: 12

                    Rectangle {
                        width: 10
                        height: 10
                        radius: 5
                        color: card.modelData.running ? Theme.success : Theme.textFaint
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        RowLayout {
                            spacing: 8
                            Txt { role: "heading"; text: card.modelData.name; Layout.maximumWidth: 220 }
                            Badge { label: card.modelData.engine; tone: card.modelData.engine === "podman" ? Theme.accent2 : Theme.accent; ink: Theme.onAccent }
                        }
                        Txt {
                            Layout.fillWidth: true
                            role: "mono"
                            font.pixelSize: 11
                            color: Theme.textSub
                            text: card.modelData.image + "  ·  " + card.modelData.status + (card.modelData.ports.length ? "  ·  " + card.modelData.ports : "")
                        }
                    }
                    IconButton {
                        icon: card.modelData.running ? "stop" : "play_arrow"
                        variant: card.modelData.running ? "danger" : "tonal"
                        size: 32
                        iconSize: 18
                        tooltip: card.modelData.running ? "Arrêter" : "Démarrer"
                        onClicked: Containers.act(card.modelData, card.modelData.running ? "stop" : "start")
                    }
                    IconButton {
                        visible: card.modelData.running
                        icon: "restart_alt"
                        size: 32
                        iconSize: 18
                        tooltip: "Redémarrer"
                        onClicked: Containers.act(card.modelData, "restart")
                    }
                    IconButton {
                        icon: "article"
                        size: 32
                        iconSize: 18
                        tooltip: "Journaux (terminal)"
                        onClicked: Containers.logs(card.modelData)
                    }
                    IconButton {
                        visible: card.modelData.running
                        icon: "terminal"
                        size: 32
                        iconSize: 18
                        tooltip: "Shell dans le conteneur"
                        onClicked: Containers.shell(card.modelData)
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
