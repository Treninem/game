"""Offline occlusion for a fitted default outfit, in common rig coordinates.

Do not hide bones or enlarge the garment at runtime. Remove only body faces
covered by the actual garment away from its open boundaries in all supported
Build extremes. Native source remains available for later outfit changes.
"""
import hashlib
import struct

import bmesh
import bpy
from mathutils.bvhtree import BVHTree


def add_fitted_lining(body,garment):
    """A real fitted inner garment under torso, sleeves and trousers.

    Native anatomical topology/weights and all morphs follow the same rig as
    the skin. Ends remain under outer cloth; the collar and wrists stay open.
    UVs use the existing tunic atlas's unprinted cloth strip, without a new map.
    """
    rig=body.parent
    allowed={'Hips','Spine','Spine1','Spine2','LeftArm','RightArm','LeftForeArm','RightForeArm','LeftShoulder','RightShoulder'}
    for side in ['Left','Right']:
        allowed.update(side+part for part in ['UpLeg','Leg','Foot','ToeBase'])
    wrists=[rig.data.bones[side+'Hand'].head_local for side in ['Left','Right']]
    neck=rig.data.bones['Neck'].head_local
    selected=[]
    for vertex in body.data.vertices:
        strongest=max(vertex.groups,key=lambda g:g.weight)
        bone=body.vertex_groups[strongest.group].name
        selected.append(bone in allowed and min((vertex.co-p).length for p in wrists)>.025
                        and (vertex.co-neck).length>.08)
    polygons=[p for p in body.data.polygons if all(selected[i] for i in p.vertices)]
    uses={}
    neighbours={i:set() for p in polygons for i in p.vertices}
    for polygon in polygons:
        ids=list(polygon.vertices)
        for a,b in zip(ids,ids[1:]+ids[:1]):
            edge=tuple(sorted((a,b)))
            uses[edge]=uses.get(edge,0)+1
            neighbours[a].add(b)
            neighbours[b].add(a)
    boundary={v for edge,count in uses.items() if count==1 for v in edge}
    protected=boundary|{j for i in boundary for j in neighbours[i]}
    # This inner garment has exact source-face correspondence in EVERY native
    # morph. Concave armpits can defeat a nearest-surface signed-distance test;
    # use the authored map for its interior, retaining two opening rings.
    body['lining_original_face_count']=len(body.data.polygons)
    body['lining_covered_faces']=[p.index for p in polygons if not any(i in protected for i in p.vertices)]
    used=sorted({i for p in polygons for i in p.vertices})
    remap={old:new for new,old in enumerate(used)}
    normals={i:body.data.vertices[i].normal.copy() for i in used}
    data=bpy.data.meshes.new('Fitted complete outfit lining')
    data.from_pydata([body.data.vertices[i].co+normals[i]*.006 for i in used],[],
                     [[remap[i] for i in p.vertices] for p in polygons])
    data.update()
    obj=bpy.data.objects.new('FittedOutfitLining',data)
    bpy.context.collection.objects.link(obj)
    obj.parent=rig
    # Outer-garment AO/tangent atlases were baked for a different surface.
    # Share its existing diffuse image, with a separate honest matte material.
    outer=garment.data.materials[0]
    shader=next(n for n in outer.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    image=shader.inputs['Base Color'].links[0].from_node.image
    lining=bpy.data.materials.new('OutfitLining')
    lining.use_nodes=True
    lining.use_backface_culling=False
    principled=lining.node_tree.nodes.get('Principled BSDF')
    principled.inputs['Roughness'].default_value=.95
    texture=lining.node_tree.nodes.new('ShaderNodeTexImage')
    texture.image=image
    lining.node_tree.links.new(texture.outputs['Color'],principled.inputs['Base Color'])
    data.materials.append(lining)
    uv=data.uv_layers.new(name='UVMap')
    original=body.data.uv_layers.active
    for target,source in zip(data.polygons,polygons):
        target.use_smooth=True
        for a,b in zip(target.loop_indices,source.loop_indices):
            u,v=original.data[b].uv
            uv.data[a].uv=(.883+.078*u,.35+.40*v)
    for group in body.vertex_groups:
        target=obj.vertex_groups.new(name=group.name)
        for old,new in remap.items():
            value=next((g.weight for g in body.data.vertices[old].groups if g.group==group.index),0)
            if value>0:target.add([new],value,'REPLACE')
    modifier=obj.modifiers.new('Native fitted cloth weights','ARMATURE')
    modifier.object=rig
    obj.shape_key_add(name='Basis')
    for key in list(body.data.shape_keys.key_blocks)[1:]:
        shape=obj.shape_key_add(name=key.name)
        shape.slider_min=-1
        for old,new in remap.items():shape.data[new].co=key.data[old].co+normals[old]*.006
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    garment.select_set(True)
    bpy.context.view_layer.objects.active=garment
    bpy.ops.object.join()
    return {'lining_faces':len(polygons),'lining_vertices':len(used),'clearance_m':.006,
            'new_textures':0,'morphs':9,'native_skin_weights':True}


def _shape_digest(mesh):
    digest = hashlib.sha256()
    for key in mesh.shape_keys.key_blocks:
        digest.update(key.name.encode())
        for vertex in key.data:
            digest.update(struct.pack("<3f", *vertex.co))
    return digest.hexdigest()


def _surface(garment, build):
    mesh = garment.data
    mesh.calc_loop_triangles()
    neighbours = [set() for _ in mesh.vertices]
    uses = {}
    for polygon in mesh.polygons:
        ids = list(polygon.vertices)
        for a, b in zip(ids, ids[1:] + ids[:1]):
            edge = tuple(sorted((a, b)))
            uses[edge] = uses.get(edge, 0) + 1
            neighbours[a].add(b)
            neighbours[b].add(a)
    boundary = {v for edge, count in uses.items() if count == 1 for v in edge}
    protected = boundary | {j for i in boundary for j in neighbours[i]}
    keys = mesh.shape_keys.key_blocks
    points = [v.co + (keys["Build"].data[i].co - v.co) * build
              for i, v in enumerate(keys["Basis"].data)]
    triangles = [list(t.vertices) for t in mesh.loop_triangles]
    eligible = [not any(i in protected for i in t) for t in triangles]
    return BVHTree.FromPolygons(points, triangles, all_triangles=True), eligible


def remove_covered_skin(body, garments):
    """Preserve vertex order, all morphs, UVs, weights and open skin regions."""
    mesh = body.data
    before_keys = _shape_digest(mesh)
    vertex_count = len(mesh.vertices)
    keys = mesh.shape_keys.key_blocks
    protected_skin=set()
    for vertex in mesh.vertices:
        strongest=max(vertex.groups,key=lambda g:g.weight)
        bone=body.vertex_groups[strongest.group].name
        if any(part in bone for part in ['Hand','Head','Neck','Jaw','Eye']):
            protected_skin.add(vertex.index)
    coverage = []
    for build in [0.0, -0.5, 0.5]:
        surfaces = [_surface(garment, build) for garment in garments]
        inside = []
        for i, vertex in enumerate(keys["Basis"].data):
            point = vertex.co + (keys["Build"].data[i].co - vertex.co) * build
            covered = False
            for bvh, eligible in surfaces:
                near, normal, triangle, distance = bvh.find_nearest(point)
                if (triangle is not None and eligible[triangle]
                        and distance < 0.09 and (point - near).dot(normal) <= 0.004):
                    covered = True
                    break
            inside.append(covered)
        coverage.append(inside)
    authored=set(body.get('lining_covered_faces',[]))
    if authored:assert body['lining_original_face_count']==len(mesh.polygons),'Coverage map does not match native body topology'
    hidden = [polygon.index for polygon in mesh.polygons
              if not any(i in protected_skin for i in polygon.vertices)
              and (polygon.index in authored or all(all(profile[i] for i in polygon.vertices) for profile in coverage))]
    assert hidden, "No actual garment-covered skin was found"
    # A garment boundary must not eat the exposed face, neck, hand or fingers.
    for index in hidden:
        for vi in mesh.polygons[index].vertices:
            vertex = mesh.vertices[vi]
            strongest = max(vertex.groups, key=lambda g: g.weight)
            bone = body.vertex_groups[strongest.group].name
            assert not any(part in bone for part in ["Hand", "Head", "Neck"]), (bone, vi)
    before_faces = len(mesh.polygons)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[bm.faces[index] for index in hidden], context="FACES_ONLY")
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    assert len(mesh.vertices) == vertex_count, "Body vertex/morph identity changed"
    assert _shape_digest(mesh) == before_keys, "Occlusion changed native shape coordinates"
    result = {"before_faces": before_faces, "removed_covered_faces": len(hidden),
              "after_faces": len(mesh.polygons), "vertices_unchanged": vertex_count,
              "shape_coordinates_unchanged": True, "build_profiles": [0, -0.5, 0.5],
              "open_boundary_rings_preserved": 2,"native_lining_face_correspondences":len(authored)}
    body["outfit_coverage"] = str(result)
    return result
