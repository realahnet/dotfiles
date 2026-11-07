// Bar.qml
// ---------------------------------------------------------------------------
// The whole top bar. One PanelWindow is created per monitor, so unplugging a
// screen or adding one Just Works.
//
// PanelWindow is a Wayland layer-shell surface: no window decorations, it
// sits on top of normal windows and reserves "exclusiveZone" pixels of space.
//
// Spacing: the RowLayout has spacing 0. Every right-side module instead has
// its own 8px left/right padding. That is exactly how waybar's CSS behaved
// (padding: 0 8px on each module), and it keeps the gaps identical whether a
// module is a short icon or a long "Good evening, ahnet" string.
// ---------------------------------------------------------------------------
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../services"

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData

            // The Hyprland monitor that matches this Quickshell screen.
            readonly property var hyprMonitor: Hyprland.monitorFor(modelData)

            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: Theme.barHeight
            exclusiveZone: Theme.barHeight
            color: "transparent"
            BackgroundEffect.blurRegion: Region { item: barWindow.contentItem }

            // Tell Hyprland this is our bar. Useful for layer rules.
            WlrLayershell.namespace: "quickshell-bar"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            // Layer-shell windows are transparent by default; draw the bar.
            Rectangle {
                anchors.fill: parent
                color: Theme.barBg

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 12
                    spacing: 0

                    BarWorkspaces {
                        monitor: barWindow.hyprMonitor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // This spacer pushes everything after it to the right.
                    Item { Layout.fillWidth: true }

                    BarGreeting {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                    }
                    BarTray {
                        id: tray
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        barWindow: barWindow
                    }
                    BarAudio {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                    }
                    BarBattery {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                    }
                    BarClock {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                    }
                    BarNotificationButton {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        screenInfo: barWindow.screen
                    }
                }

                BarMedia {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    barWindow: barWindow
                    z: 1
                }
            }

            // While a tray menu is open, clicks elsewhere on the bar close it.
            // The tray icons themselves are left exposed so a right click on
            // another icon can switch menus directly.
            Item {
                id: trayClickBlocker
                anchors.fill: parent
                z: 10
                visible: tray.menuOpen

                readonly property real holeX: {
                    const p = tray.mapToItem(trayClickBlocker, 0, 0);
                    return Math.max(0, p.x - 6);
                }
                readonly property real holeW: tray.width + 12

                MouseArea {
                    x: 0
                    y: 0
                    width: trayClickBlocker.holeX
                    height: trayClickBlocker.height
                    onClicked: tray.closeMenu()
                }

                MouseArea {
                    x: trayClickBlocker.holeX + trayClickBlocker.holeW
                    y: 0
                    width: Math.max(0, trayClickBlocker.width - x)
                    height: trayClickBlocker.height
                    onClicked: tray.closeMenu()
                }
            }
        }
    }
}
