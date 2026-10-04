# Dotfiles

On Arch/CachyOS, run `bash setup.sh <profile>` as your regular user. It installs
missing dependencies from `packages-arch.txt` (and Stow) via sudo/pacman, then runs
`install.sh`, `install-tmux-plugins.sh`, `install-runtimes.sh`, and
`install-zsh-plugins.sh`. A package install performs a full system upgrade to avoid partial
Arch upgrades; pacman asks for confirmation. If everything is installed, no sudo
or package transaction is needed. Profiles are the subdirectories of `machines/`;
the default is `default`.

`bash install.sh <profile>` remains configuration-only, with GNU Stow required.
Use it for offline reapplication or on other distributions after installing the
equivalent dependencies yourself. Uninstalling dotfiles does not remove packages.
Stow installs complete `.bashrc`, `.zshrc`, Foot, tmux, and Hyprland configs directly.
There are no generated entrypoints or injected include/source hooks. Existing
files are backed up and tracked; `bash uninstall.sh` restores them.

## Git configuration

Shared preferences are Stowed to `~/.config/git/config`. Installation creates an
empty, regular `~/.gitconfig` only if it is missing, so normal `git config --global`
writes stay outside the repository. Existing local settings take precedence over
the shared preferences and are not overwritten. Set your identity normally:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Keep `~/.gitconfig` present; if you delete it, Git may write global changes to the
tracked XDG config instead. Uninstall leaves this local identity file in place.
The shared config uses Delta, which requires `git-delta` on Arch/CachyOS.

## Dependency ownership

`packages-arch.txt` owns user applications and their configuration dependencies,
independently of Hyprcachy:

- Applications: Foot, Neovim, tmux, and Quickshell for the wallpaper shell.
- Bash: Starship, Fastfetch, and Zoxide (also used by the tmux session picker).
- Tmux session picker: fzf.
- Foot/editor appearance: JetBrains Mono Nerd Font.
- Quickshell symbols: `ttf-material-symbols-variable` (Material Symbols Rounded).
- Editor clipboard/search/build support: wl-clipboard, ripgrep, fd, and base-devel.

Hyprcachy installs the OS/desktop infrastructure plus Git and Stow, clones/updates this
repository as the user, installs packages from this validated data-only list as
root, then calls this repository's `setup.sh` once as the user. Dotfiles own the
config/runtime installation sequence; Hyprcachy never executes dotfiles scripts as root. Publish changes here before updating a Hyprcachy installer that requires them.

## Zsh plugins

Zinit loads Deja and zsh-syntax-highlighting from declarations in
`configs/zsh/.config/zsh/plugins.zsh`. Syntax highlighting loads last; native
Tab completion is preserved (Deja's Tab picker is disabled). Right arrow still
accepts Deja suggestions. No zsh-autosuggestions plugin is loaded alongside it.
Alt+Right accepts the next suggestion word; Ctrl+Right remains tmux pane navigation.
Up/Down search history by the prefix typed before the cursor (and still move
within multiline input). Tab completion is case-insensitive; repeat Tab to enter
an arrow-navigable selection menu, then Enter to accept the selected completion.
Ctrl+R opens fzf's fuzzy search of the current shell's history (pane-local in
tmux). Enter puts the selected command at the prompt without executing it;
Escape cancels. Native history search remains the fallback if fzf's packaged
integration is unavailable. Foot's Ctrl+Shift+R separately searches terminal output.
Ctrl+X, then Ctrl+E opens the current command in Neovim; save and quit to return
it to the prompt, then press Enter to execute. Ctrl+X, then Ctrl+X toggles Deja
suggestions, leaving Ctrl+X itself free as a chord prefix.

`setup.sh` installs runtimes first, then runs `install-zsh-plugins.sh` as your
regular user. Zinit v3.17.0 is bootstrapped under
`${XDG_DATA_HOME:-~/.local/share}/zinit`; plugins are downloaded without executing
them. Deja's binary is pinned to 0.4.2 in mise, with its plugin at v0.4.2 and
syntax highlighting at 0.8.0. Existing checkouts are not reset or automatically
updated. Missing plugins are skipped on shell startup, never downloaded there.
After configuration-only installation, run `bash install-runtimes.sh` and
`bash install-zsh-plugins.sh`, then open a new Zsh shell.

Updates are explicit: adjust the plugin's `ver` in `plugins.zsh`, then use
Zinit's `update <owner/repository>` command with that version loaded; use
`zinit self-update` only when intentionally upgrading the manager. Keep the
Deja binary pin and plugin version aligned. Setup itself does not run updates.

Deja generates its cached integration during setup but does not import history
or start its daemon until used in a shell. Its per-user suggestion database is
shared across panes, even though Zsh's up-arrow/Ctrl-R histories are pane-local.
Deleting a pane-history file does not delete commands from Deja's database.
If desired, explicitly import a chosen history with `deja import --file PATH`;
setup never scans or imports private histories automatically.

## Tmux pane history

Zsh keeps independent command histories for tmux panes under
`${XDG_STATE_HOME:-~/.local/state}/zsh/panes/`. Each pane gets a persistent UUID;
Resurrect saves it with the layout and restores it before the new shell loads
history. Pane moves and session renames do not change that UUID. Histories are
namespaced by tmux socket path, so separate servers cannot delete each other's
files; restore on the same socket path to reuse saved history.

Commands are written incrementally. Outside tmux, Zsh uses `~/.zsh_history`.
Existing shared history is not imported or deleted. After applying the dotfiles,
open new Zsh panes or run `source ~/.zshrc` in existing ones to opt them in.
Scrollback remains separately managed by Resurrect's pane-content capture.
The post-save hook normalizes its ANSI formatting: reset before each newline,
then restore the active style on the next line. This prevents coloured blank
strips during replay while retaining colours and joined lines. It uses Bash and
Resurrect's existing tar/gzip/core utilities, not Python, awk, or mise.

Coverage is audited against tmux **3.7c**'s `grid_string_cells*` serializer in
[`grid.c`](https://github.com/tmux/tmux/blob/3.7c/grid.c), not an arbitrary subset
of application escape sequences. All emitted attributes are covered: bold,
faint, italic, five underline styles, blink, reverse, hidden, strike and overline;
standard/bright, indexed and RGB foreground/background colours; indexed/RGB
underline colours; full resets; DEC character-set shifts; and OSC 8 hyperlinks.
The filter repairs two capture quirks: `5:3` overline is replayed as SGR `53`,
and SO line-drawing shifts receive the G1 designation missing from captures.
Tabs and UTF-8 cell text remain unchanged. Re-audit this contract when tmux's
serializer changes; unknown future styling still fails safely.

Validation covered all 1,536 attribute/underline combinations, 992 colour cases
(including every indexed colour and RGB boundaries), 93 rendering scenarios,
five-cycle replay, and a 50,000-line real-tmux replay. Temporary test tools are
not runtime dependencies.

Processing happens in a private temporary directory; the scrollback archive is
replaced atomically only after successful processing. Unsupported formatting,
invalid archives, or processing errors leave the original archive untouched.
In isolated tests, 50,000 colour-changing lines took about 15 seconds to process
in Bash (550 KB input, 1 MB output); this adds save-time work, not shell-startup
work. Reload the installed tmux config and make a new save to use the fix.
Existing colour artifacts already present in captured scrollback are not erased.

After saves/restores, cleanup deletes a history only when no live pane and no
retained snapshot references its UUID. All `.txt` snapshots and `last` in known
Resurrect directories are checked, including previously configured directories.
Keep backups there if they must protect histories from cleanup. Legacy snapshots
without history metadata postpone deletion until they are removed or expire;
unreadable/malformed snapshots or failed live-pane checks also prevent deletion.
Resurrect normally expires backups after 30 days while retaining at least five.
No timer or separate history plugin is needed.

## mise runtimes and editor tools

`configs/mise/.config/mise/config.toml` is the version source for Node (including
npm), Python (including venv/pip), Go, Rust, Zig, Dart, tree-sitter, and the
configured language servers, formatters, and linters. Rust includes `rustfmt`,
`rust-src`, and `rust-analyzer`; Dart supplies its own language server. Neovim
uses nvim-lspconfig, Conform, and nvim-lint to run tools, without Mason plugins
or tool-install hooks. Luacheck comes from pacman (mise has no LuaRocks backend),
as does unzip. The clangd download targets Linux x86-64.

Initial setup needs internet and can take several minutes.

Runtime installation is explicit setup work, never a shell/editor startup hook.
After configs are installed, rerun `bash install-runtimes.sh` to install missing
versions and refresh shims. It runs mise from HOME rather than the caller's project
and refuses root; home/global mise configuration applies. Shells activate mise,
and Neovim adds its shims before loading plugins, including for GUI launches.

Pinning means `node = "24.21.0"`, not `node = "latest"`: setup does not silently
upgrade it when a new release appears. To upgrade, edit the tracked config's exact
version and rerun `install-runtimes.sh`. These are selected published versions,
not a claim that every toolchain has been integration-tested. Zig and ZLS share
`vars.zig_version`, so the pair is updated in one place.
Project `mise.toml` files can override these global defaults; install/trust project
tools explicitly. Restart Neovim/LSP clients after changing runtime versions.
Uninstalling dotfiles restores configs but does not delete downloaded tools or
old Mason installations. Existing Mason data can be removed manually after the
replacement tools are installed and working.

Project `.nvim.json` LSP overrides now map server names directly under `lsp`:
```json
{"lsp": {"lua_ls": {"settings": {"Lua": {"diagnostics": {"globals": ["vim"]}}}}, "zls": false}}
```
Move entries out of the old `lsp.mason` / `lsp.others` groups. Overrides remain
trusted, validated data-only settings; executable overrides are not allowed.
Extra project servers must be installed explicitly, for example through the
project's mise config.

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
- Quickshell owns notifications; do not run Mako or another notification daemon.
  Hyprcachy also installs PipeWire with
  WirePlumber and PulseAudio/ALSA compatibility, Hyprland/GTK portals, Qt 5/6
  Wayland support, and Noto fonts. Use the packaged service/portal defaults;
  do not launch duplicate daemons from the config.
- Super+Return: terminal; Super+Space: application launcher; Super+B: bar keyboard mode.
- Super+Q: close window; Super+V: float; Super+F: fullscreen.
- Super+Shift+M: exit session; Super+Alt+L: toggle the dwindle split direction.
- Super+arrows: window focus; Super+number: workspace; add Shift to move a window.
- Super+H/Comma or PageDown/PageUp: previous/next workspace on this monitor.
- Super+mouse buttons: move/resize windows.
- Media keys: volume up/down in 5% steps (capped at 100%) and mute via WirePlumber's
  `wpctl`; play/pause, next and previous via `playerctl`. Hyprland handles these
  directly; Quickshell keeps its existing MPRIS display integration. Setup installs
  `playerctl`; existing installations can run `sudo pacman -S playerctl`, then
  `hyprctl reload`. ZMK RGB keys control keyboard lighting, not monitor brightness.
  Each press also shows a themed symbol near the top-center of the focused
  monitor for 1.2 seconds. Playback shows the resulting playing/paused state;
  volume changes include a bottom-up vertical level meter (dimmed when muted).
  The bindings query `playerctl status` or `wpctl get-volume` after the action
  and send the snapshot to the click-through OSD. It does not steal focus,
  control playback, or continuously listen for media events. Unavailable state
  shows a question-mark symbol instead of guessing. No text is displayed.
  Test without changing volume:
  `quickshell --path "$HOME/.config/quickshell/shell.qml" ipc call mediaOsd display volume-up "Volume: 0.65"`.
- `work` preserves the monitor layout and monitor-specific workspace shortcuts;
  its optional browser/email shortcuts still require Firefox and Betterbird.
- `jacktop` preserves the 4K, scale-2 monitor settings.

### Application launcher

Super+Space opens Fuzzel: type to search installed desktop applications, use the
arrow keys to select, Enter to launch, and Escape to dismiss. Fuzzel and its launched
applications use `uwsm app --`; terminal applications open in Foot. Application
icons use the installed icon themes. No custom application index, helper script
or background service is needed. Fuzzel keeps its normal launch-frequency cache.

Dotfiles setup installs `fuzzel`. Behavior lives in `~/.config/fuzzel/fuzzel.ini`;
fonts, colors and layout live in the shared `~/.config/theme/fuzzel.ini` include.
For an existing installation, install `fuzzel`, run `bash install.sh` here, then
run `hyprctl reload` to pick up the binding. No Quickshell restart is required.

The `uuctl` launcher entry uses `~/.local/bin/dotfiles-uuctl` to show readable tmux
scope labels: session / window / pane. From a terminal, run `dotfiles-uuctl`
(optionally `--all`); plain `/usr/bin/uuctl` remains unchanged. The adapter only
changes menu text (including follow-up prompts) and returns the exact original
selection to packaged uuctl. It reads owned sockets in tmux's standard socket
directory and the inherited `TMUX` socket. Unmatched tmux scopes explicitly show
"exited pane" or "name unavailable", with PIDs for identification. An exited pane
can leave running child processes in its scope; this is not a claim they are safe
to kill. Linked windows show the first listed session context. Custom `-S` sockets
outside that directory need an inherited `TMUX` value. No daemon, tmux hooks or
live scope renaming is involved.

### Window-session restoration

Hyprcachy owns the experimental native dwindle-tree/session plugin, its controller,
package, startup entry and upgrade hooks. In Hyprcachy's UWSM session, the package
loads the native plugin through XDG autostart. Dotfiles only configure
`hl.plugin.window_session.config({ enabled = true, ... })`; restoration is opt-in.
Guard the call with `if hl.plugin.window_session and hl.plugin.window_session.config then`
because the plugin may not be loaded yet, may be absent, or may still be an older
running binary. Hyprland reloads configuration after the plugin loads. No `dofile`
loader, separate settings file, or dotfiles startup service is needed.
See [Hyprcachy's plugin documentation](https://github.com/JacksonDCollins/hyprcachy/tree/main/plugins/window-session)
for installation, compatibility and activation.

The earlier dotfiles-only placement recorder has been removed. Its saved files
and old `window-session.lua`/JSON options are left untouched, but are no longer
read. There is no dotfiles window-session service or external interpreter helper.

## Appearance

Catppuccin Mocha is fixed across Neovim, Foot, tmux, Hyprland borders, and Quickshell
notifications, with mauve accents. The `configs/theme` Stow package installs one
shared `~/.config/theme/` directory:

- `nvim.lua`: theme plugin, variant, and options.
- `foot.ini`: terminal palette.
- `fuzzel.ini`: launcher font, palette and layout.
- `tmux.conf`: pane, message, and statusline colors.
- `hyprland.lua`: desktop border colors.
- `hyprlock.conf`: lock-screen colors, clock and password-field layout.
- `desktop.json` and `wallpaper.jpeg`: Quickshell colors (including notifications), fonts and background image.

Quickshell's four font size fields accept positive integer pixels or percentages
of the widget's smaller monitor dimension in logical pixels (after display scaling).
For example, `"pixelSize": "1%"` rounds to 11 pixels on both 1920×1080 and
1080×1920 monitors; fixed numeric sizes remain unchanged. Invalid sizes
raise QML errors naming the JSON field.

Dimensions in `bar`, `spacing`, `widget`, `radius`, `tray`, and `popups` are
independent: each accepts logical pixels or a percentage of the smaller monitor
dimension. Changing `font.pixelSize` does not change these values. For example,
`bar.height: "3%"`, `widget.padding: 10`, and `tray.iconSize: "2%"` can coexist.
`popups` holds separate width/height settings for each popup. Power/session popup
heights of 0 mean content-sized; tray/toast heights of 0 mean no configured height
cap. Popups remain screen-capped and scroll when necessary.

`Theme` creates one resolved `ScreenTheme` per monitor. Window boundaries select
it with `Theme.forScreen(screen)` and pass it to widgets through a required
`theme` property. Widgets read `theme.font`, `theme.bar.height`, or
`theme.spacing.small`; they never calculate sizes or read raw JSON. Percentage
bindings update with screen dimensions. New widgets must accept and forward the
same theme object.

The app configs load these native theme files, keeping appearance separate from
behavior and keybindings. To change the look later, edit or replace this bundle;
there is no theme switcher, generator, or Omarchy dependency. Always install the
`theme` package alongside these apps, including when using Stow manually.
Neovim uses Catppuccin's normal opaque backgrounds; forced-transparency overrides
are gone. Existing statusline and netrw highlight hooks remain. The bundled
purple wallpaper image is unchanged.

Reapply dotfiles to install these settings, then reopen Neovim and Foot. The
installer reloads tmux if running; logging out and back in applies the desktop
and notification settings without manually restarting individual services.

## Quickshell

`configs/quickshell` installs the wallpaper and bar on each monitor. It loads
`~/.config/theme/desktop.json`; change its `wallpaper` filename to select another
image in the theme bundle. The wallpaper does not take input focus or reserve
screen space.

Super+B focuses the bar on the focused monitor. Tab/Shift+Tab navigate its controls;
Enter/Space activate, and Escape closes a popup or leaves bar keyboard mode.
The clock stays centered on narrow outputs; media becomes compact and overflowing
side controls scroll horizontally with the wheel/trackpad or keyboard focus.
Popups fit their output and scroll vertically when the screen is too short.

Stow also installs `quickshell.service` and its `graphical-session.target.wants`
link. UWSM starts and stops it with the graphical session. After updating dotfiles
in an already running session, use `systemctl --user daemon-reload` followed by
`systemctl --user restart quickshell.service`, or log out and back in.

The session pill offers Lock, Suspend, Log out, Restart and Shut down. Everything
except Lock requires confirmation. Power actions respect logind inhibitors; the
menu reports refusals rather than bypassing them. The existing Super-Shift-M
logout shortcut remains immediate; Super-L requests a confirmed screen lock.

Hyprcachy provisions `hyprlock` and `hypridle`. The Hyprland Stow package supplies
complete lock/idle configs, a session-scoped `hyprlock.service`, and an enabled
`hypridle.service`. The locker runs independently of Quickshell, uses PAM with
zero grace time, and gets its Catppuccin appearance from
`~/.config/theme/hyprlock.conf`. Hypridle locks after five idle minutes, powers
screens off after ten, respects idle inhibitors, and does not auto-suspend.

The session helper waits for hypridle's native compositor lock notification via
`org.freedesktop.ScreenSaver.GetActive` before requesting suspend. It verifies the
D-Bus owner's PID against the hypridle service and pins the unique bus name;
missing, mismatched or failed confirmation refuses the action. This requires
hypridle with GetActive support (verified against v0.1.8). For sleep requests from
other tools/lid events, hypridle starts the locker and uses its lock-notification
sleep delay inhibitor; logind's delay timeout or forced sleep can still override
that external path. No script can guarantee locking before firmware-forced sleep.

On an existing installation, install the packages explicitly, run `bash install.sh`
and `systemctl --user daemon-reload`. Test `systemctl --user start hyprlock.service`
and verify that you can unlock **before** starting `hypridle.service` or leaving
auto-lock enabled at the next login. Then start hypridle and restart Quickshell.
Private fake-command checks cover lock confirmation and refusal paths; they do not
replace real PAM, suspend/resume or multi-monitor validation. Current validation
status is recorded in the [desktop checklist](QUICKSHELL-TODO.md).

The audio pill opens native PipeWire controls for output and microphone selection,
volume/mute, and individual application playback streams. Sliders cover 0–100%
average volume; changing volume never implicitly unmutes a device. Selecting a
device changes WirePlumber's preferred default; applications explicitly pinned to
another device may remain there. Capture streams are not listed as playback apps,
and no microphone recording or level-monitor stream is started. Device removal
and unavailable/unready nodes disable their controls. The bar tracks the default
output continuously; additional node tracking is released when the popup closes.
No new package or command-line helper is required. Real hardware and Bluetooth
routing checks remain on the [desktop checklist](QUICKSHELL-TODO.md).

The network pill uses native `Quickshell.Networking`/NetworkManager state for
wired and Wi-Fi connectivity, including limited-access and captive-portal status.
Its popup offers Wi-Fi power, a 15-second scan, connect/disconnect, saved networks,
and in-popup WPA/WPA2-Personal/WPA3-SAE password entry. Scanned-network passwords go
through Quickshell's native API, never shell arguments or custom files;
the input is cleared on submission, cancellation and popup close. NetworkManager
may save credentials in its normal connection profiles. Scanning stops when the
popup closes, without stopping scans owned by another component.

The main popup also shows link speed, ping latency and packet loss without opening
settings. While that view is open, a single ping runs every second with a 0.8-second
reply timeout and one-second process deadline; probes never overlap. Link information
refreshes independently every five seconds, so those queries do not delay sampling.
The ping value averages successful replies from the last five samples (or displays
Timeout if the latest probe failed); packet loss uses the last 24 transmitted probes.
The rows are always present with `--` placeholders, preventing layout jumps while
waiting for results. This follows the stable rows and rolling windows used by
[Omarchy's Quickshell network panel](https://github.com/omacom/omarchy/blob/c5b4db77d68e7fbce5cf11120712ea322557e967/shell/plugins/panels/network/Panel.qml),
whose details timer runs every 1.5 seconds. The displayed
interface is a connected wired interface when available, otherwise the first
connected interface. Pings are bound to it and target Cloudflare's `1.1.1.1`, or
`2606:4700:4700::1111` for IPv6-only connections; the target is shown in the card.
History resets on reopening or changing interface/target. These are rolling samples,
not cumulative or internet-wide measurements.
Closing the popup, disconnecting, or switching to settings stops this live monitor.
No probes run while the popup is closed. ICMP filtering can look like packet loss;
link speed is not measured internet throughput.

“Settings & diagnostics…” stays inside the popup; it does not launch `nmtui` or
a terminal. It uses the existing `nmcli` and systemd `busctl` tools for:

- Per-profile autoconnect and confirmed forgetting, identified by UUID rather
  than potentially duplicate names. Forgetting an active profile may disconnect it.
- Automatic or custom IPv4/IPv6 DNS. Apply sets the mode for both families;
  Automatic clears custom servers. A UUID- and version-checked NetworkManager
  reapply updates the active profile without forcing a reconnect. If reapply is
  unsupported or a connection changes concurrently, the saved settings remain
  and the popup reports that a later reconnect may be needed.
- Hidden open, WPA/WPA2-Personal and WPA3-SAE Wi-Fi. A new profile starts with
  autoconnect off. Passwords are sent through a pipe (`passwd-file /dev/stdin`),
  not arguments or custom files. NetworkManager can save them normally. A failed
  activation retains the new profile; Forget it before recreating it for a retry.
- Current interface/profile, addresses, gateway, MAC, active DNS and reported link
  speed. Values refresh on opening the page, after edits, or with Refresh info.
- An explicit five-packet `ping` test, bound to the selected interface, with packet
  loss and min/average/max round-trip latency. The editable target defaults to the
  gateway, falling back to `1.1.1.1` when there is none. Closing the page stops the
  test. This manual test is separate from the main popup's automatic monitor.

Enterprise/certificate and legacy Wi-Fi setup remains outside this editor.
No packages are installed by the widget: NetworkManager, systemd and iputils
provide the existing command-line tools; Python is not a runtime dependency.
Isolated checks with fake commands do not replace real Wi-Fi authentication and
driver speed validation on hardware.

The Bluetooth pill opens native adapter power, scan and device controls. Devices
are sorted connected-first, then saved; batteries are shown only when reported.
Scanning stops after 30 seconds or when the popup closes. Pairing stays inside
the popup: QML drives `bluetoothctl --agent KeyboardDisplay` through util-linux's
`script` PTY, displaying PIN/passkey and explicit confirmation prompts. Closing
the popup cancels pending pairing; a two-minute deadline bounds stalled requests.
No Blueman, Python runtime, custom executable or compilation is required.

Hyprcachy setup installs `bluez` and enables `bluetooth.service`; the dotfiles
package list supplies `bluez-utils` and `util-linux`. The controller uses systemd's
`busctl` to identify the selected adapter. On an existing system, install those
packages and enable/start `bluetooth.service` explicitly. A VM without a passed-
through adapter will show “No Bluetooth adapter detected.” Pairing parses BlueZ's
English CLI output, so unfamiliar prompts fail closed or time out rather than
being automatically accepted. Device-specific pairing still needs real-hardware
validation after BlueZ upgrades.

### Battery and brightness

The compact power pill shows a battery/charging icon; its popup shows percentage,
state and UPower's time estimate. UPower's combined system battery is used, not
headset/mouse batteries. Brightness-only machines show a brightness icon. Each
section hides without its hardware, and the entire pill hides if neither exists
(as on the current VM).

Low-battery notifications fire once at 15% and once at 5% while discharging; the
5% alert is marked critical. They use the normal notification center and obey DND,
including its optional critical bypass. Alerts re-arm on AC power or recovery to
20%. The widget does not suspend or shut down the machine; UPower's own system
critical-power policy is not changed.

Brightness uses `/sys/class/backlight` readings and logind's `SetBrightness` method
via the existing `busctl`, without a brightness helper, sudo, or group changes.
Choose a device when multiple backlights exist. Slider changes apply on release
(or keyboard adjustment), with a 1%/one-hardware-step minimum to avoid turning the
panel completely off. Hardware is refreshed every 30 seconds and every two seconds
while the popup is open. Permission/driver failures appear in the popup.
External-monitor DDC/CI, keyboard LEDs and software gamma dimming are not included.

Hyprcachy now provisions `upower` (D-Bus activated; no manual service enablement).
For an existing installation, install it explicitly, run `bash install.sh` from
this repository, then restart `quickshell.service`. No packages or live hardware
settings are changed by editing these files. Real battery/backlight behavior still
needs checking on hardware; no deleted repository tests have been restored.

### Notification center

Quickshell is the notification daemon, using its native desktop-notification API.
The bell opens a scrollable, newest-first center with unread count, expandable text,
live application actions, per-entry removal and confirmed Clear all. Notifications
also appear as up to three top-right toasts on the focused screen when a new batch
starts. The batch stays on that output until empty, with a fallback if it disappears.
The center is available from each monitor's bar. No extra package, script or backend
is needed.

Do not disturb hides all toasts by default, including critical alerts. The optional
"Allow app-marked critical alerts" switch uses the protocol's urgency flag; this is
an application claim, not a trusted classification. Turning DND off does not replay
suppressed toasts. No notification sounds are played.

Privacy and retention:

- At most 5,000 records, in memory only. History and DND settings reset on logout,
  Quickshell restart or QML reload; there is no history file or message logging in
  the widget. This is not secure erasure from OS swap or process/core memory.
- Transient notifications never enter history and are discarded when hidden,
  expired or dismissed (at most eight seconds as a toast). Sender-withdrawn
  notifications are removed too, rather than archived against the app's request.
- Text is rendered literally: no HTML, inline/remote images, clickable body links,
  or automatic URL fetching. App names/titles/bodies are bounded to 128/512/8,192
  characters; at most eight action buttons are shown. Images and inline replies
  are not advertised as supported.
- Ordinary default-timeout notifications expire after eight seconds and remain as
  read-only history. Explicit app timeouts are honored; zero-timeout and default
  critical notifications remain actionable until closed. All toasts hide after
  eight seconds, so persistent notifications do not cover windows indefinitely.
  Quickshell 0.3.1 signals property changes, not every replacement request; an
  identical replacement may not restart its timer.
- Expired entries have no working actions. Opening the center marks history read;
  Clear all removes records and dismisses any still-active notifications.

For existing Mako installations, switch explicitly when ready (this interrupts
notification delivery briefly):

```bash
cd ~/dotfiles
bash install.sh
systemctl --user daemon-reload
systemctl --user stop mako.service
sudo pacman -R mako
systemctl --user restart quickshell.service
```

Review pacman's removal prompt; do not force-remove dependencies. If another tool
still requires Mako, keep the package but disable its startup instead and ensure
only Quickshell owns `org.freedesktop.Notifications`. The dotfiles install a user
D-Bus activation entry pointing at `quickshell.service`; new Hyprcachy installations
no longer provision Mako. Old Mako config links may be left dangling after updating
an existing checkout; they are unused once Mako is removed.

Private offscreen checks cover popup input, long text and toast output selection;
the toast layer-shell window is substituted with a floating window for those checks.
They do not prove real Wayland placement or lock-screen privacy. Toasts stay on the
ordinary top layer; native Hyprlock/compositor isolation, not QML, owns lock security.
See the [desktop checklist](QUICKSHELL-TODO.md) for outstanding live checks.

Add future widgets to this same shell rather than launching another copy. The
archived Omarchy widget under `deprecated/` is not installed.

Shell-owned icons use Material Symbols Rounded through `theme.iconFont`, configured
in `desktop.json` (`font.iconFamily` and `font.iconPixelSize`). Use symbol names such
as `play_arrow`, `pause`, and `chevron_right` in `MaterialIcon` items, which use native
font rendering to avoid distance-field artifacts. Keep normal labels on
`theme.font`/`theme.smallFont`. App-provided tray icons and artwork are
unchanged. The package manifest installs the font through the existing setup flow;
configuration-only installs on other systems need the font installed separately.

### QML editor support

Quickshell discovers neighboring QML components and singleton pragmas without a
checked-in `qmldir`; the notification tests exercise this layout. An editor's QML
language server may still need separate import metadata. Native runtime tests,
not an unsupported/empty LSP result, are the validation for these components.

The OpenRouter usage script and its service/timer/path units have been removed.
For an older installation, disable the old units before removing their files:
`systemctl --user disable --now omarchy-agent-usage-openrouter.timer omarchy-agent-usage-openrouter.path`.
Fresh installations do not need this migration.
