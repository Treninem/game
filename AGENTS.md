# ImPuls development instructions

## Integration ownership and parallel-chat safety
`Treninem/game` is the canonical source of truth for the game. The designated main integration chat owns live runtime integration and release readiness.

Unless the user explicitly delegates a runtime task elsewhere, parallel specialist/source chats MUST NOT edit `scripts/**`, `scenes/**`, `tests/**`, `project.godot`, `export_presets.cfg`, `installer/**`, or runtime/build/release workflows under `.github/workflows/**`. Story-only chats may edit `story/**`. Source-only asset chats may edit staging, registry, license and source-pack material as described below.

Before every live integration write, re-read the current `main` head and the exact target file so work from another chat is not overwritten. Keep commits narrow, never force-push/rewrite shared history, and resolve newly arrived changes before continuing.

A stable installer/release MUST NOT be published merely because the project parses. Mandatory release gates are a green `Validate World Core`, green player-movement validation, and the release workflow's own bounded gameplay/UI/export/installer checks. Never remove, weaken, skip or turn a failing smoke test into a warning just to obtain a green build. Fix the underlying regression instead.

## Shared assets
All agents/chats working on this repository MUST read `assets/ASSET_PACKS.md` before creating or sourcing visual assets and should also inspect relevant detailed registries under `assets/registry/` before duplicating work.

Before downloading, generating or importing any third-party asset, agents MUST also check `assets/staging/PHYSICAL_STAGING_INDEX.md` and the relevant `assets/staging/` folder. That index is the canonical list of source packs whose real files have been confirmed in `main`; do not redownload or regenerate an equivalent pack merely because it is only mentioned elsewhere in the registry.

Use existing/imported packs from the repository whenever suitable instead of regenerating duplicates. Keep nature, buildings, animals and UI organized under `assets/` according to the registry.

The physically integrated environment shader core is documented in `assets/shaders/environment/README.md` and `assets/registry/ENVIRONMENT_SHADER_CORE_2026-08-14.md`. Reuse and extend these shared underwater, snow, wind/cloth and seasonal material systems instead of creating incompatible one-off replacements.

## Asset status vocabulary
Use these exact meanings when reporting asset state across chats:
- `DISCOVERED` — source found; no files confirmed in repository.
- `APPROVED` — source/license reviewed; physical download may still be absent.
- `STAGED_PHYSICAL` — real files confirmed under `assets/staging/` on `main`.
- `PRODUCTION_READY` — selected asset has been normalized/tested for Godot production use.
- `INTEGRATED` — the live game actually references the asset in scenes/resources/code.

Do not use the word `imported` by itself when the exact state is unclear. A registry entry is not proof of physical files, and physical staging is not proof of gameplay integration.

## Source-only staging chats
When a chat/session is explicitly assigned to asset sourcing/staging only, it MUST NOT modify runtime game integration. In source-only mode do not edit gameplay scripts, scenes, `project.godot`, autoloads, export/build configuration or connect assets to live gameplay.

Source-only work goes under `assets/staging/` plus registry/license metadata. The main integration chat is responsible for reviewing staged content, selecting what is production-ready, moving/copying it into production asset paths and wiring it into the game.

This split exists to prevent parallel asset chats from breaking the playable branch while still allowing several chats to expand the shared repository in parallel.

When adding a third-party pack:
- only add assets with verified compatible rights (CC0 preferred);
- preserve license/readme information;
- add its source and target path to `assets/ASSET_PACKS.md`, `assets/staging/PHYSICAL_STAGING_INDEX.md` once physically confirmed, or an appropriate detailed file under `assets/registry/`;
- keep only a preferred/canonical interchange format for large source packs when practical instead of storing duplicate GLB/glTF, FBX and OBJ copies of the same models;
- check the batch failure manifest before claiming the pack is `STAGED_PHYSICAL`;
- if working in source-only staging mode, record the recommended integration target but do not integrate it yourself;
- if working in the main integration chat, integrate selected useful assets after review rather than leaving production copies unused.
