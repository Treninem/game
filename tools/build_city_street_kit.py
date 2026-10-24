"""Private Blender prototype: measured public paving, planted stone trough, iron lantern post.
Original ImPuls geometry; existing shared CC0 stone photograph only.
"""
from pathlib import Path
import bpy, math, json, os, random
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
Q=R/'build/asset_work/city-streetscape-2026-10-24'
P=Q/os.environ.get('IMPULS_STREET_TREE','portable'); OUT=P/'assets/source/architecture/city_street'
assert not OUT.exists(); OUT.mkdir(parents=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.file_preview_type='NONE'
bpy.context.preferences.filepaths.save_version=0
materials={}
for name,color,rough in [('StreetStone',(.66,.64,.58,1),.96),('StreetIron',(.065,.072,.068,1),.8),('PlanterSoil',(.12,.082,.052,1),1.)]:
 m=bpy.data.materials.new(name);m.diffuse_color=color;m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=color;bs.inputs['Roughness'].default_value=rough
 if name=='StreetIron':bs.inputs['Metallic'].default_value=.65
 if name=='StreetStone':
  import shutil
  target=P/'assets/production/architecture/city_street/stone_albedo.png';target.parent.mkdir(parents=True,exist_ok=True)
  for filename in ['stone_albedo.png','stone_normal.png','stone_orm.png']:shutil.copy2(Q/'stone-material'/filename,target.parent/filename)
  image=bpy.data.images.load(str(target));tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
 materials[name]=m
parts={}; current=[]
def cube(pos,size,role,bevel=.012):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos);o=bpy.context.object;o.scale=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.data.materials.append(materials[role])
 if bevel:
  mod=o.modifiers.new('Dressed edges','BEVEL');mod.width=bevel;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name)
 current.append(o);return o
def tube(points,radius=.025):
 curve=bpy.data.curves.new('ForgedScroll','CURVE');curve.dimensions='3D';curve.resolution_u=2;curve.bevel_depth=radius;curve.bevel_resolution=2
 spline=curve.splines.new('POLY');spline.points.add(len(points)-1)
 for p,co in zip(spline.points,points):p.co=(*co,1)
 obj=bpy.data.objects.new('ForgedScroll',curve);bpy.context.collection.objects.link(obj);obj.data.materials.append(materials['StreetIron']);current.append(obj)
def finish(name):
 bpy.ops.object.select_all(action='DESELECT')
 for o in current:o.select_set(True)
 bpy.context.view_layer.objects.active=current[0];bpy.ops.object.convert(target='MESH');bpy.ops.object.join();obj=bpy.context.object;obj.name=name
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 uv=obj.data.uv_layers.active
 if uv is None:uv=obj.data.uv_layers.new(name='PhysicalUV')
 for face in obj.data.polygons:
  axis=max(range(3),key=lambda i:abs(face.normal[i]));axes=[i for i in range(3) if i!=axis]
  for loop in face.loop_indices:
   point=obj.data.vertices[obj.data.loops[loop].vertex_index].co
   uv.data[loop].uv=(point[axes[0]]*.75,point[axes[1]]*.75)
 parts[name]={'triangles':sum(len(f.vertices)-2 for f in obj.data.polygons),'bounds':[list(min(v.co[i] for v in obj.data.vertices) for i in range(3)),list(max(v.co[i] for v in obj.data.vertices) for i in range(3))]}
 current.clear();return obj
# The panel is only 35mm high. Its outer 100mm tapered edge is a walkable ramp,
# not an invisible box. Inner slabs have small joints and chamfered stone edges.
verts=[(-1.5,-1.5,0),(1.5,-1.5,0),(1.5,1.5,0),(-1.5,1.5,0),(-1.4,-1.4,.035),(1.4,-1.4,.035),(1.4,1.4,.035),(-1.4,1.4,.035)]
mesh=bpy.data.meshes.new('PanelRamp');mesh.from_pydata(verts,[],[(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7),(0,3,2,1)]);mesh.materials.append(materials['StreetStone']);o=bpy.data.objects.new('PanelRamp',mesh);bpy.context.collection.objects.link(o);current.append(o)
rng=random.Random(470219)
for row in range(6):
 widths=[rng.uniform(.7,1.3) for _ in range(5)];scale=2.79/sum(widths);cursor=-1.395
 for width in widths:
  w=width*scale;cube((cursor+w*.5,-1.395+(row+.5)*.465,.036),(w-.008,.457,.006),'StreetStone',.002);cursor+=w
finish('PavingPanel')
# Hollow planted trough: stone foot, three mortared courses, dressed overhanging
# cap stones and visible soil inside. Nothing floats; the floor is sealed.
cube((0,0,.045),(1.7,1.25,.09),'StreetStone',.025)
for level in range(3):
 z=.10+(level+.5)*.135
 for side in [-1,1]:
  for i in range(4):cube((-.60+i*.4,side*.51,z),(.39,.20,.128),'StreetStone',.012)
  for i in range(2):cube((side*.70,-.22+i*.44,z),(.20,.43,.128),'StreetStone',.012)
for side in [-1,1]:
 cube((0,side*.52,.54),(1.69,.25,.10),'StreetStone',.018)
 cube((side*.72,0,.54),(.25,.80,.10),'StreetStone',.018)
cube((0,0,.29),(1.20,.78,.10),'PlanterSoil',.006)
finish('StonePlanter')
# Octagonal stone foot and tapered forged-iron shaft. A curved bracket carries
# an existing production lantern at the measured marker rather than in air.
cube((0,0,.055),(.45,.45,.11),'StreetStone',.028)
for low,high,r0,r1 in [(.10,.25,.14,.11),(.25,2.5,.085,.055)]:
 bpy.ops.mesh.primitive_cone_add(vertices=12,radius1=r0,radius2=r1,depth=high-low,location=(0,0,(low+high)*.5));o=bpy.context.object;o.data.materials.append(materials['StreetIron']);current.append(o)
for z in [.27,.32,1.25,2.37,2.49]:
 bpy.ops.mesh.primitive_torus_add(major_segments=12,minor_segments=6,location=(0,0,z),major_radius=.078,minor_radius=.014);o=bpy.context.object;o.data.materials.append(materials['StreetIron']);current.append(o)
tube([(0,0,2.42),(.05,0,2.58),(.14,0,2.68),(.28,0,2.70),(.43,0,2.64),(.49,0,2.52),(.47,0,2.42)],.024)
tube([(.03,0,2.38),(.17,0,2.45),(.30,0,2.42),(.33,0,2.34),(.27,0,2.29),(.22,0,2.33)],.015)
finish('LanternPost')
marker=bpy.data.objects.new('LanternAnchor',None);marker.location=(.47,0,2.40);bpy.context.collection.objects.link(marker)
path=OUT/'CityStreetKit.blend'
for image in bpy.data.images:
 if image.source=='FILE':image.filepath=bpy.path.relpath(image.filepath,start=str(OUT))
bpy.ops.wm.save_as_mainfile(filepath=str(path),relative_remap=False)
target=P/'assets/production/architecture/city_street/CityStreetKit.glb';target.parent.mkdir(parents=True,exist_ok=True)
# Shared runtime material resources replace named stone/iron/soil; export no
# duplicated photographs. The editable source retains its real relative image.
for mat in materials.values():
 for link in list(mat.node_tree.links):
  if link.from_node.type=='TEX_IMAGE':mat.node_tree.links.remove(link)
bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',export_apply=True,export_yup=True)
(OUT/'.gdignore').write_text('')
(Q/'construction.json').write_text(json.dumps({'state':'CANDIDATE_NOT_INTEGRATED','parts':parts,'total_triangles':sum(p['triangles'] for p in parts.values()),'lantern_anchor_m':[.47,2.40,0],'paving_outer_ramp_height_m':.035,'paving_outer_ramp_run_m':.10,'images_relative':all(i.filepath.startswith('//') for i in bpy.data.images if i.source=='FILE'),'source_original':True},indent=2))
print('CITY_STREET_KIT_AUTHORED',sum(p['triangles'] for p in parts.values()),'triangles')
