pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.rice
import "../../components"

Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: PanelService.active === "pkgs" && PanelService.onScreen(modelData)
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "catalyst-panel"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }

            property real appear: visible ? 1 : 0
            Behavior on appear { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

            onVisibleChanged: {
                if (visible) {
                    PkgsData.reset();
                    search.focus = true;
                    search.text = PkgsData.query;
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: PanelService.hide()
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.scrim
                opacity: win.appear
            }

            Item {
                id: card
                width: Math.min(860, parent.width - 40)
                height: Math.min(720, parent.height - 56)
                anchors.horizontalCenter: parent.horizontalCenter
                y: (parent.height - height) * 0.38 + (1 - win.appear) * 36
                opacity: win.appear
                scale: 0.96 + win.appear * 0.04
                transformOrigin: Item.Center

                MouseArea { anchors.fill: parent }

                Surface {
                    anchors.fill: parent
                    elev: 3
                    photo: true
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12
                    z: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Rectangle {
                            Layout.preferredWidth: headRow.implicitWidth + 22
                            Layout.preferredHeight: 36
                            radius: 18
                            color: Qt.alpha(Theme.primary, 0.18)
                            Row {
                                id: headRow
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    text: "󰏖"
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                    color: Theme.primary
                                }
                                Text {
                                    text: "Shop"
                                    font.family: Theme.uiFont
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    color: Theme.ink
                                }
                            }
                        }
                        Text {
                            text: PkgsData.busy ? "󰦖 " + PkgsData.status : PkgsData.status
                            font.family: Theme.uiFont
                            font.pixelSize: 12
                            color: Theme.inkMuted
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Rectangle {
                            visible: PkgsData.updates > 0
                            Layout.preferredWidth: updLab.implicitWidth + 18
                            Layout.preferredHeight: 30
                            radius: 15
                            color: Qt.alpha(Theme.tertiary, 0.22)
                            border.width: 1
                            border.color: Theme.tertiary
                            Text {
                                id: updLab
                                anchors.centerIn: parent
                                text: PkgsData.updates + " maj"
                                font.family: Theme.uiFont
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: Theme.tertiary
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    PkgsData.setPage("updates");
                                    search.text = "";
                                }
                            }
                        }
                        Rectangle {
                            visible: PkgsData.page === "updates" && PkgsData.count > 0
                            Layout.preferredWidth: allUpLab.implicitWidth + 22
                            Layout.preferredHeight: 32
                            radius: 16
                            color: Theme.primary
                            Text {
                                id: allUpLab
                                anchors.centerIn: parent
                                text: "Tout maj"
                                font.family: Theme.uiFont
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: Theme.inkPrimary
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: PkgsData.upgrade()
                            }
                        }
                        IconBtn {
                            icon: "󰚰"
                            onClicked: PkgsData.upgrade()
                        }
                        IconBtn {
                            icon: "󰅖"
                            accent: Theme.inkMuted
                            onClicked: PanelService.hide()
                        }
                    }

                    Rectangle {
                        visible: PkgsData.page !== "repos" && PkgsData.page !== "updates" && PkgsData.page !== "installed"
                        Layout.fillWidth: true
                        height: visible ? 52 : 0
                        radius: 22
                        color: Qt.alpha(Theme.surfaceContainerLowest, 0.72)
                        border.width: 1
                        border.color: search.activeFocus ? Theme.primary : Qt.alpha(Theme.hairline, 0.8)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 10
                            spacing: 10
                            z: 1
                            Text {
                                text: PkgsData.page === "need" ? "󱚣" : "󰍉"
                                font.family: Theme.font
                                font.pixelSize: 18
                                color: Theme.primary
                            }
                            TextInput {
                                id: search
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: Theme.ink
                                font.family: Theme.uiFont
                                font.pixelSize: 16
                                verticalAlignment: Text.AlignVCenter
                                selectByMouse: true
                                Keys.onEscapePressed: PanelService.hide()
                                Keys.onReturnPressed: {
                                    const q = text.trim();
                                    if (!q.length)
                                        return;
                                    if (PkgsData.page === "name")
                                        PkgsData.runName(q);
                                    else
                                        PkgsData.runNeed(q);
                                }
                            }
                            Rectangle {
                                Layout.preferredWidth: goLab.implicitWidth + 20
                                Layout.preferredHeight: 32
                                radius: 16
                                color: Theme.primary
                                Text {
                                    id: goLab
                                    anchors.centerIn: parent
                                    text: PkgsData.page === "need" ? "IA" : "Go"
                                    font.family: Theme.uiFont
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    color: Theme.inkPrimary
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const q = search.text.trim();
                                        if (!q.length)
                                            return;
                                        if (PkgsData.page === "name")
                                            PkgsData.runName(q);
                                        else
                                            PkgsData.runNeed(q);
                                    }
                                }
                            }
                        }

                        Text {
                            visible: search.text.length === 0 && !search.activeFocus
                            z: 0
                            anchors.left: parent.left
                            anchors.leftMargin: 46
                            anchors.verticalCenter: parent.verticalCenter
                            text: PkgsData.page === "name"
                                  ? "Nom de paquet (firefox, neovim…)"
                                  : "Besoin : « un navigateur privé », « montage vidéo »…"
                            font.family: Theme.uiFont
                            font.pixelSize: 14
                            color: Theme.inkMuted
                        }
                    }

                    ColumnLayout {
                        visible: PkgsData.page === "repos"
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: "SOURCES · wiki Arch + ton pacman.conf"
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 1.2
                            color: Theme.inkMuted
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: 14
                            color: Qt.alpha(Theme.surfaceContainerLowest, 0.72)
                            border.width: 1
                            border.color: repoSearch.activeFocus ? Theme.primary : Theme.hairline
                            TextInput {
                                id: repoSearch
                                anchors.fill: parent
                                anchors.margins: 10
                                color: Theme.ink
                                font.family: Theme.uiFont
                                font.pixelSize: 13
                                clip: true
                                selectByMouse: true
                                onTextChanged: PkgsData.setRepoQuery(text)
                            }
                            Text {
                                visible: !repoSearch.text.length && !repoSearch.activeFocus
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                text: "Filtrer : chaotic, blackarch, kernel, seblu…"
                                font.family: Theme.uiFont
                                font.pixelSize: 12
                                color: Theme.inkMuted
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Rectangle {
                                Layout.preferredWidth: 120
                                Layout.preferredHeight: 36
                                radius: 14
                                color: Qt.alpha(Theme.surfaceContainerHigh, 0.55)
                                border.width: 1
                                border.color: Theme.hairline
                                TextInput {
                                    id: repoName
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    color: Theme.ink
                                    font.family: Theme.uiFont
                                    font.pixelSize: 12
                                    clip: true
                                    selectByMouse: true
                                }
                                Text {
                                    visible: !repoName.text.length && !repoName.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    text: "Nom"
                                    font.family: Theme.uiFont
                                    font.pixelSize: 12
                                    color: Theme.inkMuted
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: 14
                                color: Qt.alpha(Theme.surfaceContainerHigh, 0.55)
                                border.width: 1
                                border.color: Theme.hairline
                                TextInput {
                                    id: repoSrc
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    color: Theme.ink
                                    font.family: Theme.uiFont
                                    font.pixelSize: 12
                                    clip: true
                                    selectByMouse: true
                                    Keys.onReturnPressed: PkgsData.addRepo(repoName.text, repoSrc.text)
                                }
                                Text {
                                    visible: !repoSrc.text.length && !repoSrc.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    text: "Include=/… ou https://…"
                                    font.family: Theme.uiFont
                                    font.pixelSize: 12
                                    color: Theme.inkMuted
                                }
                            }
                            Rectangle {
                                Layout.preferredWidth: addLab.implicitWidth + 20
                                Layout.preferredHeight: 36
                                radius: 14
                                color: Theme.primary
                                Text {
                                    id: addLab
                                    anchors.centerIn: parent
                                    text: "Ajouter"
                                    font.family: Theme.uiFont
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    color: Theme.inkPrimary
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: PkgsData.addRepo(repoName.text, repoSrc.text)
                                }
                            }
                        }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        clip: true
                        contentWidth: pageRow.implicitWidth
                        boundsBehavior: Flickable.StopAtBounds
                        Row {
                            id: pageRow
                            spacing: 6
                            Repeater {
                                model: PkgsData.pages
                                delegate: Rectangle {
                                    id: pChip
                                    required property var modelData
                                    readonly property bool on: PkgsData.page === modelData.id
                                    height: 34
                                    width: pRow.implicitWidth + 18
                                    radius: 17
                                    color: on ? Theme.primary : Qt.alpha(Theme.surfaceContainerHigh, 0.55)
                                    border.width: on ? 0 : 1
                                    border.color: Theme.hairline
                                    Row {
                                        id: pRow
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text {
                                            text: pChip.modelData.glyph
                                            font.family: Theme.font
                                            font.pixelSize: 13
                                            color: pChip.on ? Theme.inkPrimary : Theme.ink
                                        }
                                        Text {
                                            text: pChip.modelData.label
                                            font.family: Theme.uiFont
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            color: pChip.on ? Theme.inkPrimary : Theme.ink
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            PkgsData.setPage(pChip.modelData.id);
                                            if (pChip.modelData.id === "need" || pChip.modelData.id === "name")
                                                search.forceActiveFocus();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Flickable {
                        visible: PkgsData.page !== "repos"
                        Layout.fillWidth: true
                        implicitHeight: visible ? 34 : 0
                        clip: true
                        contentWidth: srcRow.implicitWidth
                        boundsBehavior: Flickable.StopAtBounds
                        Row {
                            id: srcRow
                            spacing: 5
                            Repeater {
                                model: PkgsData.sourceCount
                                delegate: Rectangle {
                                    id: sChip
                                    required property int index
                                    readonly property var src: PkgsData.sourceAt(index)
                                    readonly property bool on: PkgsData.source === (src ? src.id : "")
                                    height: 30
                                    width: sLab.implicitWidth + 16
                                    radius: 15
                                    color: on ? Theme.primary : Qt.alpha(Theme.surfaceContainerHigh, 0.4)
                                    border.width: on ? 0 : 1
                                    border.color: Theme.hairline
                                    Text {
                                        id: sLab
                                        anchors.centerIn: parent
                                        text: (sChip.src && sChip.src.glyph ? sChip.src.glyph + " " : "") + (sChip.src ? sChip.src.label : "")
                                        font.family: Theme.uiFont
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: sChip.on ? Theme.inkPrimary : Theme.inkMuted
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (sChip.src)
                                                PkgsData.setSource(sChip.src.id);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Flickable {
                        visible: PkgsData.page !== "repos"
                        Layout.fillWidth: true
                        implicitHeight: visible ? 34 : 0
                        clip: true
                        contentWidth: catRow.implicitWidth
                        boundsBehavior: Flickable.StopAtBounds
                        Row {
                            id: catRow
                            spacing: 5
                            Repeater {
                                model: PkgsData.catCount
                                delegate: Rectangle {
                                    id: cChip
                                    required property int index
                                    readonly property var cat: PkgsData.catAt(index)
                                    readonly property bool on: PkgsData.page === "cat" && PkgsData.catId === (cat ? cat.id : "")
                                    height: 30
                                    width: cLab.implicitWidth + 16
                                    radius: 15
                                    color: on ? Qt.alpha(Theme.tertiary, 0.28) : Qt.alpha(Theme.surfaceContainerHigh, 0.35)
                                    border.width: 1
                                    border.color: on ? Theme.tertiary : Theme.hairline
                                    Text {
                                        id: cLab
                                        anchors.centerIn: parent
                                        text: (cChip.cat ? cChip.cat.glyph + " " : "") + (cChip.cat ? cChip.cat.label : "")
                                        font.family: Theme.uiFont
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: cChip.on ? Theme.tertiary : Theme.inkMuted
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (cChip.cat)
                                                PkgsData.setCat(cChip.cat.id);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: PkgsData.why.length > 0
                        Layout.fillWidth: true
                        implicitHeight: whyTxt.implicitHeight + 16
                        radius: 16
                        color: Qt.alpha(Theme.primary, 0.12)
                        border.width: 1
                        border.color: Qt.alpha(Theme.primary, 0.28)
                        Text {
                            id: whyTxt
                            anchors.fill: parent
                            anchors.margins: 10
                            text: PkgsData.why
                            wrapMode: Text.Wrap
                            font.family: Theme.uiFont
                            font.pixelSize: 12
                            color: Theme.primary
                        }
                    }

                    ListView {
                        id: list
                        visible: PkgsData.page !== "repos"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 8
                        model: PkgsData.count
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            id: row
                            required property int index
                            readonly property var pkg: PkgsData.at(index)
                            readonly property bool isUpd: !!(pkg && (pkg.update || PkgsData.page === "updates"))
                            width: list.width
                            height: Math.max(72, bodyCol.implicitHeight + 20)
                            radius: 18
                            color: Qt.alpha(Theme.surfaceContainerLow, 0.55)
                            border.width: 1
                            border.color: isUpd
                                          ? Qt.alpha(Theme.tertiary, 0.45)
                                          : (pkg && pkg.installed ? Qt.alpha(Theme.success, 0.45) : Theme.hairline)

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Rectangle {
                                    Layout.preferredWidth: 44
                                    Layout.preferredHeight: 44
                                    radius: 14
                                    color: Qt.alpha(Theme.primary, 0.16)
                                    Text {
                                        anchors.centerIn: parent
                                        text: row.isUpd ? "󰚰" : (row.pkg && row.pkg.aur ? "󰣇" : "󰏗")
                                        font.family: Theme.font
                                        font.pixelSize: 18
                                        color: Theme.primary
                                    }
                                }

                                Column {
                                    id: bodyCol
                                    Layout.fillWidth: true
                                    spacing: 3
                                    Row {
                                        spacing: 8
                                        Text {
                                            text: row.pkg ? row.pkg.name : ""
                                            font.family: Theme.uiFont
                                            font.pixelSize: 14
                                            font.weight: Font.DemiBold
                                            color: Theme.ink
                                        }
                                        Rectangle {
                                            visible: !!(row.pkg && row.pkg.aur)
                                            width: aurLab.implicitWidth + 10
                                            height: 18
                                            radius: 9
                                            color: Qt.alpha(Theme.tertiary, 0.22)
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text {
                                                id: aurLab
                                                anchors.centerIn: parent
                                                text: "AUR"
                                                font.family: Theme.uiFont
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                                color: Theme.tertiary
                                            }
                                        }
                                        Rectangle {
                                            visible: !!(row.pkg && row.pkg.installed) && !row.isUpd
                                            width: onLab.implicitWidth + 10
                                            height: 18
                                            radius: 9
                                            color: Qt.alpha(Theme.success, 0.22)
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text {
                                                id: onLab
                                                anchors.centerIn: parent
                                                text: "installé"
                                                font.family: Theme.uiFont
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                                color: Theme.success
                                            }
                                        }
                                    }
                                    Text {
                                        width: parent.width
                                        text: row.pkg ? (row.pkg.desc || row.pkg.why || "") : ""
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        font.family: Theme.uiFont
                                        font.pixelSize: 12
                                        color: Theme.inkMuted
                                    }
                                    Text {
                                        visible: !!(row.pkg && (row.pkg.ver || row.pkg.repo))
                                        text: (row.pkg && row.pkg.repo ? row.pkg.repo : "") + (row.pkg && row.pkg.ver ? "  ·  " + row.pkg.ver : "")
                                        font.family: Theme.font
                                        font.pixelSize: 10
                                        color: Theme.inkMuted
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: actLab.implicitWidth + 22
                                    Layout.preferredHeight: 34
                                    radius: 17
                                    color: row.isUpd
                                           ? Theme.primary
                                           : (row.pkg && row.pkg.installed
                                              ? Qt.alpha(Theme.error, 0.18)
                                              : Theme.primary)
                                    border.width: !row.isUpd && row.pkg && row.pkg.installed ? 1 : 0
                                    border.color: Theme.error
                                    Text {
                                        id: actLab
                                        anchors.centerIn: parent
                                        text: row.isUpd
                                              ? "Mettre à jour"
                                              : (row.pkg && row.pkg.installed ? "Retirer" : "Installer")
                                        font.family: Theme.uiFont
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        color: row.isUpd
                                               ? Theme.inkPrimary
                                               : (row.pkg && row.pkg.installed ? Theme.error : Theme.inkPrimary)
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (!row.pkg || !row.pkg.name)
                                                return;
                                            if (row.isUpd)
                                                PkgsData.upgradeOne(row.pkg.name);
                                            else if (row.pkg.installed)
                                                PkgsData.remove(row.pkg.name);
                                            else
                                                PkgsData.install(row.pkg.name);
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !PkgsData.busy && PkgsData.count === 0
                            text: PkgsData.page === "updates"
                                  ? "Système à jour"
                                  : (PkgsData.page === "installed"
                                     ? "Aucun paquet listé"
                                     : "Lance une recherche")
                            font.family: Theme.uiFont
                            font.pixelSize: 14
                            color: Theme.inkMuted
                        }
                    }

                    ListView {
                        id: repoList
                        visible: PkgsData.page === "repos"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 8
                        model: PkgsData.repoCount
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            id: rrow
                            required property int index
                            readonly property var repo: PkgsData.repoAt(index)
                            width: repoList.width
                            height: 78
                            radius: 18
                            color: Qt.alpha(Theme.surfaceContainerLow, 0.55)
                            border.width: 1
                            border.color: repo && repo.enabled ? Qt.alpha(Theme.success, 0.45) : Theme.hairline

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12
                                Rectangle {
                                    Layout.preferredWidth: 44
                                    Layout.preferredHeight: 44
                                    radius: 14
                                    color: Qt.alpha(Theme.primary, 0.16)
                                    Text {
                                        anchors.centerIn: parent
                                        text: rrow.repo ? (rrow.repo.glyph || "󰏒") : "󰏒"
                                        font.family: Theme.font
                                        font.pixelSize: 18
                                        color: Theme.primary
                                    }
                                }
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 3
                                    Row {
                                        spacing: 8
                                        Text {
                                            text: rrow.repo ? rrow.repo.label : ""
                                            font.family: Theme.uiFont
                                            font.pixelSize: 14
                                            font.weight: Font.DemiBold
                                            color: Theme.ink
                                        }
                                        Rectangle {
                                            visible: !!(rrow.repo && rrow.repo.enabled)
                                            width: enLab.implicitWidth + 10
                                            height: 18
                                            radius: 9
                                            color: Qt.alpha(Theme.success, 0.22)
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text {
                                                id: enLab
                                                anchors.centerIn: parent
                                                text: "actif"
                                                font.family: Theme.uiFont
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                                color: Theme.success
                                            }
                                        }
                                    }
                                    Text {
                                        width: parent.width
                                        text: rrow.repo ? ((rrow.repo.group ? "[" + rrow.repo.group + "] " : "") + (rrow.repo.desc || "")) : ""
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        font.family: Theme.uiFont
                                        font.pixelSize: 12
                                        color: Theme.inkMuted
                                    }
                                    Text {
                                        text: rrow.repo ? (rrow.repo.status || "") : ""
                                        font.family: Theme.font
                                        font.pixelSize: 10
                                        color: Theme.inkMuted
                                    }
                                }
                                Rectangle {
                                    Layout.preferredWidth: rAct.implicitWidth + 22
                                    Layout.preferredHeight: 34
                                    radius: 17
                                    color: rrow.repo && rrow.repo.enabled
                                           ? Qt.alpha(Theme.surfaceContainerHigh, 0.7)
                                           : Theme.primary
                                    Text {
                                        id: rAct
                                        anchors.centerIn: parent
                                        text: rrow.repo && rrow.repo.enabled ? "OK" : "Activer"
                                        font.family: Theme.uiFont
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        color: rrow.repo && rrow.repo.enabled ? Theme.inkMuted : Theme.inkPrimary
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: !(rrow.repo && rrow.repo.enabled)
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            if (rrow.repo && rrow.repo.id)
                                                PkgsData.enableRepo(rrow.repo.id);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: PkgsData.page === "repos"
                              ? "sources pacman / AUR · Activer ouvre un terminal"
                              : ("helper · " + PkgsData.helper + "  ·  actions dans un terminal")
                        font.family: Theme.uiFont
                        font.pixelSize: 10
                        color: Theme.inkMuted
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
