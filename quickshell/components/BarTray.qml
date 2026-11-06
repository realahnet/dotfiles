// BarTray.qml
// ---------------------------------------------------------------------------
// Replaces waybar's "tray" module. SystemTray is a Quickshell service that
// listens to the StatusNotifierItem protocol.
// ---------------------------------------------------------------------------
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import "../services"

Row {
    id: root
    spacing: 8
    visible: SystemTray.items.values.length > 0
    property var barWindow: null
    property var menuItem: null
    property Item menuAnchor: null
    property bool menuOpen: false

    function showMenu(item) {
        if (!item || !item.modelData || !item.modelData.hasMenu)
            return;
        menuItem = item.modelData;
        menuAnchor = item;
        menuOpen = true;
    }

    function closeMenu() {
        menuOpen = false;
        menuItem = null;
        menuAnchor = null;
    }

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem
            required property var modelData
            implicitWidth: 18
            implicitHeight: 18

            readonly property string iconSource: {
                const raw = modelData.icon;
                if (!raw)
                    return "";
                if (raw.indexOf("image://") === 0 || raw.charAt(0) === "/")
                    return raw;
                const resolved = Quickshell.iconPath(raw, true);
                return resolved !== "" ? resolved : raw;
            }

            Image {
                anchors.centerIn: parent
                source: trayItem.iconSource
                sourceSize.width: 16
                sourceSize.height: 16
                smooth: true
                visible: status === Image.Ready
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        if (!modelData.hasMenu)
                            return;
                        if (root.menuOpen && root.menuItem === modelData)
                            root.closeMenu();
                        else
                            root.showMenu(trayItem);
                    } else if (mouse.button === Qt.MiddleButton) {
                        root.closeMenu();
                        modelData.secondaryActivate();
                    } else {
                        if (root.menuOpen && root.menuItem === modelData) {
                            root.closeMenu();
                            return;
                        }
                        root.closeMenu();
                        if (modelData.onlyMenu && modelData.hasMenu)
                            root.showMenu(trayItem);
                        else
                            modelData.activate();
                    }
                }

                onWheel: (wheel) => {
                    modelData.scroll(wheel.angleDelta.y, wheel.angleDelta.x !== 0);
                }
            }
        }
    }

    TrayMenu {
        barWindow: root.barWindow
        anchorItem: root.menuAnchor
        menu: root.menuItem ? root.menuItem.menu : null
        open: root.menuOpen
        onCloseRequested: root.closeMenu()
    }

    TrayMenuCatcher {
        open: root.menuOpen
        screenInfo: root.barWindow ? root.barWindow.screen : null
        onCloseRequested: root.closeMenu()
    }
}
