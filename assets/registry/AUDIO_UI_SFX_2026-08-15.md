# Interface / system SFX — 2026-08-15

Staging-library asset only. Do not wire this pack into runtime from the asset-research chat.

## Kenney Interface Sounds
- Status: `PINNED_VENDOR`
- Path: `assets/audio/third_party/kenney_interface_sounds/`
- Upstream: `Calinou/kenney-interface-sounds`
- Pinned commit: `4596a49eaf5a533948d49a47467f606bcdea70ff`
- Original creator: Kenney.
- License: Creative Commons Zero (CC0); personal, educational and commercial use is allowed, attribution is optional according to the bundled license.
- Contents: 100 interface sounds including clicks, snaps, minimize/maximize-style cues, confirmations and other system feedback. This Godot-oriented mirror stores them as WAV files.

Recommended later semantic groups: `UI_HOVER`, `UI_CLICK`, `UI_CONFIRM`, `UI_CANCEL`, `UI_ERROR`, `UI_NOTIFICATION`, `UI_INVENTORY_MOVE`, `UI_SAVE`, `UI_LOAD`.

The main game-development flow should audition and normalize selected sounds before integration; source filenames must not become gameplay API names.
