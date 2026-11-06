import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
    id: root
    implicitWidth: 300
    implicitHeight: body.implicitHeight + 32
    radius: Theme.radius
    color: Theme.panelBg
    border.width: 1
    border.color: Theme.cardBorder
    property var battery: UPower.displayDevice
    property string profile: ""
    function pct(d) {
        if (!d) return 0;
        var v = d.percentage;
        return Math.round(v <= 1 ? v * 100 : v);
    }
    function eta() {
        if (!battery) return "";
        var s = battery.state === UPowerDeviceState.Charging ? battery.timeToFull : battery.timeToEmpty;
        if (!s || s <= 0) return "";
        var h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
        return (h > 0 ? h + "h " + m + "m" : m + "m");
    }
    function stateText() {
        if (!battery) return "";
        if (battery.state === UPowerDeviceState.Charging) return "Charging";
        if (battery.state === UPowerDeviceState.FullyCharged) return "Fully charged";
        if (battery.state === UPowerDeviceState.Discharging) return "Discharging";
        return "On battery";
    }
    function setProfileTo(p) {
        setProfile.command = ["powerprofilesctl", "set", p];
        setProfile.running = true;
        root.profile = p;
        refresh.restart();
    }
    Process {
        id: getProfile
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.profile = this.text.trim()
        }
    }
    Process {
        id: setProfile
        command: []
    }
    Timer { id: refresh; interval: 350; onTriggered: getProfile.running = true }
    ColumnLayout {
        id: body
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            StyledText {
                text: root.battery && root.battery.state === UPowerDeviceState.Charging ? "󱐋" : "󰁹"
                font.pixelSize: 26
            }
            ColumnLayout {
                spacing: 0
                StyledText { text: root.pct(root.battery) + "%"; font.pixelSize: 22; font.weight: Font.Bold }
                StyledText { text: root.stateText(); color: Theme.fgMuted; font.pixelSize: 12 }
            }
            Item { Layout.fillWidth: true }
            StyledText { text: root.eta() ? (root.battery && root.battery.state === UPowerDeviceState.Charging ? root.eta() + " to full" : root.eta() + " left") : ""; color: Theme.fg; font.pixelSize: 12 }
        }
        StyledText {
            visible: root.battery && Math.abs(root.battery.changeRate) > 0.1
            text: "Draw: " + Math.abs(root.battery ? root.battery.changeRate : 0).toFixed(1) + " W"
            color: Theme.fgMuted
            font.pixelSize: 12
        }
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.cardBorder
        }
        StyledText { text: "Power mode"; color: Theme.fgMuted; font.pixelSize: 12 }
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: [
                    { key: "performance", label: "Performance", icon: "󰓅" },
                    { key: "balanced", label: "Balanced", icon: "󰾅" },
                    { key: "power-saver", label: "Power Saver", icon: "󰾆" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 46
                    radius: 6
                    color: root.profile === modelData.key ? Theme.primary : Theme.elevated
                    border.width: 1
                    border.color: root.profile === modelData.key ? "transparent" : Theme.cardBorder
                    Column {
                        anchors.centerIn: parent
                        spacing: 1
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.icon
                            font.pixelSize: 17
                            color: root.profile === modelData.key ? "#000000" : Theme.fg
                        }
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label
                            font.pixelSize: 10
                            color: root.profile === modelData.key ? "#000000" : Theme.fg
                        }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setProfileTo(modelData.key) }
                }
            }
        }
    }
}
