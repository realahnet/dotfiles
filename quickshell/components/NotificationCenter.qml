import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../services"

// Click-driven notification center. Same visual language as the hover cards:
// panel background, rounded corners, BackgroundEffect blur, OutBack scale.
PanelWindow {
    id: root
    property Item trigger: null
    property var screenInfo: null

    readonly property bool opened: ShellState.controlCenterOpen
    readonly property int count: Notifications.count
    readonly property int maxListHeight: 560
    readonly property int listHeight: count === 0
        ? 110
        : Math.min(maxListHeight, Math.max(1, list.contentHeight))

    implicitWidth: 440
    implicitHeight: 80 + listHeight
    color: "transparent"
    visible: showWindow && !LockState.locked
    anchors.top: true
    anchors.right: true
    margins.top: Theme.barHeight + 4
    margins.right: rightMargin
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    BackgroundEffect.blurRegion: Region {
        x: 0
        y: 0
        width: root.width
        height: root.height
        radius: Theme.radius + 2
    }

    function globalX(item) {
        let v = 0, i = item;
        while (i) { v += i.x; i = i.parent; }
        return v;
    }
    readonly property int rightMargin: {
        if (!trigger || !screen) return 12;
        return Math.max(0, screen.width - (globalX(trigger) + trigger.width));
    }

    property bool showWindow: false
    property real reveal: 0
    property bool opening: true

    function openPanel() {
        hideTimer.stop();
        opening = true;
        showWindow = true;
        reveal = 1;
    }
    function closePanel() {
        opening = false;
        reveal = 0;
        hideTimer.restart();
    }

    onOpenedChanged: opened ? openPanel() : closePanel()
    Component.onCompleted: if (opened) { showWindow = true; reveal = 1; }

    Timer { id: hideTimer; interval: 170; onTriggered: root.showWindow = false }

    Behavior on reveal {
        NumberAnimation {
            duration: root.opening ? 130 : 85
            easing.type: root.opening ? Easing.OutCubic : Easing.InCubic
        }
    }

    Item {
        id: card
        anchors.fill: parent
        opacity: root.reveal
        scale: 0.8 + 0.2 * root.reveal
        transformOrigin: Item.TopRight

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius + 2
            color: Theme.panelBg
            border.width: 1
            border.color: Theme.cardBorder
        }

        RowLayout {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 20
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 10

            StyledText {
                text: "Notifications"
                color: Theme.white
                font.pixelSize: 18
                font.weight: Font.Bold
            }
            StyledText {
                visible: root.count > 0
                text: root.count
                color: Theme.fgMuted
                font.pixelSize: 13
            }
            Item { Layout.fillWidth: true }

            StyledText {
                visible: root.count > 0
                text: "Clear all"
                color: clearHover.containsMouse ? Theme.white : Theme.fgMuted
                font.pixelSize: 13
                MouseArea {
                    id: clearHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.clearAll()
                }
            }

            StyledText {
                text: "󰅖"
                color: closeHover.containsMouse ? Theme.white : Theme.fgMuted
                font.pixelSize: 17
                MouseArea {
                    id: closeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellState.closeControlCenter()
                }
            }
        }

        Flickable {
            id: list
            anchors.top: parent.top
            anchors.topMargin: 60
            anchors.left: parent.left
            anchors.leftMargin: 20
            width: parent.width - 56
            height: root.listHeight
            contentWidth: width
            contentHeight: column.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            WheelHandler {
                onWheel: (event) => {
                    const maxY = Math.max(0, list.contentHeight - list.height);
                    const step = event.pixelDelta.y !== 0
                        ? event.pixelDelta.y * 1.5
                        : (event.angleDelta.y / 120) * 180;
                    list.contentY = Math.max(0, Math.min(maxY, list.contentY - step));
                    event.accepted = true;
                }
            }

            Column {
                id: column
                width: list.width
                spacing: 10

                Repeater {
                    model: Notifications.items.length
                    delegate: NotificationCard {
                        width: column.width
                        cardIndex: index
                    }
                }

                Item {
                    width: column.width
                    height: 110
                    visible: root.count === 0
                    StyledText {
                        anchors.centerIn: parent
                        text: "No notifications"
                        color: Theme.fgMuted
                        font.pixelSize: 14
                    }
                }
            }
        }

        Rectangle {
            id: scrollTrack
            enabled: false
            visible: list.contentHeight > list.height + 1
            anchors.top: list.top
            anchors.bottom: list.bottom
            anchors.left: list.right
            anchors.leftMargin: 12
            width: 4
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.07)

            Rectangle {
                width: parent.width
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.35)
                height: Math.max(28, list.visibleArea.heightRatio * list.height)
                y: list.visibleArea.yPosition * list.height
            }
        }
    }
}
