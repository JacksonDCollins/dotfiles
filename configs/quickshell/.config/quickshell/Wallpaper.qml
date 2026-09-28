pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: wallpaperWindow
            readonly property ScreenTheme theme: Theme.forScreen(modelData)
            required property var modelData
            screen: modelData
            color: wallpaperWindow.theme.background
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell-wallpaper"
            exclusionMode: ExclusionMode.Ignore
            focusable: false
            mask: Region {}

            Image {
                anchors.fill: parent
                source: wallpaperWindow.theme.wallpaperFilePath
                fillMode: Image.PreserveAspectCrop
            }
        }
    }
}
