-- Applications supply these APIs at runtime; keep undefined-global checks elsewhere.
files["configs/hypr/**"] = { read_globals = { "hl" } }
files["machines/*/hypr/**"] = { read_globals = { "hl" } }
files["configs/nvim/**"] = { read_globals = { "vim" } }
files["machines/*/nvim/**"] = { read_globals = { "vim" } }
