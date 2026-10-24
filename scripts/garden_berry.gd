extends StaticBody3D

const NATURE := preload("res://scripts/production_nature.gd")
const BUSH := preload("res://assets/production/nature/temperate/TemperateBush.glb")
const HARVESTS := 3
const REGROW_MINUTES := 2880.0
static var fruit_mesh: SphereMesh
var persistent_id := ""
var resource_id := "berries"
var uses := HARVESTS
var ready_at := -1.0
var revision := -1
var elapsed := 0.0
var fruit: MultiMeshInstance3D

func _ready() -> void:
    collision_layer = 2
    collision_mask = 0
    add_to_group("map_resource")
    add_to_group("garden_berry")
    var bush := BUSH.instantiate() as Node3D
    bush.scale = Vector3.ONE*0.6
    add_child(bush)
    NATURE.prepare(bush)
    for mesh: GeometryInstance3D in bush.find_children("*","GeometryInstance3D",true,false):
        mesh.visibility_range_end = 65.0
        mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.5
    capsule.height = 1.1
    shape.shape = capsule
    shape.position.y = 0.55
    add_child(shape)
    if fruit_mesh==null:
        fruit_mesh = SphereMesh.new()
        fruit_mesh.radius = 0.045
        fruit_mesh.height = 0.09
        fruit_mesh.radial_segments = 10
        fruit_mesh.rings = 5
        var material := StandardMaterial3D.new()
        material.albedo_color = Color(0.4,0.06,0.09)
        material.roughness = 0.72
        fruit_mesh.material = material
    var data := MultiMesh.new()
    data.transform_format = MultiMesh.TRANSFORM_3D
    data.mesh = fruit_mesh
    data.instance_count = HARVESTS*2
    for i in range(HARVESTS*2):
        var angle := float(i)*TAU/float(HARVESTS*2)
        data.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(cos(angle)*0.25,0.65+0.12*sin(angle*2),sin(angle)*0.25)))
    fruit = MultiMeshInstance3D.new()
    fruit.multimesh = data
    fruit.visibility_range_end = 28.0
    fruit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(fruit)
    restore()

func _process(delta: float) -> void:
    elapsed += delta
    if elapsed<0.5:return
    elapsed = 0.0
    if revision!=GameState.state_revision or (uses<=0 and ready_at>=0 and _now()>=ready_at): restore()

func _now() -> float:
    return float(GameState.world_day)*1440.0+GameState.world_minutes

func restore() -> void:
    revision = GameState.state_revision
    var raw: Variant = GameState.get_world_value("garden:"+persistent_id,{})
    var saved: Dictionary = raw if raw is Dictionary else {}
    var count: Variant = saved.get("remaining",HARVESTS)
    uses = int(clampf(float(count),0,HARVESTS)) if (count is int or count is float) and is_finite(float(count)) else HARVESTS
    var deadline: Variant = saved.get("ready_at",-1.0)
    ready_at = float(deadline) if (deadline is int or deadline is float) and is_finite(float(deadline)) else -1.0
    if uses<=0 and ready_at>=0 and _now()>=ready_at:
        uses = HARVESTS
        ready_at = -1
        _save()
    fruit.multimesh.visible_instance_count = uses*2
    set_deferred("collision_layer",2 if uses>0 else 0)

func _save() -> void:
    GameState.set_world_value("garden:"+persistent_id,{"remaining":uses,"ready_at":ready_at})

func interact(actor: Node3D) -> void:
    restore()
    if actor==null or uses<=0:return
    var origin := actor.global_position+Vector3.UP*0.8
    var target := global_position+Vector3.UP*0.65
    if origin.distance_to(target)>2.7:return
    var excluded: Array[RID] = []
    if actor is CollisionObject3D:excluded.append(actor.get_rid())
    var query := PhysicsRayQueryParameters3D.create(origin,target,3,excluded)
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.get("collider")!=self:return
    GameState.add_item("berries",1)
    uses -= 1
    if uses==0:ready_at = _now()+REGROW_MINUTES
    _save()
    fruit.multimesh.visible_instance_count = uses*2
    if uses==0:set_deferred("collision_layer",0)
    GameState.notify("Собраны ягоды +1." if uses>0 else "Ягоды собраны. Новый урожай созреет через два игровых дня.")
