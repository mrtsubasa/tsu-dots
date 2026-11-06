import QtQuick
import qs.rice

// Touche de clavier (aide aux raccourcis) : capuchon mono discret.
Rectangle {
    id: root
    property string text: ""
    property bool lit: false
    property color tone: Theme.accent

    implicitHeight: 17
    implicitWidth: Math.max(17, label.implicitWidth + 9)
    radius: 4
    color: lit ? Qt.alpha(tone, 0.14) : Theme.s3
    border.width: 1
    border.color: lit ? Qt.alpha(tone, 0.5) : Theme.borderStrong

    Txt {
        id: label
        anchors.centerIn: parent
        role: "mono"
        font.pixelSize: 9
        text: root.text
        color: root.lit ? root.tone : Theme.textSub
    }
}
