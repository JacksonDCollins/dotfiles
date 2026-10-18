# vis retained buffers

`retained-buffers.patch` separates file lifetime from window lifetime. Switching
files preserves each buffer's text, undo/redo history and last primary cursor,
without creating a permanent window for it. Splits and layouts behave normally;
two splits can display the same underlying buffer. There is no Lua text cache.

The patch reuses vis's file identity and window-opening lifecycle, so reopening
a buffer restores its in-memory contents and initializes syntax/plugins normally.
Hidden buffers remain in `vis:files()` and receive `FILE_CLOSE` only on deletion
or shutdown. Unnamed buffers are retained too, even when empty, to preserve redo.

## Build and install

```sh
bash scripts/install-vis.sh
# Apply the vis Stow package with install.sh, then restart vis.
# Build a standalone bundle without activating it instead:
bash scripts/install-vis.sh --build-only /tmp/vis-buffers-build
```

The builder pins upstream commit `254329d9f4f1df1158397080d403f3f112918aff`
(the installed distro version used when developing the patch). It verifies the
source archive's SHA-256, applies the patch with zero fuzz, and builds with Lua,
TRE and curses. The archive checksum is pinned in `scripts/install-vis.sh`;
this is an integrity check, not a maintainer-signature verification.

Each default build installs an isolated bundle under
`~/.local/lib/vis-dotfiles/build.*`, including its matching Lua runtime, lexers
and helper executables. Only after successful installation is `current`
atomically switched to the new bundle. The Stow-managed `~/.local/bin/vis`
launcher runs that bundle and puts its helpers on PATH. It contains no editor
settings. `/usr/bin/vis` and all distribution files remain untouched.

`setup.sh` builds the bundle before applying dotfiles. The existing Arch
`base-devel`, `vis`, `vis-lexers` and `lua-lpeg` dependencies supply the build
and runtime requirements. Pacman does not rebuild this local binary; rerun the
builder after incompatible library upgrades. Updating upstream requires reviewing
the patch and updating the pinned revision, checksum, VERSION and API values.

Old bundles are retained so active editor processes can still load their runtime.
For rollback, close vis and point `~/.local/lib/vis-dotfiles/current` back to an
older bundle with `ln -sfn`. Delete unused `build.*` directories only after the
processes using them have exited. Dotfiles uninstall removes the launcher but
leaves these generated bundles in place.

## Configuration and use

Configuration remains in `configs/vis/.config/vis/`:

- **Space → e** opens nnn at the current file. Selection changes only the current
  split's buffer, including when another split already displays that file.
- `:e filename` switches buffers without discarding edits. `:e` reloads the
  current file from disk; `:e!` explicitly discards its edits when reloading.
  Reloading a buffer displayed in multiple splits is refused.
- `:bnext` / `:bprev` cycle through buffers in the current split. `:buffers` lists
  them: `*` is current, `+` is modified, and zero views means hidden.
- `:bdelete` removes the current buffer and shows another, or an empty buffer if
  none remain. `:bdelete!` explicitly discards its edits. Deletion is refused
  while another split displays that buffer; switch or close that view first.
- **Ctrl-w j/k** switches splits. `:split` / `:vsplit` and layouts are unchanged.
- `:q` closes a split, retaining its buffer. Closing the last split or using
  `:qall` refuses to exit while **any** buffer has unsaved changes. `:wq` saves
  only the current file; hidden modified buffers still prevent exit. Use
  `:bnext` and `:w` to save them individually; native `:X` still visits windows.
- `:q!` on the last split and `:qall!` discard **all** remaining unsaved buffers
  on exit. Closing a non-last split, even with `:q!`, does not delete its buffer.

The stock `/usr/bin/vis` keeps stock behavior: it cannot retain hidden buffers
or run these buffer commands. Files containing glob characters still go through
vis's native `vis-open` filename handling, including its filename limitations.

## Validation

Before activating a changed patch, exercise these cases in a temporary config:

1. Edit multiple named and unnamed buffers; switch and undo/redo independently,
   including an empty unnamed buffer after undoing all its edits.
2. Switch one of two splits without moving or replacing the other split's file;
   share a buffer across splits, then resize and change horizontal/vertical layout.
3. Reload and delete buffers, including refused dirty/shared-buffer operations.
4. Try `:q`, `:wq`, and `:qall` with hidden unsaved buffers; verify refusal leaves
   their contents accessible. Test explicit forced exit separately.
5. Use nnn to switch files, reopen a hidden buffer, select a file already shown
   in another split, and cancel. Check syntax and directory-startup cancellation.
6. Check cleanup with address/undefined-behavior sanitizers and file-close events.

This is a user-maintained core patch, not an upstream-supported buffer model.
It retains buffers in memory only: no autosave, crash recovery or cross-session
persistence. Window-local selections and viewport state are not buffer history;
only the last primary cursor is restored when switching back.
