pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Basic.ToolButton {
    id: root
    required property ScreenTheme theme
    required property var service
    Component.onDestruction: {
        if (service && service.centerPopup === popup) service.centerPopup = null;
    }
    implicitWidth: root.theme.tray.iconSize + 2 * root.theme.spacing.medium
    implicitHeight: root.theme.bar.height
    padding: 0
    hoverEnabled: true
    Accessible.name: "Notification center, " + service.unread + " unread" + (service.dnd ? ", do not disturb" : "")
    onClicked: {
        if (popup.visible) popup.visible = false;
        else service.showCenter(popup);
    }
    component ThemedCheckBox: Basic.CheckBox {
        id: control
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        font: root.theme.smallFont
        padding: root.theme.spacing.small
        spacing: root.theme.spacing.medium
        hoverEnabled: true
        palette.windowText: root.theme.foreground
        contentItem: Text {
            text: control.text
            font: control.font
            color: root.theme.foreground
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            verticalAlignment: Text.AlignVCenter
            leftPadding: control.mirrored ? 0 : control.indicator.width + control.spacing
            rightPadding: control.mirrored ? control.indicator.width + control.spacing : 0
        }
        indicator: Rectangle {
            implicitWidth: root.theme.font.pixelSize + 6
            implicitHeight: implicitWidth
            x: control.mirrored ? control.width - width - control.rightPadding : control.leftPadding
            y: control.topPadding + (control.availableHeight - height) / 2
            radius: root.theme.radius.small
            color: control.down ? root.theme.surfacePressed : control.checked ? root.theme.accent
                : control.hovered ? root.theme.surfaceHover : root.theme.surface
            border.width: control.visualFocus ? 2 : root.theme.widget.borderWidth
            border.color: control.visualFocus ? root.theme.focusBorder : control.checked ? root.theme.accent : root.theme.border
            opacity: control.enabled ? 1 : 0.5
            MaterialIcon { theme: root.theme;
                anchors.centerIn: parent
                text: "check"
                visible: control.checked
                color: control.down ? root.theme.accent : root.theme.background
                font: Qt.font({family: root.theme.iconFont.family, pixelSize: root.theme.font.pixelSize, variableAxes: root.theme.iconFont.variableAxes})
            }
        }
    }
    background: Rectangle {
        radius: root.theme.radius.medium
        color: root.down ? root.theme.surfacePressed : root.hovered ? root.theme.surfaceHover : root.theme.background
        border.width: root.visualFocus ? root.theme.widget.borderWidth : 0
        border.color: root.theme.focusBorder
    }
    contentItem: MaterialIcon { theme: root.theme;
        text: root.service.dnd ? "notifications_off" : "notifications"
        color: root.service.dnd ? root.theme.warning : root.theme.foreground
        font: Qt.font({family: root.theme.iconFont.family, pixelSize: root.theme.tray.iconSize, variableAxes: root.theme.iconFont.variableAxes})
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        Rectangle {
            width: 5
            height: 5
            radius: width / 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: root.theme.tray.iconSize / 2 - 1
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -root.theme.tray.iconSize / 2 + 2
            visible: root.service.unread > 0
            color: root.theme.accent
            border.color: root.theme.background
            border.width: 1
        }
    }
    DesktopPopup { theme: root.theme;
        id: popup
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        preferredWidth: root.theme.popups.notifications.width
        preferredHeight: root.theme.popups.notifications.height
        color: "transparent"
        grabFocus: true
        onVisibleChanged: {
            if (visible) content.forceActiveFocus();
            else {
                clearButton.armed = false;
                if (root.service.centerPopup === popup) root.service.centerPopup = null;
            }
        }
        Rectangle {
            anchors.fill: parent
            color: root.theme.background
            radius: root.theme.radius.large
            border.color: root.theme.border
            border.width: root.theme.widget.borderWidth
            ColumnLayout {
                id: content
                anchors.fill: parent
                anchors.margins: root.theme.widget.padding
                spacing: root.theme.spacing.small
                Keys.onEscapePressed: popup.visible = false
                Text { text: "Notifications"; font: root.theme.largeFont; color: root.theme.foreground }
                ThemedCheckBox {
                    text: "Do not disturb"
                    checked: root.service.dnd
                    onToggled: root.service.dnd = checked
                }
                ThemedCheckBox {
                    text: "Allow app-marked critical alerts"
                    checked: root.service.allowCritical
                    onToggled: root.service.allowCritical = checked
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: root.service.history.length + " in this session"
                        elide: Text.ElideRight
                        font: root.theme.smallFont
                        color: root.theme.muted
                    }
                    Basic.Button {
                        id: clearButton
                        objectName: "notificationClear"
                        property bool armed: false
                        text: armed ? "Confirm clear" : "Clear all"
                        enabled: root.service.entries.length > 0
                        font: root.theme.smallFont
                        palette.button: root.theme.surface
                        palette.buttonText: root.theme.foreground
                        onClicked: {
                            if (armed) { root.service.clear(); armed = false; }
                            else armed = true;
                        }
                        onEnabledChanged: if (!enabled) armed = false
                    }
                    Basic.Button {
                        objectName: "notificationCancelClear"
                        visible: clearButton.armed
                        text: "Cancel"
                        font: root.theme.smallFont
                        palette.button: root.theme.surface
                        palette.buttonText: root.theme.foreground
                        onClicked: clearButton.armed = false
                    }
                }
                ListView {
                    id: history
                    activeFocusOnTab: true
                    keyNavigationEnabled: true
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: root.theme.spacing.small
                    model: root.service.history
                    highlight: Rectangle {
                        z: 2
                        visible: history.activeFocus
                        color: "transparent"
                        radius: root.theme.radius.medium
                        border.width: 2
                        border.color: root.theme.focusBorder
                    }
                    Basic.ScrollBar.vertical: Basic.ScrollBar {}
                    delegate: NotificationCard { theme: root.theme;
                        required property var modelData
                        width: history.width
                        entry: modelData
                        service: root.service
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: history.count === 0
                        text: "No notifications"
                        font: root.theme.font
                        color: root.theme.muted
                    }
                }
                Basic.Button {
                    Layout.fillWidth: true
                    text: "Close"
                    font: root.theme.smallFont
                    palette.button: root.theme.surface
                    palette.buttonText: root.theme.foreground
                    onClicked: popup.visible = false
                }
            }
        }
    }
}
