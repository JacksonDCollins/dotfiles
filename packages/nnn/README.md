# nnn plain-o customization

Each build resolves upstream's **latest stable release**. `plain-o.patch` was last
validated against nnn **5.3**, but does not pin the version. It binds plain `o` to
`dotfiles-open-with` on the hovered file. Ctrl+O retains the original command
prompt; Enter, nuke, selections and plugin bindings are otherwise unchanged.
The built-in help documents the new binding. While filtering, `o` remains text.

From the dotfiles repository, as your normal user:

```sh
bash install-nnn.sh                         # install ~/.local/bin/nnn-dotfiles
bash install-nnn.sh --build-only /tmp/nnn-build  # build there without installing
```

The script resolves GitHub's latest-release redirect once per run, then downloads
that release's source archive and detached signature over HTTPS. It verifies the
signature using a temporarily downloaded maintainer public key in an isolated
GPG home, applies the local patch with zero fuzz, and builds with readline enabled.
There is no fixed-version fallback, extra JSON parser or new package dependency.
It runs upstream's `-K` collision check and checks its output too, because `-K`
returns success even on collisions. Publication uses an atomic rename, leaving
an existing binary intact if download, patching or compilation fails.

No sudo, package replacement, GUI launch or live shell reload is performed.
Build tools come from the existing `base-devel` dependency, and ncurses/readline
from stock nnn's dependencies on Arch. The output uses the host compiler and
libraries; source versions advance on each run, not in a background service.
`setup.sh` builds it before applying dotfiles. Stock `/usr/bin/nnn` still supplies
nuke and remains usable independently; the `n` shell helper uses this companion.

To upgrade the companion, rerun `install-nnn.sh` or `setup.sh`. If the latest
release changes the patched code incompatibly, the build stops; rebase the patch
rather than bypassing verification or falling back to an older release.
Pacman updates to stock nnn do not rebuild the companion automatically.
Rebuild after incompatible ncurses/readline library upgrades; no upgrade guard
is installed for this user-local binary.
The generated binary is not Stow-managed; dotfiles uninstall leaves it in place.

## Signing identity

Each build downloads the public key from Ubuntu's HTTPS keyserver and requires
primary fingerprint `E0B84447CD884CBB13E3266E4A865183AF6C5631`. It belongs to
Arun Prakash Jana and was checked against the maintainer's
[GitHub signing keys](https://api.github.com/users/jarun/gpg_keys) and Arch's
[nnn recipe](https://gitlab.archlinux.org/archlinux/packaging/packages/nnn/-/blob/main/PKGBUILD).
The key and temporary keyring are deleted after the build; no key is stored in
this repository or imported into your personal keyring. Keyserver unavailability
or a fingerprint mismatch stops the build. A future signing-key rotation requires
review; the builder never automatically trusts an unknown key to obtain a newer release.
