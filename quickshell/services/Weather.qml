// Weather.qml
// ---------------------------------------------------------------------------
// Free weather lookup for the greeting card.
// wttr.in needs no API key or registration, and works out the location from
// the public IP address. If the request fails or the answer cannot be parsed,
// everything falls back to "unknown" instead of showing a stale value.
// ---------------------------------------------------------------------------
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string temperature: "--"
    property string condition: "unknown"
    property string icon: "󰖐"
    property int code: 0

    function refresh() {
        if (!req.running)
            req.running = true;
    }

    function iconFor(c) {
        if (c === 113) return "󰖙";                       // clear
        if (c === 116) return "󰖕";                       // partly cloudy
        if (c === 119 || c === 122) return "󰖐";          // cloudy / overcast
        if ([143, 248, 260, 149].includes(c)) return "󰖑"; // fog / haze
        if ([179, 182, 185, 227, 230, 320, 323, 326, 329,
             332, 335, 338, 350, 368, 371, 374, 377].includes(c)) return "󰼶";
        if ([200, 386, 389, 392, 395].includes(c)) return "󰖓";
        if ([176, 263, 266, 281, 284, 293, 296].includes(c)) return "󰖖";
        if ([299, 302, 305, 308, 311, 314, 317,
             353, 356, 359].includes(c)) return "󰖗";
        return "󰖐";
    }

    function unknown() {
        root.temperature = "--";
        root.condition = "unknown";
        root.icon = "󰖐";
        root.code = 0;
    }

    function parse(text) {
        try {
            const data = JSON.parse(text);
            const cur = data.current_condition[0];
            root.code = parseInt(cur.weatherCode);
            root.temperature = cur.temp_C + "\u00b0C";
            root.condition = cur.weatherDesc[0].value;
            root.icon = root.iconFor(root.code);
        } catch (e) {
            root.unknown();
        }
    }

    Process {
        id: req
        command: ["curl", "-fsS", "--max-time", "10", "https://wttr.in/?format=j1"]
        running: false
        stdout: StdioCollector {
            // Fires when stdout closes, including when curl exits with an
            // error. Empty/garbage output simply ends up as "unknown".
            onStreamFinished: root.parse(this.text)
        }
    }

    Timer {
        interval: 20 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
