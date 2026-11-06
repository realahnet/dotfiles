import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services"

// Full-screen transparent catcher shown while the notification center is open.
// Its input mask excludes the center (plus a margin), so clicks on the center
// reach the panel and clicks anywhere else close it.
PanelWindow {
    id: root
    property var center: null
    property var screenInfo: null

    visible: ShellState.controlCenterOpen && !LockState.locked
    screen: center ? center.screen : screenInfo
    color: "transparent"
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    margins.top: -Theme.barHeight
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell-notification-catcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property real centerX: {
        if (!center || !screen) return 0;
        return screen.width - center.rightMargin - center.implicitWidth;
    }

    mask: Region {
        x: 0
        y: 0
        width: root.width
        height: root.height

        Region {
            x: Math.max(0, root.centerX - 40)
            y: 16
            width: Math.min(root.width, (center ? center.implicitWidth : 0) + 80)
            height: Math.min(root.height, (center ? center.implicitHeight : 0) + 180)
            intersection: Intersection.Subtract
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: ShellState.closeControlCenter()
    }
}
