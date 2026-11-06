import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services"

// Click catcher behind the tray menu. Starts below the bar so tray icons
// stay clickable (switching menus), and the bar handles its own clicks.
PanelWindow {
    id: root
    property bool open: false
    property var screenInfo: null
    signal closeRequested()

    visible: open
    screen: screenInfo
    color: "transparent"
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    margins.top: Theme.barHeight
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell-tray-menu-catcher"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }
}
