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
    required property ScreenTheme theme
    required property QsMenuHandle handle
    property QsMenuEntry entry: null
    property int maximumWidth: root.theme.popups.tray.width

    title: entry ? entry.text : ""
    enabled: !entry || entry.enabled
    icon.source: entry ? entry.icon : ""
    icon.color: "transparent"
    popupType: Popup.Window
    cascade: true
    padding: root.theme.widget.padding
    spacing: root.theme.spacing.small

    implicitWidth: {
        let widest = 0;
        for (let i = 0; i < count; i++)
            widest = Math.max(widest, itemAt(i).implicitWidth);
        return Math.max(1, Math.min(maximumWidth, root.theme.screen.width - 2 * root.theme.spacing.small, Math.ceil(widest) + leftPadding + rightPadding));
    }

    implicitHeight: Math.max(1, Math.min(contentItem.implicitHeight + topPadding + bottomPadding,
        root.theme.popups.tray.height || root.theme.screen.height,
        root.theme.screen.height - 2 * root.theme.spacing.small))

    contentItem: ListView {
        implicitHeight: contentHeight
        model: root.contentModel
        currentIndex: root.currentIndex
        spacing: root.spacing
        clip: true
        interactive: contentHeight > height
        ScrollIndicator.vertical: Basic.ScrollIndicator {
            palette.mid: root.theme.muted
            palette.text: root.theme.foreground
        }
    }

    background: Rectangle {
        color: root.theme.background
        radius: root.theme.radius.large
        border.color: root.theme.border
        border.width: root.theme.widget.borderWidth
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
        font: root.theme.font
        padding: root.theme.spacing.medium
        hoverEnabled: true
        indicator: null
        arrow: null

        background: Rectangle {
            radius: root.theme.radius.small
            color: action.down ? root.theme.surfacePressed : action.highlighted ? root.theme.surfaceHover : root.theme.background
            border.color: root.theme.focusBorder
            border.width: action.visualFocus ? root.theme.widget.borderWidth : 0
        }

        contentItem: RowLayout {
            spacing: root.theme.spacing.small

            MaterialIcon { theme: root.theme;
                visible: action.checkable
                font: root.theme.iconFont
                color: action.enabled ? root.theme.foreground : root.theme.muted
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
                implicitSize: root.theme.font.pixelSize
            }

            Text {
                Layout.fillWidth: true
                text: action.text
                font: action.font
                color: action.enabled ? root.theme.foreground : root.theme.muted
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
            }

            MaterialIcon { theme: root.theme;
                visible: action.subMenu !== null
                text: "chevron_right"
                font: root.theme.iconFont
                color: action.enabled ? root.theme.foreground : root.theme.muted
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
                        theme: Qt.binding(() => root.theme),
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
                    padding: root.theme.spacing.small
                    contentItem: Rectangle {
                        implicitHeight: root.theme.widget.borderWidth
                        color: root.theme.border
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
