// BarBattery.qml
// ---------------------------------------------------------------------------
// Replaces waybar's "battery" module. UPower is already running on your
// system, so Quickshell reads it directly over D-Bus.
//
// NOTE: Quickshell 0.3.x exposes UPowerDevice.percentage as 0.0..1.0.
// (The docs say 0..100, but the value we observed is 0.57 for 57%.)
// percentageOf() handles both conventions so this keeps working if it changes.
// ---------------------------------------------------------------------------
import Quickshell
import Quickshell.Services.UPower
import QtQuick
import "../services"

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight
    property bool hovered: false

    readonly property var battery: UPower.displayDevice
    readonly property int state: battery ? battery.state : UPowerDeviceState.Unknown

    function percentageOf(device) {
        if (!device)
            return 0;
        const raw = device.percentage;
        return Math.round(raw <= 1 ? raw * 100 : raw);
    }

    readonly property int percent: percentageOf(battery)

    readonly property bool charging:
        state === UPowerDeviceState.Charging ||
        state === UPowerDeviceState.PendingCharge
    readonly property bool full: state === UPowerDeviceState.FullyCharged
    readonly property bool present:
        battery && battery.isLaptopBattery && battery.isPresent

    visible: present

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        StyledText {
            height: 18
            text: root.charging ? "󱐋" : (root.full ? "" : "󰁹")
            color: Theme.fg
        }
        StyledText {
            height: 18
            text: root.percent + "%"
            color: Theme.fg
        }
    }
    HoverPopup {
        id: menu
        trigger: root
        triggerHovered: root.hovered
        popupWidth: 300
        popupHeight: 200
        BatteryMenu { anchors.fill: parent }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
    }
}
