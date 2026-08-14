# ImPuls development instructions

## Shared assets
All agents/chats working on this repository MUST read `assets/ASSET_PACKS.md` before creating or sourcing visual assets and should also inspect relevant detailed registries under `assets/registry/` before duplicating work.

Use existing/imported packs from the repository whenever suitable instead of regenerating duplicates. Keep nature, buildings, animals and UI organized under `assets/` according to the registry.

The physically integrated environment shader core is documented in `assets/shaders/environment/README.md` and `assets/registry/ENVIRONMENT_SHADER_CORE_2026-08-14.md`. Reuse and extend these shared underwater, snow, wind/cloth and seasonal material systems instead of creating incompatible one-off replacements.

When adding a third-party pack:
- only add assets with verified compatible rights (CC0 preferred);
- preserve license/readme information;
- add its source and target path to `assets/ASSET_PACKS.md` or an appropriate detailed file under `assets/registry/`;
- integrate the useful assets into the game rather than leaving them unused.

The repository `Treninem/game` is the canonical source of truth for this game.
