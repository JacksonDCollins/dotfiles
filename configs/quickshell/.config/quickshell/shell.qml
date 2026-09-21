pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Scope {
    Bar {}
    Wallpaper {}
}
// ShellRoot {
//     id: root
//     readonly property string themeDir: Quickshell.env("HOME") + "/.config/theme"
//     readonly property var theme: JSON.parse(themeFile.text())
//
//     FileView {
//         id: themeFile
//         path: root.themeDir + "/desktop.json"
//         blockLoading: true
//     }
//
//     Variants {
//         model: Quickshell.screens
//
//         PanelWindow {
//             required property var modelData
//             screen: modelData
//             color: root.theme.background
//             anchors {
//                 top: true
//                 bottom: true
//                 left: true
//                 right: true
//             }
//             WlrLayershell.layer: WlrLayer.Background
//             WlrLayershell.namespace: "quickshell-wallpaper"
//             exclusionMode: ExclusionMode.Ignore
//             focusable: false
//             mask: Region {}
//
//             Image {
//                 anchors.fill: parent
//                 source: "file://" + root.themeDir + "/" + root.theme.wallpaper
//                 fillMode: Image.PreserveAspectCrop
//             }
//         }
//     }
// }
