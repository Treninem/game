"""Project-authored grass candidate: tapered curved blades, no alpha cards.

Blender source and GLB remain private until world/native/budget review. Uses
the existing 0.38m ground-cover envelope and <=180 triangle contract.
"""
from pathlib import Path
import bpy,math,random,json,os
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
OUT=Path(os.environ.get('IMPULS_GRASS_OUTPUT',R/'build/asset_work/region-art-2026-10-23/grass1'))
assert not OUT.exists();OUT.mkdir(parents=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
rng=random.Random(231026);vertices=[];faces=[];pigments=[]
for blade in range(26):
    angle=rng.uniform(0,math.tau);radius=.13*math.sqrt(rng.random());base=Vector((math.cos(angle)*radius,math.sin(angle)*radius,0))
    heading=rng.uniform(0,math.tau);lean=Vector((math.cos(heading),math.sin(heading),0));side=Vector((-lean.y,lean.x,0))
    height=.38 if blade==0 else rng.uniform(.16,.36);width=rng.uniform(.008,.016);bend=rng.uniform(.045,.13)
    start=len(vertices)
    pigment=Vector((rng.uniform(.19,.28),rng.uniform(.38,.52),rng.uniform(.07,.13)))
    for segment in range(4):
        t=segment/3;center=base+Vector((0,0,height*t))+lean*(bend*t*t)
        half=width*.5*(1-t)**.65
        for sign in [-1,1]:
            vertices.append(tuple(center+side*half*sign));shade=.70+.30*t;pigments.append((*tuple(pigment*shade),1))
    for segment in range(3):
        a=start+segment*2
        # One tip vertex shared by the final triangle: no zero-area twin.
        if segment==2:faces.append((a,a+1,a+2))
        else:faces.extend([(a,a+1,a+3),(a,a+3,a+2)])
mesh=bpy.data.meshes.new('Tapered meadow blades');mesh.from_pydata(vertices,[],faces)
colors=mesh.color_attributes.new(name='BladePigment',type='FLOAT_COLOR',domain='POINT')
for i,color in enumerate(pigments):colors.data[i].color=color
uv=mesh.uv_layers.new(name='RootAnchoredBladeUV')
for face in mesh.polygons:
    for loop in face.loop_indices:
        index=mesh.loops[loop].vertex_index;uv.data[loop].uv=(0 if index%2==0 else 1,(index%8)//2/3)
material=bpy.data.materials.new('MeadowGrass');material.use_nodes=True
bs=material.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.93
color=material.node_tree.nodes.new('ShaderNodeVertexColor');color.layer_name='BladePigment';material.node_tree.links.new(color.outputs['Color'],bs.inputs['Base Color'])
material.use_backface_culling=False;mesh.materials.append(material)
obj=bpy.data.objects.new('MeadowGrass',mesh);bpy.context.collection.objects.link(obj)
assert sum(len(p.vertices)-2 for p in mesh.polygons)==130
bpy.context.preferences.filepaths.file_preview_type='NONE';bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'MeadowGrass.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'MeadowGrass.glb'),export_format='GLB',export_animations=False,export_texcoords=True)
(OUT/'construction.json').write_text(json.dumps({'status':'CANDIDATE_NOT_INTEGRATED','blades':26,'triangles':130,'height_m':.38,'source':'Project-authored Blender geometry and vertex pigments; no downloaded/generated bitmap','acceptance':'Native close/mid/far world views, wind root anchoring, road/house exclusions, quality presets and measured draw/triangle budget remain required'},indent=2)+'\n')
print('MEADOW_CANDIDATE_BUILT blades=26 triangles=130 height=.38')
