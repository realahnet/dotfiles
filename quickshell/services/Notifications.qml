// Notifications.qml
// ---------------------------------------------------------------------------
// One Quickshell NotificationServer for the whole shell. It owns the
// org.freedesktop.Notifications D-Bus name, so swaync must not be running.
//
// Active toasts live in a ListModel. A new notification is inserted at index
// 0, so the existing cards are displaced downward and the newest is on top.
// ---------------------------------------------------------------------------
pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    readonly property var model: server.trackedNotifications
    readonly property var items: server.trackedNotifications.values
    readonly property int count: items.length

    // ---- stacked toasts ----
    readonly property int maxToasts: 3
    property int nextToastId: 1
    readonly property alias toastModel: toastListModel
    readonly property int toastCount: toastListModel.count

    ListModel { id: toastListModel }

    function clearAll() {
        // Copy first: dismiss() mutates the model while we iterate.
        const all = server.trackedNotifications.values.slice();
        for (let i = 0; i < all.length; ++i)
            all[i].dismiss();
    }

    function toastDelay(n) {
        const t = (n && n.expireTimeout > 0) ? n.expireTimeout * 1000 : 6000;
        return Math.max(4000, Math.min(8000, t));
    }

    function pushToast(n) {
        if (!n || !n.tracked) return;
        if (ShellState.dnd || ShellState.controlCenterOpen) return;

        toastListModel.insert(0, {
            toastId: root.nextToastId++,
            notification: n,
            duration: root.toastDelay(n)
        });

        while (toastListModel.count > root.maxToasts)
            toastListModel.remove(toastListModel.count - 1);
    }

    function removeToast(id) {
        for (let i = 0; i < toastListModel.count; ++i) {
            if (toastListModel.get(i).toastId === id) {
                toastListModel.remove(i);
                return;
            }
        }
    }

    function hideToast() {
        toastListModel.clear();
    }

    Connections {
        target: ShellState
        function onControlCenterOpenChanged() {
            if (ShellState.controlCenterOpen) root.hideToast();
        }
    }

    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: false
        keepOnReload: true

        // Without this the server emits the notification and discards it.
        onNotification: (notification) => {
            notification.tracked = true;
            if (!notification.lastGeneration)
                root.pushToast(notification);
        }
    }
}
