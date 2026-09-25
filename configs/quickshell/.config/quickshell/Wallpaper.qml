pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            required property var modelData
            screen: modelData
            color: Theme.background
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
                source: Theme.wallpaperFilePath
                fillMode: Image.PreserveAspectCrop
            }
        }
    }
}
