# ImPuls — Dynamic Music Source Library

Asset-library document only. This chat does not wire music into gameplay, scenes, autoloads, `project.godot`, or runtime scripts.

## Physical / pinned music source

### Efface Studios Royalty-Free Music Pack
- Status: `PINNED_VENDOR`
- Path: `assets/audio/music/source_packs/efface_cc0_music_pack/`
- Upstream: `effacestudios/Royalty-Free-Music-Pack`
- Pinned commit: `2ce8458293fe4eeb91414a19d6d7ecd1562a5949`
- License: CC0 1.0 Universal (`LICENSE` in upstream root).
- Repository size is kept outside the core Git history through a pinned submodule.
- Contains dozens of real MP3 tracks, including titles such as `Fury`, `Mysterious`, `The Mystery`, `Unexpected`, `Unknown`, `Unpredicted`, `alarming`, `lunatic`, `slow down`, `Planning`, `Science Fiction`, `The Templer`, `Happy Life`, `Outsider` and others.
- Track-name-to-game-state mapping below is a candidate map; final selection must be auditioned by the main game-development flow before runtime integration.

## Existing linked music-capable source
The already pinned `assets/audio/source_packs/cc0_public_domain_sounds/` library also contains Kenney music/jingle material. Keep short cues, stingers, victory/defeat transitions and UI/menu cues there instead of duplicating them into core history.

## Dynamic music states
The intended runtime system should be semantic rather than filename-driven. Music intensity can move gradually through these states:

`SILENCE -> CALM -> EXPLORATION -> SUSPICION -> DANGER -> CHASE -> COMBAT -> BOSS`

Additional orthogonal contexts:
- `NIGHT`
- `CITY`
- `TAVERN`
- `FOREST`
- `FIELDS`
- `MOUNTAINS`
- `CAVE`
- `SWAMP`
- `RUINS`
- `DUNGEON`
- `MAGIC`
- `MYSTERY`
- `SAD`
- `HOPEFUL`
- `VICTORY`
- `DEFEAT`
- `MENU`
- `CUTSCENE`

## Candidate mood map from the pinned pack
These are starting points based on track names and source presentation; audition before production use.

### Calm / safe / rest
Candidates:
- `Happy Life.mp3`
- `slow down.mp3`
- `biography.mp3`
- `recipe.mp3`
- `Newness.mp3`

Use for safe settlements, home/interior rest, peaceful travel and low-intensity exploration.

### Exploration / open world
Candidates:
- `Outsider.mp3`
- `Sudden Tour.mp3`
- `Planning.mp3`
- `Starter.mp3`
- `The Templer.mp3`

Use low-volume, sparse playback. Allow long quiet gaps so the world ambience remains important.

### Mystery / ruins / magic
Candidates:
- `Mysterious.mp3`
- `The Mystery.mp3`
- `Illusionist.mp3`
- `Unknown.mp3`
- `Unpredicted.mp3`
- `Science Fiction.mp3`

Use for ancient ruins, unknown magic, strange discoveries, forbidden areas and supernatural story beats.

### Suspicion / nearby danger
Candidates:
- `alarming.mp3`
- `Unexpected.mp3`
- `Unknown.mp3`
- `Planning.mp3`

Desired behavior later: fade up subtly when threat awareness rises; do not jump immediately to combat music.

### Danger / pursuit / chase
Candidates:
- `Fury.mp3`
- `lunatic.mp3`
- `breaker.mp3`
- `Dubstepper.mp3`
- `my snares.mp3`

Desired behavior later: faster transition than ordinary exploration, but preserve a short escalation phase before full combat.

### Combat / high intensity
Candidates:
- `Fury.mp3`
- `The Champion.mp3`
- `Worship Me.mp3`
- `Sports Spirit.mp3`
- `breaker.mp3`

Boss encounters should use their own pool and should not reuse ordinary roadside combat too often.

### Silence / near-silence
Silence is an intentional music state, not missing content.
- wilderness at night
- stealth
- aftermath of battle
- entering an unknown building
- emotional dialogue
- weather-heavy scenes
- caves where ambience should dominate

Do not fill every minute with music. Environmental audio, footsteps, wind, wildlife, water, fire and distant activity should often carry the scene alone.

## Verified external CC0 candidates for later physical import
- OpenGameArt `Overworld (BGM)` — calm/minimal looping overworld music, CC0.
- OpenGameArt `EmptyCity: Background Music` — dark, lonely, loopable exploration, CC0.
- OpenGameArt `Insistent: background loop` — danger/paranoia/underground tension, CC0.
- OpenGameArt `Chase - Diamond Dust` — fast panic/chase loop, CC0.
- OpenGameArt `Short Battle Loop` — sparse intense encounter loop, CC0.
- OpenGameArt `music loops` by drakzlin — CC0 packs containing action/battle/horror loop material.

These are registered as `APPROVED_SOURCE`; do not mark them `PHYSICAL` until their files are actually vendored.

## Adaptive-music design requirements for the main game chat
No runtime code is added here. When integration begins, prefer:
- semantic event names instead of hard-coded filenames;
- 2–6 second crossfades for ordinary state changes;
- faster danger/chase escalation, slower de-escalation;
- cooldown before dropping from combat straight back to calm;
- optional intro/loop/outro or stem/layer support when source material provides it;
- intensity tiers so nearby threat can add tension without starting full combat music;
- biome/location pools to avoid one global exploration track;
- randomized track choice with recent-history exclusion;
- configurable minimum silence between tracks;
- music ducking below dialogue and important one-shot SFX;
- no music restart when crossing tiny area boundaries;
- persistent musical context through short loading/indoor transitions when appropriate;
- boss, major quest, discovery and tragedy themes kept rare so they retain impact.

## Suggested intensity values for future implementation
- 0.00–0.10: silence / environmental ambience only
- 0.10–0.30: calm
- 0.30–0.45: exploration
- 0.45–0.60: suspicion
- 0.60–0.75: danger
- 0.75–0.88: chase
- 0.88–1.00: combat / boss

These values are design guidance only and are not wired to gameplay from this asset-research flow.

## RPG / cinematic expansion — 2026-08-15
Detailed verified discovery catalog:
- `assets/audio/music/catalogs/CC0_RPG_MUSIC_DISCOVERY.md`

New verified CC0 candidates registered there include:
- `Pursuit` — tense loopable piano chase/battle;
- `Enemy Ship Approaching` — short approaching-threat loop;
- `Determined Pursuit` — orchestral pursuit/boss loop;
- `Heartfelt Battle` — fantasy battle with separate intro/loop/outro assets;
- `JRPG Epic Rock Battle Theme #1` — intro/loop/full combat set;
- `Chase` — fast modern pursuit for special sequences;
- `Creed of Course` — flute/violin/snare material useful for military/village contexts.

Large external corpus `SoundSafari/CC0-1.0-Music` is registered as `DISCOVERY_ONLY`; do not vendor tens of gigabytes into core Git. Select individual tracks only after source/lineage verification.

For future original ImPuls score production, CC0 orchestral/sample sources are registered at:
- `assets/audio/music/composition_sources/README.md`

That production path should prefer exportable stems (low intensity, percussion/pulse, melody/harmony and danger/combat augmentation) so later runtime integration can create genuinely adaptive music instead of only crossfading complete songs.
