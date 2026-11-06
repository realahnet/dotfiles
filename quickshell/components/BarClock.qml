// BarClock.qml
// ---------------------------------------------------------------------------
// Replaces waybar's "clock" module.
// Qt.formatDateTime() uses the same date/time pieces as waybar's strftime.
// ---------------------------------------------------------------------------
import Quickshell
import QtQuick
import "../services"

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight
    property bool hovered: false

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16

        Row {
            spacing: 6
            StyledText { height: 18; text: "󰥔" }
            StyledText { height: 18; text: Qt.formatDateTime(clock.date, "hh:mm AP") }
        }

        Row {
            spacing: 6
            StyledText { height: 18; text: "󰃭" }
            StyledText { height: 18; text: Qt.formatDateTime(clock.date, "MMM dd") }
        }
    }

    HoverPopup {
        id: menu
        trigger: root
        triggerHovered: root.hovered
        popupWidth: 372
        popupHeight: 400
        ClockMenu { anchors.fill: parent }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
    }
}
