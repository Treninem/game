# Binbun library editor compatibility — review candidate

This is a library-only repair. It does not connect vendor showcases or new effects to the live game and does not establish production visual acceptance. Existing CC0 SOURCE.md/LICENSE.txt files are retained; no download or duplicate source asset was added.

## Global classes

The core and combat libraries both declared `VFXControllerBB`, `VFXEmitterBB` and `VFXOmniLightBB`. Godot reproduced `Class ... hides a global script class` on each core script. The combat controller also contains different material-instance and smoke-decay behavior, so substituting the core implementation would lose behavior.

Combat classes now use `VFXCombatControllerBB`, `VFXCombatEmitterBB` and `VFXCombatOmniLightBB`. Their combat subclasses and typed light references are updated. File paths, scene node names, serialized parameters and the existing controller implementations remain in place. In particular, nodes still named `VFXOmniLightBB` keep those names.

## Existing physical dependencies

- The core flame showcase references the existing combat-library `shared/suzanne.obj` instead of an absent core copy. This reuses the already retained CC0 mesh; no duplicate is created.
- The combat showcase uses its existing free `vfx_blank_shield_01.tscn` at the second shield position; its reference to absent `vfx_blank_shield_02.tscn` is removed. This is an available free-asset variant, not a recovered missing preset.
- The free beam base scene now binds its existing controller as an actual Script external resource. The old generic Resource with load-path metadata could not be assigned as a node script.

## Verification scope

The regression checks global-name uniqueness, compiles all 26 scripts, and loads/instantiates all 33 scenes across the four existing Binbun folders. It retains missing-dependency and invalid-script errors as failures. World Core watches these pack paths and runs the regression; existing gates remain unchanged.

Foreign external-resource UID fallback warnings are a separate remaining normalization issue. Compilation/instantiation is not proof that every vendor effect looks correct, plays correctly in every renderer, or is suitable for the ImPuls art direction.
