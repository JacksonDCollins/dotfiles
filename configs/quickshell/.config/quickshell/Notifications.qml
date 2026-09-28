pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Scope {
    id: root
    // ponytail: bounded linear scans; use an indexed model if 5,000 entries becomes slow.
    readonly property int historyLimit: 5000
    property var entries: []
    property bool dnd: false
    property bool allowCritical: false
    property var centerPopup: null
    readonly property int unread: entries.filter(e => !e.isTransient && !e.read).length
    readonly property var history: entries.filter(e => !e.isTransient)
    readonly property var toasts: entries.filter(e => e.popup && e.notification !== null).slice(0, 3)

    function allowed(entry): bool { return !dnd || (allowCritical && entry.critical); }
    function suppress(): void {
        for (const entry of entries) if (!allowed(entry)) {
            entry.popup = false;
            if (entry.isTransient && entry.notification) entry.notification.expire();
        }
    }
    onDndChanged: suppress()
    onAllowCriticalChanged: suppress()
    function markRead(): void { for (const entry of entries) entry.read = true; }
    function showCenter(popup): void {
        if (centerPopup && centerPopup !== popup) centerPopup.visible = false;
        centerPopup = popup;
        popup.visible = true;
        markRead();
        for (const entry of entries) {
            entry.popup = false;
            if (entry.isTransient && entry.notification) entry.notification.expire();
        }
    }
    function forget(entry): void {
        if (entries.indexOf(entry) === -1) return;
        entries = entries.filter(e => e !== entry);
        if (entry.notification) entry.notification.dismiss();
        entry.destroy();
    }
    function clear(): void { for (const entry of entries.slice()) forget(entry); }
    function receive(notification): void {
        notification.tracked = true;
        const entry = record.createObject(root, {notification: notification});
        entry.refresh();
        entries = [entry].concat(entries);
        while (entries.length > historyLimit) {
            const oldest = entries[entries.length - 1];
            if (oldest.notification) oldest.notification.expire();
            forget(oldest);
        }
    }
    NotificationServer {
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        imageSupported: false
        actionsSupported: true
        actionIconsSupported: false
        inlineReplySupported: false
        persistenceSupported: false
        onNotification: notification => root.receive(notification)
    }
    Component {
        id: record
        Scope {
            id: entry
            property var notification: null
            property string app: ""
            property string summary: ""
            property string body: ""
            property double received: 0
            property bool critical: false
            property bool isTransient: false
            property bool read: false
            property bool popup: false
            function snapshot(): void {
                if (!notification) return;
                app = notification.appName.slice(0, 128) || "Application";
                summary = notification.summary.slice(0, 512);
                body = notification.body.slice(0, 8192);
                critical = notification.urgency === NotificationUrgency.Critical;
                isTransient = notification.transient;
            }
            function refresh(): void {
                if (!notification) return;
                snapshot();
                received = Date.now();
                if (root.entries.indexOf(entry) !== -1)
                    root.entries = [entry].concat(root.entries.filter(e => e !== entry));
                read = root.centerPopup !== null;
                popup = root.allowed(entry) && !read;
                lifetime.stop();
                // Critical/default and explicit zero-timeout notifications wait for dismissal.
                const timeout = notification.expireTimeout;
                if (timeout > 0 || (timeout < 0 && !critical)) {
                    lifetime.interval = timeout > 0 ? timeout : 8000;
                    lifetime.start();
                }
                // A persistent notification remains in the center, not permanently over windows.
                toastLifetime.restart();
                if (isTransient && !popup) Qt.callLater(entry.expireTransient);
            }
            function expireTransient(): void { if (isTransient && notification) notification.expire(); }
            function close(reason): void {
                snapshot();
                notification = null;
                popup = false;
                lifetime.stop();
                toastLifetime.stop();
                if (reason === NotificationCloseReason.Dismissed) read = true;
                if (isTransient || reason === NotificationCloseReason.CloseRequested) root.forget(entry);
            }
            function changed(): void { Qt.callLater(entry.refresh); }
            Timer { id: lifetime; onTriggered: { if (entry.notification) entry.notification.expire(); } }
            Timer {
                id: toastLifetime
                interval: 8000
                onTriggered: { entry.popup = false; entry.expireTransient(); }
            }
            Connections {
                target: entry.notification
                function onClosed(reason): void { entry.close(reason); }
                function onSummaryChanged(): void { entry.changed(); }
                function onBodyChanged(): void { entry.changed(); }
                function onAppNameChanged(): void { entry.changed(); }
                function onExpireTimeoutChanged(): void { entry.changed(); }
                function onTransientChanged(): void { entry.changed(); }
                function onUrgencyChanged(): void { entry.changed(); }
                function onActionsChanged(): void { entry.changed(); }
                function onHintsChanged(): void { entry.changed(); }
            }
        }
    }
}
