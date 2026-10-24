class_name SettlementNPC
extends CharacterBody3D

const PUBLIC_SEATING := preload("res://scripts/public_seating.gd")
const HUMANOID := preload("res://scripts/humanoid_visual.gd")
const RUNTIME_STATE := preload("res://scripts/citizen_runtime_state.gd")

@export var display_name := "Житель"
@export var role := "resident"
@export var move_speed := 1.45
@export var palette_index := 0
@export var autonomous := false
@export_enum("male", "female") var body_sex := "male"

var route_points_local: Array[Vector3] = []
var route_index := 0
var pause_elapsed := 0.0
var visual: Node3D
var ground_ready := false
var activity := ""
var routine_phase := ""
var talking_to_player := false
var citizen_id := ""
var avoid_elapsed := 0.0
var avoid_heading := Vector3.ZERO
var home_crossing := false
var used_furniture: Node3D
var household_elapsed := 0.0
var witnessed_pause := 0.0
var authored_position := Vector3.ZERO
var authored_yaw := 0.0
var authored_route_index := 0
var state_revision := -1
const SHOP_PRICES := {"berries": 2, "water_flask": 3, "arrow": 1, "starter_axe": 12}

func configure(name_value: String, role_value: String, palette_value: int, route_points: Array) -> void:
    display_name = name_value
    role = role_value
    palette_index = palette_value
    route_points_local.clear()
    for point in route_points:
        if point is Vector3:
            route_points_local.append(point)

func _ready() -> void:
    # Legacy civilian routes described four patrol corners. Civilians now use
    # time-of-day destinations; only watchmen keep their authored patrol route.
    if role != "watch" and route_points_local.size() >= 2:
        autonomous = true
    add_to_group("settlement_npc")
    if role == "watch":
        add_to_group("ally")
    collision_layer = 1
    collision_mask = 1
    # At capital coordinates the default millimetre recovery margin is close
    # to float precision. A two-centimetre capsule margin separates grazing
    # masonry contacts instead of pinning a resident to a bevel indefinitely.
    # Keep this recovery margin independent of the adult stature and capsule size.
    safe_margin = 0.02
    floor_snap_length = 0.35
    floor_max_angle = deg_to_rad(48.0)
    up_direction = Vector3.UP
    citizen_id = String(get_meta("citizen_id", "%s:%s:%d:%d" % [display_name, role, roundi(global_position.x), roundi(global_position.z)]))
    _build_collision()
    _build_visual()
    authored_position = position
    authored_yaw = rotation.y
    authored_route_index = route_index
    restore_runtime_state()
    DialogueManager.dialogue_closed.connect(_end_conversation)
    MagicSystem.spell_cast.connect(_witness_spell)

func _physics_process(delta: float) -> void:
    if state_revision != GameState.state_revision:
        # Old scene teardown must never repopulate a freshly reset new game.
        if GameState.state_transition_kind != "load":
            return
        restore_runtime_state()
    var xz := Vector2(global_position.x, global_position.z)
    var terrain_y := WorldData.elevation_at(xz)
    if not ground_ready or global_position.y < terrain_y - 0.5:
        ground_ready = _wait_for_ground(terrain_y)
        if not ground_ready:
            return
    if talking_to_player and DialogueManager.is_open:
        velocity = Vector3.ZERO
        return
    witnessed_pause = maxf(0.0, witnessed_pause - delta)

    if not is_on_floor():
        velocity.y -= 18.0 * delta
    elif velocity.y < 0.0:
        velocity.y = -0.15

    if autonomous:
        _follow_routine(delta)
        return

    if route_points_local.size() < 2:
        velocity.x = move_toward(velocity.x, 0.0, delta * 7.0)
        velocity.z = move_toward(velocity.z, 0.0, delta * 7.0)
        move_and_slide()
        return

    if pause_elapsed > 0.0:
        pause_elapsed = maxf(0.0, pause_elapsed - delta)
        velocity.x = move_toward(velocity.x, 0.0, delta * 6.0)
        velocity.z = move_toward(velocity.z, 0.0, delta * 6.0)
        move_and_slide()
        return

    var parent_3d := get_parent() as Node3D
    if parent_3d == null:
        return
    var target := parent_3d.to_global(route_points_local[route_index])
    var flat_delta := target - global_position
    flat_delta.y = 0.0
    if flat_delta.length() <= 0.75:
        route_index = (route_index + 1) % route_points_local.size()
        pause_elapsed = 0.7 + float((palette_index + route_index) % 4) * 0.35
        velocity.x = 0.0
        velocity.z = 0.0
        move_and_slide()
        return

    var direction := flat_delta.normalized()
    velocity.x = move_toward(velocity.x, direction.x * move_speed, delta * 5.5)
    velocity.z = move_toward(velocity.z, direction.z * move_speed, delta * 5.5)
    rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 7.0))
    move_and_slide()

func routine_plan(minutes: float) -> Dictionary:
    var hour := fmod(minutes / 60.0, 24.0)
    var side := -1.0 if name.ends_with("0") else 1.0
    var home := Vector3(28.0 * side, 0, 16.0 * side)
    var work := home if role == "craftsman" else Vector3(12.0 * side, 0, -12.0 * side)
    if role == "trader":
        work = Vector3(9, 0, -12)
    var places: Dictionary = get_meta("routine_places", {})
    home = places.get("home", home)
    work = places.get("work", work)
    if hour < 6.0 or hour >= 21.0:
        return {"phase": "home", "target": home, "activity": "Отдыхает у дома", "walking": "Идёт домой"}
    if hour >= 12.0 and hour < 14.0:
        return {"phase": "meal", "target": places.get("meal", Vector3(12 * side, 0, 12)), "activity": "Обедает", "walking": "Идёт на обед"}
    if hour >= 18.0:
        return {"phase": "social", "target": places.get("social", Vector3(1.3 * side, 0, 12)), "activity": "Общается", "walking": "Идёт на встречу"}
    if role == "traveler":
        return {"phase": "travel_morning" if hour < 12 else "travel_afternoon", "target": Vector3(0, 0, 156 if hour < 12 else -156), "activity": "Остановился в пути", "walking": "Путешествует"}
    return {"phase": "work", "target": work, "activity": "Торгует" if role == "trader" else "Ремонтирует" if role == "craftsman" else "На работе", "walking": "Идёт на работу"}

func _follow_routine(delta: float) -> void:
    var plan := routine_plan(GameState.world_minutes)
    if plan.phase == "work" and has_meta("work_shop_id"):
        # Production starts at the surface, not at the old loose social radius.
        plan.arrival_radius = 0.08
    plan = _home_route(plan)
    plan = _work_approach(plan)
    plan = _household_plan(plan)
    plan = PUBLIC_SEATING.plan(self,plan)
    plan = _route_home_rooms(plan)
    # A commute is a goal too. Use the same measured obstacle grid as public
    # seating, including the entire bridge approach, rather than leaving the
    # deck diagonally through a parapet. Interior/door crossing has its own
    # geometry planner and must not use the exterior grid's closed-door sample.
    var navigation:=get_parent().get_node_or_null("PublicSpaceNavigation")
    if navigation!=null and bool(navigation.get_meta("commute_navigation",false)) and not home_crossing and not bool(plan.get("indoor_path",false)):
        var destination:Vector3=get_parent_node_3d().to_global(plan.target)
        if navigation.contains(global_position) and navigation.contains(destination):
            var point:Vector3=navigation.next_point(global_position,destination,self)
            if Vector2(point.x-destination.x,point.z-destination.z).length()>.02:
                plan.target=get_parent_node_3d().to_local(point)
                plan.erase("furniture");plan.erase("public_furniture")
                plan.arrival_radius=.08
                plan.navigation_pending=true
                plan.measured_public_link=true
            plan.indoor_path=true
    var target: Vector3 = get_parent_node_3d().to_global(plan.target)
    var flat := target - global_position
    flat.y = 0
    var arrived := flat.length() < float(plan.get("arrival_radius", 0.75)) and not bool(plan.get("navigation_pending",false))
    activity = String(plan.activity if arrived else plan.walking)
    if witnessed_pause > 0.0:
        _leave_furniture()
        activity = "Осторожно! Не колдуйте рядом с людьми."
        velocity.x = move_toward(velocity.x, 0.0, delta * 8.0)
        velocity.z = move_toward(velocity.z, 0.0, delta * 8.0)
        set_meta("activity", "idle")
        move_and_slide()
        return
    set_meta("activity", "work" if arrived and plan.phase == "work" and role == "craftsman" else "social" if arrived and plan.phase == "social" else "idle")
    set_meta("work_pose", "WorkStanding" if plan.phase == "work" and has_meta("work_shop_id") else "Working")
    if routine_phase != plan.phase:
        routine_phase = plan.phase
        var saved_record: Variant = GameState.get_world_value("citizen:" + citizen_id, {})
        var record: Dictionary = saved_record.duplicate(true) if saved_record is Dictionary else {}
        record["phase"] = routine_phase
        record["role"] = role
        GameState.set_world_value("citizen:" + citizen_id, record)
    if not arrived:
        HouseholdFurniture.clear_pose(self, visual)
    if arrived:
        if plan.has("furniture"):
            _use_household(plan.furniture, delta)
        elif plan.has("public_furniture"):
            PUBLIC_SEATING.use(self,plan.public_furniture,delta)
        velocity.x = move_toward(velocity.x, 0.0, delta * 6.0)
        velocity.z = move_toward(velocity.z, 0.0, delta * 6.0)
        if plan.phase == "work" and has_meta("work_facing"):
            var toward_work: Vector3 = get_meta("work_facing") - plan.target
            rotation.y = lerp_angle(rotation.y, atan2(-toward_work.x, -toward_work.z), minf(1.0, delta * 5.0))
            var crafting := _workbench_step(delta)
            if has_meta("work_shop_id"):
                activity = "Изготавливает стрелы" if crafting else "Ждёт материалы у верстака"
                set_meta("activity", "work" if crafting else "idle")
        if plan.phase == "social" and not plan.has("public_furniture"):
            for other: Node3D in get_tree().get_nodes_in_group("settlement_npc"):
                if other != self and global_position.distance_squared_to(other.global_position) < 16.0:
                    var toward := other.global_position - global_position
                    rotation.y = lerp_angle(rotation.y, atan2(-toward.x, -toward.z), delta * 3.0)
                    break
    else:
        var waypoint:=Vector2(target.x,target.z)
        if not bool(plan.get("indoor_path",false)):
            waypoint=preload("res://scripts/capital_canal_data.gd").navigation_target(Vector2(global_position.x,global_position.z),waypoint)
        var desired:=Vector3(waypoint.x-global_position.x,0,waypoint.y-global_position.z).normalized()
        var lookahead:=0.5 if plan.get("indoor_path",false) else 1.8
        # A snapped public anchor may be only centimetres away. Steering must
        # not inspect beyond that verified corner and turn away from the goal.
        if bool(plan.get("measured_public_link",false)):lookahead=minf(lookahead,flat.length())
        var direction := _routine_direction(desired,delta,lookahead)
        velocity.x = move_toward(velocity.x, direction.x * move_speed, delta * 5.5)
        velocity.z = move_toward(velocity.z, direction.z * move_speed, delta * 5.5)
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 7.0))
    move_and_slide()

func _exit_tree() -> void:
    capture_runtime_state()

func capture_runtime_state() -> void:
    if not is_instance_valid(GameState) or state_revision != GameState.state_revision or not ground_ready:
        return
    if not has_meta("citizen_id") or citizen_id.is_empty() or not is_inside_tree():
        return
    var parent := get_parent_node_3d()
    if parent == null:
        return
    var anchor := parent.global_position
    if is_instance_valid(visual):
        GameState.set_world_value("appearance:" + citizen_id, visual.current_profile.duplicate(true))
    GameState.set_world_value("citizen:" + citizen_id, {
        "runtime_version": 1, "capital_canals_revision":1, "role": role, "phase": routine_phase,
        "anchor": [anchor.x, anchor.y, anchor.z],
        "position": [position.x, position.y, position.z], "yaw": rotation.y,
        "home_crossing": home_crossing, "route_index": route_index,
        "pause_elapsed": pause_elapsed, "witnessed_pause": witnessed_pause
    })

func restore_runtime_state() -> void:
    _leave_furniture(false)
    state_revision = GameState.state_revision
    if not has_meta("citizen_id") or citizen_id.is_empty():
        return
    var saved_appearance = GameState.get_world_value("appearance:" + citizen_id)
    if typeof(saved_appearance) == TYPE_DICTIONARY and is_instance_valid(visual):
        visual.call("apply_appearance", saved_appearance)
    var decoded := RUNTIME_STATE.decode(GameState.get_world_value("citizen:" + citizen_id), get_parent_node_3d().global_position, authored_position, role)
    position = decoded.get("position", authored_position)
    var old_record:Variant=GameState.get_world_value("citizen:"+citizen_id,{})
    if old_record is Dictionary and not preload("res://scripts/capital_canal_data.gd").has_current_revision(old_record.get("capital_canals_revision",0)):
        global_position=preload("res://scripts/capital_canal_data.gd").legacy_bridge_position(global_position)
    rotation.y = float(decoded.get("yaw", authored_yaw))
    home_crossing = bool(decoded.get("home_crossing", false))
    route_index = clampi(int(decoded.get("route_index", authored_route_index)), 0, maxi(0, route_points_local.size() - 1))
    pause_elapsed = float(decoded.get("pause_elapsed", 0.0))
    witnessed_pause = float(decoded.get("witnessed_pause", 0.0))
    avoid_elapsed = 0.0
    routine_phase = ""
    ground_ready = false
    velocity = Vector3.ZERO
    visual.visible = false

func _home_route(plan: Dictionary) -> Dictionary:
    if not has_meta("home_building"):
        return plan
    var home := get_parent().get_node_or_null(String(get_meta("home_building"))) as EnterableBuilding
    if home == null:
        return plan
    if plan.phase == "home":
        GameState.set_world_value("commute:" + citizen_id, 0)
    var local := home.to_local(global_position)
    var front := home.footprint.y * 0.5
    var inside := absf(local.x) < home.footprint.x * 0.5 and local.z < front - 1.0 and local.z > -front
    var approach := home.position + Vector3(0, 0, front + 2.0)
    var owner_id := int(home.get_meta("door_user", 0))
    var owner := instance_from_id(owner_id) if owner_id != 0 else null
    var needs_crossing: bool = (plan.phase == "home" and not inside) or (plan.phase != "home" and (inside or home_crossing))
    if needs_crossing and is_instance_valid(owner) and owner != self:
        # A single narrow entrance is a shared resource. Wait away from the
        # threshold instead of two avoidance rays deadlocking face to face.
        plan.target = home.position + Vector3(-2.5 if role == "trader" else 2.5, 0, front - 2.8 if inside else front + 3.0)
        plan.phase = "door_wait"
        plan.activity = "Пропускает соседа в дверях"
        plan.walking = "Освобождает проход"
        return plan
    if plan.phase == "home" and not inside:
        var to_approach := Vector2(local.x, local.z - front - 2.0).length()
        if to_approach < 0.8:
            home_crossing = true
        if home_crossing:
            home.set_meta("door_user", get_instance_id())
            home.set_meta("auto_close", true)
            home.front_door.set_open(true)
            plan.target = home.position + Vector3(0, 0, front - 1.8)
        else:
            plan.target = approach
        plan.walking = "Идёт домой"
        plan.activity = "Открывает дверь"
    elif plan.phase != "home" and (inside or home_crossing):
        home_crossing = true
        home.set_meta("door_user", get_instance_id())
        home.set_meta("auto_close", true)
        home.front_door.set_open(true)
        plan.target = approach
        if local.z < front + 1.0 and absf(local.x) > 0.18:
            plan.target = home.position + Vector3(0, 0, clampf(local.z, -front + 2.0, front - 2.0))
            plan.arrival_radius = 0.1
        plan.walking = "Выходит из дома"
        # Routine arrival accepts a 0.75 m radius around the +2 m approach.
        # Release before that stopping radius, after clearing the actual leaf.
        if local.z > front + 1.0:
            home_crossing = false
            home.set_meta("door_user", 0)
    else:
        home_crossing = false
        if owner == self:
            home.set_meta("door_user", 0)
        if plan.phase == "home":
            plan.activity = "Отдыхает дома"
        # Leave the door open while anyone occupies the full swing/threshold.
        # Never swing it shut into the player or the other returning resident.
        var occupied := false
        for actor in get_tree().get_nodes_in_group("settlement_npc") + get_tree().get_nodes_in_group("player"):
            if actor is Node3D:
                var p := home.to_local(actor.global_position)
                if absf(p.x) < 2.2 and absf(p.z - front) < 2.5:
                    occupied = true
                    break
        if not occupied and bool(home.get_meta("auto_close", false)):
            home.front_door.set_open(false)
            home.set_meta("auto_close", false)
    return plan

func _witness_spell(spell_id: String) -> void:
    var actor := get_tree().get_first_node_in_group("player") as Node3D
    if actor == null or global_position.distance_squared_to(actor.global_position) > 144.0:
        return
    var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.5, actor.global_position + Vector3.UP * 1.1, 1, [get_rid()])
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty() and hit.collider != actor:
        return
    var memory: Dictionary = GameState.get_world_value("memory:" + citizen_id, {}).duplicate(true)
    memory["spell"] = spell_id
    GameState.set_world_value("memory:" + citizen_id, memory)
    if spell_id not in ["heal", "shield", "blink"]:
        witnessed_pause = 6.0

func _context_line() -> String:
    var memory: Dictionary = GameState.get_world_value("memory:" + citizen_id, {})
    var line := ""
    if int(memory.get("supplies", 0)) > 0:
        line += "Спасибо за материалы: вы уже продали мне %d ед. сырья. " % int(memory.supplies)
    if memory.has("spell"):
        line += "Помню ваше заклинание «%s». " % String(MagicSystem.SPELLS.get(String(memory.spell), {}).get("label", memory.spell))
    if not InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON).is_empty():
        line += "Осторожнее с оружием у прилавка. "
    return line

func _routine_direction(desired: Vector3, delta: float, lookahead: float = 1.8) -> Vector3:
    avoid_elapsed = maxf(0.0, avoid_elapsed - delta)
    if lookahead > 1.0 and avoid_elapsed > 0 and _routine_way_clear(avoid_heading, lookahead):
        return avoid_heading
    if _routine_way_clear(desired, lookahead):
        return desired
    for angle in [0.65, -0.65, 1.05, -1.05, 1.55, -1.55]:
        var candidate := desired.rotated(Vector3.UP, angle)
        if _routine_way_clear(candidate, lookahead):
            avoid_heading = candidate
            avoid_elapsed = 1.1
            return candidate
    return Vector3.ZERO

func _routine_way_clear(direction: Vector3, lookahead: float = 1.8) -> bool:
    var origin := global_position + Vector3.UP * 0.8
    var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * lookahead, 1, [get_rid()])
    return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _end_conversation() -> void:
    talking_to_player = false

func _workbench_step(delta: float) -> bool:
    if role != "craftsman" or not has_meta("work_shop_id"):
        return false
    # Waiting for a local path is not arrival at the actual work surface.
    var places:Dictionary=get_meta("routine_places",{})
    if not places.has("work") or not is_on_floor():return false
    var workplace:Vector3=get_parent_node_3d().to_global(places.work)
    if Vector2(workplace.x-global_position.x,workplace.z-global_position.z).length()>.10:return false
    var recipe_id := String(get_meta("work_recipe", ""))
    if not InventorySystem.RECIPES.has(recipe_id):
        return false
    var recipe: Dictionary = InventorySystem.RECIPES[recipe_id]
    var shop_key := "shop:" + String(get_meta("work_shop_id"))
    var stock: Dictionary = GameState.get_world_value(shop_key, {})
    for item: String in recipe.requirements:
        if int(stock.get(item, 0)) < int(recipe.requirements[item]):
            return false
    var progress_key := "workshop:" + citizen_id
    var progress := float(GameState.get_world_value(progress_key, 0.0)) + delta
    if progress >= 8.0:
        for item: String in recipe.requirements:
            stock[item] = int(stock[item]) - int(recipe.requirements[item])
        stock[recipe.result] = int(stock.get(recipe.result, 0)) + int(recipe.amount)
        GameState.set_world_value(shop_key, stock)
        progress = 0.0
    GameState.set_world_value(progress_key, progress)
    return true

func _shop_stock() -> Dictionary:
    var stock: Dictionary = GameState.get_world_value("shop:" + citizen_id, {"berries": 12, "water_flask": 8, "arrow": 30, "wood": 0})
    # Migrate existing shops once; an explicitly sold-out axe stays sold out.
    if not stock.has("starter_axe"):
        stock["starter_axe"] = 2
    if not stock.has("stone"):
        stock["stone"] = 0
    if not stock.has("coins"):
        stock["coins"] = 100
    return stock

func _open_shop() -> void:
    var stock := _shop_stock()
    var choices: Array = []
    for item: String in SHOP_PRICES:
        var label := String(InventorySystem.item_info(item).get("name", item))
        choices.append({"text": "%s — %d мон. (осталось %d)" % [label, SHOP_PRICES[item], stock.get(item, 0)], "action": "merchant_trade", "merchant": get_instance_id(), "item": item, "sell": false})
    choices.append({"text": "Продать древесину — 1 мон.", "action": "merchant_trade", "merchant": get_instance_id(), "item": "wood", "sell": true})
    choices.append({"text": "Продать камень — 1 мон.", "action": "merchant_trade", "merchant": get_instance_id(), "item": "stone", "sell": true})
    choices.append({"text": "До встречи.", "action": "close"})
    DialogueManager.open_dialogue(display_name, _context_line() + "Выберите товар. У вас %d монет, у меня %d." % [GameState.coins, int(stock.coins)], choices)

func complete_trade(item: String, sell: bool) -> bool:
    if role != "trader":
        return false
    if has_meta("home_building") and routine_plan(GameState.world_minutes).phase != "work":
        GameState.notify("Лавка закрыта. Приходите в рабочее время.")
        return false
    var stock := _shop_stock()
    var success := false
    if sell and item in ["wood", "stone"] and int(stock.coins) >= 1 and GameState.remove_item(item, 1):
        GameState.coins += 1
        stock.coins = int(stock.coins) - 1
        stock[item] = int(stock.get(item, 0)) + 1
        var memory: Dictionary = GameState.get_world_value("memory:" + citizen_id, {}).duplicate(true)
        memory["supplies"] = int(memory.get("supplies", 0)) + 1
        GameState.set_world_value("memory:" + citizen_id, memory)
        success = true
    elif not sell and SHOP_PRICES.has(item):
        var price := int(SHOP_PRICES[item])
        if GameState.coins >= price and int(stock.get(item, 0)) > 0:
            GameState.coins -= price
            stock.coins = int(stock.coins) + price
            stock[item] = int(stock[item]) - 1
            GameState.add_item(item, 1)
            success = true
    if success:
        GameState.set_world_value("shop:" + citizen_id, stock)
        GameState.inventory_changed.emit()
    else:
        GameState.notify("Не хватает монет у покупателя, товара или ресурса для продажи.")
    if talking_to_player:
        _open_shop()
    return success

func _wait_for_ground(terrain_y: float) -> bool:
    # Residents can stream in before the terrain physics chunk. Never let them
    # fall below the arriving mesh or display a person standing in empty air.
    terrain_y=preload("res://scripts/capital_canal_data.gd").supported_height(Vector2(global_position.x,global_position.z),global_position.y,terrain_y)
    var from := Vector3(global_position.x, terrain_y + 2.0, global_position.z)
    var to := Vector3(global_position.x, terrain_y - 2.0, global_position.z)
    var query := PhysicsRayQueryParameters3D.create(from, to, 1, [get_rid()])
    query.collide_with_areas = false
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    velocity = Vector3.ZERO
    if hit.is_empty() or not hit.get("collider") is StaticBody3D:
        visual.visible = false
        return false
    global_position.y = Vector3(hit["position"]).y + 0.04
    visual.visible = true
    return true

func interact(_player: Node) -> void:
    talking_to_player = true
    velocity.x = 0.0
    velocity.z = 0.0
    match role:
        "watch":
            DialogueManager.open_dialogue(display_name, "Ворота и дорога перед ними должны оставаться свободными. Проходите, но не стойте в проезде.", [{"text":"Понял.", "action":"close"}])
        "trader":
            if has_meta("home_building") and routine_plan(GameState.world_minutes).phase != "work":
                DialogueManager.open_dialogue(display_name, _context_line() + "Лавка закрыта. Торгую с 6 до 12 и с 14 до 18 часов; сейчас у меня личное время.", [{"text":"Зайду позже.", "action":"close"}])
            else:
                _open_shop()
        "craftsman":
            var line := "Продайте Марте древесину и камень: у верстака я делаю из них стрелы для её лавки." if has_meta("work_shop_id") else "Здесь всё приходится чинить руками: дома, ограды, телеги и инструмент."
            if has_meta("work_shop_id"):
                var stock: Dictionary = GameState.get_world_value("shop:" + String(get_meta("work_shop_id")), {})
                line += " Сейчас в лавке: древесина %d, камень %d, стрелы %d." % [int(stock.get("wood", 0)), int(stock.get("stone", 0)), int(stock.get("arrow", 30))]
            DialogueManager.open_dialogue(display_name, _context_line() + line, [{"text":"Ясно.", "action":"close"}])
        _:
            DialogueManager.open_dialogue(display_name, "Добрый день. Держитесь дороги — между домами проходы узкие.", [{"text":"До встречи.", "action":"close"}])

func _build_collision() -> void:
    var collision := CollisionShape3D.new()
    collision.name = "CollisionShape3D"
    collision.position = Vector3(0.0, 0.9, 0.0)
    var shape := CapsuleShape3D.new()
    shape.radius = 0.34
    shape.height = 1.8
    collision.shape = shape
    add_child(collision)

func apply_character_dimensions(height_cm:float) -> void:
    var appearance:=preload("res://scripts/character_appearance.gd")
    var height:=clampf(height_cm,appearance.MIN_HEIGHT_CM,appearance.MAX_HEIGHT_CM) if is_finite(height_cm) else appearance.DEFAULT_HEIGHT_CM
    var collider:=get_node_or_null("CollisionShape3D") as CollisionShape3D
    if collider==null:return
    var capsule:=collider.shape as CapsuleShape3D
    capsule.height=height/100.0;capsule.radius=.34*height/180.0
    collider.position.y=capsule.height*.5

func _build_visual() -> void:
    visual = HUMANOID.new()
    visual.name = "Visual"
    var palettes := [
        [Color(0.24,0.18,0.13), Color(0.42,0.31,0.20), Color(0.67,0.49,0.25)],
        [Color(0.15,0.25,0.18), Color(0.28,0.39,0.29), Color(0.55,0.66,0.42)],
        [Color(0.24,0.25,0.27), Color(0.35,0.37,0.40), Color(0.62,0.66,0.70)],
        [Color(0.27,0.18,0.28), Color(0.42,0.30,0.42), Color(0.66,0.50,0.65)],
        [Color(0.18,0.22,0.30), Color(0.29,0.34,0.43), Color(0.55,0.66,0.80)]
    ]
    var palette: Array = palettes[palette_index % palettes.size()]
    visual.primary_color = palette[0]
    visual.secondary_color = palette[1]
    visual.accent_color = palette[2]
    visual.skin_color = Color(0.66 + 0.035 * float(palette_index % 3), 0.49 + 0.02 * float(palette_index % 2), 0.37)
    visual.hair_color = Color(0.07 + 0.03 * float(palette_index % 3), 0.05, 0.035)
    visual.has_guard_armor = role == "watch"
    visual.has_hood = role == "trader"
    visual.has_apron = role == "craftsman"
    visual.palette_variant = palette_index % 3
    # Authored identity survives streaming; a model is not chosen by a random
    # node instance or a temporary palette index on reload.
    var appearance_id := "appearance:" + citizen_id
    var fallback := preload("res://scripts/character_appearance.gd").preset((5 if body_sex == "female" else 0) + palette_index % 5)
    # Identity, not scene order or a random frame, chooses an adult's stature.
    # Preserve explicit old looks; missing legacy heights remain180cm.
    fallback.height_cm=160.0+float(absi(citizen_id.hash())%41)
    visual.appearance_profile = preload("res://scripts/character_appearance.gd").normalized(GameState.get_world_value(appearance_id, fallback))
    add_child(visual)

func _household_plan(plan: Dictionary) -> Dictionary:
    if not has_meta("home_building"):
        return plan
    var home := get_parent().get_node_or_null(String(get_meta("home_building"))) as EnterableBuilding
    if home == null or plan.phase != "home" or home_crossing or home.to_local(global_position).z >= home.footprint.y * 0.5 - 1.0:
        if not is_instance_valid(used_furniture) or not used_furniture.is_in_group("public_rest_furniture"):
            _leave_furniture()
        if routine_plan(GameState.world_minutes).phase != "home":
            var record: Dictionary = _household_state()
            if float(record.get("seated_seconds", 0)) > 0 or float(record.get("seated_wait_seconds", 0)) > 0 or bool(record.get("clearing_storage", false)):
                record = record.duplicate(true)
                record.seated_seconds = 0
                record.seated_wait_seconds = 0
                record.clearing_storage = false
                GameState.set_world_value("household:" + citizen_id, record)
        return plan
    var saved := _household_state()
    if bool(saved.get("clearing_storage", false)):
        var storage_body := home.get_node_or_null("InteriorFurniture/StorageChest") as HouseholdFurniture
        if storage_body != null and storage_body.claim(citizen_id):
            used_furniture = storage_body
            var storage_local := home.to_local(global_position)
            var exit_point := Vector3(2.4, storage_local.y, -1.2) if role == "trader" else Vector3(2.2, storage_local.y, -2.92)
            var clearing := Vector2(storage_local.x - exit_point.x, storage_local.z - exit_point.z).length() > 0.25
            if home.has_node("HouseRooms"):
                # Keep the reservation only while physically clearing storage.
                # The next need supplies the goal; geometry supplies its path.
                var approach := home.to_local(storage_body.approach_point())
                clearing = Vector2(storage_local.x - approach.x, storage_local.z - approach.z).length() < 1.25
                var seat := home.get_node_or_null("InteriorFurniture/" + ("Bench" if role == "trader" or not home.has_node("InteriorFurniture/BenchSecond") else "BenchSecond")) as HouseholdFurniture
                if seat != null:
                    exit_point = home.to_local(seat.approach_point())
                    # Distance from the chest alone releases the queue while
                    # its user is still in the narrow table-side aisle. Keep
                    # ownership until the measured next approach is clear.
                    clearing=Vector2(storage_local.x-exit_point.x,storage_local.z-exit_point.z).length()>.25
            if clearing:
                plan.target = get_parent_node_3d().to_local(home.to_global(exit_point))
                plan.arrival_radius = 0.20
                plan.activity = "Освобождает место у сундука"
                plan.walking = plan.activity
                return plan
        saved.clearing_storage = false
        GameState.set_world_value("household:" + citizen_id, saved)
        _leave_furniture()
    var object_name := "Bed" if role == "trader" else "BedSecond"
    # Arrival drives finite household actions. Short clock windows used to expire
    # before a resident could physically walk home at the normal 4 min/s rate.
    if not bool(saved.get("stored", false)):
        object_name = "StorageChest"
    elif float(saved.get("seated_seconds", 0)) < 12.0:
        object_name = "Bench"
    if object_name == "Bench" and role != "trader" and home.has_node("InteriorFurniture/BenchSecond"):
        object_name = "BenchSecond"
    var furniture := home.get_node_or_null("InteriorFurniture/" + object_name) as HouseholdFurniture
    if furniture == null:
        return plan
    if is_instance_valid(used_furniture) and used_furniture != furniture:
        _leave_furniture()
    # Only one user per seat/container, with a clear waiting position.
    if not furniture.occupant.is_empty() and furniture.occupant != citizen_id:
        # Wait in the common hall, away from the chest-to-seat aisle.
        plan.target = home.position + Vector3(0, 0, 0.8)
        plan.activity = "Ждёт свободное место"
        return plan
    if not furniture.claim(citizen_id):
        return plan
    used_furniture = furniture
    var destination := home.to_local(furniture.approach_point())
    var local := home.to_local(global_position)
    var waypoint := destination
    # Side-wall furniture is reached via the clear central aisle rather than
    # steering straight through the dining table from chest to bench/bed.
    var aligning_lane := false
    if not home.has_node("HouseRooms") and absf(local.z - destination.z) > 0.85:
        # Clear both the resident and stationary hero capsules before moving
        # along the aisle. A broad lateral arrival radius left residents wedged
        # against the hero despite the authored lane itself being clear.
        var lane := 1.1 if furniture.kind == "chest" else 2.4 if object_name == "Bench" else -1.1
        aligning_lane = absf(local.x - lane) > 0.10
        waypoint = Vector3(lane, local.y, local.z) if aligning_lane else Vector3(lane, local.y, destination.z)
    plan.target = get_parent_node_3d().to_local(home.to_global(waypoint))
    plan.arrival_radius = 0.06 if aligning_lane else 0.28
    if waypoint.distance_to(destination) < 0.1:
        plan.furniture = furniture
        plan.arrival_radius = 0.65
    plan.activity = "Спит дома" if furniture.kind == "bed" else "Сидит дома" if furniture.kind == "bench" else "Убирает вещи в сундук"
    plan.walking = "Идёт к кровати" if furniture.kind == "bed" else "Идёт к скамье" if furniture.kind == "bench" else "Идёт к сундуку"
    if not plan.has("furniture"):
        plan.activity = "Проходит между мебелью"
    return plan

func _route_home_rooms(plan: Dictionary) -> Dictionary:
    if not has_meta("home_building"):
        return plan
    var home := get_parent().get_node_or_null(String(get_meta("home_building"))) as EnterableBuilding
    if home == null or not home.has_node("HouseRooms"):
        return plan
    var local := home.to_local(global_position)
    var destination := home.to_local(get_parent_node_3d().to_global(plan.target))
    var half := home.interior_size * 0.5
    if absf(local.x) > half.x or absf(local.z) > half.z or absf(destination.x) > half.x or absf(destination.z) > half.z:
        return plan
    var point: Vector3 = home.get_node("HouseRooms").waypoint(local, destination, self)
    plan.indoor_path = true
    if point.distance_to(destination) > 0.02:
        plan.erase("furniture")
        plan.target = get_parent_node_3d().to_local(home.to_global(point))
        plan.arrival_radius = 0.08
    return plan

func _use_household(furniture: HouseholdFurniture, delta: float) -> void:
    if not furniture.claim(citizen_id):
        return
    used_furniture = furniture
    if furniture.kind in ["bed", "bench"]:
        furniture.apply_rest_pose(self, visual)
        if furniture.kind == "bench":
            var key := "household:" + citizen_id
            var saved: Dictionary = _household_state()
            if _home_rest_companions_ready() or float(saved.get("seated_wait_seconds", 0)) >= 20.0:
                saved.seated_seconds = minf(12, maxf(0, float(saved.get("seated_seconds", 0))) + delta)
            else:
                saved.seated_wait_seconds = minf(20, float(saved.get("seated_wait_seconds", 0)) + delta)
            GameState.set_world_value(key, saved)
    else:
        set_meta("activity", "work")
        var toward := furniture.global_position - global_position
        rotation.y = atan2(-toward.x, -toward.z)
        var key := "household:" + citizen_id
        var saved: Dictionary = _household_state()
        var progress := clampf(float(saved.get("progress", 0)), 0, 3) + delta
        if not bool(saved.get("stored", false)) and progress >= 3 and furniture.free_capacity() > 0 and furniture.allows(citizen_id):
            # One authored personal berry, never minted again on reload/day loop.
            var items := furniture.contents()
            items.berries = int(items.get("berries", 0)) + 1
            var chest := furniture.state()
            chest.items = items
            GameState.set_world_value(furniture.furniture_id, chest)
            saved.personal_berries = 0
            saved.stored = true
            saved.clearing_storage = true
        saved.progress = minf(progress, 3)
        GameState.set_world_value(key, saved)
        if bool(saved.get("stored", false)):
            # Keep the exclusive reservation until the resident physically clears
            # the chest approach; the next user must not collide head-on here.
            set_meta("activity", "idle")

func _home_rest_companions_ready() -> bool:
    # A shared evening pause starts once the other present household member is
    # seated too. The saved 20-second bound prevents waiting for a blocked or
    # unavailable neighbour forever; furniture still remains exclusive.
    for child in get_parent().get_children():
        var other := child as SettlementNPC
        if other == null or other == self:
            continue
        if other.get_meta("home_building", "") != get_meta("home_building", ""):
            continue
        var other_state: Dictionary = other._household_state()
        if other.get_meta("activity", "idle") != "sit" and float(other_state.get("seated_seconds", 0)) < 12.0:
            return false
    return true

func _leave_furniture(write_state: bool = true) -> void:
    if write_state and state_revision == GameState.state_revision and is_inside_tree():
        for furniture in get_tree().get_nodes_in_group("household_furniture"):
            furniture.release(citizen_id)
    if is_instance_valid(used_furniture):
        if write_state and state_revision == GameState.state_revision:
            used_furniture.release(citizen_id)
        used_furniture = null
    if is_instance_valid(visual):
        HouseholdFurniture.clear_pose(self, visual)

func _work_approach(plan: Dictionary) -> Dictionary:
    if plan.phase != "work" or home_crossing or not has_meta("work_approach_path"):
        return plan
    var raw: Variant = GameState.get_world_value("commute:" + citizen_id, -1)
    var stage := clampi(int(raw), -1, 100) if RUNTIME_STATE._number(raw) else -1
    if stage < 0:
        return plan
    var home := get_parent().get_node_or_null(String(get_meta("home_building", ""))) as EnterableBuilding
    if home != null and home.to_local(global_position).z < home.footprint.y * 0.5 + 1:
        return plan
    var path: Array = get_meta("work_approach_path")
    if stage >= path.size():
        GameState.set_world_value("commute:" + citizen_id, -1)
        return plan
    var target: Vector3 = get_parent_node_3d().to_global(path[stage])
    if Vector2(target.x - global_position.x, target.z - global_position.z).length() < 0.65:
        stage += 1
        GameState.set_world_value("commute:" + citizen_id, stage if stage < path.size() else -1)
        if stage >= path.size():
            return plan
    plan.target = path[stage]
    plan.phase = "commute"
    plan.arrival_radius = 0.45
    plan.activity = "Возвращается к рабочему месту"
    plan.walking = "Идёт на работу"
    return plan

func _household_state() -> Dictionary:
    var value: Variant = GameState.get_world_value("household:" + citizen_id, {})
    var saved: Dictionary = value.duplicate(true) if value is Dictionary else {}
    saved.stored = saved.get("stored") is bool and bool(saved.get("stored"))
    saved.clearing_storage = saved.get("clearing_storage") is bool and bool(saved.get("clearing_storage"))
    saved.personal_berries = 0 if saved.stored else 1
    saved.progress = RUNTIME_STATE._bounded(saved.get("progress"), 3.0)
    saved.seated_seconds = RUNTIME_STATE._bounded(saved.get("seated_seconds"), 12.0)
    saved.seated_wait_seconds = RUNTIME_STATE._bounded(saved.get("seated_wait_seconds"), 20.0)
    return saved
