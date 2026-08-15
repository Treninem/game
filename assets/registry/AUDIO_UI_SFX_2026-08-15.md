# Interface / system SFX — 2026-08-15

Staging-library asset only. Do not wire this pack into runtime from the asset-research chat.

## Kenney Interface Sounds
- Status: `PINNED_VENDOR`
- Path: `assets/audio/third_party/kenney_interface_sounds/`
- Upstream: `Calinou/kenney-interface-sounds`
- Pinned commit: `4596a49eaf5a533948d49a47467f606bcdea70ff`
- Original creator: Kenney.
- License: Creative Commons Zero (CC0); personal, educational and commercial use is allowed, attribution is optional according to the bundled license.
- Contents: 100 real WAV interface sounds. The pack includes button clicks, selections, toggles, switches, confirmations, back/cancel cues, open/close cues, errors, ticks, questions, scroll sounds and minimize/maximize-style feedback.

## Button-press pool already physically available through the pinned submodule

### Direct click candidates
- `addons/kenney_interface_sounds/click_001.wav`
- `addons/kenney_interface_sounds/click_002.wav`
- `addons/kenney_interface_sounds/click_003.wav`
- `addons/kenney_interface_sounds/click_004.wav`
- `addons/kenney_interface_sounds/click_005.wav`

Recommended semantic family: `UI_BUTTON_PRESS`.
Do not bind a source filename directly in gameplay code; the main development flow should audition the five variants and choose the final primary/secondary button palette.

### Selection / hover-like feedback candidates
- `select_001.wav` through `select_008.wav`
- `tick_001.wav`, `tick_002.wav`, `tick_004.wav`

Recommended semantic families:
- `UI_HOVER`
- `UI_FOCUS_MOVE`
- `UI_LIST_STEP`
- `UI_SLIDER_STEP`

### Toggle / checkbox / switch candidates
- `toggle_001.wav` through `toggle_004.wav`
- `switch_001.wav` through `switch_007.wav`

Recommended semantic families:
- `UI_TOGGLE_ON`
- `UI_TOGGLE_OFF`
- `UI_CHECKBOX`
- `UI_SWITCH`

### Confirm / accept
- `confirmation_001.wav` through `confirmation_004.wav`

Recommended semantic families:
- `UI_CONFIRM`
- `UI_APPLY`
- `UI_SAVE_CONFIRM`
- `UI_PURCHASE_CONFIRM`

### Back / cancel
- `back_001.wav` through `back_004.wav`

Recommended semantic families:
- `UI_BACK`
- `UI_CANCEL`
- `UI_CLOSE_SECONDARY`

### Menu / panel open-close
- `open_001.wav` through `open_004.wav`
- `close_001.wav` through `close_004.wav`
- `maximize_001.wav` through `maximize_009.wav`
- `minimize_001.wav` through `minimize_009.wav`

Recommended semantic families:
- `UI_PANEL_OPEN`
- `UI_PANEL_CLOSE`
- `UI_MENU_OPEN`
- `UI_MENU_CLOSE`
- `UI_WINDOW_EXPAND`
- `UI_WINDOW_COLLAPSE`

### Error / unavailable action
- `error_001.wav` through `error_008.wav`

Recommended semantic families:
- `UI_ERROR`
- `UI_ACTION_BLOCKED`
- `UI_INVALID`

### Optional notification / prompt material
- `question_001.wav` through `question_004.wav`
- `bong_001.wav`
- `pluck_001.wav`, `pluck_002.wav`

Recommended semantic families:
- `UI_QUESTION`
- `UI_NOTIFICATION`
- `UI_NEW_ITEM`

## Button-sound design rules for later integration
- Ordinary buttons should use a short, restrained click/select sound rather than a loud confirmation cue.
- Hover/focus should be subtler than an actual press and should not spam when the pointer jitters over the same control.
- Confirm/back/error sounds must remain recognizably different so the player understands an action without staring at the UI.
- Sliders and repeated list navigation should use the lighter tick/select family rather than replaying a heavy click many times per second.
- Menu opening/closing should be separate from the click that caused it; the main flow may layer both only when it sounds natural.
- The same semantic event should keep a consistent sound family across inventory, map, crafting, settings, save/load and dialogue screens unless the UI theme intentionally changes.
- Main development owns auditioning, loudness normalization, final selection, event wiring and any variation/randomization. This asset chat only stages the legal source pool.

Recommended later semantic groups: `UI_HOVER`, `UI_CLICK`, `UI_CONFIRM`, `UI_CANCEL`, `UI_ERROR`, `UI_NOTIFICATION`, `UI_INVENTORY_MOVE`, `UI_SAVE`, `UI_LOAD`.

The main game-development flow should audition and normalize selected sounds before integration; source filenames must not become gameplay API names.
