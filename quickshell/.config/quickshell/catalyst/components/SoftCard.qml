pragma ComponentBehavior: Bound
import QtQuick
import qs.rice

Rectangle {
    id: root
    radius: Tokens.rLg
    clip: true
    border.width: 1
    border.color: Tokens.borderOf(0.7)
    color: Qt.alpha(Theme.surfaceContainerLow, 0.45)
    gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.alpha(Theme.primary, 0.10) }
        GradientStop { position: 1.0; color: Qt.alpha(Theme.surfaceContainerLow, 0.38) }
    }
}
