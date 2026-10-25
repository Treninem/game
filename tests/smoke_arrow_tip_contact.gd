extends SceneTree

class DamageTarget extends StaticBody3D:
    var received := 0.0
    var hits := 0
    func take_damage(amount: float, _source: Node) -> void:
        received += amount
        hits += 1

var failures: Array[String] = []
var samples: Array = []

func _initialize() -> void:
    call_deferred("_run")

func _shape(body: CollisionObject3D, size: Vector3) -> void:
    var collision := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = size
    collision.shape = box
    body.add_child(collision)

func _run() -> void:
    create_timer(90).timeout.connect(func():push_error("ARROW_TIP_CONTACT timeout");quit(1))
    # Deterministic physics fixtures; explicit projectile ticks and placements
    # isolate continuous tip contact. These are not a manual gameplay journey.
    var world := Node3D.new()
    root.add_child(world)
    current_scene = world
    var caster := CharacterBody3D.new()
    _shape(caster,Vector3(.5,1.8,.5))
    world.add_child(caster)
    caster.position=Vector3(0,2,0)
    for entry: Array in [[.02,1.0/60,Vector3.FORWARD],[.35,1.0/60,Vector3.FORWARD],[.70,1.0/60,Vector3.FORWARD],[.80,1.0/60,Vector3.FORWARD],[1.20,1.0/60,Vector3.FORWARD],[2.4,1.0/60,Vector3.FORWARD],[6.0,1.0/15,Vector3.FORWARD],[2.0,1.0/120,Vector3(.6,.4,-.7).normalized()],[2.0,1.0/60,Vector3.UP],[2.0,1.0/60,Vector3.DOWN]]:
        var distance: float=entry[0]
        var step: float=entry[1]
        var heading: Vector3=entry[2]
        var target := DamageTarget.new()
        _shape(target,Vector3(20,20,.002))
        world.add_child(target)
        var up:=Vector3.FORWARD if absf(heading.dot(Vector3.UP))>.999 else Vector3.UP
        target.transform=Transform3D(Basis.looking_at(heading,up),caster.position+heading*distance)
        await physics_frame
        await physics_frame
        var arrow := load("res://scripts/weapon_projectile.gd").new() as Node3D
        world.add_child(arrow)
        arrow.set_physics_process(false)
        arrow.position=caster.position
        arrow.call("setup",caster,heading)
        var ticks:=0
        var penetrated:=false
        while not arrow.is_queued_for_deletion() and ticks<180:
            arrow.call("_physics_process",step)
            ticks+=1
            if arrow.is_queued_for_deletion():break
            # Independent endpoint on the actual render hierarchy, including
            # the imported scene transform: do not trust SHAFT_LENGTH or a
            # production helper to verify its own collision offset.
            var furthest: float=-INF
            var tip := Vector3.ZERO
            for node: MeshInstance3D in arrow.find_children("*","MeshInstance3D",true,false):
                var mesh:=node.mesh as ArrayMesh
                for surface in range(mesh.get_surface_count()):
                    var vertices: PackedVector3Array=mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
                    for vertex in vertices:
                        var point:=node.to_global(vertex)
                        var advance:=heading.dot(point-caster.position)
                        if advance>furthest:furthest=advance;tip=point
            if furthest>distance+.002:
                penetrated=true
                failures.append("Rendered arrow crossed a thin target before contact: distance=%.3f step=%.6f tip=%.4f" % [distance,step,furthest])
                break
        if not arrow.is_queued_for_deletion() or target.hits!=1 or not is_equal_approx(target.received,20):
            failures.append("Arrow failed exactly-once damage at %.3fm: hits=%d damage=%.2f ticks=%d" % [distance,target.hits,target.received,ticks])
        if distance<=1.20 and ticks!=1:
            failures.append("Initial shaft span was not covered on its first tick")
        samples.append({"distance_m":distance,"step_s":step,"heading":str(heading),"ticks":ticks,"hits":target.hits,"damage":target.received,"penetrated":penetrated})
        arrow.queue_free()
        target.queue_free()
        await process_frame
    # Free flight keeps the existing ballistics and bounded lifetime.
    var free_arrow:=load("res://scripts/weapon_projectile.gd").new() as Node3D
    world.add_child(free_arrow)
    free_arrow.set_physics_process(false)
    free_arrow.position=Vector3(0,40,0)
    free_arrow.call("setup",caster,Vector3.FORWARD)
    for i in range(60):free_arrow.call("_physics_process",1.0/60)
    if absf(free_arrow.position.z+35)>0.001 or absf(float(free_arrow.get("velocity").y)+4.9)>0.001:
        failures.append("Tip fix changed arrow speed or gravity")
    for i in range(122):free_arrow.call("_physics_process",1.0/60)
    if not free_arrow.is_queued_for_deletion():failures.append("Arrow exceeded its three-second lifetime")
    var orphan:=load("res://scripts/weapon_projectile.gd").new() as Node3D
    var temporary:=CharacterBody3D.new()
    world.add_child(temporary)
    world.add_child(orphan)
    orphan.set_physics_process(false)
    orphan.call("setup",temporary,Vector3.ZERO)
    temporary.free()
    orphan.call("_physics_process",1.0/60)
    if not orphan.is_queued_for_deletion():failures.append("Invalid caster left an orphaned projectile")
    var report:={"samples":samples,"failures":failures,"manual_gameplay":false,"fixture_transform_edits":true,"actual_production_mesh_endpoints":true,"ballistic_speed":35,"gravity":4.9,"damage":20}
    var file:=FileAccess.open("user://arrow-tip-contact.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "));file.close()
    print("ARROW_TIP_CONTACT_REPORT ",JSON.stringify(report))
    for failure in failures:push_error(failure)
    world.queue_free()
    await process_frame
    quit(0 if failures.is_empty() else 1)
