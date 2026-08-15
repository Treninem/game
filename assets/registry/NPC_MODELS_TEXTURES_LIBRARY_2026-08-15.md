# ImPuls — NPC / Character / Medieval Material Library

Date: 2026-08-15
Status: ASSET LIBRARY ONLY — NOT WIRED INTO RUNTIME

This registry is for the main game-development chat/agent. The asset-research chat must not edit `project.godot`, `scripts/`, `scenes/` or runtime wiring.

## Main-chat integration rule

Before generating replacement NPC art or placeholder world materials, check this registry and `assets/` first. Prefer verified assets below. The main chat owns Godot import, animation retargeting, collision/navigation setup, LOD, materials and final integration/testing.

## Priority A — NPC / humanoid character sources

### Quaternius — Ultimate Animated Character Pack
- License: CC0.
- Scope: 52 textured animated characters; 50+ character variants with multiple animations.
- Formats: FBX, OBJ, Blend.
- Best use in ImPuls: city/village population pool, civilians, guards, workers, merchants and background NPC variation.
- Source: https://quaternius.com/packs/ultimatedanimatedcharacter.html
- Upstream download mirror announced by author: https://drive.google.com/drive/folders/1sNi1AfenfPRrvRt5yfaj5QMMd6KKcUJ5?usp=sharing
- Integration priority: HIGH.

### Quaternius — Ultimate Modular Men
- License: CC0.
- Scope: 11 characters; 24 animations each; character split into 4 swappable model sections.
- Formats: FBX, OBJ, glTF, Blend.
- Best use: reusable male NPC generator for towns, farms, roads, guilds and quest population.
- Source: https://quaternius.com/packs/ultimatemodularcharacters.html
- Upstream download mirror announced by author: https://drive.google.com/drive/folders/1USAAquX2JJWuA2m6zol0KUkFe3UkZ8zX?usp=sharing
- Integration priority: VERY HIGH.

### Quaternius — Ultimate Modular Women
- License: CC0.
- Scope: 10 characters; 24 animations; 4 swappable model sections; humanoid rig version included.
- Formats: FBX, OBJ, glTF, Blend.
- Best use: reusable female NPC generator with the same population strategy as Modular Men.
- Source: https://quaternius.com/packs/ultimatemodularwomen.html
- Upstream download mirror announced by author: https://drive.google.com/drive/folders/1720N9IGyQHXYvtvZJzazhxtTTlz-y2Vf?usp=sharing
- Integration priority: VERY HIGH.

### Quaternius — RPG Character Pack
- License: CC0.
- Scope: six fantasy characters, rigged/animated/textured.
- Formats: FBX, OBJ, Blend, glTF.
- Best use: guards, bandits, adventurers, combatants and named fantasy NPC prototypes.
- Source: https://quaternius.com/packs/rpgcharacters.html
- Integration priority: HIGH.

### Quaternius — Modular Character Outfits: Fantasy
- License: CC0 for the free pack content; verify the exact downloaded free files before committing binaries.
- Scope: fantasy modular clothing/outfits intended for universal base characters.
- Best use: visually separating professions, factions, rich/poor classes, guards, travelers and quest NPCs without duplicating full bodies.
- Source: https://quaternius.com/
- Integration priority: HIGH after base humanoids.

### Kenney — Blocky Characters 2.0
- License: CC0.
- Scope: 18 skins and 27 animations; optimized low-poly character set; separate FBX/OBJ/glTF models and PNG skins.
- Best use: distant/background NPC LOD, prototypes, crowds, low-cost population and fallback characters.
- Source page: https://opengameart.org/content/blocky-characters
- Upstream archive: https://opengameart.org/sites/default/files/kenney_blocky-characters_2.0.zip
- Integration priority: MEDIUM/HIGH, especially for crowd LOD.

### OpenGameArt — 3D Character Pack (byzmod3d, 2026)
- License: CC0.
- Scope: male/female human character collection tagged low-poly, stylized, rigged, animated, humanoid and NPC.
- Best use: extra human variety after the Quaternius core population is established.
- Source: https://opengameart.org/content/3d-character-pack
- Integration priority: MEDIUM; inspect topology/rig consistency before mass use.

### OpenGameArt — 3D Human Parts Pack (byzmod3d, 2026)
- License: CC0.
- Scope: modular human heads/faces/arms/legs/hands/feet and other body pieces.
- Best use: character customization experiments and visual variation generation.
- Source: https://opengameart.org/content/3d-human-parts-pack
- Integration priority: MEDIUM.

## Priority A — World PBR materials

Use Poly Haven as the primary realistic CC0 material source. Prefer 1K/2K in normal gameplay and higher resolution only for hero/close-up assets. Godot uses OpenGL normal maps (`nor_gl`).

### Medieval Wood
- License: CC0.
- Intended use: doors, fences, sheds, barns, taverns, carts, beams, bridges, furniture and weathered wooden structures.
- Maps to keep: diffuse, normal OpenGL, roughness; optional AO/displacement for hero assets.
- Source: https://polyhaven.com/a/medieval_wood

### Medieval Wall 02
- License: CC0.
- Intended use: old town walls, foundations, cellars, ruins, wells, fortifications, stone houses and dungeons.
- Maps to keep: diffuse, normal OpenGL, roughness; optional AO/displacement.
- Source: https://polyhaven.com/a/medieval_wall_02

### Cobblestone Floor 001
- License: CC0.
- Intended use: city streets, village roads, courtyards, market squares, castle yards and old paths.
- Maps to keep: diffuse, normal OpenGL, roughness; optional ARM/displacement.
- Source: https://polyhaven.com/a/cobblestone_floor_001

## Recommended NPC population architecture for main chat

1. Build one shared humanoid/NPC base pipeline, not one bespoke scene per citizen.
2. Use modular bodies/outfits/material variants to create visual diversity.
3. Retarget a shared locomotion/idle/interact animation library rather than duplicating animation files per NPC.
4. Split population by role tags: civilian, worker, farmer, merchant, guard, traveler, bandit, adventurer, noble, child/elder only when suitable assets exist.
5. Use LOD/culling: full rig nearby; simplified mesh/animation at mid distance; impostor/static crowd far away.
6. Keep NPC gameplay data separate from visual model choice so art can be replaced without breaking quests or saves.
7. Never hard-code a quest/NPC identity to one third-party filename.

## Visual matching rule

Do not mix assets blindly. The main chat must normalize scale, orientation, material response, palette/lighting and shader settings. Quaternius/Kenney low-poly characters are best treated as a coherent population family or as LOD/prototype layers. Poly Haven materials are suited to world surfaces/buildings and should be tuned so they do not make NPCs look visually disconnected.

## License rule

Only physically import files after the exact upstream file/package license is verified. Preserve `SOURCE.md` and `LICENSE.txt` beside every vendored pack. CC0 is preferred. Do not import NC/ND assets.

## Status

- Verified source registry: COMPLETE for this batch.
- Runtime integration: intentionally NOT DONE in this chat.
- Main chat action: consume these sources before generating duplicate NPC/model/material assets.
