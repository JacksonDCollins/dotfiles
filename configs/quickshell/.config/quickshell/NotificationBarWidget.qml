pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Basic.ToolButton {
    id: root
    required property var service
    Component.onDestruction: {
        if (service && service.centerPopup === popup) service.centerPopup = null;
    }
    implicitWidth: Theme.font.pixelSize + 2 * Theme.spacing.medium
    implicitHeight: metrics.height
    padding: 0
    hoverEnabled: true
    Accessible.name: "Notification center, " + service.unread + " unread" + (service.dnd ? ", do not disturb" : "")
    onClicked: {
        if (popup.visible) popup.visible = false;
        else service.showCenter(popup);
    }
    FontMetrics { id: metrics; font: Theme.font }
    component ThemedCheckBox: Basic.CheckBox {
        id: control
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        font: Theme.smallFont
        padding: Theme.spacing.small
        spacing: Theme.spacing.medium
        hoverEnabled: true
        palette.windowText: Theme.foreground
        contentItem: Text {
            text: control.text
            font: control.font
            color: Theme.foreground
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            verticalAlignment: Text.AlignVCenter
            leftPadding: control.mirrored ? 0 : control.indicator.width + control.spacing
            rightPadding: control.mirrored ? control.indicator.width + control.spacing : 0
        }
        indicator: Rectangle {
            implicitWidth: Theme.font.pixelSize + 6
            implicitHeight: implicitWidth
            x: control.mirrored ? control.width - width - control.rightPadding : control.leftPadding
            y: control.topPadding + (control.availableHeight - height) / 2
            radius: Theme.radius.small
            color: control.down ? Theme.surfacePressed : control.checked ? Theme.accent
                : control.hovered ? Theme.surfaceHover : Theme.surface
            border.width: control.visualFocus ? 2 : Theme.widget.borderWidth
            border.color: control.visualFocus ? Theme.focusBorder : control.checked ? Theme.accent : Theme.border
            opacity: control.enabled ? 1 : 0.5
            MaterialIcon {
                anchors.centerIn: parent
                text: "check"
                visible: control.checked
                color: control.down ? Theme.accent : Theme.background
                font: Qt.font({family: Theme.iconFont.family, pixelSize: Theme.font.pixelSize, variableAxes: Theme.iconFont.variableAxes})
            }
        }
    }
    background: Rectangle {
        radius: Theme.radius.medium
        color: root.down ? Theme.surfacePressed : root.hovered ? Theme.surfaceHover : Theme.background
        border.width: root.visualFocus ? Theme.widget.borderWidth : 0
        border.color: Theme.focusBorder
    }
    contentItem: MaterialIcon {
        text: root.service.dnd ? "notifications_off" : "notifications"
        color: root.service.dnd ? Theme.warning : Theme.foreground
        font: Qt.font({family: Theme.iconFont.family, pixelSize: Theme.font.pixelSize, variableAxes: Theme.iconFont.variableAxes})
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        Rectangle {
            width: 5
            height: 5
            radius: width / 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: Theme.font.pixelSize / 2 - 1
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -Theme.font.pixelSize / 2 + 2
            visible: root.service.unread > 0
            color: Theme.accent
            border.color: Theme.background
            border.width: 1
        }
    }
    DesktopPopup {
        id: popup
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        preferredWidth: 420
        preferredHeight: 560
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
            color: Theme.background
            radius: Theme.radius.large
            border.color: Theme.border
            border.width: Theme.widget.borderWidth
            ColumnLayout {
                id: content
                anchors.fill: parent
                anchors.margins: Theme.widget.padding
                spacing: Theme.spacing.small
                Keys.onEscapePressed: popup.visible = false
                Text { text: "Notifications"; font: Theme.largeFont; color: Theme.foreground }
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
                        font: Theme.smallFont
                        color: Theme.muted
                    }
                    Basic.Button {
                        id: clearButton
                        objectName: "notificationClear"
                        property bool armed: false
                        text: armed ? "Confirm clear" : "Clear all"
                        enabled: root.service.entries.length > 0
                        font: Theme.smallFont
                        palette.button: Theme.surface
                        palette.buttonText: Theme.foreground
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
                        font: Theme.smallFont
                        palette.button: Theme.surface
                        palette.buttonText: Theme.foreground
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
                    spacing: Theme.spacing.small
                    model: root.service.history
                    highlight: Rectangle {
                        z: 2
                        visible: history.activeFocus
                        color: "transparent"
                        radius: Theme.radius.medium
                        border.width: 2
                        border.color: Theme.focusBorder
                    }
                    Basic.ScrollBar.vertical: Basic.ScrollBar {}
                    delegate: NotificationCard {
                        required property var modelData
                        width: history.width
                        entry: modelData
                        service: root.service
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: history.count === 0
                        text: "No notifications"
                        font: Theme.font
                        color: Theme.muted
                    }
                }
                Basic.Button {
                    Layout.fillWidth: true
                    text: "Close"
                    font: Theme.smallFont
                    palette.button: Theme.surface
                    palette.buttonText: Theme.foreground
                    onClicked: popup.visible = false
                }
            }
        }
    }
}
