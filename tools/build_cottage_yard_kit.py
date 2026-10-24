"""Blender kit for the supplied cottage/yard concept; metres, Godot +Z front.

Project-authored worked timber/stone, planter, flowers and open timber store.
Fence geometry reuses the physically staged B47 CC0 WoodenFence_Single OBJ.
Runtime supplies existing photographed wood/stone and shared environment wind.
"""
from pathlib import Path
import bpy,math,random,json,hashlib
from mathutils import Vector
r=Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
materials={}
for name,col in [('Timber',(.34,.24,.15,1)),('RoofWood',(.24,.18,.12,1)),('Stone',(.55,.52,.47,1)),('Leaves',(.24,.34,.16,1)),('Petals',(.73,.67,.56,1)),('Pollen',(.58,.42,.16,1))]:
 m=bpy.data.materials.new(name);m.diffuse_color=col;m.use_nodes=True
 shader=m.node_tree.nodes.get('Principled BSDF');shader.inputs['Base Color'].default_value=col;shader.inputs['Roughness'].default_value=.95
 materials[name]=m
def block(name,size,point,mat='Timber',bevel=.008):
 x,y,z=point;bpy.ops.mesh.primitive_cube_add(size=1,location=(x,-z,y));o=bpy.context.object;o.name=name
 o.dimensions=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.data.materials.append(materials[mat])
 if bevel:
  mod=o.modifiers.new('Worked edges','BEVEL');mod.width=bevel;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def join(name,objects):
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 return o
block('TimberBeam',(.16,1,.16),(0,0,0),bevel=.012)
rng=random.Random(261022)
stones=[]
for row in range(2):
 for i in range(4):
  o=block('Hand set stone',(.244,.485,.18),(-.375+i*.25,.25+row*.5,0),'Stone',.025)
  for v in o.data.vertices:
   v.co.x+=rng.uniform(-.006,.006);v.co.z+=rng.uniform(-.006,.006)
  stones.append(o)
join('StoneCourse',stones)
parts=[]
for z in [-.15,.15]:
 for y in [.07,.20]:parts.append(block('Planter boards',(1.6,.12,.035),(0,y,z)))
for x in [-.78,.78]:parts.append(block('Planter end',(.04,.27,.30),(x,.135,0)))
parts.append(block('Planter bottom',(1.6,.035,.3),(0,.02,0)))
join('WindowPlanter',parts)

# Source has no reliable up-axis metadata; normalize its largest dimension to
# horizontal span, middle to height, smallest to depth. Original UVs are kept;
# runtime uses the shared photographic timber material.
source=r/'assets/staging/sourcechat_b47/models/quaternius_medieval_village_megakit_standard/OBJ/Prop_WoodenFence_Single.obj'
temporary=r/'build/asset_work/cottage-yard';temporary.mkdir(parents=True,exist_ok=True)
# The source MTL contains the original author's absolute Windows paths. Runtime
# deliberately shares existing timber, so avoid searching those unavailable maps.
clean=temporary/'fence.obj';clean.write_text('\n'.join(line for line in source.read_text().splitlines() if not line.startswith(('mtllib ','usemtl '))),encoding='utf-8')
print('COTTAGE_STAGE fence_import',flush=True)
before=set(bpy.data.objects);bpy.ops.wm.obj_import(filepath=str(clean));objects=[o for o in set(bpy.data.objects)-before if o.type=='MESH']
for o in objects:
 bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
fence=join('GardenFence',objects)
lo=Vector(tuple(min(v.co[a] for v in fence.data.vertices) for a in range(3)));hi=Vector(tuple(max(v.co[a] for v in fence.data.vertices) for a in range(3)))
axes=sorted(range(3),key=lambda a:hi[a]-lo[a],reverse=True);length,height,depth=axes
for v in fence.data.vertices:
 p=v.co.copy();v.co.x=(p[length]-(lo[length]+hi[length])*.5)*2/(hi[length]-lo[length]);v.co.y=(p[depth]-(lo[depth]+hi[depth])*.5)*.18/(hi[depth]-lo[depth]);v.co.z=(p[height]-lo[height])*1.05/(hi[height]-lo[height])
fence.data.materials.clear();fence.data.materials.append(materials['Timber'])
for p in fence.data.polygons:p.material_index=0
mod=fence.modifiers.new('Worn fence corners','BEVEL');mod.width=.008;mod.segments=2;bpy.context.view_layer.objects.active=fence;bpy.ops.object.modifier_apply(modifier=mod.name)

parts=[]
for x in [-1.45,1.45]:
 for z in [-.9,.9]:parts.append(block('Store post',(.14,2.5,.14),(x,1.25,z)))
for y in [.35,1.0,1.7]:
 parts.append(block('Store rear rail',(3.05,.13,.10),(0,y,-.9)))
 for x in [-1.45,1.45]:parts.append(block('Store side rail',(.10,.13,1.85),(x,y,0)))
for x in [-1.45,1.45]:parts.append(block('Store upper rail',(.15,.15,2.15),(x,2.49,0)))
for i in range(18):
 o=block('Overlapping roof board',(.187,.075,2.45),(-1.59+i*.187,2.55,0),'RoofWood');o.rotation_euler.x=-math.atan(.35/2.45);parts.append(o)
join('TimberStore',parts)

flowers=[]
for i,(x,z,h) in enumerate([(-.16,-.04,.43),(.12,.08,.35),(.02,-.12,.51)]):
 bpy.ops.mesh.primitive_cylinder_add(vertices=6,radius=.008,depth=h,location=(x,-z,h*.5));stem=bpy.context.object;stem.data.materials.append(materials['Leaves']);flowers.append(stem)
 for side in [-1,1]:
  verts=[(x,-z,h*.38),(x+side*.09,-z-.025,h*.55),(x+side*.15,-z,h*.50),(x+side*.08,-z+.025,h*.43)]
  mesh=bpy.data.meshes.new('Tapered leaf');mesh.from_pydata(verts,[],[(0,1,2,3)]);mesh.update();o=bpy.data.objects.new('Leaf',mesh);bpy.context.collection.objects.link(o);mesh.materials.append(materials['Leaves']);flowers.append(o)
 for petal in range(8):
  angle=petal*math.tau/8;verts=[]
  for radius,width,y in [(0.008,.007,h),(.045,.019,h+.008),(.075,.018,h+.038),(.081,0,h+.043)]:
   for sign in [-1,1]:verts.append((x+math.cos(angle)*radius-math.sin(angle)*width*sign,-z+math.sin(angle)*radius+math.cos(angle)*width*sign,y))
  mesh=bpy.data.meshes.new('Curved petal');mesh.from_pydata(verts,[],[(0,1,3,2),(2,3,5,4),(4,5,6)]);mesh.update();o=bpy.data.objects.new('Petal',mesh);bpy.context.collection.objects.link(o);mesh.materials.append(materials['Petals']);flowers.append(o)
 bpy.ops.mesh.primitive_uv_sphere_add(segments=8,ring_count=4,radius=.017,location=(x,-z,h+.006));o=bpy.context.object;o.data.materials.append(materials['Pollen']);flowers.append(o)
join('MeadowFlowers',flowers)

out=r/'assets/production/exteriors/cottage_yard';out.mkdir(parents=True,exist_ok=True)
work=r/'assets/source/exteriors';work.mkdir(parents=True,exist_ok=True);(work/'.gdignore').write_text('')
bpy.data.orphans_purge(do_recursive=True)
print('COTTAGE_STAGE save_source',flush=True)
bpy.context.preferences.filepaths.file_preview_type='NONE';bpy.ops.wm.save_as_mainfile(filepath=str(work/'CottageYardKit.blend'))
print('COTTAGE_STAGE export',flush=True)
bpy.ops.export_scene.gltf(filepath=str(out/'CottageYardKit.glb'),export_format='GLB',export_yup=True)
stats={}
for o in bpy.data.objects:
 if o.type=='MESH':o.data.calc_loop_triangles();stats[o.name]={'triangles':len(o.data.loop_triangles),'vertices':len(o.data.vertices)}
stats['fence_source_sha256']=hashlib.sha256(source.read_bytes()).hexdigest()
(r/'build/acceptance/cottage-yard-kit-metrics.json').write_text(json.dumps(stats,indent=2),encoding='utf-8')
print('COTTAGE_YARD_KIT_BUILT',json.dumps(stats))
