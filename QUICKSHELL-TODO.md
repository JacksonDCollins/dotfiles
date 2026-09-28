# Quickshell desktop checklist

## Widgets

- [x] **Audio** — native PipeWire output/input selection, volume/mute and
  per-application playback controls. Hardware validation remains below.
- [x] **Lock and session controls** — independent Hyprlock/PAM and Hypridle;
  confirmations and compositor-verified locking before menu suspend.
- [x] **Notifications** — native toasts and center replace Mako; bounded,
  memory-only history, unread indicator, DND, actions and confirmed clearing.
- [x] **Battery and brightness** — native UPower state/estimates, 15%/5% alerts
  and logind backlight controls; hidden without hardware. No automatic power action.
- [x] **Application launcher** — themed Fuzzel on Super+Space, UWSM launching
  and Foot for terminal applications.

## Completed usability work and checks

- [x] Prevent bar overlap at 320–1920 logical pixels, including long workspace
  names. Keep the clock centered; compact media and horizontally scroll overflowing
  side controls. Keyboard focus scrolls the selected control into view.
- [x] Make clock, media and workspace controls keyboard accessible with visible
  focus. Super+B enters/leaves bar keyboard mode on the focused monitor; Tab and
  Shift+Tab navigate, Enter/Space activate, Escape dismisses popups or leaves the bar.
- [x] Bound all eight popups to their output; oversized content scrolls rather
  than losing controls. Native offscreen checks covered Escape, focus visibility,
  narrow layouts, tall content and suspend confirmation without executing it,
  at both normal and 2× Qt scaling.
- [x] Choose the focused output for a new toast batch; keep the batch there rather
  than chasing focus. Two-output offscreen checks covered selection and size bounds
  with long text. A transient live toast on Virtual-1 settled at x=1192, y=38,
  size 400×98, inside the 1600×900 output. Other outputs/DPI still need checking.
- [x] Verify Quickshell owns the notification D-Bus name. On this VM, Mako is
  absent and inactive; no competing notification daemon needs migration.
- [x] Verify the ScreenSaver D-Bus owner matches Hypridle. Fake-command checks
  cover delayed locking, wrong-owner/error/unlocked refusal and inhibitor-respecting
  suspend. These checks did not suspend, reboot or lock the real session.
- [x] Recheck fake battery warning tiers and brightness writes, including invalid
  targets and minimum brightness. No real backlight writes were performed.
- [x] PAM unlock was previously confirmed manually by the user.

Private checks are temporary development tools, not repository tests or runtime
requirements. The deliberately deleted tests directory has not been restored.

## Remaining live/hardware validation — not verified by simulation

- [ ] Check real multi-monitor/DPI placement, bar keyboard focus and popup/menu
  positioning in Hyprland. Only one 1600×900 Hyper-V output is available here.
- [ ] Observe notification toasts and the center while locking/unlocking, including
  every output. Toasts remain ordinary top-layer surfaces, not lock surfaces;
  native Hyprlock/compositor isolation owns security. Visual privacy is not yet
  signed off, and no disruptive lock test was performed in this pass.
- [ ] Validate audio device hotplug, Bluetooth headphone routing, microphone
  controls and per-application volume. This VM exposes no audio sinks/sources.
- [ ] Validate real Bluetooth pairing and Wi-Fi authentication. This VM has no
  Bluetooth adapter or Wi-Fi device; its current link is Ethernet.
- [ ] Validate physical battery discharge/charging and screen brightness. This VM
  has neither a battery nor a backlight.
- [ ] Test real lock-before-suspend, resume, inhibitors and all monitors. Suspend
  and destructive session actions require explicit permission and an operator
  able to unlock/resume; mock success is not a real suspend/resume test.

Existing: workspaces, clock/calendar, MPRIS controls, tray, Bluetooth and network
controls with live diagnostics. Keep infrastructure in Hyprcachy and UI/config in
dotfiles. No automatic package installs or service restarts. The installer and
Hyprland reload for this usability pass were explicitly approved by the user.
