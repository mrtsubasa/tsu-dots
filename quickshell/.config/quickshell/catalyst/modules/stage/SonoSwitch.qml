import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Un effet à activer ou couper : `active` reflète le moteur, `act` envoie le choix.
RowLayout {
    id: sw
    property string label
    property string hint
    property bool active: false
    signal act(bool value)
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    spacing: 10
    Toggle {
        checked: sw.active
        disabled: !Sono.running || Sono.outdated
        onToggled: value => sw.act(value)
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        Txt { role: "label"; text: sw.label }
        Txt { Layout.fillWidth: true; role: "caption"; wrapMode: Text.WordWrap; text: sw.hint }
    }
}
