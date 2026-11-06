import QtQuick
import "../services"

Item {
    id: root
    property real value: 0
    property real from: 0
    property real to: 1.5
    signal moved(real value)
    implicitHeight: 20
    readonly property real ratio: Math.max(0, Math.min(1, (value - from) / (to - from)))
    Rectangle { id: track; anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: Theme.elevated }
    Rectangle { id: fill; anchors.verticalCenter: parent.verticalCenter; width: root.ratio * track.width; height: 4; radius: 2; color: Theme.primary }
    Rectangle { id: thumb; x: fill.width - width / 2; anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; radius: 6; color: Theme.white }
    MouseArea {
        anchors.fill: parent
        onPressed: (m) => root.moved(root.from + Math.max(0, Math.min(1, m.x / width)) * (root.to - root.from))
        onPositionChanged: (m) => { if (pressed) root.moved(root.from + Math.max(0, Math.min(1, m.x / width)) * (root.to - root.from)); }
    }
}
