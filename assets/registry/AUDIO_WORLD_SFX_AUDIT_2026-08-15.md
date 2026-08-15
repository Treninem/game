# Audio world / environment audit — 2026-08-15

Staging-library update only. Nothing here is wired into gameplay, scenes, `project.godot`, autoloads, or runtime scripts.

## Newly pinned: Kenney Digital Audio
- Status: `PINNED_VENDOR`
- Path: `assets/audio/third_party/kenney_digital_audio/`
- Upstream: `Boyquotes/kenney-digital-audio-for-godot`
- Pinned commit: `185a77e7c675341ad8d0805b3bbe4f20427c2481`
- License: CC0 1.0 Universal (`LICENSE` in upstream root).
- Real OGG material includes high/low digital cues, laser variants, phase-jump/phaser effects and other synthetic technology feedback.
- Later semantic groups: `TECH_BEEP`, `TECH_POWER_UP`, `TECH_POWER_DOWN`, `TECH_PHASE`, `ENERGY_SHOT`, `ENERGY_DEVICE`.

## Audited real files in the already pinned bulk CC0 source library
Source: `assets/audio/source_packs/cc0_public_domain_sounds/` at `f2b6264f9ab89fabc266914c3654685d68c5a39b`.

### Water / weather
`40-cc0-water-splash-slime-sfx/` contains real OGG one-shots and loops including bubbles, `loop_rain.ogg`, water loops, splashes and wet/slime interactions.
Recommended later groups: `RAIN_LOOP`, `WATER_FLOW_LOOP`, `WATER_BUBBLE`, `WATER_SPLASH`, `WET_IMPACT`.

### Creatures / animals
`80-CC0-creature-SFX/` contains real OGG creature material including barking, breathing and many creature/monster vocalizations. It is useful for generic creatures and some domestic-animal cues, but must not be treated as a complete realistic wildlife library.
Recommended later groups: `CREATURE_IDLE`, `CREATURE_ALERT`, `CREATURE_ATTACK`, `CREATURE_PAIN`, `DOG_BARK`, `CREATURE_BREATH`.

### Small mechanisms
`bb - Smol Mechanisms (May 2021)/` contains real WAV recordings such as cable coilers and physical button clicks, useful for workshop, machinery and prop interactions.
Recommended later groups: `MECH_SMALL_LOOP`, `MECH_CLICK`, `MECH_COILER`, `PROP_MECHANISM`.

## Classification correction
`Micro Pack - MadameBerry - Stream Noises/` is **not water/river audio**. Its files are streamer/voice phrases and vocal reactions. Do not use it for rivers, streams or nature ambience.

`Maximiliano-Stradex-Ambient/` contains generic ambient/theme MP3 tracks. Keep it in audition-only ambience/music material; do not label it as verified forest/nature field recording.

## Remaining high-priority gaps
Still deliberately missing or not yet strong enough for a realistic open world:
1. forest day/night field ambience;
2. separate bird and insect ecology by biome;
3. wind/gust/storm/blizzard layers;
4. thunder at several distances;
5. cave, mine and underground room tones;
6. farm animals and realistic wildlife families;
7. settlement crowd, market, tavern and workshop beds;
8. ocean/coast/waterfall/large-river beds;
9. large building collapse and structural destruction;
10. era-specific vehicle and heavy-machine libraries.

Main development should audition, normalize and select only needed production variants later. Source filenames must not become gameplay API names.
