import Quickshell
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../services"

// Hyprlock-style lock surface. The vertical offsets are inverted relative to
// hyprlock's positive-up coordinate system:
//   clock (top), date, avatar, username, password (bottom).
Item {
    id: root
    anchors.fill: parent

    readonly property string home: Quickshell.env("HOME") || "/home/ahnet"
    readonly property string userName: Quickshell.env("USER") || "ahnet"
    readonly property var dayNames: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    property bool failed: false
    property real lockReveal: 0
    property bool unlocking: false
    property string errorText: ""
    property string pendingPassword: ""

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property int hour12: ((clock.hours + 11) % 12) + 1
    readonly property string minuteText: (clock.minutes < 10 ? "0" : "") + clock.minutes
    readonly property string ampm: clock.hours >= 12 ? "PM" : "AM"
    readonly property string dateText: {
        const d = clock.date;
        return dayNames[d.getDay()] + ", " + monthNames[d.getMonth()] + " " + ("0" + d.getDate()).slice(-2);
    }

    readonly property string wallpaperSource: "file://" + LockState.wallpaperPath
    readonly property string shotSource: "file://" + LockState.backgroundPath
    readonly property string noiseSource: "file://" + root.home + "/dotfiles/quickshell/assets/noise.png"

    Component.onCompleted: {
        revealAnim.start();
        focusTimer.restart();
    }

    NumberAnimation {
        id: revealAnim
        target: root
        property: "lockReveal"
        from: 0
        to: 1
        duration: 450
        easing.type: Easing.OutExpo
    }

    NumberAnimation {
        id: unlockAnim
        target: root
        property: "lockReveal"
        to: 0
        duration: 300
        easing.type: Easing.InOutQuad
        onFinished: LockState.locked = false
    }

    Timer {
        id: focusTimer
        interval: 150
        onTriggered: input.forceActiveFocus()
    }


    // ---- background ----
    Image {
        id: wallpaper
        anchors.fill: parent
        source: root.wallpaperSource
        fillMode: Image.PreserveAspectCrop
        visible: false
        asynchronous: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        visible: true
        blurEnabled: true
        blur: 0.85 * root.lockReveal
        blurMax: 80
        autoPaddingEnabled: false
    }

    Image {
        id: shot
        anchors.fill: parent
        source: root.shotSource
        fillMode: Image.PreserveAspectCrop
        visible: false
        cache: false
        asynchronous: false
    }

    MultiEffect {
        anchors.fill: parent
        source: shot
        visible: LockState.hasCapture
        blurEnabled: true
        blur: 0.85 * root.lockReveal
        blurMax: 80
        autoPaddingEnabled: false
    }

    // A faint scattering/grain layer, similar to hyprlock's noise.
    Image {
        anchors.fill: parent
        source: root.noiseSource
        fillMode: Image.Tile
        opacity: 0.03 * root.lockReveal
        smooth: false
    }

    // Much lighter than before; lets the blurred colours through.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(25 / 255, 20 / 255, 20 / 255, 0.22)
        opacity: root.lockReveal
    }

    MouseArea {
        anchors.fill: parent
        onClicked: input.forceActiveFocus()
    }

    // ---- clock (top) ----
    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -260
        spacing: 8
        opacity: root.lockReveal

        StyledText {
            text: root.hour12 + ":" + root.minuteText
            color: Qt.rgba(1, 1, 1, 0.85)
            font.pixelSize: 80
            font.weight: Font.Normal
            font.family: Theme.fontFamily
        }
        StyledText {
            text: root.ampm
            color: Qt.rgba(1, 1, 1, 0.85)
            font.pixelSize: 16
            font.weight: Font.Normal
            font.family: Theme.fontFamily
            Layout.alignment: Qt.AlignBottom
            Layout.bottomMargin: 12
        }
    }

    // ---- date ----
    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -180
        text: root.dateText
        opacity: root.lockReveal
        color: Qt.rgba(1, 1, 1, 0.65)
        font.pixelSize: 18
        font.weight: Font.Normal
        font.family: Theme.fontFamily
    }

    // ---- profile picture ----
    Item {
        width: 130
        height: 130
        opacity: root.lockReveal
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -10

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#151515"
        }

        Image {
            id: avatarImage
            anchors.fill: parent
            source: "file://" + root.home + "/.face"
            fillMode: Image.PreserveAspectCrop
            smooth: true
            visible: false
        }

        Rectangle {
            id: avatarMask
            anchors.fill: parent
            radius: width / 2
            visible: false
            layer.enabled: true
        }

        MultiEffect {
            anchors.fill: parent
            source: avatarImage
            maskEnabled: true
            maskSource: avatarMask
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(1, 1, 1, 0.5)
        }
    }

    // ---- username (below avatar) ----
    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 85
        text: root.userName
        opacity: root.lockReveal
        color: Qt.rgba(1, 1, 1, 0.8)
        font.pixelSize: 16
        font.weight: Font.Normal
        font.family: Theme.fontFamily
    }

    // ---- password pill (below username) ----
    Item {
        width: 260
        height: 45
        clip: true
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 145
        opacity: root.lockReveal

        Rectangle {
            id: field
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(0, 0, 0, 0.5)
            border.width: 2
            border.color: root.failed
                ? Qt.rgba(204 / 255, 34 / 255, 34 / 255, 0.65)
                : Qt.rgba(1, 1, 1, 0.2)
            clip: true
            Behavior on border.color { ColorAnimation { duration: 250 } }
        }

        // Keep a 22px margin on both sides of the pill. If the password gets
        // long the orbs scale down instead of touching the rounded ends.
        Item {
            id: dotsArea
            width: parent.width - 44
            height: parent.height
            anchors.centerIn: parent
            clip: true

            Row {
                id: dotsRow
                anchors.verticalCenter: parent.verticalCenter
                x: 0
                spacing: 7
                scale: Math.min(1, parent.width / Math.max(1, width))
                transformOrigin: Item.Center
                opacity: (root.failed || input.text.length === 0) ? 0 : 1

                Component.onCompleted: {
                    x = parent.width / 2;
                    root.recenterDots();
                }
                onWidthChanged: root.recenterDots()

                Repeater {
                    model: input.text.length
                    delegate: Rectangle {
                        id: orb
                        width: 14
                        height: 14
                        radius: 7
                        color: Theme.white
                        scale: 0.75
                        Component.onCompleted: orbScaleIn.start()
                        NumberAnimation {
                            id: orbScaleIn
                            target: orb
                            property: "scale"
                            to: 1
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }

        // Placeholder / error, faded in and out.
        StyledText {
            anchors.centerIn: parent
            text: root.failed ? "wrong password" : "Password..."
            color: root.failed
                ? Qt.rgba(204 / 255, 34 / 255, 34 / 255, 0.9)
                : Qt.rgba(1, 1, 1, 0.45)
            font.pixelSize: 13
            font.italic: true
            font.weight: Font.Normal
            font.family: Theme.fontFamily
            opacity: (root.failed || input.text.length === 0) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220 } }
        }

        // Invisible real input, on top so it owns focus and typing.
        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            focus: true
            echoMode: TextInput.Password
            color: "transparent"
            selectionColor: "transparent"
            selectedTextColor: "transparent"
            cursorVisible: false
            cursorDelegate: Item { }
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Theme.fontWeight
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            onAccepted: root.submit()
            onTextEdited: {
                if (root.failed) {
                    root.failed = false;
                    root.errorText = "";
                }
            }
        }
    }

    PamContext {
        id: pam
        user: root.userName
        config: "quickshell-lock"
        configDirectory: "../pam.d"
    }

    Timer {
        id: errorTimer
        interval: 2000
        onTriggered: {
            root.failed = false;
            root.errorText = "";
        }
    }

    function recenterDots() {
        if (!dotsRow || !dotsRow.parent) return;
        const target = (dotsRow.parent.width - dotsRow.width) / 2;
        centerAnim.stop();
        centerAnim.from = dotsRow.x;
        centerAnim.to = target;
        centerAnim.start();
    }

    NumberAnimation {
        id: centerAnim
        target: dotsRow
        property: "x"
        duration: 140
        easing.type: Easing.OutQuad
    }

    function unlock() {
        if (unlocking) return;
        unlocking = true;
        input.enabled = false;
        revealAnim.stop();
        unlockAnim.start();
    }

    function showError(message) {
        input.text = "";
        errorText = message;
        failed = true;
        errorTimer.restart();
        input.forceActiveFocus();
    }

    function submit() {
        if (input.text.length === 0 || pam.active)
            return;

        pendingPassword = input.text;
        failed = false;
        errorText = "";

        if (!pam.start()) {
            showError("authentication error");
            return;
        }

        if (pam.responseRequired) {
            pam.respond(pendingPassword);
        }
    }

    Connections {
        target: pam

        function onResponseRequiredChanged() {
            if (pam.responseRequired)
                pam.respond(root.pendingPassword);
        }

        function onCompleted(result) {
            if (result === PamResult.Success) {
                root.failed = false;
                root.errorText = "";
                root.unlock();
            } else {
                if (pam.active)
                    pam.abort();
                root.showError("wrong password");
            }
        }

        function onError(error) {
            root.showError("authentication error");
        }
    }
}
