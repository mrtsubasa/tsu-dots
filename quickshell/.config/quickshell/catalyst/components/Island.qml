pragma ComponentBehavior: Bound
import QtQuick
import qs.rice

Rectangle {
    id: root
    radius: Chrome.islandRadius
    color: Qt.alpha(Theme.surfaceContainer, Identity.cfg.bar_opacity ?? 0.82)
    border.width: Identity.cfg.bar_border === false ? 0 : Chrome.borderW
    border.color: Qt.alpha(Theme.outlineVariant, 0.85)
    clip: true
}
