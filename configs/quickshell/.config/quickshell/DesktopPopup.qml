import Quickshell
import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic as Basic

PopupWindow {
    id: root
    required property ScreenTheme theme
    property real preferredWidth: root.theme.popups.default.width
    property real preferredHeight: root.theme.popups.default.height
    readonly property var anchorWindow: anchor.item ? anchor.item.QsWindow.window : anchor.window
    readonly property var sizingScreen: root.theme.screen
    default property alias popupContent: viewport.flickableData
    implicitWidth: Math.max(1, Math.min(preferredWidth,
        sizingScreen.width - 2 * root.theme.spacing.small,
        anchorWindow ? anchorWindow.width - 2 * root.theme.spacing.small : preferredWidth))
    implicitHeight: Math.max(1, Math.min(preferredHeight,
        sizingScreen.height - root.theme.bar.height - 2 * root.theme.spacing.small))
    anchor.adjustment: PopupAdjustment.Slide
    color: "transparent"
    grabFocus: true
    contentItem.Keys.onEscapePressed: root.visible = false
    onVisibleChanged: {
        if (visible) {
            viewport.contentY = 0;
            contentItem.forceActiveFocus(Qt.PopupFocusReason);
        }
    }
    // Keep the intended layout height on short screens; scroll rather than cut off controls.
    property Item scrollView: Flickable {
        id: viewport
        parent: root.contentItem
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: Math.max(height, root.preferredHeight)
        Basic.ScrollBar.vertical: Basic.ScrollBar { palette.mid: root.theme.muted }
    }
    property Connections focusTracker: Connections {
        target: root.contentItem.Window.window
        function onActiveFocusItemChanged(): void {
            const item = root.contentItem.Window.window?.activeFocusItem;
            const flickable = viewport;
            let ancestor = item;
            while (ancestor && ancestor !== flickable.contentItem) ancestor = ancestor.parent;
            if (!ancestor || item.height > flickable.height) return;
            const y = item.mapToItem(flickable.contentItem, 0, 0).y;
            if (y < flickable.contentY) flickable.contentY = y;
            else if (y + item.height > flickable.contentY + flickable.height)
                flickable.contentY = y + item.height - flickable.height;
            flickable.contentY = Math.max(0, Math.min(flickable.contentY, flickable.contentHeight - flickable.height));
        }
    }
}
