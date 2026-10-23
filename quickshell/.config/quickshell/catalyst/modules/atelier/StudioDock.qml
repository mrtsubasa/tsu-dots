pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import "../../components"

Flickable {
    id: root
    clip: true
    contentHeight: col.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        id: col
        width: root.width
        spacing: 10

        Text { text: "DOCK"; font.family: Theme.uiFont; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        RowLayout {
            Chip { label: "On"; on: DockCfg.enabled; onClicked: DockCfg.set("enabled", true) }
            Chip { label: "Off"; on: !DockCfg.enabled; onClicked: DockCfg.set("enabled", false) }
        }

        Text { text: "STYLE"; font.family: Theme.uiFont; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 6
            rowSpacing: 6
            Chip { label: "Apple"; on: DockCfg.theme === "apple"; onClicked: DockCfg.set("theme", "apple") }
            Chip { label: "Wolf"; on: DockCfg.theme === "silverwolf"; onClicked: DockCfg.set("theme", "silverwolf") }
            Chip { label: "Lain"; on: DockCfg.theme === "lain"; onClicked: DockCfg.set("theme", "lain") }
            Chip { label: "Tsubasa"; on: DockCfg.theme === "tsubasa"; onClicked: DockCfg.set("theme", "tsubasa") }
            Chip { label: "AE86"; on: DockCfg.theme === "initiald"; onClicked: DockCfg.set("theme", "initiald") }
            Chip { label: "Minimal"; on: DockCfg.theme === "minimal"; onClicked: DockCfg.set("theme", "minimal") }
        }

        Text { text: "TAILLE"; font.family: Theme.uiFont; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        RowLayout {
            Chip { label: "32"; on: DockCfg.iconSize <= 34; onClicked: DockCfg.set("iconSize", 32) }
            Chip { label: "40"; on: DockCfg.iconSize > 34 && DockCfg.iconSize < 45; onClicked: DockCfg.set("iconSize", 40) }
            Chip { label: "48"; on: DockCfg.iconSize >= 45 && DockCfg.iconSize < 56; onClicked: DockCfg.set("iconSize", 48) }
            Chip { label: "64"; on: DockCfg.iconSize >= 56; onClicked: DockCfg.set("iconSize", 64) }
        }

        Text { text: "ZOOM"; font.family: Theme.uiFont; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        RowLayout {
            Chip { label: "Off"; on: DockCfg.zoom < 1.2; onClicked: DockCfg.set("zoom", 1) }
            Chip { label: "Léger"; on: DockCfg.zoom >= 1.2 && DockCfg.zoom < 1.65; onClicked: DockCfg.set("zoom", 1.45) }
            Chip { label: "Apple"; on: DockCfg.zoom >= 1.65; onClicked: DockCfg.set("zoom", 1.88) }
        }

        Text { text: "POSITION"; font.family: Theme.uiFont; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 6
            rowSpacing: 6
            Chip { label: "Bas"; on: DockCfg.position === "bottom"; onClicked: DockCfg.set("position", "bottom") }
            Chip { label: "Haut"; on: DockCfg.position === "top"; onClicked: DockCfg.set("position", "top") }
            Chip { label: "Gauche"; on: DockCfg.position === "left"; onClicked: DockCfg.set("position", "left") }
            Chip { label: "Droite"; on: DockCfg.position === "right"; onClicked: DockCfg.set("position", "right") }
        }

        Text { text: "OPACITÉ / MARGE"; font.family: Theme.uiFont; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.inkMuted }
        RowLayout {
            Chip { label: "50%"; on: DockCfg.opacity < 0.62; onClicked: DockCfg.set("opacity", 0.5) }
            Chip { label: "75%"; on: DockCfg.opacity >= 0.62 && DockCfg.opacity < 0.9; onClicked: DockCfg.set("opacity", 0.75) }
            Chip { label: "100%"; on: DockCfg.opacity >= 0.9; onClicked: DockCfg.set("opacity", 1) }
        }
        RowLayout {
            Chip { label: "Collé"; onClicked: DockCfg.set("margin", 4) }
            Chip { label: "10"; onClicked: DockCfg.set("margin", 10) }
            Chip { label: "20"; onClicked: DockCfg.set("margin", 20) }
        }
        RowLayout {
            Chip { label: "Autohide"; on: DockCfg.autohide; onClicked: DockCfg.toggle("autohide") }
            Chip { label: "Pilule"; on: DockCfg.showPill; onClicked: DockCfg.toggle("showPill") }
            Chip { label: "Points"; on: DockCfg.showDots; onClicked: DockCfg.toggle("showDots") }
        }

        Text {
            text: "Clic droit sur une icône pour la retirer."
            font.family: Theme.uiFont
            font.pixelSize: 11
            color: Theme.inkMuted
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }
}
