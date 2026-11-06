import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../services"

// Compact OSD pill for volume and brightness changes. Positioned near 80% of
// the screen height, centered, like the old swayosd setup.
PanelWindow {
    id: root
    implicitWidth: 280
    implicitHeight: 44
    color: "transparent"
    visible: showWindow && !LockState.locked
    anchors.bottom: true
    anchors.left: true
    margins.left: Math.round(((root.screen ? root.screen.width : 0) - implicitWidth) / 2)
    margins.bottom: Math.max(0, Math.round((root.screen ? root.screen.height : 0) * 0.20) - Math.round(implicitHeight / 2))
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Rounded blur matches the pill exactly, so no square corners leak.
    BackgroundEffect.blurRegion: Region {
        x: 0
        y: 0
        width: root.width
        height: root.height
        radius: Math.round(root.implicitHeight / 2)
    }

    readonly property bool active: ShellState.osdVisible
    readonly property real fraction: Math.max(0, Math.min(1, ShellState.osdValue / 100))

    property bool showWindow: false
    property real reveal: 0
    property bool opening: true

    function openOsd() {
        hideTimer.stop();
        opening = true;
        showWindow = true;
        reveal = 1;
    }
    function closeOsd() {
        opening = false;
        reveal = 0;
        hideTimer.restart();
    }

    onActiveChanged: active ? openOsd() : closeOsd()
    Component.onCompleted: if (active) { showWindow = true; reveal = 1; }

    Timer { id: hideTimer; interval: 170; onTriggered: root.showWindow = false }

    Behavior on reveal {
        NumberAnimation {
            duration: root.opening ? 180 : 120
            easing.type: root.opening ? Easing.OutBack : Easing.InCubic
            easing.overshoot: 1.2
        }
    }

    Item {
        id: card
        anchors.fill: parent
        opacity: root.reveal
        scale: 0.9 + 0.1 * root.reveal
        transformOrigin: Item.Bottom

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(10 / 255, 10 / 255, 10 / 255, 0.90)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.15)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 10

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: ShellState.osdIcon
                color: Theme.white
                font.pixelSize: 20
            }

            Item {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: 4

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.20)
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * root.fraction
                    height: 4
                    radius: 2
                    color: Theme.white
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: Math.round(ShellState.osdValue) + "%"
                color: Theme.white
                font.pixelSize: 14
                font.weight: Font.Bold
            }
        }
    }
}
