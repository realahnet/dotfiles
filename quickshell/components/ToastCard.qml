import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../services"

// One card in the toast stack. It carries its own lifetime timer and the
// white progress line across its top edge.
Rectangle {
    id: root
    property var notification: null
    property int duration: 6000
    property int entryId: 0
    property var screenInfo: null
    property bool iconFailed: false
    property real progress: 0
    property bool dismissing: false

    readonly property string iconSource: {
        if (!notification) return "";
        const img = notification.image || "";
        if (img) return img;
        const icon = notification.appIcon || "";
        if (!icon) return "";
        if (icon.startsWith("/") || icon.startsWith("file://") || icon.startsWith("http"))
            return icon;
        return Quickshell.iconPath(icon, true);
    }
    onIconSourceChanged: iconFailed = false

    implicitHeight: content.implicitHeight + 38
    radius: Theme.radius
    color: Theme.panelBg
    border.width: 1
    border.color: Theme.cardBorder
    clip: true

    function dismiss() {
        if (dismissing) return;
        dismissing = true;
        cardTimer.stop();
        barAnim.stop();
        dismissAnim.start();
    }

    function openApp() {
        if (notification) {
            const actions = notification.actions || [];
            for (let i = 0; i < actions.length; ++i) {
                if (actions[i].identifier === "default") {
                    actions[i].invoke();
                    break;
                }
            }
        }
        root.dismiss();
    }

    // One blur surface per card. The rounded Region matches the card, so the
    // blur is independent and never shows in the gaps or at the corners.
    PanelWindow {
        id: blurWin
        screen: root.screenInfo
        visible: root.visible && root.opacity > 0.01
        color: "transparent"
        implicitWidth: root.width
        implicitHeight: root.height
        anchors.top: true
        anchors.right: true
        margins.top: Theme.barHeight + 4 + root.y
        margins.right: 20
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell-toast-blur"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        BackgroundEffect.blurRegion: Region {
            x: 0
            y: 0
            width: blurWin.width
            height: blurWin.height
            radius: Theme.radius
        }
    }

    // Lifetime line across the top border.
    Rectangle {
        x: Theme.radius
        y: 0
        height: 3
        radius: 1
        color: Theme.white
        width: Math.max(0, (root.width - 2 * Theme.radius) * root.progress)
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        anchors.topMargin: 20
        anchors.bottomMargin: 18
        spacing: 9

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Item {
                implicitWidth: 25
                implicitHeight: 25
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
                    font.pixelSize: 18
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

    // If the sending app blanks the notification body (e.g. withdrawing it
    // when its window opens) instead of closing it, drop the toast at once.
    property bool hadBody: false

    function contentCheck() {
        if (root.entryId <= 0 || !root.notification) return;
        const body = root.notification.body || "";
        if (body) root.hadBody = true;
        else if (root.hadBody) root.dismiss();
    }

    Connections {
        target: root.notification
        function onClosed() { root.dismiss(); }
        function onBodyChanged() { root.contentCheck(); }
        function onSummaryChanged() { root.contentCheck(); }
        function onAppNameChanged() { root.contentCheck(); }
        function onImageChanged() { root.contentCheck(); }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openApp()
    }

    Timer {
        id: cardTimer
        interval: root.duration
        running: true
        onTriggered: root.dismiss()
    }

    NumberAnimation {
        id: barAnim
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: root.duration
        easing.type: Easing.Linear
    }

    NumberAnimation {
        id: dismissAnim
        target: root
        property: "opacity"
        from: 1
        to: 0
        duration: 160
        easing.type: Easing.InCubic
        onFinished: Notifications.removeToast(root.entryId)
    }

    Component.onCompleted: {
        root.progress = 0;
        barAnim.restart();
    }

    onEntryIdChanged: {
        root.hadBody = false;
        root.progress = 0;
        barAnim.restart();
        cardTimer.restart();
    }
}
