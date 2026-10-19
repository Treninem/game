## Tree materials and frozen review — unreleased — 2026-10-20
- Restore original photographic bark from the existing CC0 tree pack, retain UVs/source materials, cache prepared surfaces and enable mipmapped anisotropic filtering. Shared foliage wind now varies phase by instance.
- Fix owned offworld-test audio teardown ordering with explicit shutdown assertions; retain strict CI errors. Five affected local scenarios, same-camera native bark comparison, native world views and two frozen-package checks pass. Linux CI confirmation and cleanup warnings remain open. Evidence: docs/DEVELOPMENT_LOG_2026-10-20_NATURE_MATERIALS.json.

## Coast and nature — unreleased follow-up — 2026-10-20
- Refine physical/rendered terrain from 8 m to 4 m spacing and share halo-derived normals at chunk edges. Add strict seam/collision regression.
- Replace a duplicate tree alias with the existing pine, retain tree positions/IDs, triple bounded grass targets, mute neon vegetation color and anchor grass wind at its roots. Startup, streaming, movement, chopping and native views pass. Existing tree art, cleanup warnings and broader performance work remain open. Evidence: docs/DEVELOPMENT_LOG_2026-10-20_COAST_NATURE.json.

## World surfaces — unreleased follow-up — 2026-10-19
- Retire the emergency start pad visual with its physics once real ground is confirmed; native before/after shows the large flat green overlay removed.
- Blend existing terrain textures at multiple scales, extend shared water/ice wave normals in world space and reduce the oversized sun disk. Startup/movement/nature/hydrology and three native views pass; sparse trees, angular banks and cleanup warnings remain. Evidence: docs/DEVELOPMENT_LOG_2026-10-19_WORLD_SURFACES.json.

## Character surfaces — unreleased follow-up — 2026-10-19
- Reuse existing authored garment normal/AO and footwear albedo, mipmapped anisotropic filtering and editor MSAA. Both bodies checked in the native editor and bounded weapon gameplay. Materials only; face/hair topology and natural combat remain unfinished. Evidence: docs/DEVELOPMENT_LOG_2026-10-19_CHARACTER_SURFACES.json.

## 0.10.7.3 — unreleased weapon grip review — 2026-10-19
- Align axe/bow handles to measured palms, close native fingers, animate the bow cord and preserve arrow size. Retain walking legs and camera pitch during attacks.
- Delay arrow release/ammo and axe impact until animation contact; cancel stale attacks and recheck short-tool reach.
- Both bodies inspected in the actual game; 60 measured poses and three frozen-package checks pass. Exit cleanup warnings remain. Evidence: docs/DEVELOPMENT_LOG_2026-10-19_WEAPON_GRIP.json. No stable release.

## 0.10.7.2 — unreleased character review — 2026-10-19
- Added actual combat equipment to editor previews, corrected behind-back bow arms and isolated generated poses per actor. Added explicit audio retirement and owned-fixture teardown for Linux Ogg shutdown diagnosis; strict gates retained. Follow-up evidence: docs/DEVELOPMENT_LOG_2026-10-19_COMBAT_PREVIEW.json.
- Replaced the temporary body with separate authored MakeHuman male/female models, textured skin/eyes/hair and fitted clothing/boots. Preserved source licenses and reproducible build/validation tools.
- New Game opens a working 3D creator with ten shape presets, bounded face/body controls, color/style selection and appearance persistence. Marta and Marek use their respective bodies.
- Fixed garment stretch, cuffs, reversed knees, backward walking lean, shoe contact and skeleton-dependent seated/jump poses.
- Repeated affected local checks, frozen-package boot and graphical forest/home interactions. Evidence and remaining warnings: docs/DEVELOPMENT_LOG_2026-10-19_CHARACTERS.json. Full armor wardrobe, advanced age/face controls and stable release gates remain open.

## 0.10.7.1 — unreleased household review — 2026-10-19
- Removed floating resident name/activity labels. Corrected seated thigh/calf axes with an actual joint-direction regression; low graphics now disables the indoor lantern shadow.
- Two named capital residents physically use their own beds and benches and store finite personal goods. Rest, ownership, contents and bounded activity progress survive JSON/disk saves and streamed recreation. Player rest ends through ordinary movement.
- Reused the existing authored animated chest and wall lantern; measured actual mattress/seat support also controls physical collision. Separate player storage supports bulk transfer, finite capacity, atomic failure and private-owner access checks.
- Combined the current main runtime with preceding local integration, preserving remote workflows and progression. Fixed pre-tree world-transform errors in siege, arena, race and plot placement. A package test exposed missing boot resources; restored the upstream complete-resource export and repeated the packaged checks.
- Nineteen unique affected local scenarios, an external packaged-game smoke and a bounded graphical household walk passed. Actual evidence, hardware samples and limitations: docs/DEVELOPMENT_LOG_2026-10-19_HOUSEHOLD.json. This is not a certified stable release.

# Changelog

## Unreleased workspace — 2026-10-19 — persistent streamed residents
- Residents with stable IDs retain validated local transforms, parent anchors, doorway transit, route index and bounded activity/reaction timers. Save snapshots capture live state at the actual boundary; unloading records the last grounded position. No Node references or transient doorway owners enter save data.
- Loading restores existing residents and physical door openings, then revalidates floor collision before showing the human. State revisions prevent teardown of an old scene from repopulating a clean new game. Legacy phase-only records and malformed/nonfinite coordinates have bounded fallbacks.
- Added a regression that reproduced five failures before the fix and now passes real-slot/JSON/streaming/reset/corrupt-state checks. The live square test also rebuilds during doorway transit and requires completion of both home and work routes. Nine unique affected scenarios passed.
- Official graphical inspection walked 1368.68 m through ordinary movement Input, confirmed the original square nodes were freed beyond the actual unload radius, returned to both residents still indoors, entered through a real ray interaction and saved/loaded slot 3. Only the inspection fixture holds clock/survival at 22:00; this is not a manual full-world or performance certification.
- Prepared a seven-file runtime/test patch relative to the preceding home-life integration working tree and validated it without modifying the index. No commit or stable release was created. Evidence: docs/DEVELOPMENT_LOG_2026-10-19_CITIZEN_STATE.json. Continuous distant simulation, household actions and the remaining master-specification systems are unfinished.

## Unreleased workspace — 2026-10-19 — square home and local NPC context
- Replaced one sealed square house with the existing physical room/door and authored furniture. Residents return inside at night and leave for work; doorway ownership fixes the observed deadlock. Player-opened doors are no longer immediately closed by an unrelated work routine.
- Native review exposed coplanar paving/floor flicker, blank FBX furniture slots and open roof ends. Added a small physical threshold, reused wood/cloth materials and shared roof gables, then repeated affected movement/room/furniture checks.
- Shop hours and finite merchant money now govern real trades. Failed purchases/sales preserve goods; supply history and visible nearby successful spells inform saved contextual dialogue. Dangerous magic temporarily interrupts activity. No external LLM or full social simulation is claimed.
- Thirteen unique affected local scenarios passed, plus a full graphical home/life fixture and a 135.32 m native walk from the previously earned arrival save, with actual ray interactions, purchases, weapon equip/unequip and shield. A final sentence-only wording edit received a separate exported-package saved-dialogue check. Strict error detection remains enabled; short tests now allow proper asynchronous audio teardown.
- An immediate post-load dialogue could freeze the opaque reveal overlay. Its tween now continues during pause; the final saved-dialogue probe asserts a nonblack real frame and functioning close, and boot_world passed again.
- Evidence, snapshots and limitations: docs/DEVELOPMENT_LOG_2026-10-19_HOME_LIFE.json. Most houses, household activities, persistent citizen positions, full performance and stable release certification remain unfinished.

## Unreleased workspace — 2026-10-19 — bounded merchant dialogue
- Native review found seven merchant choices expanding a bottom-anchored panel beyond both 1280×720 and 800×450 viewports. Replaced the unbounded layout with a viewport-fitted panel, scrolling body and keyboard-focus following; removing old choice rows immediately also prevents transient doubled layout size during trade refreshes.
- Real purchase, supply-sale and close choices remain available; the actual close button resumes gameplay. Added a failing-before/passing-after merchant regression, graphical captures and exported-package checks. Responsive UI and affected gameplay scenarios bring acceptance to nineteen unique local cases.
- The final frozen PCK completed a fresh 16911.59 m input-driven forest-to-capital route after this UI change: all sixteen waypoints, no driver position assignments, arrival saved. Nineteen local scenarios passed. Final evidence and limitations: docs/DEVELOPMENT_LOG_2026-10-19_CAPITAL_SQUARE_UI.json. This is an unreleased review, not a certified stable release.

## Unreleased workspace — 2026-10-19 — working capital square
- Selected existing CC0 authored benches, lanterns, workbench and produce barrels for the central square, with measured grounding, collision and 47 cm bench seats. Reused existing market stalls; main crossings remain clear.
- Added an existing photographic stone texture with world-space scale and mipmaps. Corrected paving height and removed duplicate world dirt overlays inside the capital; bridge and roadbed physics remain unchanged.
- Added bounded readable night fill and warm evening stall lights; reduced daytime overexposure after native visual review.
- Linked two citizens to actual workplaces, meal/social spots and home approaches. Players can sell wood and stone; the artisan uses the existing arrow recipe over eight seconds to replenish finite shop stock. Progress/stock survive streaming, and missing materials produce a waiting state rather than fake work.
- Map records actual street furniture footprints beneath living markers. Paved walking no longer produces dirt prints or stone fragments; actual tool-impact effects remain.
- Fixed composed VFX expiry callbacks with weak references after native walking exposed already-freed child objects. Added ownership/natural-expiry regression coverage.
- Seventeen unique local scenarios and graphical square/gameplay-action checks passed. Frozen-package traversal and export evidence are recorded in the acceptance journal. This remains an unreleased review; ordinary capital homes lack full interiors and realistic character/forest materials are unfinished.

## Unreleased workspace — 2026-10-19 — anatomical human and living-world refresh
- Replaced the previous citizen geometry with an existing CC0 B89 anatomical human fitted to the existing Quaternius rig; retained ten animations and skin/clothing variants. Connected-arm transfer and smoothed joint weights prevent previously observed bow/hand stretching. Exact grip and realistic surface materials remain unfinished.
- Selected an additional existing B44 authored broadleaf tree with its original branch texture for the start forest, reusing shared foliage wind/cutout.
- Added the existing B47 authored chimney and wider roof eaves to ordinary capital roofs. Homes still have solid collision shells and do not yet provide full interiors.
- Civilian legacy patrols now enter day/night work, meal, social and home routines; watchmen retain their patrols. Obstacle steering and a street-side work target prevent tested workplace blockage.
- Local-map features now include actual rock batches and persistent felled stumps, preserving existing terrain, water, roads, houses and live markers.
- Fourteen local gameplay/physics/UI scenarios and fifty sampled animation poses passed; four affected scenarios repeated after bow/gait fixes. Native forest/capital inspection, graphical gameplay actions and an external packaged-game smoke passed. A fresh continuous 16.91 km input-driven autopilot route reached the capital square without driver position assignments. Headless fixed 1/60-second simulation can run faster than wall time; normal movement parameters/time scale remain. Evidence: `docs/DEVELOPMENT_LOG_2026-10-19_WORLD_REFRESH.json`. No stable release is certified here.

## Unreleased workspace — 2026-10-19 — tree contact refinement
- Tree-impact particles and spatial sound now originate at the ray-confirmed bark surface after a valid axe stroke. Cancelled strokes do not emit wood-hit audio; three existing CC0 samples provide variation.
- Short sound emitters retire safely after playback; fallback cleanup uses weak references.
- Corrected source/target shoulder orientation during chopping-animation retargeting.
- Standing-tree map footprints disappear after felling even when the cell is unloaded or restored from a saved feature dictionary. Ordinary stone/plant melee surface effects are preserved.

## Unreleased workspace — 2026-10-19 — axe harvesting
- Standing resource trees and ordinary start-forest trees require an equipped axe and three reachable strokes; contact is delayed and rechecks equipment, distance and obstacles.
- Reused the physically staged CC0 TreeChopping_Loop on the existing human skeleton as Axe_Chop, replacing the generic gesture for axe swings.
- Undamaged forest trees retain shared draw batches. Only a struck tree becomes independently animated; neighbouring instances remain unchanged.
- Controlled tree falls leave authored Kenney stump/log models. E collects nearby fallen wood once; partial cuts, felling and collected loot persist through streaming and saves, including saves during a fall.
- Traders now sell finite axe stock, including migration of older saved shops. Existing berries, stone, combat and camera checks remain required.
- This is a private working-tree review. Falling crowns do not use destructive rigid-body physics; distant batched forests outside the start region are not fully harvestable.

## Unreleased workspace — 2026-10-19 — camera stabilization
- Integrated a sphere-tested third-person camera with immediate wall clearance and smooth distance recovery, including initially overlapping geometry.
- Added persistent 2–9 m zoom using the mouse wheel and the gameplay settings slider; zoom does not reapply display settings.
- Windows-compatible pointing now handles absolute cursor events even when both relative-motion fields are empty.
- Returning from a menu discards buffered pointer motion during recapture, preventing the observed yaw/pitch snap while retaining subsequent camera control.
- Interaction rays follow camera distance, while actual reach remains measured from the hero. Melee and interaction reject targets behind the hero and obstacles between hero and target.
- Added physical obstruction/reach regression coverage and extended graphical input checks for wheel zoom, paused menus and absolute pointing. Results and unresolved issues are recorded with each private review package.
- Added the factual system inventory in `docs/DEVELOPMENT_STATUS.json`; unimplemented guild, wildlife, terrain editing and social-memory systems are explicitly separated from integrated functionality. This workspace entry is not a stable release.

## 0.10.2-stable — 2026-08-14
- Added `updater_v4.ps1`: normal updates for an installed game now use retained content-aware delta chains only and no longer fall back to downloading the full game archive.
- Full `ImPuls-PC-Windows-x64.zip` is reserved for first installation/manual recovery; ordinary updates download only the missing delta payload plus small manifests/runtime metadata.
- Added visible aggregate update progress with transferred bytes, total planned network traffic, delta stage, verification stage and final result.
- Kept SHA-256 verification, full final-manifest validation, rollback and offline-safe startup before replacing the installed build.
- Scheduled background updates now prefer the v4 delta updater while retaining the legacy updater only as a compatibility fallback.
- Added PowerShell syntax validation for updater/runtime scripts to the stable Windows build pipeline.
- Activated a centralized `UILayoutGuard` for pause and gameplay panels.
- Menu geometry now reflows after window size, fullscreen and UI-scale changes, compacts sidebar/tabs when needed and re-centers frames in the actual viewport.
- Expanded UI smoke coverage to the maximum supported 150% UI scale and verifies both pause and gameplay panels plus sidebar fit.
- Continued the streamed Люменград foundation with differentiated street hierarchy, district density/identity and streamed protected landmarks while preserving the one-city-cell-per-frame loading budget.

## 0.10.1-stable — 2026-08-14
- Introduced a rolling `stable` GitHub Release channel controlled only by the main integration chat; ordinary asset/research commits can no longer become player updates.
- Pinned both the in-game updater and external PowerShell updater to the stable channel instead of `releases/latest`.
- Made SHA-256 metadata mandatory for game and updater-runtime downloads; invalid or missing checksums abort the update and preserve the installed build.
- Replaced stale/fallback branding generation: the selected ImPuls artwork in `assets/branding/impuls_icon.png` is now the single source for the game window, Windows EXE, installer and refreshed shortcuts.
- Removed the duplicate standalone MagicHUD overlay from autoload so the normal gameplay HUD is the only persistent HUD layer.
- Added a real WorldEnvironment with procedural sky and ambient sky lighting so the world cannot boot as a flat gray/black scene.
- Increased the active third-person camera far plane to 1100 m and strengthened the main sun for readable traversal.
- Added stable-world boot smoke validation: mandatory player/camera/environment/HUD nodes, camera visibility distance and hidden blocking menus at gameplay start.
- Added UI/save smoke validation: pause menu and gameplay panels must fit the viewport, pause/unpause correctly, restore gameplay and preserve exactly 10 save slots.
- Existing movement smoke remains mandatory so a build where the character walks in place cannot enter the stable release.

## 0.10.0-stage10 — 2026-08-14
- Reordered development to world-first: terrain, capital, forests, fields, water, roads and regions now take priority over quests and player construction.
- Replaced 512 m streaming tiles with lighter 192 m local chunks and a roughly 960 m visible streaming window around the player.
- Limited collision generation to the nearby 3×3 chunk area; distant visible chunks are render-only.
- Limited chunk creation to one visual chunk per frame and prioritized local collision generation to reduce traversal stalls.
- Reduced procedural vegetation/resource density and added visibility ranges to keep the streamed world smooth.
- Reserved a stable roughly 4 km capital footprint before future district authoring.
- Removed the prototype shelter/"doghouse" from the active scene and migrated old saves so it cannot return.
- Suspended the temporary Mira and South Gate quest chains until real locations are complete.
- Deferred permanent building recipes and build controls until land/building rules are implemented against the completed world.
- Added player terrain recovery so movement cannot fall through a chunk while local collision catches up.
- Simplified pause UI and kept inventory/map/crafting/journal as direct in-game panels.
- Removed the temporary quest card from the HUD; minimap remains permanently visible.
- Increased save schema to v5 while preserving useful inventory, exploration and world-state data.
- Fixed branding generation to use only the canonical selected ImPuls icon source instead of stale chunk fragments.
- Added the project-owned procedural VFX Core Pack with reusable magic, combat, explosion and collision presets.
- Added arcane, fire, frost, lightning, poison, heal, holy, dark, portal and shield magic VFX presets.
- Added small/medium/large explosions plus metal, stone, wood, dirt, glass and water collision effects.
- Connected melee swing/hit, enemy attack and enemy defeat feedback to the active combat scripts.

## 0.9.0-stage9 — 2026-08-14
- Added a permanent in-game minimap with explored terrain, discovered POIs and a directional player marker.
- Split inventory, full map, crafting and quest journal away from the pause menu into direct gameplay panels opened with I/M/K/J.
- Simplified Esc pause menu to Continue, Saves, Settings, Updates and Exit.
- Kept 10 independent save slots with create/overwrite/load/delete operations.
- Simplified HUD by removing resource/combat debug text and keeping compact quest, vitals, minimap, location/time/economy and quick-use controls.
- Added third quick-use slot on key 3 for cooked/raw meat.
- Switched Windows branding generation to the user-selected ImPuls artwork; build pipeline generates the application PNG and multi-size ICO from that source.
- Installer/updater shortcut branding remains refreshable during automatic updates.

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
