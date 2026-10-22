# Whole arm chains and garment clearance — review evidence

Actual Godot 4.7.1 GL Compatibility / Intel UHD 610 native frames; automated
input, not manual play. Screenshots are unedited.

Compare `arm-before-female-Idle.png` with `arm-after-female-Idle.png`: the hands
now remain outside the tunic. The seated and legacy ground-work views review
deep arm/leg overlap. The controlled pose fixture has no bench and its floor
is not a player-grounding test. `arm-after-male-Cast_Left.png` checks the free
casting hand while retaining the axe in the other palm.

The 1,344-pose gate (960 retained player/preview plus 384 ordinary-citizen poses) covers both bodies, eight Build values (including saved
presets), 15 clips and four phases. It independently intersects actual final
skinned sleeve triangles with trousers and the tunic torso, counting proper
crossings deeper than 0.5 mm. 42438 pairs before, zero after; these are geometric
pairs, not visible bugs. Bone lengths, global palm rotation and supported legs
are checked separately. Bow draw/shoot, sleeping and death retain authored arms.
This does not certify the whole tunic/waist/hem, elbow volume, every continuous
blend or a full wardrobe.

34 poses / 62 color frames also compare actual packed GPU morphed/skinned
vertices against the final modifier snapshot: maximum discrepancy 1.68 µm.
RGB calibration must be exact; packed mesh/skin/morph buffers are preserved.
The existing independent 810-view covered-skin gate still passes. World Core
gains required geometry and graphical GPU checks without removing old gates.

`head-size-*` and `workshop-standing-production.png` are actual game frames.
Normal automated inputs walked 28.69 m in the forest, 40.29 m from the previously
earned capital arrival, and 27.22 m in the separate two-body action fixture.
No driver position writes, no fresh full forest-to-capital run. Tested creator,
two heights, nine forms, equip, bow, axe, magic, repeated menus and disk saves.
The workshop fixture holds the clock/survival for inspection; finite paid
trading and saved production still execute. Medium 120-frame means: forest
31.58 ms, workshop 39.93 ms. These are bounded samples, not sustained FPS.

An initial unchanged camera boot timed out at its existing 35-second limit;
the exact same warmed-profile test then passed both mouse modes, three UI scales,
boot and save/load. Two additional clean-profile runs reproduced the existing 35-second boot bound; the previous grip passed one clean-profile run. Diagnostics show scene-resource loading followed by 25 startup chunks. Warmed-profile camera passes do not establish reliable cold-start performance. No timeout, quality preset or readiness requirement was weakened. This remains open. A harness invocation also named a
nonexistent `smoke_airborne_actions.tscn`; that invocation failed, is retained
locally and is not counted as a pass. Actual jump/landing tests use existing
locomotion and native motion fixtures. No timeouts or gates were weakened.

82/84/100 ObjectDB exit leftovers remain in world/camera/workshop. Whole human
art, faces/hair, clothing dynamics, modern tool meshes, world art and animals
remain open. Experimental Blender jackets and GPU garment projections failed
expanded geometry checks and are not included in live assets. Accepted GLBs,
source .blend files, save formats, inventories and controls are unchanged here.

See `../../DEVELOPMENT_LOG_2026-10-22_ARM_CLEARANCE.json`, metrics and native logs.
Stable release remains unpublished. New exact-SHA CI is checked after push;
the parent 8df014f's eight green checks do not stand in for that verification.

Ordinary citizens have a separate arm-only modifier: no player gait, ground IK,
weapon socket or preview metadata. Six activities, both bodies, eight Build
values and four phases add 384 independent geometry cases and 12 GPU poses.
Real home routes, stationary-player clearance, saved/streamed citizens, finite
workshop production and the native workshop frame were repeated after this wiring.
The other retained local player checks precede the citizen-only wiring; the final
exact-head World Core repeats its complete mandatory gates.
