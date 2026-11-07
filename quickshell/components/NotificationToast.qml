import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services"

// The toast stack at the top right. A new notification is inserted at the top:
// existing cards are displaced downward, the new one fades in above them.
PanelWindow {
    id: root
    property var screenInfo: null

    readonly property bool active: Notifications.toastCount > 0

    implicitWidth: 480
    implicitHeight: toastList.contentHeight
    color: "transparent"
    visible: showWindow && !LockState.locked
    anchors.top: true
    anchors.right: true
    margins.top: Theme.barHeight + 6
    margins.right: 20
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell-toast"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None


    property bool showWindow: false
    property real reveal: 0
    property bool opening: true

    function openToast() {
        hideTimer.stop();
        opening = true;
        showWindow = true;
        reveal = 1;
    }
    function closeToast() {
        opening = false;
        reveal = 0;
        hideTimer.restart();
    }

    onActiveChanged: active ? openToast() : closeToast()
    Component.onCompleted: if (active) { showWindow = true; reveal = 1; }

    Timer { id: hideTimer; interval: 170; onTriggered: root.showWindow = false }

    Behavior on reveal {
        NumberAnimation {
            duration: root.opening ? 180 : 120
            easing.type: root.opening ? Easing.OutBack : Easing.InCubic
            easing.overshoot: 1.2
        }
    }

    Item {
        id: card
        anchors.fill: parent
        opacity: root.reveal
        scale: 0.8 + 0.2 * root.reveal
        transformOrigin: Item.TopRight

        ListView {
            id: toastList
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: contentHeight
            spacing: 8
            interactive: false
            model: Notifications.toastModel

            delegate: ToastCard {
                width: toastList.width
                notification: model.notification
                duration: model.duration
                entryId: model.toastId
                screenInfo: root.screenInfo
            }

            displaced: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }

            add: Transition {
                NumberAnimation {
                    properties: "opacity"
                    from: 0
                    to: 1
                    duration: 180
                }
            }

        }
    }
}
