# Asset research chat rule

This file records the operating rule for the dedicated asset-research chat.

## Scope
This chat must NOT integrate assets into the running game and must NOT modify runtime/gameplay assembly.

Do not modify from this chat:
- `project.godot`
- autoload configuration
- gameplay/runtime scripts under `scripts/`
- scenes under `scenes/`
- active game assembly, boot flow, save system, controls, gameplay balance, world/runtime wiring

## Allowed work in this chat
- search for free/CC0 assets and verify licenses;
- download/store approved asset source files in appropriate `assets/` folders when practical;
- add `SOURCE.md`, `LICENSE.txt`, manifests, registries and import notes;
- prepare shaders/textures/models/VFX as source assets only, without wiring them into runtime;
- update `assets/ASSET_PACKS.md` and `assets/registry/`;
- document Godot compatibility requirements, performance notes and recommended integration steps.

## Integration ownership
The main game-development chat is responsible for deciding when and how to integrate these assets into the actual game, resolve conflicts, modify `project.godot`, wire scenes/scripts/autoloads and perform final testing.

## Safety rule
If an asset needs runtime code to demonstrate it, this chat should provide an integration note/example under `assets/registry/` or `assets/integration_notes/` instead of editing live game runtime files.
