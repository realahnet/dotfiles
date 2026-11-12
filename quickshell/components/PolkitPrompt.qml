import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../services"

// Minimal polkit authentication agent. The card sits in the middle of the
// screen, above every other surface, and uses the same password pill as the
// lock screen.
PanelWindow {
    id: root

    readonly property var flow: agent.flow
    readonly property bool active: flow !== null && !LockState.locked

    property bool shown: false
    property bool closing: false
    property real reveal: 0
    property bool failed: false
    property bool authenticating: false
    property string errorText: ""
    property bool iconFailed: false

    readonly property string iconSource: root.flow && root.flow.iconName
        ? Quickshell.iconPath(root.flow.iconName, true) : ""

    implicitWidth: 380
    implicitHeight: 210
    color: "transparent"
    visible: (shown || reveal > 0.01) && !LockState.locked
    anchors.top: true
    anchors.left: true
    margins.left: Math.round(((screen ? screen.width : 0) - implicitWidth) / 2)
    margins.top: Math.round(((screen ? screen.height : 0) - implicitHeight) / 2)
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell-polkit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    PolkitAgent {
        id: agent
    }

    BackgroundEffect.blurRegion: Region {
        x: 0
        y: 0
        width: root.width
        height: root.height
        radius: Theme.radius
    }

    onFlowChanged: {
        if (flow) {
            closing = false;
            authenticating = false;
            failed = false;
            errorText = "";
            iconFailed = false;
            input.text = "";
            shown = true;
            reveal = 1;
            focusTimer.restart();
        } else {
            closing = true;
            authenticating = false;
            reveal = 0;
            input.text = "";
            hideTimer.restart();
        }
    }

    onActiveChanged: if (active) focusTimer.restart()

    Timer {
        id: hideTimer
        interval: 180
        onTriggered: root.shown = false
    }

    Timer {
        id: focusTimer
        interval: 120
        onTriggered: input.forceActiveFocus()
    }

    Timer {
        id: focusGuard
        interval: 250
        running: root.active && !root.authenticating
        repeat: true
        onTriggered: if (!input.activeFocus) input.forceActiveFocus()
    }

    Behavior on reveal {
        NumberAnimation {
            duration: root.closing ? 180 : 450
            easing.type: root.closing ? Easing.InCubic : Easing.OutExpo
        }
    }

    Connections {
        target: root.flow
        function onAuthenticationFailed() {
            root.authenticating = false;
            root.failed = true;
            root.errorText = "wrong password";
            input.text = "";
            focusTimer.restart();
        }
        function onAuthenticationSucceeded() {
            root.authenticating = false;
            root.failed = false;
            root.errorText = "";
        }
    }

    function submit() {
        if (!root.flow || !root.flow.isResponseRequired || root.authenticating) return;
        if (input.text.length === 0) return;
        root.authenticating = true;
        root.failed = false;
        root.errorText = "";
        root.flow.submit(input.text);
    }

    function cancel() {
        if (root.flow) root.flow.cancelAuthenticationRequest();
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

    Item {
        id: card
        anchors.fill: parent
        opacity: root.reveal

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.panelBg
            border.width: 1
            border.color: Theme.cardBorder
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 11

                Item {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    Layout.alignment: Qt.AlignTop
                    Image {
                        anchors.fill: parent
                        source: root.iconSource
                        visible: root.iconSource !== "" && !root.iconFailed
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        onStatusChanged: if (status === Image.Error) root.iconFailed = true
                    }
                    StyledText {
                        anchors.centerIn: parent
                        visible: root.iconSource === "" || root.iconFailed
                        text: ""
                        font.pixelSize: 20
                        color: Theme.fgMuted
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: "Authentication Required"
                        color: Theme.white
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.flow ? root.flow.message : ""
                        color: Theme.fgMuted
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }
            }

            Item { Layout.fillHeight: true }

            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 300
                height: 45
                clip: true

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
                        scale: Math.max(0.45, Math.min(1, parent.width / Math.max(1, width)))
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

                StyledText {
                    anchors.centerIn: parent
                    text: root.failed
                        ? (root.errorText || "wrong password")
                        : (root.flow && root.flow.inputPrompt ? root.flow.inputPrompt : "Password...")
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

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    focus: true
                    enabled: !root.authenticating
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

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                visible: text !== ""
                text: root.authenticating ? "Authenticating..."
                    : (root.flow ? root.flow.supplementaryMessage : "")
                color: root.flow && root.flow.supplementaryIsError
                    ? Qt.rgba(204 / 255, 34 / 255, 34 / 255, 0.9)
                    : Theme.fgMuted
                font.pixelSize: 12
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "Enter to authenticate · Esc to cancel"
                color: Theme.fgMuted
                font.pixelSize: 10
                opacity: 0.7
            }
        }

        Keys.onEscapePressed: root.cancel()
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.AllButtons
    }
}
