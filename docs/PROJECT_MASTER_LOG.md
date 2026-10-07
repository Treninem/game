# ImPuls Project Master Log

This is the **only development and coordination journal** for `Treninem/game`.

Repository state, current CI and reproducible logs override stale chat prose. Every coding chat, Work session, Codex session, automation or other executor must read this file before changing live runtime, release or integration files.

## Current release train

- Canonical repository: `Treninem/game`
- Canonical branch: `main`
- Baseline HEAD at start of stabilization: `c7cbd13a5b9541552ffeb85694f7dd4fcef3e5fe`
- Engine: Godot 4.7.1 Stable / GL Compatibility
- Current product version in `project.godot`: `0.10.7-stable`
- Public rolling release: `stable` / build-649
- Current phase: **STABILIZATION FREEZE — playable baseline before new content**
- New world expansion, story expansion, item families, NPC families and new gameplay systems are deferred until the current baseline passes the acceptance gates below.

PROGRESS_COMPLETE: 75%
PROGRESS_REMAINING: 25%

DONE:
- Current repository already contains the core RPG/runtime, world streaming, saves, settings, UI, combat, magic, map, quests, dungeons/realms, installer/updater and extensive smoke coverage.
- Grey-void/falling startup class was fixed and merged in `c7cbd13a5b9541552ffeb85694f7dd4fcef3e5fe`.
- PR #8 `Validate World Core` passed with the strengthened boot → menu → loading → visible world → grounded player smoke.
- Main `Validate Player Movement` passed after the grey-void fix.
- STAB-002 runtime P0/P1 audit is merged as `20f1298523c0cdbc21f1772e568682e940edb190`; all seven required PR #10 checks passed on exact head `2f2a8be7786c007a96fd3bfcbd52065aec93a1ed`.
- Large verified CC0 libraries are physically present in the repository; they must be reused before drawing/downloading duplicates.

REMAINING:
- Produce and verify the next stable candidate from one exact accepted `main` SHA.
- Perform installed-package playability acceptance, including boot/menu/world handoff and core controls, before publishing the next rolling `stable`.
- Re-check updater/repair against the candidate artifact lineage and preserve user data.
- Only after the stable candidate is accepted, continue bounded asset integration from existing `STAGED_PHYSICAL` libraries.

BLOCKERS:
- Installed-package playability is still unproven for the next candidate, so rolling `stable` must not move yet.

NEXT:
- STAB-003: make the comprehensive Windows workflow candidate-only by default and require explicit publication opt-in.
- Run the candidate build, verify the produced Windows package/installer, then perform installed-package playability acceptance before any rolling `stable` publication or asset-family expansion.

## Stabilization acceptance gates

The current baseline is not considered stable until all items below are proven on the same candidate lineage:

1. Boot launcher opens the main menu without blocking.
2. New game and load game always pass through the loading gate.
3. World is not revealed until renderable terrain, sky/environment, camera and physical ground are ready.
4. Player remains grounded after handoff and can walk, sprint, jump and interact.
5. Save/load/slot recovery works without moving the player into invalid world coordinates.
6. HUD, pause, settings, inventory, map, journal and crafting remain usable and inside the viewport.
7. Current combat/magic/quest/dungeon/realm/minigame systems do not produce parse/runtime P0/P1 failures.
8. Current world streaming stays bounded; no known runaway node, collision, asset or memory growth.
9. Windows export succeeds.
10. Installer succeeds and installed game starts.
11. Updater/repair path preserves installed data and can recover missing core files.
12. Mandatory GitHub gates are green without weakened/skipped assertions.
13. Version metadata is synchronized.
14. Final candidate receives an installed-package playability check before the rolling stable release is updated.

A green parse alone is never sufficient.

## Active work and claimed files

| Claim | Owner | Status | Scope / files | Intended result |
|---|---|---|---|---|
| STAB-001 | main integration chat | DONE | `AGENTS.md`, `README.md`, `VERSION`, `docs/PROJECT_MASTER_LOG.md`, `docs/IMPULS_ENGINEERING_MEMORY.md`, `tools/check_version_sync.py`, `.github/workflows/validate-world-core.yml`, `.github/workflows/windows-build.yml`, `.github/workflows/build-windows-installer.yml`, `.github/workflows/diagnose-ui-smoke.yml`, `.github/workflows/release-gate-status.yml`, `tests/test_world_loading_readiness.gd`, `tests/test_world_loading_readiness.tscn`, `installer/ImPuls.iss` | Establish Fox-style coordination rules, engineering memory, stabilization freeze, remove metadata drift, enforce version sync, make the fast installer artifact-only, and repair broken diagnostic/release-status CI. No public version bump. |

| STAB-002 | main integration chat | DONE | `.github/workflows/validate-magic.yml`, `.github/workflows/validate-world-vfx.yml`, `.github/workflows/validate-updater.yml`, `.github/workflows/validate-movement.yml`, `.github/workflows/windows-build.yml`, `export_presets.cfg`, `tools/check_version_sync.py`, `tools/verify_delta_roundtrip.py`, `installer/updater_v4.ps1`, `installer/repair_sync.ps1`, `project.godot`, `scripts/{world_streamer,player_controller,runtime_stability_guard,save_manager,progression_system,dungeon_runtime,realm_runtime,minigame_runtime,combat_state_controller,vip_flight_controller,capital_night_siege,game_state}.gd`, and new/changed stabilization smokes under `tests/**` | Prove magic/VFX/updater and repair confirmed P0/P1 runtime defects found during the mandatory audit: corrupted version gate, unsafe repair while game is running, offworld mainland streaming, realm/dungeon fall recovery, save/load runtime resync, minigame pause/cancel exploit, per-frame deep-copy hot paths and broken multi-day event/siege identity. No new gameplay/content or public stable publication. |
| STAB-003 | main integration chat | ACTIVE | `.github/workflows/windows-build.yml`, `docs/PROJECT_MASTER_LOG.md`, `docs/IMPULS_ENGINEERING_MEMORY.md` | Separate candidate build from rolling stable publication so a Windows package/installer can be built and accepted first; publication must require an explicit opt-in after installed-package playability evidence. |

Before modifying a claimed file/subsystem, another executor must integrate fresh `main` and explicitly reconcile/take over the claim here.

## Asset integration state

### Already physically available

The repository already contains verified staged libraries for, among other things:

- animated humans and 50+ character variants;
- universal humanoid animations;
- wolves, eagles, dogs, cats, fish and other fauna;
- crops, food, survival objects, RPG items and medieval weapons;
- medieval village/building/dungeon/castle/graveyard/fantasy-town packs;
- furniture, house interiors, markets and city/industrial packs;
- vehicles and transport;
- large UI/icon/font/material libraries;
- magic/combat/electric/beam VFX, spell icons and magic audio;
- nature/environment assets and shader/material systems.

The canonical lists are `assets/ASSET_PACKS.md` and `assets/staging/PHYSICAL_STAGING_INDEX.md`.

### Current integration rule

Do **not** mass-wire every staged pack into runtime. That creates style inconsistency, import cost, memory spikes and unstable collisions.

For the stabilization phase:
1. keep existing working production integrations;
2. replace obvious placeholders only with already-staged coherent assets;
3. integrate one bounded asset family at a time;
4. normalize scale/material/collision/LOD/animation;
5. add smoke/performance evidence;
6. only then mark the asset `INTEGRATED`.

Preferred first passes after P0/P1 stability:
- player/NPC visual baseline + shared animation set;
- coherent nearby wildlife/farm animals;
- coherent medieval settlement/farm props;
- current item/food/weapon visuals;
- VFX/audio bindings already needed by implemented mechanics;
- UI/icon polish using staged UI assets.

Large new biomes, cities, story arcs, content volume and new mechanics remain deferred.

## Stable branch / old branch decision

Historical asset/audio branches that are already ancestors of `main` must not be merged again.

At stabilization start:
- `asset-pass-2026-08-14` and the listed audio branches were fully behind `main`;
- `assets/cc0-packs` only retained two obsolete documentation commits against a much older base;
- `release/stable-0.10.8` retained one obsolete release commit and was far behind current `main`.

Do not merge these branches wholesale. Recover an individual change only if a current audit proves it is still missing and useful.

## Severity model

- **P0** — game cannot start/play, data loss, infinite fall/void, save corruption, release/install failure, catastrophic crash/freeze.
- **P1** — major implemented feature unusable, severe visual/runtime break, repeated multi-second stall, major control/UI failure.
- **P2** — contained defect with workaround, incorrect polish/content, non-critical visual issue.
- **P3** — polish/backlog.

No new feature/content expansion while a known P0 is open. New expansion should normally wait until owned P1 defects are resolved or explicitly isolated.

## Change protocol

For each batch:
1. read fresh `main`, this log and `docs/IMPULS_ENGINEERING_MEMORY.md`;
2. claim exact files/subsystem here;
3. implement a coherent bounded batch;
4. run the relevant tests;
5. record commit/PR/run evidence;
6. update engineering memory for reusable failures/fixes;
7. mark the claim DONE and release the files;
8. state the exact next executable step.

Do not create another progress/development/coordination journal.

## Evidence log

### 2026-10-07 — grey-void startup stabilization
- Starting main: `7024262962f7a8023d765a987dd9b5a8aa211841`.
- PR: #8 `Fix grey-void startup and verify visual world handoff`.
- Merge commit: `c7cbd13a5b9541552ffeb85694f7dd4fcef3e5fe`.
- Fix: loading readiness now requires renderable center terrain and materialized sky/environment; start surface has a visible emergency fallback; boot smoke verifies active camera, visible terrain/environment and stable Y after handoff.
- PR `Validate World Core`: success, run `37543723961`.
- Main `Validate Player Movement`: success, run `37543968394`.
- Stable release was intentionally not published from the fix commit.

### 2026-10-07 — STAB-002 runtime P0/P1 audit (DONE; merged)
- PR #10: `Stabilize magic, updater and runtime release gates`.
- MagicHUD runtime smoke, World VFX wiring gate, delta updater roundtrip and PR execution of the mandatory movement/updater checks were added before the wider audit.
- Confirmed/fixed version-gate corruption: `tools/check_version_sync.py` had an unterminated regex/program fragment and blocked World Core + Windows Installer before any real build step.
- Updater/repair safety: resumable `.part` + HTTP Range + persistent cache retained; repair now refuses to replace files while ImPuls is still running.
- Offworld streaming: mainland `WorldStreamer` is suspended and cleared in dungeon/realm, then rebuilt on mainland return; a dedicated smoke covers suspension/resume.
- Player instanced-world recovery: the previously referenced but missing dungeon-mode contract is implemented; realm/dungeon falls no longer recover against mainland height data while mainland streaming is disabled.
- Save/load resync: `SaveManager.game_loaded` now resynchronizes player, realm and dungeon runtimes after in-session loads.
- Minigame stability: intentional rune-puzzle pause is respected; combat/realm transition conflicts are blocked; cancellation/death no longer grants a reward.
- Performance: per-frame deep copies of progression state were removed from WorldStreamer, DungeonRuntime, CombatStateController and VIP flight hot paths.
- World calendar: `world_day` is persisted separately from minute-of-day, fixing daily event rotation and later-day capital siege identity.
- Added/expanded smoke coverage for offworld transitions, save resync, cancel-reward protection, rune pause stability and multi-day event rotation.
- Exact accepted PR head: `2f2a8be7786c007a96fd3bfcbd52065aec93a1ed`.
- `Validate Delta Updater`: run `37608635758` — PASS.
- `Diagnose UI Smoke`: run `37608635663` — PASS.
- `Validate Player Movement`: run `37608635765` — PASS.
- `Validate World Core`: run `37608635739` — PASS.
- `Validate World VFX`: run `37608635632` — PASS.
- `Build Windows Installer`: run `37608635737` — PASS.
- `Validate Magic Runtime`: run `37608635839` — PASS.
- PR #10 merged to `main` as `20f1298523c0cdbc21f1772e568682e940edb190`.

### 2026-10-07 — STAB-001 governance/release-infrastructure stabilization
- PR #9: `Stabilize project governance and version metadata`.
- Added the single master development journal, engineering memory and mandatory claim protocol.
- Stabilization freeze recorded: existing playable baseline first; world/story/item/NPC expansion deferred until P0/P1 and release gates are clean.
- `VERSION`, `project.godot`, `bootstrap.gd` and installer metadata aligned to the accepted `0.10.7-stable` runtime lineage; CI now rejects drift.
- Fast `Build Windows Installer` is artifact-only and can no longer move/publish `stable`.
- Fixed UI diagnostic project context/readiness test and release-gate recorder dirty-rebase failure.
- PR #9 `Diagnose UI Smoke`: run `37545493981` — PASS.
- PR #9 `Validate World Core`: run `37545493943` — PASS.
- PR #9 `Build Windows Installer`: run `37545494001` — PASS (Windows export + installer + SHA-256 + artifact).
- Historical PR #7 (`0.10.8`) closed unmerged as stale; no old asset/release branch was wholesale-merged.
- No public rolling stable release was published by STAB-001.

## Required owner-facing status format

Substantial coordinator updates should include an evidence-backed readiness percentage. A response claiming full stability must not use 100% until the acceptance gates above are satisfied.

Coordinator footer:
`ОБЩАЯ ГОТОВНОСТЬ IMPULS: XX%`
