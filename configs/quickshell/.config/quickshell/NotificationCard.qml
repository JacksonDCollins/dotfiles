pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Rectangle {
    id: root
    required property var entry
    required property var service
    property bool compact: false
    property bool expanded: false
    implicitHeight: content.implicitHeight + 2 * Theme.spacing.medium
    radius: Theme.radius.medium
    color: Theme.surface
    border.width: Theme.widget.borderWidth
    border.color: entry.critical ? Theme.warning : Theme.border
    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spacing.medium }
        spacing: Theme.spacing.small
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: root.entry.app + (root.entry.critical ? " · Critical" : "")
                textFormat: Text.PlainText
                elide: Text.ElideRight
                font: Theme.smallFont
                color: Theme.muted
            }
            Text {
                text: Qt.formatDateTime(new Date(root.entry.received), "MMM d hh:mm")
                font: Theme.smallFont
                color: Theme.muted
            }
            Basic.ToolButton {
                text: "×"
                font: Theme.font
                palette.buttonText: Theme.foreground
                Accessible.name: "Remove notification"
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
            font: Theme.font
            color: Theme.foreground
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
            font: Theme.smallFont
            color: Theme.foreground
        }
        Basic.ToolButton {
            visible: !root.compact && (root.expanded || titleText.truncated || bodyText.truncated)
            text: root.expanded ? "Show less" : "Show more"
            font: Theme.smallFont
            palette.buttonText: Theme.accent
            onClicked: root.expanded = !root.expanded
        }
        Flow {
            Layout.fillWidth: true
            spacing: Theme.spacing.small
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
                        color: Theme.foreground
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                    width: Math.min(implicitWidth, content.width)
                    font: Theme.smallFont
                    palette.button: Theme.background
                    palette.buttonText: Theme.foreground
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
            font: Theme.smallFont
            color: Theme.muted
        }
    }
}
