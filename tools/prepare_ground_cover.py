"""Derive bounded low grass from the existing CC0 production selection."""
import bpy,json,hashlib
from pathlib import Path
from mathutils import Matrix,Vector
R=Path(__file__).resolve().parents[1]
source=R/'assets/production/nature/woodland/Grass_Wispy_Tall.glb'
output=source.with_name('Grass_Ground.glb')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
meshes=[o for o in bpy.data.objects if o.type=='MESH']
for obj in meshes:
 world=obj.matrix_world.copy();obj.parent=None
 for vertex in obj.data.vertices:vertex.co=world@vertex.co
 obj.matrix_world=Matrix.Identity(4)
 bpy.context.view_layer.objects.active=obj
 mod=obj.modifiers.new('GroundCoverReduction','DECIMATE');mod.ratio=.25;mod.use_collapse_triangulate=True
 bpy.ops.object.modifier_apply(modifier=mod.name)
points=[v.co for obj in meshes for v in obj.data.vertices]
low=min(v.z for v in points);high=max(v.z for v in points)
center=Vector(((min(v.x for v in points)+max(v.x for v in points))*.5,(min(v.y for v in points)+max(v.y for v in points))*.5,low))
scale=.38/(high-low)
for obj in meshes:
 for vertex in obj.data.vertices:
  vertex.co=(vertex.co-center)*scale;vertex.co.x*=1.8;vertex.co.y*=1.8
for obj in list(bpy.data.objects):
 if obj not in meshes:bpy.data.objects.remove(obj,do_unlink=True)
bpy.ops.export_scene.gltf(filepath=str(output),export_format='GLB',export_animations=False)
metadata={'source':str(source.relative_to(R)).replace('\\','/'),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'license':'CC0; existing woodland/LICENSE.txt','height_m':.38,'decimate_ratio':.25,'horizontal_spread':1.8,'vertices':sum(len(o.data.vertices) for o in meshes),'reproducer':'tools/prepare_ground_cover.py','output_sha256':hashlib.sha256(output.read_bytes()).hexdigest()}
output.with_suffix('.source.json').write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf-8')
print('GROUND_COVER_PREPARED',json.dumps(metadata))
