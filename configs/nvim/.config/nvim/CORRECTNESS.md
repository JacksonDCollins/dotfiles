# Neovim Correctness Remediation

Audit target: Neovim 0.12.5 and the revisions in `nvim-pack-lock.json`.

Host-level tool availability is intentionally out of scope.

## Security And Data Safety

- [x] Trust and validate `.nvim.json` before applying project-local LSP configuration.
- [x] Prevent project-local configuration from defining executable LSP fields.
- [x] Support explicit project server replacement or disabling without invalid table merges.
- [x] Escape external text before embedding paths and Git branches in the statusline.
- [x] Make netrw file creation exclusive so an existing file is never truncated.

## Completion And Editing

- [x] Make `<C-f>` context-dependent: accept visible Copilot text first, otherwise scroll Blink documentation, then fall back.
- [x] Integrate Sidekick NES into Blink's `<Tab>` chain without bypassing Tabout.
- [x] Fix the insert-line `nvim-surround` plug mapping.
- [x] Use the `locals` Treesitter query for the `@local.scope` textobject.

## LSP Lifecycle

- [x] Make document-highlight autocmds buffer-local, idempotent, and aware of remaining clients.
- [x] Toggle inlay hints only in the attached buffer.
- [x] Remove forced duplicate LSP shutdown and rely on Neovim's native graceful exit handler.
- [x] Remove editor-side tool installation/restart callbacks; setup installs tools before Neovim enables servers.
- [x] Validate malformed project LSP structures without aborting all LSP setup.

## Treesitter And Linting

- [x] Install missing Treesitter parsers asynchronously instead of blocking `FileType` for up to 30 seconds.
- [x] Enable expression folding when Treesitter folding is configured.
- [x] Avoid running filename-based ShellCheck against stale on-disk content on `InsertLeave`.

## Statusline And Theme

- [x] Scope Copilot loading state to pending requests for the current buffer.
- [x] Close or reuse the Copilot spinner timer and refresh both native and tpipeline statuslines while it animates.
- [x] Render files in the current directory as named files rather than `[No Name]`.
- [x] Reapply custom statusline and netrw highlights after colorscheme changes; let the theme own backgrounds.
- [x] Use a valid statusline highlight fallback outside tmux.

## Core Behavior And Maintenance

- [x] Replace partial module reloading with Neovim 0.12's `:restart` command.
- [x] Make the diagnostic location-list toggle inspect and close only the current window's location list.
- [x] Correct netrw jump-list settings and remove the invalid `b:netrw_lastfile` assignment.
- [x] Set `shiftwidth` and `tabstop` consistently with four-space indentation.
- [x] Replace deprecated `vim.loop` accesses with `vim.uv`.
- [x] Remove permanent `lazyredraw`, which Neovim documents as unsafe for general use.
- [x] Track Sidekick's Copilot status without emitting notifications.

## Verification

- [x] All Lua files parse and the pack lockfile is valid JSON.
- [x] Stylua passes for all changed Lua files.
- [x] Headless startup and shutdown complete without errors or deprecated API warnings.
- [x] Locked plugin revisions match installed plugin revisions.
- [x] Focused regressions cover project config validation, statusline escaping, keymap ownership, LSP scoping, and reload behavior.
- [x] Relevant health checks pass, excluding documented host-level tool availability.
