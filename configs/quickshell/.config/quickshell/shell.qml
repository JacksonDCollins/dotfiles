//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

ShellRoot {
    Notifications { id: notifications }
    Power { id: power }
    Wallpaper {}
    Bar { notificationService: notifications; powerService: power }
    NotificationToasts { service: notifications }
}
