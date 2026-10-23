pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import "../../components"

Item {
    id: root
    implicitWidth: 340
    implicitHeight: 420

    Component.onCompleted: Qt.callLater(() => prompt.forceActiveFocus())

    function submit(inTerm) {
        const c = prompt.text;
        prompt.text = "";
        if (inTerm)
            Term.spawnCmd(c);
        else
            Term.run(c);
        Qt.callLater(() => prompt.forceActiveFocus());
    }

    Surface {
        anchors.fill: parent
        elev: 3
        radius: Tokens.rLg
        photo: true
        border.color: Qt.alpha(Theme.primary, 0.22)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                PanelHead {
                    icon: "󰆍"
                    title: Term.cwdPretty
                    Layout.fillWidth: true
                }
                Rectangle {
                    implicitWidth: sessLab.implicitWidth + 16
                    implicitHeight: 22
                    radius: 11
                    color: sessMouse.containsMouse ? Theme.primary : Qt.alpha(Theme.primary, 0.16)
                    border.width: 1
                    border.color: Qt.alpha(Theme.primary, 0.4)
                    Text {
                        id: sessLab
                        anchors.centerIn: parent
                        text: "session"
                        font.family: Theme.uiFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: sessMouse.containsMouse ? Theme.inkPrimary : Theme.primary
                    }
                    MouseArea {
                        id: sessMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Term.spawn()
                    }
                }
                Rectangle {
                    implicitWidth: 22
                    implicitHeight: 22
                    radius: 11
                    color: wipeMouse.containsMouse ? Qt.alpha(Theme.primary, 0.22) : Qt.alpha(Theme.primary, 0.12)
                    Text {
                        anchors.centerIn: parent
                        text: "󰎆"
                        font.family: Theme.font
                        font.pixelSize: 12
                        color: Theme.primary
                    }
                    MouseArea {
                        id: wipeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Term.clearLog()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 22
                color: Qt.alpha(Theme.surfaceContainerLow, 0.45)
                border.width: 1
                border.color: Qt.alpha(Theme.primary, 0.12)
                clip: true

                Flickable {
                    id: logFlick
                    anchors.fill: parent
                    anchors.margins: 10
                    contentHeight: logCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    onContentHeightChanged: Qt.callLater(() => {
                        contentY = Math.max(0, contentHeight - height);
                    })

                    Column {
                        id: logCol
                        width: logFlick.width
                        spacing: 3
                        Repeater {
                            model: Term.lines
                            delegate: Text {
                                required property var modelData
                                width: logCol.width
                                wrapMode: Text.WrapAnywhere
                                font.family: Theme.font
                                font.pixelSize: 11
                                text: modelData.t
                                color: modelData.k === "cmd" ? Theme.primary : (modelData.k === "err" ? Theme.error : Theme.ink)
                            }
                        }
                    }
                }

                Text {
                    visible: Term.lines.length === 0
                    anchors.centerIn: parent
                    text: "prêt"
                    font.family: Theme.uiFont
                    font.pixelSize: 12
                    color: Theme.inkMuted
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6
                visible: Term.history.length > 0
                Repeater {
                    model: Term.history.slice(0, 5)
                    delegate: Rectangle {
                        required property var modelData
                        implicitWidth: Math.min(160, hLab.implicitWidth + 12)
                        implicitHeight: 20
                        radius: 10
                        color: Qt.alpha(Theme.primary, 0.12)
                        border.width: 1
                        border.color: Qt.alpha(Theme.primary, 0.28)
                        Text {
                            id: hLab
                            anchors.centerIn: parent
                            width: parent.width - 10
                            text: modelData
                            font.family: Theme.font
                            font.pixelSize: 10
                            color: Theme.primary
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                prompt.text = modelData;
                                prompt.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: 10
                color: Qt.alpha(Theme.background, 0.4)
                border.width: 1
                border.color: prompt.activeFocus ? Theme.primary : Qt.alpha(Theme.primary, 0.28)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 6
                    Text {
                        text: "$"
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: Theme.primary
                    }
                    TextInput {
                        id: prompt
                        Layout.fillWidth: true
                        color: Theme.ink
                        font.family: Theme.font
                        font.pixelSize: 13
                        clip: true
                        selectByMouse: true
                        activeFocusOnTab: true
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.submit(!!(event.modifiers & Qt.ControlModifier));
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                prompt.text = Term.histPrev(prompt.text);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down) {
                                prompt.text = Term.histNext();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_L && (event.modifiers & Qt.ControlModifier)) {
                                Term.clearLog();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier) && Term.busy) {
                                Term.kill();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                PanelService.hidePopover();
                                event.accepted = true;
                            }
                        }
                    }
                    Rectangle {
                        implicitWidth: 28
                        implicitHeight: 24
                        radius: 8
                        color: goMouse.containsMouse ? Theme.primary : Qt.alpha(Theme.primary, 0.2)
                        Text {
                            anchors.centerIn: parent
                            text: "󰁔"
                            font.family: Theme.font
                            font.pixelSize: 13
                            color: goMouse.containsMouse ? Theme.inkPrimary : Theme.primary
                        }
                        MouseArea {
                            id: goMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.submit(false)
                        }
                    }
                    Text {
                        visible: Term.busy
                        text: "…"
                        font.family: Theme.font
                        font.pixelSize: 14
                        color: Theme.primary
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Entrée ici  ·  Ctrl+Entrée dans Alacritty  ·  clic droit sur l’icône = session"
                font.family: Theme.uiFont
                font.pixelSize: 9
                color: Theme.inkMuted
                wrapMode: Text.WordWrap
            }
        }
    }
}
