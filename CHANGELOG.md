# Changelog

## 0.8.0-stage8 — 2026-08-14
- Expanded the target playable world to a 64 × 64 km first continent.
- Added deterministic terrain streaming in 512 m chunks around the player instead of loading the whole continent at once.
- Added layered procedural elevation with a flattened capital area, hills and mountain ridges.
- Added continent edges that descend into sea level and streamed water surfaces where terrain falls below the sea.
- Added biome classification for plains, forests, taiga, tundra, drylands, marshes, mountains and ocean.
- Added biome-specific procedural vegetation and boulder MultiMeshes to keep the large world lightweight.
- Added major distant world landmarks distributed across the continent.
- Scaled fog-of-war exploration from the prototype map to the full continent using persistent 256 m exploration cells.
- Added continent map rendering with explored biome colors, major POIs, player marker and explored area in km².
- Added a local 2.4 km map inset so the capital and nearby POIs remain readable even on the huge continent map.
- Kept Люменград as the detailed starter district inside the streamed world.

## 0.7.0-stage7 — 2026-08-14
- Rebuilt the pause/navigation menu into a game-style sidebar layout.
- Saves, settings, map, inventory, crafting, journal and updates are now always visible from the pause menu.
- Added direct gameplay hotkeys: M map, I inventory, J journal, K crafting.
- Added a persistent exploration map with fog of war: visited cells are revealed and unexplored territory remains hidden.
- Exploration progress is stored inside save data through world state and persists across reloads.
- Added discovered POI markers for city gates, plaza, market, forge, tavern, guardhouse, Mira and danger areas.
- Added player position marker and explored-percentage display on the map.
- Kept the 10-slot save system, control rebinding, graphics, audio, gameplay settings and in-game update controls in the new menu.

## 0.6.0-stage6 — 2026-08-14
- Added the first playable city district: Люменград South Quarter.
- Added southern wall and gate, gate towers, main road, plaza, market stalls, forge, tavern, guardhouse, houses, fountain, lamps, trees and city decor.
- Added modular procedural humanoid visuals for the player and NPCs instead of primitive capsule/box placeholders.
- Added procedural walking animation for arms, legs and body movement.
- Added scheduled city NPCs with work/evening/home positions.
- Added blacksmith, merchant, guard, innkeeper, artisan and citizen roles with distinct dialogue.
- Added the first city quest from blacksmith Radan.
- Added city coins and Люменград reputation progression.
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
