# Dotfiles

On Arch/CachyOS, run `bash setup.sh <profile>` as your regular user. It installs
missing dependencies from `packages-arch.txt` (and Stow) via sudo/pacman, then runs
`install.sh` and `install-runtimes.sh`. A package install performs a full system upgrade to avoid partial
Arch upgrades; pacman asks for confirmation. If everything is installed, no sudo
or package transaction is needed. Profiles are the subdirectories of `machines/`;
the default is `default`.

`bash install.sh <profile>` remains configuration-only, with GNU Stow required.
Use it for offline reapplication or on other distributions after installing the
equivalent dependencies yourself. Uninstalling dotfiles does not remove packages.
Stow installs complete `.bashrc`, Foot, tmux, and Hyprland configs directly.
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

## Appearance

Catppuccin Mocha is fixed across Neovim, Foot, tmux, Hyprland borders, and Mako
notifications, with mauve accents. The `configs/theme` Stow package installs one
shared `~/.config/theme/` directory:

- `nvim.lua`: theme plugin, variant, and options.
- `foot.ini`: terminal palette.
- `tmux.conf`: pane, message, and statusline colors.
- `hyprland.lua`: desktop border colors.
- `mako.conf`: notification colors.
- `desktop.json` and `wallpaper.jpeg`: Quickshell background color and image.

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

Stow also installs `quickshell.service` and its `graphical-session.target.wants`
link. UWSM starts and stops it with the graphical session. After updating dotfiles
in an already running session, use `systemctl --user daemon-reload` followed by
`systemctl --user restart quickshell.service`, or log out and back in.

Add future widgets to this same shell rather than launching another copy. The
archived Omarchy widget under `deprecated/` is not installed. Mako continues to
provide notifications.

Shell-owned icons use Material Symbols Rounded through `Theme.iconFont`, configured
in `desktop.json` (`font.iconFamily` and `font.iconPixelSize`). Use symbol names such
as `play_arrow`, `pause`, and `chevron_right` in `MaterialIcon` items, which use native
font rendering to avoid distance-field artifacts. Keep normal labels on
`Theme.font`/`Theme.smallFont`. App-provided tray icons and artwork are
unchanged. The package manifest installs the font through the existing setup flow;
configuration-only installs on other systems need the font installed separately.

### QML editor support

The `qmldir` beside `shell.qml` registers components and singletons for both
Quickshell and the host's `qmlls6`, without machine-specific generated paths.
Register each new component there, for example `Workspaces 1.0 Workspaces.qml`.
Prefix singleton entries with `singleton`. Restart the editor's QML language
server after switching back from generated `.qmlls.ini` metadata.

The OpenRouter usage script and its service/timer/path units have been removed.
For an older installation, disable the old units before removing their files:
`systemctl --user disable --now omarchy-agent-usage-openrouter.timer omarchy-agent-usage-openrouter.path`.
Fresh installations do not need this migration.
