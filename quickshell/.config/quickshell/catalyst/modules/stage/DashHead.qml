import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Micro-titre de tuile du dashboard : « // TITRE » à gauche, méta à droite.
RowLayout {
    id: h
    property string label: ""
    property string meta: ""
    spacing: 8
    Txt { role: "overline"; text: "// " + h.label; color: Theme.accent }
    Item { Layout.fillWidth: true }
    Txt { role: "mono"; text: h.meta; color: Theme.textFaint; font.pixelSize: 10 }
}
