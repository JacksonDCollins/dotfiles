pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string themeDir: Quickshell.env("HOME") + "/.config/theme"
    readonly property var config: JSON.parse(themeFile.text())
    property int revision: 0

    // Only window boundaries look up a theme. Widgets receive the resolved object.
    function forScreen(screen: var): ScreenTheme {
        const revision = root.revision;
        for (let i = 0; i < screenThemes.count; ++i) {
            const theme = screenThemes.objectAt(i) as ScreenTheme;
            if (theme && theme.screen === screen)
                return theme;
        }
        return null;
    }

    Instantiator {
        id: screenThemes
        model: Quickshell.screens
        delegate: ScreenTheme {
            required property var modelData
            screen: modelData
            config: root.config
            themeDir: root.themeDir
        }
        onObjectAdded: root.revision++
        onObjectRemoved: root.revision++
    }
    FileView {
        id: themeFile
        path: root.themeDir + "/desktop.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }
}
