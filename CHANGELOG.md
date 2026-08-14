# Changelog

## 0.6.0-stage6 — 2026-08-14
- Added the first playable city district: Lюмengrad South Quarter.
- Added southern wall and gate, gate towers, main road, plaza, market stalls, forge, tavern, guardhouse, houses, fountain, lamps, trees and city decor.
- Added modular procedural humanoid visuals for the player and NPCs instead of primitive capsule/box placeholders.
- Added procedural walking animation for arms, legs and body movement.
- Added scheduled city NPCs with work/evening/home positions.
- Added blacksmith, merchant, guard, innkeeper, artisan and citizen roles with distinct dialogue.
- Added the first city quest from blacksmith Radan.
- Added city coins and Lюмengrad reputation progression.
- Added dynamic location tracking between the outskirts and South Quarter.
- Added location, coins and city reputation to the HUD.
- Moved hostile raiders and ruins outside the protected starter city area.

## 0.5.1-stage5 — 2026-08-14
- Updater runtime now includes branding refresh support.
- Game updates can replace the ImPuls icon without reinstalling the full application.
- Desktop and Start Menu shortcuts are recreated after branding updates.
- Windows shell icon refresh is triggered after an icon update.

## 0.5.0-stage5 — 2026-08-14
- Added inventory and equipment UI.
- Added item metadata and equippable weapon support.
- Added crafting UI and expanded recipes.
- Added dialogue UI with selectable answers.
- Added quest journal UI.
- Added first equipment-driven combat bonus.

## 0.4.1-stage4 — 2026-08-14
- Reworked the prototype HUD into compact game-style cards and status bars.
- Added the ImPuls icon to the Godot application window, Windows executable and boot splash.
- Added polished main menu styling.
- Added 10 independent save slots with create, overwrite, load and delete operations.
- Added graphics, audio, controls and gameplay settings.
- Added in-game update check and update/restart flow.

## 0.1.0-stage1 — 2026-08-14
- Fixed the Stage 0 project wiring and added a runnable Stage 1 scene.
- Added third-person movement, mouse camera, jump, sprint and interaction ray.
- Added wood and stone harvesting with persistent inventory state.
- Added first NPC quest chain with Mira.
- Added basic crafting and starter shelter construction.
- Added health, hunger, thirst and accelerated world time.
- Added versioned local saves, autosave and manual F5/F9 save/load.
- Added a real Windows installer pipeline with an original ImPuls icon.
- Installer creates Desktop and Start Menu shortcuts and registers uninstall support.
- Added hourly background update checks from GitHub Releases with SHA-256 verification and rollback.
- GitHub Actions builds the Windows game, builds ImPuls-Setup.exe and publishes release assets.

## 0.0.1-stage0 — 2026-08-14
- Started standalone ImPuls PC project.
- Added Godot project configuration.
- Added bootstrap 3D scene and offline runtime.
- Added empty legal asset registry.
- Established offline-first/no-paid-API project rules.
