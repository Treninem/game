extends RefCounted
const CAPITAL:=preload("res://scripts/capital_data.gd")
const STREET:=preload("res://scripts/capital_streetscape.gd")
const COURT:=preload("res://scripts/cottage_yard_assets.gd")
static var planter_shape:Shape3D

static func build(root:Node3D)->void:
    var cell_center:=Vector2(root.global_position.x,root.global_position.z)
    if cell_center.distance_to(CAPITAL.CENTER)<1:return
    STREET._prepare()
    if planter_shape==null:planter_shape=STREET.parts.StonePlanter.mesh.create_trimesh_shape()
    var planters:Array[Transform3D]=[];var flowers:Array[Transform3D]=[]
    for axis in range(2):
        for side:float in [-1,1]:
            for along:float in [-13.5,13.5]:
                var offset:=Vector2(side*43,along) if axis==0 else Vector2(along,side*43)
                var point:=cell_center+offset
                if CAPITAL.in_gate_approach(point,15) or not CAPITAL.protected_infrastructure_near(point,58).is_empty():continue
                var at:=Vector3(offset.x,WorldData.elevation_at(point)+.026,offset.y)
                var transform:=Transform3D(Basis(Vector3.UP,PI*.5 if axis==0 else 0),at)
                var body:=StaticBody3D.new();body.name="StreetPocketFlowerBed";body.transform=transform;root.add_child(body)
                var collision:=CollisionShape3D.new();collision.shape=planter_shape;collision.transform=STREET.parts.StonePlanter.transform;body.add_child(collision)
                body.add_to_group("map_fixture");body.set_meta("map_footprint",Vector2(1.25,1.7) if axis==0 else Vector2(1.7,1.25))
                planters.append(transform)
                for x:float in [-.48,0,.48]:flowers.append(transform*Transform3D(Basis.from_scale(Vector3.ONE*.65),Vector3(x,.34,0)))
    if not planters.is_empty():STREET._batch(root,"StonePlanter",planters)
    COURT.batch(root,"MeadowFlowers",flowers,100,false)
    root.set_meta("street_flower_beds",planters.size())
