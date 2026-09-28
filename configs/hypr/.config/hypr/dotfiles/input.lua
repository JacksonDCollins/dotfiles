hl.config({
  input = {
    -- Installer/system defaults; standalone use remains US with no remappings.
    kb_layout = os.getenv("XKB_DEFAULT_LAYOUT") or "us",
    kb_model = os.getenv("XKB_DEFAULT_MODEL") or "",
    kb_variant = os.getenv("XKB_DEFAULT_VARIANT") or "",
    kb_options = os.getenv("XKB_DEFAULT_OPTIONS") or "",
    follow_mouse = 2,
    accel_profile = "flat",
  },
})
