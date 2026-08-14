extends Node

signal selected_spell_changed(spell_id: String, label: String)
signal spell_cast(spell_id: String)

const PROJECTILE_SCRIPT = preload("res://scripts/magic_projectile.gd")
const ZONE_SCRIPT = preload("res://scripts/magic_zone.gd")

const SPELL_ORDER := [
    "fireball",
    "ice_shard",
    "lightning",
    "poison_orb",
    "heal",
    "shield",
    "fire_zone",
    "frost_zone",
    "arcane_blast",
    "blink"
]

const SPELLS := {
    "fireball": {
        "id": "fireball", "label": "Огненный шар", "type": "projectile", "element": "fire",
        "mana": 22.0, "cooldown": 0.85, "damage": 34.0, "speed": 19.0, "lifetime": 3.2,
        "status": "burning", "status_duration": 4.0, "explosion_radius": 2.4,
        "color": Color(1.0, 0.24, 0.04, 1.0), "visual_radius": 0.18
    },
    "ice_shard": {
        "id": "ice_shard", "label": "Ледяной осколок", "type": "projectile", "element": "frost",
        "mana": 16.0, "cooldown": 0.55, "damage": 27.0, "speed": 27.0, "lifetime": 2.8,
        "status": "frozen", "status_duration": 3.2, "explosion_radius": 0.0,
        "color": Color(0.25, 0.82, 1.0, 1.0), "visual_radius": 0.12
    },
    "lightning": {
        "id": "lightning", "label": "Молния", "type": "instant", "element": "lightning",
        "mana": 28.0, "cooldown": 1.10, "damage": 42.0, "range": 34.0,
        "status": "shocked", "status_duration": 2.2
    },
    "poison_orb": {
        "id": "poison_orb", "label": "Ядовитая сфера", "type": "projectile", "element": "poison",
        "mana": 20.0, "cooldown": 0.95, "damage": 17.0, "speed": 15.0, "lifetime": 3.6,
        "status": "poisoned", "status_duration": 6.0, "explosion_radius": 2.7,
        "color": Color(0.32, 0.95, 0.24, 1.0), "visual_radius": 0.16
    },
    "heal": {
        "id": "heal", "label": "Лечение", "type": "heal", "element": "heal",
        "mana": 30.0, "cooldown": 4.0, "heal": 38.0
    },
    "shield": {
        "id": "shield", "label": "Магический щит", "type": "shield", "element": "shield",
        "mana": 25.0, "cooldown": 6.0, "shield": 42.0
    },
    "fire_zone": {
        "id": "fire_zone", "label": "Огненная зона", "type": "zone", "element": "fire",
        "mana": 36.0, "cooldown": 5.0, "range": 15.0, "radius": 3.2, "duration": 6.0,
        "tick_interval": 0.75, "damage_per_tick": 7.0, "status": "burning", "status_duration": 2.0,
        "color": Color(1.0, 0.20, 0.04, 0.40)
    },
    "frost_zone": {
        "id": "frost_zone", "label": "Ледяное поле", "type": "zone", "element": "frost",
        "mana": 34.0, "cooldown": 5.0, "range": 15.0, "radius": 3.6, "duration": 5.5,
        "tick_interval": 0.80, "damage_per_tick": 3.5, "status": "frozen", "status_duration": 1.8,
        "color": Color(0.25, 0.82, 1.0, 0.38)
    },
    "arcane_blast": {
        "id": "arcane_blast", "label": "Арканный взрыв", "type": "burst", "element": "arcane",
        "mana": 32.0, "cooldown": 2.2, "range": 18.0, "radius": 3.8, "damage": 31.0
    },
    "blink": {
        "id": "blink", "label": "Короткий портал", "type": "blink", "element": "portal",
        "mana": 24.0, "cooldown": 3.5, "range": 8.0
    }
}

var selected_index := 0
var cooldowns: Dictionary = {}

func _ready() -> void:
    set_process(true)

func _process(delta: float) -> void:
    for spell_id in cooldowns.keys():
        var left := maxf(0.0, float(cooldowns[spell_id]) - delta)
        if left <= 0.0:
            cooldowns.erase(spell_id)
        else:
            cooldowns[spell_id] = left

func selected_spell_id() -> String:
    if SPELL_ORDER.is_empty():
        return ""
    selected_index = posmod(selected_index, SPELL_ORDER.size())
    return String(SPELL_ORDER[selected_index])

func selected_spell_label() -> String:
    var spell_id := selected_spell_id()
    return String(SPELLS.get(spell_id, {}).get("label", spell_id))

func select_next() -> void:
    if SPELL_ORDER.is_empty():
        return
    selected_index = (selected_index + 1) % SPELL_ORDER.size()
    _announce_selection()

func select_previous() -> void:
    if SPELL_ORDER.is_empty():
        return
    selected_index = posmod(selected_index - 1, SPELL_ORDER.size())
    _announce_selection()

func _announce_selection() -> void:
    var spell_id := selected_spell_id()
    var label := selected_spell_label()
    selected_spell_changed.emit(spell_id, label)
    GameState.notify("Магия: %s • ПКМ — применить • Q — следующая" % label)

func cooldown_left(spell_id: String) -> float:
    return maxf(0.0, float(cooldowns.get(spell_id, 0.0)))

func cast_selected(caster: CharacterBody3D, camera: Camera3D) -> bool:
    var spell_id := selected_spell_id()
    if spell_id.is_empty() or not SPELLS.has(spell_id):
        return false
    if GameState.is_dead:
        return false

    var data: Dictionary = SPELLS[spell_id]
    var cooldown := cooldown_left(spell_id)
    if cooldown > 0.0:
        GameState.notify("%s: восстановление %.1f с" % [String(data.get("label", spell_id)), cooldown])
        return false

    var mana_cost := float(data.get("mana", 0.0))
    if not GameState.consume_mana(mana_cost):
        GameState.notify("Недостаточно маны: нужно %.0f." % mana_cost)
        return false

    var cast_ok := false
    match String(data.get("type", "")):
        "projectile": cast_ok = _cast_projectile(data, caster, camera)
        "instant": cast_ok = _cast_instant(data, caster, camera)
        "heal": cast_ok = _cast_heal(data, caster)
        "shield": cast_ok = _cast_shield(data, caster)
        "zone": cast_ok = _cast_zone(data, caster, camera)
        "burst": cast_ok = _cast_burst(data, caster, camera)
        "blink": cast_ok = _cast_blink(data, caster, camera)

    if not cast_ok:
        GameState.restore_mana(mana_cost)
        return false

    cooldowns[spell_id] = float(data.get("cooldown", 0.5))
    spell_cast.emit(spell_id)
    return true

func _cast_projectile(data: Dictionary, caster: CharacterBody3D, camera: Camera3D) -> bool:
    var host := get_tree().current_scene
    if host == null:
        return false
    var direction := -camera.global_transform.basis.z.normalized()
    var projectile = PROJECTILE_SCRIPT.new()
    host.add_child(projectile)
    projectile.global_position = camera.global_position + direction * 0.85
    projectile.setup(data, caster, direction)
    VFXLibrary.spawn_magic(String(data.get("element", "arcane")), projectile.global_position, host, 0.65)
    return true

func _cast_instant(data: Dictionary, caster: CharacterBody3D, camera: Camera3D) -> bool:
    var direction := -camera.global_transform.basis.z.normalized()
    var from := camera.global_position
    var to := from + direction * float(data.get("range", 30.0))
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.collide_with_areas = false
    query.collide_with_bodies = true
    query.exclude = [caster.get_rid()]
    var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
    var impact := to
    var normal := -direction
    if not hit.is_empty():
        impact = hit.get("position", to)
        normal = hit.get("normal", -direction)
        var collider = hit.get("collider")
        if collider != null and collider.has_method("take_damage"):
            collider.take_damage(float(data.get("damage", 0.0)), caster)
            if collider.has_method("apply_status"):
                collider.apply_status(String(data.get("status", "")), float(data.get("status_duration", 0.0)), caster)
        else:
            VFXLibrary.spawn_collision("stone", impact, normal, get_tree().current_scene, 0.8)
    VFXLibrary.spawn("magic_lightning", impact, get_tree().current_scene, normal, direction, 1.25)
    VFXLibrary.spawn("magic_lightning", from + direction * minf(2.0, from.distance_to(impact) * 0.5), get_tree().current_scene, Vector3.UP, direction, 0.55)
    return true

func _cast_heal(data: Dictionary, caster: CharacterBody3D) -> bool:
    var before := GameState.health
    GameState.health = minf(GameState.max_health, GameState.health + float(data.get("heal", 0.0)))
    GameState.survival_changed.emit()
    VFXLibrary.spawn("magic_heal", caster.global_position + Vector3.UP, get_tree().current_scene, Vector3.UP, Vector3.ZERO, 1.2)
    GameState.notify("Лечение: +%.0f HP." % (GameState.health - before))
    return true

func _cast_shield(data: Dictionary, caster: CharacterBody3D) -> bool:
    GameState.add_magic_shield(float(data.get("shield", 0.0)))
    VFXLibrary.spawn("magic_shield", caster.global_position + Vector3.UP * 0.9, get_tree().current_scene, Vector3.UP, Vector3.ZERO, 1.35)
    return true

func _cast_zone(data: Dictionary, caster: CharacterBody3D, camera: Camera3D) -> bool:
    var host := get_tree().current_scene
    if host == null:
        return false
    var target := _target_position(caster, camera, float(data.get("range", 15.0)))
    var zone = ZONE_SCRIPT.new()
    host.add_child(zone)
    zone.global_position = target
    zone.setup(data, caster)
    return true

func _cast_burst(data: Dictionary, caster: CharacterBody3D, camera: Camera3D) -> bool:
    var target := _target_position(caster, camera, float(data.get("range", 18.0)))
    var radius := float(data.get("radius", 3.5))
    VFXLibrary.spawn("magic_arcane", target, get_tree().current_scene, Vector3.UP, Vector3.ZERO, 1.55)
    _apply_area_damage(target, radius, float(data.get("damage", 0.0)), "", 0.0, caster)
    return true

func _cast_blink(data: Dictionary, caster: CharacterBody3D, camera: Camera3D) -> bool:
    var forward := -camera.global_transform.basis.z
    forward.y = 0.0
    if forward.length_squared() <= 0.001:
        forward = -caster.global_transform.basis.z
        forward.y = 0.0
    forward = forward.normalized()

    var start := caster.global_position
    var desired := start + forward * float(data.get("range", 8.0))
    var query := PhysicsRayQueryParameters3D.create(start + Vector3.UP * 0.7, desired + Vector3.UP * 0.7)
    query.exclude = [caster.get_rid()]
    var hit := caster.get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        desired = hit.get("position", desired) - forward * 0.85

    var xz := Vector2(desired.x, desired.z)
    if not WorldData.inside_world(xz):
        return false
    desired.y = WorldData.elevation_at(xz) + 1.2

    VFXLibrary.spawn("magic_portal", start + Vector3.UP * 0.8, get_tree().current_scene, Vector3.UP, forward, 1.0)
    caster.global_position = desired
    caster.velocity = Vector3.ZERO
    VFXLibrary.spawn("magic_portal", desired + Vector3.UP * 0.8, get_tree().current_scene, Vector3.UP, forward, 1.0)
    return true

func _target_position(caster: CharacterBody3D, camera: Camera3D, max_range: float) -> Vector3:
    var direction := -camera.global_transform.basis.z.normalized()
    var from := camera.global_position
    var to := from + direction * max_range
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [caster.get_rid()]
    var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        return hit.get("position", to) + Vector3.UP * 0.04
    var xz := Vector2(to.x, to.z)
    if WorldData.inside_world(xz):
        to.y = WorldData.elevation_at(xz) + 0.05
    return to

func resolve_projectile_hit(
        spell_id: String,
        element: String,
        damage: float,
        status_name: String,
        status_duration: float,
        explosion_radius: float,
        collider: Variant,
        hit_position: Vector3,
        hit_normal: Vector3,
        caster: Node3D
    ) -> void:
    if explosion_radius > 0.0:
        _apply_area_damage(hit_position, explosion_radius, damage, status_name, status_duration, caster)
        if element == "fire":
            VFXLibrary.spawn_explosion(hit_position, "small", get_tree().current_scene, 0.85)
        else:
            VFXLibrary.spawn_magic(element, hit_position, get_tree().current_scene, 1.0)
        return

    if collider != null and collider.has_method("take_damage"):
        collider.take_damage(damage, caster)
        if not status_name.is_empty() and collider.has_method("apply_status"):
            collider.apply_status(status_name, status_duration, caster)
    else:
        VFXLibrary.spawn_collision(_surface_from_element(element), hit_position, hit_normal, get_tree().current_scene, 0.8)

func _apply_area_damage(center: Vector3, radius: float, damage: float, status_name: String, status_duration: float, caster: Node3D) -> void:
    for hostile in get_tree().get_nodes_in_group("hostile"):
        if not is_instance_valid(hostile) or not (hostile is Node3D):
            continue
        var body := hostile as Node3D
        var distance := body.global_position.distance_to(center)
        if distance > radius:
            continue
        var factor := clampf(1.0 - (distance / maxf(radius, 0.01)) * 0.40, 0.60, 1.0)
        if body.has_method("take_damage"):
            body.take_damage(damage * factor, caster)
        if not status_name.is_empty() and body.has_method("apply_status"):
            body.apply_status(status_name, status_duration, caster)

func _surface_from_element(element: String) -> String:
    match element:
        "fire": return "stone"
        "frost": return "glass"
        "poison": return "dirt"
        "lightning": return "metal"
        _: return "stone"
