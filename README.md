# Dotfiles

On Arch/CachyOS, run `bash setup.sh <profile>` as your regular user. It installs
missing dependencies from `packages-arch.txt` (and Stow) via sudo/pacman, then runs
`install.sh`. A package install performs a full system upgrade to avoid partial
Arch upgrades; pacman asks for confirmation. If everything is installed, no sudo
or package transaction is needed. Profiles are the subdirectories of `machines/`;
the default is `default`.

`bash install.sh <profile>` remains configuration-only, with GNU Stow required.
Use it for offline reapplication or on other distributions after installing the
equivalent dependencies yourself. Uninstalling dotfiles does not remove packages.
Stow installs complete `.bashrc`, Foot, tmux, and Hyprland configs directly.
There are no generated entrypoints or injected include/source hooks. Existing
files are backed up and tracked; `bash uninstall.sh` restores them.

## Dependency ownership

`packages-arch.txt` owns user applications and their configuration dependencies,
independently of Hyprcachy:

- Applications: Foot, Neovim, tmux, and Quickshell for the wallpaper shell.
- Bash: Starship, Fastfetch, and Zoxide (also used by the tmux session picker).
- Tmux session picker: fzf.
- Foot/editor appearance: JetBrains Mono Nerd Font.
- Editor clipboard/search/build support: wl-clipboard, ripgrep, fd, and base-devel.

Hyprcachy installs the OS/desktop infrastructure plus Git and Stow, clones/updates this
repository as the user, installs packages from this validated data-only list as
root, then runs `install.sh` as the user. It never executes dotfiles scripts as
root. Publish changes here before updating a Hyprcachy installer that requires them.

This moves the existing dependencies; it does not add every language toolchain.
Neovim's Mason setup still needs any additional runtimes required by your configured
languages. Those belong here or in project setup, not in Hyprcachy's OS package list.
Package installation is explicit setup work, never a shell/editor startup hook.

## Standalone desktop

Hyprland uses its native Lua configuration (tested with stock Hyprland 0.56.2),
not Omarchy's helpers. Older Hyprland releases without Lua configuration support
are not supported by these configs. Run `Hyprland --version` to check your version.

- Install `hyprland`; dotfiles setup supplies Foot and the configured JetBrains Mono Nerd Font.
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

Run `python tests/test_setup.py` for mocked dependency-bootstrap checks (no real
package installation), and `bash tests/standalone.sh` to test installation, profile switching, and
uninstallation in a temporary HOME. It also runs Hyprland's offline config
validator when available; it does not reload your current desktop.
