# Dotfiles

Install with `bash install.sh <profile>` as your regular user. Profiles are the
subdirectories of `machines/`; the default is `default`. GNU Stow is required.
Stow installs complete `.bashrc`, Foot, tmux, and Hyprland configs directly.
There are no generated entrypoints or injected include/source hooks. Existing
files are backed up and tracked; `bash uninstall.sh` restores them.

## Standalone desktop

Hyprland uses its native Lua configuration (tested with stock Hyprland 0.56.2),
not Omarchy's helpers. Older Hyprland releases without Lua configuration support
are not supported by these configs. Run `Hyprland --version` to check your version.

- Install `hyprland` and `foot`; use `ttf-jetbrains-mono-nerd` for the configured font.
- Start Hyprland using your distro's normal session launcher (`start-hyprland`).
- Super+Return: terminal; Super+Q: close window; Super+V: float; Super+F: fullscreen.
- Super+Shift+M: exit session; Super+Alt+L: toggle the dwindle split direction.
- Super+arrows: window focus; Super+number: workspace; add Shift to move a window.
- Super+H/Comma or PageDown/PageUp: previous/next workspace on this monitor.
- Super+mouse buttons: move/resize windows.
- `work` preserves the monitor layout and monitor-specific workspace shortcuts;
  its optional browser/email shortcuts still require Firefox and Betterbird.
- `jacktop` preserves the 4K, scale-2 monitor settings.

There is no standalone Quickshell bar here yet. The archived workspace widget
under `deprecated/` requires Omarchy and is not installed. Installing Quickshell
alone does not create a bar, launcher, lock screen, or notification service.

The OpenRouter usage script and its service/timer/path units have been removed.
For an older installation, disable the old units before removing their files:
`systemctl --user disable --now omarchy-agent-usage-openrouter.timer omarchy-agent-usage-openrouter.path`.
Fresh installations do not need this migration.

## Checks

Run `bash tests/standalone.sh` to test installation, profile switching, and
uninstallation in a temporary HOME. It also runs Hyprland's offline config
validator when available; it does not reload your current desktop.
