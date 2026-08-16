# ImPuls production UI backgrounds

`menu_bg_small.webp.b64.*.txt` is a compressed WebP representation of the main-menu background supplied by the ImPuls project owner in the ChatGPT project session on 2026-08-16.

`loading_bg_small.webp.b64.*.txt` is a compressed WebP representation of the world-loading background supplied by the ImPuls project owner in the same project session. The decorative empty loading-bar frame is intentionally part of the source artwork; live progress is rendered by Godot over it.

The WebP bytes are split into base64 text fragments only for deterministic repository transport. `scripts/embedded_ui_texture.gd` reconstructs them in memory at runtime. No network request is needed to display either background.
