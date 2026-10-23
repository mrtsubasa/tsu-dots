pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Profil d'énergie (power-profiles-daemon) + « rester éveillé ».
ColumnLayout {
    id: root
    signal back()
    spacing: Tokens.sectionGap

    PageHeader {
        Layout.fillWidth: true
        title: "Énergie"
        subtitle: Power.degraded ? "Performances réduites (température)" : "Profil actuel : " + Power.current.label
        onBack: root.back()
    }

    Repeater {
        model: Power.profiles
        ListItem {
            required property var modelData
            Layout.fillWidth: true
            icon: modelData.icon
            title: modelData.label
            subtitle: modelData.desc
            selected: Power.profile === modelData.id
            checked: selected
            onClicked: Power.set(modelData.id)
        }
    }

    SectionHeader { Layout.fillWidth: true; text: "Veille" }

    ListItem {
        Layout.fillWidth: true
        icon: "coffee"
        title: "Rester éveillé"
        subtitle: Caffeine.on ? "La mise en veille et le verrouillage automatique sont suspendus" : "Veille automatique selon hypridle"
        Toggle {
            checked: Caffeine.on
            onToggled: Caffeine.toggle()
        }
        onClicked: Caffeine.toggle()
    }
}
