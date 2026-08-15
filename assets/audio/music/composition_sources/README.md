# ImPuls — CC0 Composition Sources

Source registry only. These libraries are not connected to Godot or runtime audio.

The purpose of this folder is to preserve legal, reusable sources for producing original ImPuls music later instead of relying only on finished third-party tracks.

## VS Chamber Orchestra: Community Edition (VSCO 2 CE)
Repository: https://github.com/sgossner/VSCO-2-CE
License: CC0 1.0
Use: orchestral source library for future original fantasy/RPG scoring — strings, winds, brass and orchestral colors.
Policy: do not vendor the entire sample library into the core game repository. Use it in the music-production workflow and export only finished game-ready mixes/stems to the production music area.

## Versilian Community Sample Library (VCSL)
Repository: https://github.com/sgossner/VCSL
License: CC0
Use: broad acoustic/instrument sample source for future custom soundtrack, foley-like musical textures and unusual instruments.
Policy: production tool/source only; export selected finished music/stems rather than copying the full sample corpus into the game.

## Future original-score structure
When original ImPuls music is produced, prefer delivering:
- full mix;
- loop-safe mix;
- optional intro;
- optional outro;
- low-intensity stem;
- pulse/percussion stem;
- melody/harmony stem;
- danger/combat augmentation stem;
- BPM, key and loop-point metadata;
- source/project file kept outside the runtime game package when large.

This allows a later adaptive system to increase or remove layers without abrupt track changes.
