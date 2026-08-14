# ImPuls asset staging

This directory is intentionally **not gameplay-integrated**.

Source-only asset chats may download, sanitize, classify and document verified reusable packs here without touching game scripts, scenes, `project.godot`, autoloads or build/export settings.

## Workflow
1. Verify the source page and license. Prefer CC0.
2. Store the physical files under an appropriate `assets/staging/<category>/...` path.
3. Keep `SOURCE.md` and `LICENSE.txt` with every third-party pack.
4. Record what the pack contains and the recommended production destination.
5. Do **not** wire staged assets into gameplay from a source-only chat.
6. The main integration chat reviews the staging area and chooses what to move/use.

## Current categories
- `vfx_nonmagic/` — physical/world/combat/environment effects that are not tied to the magic runtime.

A staged pack is available for integration, not automatically approved as a production dependency. The main integration chat remains responsible for performance, art direction, deduplication and runtime wiring.
