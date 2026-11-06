// BarGreeting.qml
// ---------------------------------------------------------------------------
// Replaces waybar's custom/welcome module and waybar-greeting.sh.
// SystemClock is a Quickshell service that ticks by itself; no shell script,
// no timer, no subprocess.
// ---------------------------------------------------------------------------
import Quickshell
import QtQuick
import QtQuick.Layouts
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

    readonly property var greeting: {
        const h = clock.hours;
        if (h >= 5 && h < 12)  return { icon: "󰖙", color: "#f9e2af", text: "Good morning",   emoji: "☀️", heading: "Good Morning" };
        if (h >= 12 && h < 17) return { icon: "󰖙", color: "#f9e2af", text: "Good afternoon", emoji: "🌞", heading: "Good Afternoon" };
        if (h >= 17 && h < 21) return { icon: "󰖚", color: "#fab387", text: "Good evening",   emoji: "🌇", heading: "Good Evening" };
        return                        { icon: "󰖔", color: "#a6adc8", text: "Good night",     emoji: "😴", heading: "Good Night" };
    }

    // RowLayout + Layout.alignment keeps the 20px icon and the 14px text
    // on the same vertical centre line (a plain Row would top-align them).
    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: root.greeting.icon
            color: root.greeting.color
            font.pixelSize: 20
        }
        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: root.greeting.text + ","
            color: Theme.fg
        }
        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: "ahnet"
            color: Theme.fgMuted
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: root.hovered = true
        onExited: root.hovered = false
    }

    HoverPopup {
        id: menu
        trigger: root
        triggerHovered: root.hovered
        popupWidth: 260
        popupHeight: greetingMenu.implicitHeight
        GreetingMenu {
            id: greetingMenu
            width: parent.width
            height: implicitHeight
            emoji: root.greeting.emoji
            heading: root.greeting.heading
        }
    }
}
