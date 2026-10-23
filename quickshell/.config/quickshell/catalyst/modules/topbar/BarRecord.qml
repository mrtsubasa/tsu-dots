import QtQuick
import qs.rice
import qs.kit

// Voyant d'enregistrement d'écran : visible uniquement pendant une capture
// vidéo. Clic = arrêter.
BarItem {
    id: root
    want: Recorder.recording
    tooltip: "Arrêter l'enregistrement"
    padX: 9
    spacing: 7
    onClicked: Recorder.stop()

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 8
        height: 8
        radius: 4
        color: Theme.error
        SequentialAnimation on opacity {
            running: Recorder.recording
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
        }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Recorder.elapsedText
        font.family: Theme.monoFont
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: Theme.error
    }
}
