# ImPuls development instructions

These instructions apply to **every** coding agent, ChatGPT chat, Work session, Codex session, automation or other development process that changes `Treninem/game`.

## Mandatory first action

Before editing any live project file:

1. Fetch the latest `main` HEAD.
2. Read **all of `docs/PROJECT_MASTER_LOG.md`**.
3. Read **all of `docs/IMPULS_ENGINEERING_MEMORY.md`** and search it for the subsystem, symptom and exact error involved.
4. Read the master log section `Active work and claimed files`.
5. Add/reconcile an ACTIVE claim in the master log before touching implementation/release files.
6. Re-read the exact target file from the current base immediately before editing it.
7. If asset work is involved, also read `assets/ASSET_PACKS.md` and `assets/staging/PHYSICAL_STAGING_INDEX.md`.

Repository state, current CI and reproducible logs override stale chat prose.

## One journal only

`docs/PROJECT_MASTER_LOG.md` is the **only development/coordination journal** for ImPuls.

Do not create separate chat, Work, Codex, lane, progress, release or development journals. Technical subsystem documentation and engineering-memory entries are allowed, but current status, claims, commits, CI evidence, release readiness and exact NEXT belong only in the master log.

## Engineering-memory protocol

`docs/IMPULS_ENGINEERING_MEMORY.md` stores durable confirmed failures, root causes, unsuccessful workarounds worth avoiding, fixes and prevention rules.

- Search it before repeating a workaround.
- Record a newly confirmed reusable failure/fix before closing the owning claim.
- Do not erase resolved lessons; mark them `RESOLVED` or `SUPERSEDED`.
- Never record a skipped/waived check as PASS.
- Never store passwords, tokens, signing secrets or credentials.
- Progress/status does not belong there; it belongs in the master log.

## Stabilization invariant — playable baseline first

Until the master log explicitly ends the current stabilization freeze, the primary goal is:

> Make the **existing** game reliably playable and releasable before expanding world size, story volume, item families, NPC families or new gameplay systems.

During stabilization:

- P0 defects block new feature/content expansion.
- P1 defects in the touched subsystem must be resolved or explicitly isolated before adding more content to it.
- Prefer fixing/integrating what already exists over adding another system.
- Do not mass-wire staging libraries into runtime.
- Replace obvious placeholders only with coherent already-staged assets and prove performance/stability.
- A new asset family is integrated in a bounded batch with scale/material/collision/LOD/animation normalization and tests.
- A system is not “done” merely because its script exists; the player-facing flow must work.
- Do not publish a stable release from a SHA that has not passed the required release gates.

## Integration ownership and parallel-chat safety

`Treninem/game` is the canonical source of truth for the game. The designated main integration chat owns live runtime integration and release readiness.

Unless the user explicitly delegates a runtime task elsewhere, parallel specialist/source chats MUST NOT edit `scripts/**`, `scenes/**`, `tests/**`, `project.godot`, `export_presets.cfg`, `installer/**`, or runtime/build/release workflows under `.github/workflows/**`. Story-only chats may edit `story/**`. Source-only asset chats may edit staging, registry, license and source-pack material as described below.

Before every live integration write, re-read the current `main` head and the exact target file so work from another chat is not overwritten. Keep commits narrow, never force-push/rewrite shared history, and resolve newly arrived changes before continuing.

## Stable release invariant

A stable installer/release MUST NOT be published merely because the project parses.

Minimum requirements are:

- green `Validate World Core`;
- green `Validate Player Movement`;
- green relevant UI/gameplay smokes;
- successful Windows export/package/installer gates;
- synchronized version metadata;
- no known P0 defect in the candidate;
- installed-package playability acceptance before updating the rolling `stable` release.

Never remove, weaken, skip or turn a failing smoke test into a warning just to obtain a green build. Fix the underlying regression instead.

Release evidence must refer to the exact candidate lineage/SHA. Do not combine green checks from unrelated commits and call the result stable.

## Version metadata rule

Do not bump the public version merely because work started.

- Keep version-bearing files synchronized.
- Fix drift by aligning stale metadata to the currently accepted version unless a real release bump is being performed.
- Perform a new version bump only after the accumulated candidate passes its relevant functional tests.
- After a version bump, re-run version/package/release gates.
- Never distribute functionally changed binaries as though they were the same older release.

## Shared assets

All agents/chats working on this repository MUST read `assets/ASSET_PACKS.md` before creating or sourcing visual assets and should also inspect relevant detailed registries under `assets/registry/` before duplicating work.

Before downloading, generating or importing any third-party asset, agents MUST also check `assets/staging/PHYSICAL_STAGING_INDEX.md` and the relevant `assets/staging/` folder. That index is the canonical list of source packs whose real files have been confirmed in `main`; do not redownload or regenerate an equivalent pack merely because it is only mentioned elsewhere in the registry.

Use existing packs from the repository whenever suitable instead of generating duplicates. Keep nature, buildings, animals, characters, clothing, items, UI, audio and VFX organized under `assets/` according to the registry.

The physically integrated environment shader core is documented in `assets/shaders/environment/README.md` and `assets/registry/ENVIRONMENT_SHADER_CORE_2026-08-14.md`. Reuse and extend these shared underwater, snow, wind/cloth and seasonal material systems instead of creating incompatible one-off replacements.

## Asset status vocabulary

Use these exact meanings when reporting asset state across chats:

- `DISCOVERED` — source found; no files confirmed in repository.
- `APPROVED` — source/license reviewed; physical download may still be absent.
- `STAGED_PHYSICAL` — real files confirmed under staging/source-pack storage on `main`.
- `PRODUCTION_READY` — selected asset normalized/tested for Godot production use.
- `INTEGRATED` — the live game actually references the asset in scenes/resources/code.

Do not use the word `imported` by itself when the exact state is unclear. A registry entry is not proof of physical files, and physical staging is not proof of gameplay integration.

## Asset integration invariant

The repository already contains large staged libraries for characters/NPCs, animation, fauna, clothing/props, buildings/interiors, food/items/weapons, UI, audio and VFX.

Therefore:

1. Search existing physical staging/source packs first.
2. Prefer a coherent already-used pack over mixing unrelated styles.
3. Do not create new generic art when a suitable verified staged asset exists.
4. Do not mass-load the entire staging tree.
5. Promote only selected assets into production/runtime use.
6. Normalize scale, axes, pivots, materials, collisions and LODs.
7. Retarget/reuse shared animation libraries rather than duplicating per-character animation where practical.
8. Add bounded smoke/performance evidence before marking an asset `INTEGRATED`.
9. Keep source/license metadata intact.

Historical asset branches are not an integration queue. Compare them to current `main`; do not merge stale branches wholesale merely because they contain “asset” in the name.

## Source-only staging chats

When a chat/session is explicitly assigned to asset sourcing/staging only, it MUST NOT modify runtime game integration. In source-only mode do not edit gameplay scripts, scenes, `project.godot`, autoloads, export/build configuration or connect assets to live gameplay.

Source-only work goes under staging/source-pack storage plus registry/license metadata. The main integration chat is responsible for reviewing staged content, selecting what is production-ready, moving/copying it into production asset paths and wiring it into the game.

When adding a third-party pack:

- only add assets with verified compatible rights (CC0 preferred);
- preserve license/readme information;
- update the correct registry/index once physically confirmed;
- keep only a preferred/canonical interchange format for large source packs when practical;
- check batch failure manifests before claiming `STAGED_PHYSICAL`;
- in source-only mode, record the recommended integration target but do not integrate it;
- in main integration mode, integrate selected useful assets only after review.

## Change/claim protocol

For each coherent batch:

1. Declare exact scope/files in the master log.
2. State the acceptance criteria.
3. Implement on a current base without rewriting shared history.
4. Run the smallest relevant fast tests first, then mandatory broader gates.
5. Record commit/PR/run IDs and the result in the master log.
6. Record reusable technical lessons in engineering memory.
7. Mark the claim DONE and release its files/subsystem.
8. State the exact NEXT step.

When a lane reaches its acceptance criteria, it should not idle: release the claim, read fresh `main`, then take the next unclaimed stabilization package or independent verification work.

## Required status reporting

Every substantial executor handoff should use evidence-backed percentages:

- `PROGRESS_COMPLETE: XX%`
- `PROGRESS_REMAINING: YY%`

`XX + YY` must equal 100. Pending CI, unresolved P0/P1 defects, unverified packages/installers and missing installed-game evidence must remain counted in `PROGRESS_REMAINING`.

The main coordinator should end owner-facing progress reports with:

`ОБЩАЯ ГОТОВНОСТЬ IMPULS: XX%`

Do not report 100% until the current release-train acceptance gates in the master log are actually satisfied.
