extends Node

# Non-magic world/combat feedback shared by player, NPCs, animals, tools and vehicles.
# This layer resolves a semantic surface first, then delegates lightweight particles
# to VFXLibrary and optional CC0 flipbooks to ThirdPartyVFX.

const FLIPBOOK_SCRIPT = preload("res://scripts/vfx_flipbook_3d.gd")
const KENNEY := "res://assets/vfx/third_party/kenney_particle_pack/PNG (Transparent)/"

const SURFACES := ["dirt", "grass", "sand", "mud", "snow", "stone", "wood", "metal", "glass", "water"]

func surface_at(world_position: Vector3) -> String:
    var xz := Vector2(world_position.x, world_position.z)
    if not WorldData.inside_world(xz):
        return "stone"

    var biome := WorldData.biome_at(xz)
    var elevation := WorldData.elevation_at(xz)
    if EnvironmentState.is_underwater or (biome == "ocean" and world_position.y <= WorldData.SEA_LEVEL + 1.5):
        return "water"

    var winter_snow := EnvironmentState.season == EnvironmentState.Season.WINTER and EnvironmentState.temperature_c <= 2.0
    if EnvironmentState.snow_intensity >= 0.15 or winter_snow or (EnvironmentState.frost_amount > 0.55 and biome in ["tundra", "taiga"]):
        return "snow"

    match biome:
        "mountains": return "stone"
        "marsh": return "mud"
        "drylands": return "sand"
        "forest", "taiga", "plains": return "grass"
        "tundra": return "dirt"
        "ocean": return "water" if elevation <= WorldData.SEA_LEVEL + 0.5 else "sand"
        _: return "dirt"

func surface_from_collider(collider: Variant, world_position: Vector3 = Vector3.ZERO) -> String:
    if collider == null:
        return surface_at(world_position)

    if collider is Node:
        var node := collider as Node
        if node.has_meta("surface_type"):
            var meta_surface := String(node.get_meta("surface_type")).to_lower()
            if meta_surface in SURFACES:
                return meta_surface

        for surface in SURFACES:
            if node.is_in_group("surface_" + surface) or node.is_in_group(surface):
                return surface

        var lowered := String(node.name).to_lower()
        var keywords := {
            "metal": ["metal", "steel", "iron", "pipe", "rail"],
            "wood": ["wood", "tree", "log", "plank", "door"],
            "glass": ["glass", "window"],
            "water": ["water", "river", "lake", "ocean"],
            "stone": ["stone", "rock", "brick", "concrete", "wall"],
            "sand": ["sand", "dune"],
            "mud": ["mud", "marsh", "swamp"],
            "snow": ["snow", "ice"],
            "grass": ["grass", "bush", "field"],
            "dirt": ["dirt", "soil", "ground", "terrain"]
        }
        for surface in keywords:
            for keyword in keywords[surface]:
                if lowered.contains(keyword):
                    return String(surface)

    return surface_at(world_position)

func spawn_footstep(world_position: Vector3, strength: float = 1.0, surface_override: String = "") -> void:
    var surface := _safe_surface(surface_override) if not surface_override.is_empty() else surface_at(world_position)
    var host := get_tree().current_scene
    if host == null:
        return
    var s := clampf(strength, 0.25, 2.2)

    match surface:
        "water":
            VFXLibrary.spawn_collision("water", world_position + Vector3.UP * 0.05, Vector3.UP, host, 0.45 * s)
        "stone":
            VFXLibrary.spawn_collision("stone", world_position + Vector3.UP * 0.05, Vector3.UP, host, 0.22 * s)
        "snow":
            VFXLibrary.spawn("magic_frost", world_position + Vector3.UP * 0.06, host, Vector3.UP, Vector3.ZERO, 0.18 * s)
            _spawn_flipbook([KENNEY + "smoke_03.png"], world_position + Vector3.UP * 0.10, 0.38 * s, Color(0.90, 0.96, 1.0, 0.68), 0.12)
        "mud":
            VFXLibrary.spawn_collision("dirt", world_position + Vector3.UP * 0.05, Vector3.UP, host, 0.32 * s)
            VFXLibrary.spawn_collision("water", world_position + Vector3.UP * 0.04, Vector3.UP, host, 0.18 * s)
        "sand":
            VFXLibrary.spawn_collision("dirt", world_position + Vector3.UP * 0.05, Vector3.UP, host, 0.34 * s)
            _spawn_flipbook(_dirt_frames(), world_position + Vector3.UP * 0.12, 0.42 * s, Color(0.82, 0.68, 0.42, 0.72), 0.055)
        "grass":
            VFXLibrary.spawn_collision("dirt", world_position + Vector3.UP * 0.05, Vector3.UP, host, 0.18 * s)
            _spawn_flipbook(_dirt_frames(), world_position + Vector3.UP * 0.10, 0.30 * s, Color(0.46, 0.64, 0.28, 0.56), 0.060)
        _:
            VFXLibrary.spawn_collision("dirt", world_position + Vector3.UP * 0.05, Vector3.UP, host, 0.24 * s)
            _spawn_flipbook(_dirt_frames(), world_position + Vector3.UP * 0.10, 0.34 * s, Color(0.60, 0.47, 0.30, 0.62), 0.060)

func spawn_landing(world_position: Vector3, fall_speed: float, surface_override: String = "") -> void:
    var strength := clampf((absf(fall_speed) - 3.0) / 6.0, 0.45, 2.2)
    var surface := _safe_surface(surface_override) if not surface_override.is_empty() else surface_at(world_position)
    spawn_footstep(world_position, strength * 1.35, surface)
    if strength > 0.9:
        spawn_impact(surface, world_position + Vector3.UP * 0.08, Vector3.UP, Vector3.DOWN, strength * 0.75)

func spawn_impact(
        surface: String,
        world_position: Vector3,
        normal: Vector3 = Vector3.UP,
        direction: Vector3 = Vector3.ZERO,
        strength: float = 1.0
    ) -> void:
    var host := get_tree().current_scene
    if host == null:
        return
    var safe := _safe_surface(surface)
    var s := clampf(strength, 0.25, 3.0)
    match safe:
        "metal":
            VFXLibrary.spawn_collision("metal", world_position, normal, host, s)
            _spawn_flipbook(_spark_frames(), world_position, 0.55 * s, Color(1.0, 0.84, 0.46, 0.95), 0.035)
        "glass":
            VFXLibrary.spawn_collision("glass", world_position, normal, host, s)
            _spawn_flipbook(_spark_frames(), world_position, 0.42 * s, Color(0.72, 0.94, 1.0, 0.82), 0.040)
        "wood":
            VFXLibrary.spawn_collision("wood", world_position, normal, host, s)
            _spawn_flipbook(_dirt_frames(), world_position, 0.36 * s, Color(0.58, 0.36, 0.16, 0.70), 0.055)
        "water":
            VFXLibrary.spawn_collision("water", world_position, normal, host, s)
        "stone":
            VFXLibrary.spawn_collision("stone", world_position, normal, host, s)
            _spawn_flipbook(_dirt_frames(), world_position, 0.32 * s, Color(0.58, 0.57, 0.54, 0.64), 0.055)
        "snow":
            VFXLibrary.spawn("magic_frost", world_position, host, normal, direction, 0.28 * s)
            _spawn_flipbook([KENNEY + "smoke_03.png"], world_position, 0.48 * s, Color(0.92, 0.97, 1.0, 0.72), 0.11)
        "mud":
            VFXLibrary.spawn_collision("dirt", world_position, normal, host, 0.75 * s)
            VFXLibrary.spawn_collision("water", world_position, normal, host, 0.45 * s)
        "sand":
            VFXLibrary.spawn_collision("dirt", world_position, normal, host, 0.85 * s)
            _spawn_flipbook(_dirt_frames(), world_position, 0.50 * s, Color(0.84, 0.70, 0.44, 0.76), 0.055)
        "grass":
            VFXLibrary.spawn_collision("dirt", world_position, normal, host, 0.55 * s)
            _spawn_flipbook(_dirt_frames(), world_position, 0.36 * s, Color(0.42, 0.58, 0.25, 0.62), 0.060)
        _:
            VFXLibrary.spawn_collision("dirt", world_position, normal, host, s)

func spawn_environment_effect(kind: String, world_position: Vector3, strength: float = 1.0) -> Node3D:
    var host := get_tree().current_scene
    if host == null:
        return null
    var s := clampf(strength, 0.25, 3.0)
    match kind.to_lower():
        "fire", "flame":
            VFXLibrary.spawn("magic_fire", world_position, host, Vector3.UP, Vector3.ZERO, 0.65 * s)
            return _spawn_flipbook(_fire_frames(), world_position + Vector3.UP * 0.35, 0.95 * s, Color(1.0, 0.62, 0.28, 0.94), 0.055)
        "smoke":
            return _spawn_flipbook(_smoke_frames(), world_position + Vector3.UP * 0.45, 1.05 * s, Color(0.36, 0.37, 0.40, 0.72), 0.085)
        "steam":
            return _spawn_flipbook(_smoke_frames(), world_position + Vector3.UP * 0.35, 0.90 * s, Color(0.88, 0.92, 0.94, 0.58), 0.075)
        "dust":
            VFXLibrary.spawn_collision("dirt", world_position, Vector3.UP, host, 0.50 * s)
            return _spawn_flipbook(_dirt_frames(), world_position + Vector3.UP * 0.15, 0.65 * s, Color(0.70, 0.57, 0.38, 0.66), 0.065)
        "sparks":
            VFXLibrary.spawn_collision("metal", world_position, Vector3.UP, host, 0.65 * s)
            return _spawn_flipbook(_spark_frames(), world_position, 0.60 * s, Color(1.0, 0.78, 0.34, 0.96), 0.035)
        "splash":
            VFXLibrary.spawn_collision("water", world_position, Vector3.UP, host, 0.65 * s)
        "debris":
            VFXLibrary.spawn_collision("stone", world_position, Vector3.UP, host, 0.70 * s)
        _:
            VFXLibrary.spawn_collision("dirt", world_position, Vector3.UP, host, 0.45 * s)
    return null

func _spawn_flipbook(paths: Array[String], position: Vector3, size: float, tint: Color, frame_time: float) -> Node3D:
    var host := get_tree().current_scene
    if host == null:
        return null
    var valid: Array[String] = []
    for path in paths:
        if ResourceLoader.exists(path):
            valid.append(path)
    if valid.is_empty():
        return null
    var flipbook = FLIPBOOK_SCRIPT.new()
    host.add_child(flipbook)
    flipbook.global_position = position
    if not flipbook.setup(valid, maxf(size, 0.12), tint, maxf(frame_time, 0.025), 1):
        flipbook.queue_free()
        return null
    return flipbook

func _safe_surface(surface: String) -> String:
    var lowered := surface.to_lower()
    return lowered if lowered in SURFACES else "dirt"

func _dirt_frames() -> Array[String]:
    return [KENNEY + "dirt_01.png", KENNEY + "dirt_02.png", KENNEY + "dirt_03.png"]

func _spark_frames() -> Array[String]:
    return [KENNEY + "spark_01.png", KENNEY + "spark_02.png", KENNEY + "spark_03.png", KENNEY + "spark_04.png"]

func _smoke_frames() -> Array[String]:
    return [KENNEY + "smoke_03.png", KENNEY + "smoke_06.png", KENNEY + "smoke_08.png", KENNEY + "smoke_10.png"]

func _fire_frames() -> Array[String]:
    return [KENNEY + "flame_01.png", KENNEY + "flame_02.png", KENNEY + "flame_03.png", KENNEY + "flame_04.png"]
