pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Rectangle {
    id: root
    required property ScreenTheme theme
    required property var entry
    required property var service
    property bool compact: false
    property bool expanded: false
    implicitHeight: content.implicitHeight + 2 * root.theme.spacing.medium
    radius: root.theme.radius.medium
    color: root.theme.surface
    border.width: root.theme.widget.borderWidth
    border.color: entry.critical ? root.theme.warning : root.theme.border
    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: root.theme.spacing.medium }
        spacing: root.theme.spacing.small
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: root.entry.app + (root.entry.critical ? " · Critical" : "")
                textFormat: Text.PlainText
                elide: Text.ElideRight
                font: root.theme.smallFont
                color: root.theme.muted
            }
            Text {
                text: Qt.formatDateTime(new Date(root.entry.received), "MMM d hh:mm")
                font: root.theme.smallFont
                color: root.theme.muted
            }
            Basic.ToolButton {
                id: closeButton
                text: "close"
                implicitWidth: root.theme.iconFont.pixelSize + 2 * root.theme.spacing.small
                implicitHeight: implicitWidth
                padding: root.theme.spacing.small
                hoverEnabled: true
                Accessible.name: "Remove notification"
                contentItem: MaterialIcon {
                    theme: root.theme
                    text: closeButton.text
                    color: closeButton.down || closeButton.hovered ? root.theme.foreground : root.theme.muted
                    Accessible.ignored: true
                }
                background: Rectangle {
                    radius: root.theme.radius.small
                    color: closeButton.down ? root.theme.surfacePressed
                        : closeButton.hovered ? root.theme.surfaceHover : "transparent"
                    border.color: root.theme.focusBorder
                    border.width: closeButton.visualFocus ? root.theme.widget.borderWidth : 0
                }
                onClicked: root.service.forget(root.entry)
            }
        }
        Text {
            id: titleText
            Layout.fillWidth: true
            text: root.entry.summary
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: root.expanded ? 1000 : 2
            elide: Text.ElideRight
            font: root.theme.font
            color: root.theme.foreground
        }
        Text {
            id: bodyText
            Layout.fillWidth: true
            visible: text !== ""
            text: root.entry.body
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: root.expanded ? 10000 : 3
            elide: Text.ElideRight
            font: root.theme.smallFont
            color: root.theme.foreground
        }
        Basic.ToolButton {
            visible: !root.compact && (root.expanded || titleText.truncated || bodyText.truncated)
            text: root.expanded ? "Show less" : "Show more"
            font: root.theme.smallFont
            palette.buttonText: root.theme.accent
            onClicked: root.expanded = !root.expanded
        }
        Flow {
            Layout.fillWidth: true
            spacing: root.theme.spacing.small
            Repeater {
                model: root.entry.notification ? root.entry.notification.actions.slice(0, 8) : []
                delegate: Basic.Button {
                    id: action
                    required property var modelData
                    text: modelData.text.slice(0, 120) || (modelData.identifier === "default" ? "Open" : "Action")
                    contentItem: Text {
                        text: action.text
                        textFormat: Text.PlainText
                        font: action.font
                        color: root.theme.foreground
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                    width: Math.min(implicitWidth, content.width)
                    font: root.theme.smallFont
                    palette.button: root.theme.background
                    palette.buttonText: root.theme.foreground
                    Accessible.name: text
                    onClicked: {
                        if (root.entry.notification && modelData) {
                            root.entry.read = true;
                            modelData.invoke();
                        }
                    }
                }
            }
        }
        Text {
            visible: !root.compact && root.entry.notification === null
            text: "History · actions expired"
            font: root.theme.smallFont
            color: root.theme.muted
        }
    }
}
