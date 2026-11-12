import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../services"

// Context menu for a StatusNotifierItem. Built from its DBusMenu tree with a
// QsMenuOpener, so it can be themed and blurred like the rest of the shell.
PanelWindow {
    id: root
    property var barWindow: null
    property Item anchorItem: null
    property var menu: null
    property bool open: false
    property var currentMenu: null
    property var stack: []
    property real reveal: 0
    signal closeRequested()

    readonly property var entries: opener.children.values
    readonly property real anchorX: {
        if (!anchorItem || !barWindow) return 0;
        return anchorItem.mapToItem(barWindow.contentItem, 0, 0).x;
    }

    implicitWidth: 250
    implicitHeight: body.implicitHeight + 12
    visible: open && menu !== null
    screen: barWindow ? barWindow.screen : null
    color: "transparent"
    anchors.top: true
    anchors.left: true
    margins.top: Theme.barHeight + 4
    margins.left: Math.max(8, Math.min(Math.round(anchorX),
        (screen ? screen.width : 1920) - implicitWidth - 8))
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell-tray-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    BackgroundEffect.blurRegion: Region {
        x: 0; y: 0
        width: root.width
        height: root.height
        radius: Theme.radius
    }

    QsMenuOpener {
        id: opener
        menu: root.currentMenu
    }

    onOpenChanged: {
        if (open) {
            stack = [];
            currentMenu = menu;
            reveal = 1;
        } else {
            reveal = 0;
        }
    }
    onMenuChanged: {
        if (open) {
            stack = [];
            currentMenu = menu;
        }
    }

    Behavior on reveal {
        NumberAnimation {
            duration: root.open ? 200 : 140
            easing.type: root.open ? Easing.OutCubic : Easing.InCubic
        }
    }

    Item {
        id: card
        anchors.fill: parent
        opacity: root.reveal
        scale: 0.96 + 0.04 * root.reveal
        transformOrigin: Item.TopLeft

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.panelBg
            border.width: 1
            border.color: Theme.cardBorder
        }

        Column {
            id: body
            anchors.fill: parent
            anchors.margins: 6
            spacing: 0

            Rectangle {
                visible: root.stack.length > 0
                width: body.width
                height: 28
                radius: 4
                color: backHover.containsMouse ? Theme.elevated : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6
                    StyledText { text: "󰁍"; color: Theme.fgMuted; font.pixelSize: 12 }
                    StyledText { Layout.fillWidth: true; text: "Back"; color: Theme.fg; font.pixelSize: 12 }
                }
                MouseArea {
                    id: backHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.goBack()
                }
            }

            Repeater {
                model: root.entries
                delegate: Item {
                    id: row
                    required property var modelData
                    readonly property bool sep: modelData.isSeparator
                    width: body.width
                    height: sep ? 9 : 28

                    Rectangle {
                        visible: row.sep
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        height: 1
                        color: Theme.cardBorder
                    }

                    Rectangle {
                        visible: !row.sep
                        anchors.fill: parent
                        radius: 4
                        color: (entryHover.containsMouse && row.modelData.enabled)
                            ? Theme.elevated
                            : "transparent"
                    }

                    RowLayout {
                        visible: !row.sep
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        StyledText {
                            Layout.preferredWidth: 16
                            text: {
                                if (row.modelData.buttonType === QsMenuButtonType.CheckBox)
                                    return row.modelData.checkState === Qt.Checked ? "󰄬" : "";
                                if (row.modelData.buttonType === QsMenuButtonType.RadioButton)
                                    return row.modelData.checkState === Qt.Checked ? "󰄰" : "";
                                return "";
                            }
                            color: row.modelData.enabled ? Theme.fg : Theme.fgMuted
                            font.pixelSize: 12
                        }

                        Image {
                            id: entryIcon
                            visible: row.modelData.icon !== ""
                            source: row.modelData.icon
                            sourceSize.width: 16
                            sourceSize.height: 16
                            Layout.preferredWidth: visible ? 16 : 0
                            Layout.preferredHeight: 16
                            smooth: true
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: row.modelData.text
                            textFormat: Text.RichText
                            color: row.modelData.enabled ? Theme.fg : Theme.fgMuted
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        StyledText {
                            visible: row.modelData.hasChildren
                            text: "󰅂"
                            color: Theme.fgMuted
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        id: entryHover
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !row.sep && row.modelData.enabled
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (row.modelData.hasChildren) {
                                root.pushSubmenu(row.modelData);
                            } else {
                                row.modelData.triggered();
                                root.closeRequested();
                            }
                        }
                    }
                }
            }
        }
    }

    function pushSubmenu(entry) {
        stack = stack.concat([currentMenu]);
        currentMenu = entry;
    }

    function goBack() {
        if (stack.length === 0) return;
        currentMenu = stack[stack.length - 1];
        stack = stack.slice(0, stack.length - 1);
    }
}
