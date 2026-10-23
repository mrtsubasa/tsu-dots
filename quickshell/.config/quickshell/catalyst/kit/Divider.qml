import QtQuick
import qs.rice

Rectangle {
    property bool vertical: false
    implicitWidth: vertical ? 1 : 100
    implicitHeight: vertical ? 16 : 1
    color: Theme.divider
}
