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
- Install `uwsm`; Hyprcachy's greetd launches
  `uwsm start -e -D Hyprland hyprland.desktop` (the packaged UWSM session command).
- Install `hyprpolkitagent`; Hyprcachy enables its systemd user service globally.
  UWSM activates `graphical-session.target`, which starts the agent and stops it
  on logout. There is no authentication-agent startup hook in Hyprland.
  Outside Hyprcachy, enable it once with `systemctl --user enable hyprpolkitagent.service`.
- Application bindings use `uwsm app --`; logout uses `uwsm stop` so systemd
  can shut down session applications/services in order. Do not use the native
  compositor exit command when running under UWSM.
- Hyprcachy also installs Mako (D-Bus-activated notifications), PipeWire with
  WirePlumber and PulseAudio/ALSA compatibility, Hyprland/GTK portals, Qt 5/6
  Wayland support, and Noto fonts. Use the packaged service/portal defaults;
  do not launch duplicate daemons from the config.
- Super+Return: terminal; Super+Q: close window; Super+V: float; Super+F: fullscreen.
- Super+Shift+M: exit session; Super+Alt+L: toggle the dwindle split direction.
- Super+arrows: window focus; Super+number: workspace; add Shift to move a window.
- Super+H/Comma or PageDown/PageUp: previous/next workspace on this monitor.
- Super+mouse buttons: move/resize windows.
- `work` preserves the monitor layout and monitor-specific workspace shortcuts;
  its optional browser/email shortcuts still require Firefox and Betterbird.
- `jacktop` preserves the 4K, scale-2 monitor settings.

## Quickshell wallpaper

`linux/quickshell` installs a wallpaper-only shell, with one background window per
monitor and a bundled image (`wallpaper.jpeg`). Change the `wallpaper` URL
in `~/.config/quickshell/shell.qml` to select your own image. It does not take input
focus or reserve screen space.

Stow also installs `quickshell.service` and its `graphical-session.target.wants`
link. UWSM starts and stops it with the graphical session. After updating dotfiles
in an already running session, use `systemctl --user daemon-reload` followed by
`systemctl --user start quickshell.service`, or log out and back in.

There is no standalone bar yet. Add future widgets to this same shell rather
than launching another copy. The archived Omarchy widget under `deprecated/`
is not installed. Mako continues to provide notifications.

The OpenRouter usage script and its service/timer/path units have been removed.
For an older installation, disable the old units before removing their files:
`systemctl --user disable --now omarchy-agent-usage-openrouter.timer omarchy-agent-usage-openrouter.path`.
Fresh installations do not need this migration.

## Checks

Run `bash tests/standalone.sh` to test installation, profile switching, and
uninstallation in a temporary HOME. It also runs Hyprland's offline config
validator when available; it does not reload your current desktop.
