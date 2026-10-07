# ImPuls Engineering Memory

Durable technical memory for confirmed failures, root causes, fixes, rejected workarounds and prevention rules.

This is **not** the project progress journal. Current status, active claims, commits, CI and NEXT belong only in `docs/PROJECT_MASTER_LOG.md`.

## Protocol

Before proposing a workaround or changing a subsystem:
- search this file by subsystem, exact symptom and error text;
- prefer current repository state and reproducible CI over stale prose;
- record newly confirmed reusable lessons before closing the owning claim;
- keep failed approaches when they are useful to avoid repetition;
- never record a skipped/waived test as PASS;
- never store secrets or credentials.

Use statuses: `OPEN`, `RESOLVED`, `SUPERSEDED`, `UNCONFIRMED`.

---

## IMP-2026-10-07-001 — Grey/empty world and falling sensation after entering gameplay

**Status:** RESOLVED in code; installed-package acceptance still required before next stable release.

**Symptom**
- After entering the game, the user observed a grey/empty space and the sensation that the player was falling.

**Affected area**
- Boot/menu → world-loading → gameplay handoff.
- Streamed terrain visual readiness.
- Player spawn safety.

**Confirmed repository state before fix**
- Player controller already had a streamed-surface ground guard.
- `StoryStartSurface` already provided physical collision.
- `RuntimeStabilityGuard` could create an emergency physical floor.
- Existing boot smoke proved collision/ground presence but did not prove that the rendered terrain and sky were actually usable.

**Root cause class**
- The loading-readiness contract accepted the presence of a center `Terrain` node and physics, but did not require renderable terrain geometry/material or a materialized sky/environment.
- The startup safety surface was collision-only, so a false-positive readiness state could still leave a player physically supported while visually seeing an empty/grey world.
- This explains why physics-oriented smoke tests could pass while a real user still perceived a void.

**Fix**
- Merge commit: `c7cbd13a5b9541552ffeb85694f7dd4fcef3e5fe`.
- `world_loading_readiness.gd` now requires:
  - center terrain visible in tree;
  - non-null mesh with renderable surfaces and useful bounds;
  - render material;
  - materialized `WorldEnvironment` with sky.
- `start_spawn_surface.gd` includes a small visible fallback just below normal terrain.
- `smoke_boot_world.gd` verifies:
  - center renderable terrain;
  - sky/environment;
  - active viewport camera;
  - stable player Y/velocity for physics frames after handoff.

**Evidence**
- PR #8 `Validate World Core`: run `37543723961` — PASS.
- Main `Validate Player Movement`: run `37543968394` — PASS.

**Prevention**
- Never define world readiness only by node existence or collision.
- Boot acceptance must validate both **visual** and **physical** readiness.
- Do not weaken the boot smoke to bypass import/render problems.
- Any future streaming rewrite must preserve the post-handoff grounded-player assertion.

---

## IMP-2026-10-07-002 — Version and documentation drift

**Status:** OPEN at stabilization-claim creation; fix included in STAB-001.

**Symptom**
- `VERSION` reports `0.10.4-stable`.
- `project.godot` reports `0.10.7-stable`.
- README names `scenes/main_menu.tscn` as the main launch scene while `project.godot` actually launches `scenes/boot_launcher.tscn`.

**Risk**
- Installer/updater/release metadata can disagree with the runtime.
- A developer may test or document the wrong startup path.
- Release troubleshooting becomes ambiguous.

**Fix rule**
- Do not invent a new public version merely to resolve drift.
- During stabilization, align stale metadata to the currently accepted runtime version.
- A future release bump occurs only after candidate acceptance, then all version-bearing files must be synchronized and re-tested.

**Prevention**
- Add version-sync validation before publishing the next stable release.
- Repository truth overrides stale README/comment text.

---

## IMP-2026-10-07-003 — Historical asset branches are not an integration queue

**Status:** RESOLVED as a coordination rule.

**Symptom/risk**
- Repository contains old asset/audio branches and a stale release branch, which can create the impression that all must be merged to recover content.

**Audit result**
- `asset-pass-2026-08-14` and the historical audio branches were already fully behind current `main`.
- `assets/cc0-packs` retained only two old documentation commits against a very old base.
- `release/stable-0.10.8` retained one old release commit and was far behind current `main`.

**Rule**
- Do not merge historical branches wholesale.
- Staged physical assets already present on `main` are the source pool.
- Integration means selecting, normalizing, testing and wiring those assets into runtime, not merging an old source branch.

**Prevention**
- Check `assets/ASSET_PACKS.md` and `assets/staging/PHYSICAL_STAGING_INDEX.md` first.
- Compare a branch against current `main` before any merge.


---

## IMP-2026-10-07-004 — UI diagnostic false-red from incomplete project context

**Status:** RESOLVED.

**Symptom**
- `Diagnose UI Smoke` failed before reaching the real UI/boot smoke.
- Errors included missing `WorldData`, missing environment shader files and a timeout in the numeric readiness guard test.

**Root cause**
- The workflow launched `tests/test_world_loading_readiness.gd` as a raw `--script` while that script preloaded runtime code that expects normal project autoload context.
- Sparse checkout omitted required shader/runtime dependencies.

**Fix**
- Convert the numeric readiness guard into a normal Godot test scene.
- Run it with `--path . tests/test_world_loading_readiness.tscn`.
- Include the required shader/audio/production project context in the diagnostic checkout.

**Evidence**
- PR #9 `Diagnose UI Smoke` run `37545493981` — PASS.
- Numeric readiness guards, bounded UI smoke and end-to-end boot/world smoke all passed.

**Prevention**
- Runtime scripts that depend on project autoloads must be tested inside a real project scene unless the test intentionally supplies all dependencies.
- Sparse checkout must include every resource reachable by autoload/preload for the tested path.

---

## IMP-2026-10-07-005 — Stable gate recorder dirty-rebase failure

**Status:** RESOLVED in PR #9.

**Symptom**
- `Record Stable Release Gate Status` failed in the commit step even after mandatory workflow conclusions were collected successfully.

**Root cause**
- The workflow staged `release/verified.json` and then executed `git pull --rebase origin main`.
- Git refuses rebase when the index contains staged changes.

**Fix**
- Preserve the generated verification payload outside the working tree.
- Refresh/reset from current `origin/main` first.
- Reapply the payload, commit and push.
- Retry non-destructively if main moves concurrently.

**Prevention**
- Never rebase/pull a CI checkout after staging generated state.
- For generated coordination files, refresh base first, then regenerate/reapply and commit.

---

## IMP-2026-10-07-006 — Fast Windows installer could publish stable and also failed to build

**Status:** RESOLVED in PR #9.

**Symptom**
- `Build Windows Installer` was allowed to move the `stable` tag and publish the rolling stable release directly from a normal push.
- The same workflow failed in Inno Setup before those publish steps.

**Root causes**
- Release authority was duplicated between the fast installer workflow and the comprehensive stable workflow.
- The fast workflow did not generate `installer/impuls.ico` although `ImPuls.iss` requires it via `SetupIconFile`.
- Installer metadata still carried stale `0.10.4` defaults while runtime was `0.10.7-stable`.

**Fix**
- Make the fast Windows installer workflow **artifact-only** with read-only contents permission.
- Remove stable-tag movement and GitHub release publication from that workflow.
- Generate the installer icon before Inno Setup.
- Pass/verify canonical app version and align `ImPuls.iss` fallback/version-info metadata.
- Add pull-request execution so installer regressions are caught before merge.

**Evidence**
- PR #9 `Build Windows Installer` run `37545494001` — PASS.
- Windows export, icon preparation, Inno Setup, SHA-256 and artifact upload all succeeded.

**Prevention**
- Only the comprehensive release workflow may update rolling `stable`.
- Installer metadata must derive from the canonical version source and be checked in CI.
- A fast packaging workflow must not have release-publication authority.
