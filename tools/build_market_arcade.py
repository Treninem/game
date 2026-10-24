"""Build an open two-bay market arcade from the accepted city roof family.

Run with Blender; output is a new private review tree. Existing house/roof
assets are read only. Timber trusses, octagonal masonry shoes and a shared
valley gutter are authored here; roof tiles/decks reuse the selected CC0 kit.
"""
from pathlib import Path
import bpy,math,os,json
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
OUT=Path(os.environ.get('IMPULS_MARKET_ARCADE_OUTPUT',R/'build/asset_work/market-arcade-2026-10-23/arcade1'));assert not OUT.exists();OUT.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(R/'assets/source/architecture/townhouse/Townhouse_2.blend'),load_ui=False)
bpy.context.preferences.filepaths.file_preview_type='NONE';bpy.context.preferences.filepaths.save_version=0
source=next(o for o in bpy.data.objects if o.type=='MESH');data=source.data;roof=[]
for face in data.polygons:
 role=data.materials[face.material_index].name
 if role not in ['Timber','RoofTiles']:continue
 p=[tuple(data.vertices[i].co) for i in face.vertices]
 if min(v[2] for v in p)<5.74:continue
 # Attic-window framing belongs to enclosed houses, not an open roof truss.
 if role=='Timber' and max(abs(v[0]) for v in p)<.81 and min(abs(v[1]) for v in p)>4.8 and max(abs(v[1]) for v in p)<5.4:continue
 uv=[tuple(data.uv_layers.active.data[i].uv) for i in face.loop_indices]
 roof.append((p,role,uv))
materials={name:bpy.data.materials[name] for name in ['Timber','Stone','RoofTiles','Metal']}
for obj in list(bpy.data.objects):bpy.data.objects.remove(obj,do_unlink=True)
counts={}
def mesh(name,vertices,faces,roles,uvs=None):
 data=bpy.data.meshes.new(name);data.from_pydata([(p[0],-p[2],p[1]) for p in vertices],[],faces)
 names=list(dict.fromkeys(roles))
 for role in names:data.materials.append(materials[role])
 uv=data.uv_layers.new(name='PhysicalUV')
 for face,role in zip(data.polygons,roles):
  face.material_index=names.index(role)
  for k,loop in enumerate(face.loop_indices):
   point=data.vertices[data.loops[loop].vertex_index].co
   uv.data[loop].uv=uvs[face.index][k] if uvs else (point.x*.4+point.y*.15,point.z*.5)
 obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj)
 counts[name]=sum(len(p.vertices)-2 for p in data.polygons);return obj
for center in [-4.5,4.5]:
 vertices=[];faces=[];roles=[];uvs=[]
 for points,role,uv in roof:
  start=len(vertices);vertices.extend((center+p[0]*1.125,p[2]-6.24+3.6,-p[1]*1.4) for p in points);faces.append(tuple(start+i for i in range(len(points))));roles.append(role);uvs.append(uv)
 mesh('RoofLeft' if center<0 else 'RoofRight',vertices,faces,roles,uvs)
verts=[];faces=[];roles=[]
def add(points,polys,role):
 start=len(verts);verts.extend(points);faces.extend(tuple(start+i for i in face) for face in polys);roles.extend([role]*len(polys))
def beam(a,b,width,depth,role='Timber'):
 a=Vector(a);b=Vector(b);axis=(b-a).normalized();helper=Vector((0,0,1)) if abs(axis.z)<.95 else Vector((0,1,0));x=axis.cross(helper).normalized()*width*.5;z=x.normalized().cross(axis)*depth*.5
 points=[tuple(p+sx*x+sz*z) for p in [a,b] for sx,sz in [(-1,-1),(1,-1),(1,1),(-1,1)]]
 add(points,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],role)
def octagon(x,z,levels,role):
 points=[(x+radius*math.cos(i*math.tau/8),y,z+radius*math.sin(i*math.tau/8)) for y,radius in levels for i in range(8)]
 polys=[tuple(reversed(range(8))),tuple((len(levels)-1)*8+i for i in range(8))]
 for level in range(len(levels)-1):
  for i in range(8):polys.append((level*8+i,level*8+(i+1)%8,(level+1)*8+(i+1)%8,(level+1)*8+i))
 add(points,polys,role)
for z in [-6.8,0,6.8]:
 for x in [-9,0,9]:
  octagon(x,z,[(0,.43),(.09,.46),(.18,.37),(.52,.34),(.59,.29)],'Stone')
  octagon(x,z,[(.5,.24),(3.4,.24),(3.55,.3)],'Timber')
 for x in [-9,0]:
  beam((x,3.42,z),(x+9,3.42,z),.26,.29)
  beam((x+4.5,3.43,z),(x+4.5,7.3,z),.18,.18)
  for side in [-1,1]:
   beam((x+4.5+side*4.4,3.5,z),(x+4.5,7.31,z),.19,.21)
   beam((x+4.5+side*4.35,2.5,z),(x+4.5+side*3.1,3.45,z),.18,.19)
for x in [-9,0,9]:beam((x,3.4,-6.9),(x,3.4,6.9),.26,.28)
mesh('MeasuredPostsAndTrusses',verts,[tuple(reversed(face)) for face in faces],roles)
# Open gutter catches the paired roof valleys, with no floating decorative cap.
mesh('ValleyGutter',[(-.21,3.27,-7.7),(.21,3.27,-7.7),(.21,3.27,7.7),(-.21,3.27,7.7),(-.21,3.42,-7.7),(-.21,3.42,7.7),(.21,3.42,-7.7),(.21,3.42,7.7)],[(0,3,2,1),(0,4,5,3),(1,2,7,6)],['Metal']*3)
for name,x in [('Left',-9),('Center',0)]:
 marker=bpy.data.objects.new('LanternMount'+name,None);marker.location=(x,-7.08,2.15);bpy.context.collection.objects.link(marker)
for block in list(bpy.data.meshes):
 if block.users==0:bpy.data.meshes.remove(block)
for block in list(bpy.data.materials):
 if block.users==0:bpy.data.materials.remove(block)
for block in list(bpy.data.images):
 if block.users==0:bpy.data.images.remove(block)
bpy.ops.object.select_all(action='SELECT');bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'MarketArcade.blend'))
for material in materials.values():
 for link in list(material.node_tree.links):material.node_tree.links.remove(link)
bpy.ops.export_scene.gltf(filepath=str(OUT/'MarketArcade.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
(OUT/'construction.json').write_text(json.dumps({'state':'CANDIDATE_NOT_INTEGRATED','roof_source':'assets/source/architecture/townhouse/Townhouse_2.blend','reused_roof_faces':len(roof),'triangles':counts,'support_posts':9,'clear_headroom_m':2.4,'ground_y':0,'eaves_y':3.6,'bays':2,'bay_width_m':9,'width_between_posts_m':18,'length_between_posts_m':13.6,'lantern_mounts':2,'art_acceptance':False},indent=2));print('MARKET_ARCADE_AUTHORED',sum(counts.values()),'triangles roofs_reused=true open_passages=true')
