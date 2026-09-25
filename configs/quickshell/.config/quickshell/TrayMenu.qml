pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import QtQml.Models

Basic.Menu {
    id: root
    required property QsMenuHandle handle
    property QsMenuEntry entry: null
    property int maximumWidth: 320

    title: entry ? entry.text : ""
    enabled: !entry || entry.enabled
    icon.source: entry ? entry.icon : ""
    icon.color: "transparent"
    popupType: Popup.Window
    cascade: true
    padding: Theme.widget.padding
    spacing: Theme.spacing.small

    implicitWidth: {
        let widest = 0;
        for (let i = 0; i < count; i++)
            widest = Math.max(widest, itemAt(i).implicitWidth);
        return Math.min(maximumWidth, Math.ceil(widest) + leftPadding + rightPadding);
    }

    contentItem: ListView {
        implicitHeight: contentHeight
        model: root.contentModel
        currentIndex: root.currentIndex
        spacing: root.spacing
        clip: true
        interactive: contentHeight > height
        ScrollIndicator.vertical: Basic.ScrollIndicator {
            palette.mid: Theme.muted
            palette.text: Theme.foreground
        }
    }

    background: Rectangle {
        color: Theme.background
        radius: Theme.radius.large
        border.color: Theme.border
        border.width: Theme.widget.borderWidth
    }

    // Qt creates this delegate for insertMenu(), including its submenu behavior.
    delegate: EntryItem {
        // Qt exposes subMenu as the base Menu type; the adapter adds entry.
        readonly property var sourceMenu: subMenu
        entry: sourceMenu ? sourceMenu.entry : null
    }

    component EntryItem: Basic.MenuItem {
        id: action
        property QsMenuEntry entry: null
        text: entry ? entry.text : ""
        enabled: !entry || entry.enabled
        checkable: entry && entry.buttonType !== QsMenuButtonType.None
        checked: entry && entry.checkState === Qt.Checked
        font: Theme.font
        padding: Theme.spacing.medium
        hoverEnabled: true
        indicator: null
        arrow: null

        background: Rectangle {
            radius: Theme.radius.small
            color: action.down ? Theme.surfacePressed : action.highlighted ? Theme.surfaceHover : Theme.background
            border.color: Theme.focusBorder
            border.width: action.visualFocus ? Theme.widget.borderWidth : 0
        }

        contentItem: RowLayout {
            spacing: Theme.spacing.small

            MaterialIcon {
                visible: action.checkable
                font: Theme.iconFont
                color: action.enabled ? Theme.foreground : Theme.muted
                text: {
                    if (!action.entry)
                        return "";
                    const checked = action.entry.checkState === Qt.Checked;
                    if (action.entry.buttonType === QsMenuButtonType.RadioButton)
                        return checked ? "radio_button_checked" : "radio_button_unchecked";
                    if (action.entry.checkState === Qt.PartiallyChecked)
                        return "indeterminate_check_box";
                    return checked ? "check_box" : "check_box_outline_blank";
                }
            }

            IconImage {
                visible: action.entry && action.entry.icon !== ""
                source: action.entry ? action.entry.icon : ""
                implicitSize: Theme.font.pixelSize
            }

            Text {
                Layout.fillWidth: true
                text: action.text
                font: action.font
                color: action.enabled ? Theme.foreground : Theme.muted
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
            }

            MaterialIcon {
                visible: action.subMenu !== null
                text: "chevron_right"
                font: Theme.iconFont
                color: action.enabled ? Theme.foreground : Theme.muted
            }
        }

        onTriggered: {
            if (entry && !entry.hasChildren)
                entry.triggered();
        }
    }

    QsMenuOpener {
        id: opener
        menu: root.handle
    }

    Instantiator {
        model: {
            const entries = opener.children.values;
            let end = entries.length;
            while (end > 0 && entries[end - 1].isSeparator)
                end--;
            return entries.slice(0, end);
        }
        onObjectRemoved: (index, object) => (object as EntryLoader).detach()
        delegate: EntryLoader {}

        component EntryLoader: Loader {
            id: row
            required property int index
            required property QsMenuEntry modelData
            readonly property int kind: modelData.isSeparator ? 0 : modelData.hasChildren ? 2 : 1
            property bool ready: false
            property var inserted: null
            property bool insertedAsMenu: false
            active: false

            // Detach before Loader destroys an entry, including Qt's submenu row.
            function detach(): void {
                if (!inserted)
                    return;
                for (let i = 0; i < root.count; i++) {
                    if (insertedAsMenu ? root.menuAt(i) === inserted : root.itemAt(i) === inserted) {
                        if (insertedAsMenu)
                            root.takeMenu(i);
                        else
                            root.takeItem(i);
                        break;
                    }
                }
                inserted = null;
            }

            // Only data adaptation is dynamic; Qt owns submenu input and dismissal.
            function loadEntry(): void {
                detach();
                active = false;
                source = "";
                sourceComponent = undefined;
                if (kind === 2) {
                    setSource(Qt.resolvedUrl("TrayMenu.qml"), {
                        handle: modelData,
                        entry: modelData,
                        maximumWidth: Qt.binding(() => root.maximumWidth)
                    });
                } else {
                    sourceComponent = kind === 0 ? separatorComponent : actionComponent;
                }
                active = true;
            }

            Component.onCompleted: {
                ready = true;
                loadEntry();
            }
            onKindChanged: {
                if (ready)
                    loadEntry();
            }
            onLoaded: {
                inserted = item;
                insertedAsMenu = kind === 2;
                if (insertedAsMenu)
                    root.insertMenu(index, item);
                else
                    root.insertItem(index, item);
            }

            Component {
                id: separatorComponent
                Basic.MenuSeparator {
                    padding: Theme.spacing.small
                    contentItem: Rectangle {
                        implicitHeight: Theme.widget.borderWidth
                        color: Theme.border
                    }
                }
            }
            Component {
                id: actionComponent
                EntryItem { entry: row.modelData }
            }
        }
    }
}
