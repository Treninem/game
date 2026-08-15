# Music source library

This folder is a source/staging area for game music. Nothing here is automatically connected to runtime gameplay.

## Rules
- Keep third-party source/license information.
- Prefer CC0/public-domain material where possible.
- Main game-development flow must audition tracks before use.
- Do not hard-code filenames from this folder into gameplay systems.
- Use semantic states such as calm, exploration, suspicion, danger, chase, combat and boss.
- Silence is an intentional state; environmental ambience should often play without music.
- Avoid copying giant music libraries directly into core Git history when a pinned source repository is sufficient.

See `assets/registry/MUSIC_DYNAMIC_LIBRARY_2026-08-15.md` for the current mood/state map and integration guidance.
