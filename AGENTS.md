# ImPuls development instructions

## Shared assets
All agents/chats working on this repository MUST read `assets/ASSET_PACKS.md` before creating or sourcing visual assets and should also inspect relevant detailed registries under `assets/registry/` before duplicating work.

Use existing/imported packs from the repository whenever suitable instead of regenerating duplicates. Keep nature, buildings, animals and UI organized under `assets/` according to the registry.

The physically integrated environment shader core is documented in `assets/shaders/environment/README.md` and `assets/registry/ENVIRONMENT_SHADER_CORE_2026-08-14.md`. Reuse and extend these shared underwater, snow, wind/cloth and seasonal material systems instead of creating incompatible one-off replacements.

## Source-only staging chats
When a chat/session is explicitly assigned to asset sourcing/staging only, it MUST NOT modify runtime game integration. In source-only mode do not edit gameplay scripts, scenes, `project.godot`, autoloads, export/build configuration or connect assets to live gameplay.

Source-only work goes under `assets/staging/` plus registry/license metadata. The main integration chat is responsible for reviewing staged content, selecting what is production-ready, moving/copying it into production asset paths and wiring it into the game.

This split exists to prevent parallel asset chats from breaking the playable branch while still allowing several chats to expand the shared repository in parallel.

When adding a third-party pack:
- only add assets with verified compatible rights (CC0 preferred);
- preserve license/readme information;
- add its source and target path to `assets/ASSET_PACKS.md` or an appropriate detailed file under `assets/registry/`;
- if working in source-only staging mode, record the recommended integration target but do not integrate it yourself;
- if working in the main integration chat, integrate selected useful assets after review rather than leaving production copies unused.

The repository `Treninem/game` is the canonical source of truth for this game.
