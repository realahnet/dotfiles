// BarWorkspaces.qml
// ---------------------------------------------------------------------------
// The left side of the bar: one clickable pill per workspace.
// Each pill shows the workspace number and the icons of the windows on it.
// This replaces waybar's "hyprland/workspaces" module.
//
// Layout note: a plain Row positions children by their TOP edge. Text glyphs
// have different heights, so the number, colon and icons looked scattered.
// Giving every child the pill's height and verticalAlignment: AlignVCenter
// makes them share the same vertical centre line.
// ---------------------------------------------------------------------------
import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../services"

Row {
    id: root

    // The Hyprland monitor this bar belongs to. Bar.qml passes it in.
    property var monitor: null

    spacing: 0

    // Recompute this list whenever Hyprland's workspace list changes.
    // ObjectModel.values is what makes the binding reactive.
    readonly property var workspaces: {
        const all = Hyprland.workspaces.values;
        if (!root.monitor)
            return all;
        return all.filter(ws => ws.monitor && ws.monitor.name === root.monitor.name);
    }

    Repeater {
        model: root.workspaces

        delegate: Rectangle {
            id: pill
            required property var modelData

            readonly property bool active:
                root.monitor && root.monitor.activeWorkspace &&
                root.monitor.activeWorkspace.id === modelData.id

            // Hyprland's urgent flag is cleared when the workspace is focused.
            readonly property bool urgent: !active && modelData.urgent
            property real urgentLevel: 0

            function mixColor(a, b, t) {
                return Qt.rgba(a.r + (b.r - a.r) * t,
                               a.g + (b.g - a.g) * t,
                               a.b + (b.b - a.b) * t,
                               a.a + (b.a - a.a) * t);
            }

            height: 26
            implicitWidth: content.implicitWidth + 24
            radius: Theme.radiusSmall
            color: active ? Theme.primary
                 : urgent ? mixColor(Theme.elevated, Qt.rgba(0x55 / 255, 0x55 / 255, 0x55 / 255, 1), urgentLevel)
                 : hover.hovered ? Theme.elevated
                 : "transparent"

            onUrgentChanged: if (!urgent) urgentLevel = 0

            SequentialAnimation {
                running: pill.urgent
                loops: Animation.Infinite
                NumberAnimation {
                    target: pill
                    property: "urgentLevel"
                    from: 0
                    to: 1
                    duration: 600
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: pill
                    property: "urgentLevel"
                    from: 1
                    to: 0
                    duration: 600
                    easing.type: Easing.InOutQuad
                }
            }

            Row {
                id: content
                anchors.centerIn: parent
                spacing: 4

                StyledText {
                    height: pill.height
                    text: pill.modelData.id
                    color: pill.active ? "#000000"
                         : pill.urgent ? pill.mixColor(Theme.fgMuted, Theme.white, pill.urgentLevel)
                         : Theme.fgMuted
                    font.pixelSize: 15
                    verticalAlignment: Text.AlignVCenter
                }

                StyledText {
                    height: pill.height
                    text: ":"
                    color: pill.active ? "#000000"
                         : pill.urgent ? pill.mixColor(Theme.fgMuted, Theme.white, pill.urgentLevel)
                         : Theme.fgMuted
                    font.pixelSize: 15
                    verticalAlignment: Text.AlignVCenter
                }

                // One glyph per window on this workspace.
                Repeater {
                    model: pill.modelData.toplevels

                    delegate: StyledText {
                        required property var modelData
                        height: pill.height
                        text: AppIcons.iconFor(modelData)
                        color: pill.active ? "#000000"
                             : pill.urgent ? pill.mixColor(Theme.fg, Theme.white, pill.urgentLevel)
                             : Theme.fg
                        font.pixelSize: 15
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: pill.modelData.activate()
            }
        }
    }
}
