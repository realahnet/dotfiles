import Quickshell
import QtQuick
import QtQuick.Layouts
import "../services"

// One notification card. The base is the shared card color; a very low-alpha
// tint derived from the app name makes cards distinguishable without turning
// them into a rainbow. Hover raises the tint alpha a little.
Rectangle {
    id: root
    property var notification: null
    property int cardIndex: 0
    property bool hovered: false
    property bool iconFailed: false

    readonly property string iconSource: {
        if (!notification) return "";
        // notify-send and many apps put the icon in image (usually an
        // image://icon/... URL); appIcon is the fallback.
        const img = notification.image || "";
        if (img) return img;
        const icon = notification.appIcon || "";
        if (!icon) return "";
        if (icon.startsWith("/") || icon.startsWith("file://") || icon.startsWith("http"))
            return icon;
        return Quickshell.iconPath(icon, true);
    }
    onIconSourceChanged: iconFailed = false

    function openApp() {
        if (!notification) return;
        const actions = notification.actions || [];
        for (let i = 0; i < actions.length; ++i) {
            if (actions[i].identifier === "default") {
                actions[i].invoke();
                return;
            }
        }
        if (actions.length > 0) actions[0].invoke();
    }

    implicitWidth: 100
    implicitHeight: content.implicitHeight + 32
    radius: Theme.radius + 2
    color: Theme.cardBg
    border.width: 1
    border.color: Theme.cardBorder
    clip: true

    // Neutral hover lift only. No per-card hue changes.
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.white
        opacity: root.hovered ? 0.05 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Item {
                implicitWidth: 22
                implicitHeight: 22
                Image {
                    anchors.fill: parent
                    source: root.iconSource
                    visible: source !== "" && !root.iconFailed
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    onStatusChanged: if (status === Image.Error) root.iconFailed = true
                }
                StyledText {
                    anchors.centerIn: parent
                    visible: root.iconSource === "" || root.iconFailed
                    text: "󰂚"
                    font.pixelSize: 16
                    color: Theme.fgMuted
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.notification
                    ? (root.notification.summary || root.notification.appName)
                    : ""
                color: Theme.white
                font.pixelSize: 15
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.notification ? root.notification.body : ""
            textFormat: Text.PlainText
            color: Theme.fgMuted
            font.pixelSize: 13
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }
    }

    Component.onCompleted: notification = Notifications.items[cardIndex] || null

    Connections {
        target: Notifications
        function onCountChanged() {
            root.notification = Notifications.items[root.cardIndex] || null;
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.openApp()
    }
}
