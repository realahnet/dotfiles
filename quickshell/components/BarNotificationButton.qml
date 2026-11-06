// BarNotificationButton.qml
// ---------------------------------------------------------------------------
// The bell on the far right. Hover it for the current count, click it to open
// the notification center.
// ---------------------------------------------------------------------------
import Quickshell
import QtQuick
import "../services"

Item {
    id: root
    implicitWidth: 18
    implicitHeight: Theme.barHeight
    property bool hovered: false
    property var screenInfo: null

    StyledText {
        anchors.centerIn: parent
        text: "󰂚"
        color: ShellState.controlCenterOpen || root.hovered ? Theme.white : Theme.fg
        font.pixelSize: 16
    }

    Rectangle {
        visible: Notifications.count > 0
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 6
        width: 5
        height: 5
        radius: 3
        color: Theme.white
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: ShellState.toggleControlCenter()
    }

    // Hover tooltip: how many notifications are waiting.
    HoverPopup {
        id: countTip
        trigger: root
        triggerHovered: root.hovered && !ShellState.controlCenterOpen && Notifications.toastCount === 0
        popupWidth: 150
        popupHeight: 34

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.panelBg
            border.width: 1
            border.color: Theme.cardBorder

            StyledText {
                anchors.centerIn: parent
                text: Notifications.count === 0
                    ? "No notifications"
                    : (Notifications.count === 1
                        ? "1 notification"
                        : Notifications.count + " notifications")
                color: Theme.fg
                font.pixelSize: 11
            }
        }
    }

    NotificationCenter {
        id: center
        trigger: root
        screenInfo: root.screenInfo
    }

    NotificationCatcher {
        center: center
        screenInfo: root.screenInfo
    }

    NotificationToast {
        screenInfo: root.screenInfo
    }
}
