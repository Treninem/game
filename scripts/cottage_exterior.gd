extends RefCounted

const KIT := preload("res://scripts/cottage_yard_assets.gd")

static func build(home: Node3D) -> void:
    if home.has_node("CottageExterior"):return
    var root := Node3D.new()
    root.name = "CottageExterior"
    home.add_child(root)
    var half: Vector2 = home.get("footprint")*0.5
    var height: float = home.get("wall_height")
    var door_half: float = home.get("doorway_width")*0.5
    var beams: Array[Transform3D] = []
    var stone: Array[Transform3D] = []
    # Corner posts and wall plates describe the construction outside the plaster.
    for x in [-half.x,half.x]:
        for z in [-half.y,half.y]:
            beams.append(KIT.beam(Vector3(x,0.22,z),Vector3(x,height,z)))
            KIT.collision(root,"CornerPost",Transform3D(Basis.IDENTITY,Vector3(x,(height+0.22)*0.5,z)),Vector3(.16,height-.22,.16))
        for y in [0.48,height-0.08]:
            beams.append(KIT.beam(Vector3(x,y,-half.y),Vector3(x,y,half.y)))
    for z in [-half.y,half.y]:
        beams.append(KIT.beam(Vector3(-half.x,height-0.08,z),Vector3(half.x,height-0.08,z)))
        for x in [-half.x*0.5,half.x*0.5]:
            # Back studs must avoid both actual window openings. Front has only
            # a central doorway, so its side panels can carry full uprights.
            if z>0: beams.append(KIT.beam(Vector3(x,0.48,z),Vector3(x,height-0.08,z),0.8))
        if z>0:
            for sign_value in [-1,1]:
                var x: float = sign_value*(door_half+0.13)
                beams.append(KIT.beam(Vector3(x,0.18,z+0.035),Vector3(x,2.45,z+0.035),0.85))
                KIT.collision(root,"DoorJamb",Transform3D(Basis.IDENTITY,Vector3(x,1.315,z+.035)),Vector3(.136,2.27,.136))
            beams.append(KIT.beam(Vector3(-door_half-0.2,2.44,z+0.035),Vector3(door_half+0.2,2.44,z+0.035),0.9))
        else: beams.append(KIT.beam(Vector3(-half.x,0.48,z),Vector3(half.x,0.48,z)))
        # A king post, collar and rafters articulate the existing tall attic.
        var base := height+0.03
        beams.append(KIT.beam(Vector3(-half.x,base,z),Vector3(0,base+5.5,z),0.95))
        beams.append(KIT.beam(Vector3(half.x,base,z),Vector3(0,base+5.5,z),0.95))
        beams.append(KIT.beam(Vector3(0,base,z),Vector3(0,base+5.45,z),0.9))
        beams.append(KIT.beam(Vector3(-half.x*0.66,base+1.8,z),Vector3(half.x*0.66,base+1.8,z),0.8))
    for side in [-1,1]:
        # Small diagonal knee braces stay above the glazed openings.
        for z in [-half.y,half.y]:
            beams.append(KIT.beam(Vector3(side*half.x, height-0.8,z),Vector3(side*(half.x-0.65),height-0.08,z),0.7))
    var planters: Array[Transform3D] = []
    var flowers: Array[Transform3D] = []
    for light: SpotLight3D in home.get("window_lights"):
        var frame := (light.get_parent() as Node3D).transform
        var outward := -frame.basis.z.normalized()
        var point := frame.origin-Vector3.UP*(float(home.get("window_height"))*0.5+0.27)+outward*(float(home.get("wall_thickness"))*0.5+0.19)
        planters.append(Transform3D(frame.basis,point))
        KIT.collision(root,"WindowBox",Transform3D(frame.basis,point+Vector3.UP*.135),Vector3(1.6,.27,.32))
        for x: float in [-.53,.53]:
            var support := point+frame.basis.x*x
            beams.append(KIT.beam(support-outward*.22,support+outward*.05,0.45))
        for x: float in [-.48,0,.48]:
            flowers.append(Transform3D(frame.basis.scaled(Vector3.ONE*.6),point+frame.basis.x*x+Vector3.UP*.26))
    KIT.batch(root,"WindowPlanter",planters,110)
    KIT.batch(root,"MeadowFlowers",flowers,48,false)
    KIT.batch(root,"TimberBeam",beams)
    # Short courses follow the actual foot of each wall; front door stays open.
    for side in range(4):
        var a: Vector2
        var b: Vector2
        match side:
            0:a=Vector2(-half.x,-half.y);b=Vector2(half.x,-half.y)
            1:a=Vector2(-half.x,-half.y);b=Vector2(-half.x,half.y)
            2:a=Vector2(half.x,-half.y);b=Vector2(half.x,half.y)
            _:a=Vector2(-half.x,half.y);b=Vector2(half.x,half.y)
        var count := ceili(a.distance_to(b))
        for i in range(count):
            var start := a.lerp(b,float(i)/count)
            var finish := a.lerp(b,float(i+1)/count)
            if side==3 and start.x<door_half+0.2 and finish.x>-door_half-0.2:continue
            var p := (start+finish)*0.5
            var world := home.to_global(Vector3(p.x,0,p.y))
            var bottom := minf(0.02,WorldData.elevation_at(Vector2(world.x,world.z))-home.global_position.y-0.04)
            var rise := 0.42-bottom
            var x := Vector3(finish.x-start.x,0,finish.y-start.y).normalized()
            stone.append(Transform3D(Basis(x*start.distance_to(finish),Vector3.UP*rise,x.cross(Vector3.UP)),Vector3(p.x,bottom,p.y)))
            KIT.collision(root,"StoneBase",Transform3D(Basis(x,Vector3.UP,x.cross(Vector3.UP)),Vector3(p.x,bottom+rise*.5,p.y)),Vector3(start.distance_to(finish),rise,.18))
    KIT.batch(root,"StoneCourse",stone)
    # Root-scale mirrors the actual room envelope, without replacing collision
    # walls, working windows, door IDs or indoor furnishing/support geometry.
    root.set_meta("source_kit","CottageYardKit")
    root.set_meta("beam_members",beams.size())
    root.set_meta("stone_courses",stone.size())
