"""Layered timber-shingle roof candidate for the existing 12x10m family home.

Private output only. Preserve wall/door/window/furniture identities; gameplay
integration must replace the matching visual roof/gables together after review.
"""
from pathlib import Path
import bpy,bmesh,math,random,os,json
from mathutils import Vector,Matrix
R=Path(__file__).resolve().parents[1];OUT=Path(os.environ.get('IMPULS_ROOF_OUTPUT',R/'build/asset_work/region-art-2026-10-23/roof1'))
assert not OUT.exists();OUT.mkdir(parents=True);bpy.ops.wm.read_factory_settings(use_empty=True)
mats={}
for name,color in [('RoofShingle',(.38,.31,.23,1)),('Timber',(.25,.17,.10,1)),('Stone',(.44,.42,.38,1)),('Iron',(.17,.18,.19,1)),('Plaster',(.7,.65,.55,1))]:
 m=bpy.data.materials.new(name);m.diffuse_color=color;mats[name]=m
vertices=[];faces=[];face_roles=[];face_uvs=[];piece_count=0;rng=random.Random(231026)
def block(name,size,center,role,rotation=0,bevel=0):
 global piece_count
 # Authoring coordinates match Godot X/Y(up)/Z; Blender Z is up.
 rotation_matrix=Matrix.Rotation(rotation,3,'Y');start=len(vertices)
 local=[Vector((x*size[0]/2,z*size[2]/2,y*size[1]/2)) for x,y,z in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
 world=[rotation_matrix@p+Vector((center[0],-center[2],center[1])) for p in local];vertices.extend(tuple(p) for p in world)
 for indices in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(3,7,6,2),(0,4,7,3),(1,2,6,5)]:
  faces.append(tuple(start+i for i in indices));face_roles.append(list(mats).index(role))
  uv=[]
  for i in indices:
   p=world[i]
   uv.append((-p.y/3.84,p.z/max(math.sin(pitch),.1)/3.2) if role=='RoofShingle' else (local[i].x*.5,local[i].z*.5))
  face_uvs.append(uv)
 piece_count+=1
span=6.6;rise=5.5;depth=11.2;pitch=math.atan2(rise,span);slope=math.hypot(span,rise)
for side in [-1,1]:
 block('ContinuousDeck',(slope,.055,depth),(side*span/2,rise/2,0),'Timber',side*pitch)
 rows=math.ceil(slope/.36);columns=math.ceil(depth/.28)
 for row in range(rows):
  along=(row+.5)*slope/rows
  for column in range(columns):
   z=-depth/2+(column+.5)*depth/columns+(.07 if row%2 else -.07)
   z=max(-depth/2+.13,min(depth/2-.13,z))
   x=side*(span-along*math.cos(pitch));y=along*math.sin(pitch)+.065+row*.0012
   # Overlap at the head and irregular restrained edges read as laid shingles.
   block('LaidShingle',(.43,.022,depth/columns+.012),(x,y,z),'RoofShingle',side*pitch+rng.uniform(-.004,.004))
 for z in [-depth/2,depth/2]:block('BargeBoard',(slope+.1,.16,.15),(side*span/2,rise/2+.03,z),'Timber',side*pitch,.008)
 block('EaveFascia',(.14,.21,depth+.16),(side*span,.02,0),'Timber',0,.008)
 for z in [-5.1,-2.55,0,2.55,5.1]:block('ExposedRafter',(slope+.05,.17,.16),(side*span/2,rise/2-.08,z),'Timber',side*pitch,.008)
for z in [(-depth/2+.15)+i*.3 for i in range(math.ceil(depth/.3))]:
 for side in [-1,1]:block('RidgeCap',(.24,.034,.34),(side*.07,rise+.14,z),'RoofShingle',side*pitch)
# Family-home hearth is on the right kitchen wall: x = inner_half_x - .25,
# z = (kitchen_z + inner_half_z)/2. Keep its flue vertical through this roof.
chimney_x=5.4;chimney_z=3.475
for row in range(12):
 for side in [-1,1]:
  block('ChimneyCourse',(.15,.16,.72),(chimney_x+side*.29,.18+row*.16,chimney_z),'Stone',0,.006)
  block('ChimneyCourse',(.72,.16,.15),(chimney_x,.18+row*.16,chimney_z+side*.29),'Stone',0,.006)
# Close both attics to the actual overhanging roof slope, including the short
# vertical return above the room's wall plate. No open triangle behind a facade.
profile=[(-6,0),(6,0),(6,.5),(0,5.5),(-6,.5)]
for z in [-5,5]:
 start=len(vertices)
 for depth_side in [-1,1]:
  vertices.extend((x,-(z+depth_side*.075),y) for x,y in profile)
 cap=[(0,1,2),(0,2,3),(0,3,4)]
 for indices in cap:
  for offset,reverse in [(0,False),(5,True)]:
   tri=tuple(start+offset+i for i in (tuple(reversed(indices)) if reverse else indices));faces.append(tri);face_roles.append(4);face_uvs.append([(vertices[i][0]*.35,vertices[i][2]*.35) for i in tri])
 for i in range(5):
  quad=(start+i,start+(i+1)%5,start+5+(i+1)%5,start+5+i);faces.append(quad);face_roles.append(4);face_uvs.append([(vertices[j][0]*.35,vertices[j][2]*.35) for j in quad])
mesh=bpy.data.meshes.new('Laid timber shingles and structural members');mesh.from_pydata(vertices,[],faces)
for material in mats.values():mesh.materials.append(material)
uv=mesh.uv_layers.new(name='PhysicalRoofUV')
for polygon,role,coords in zip(mesh.polygons,face_roles,face_uvs):
 polygon.material_index=role
 for loop,coord in zip(polygon.loop_indices,coords):uv.data[loop].uv=coord
obj=bpy.data.objects.new('CottageShingleRoof',mesh);bpy.context.collection.objects.link(obj)
bpy.context.view_layer.objects.active=obj;obj.select_set(True)
bm=bmesh.new();bm.from_mesh(mesh);bm.normal_update();weight=bm.edges.layers.float.new('bevel_weight_edge')
for edge in bm.edges:
 if len(edge.link_faces)==2 and all(face.material_index in [1,2] for face in edge.link_faces):edge[weight]=1
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free()
mod=obj.modifiers.new('Worked timber and masonry edges','BEVEL');mod.limit_method='WEIGHT';mod.width=.005;mod.segments=1;bpy.ops.object.modifier_apply(modifier=mod.name)
triangles=sum(len(p.vertices)-2 for p in obj.data.polygons);assert triangles<45000,triangles
bpy.context.preferences.filepaths.file_preview_type='NONE';bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'CottageShingleRoof.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'CottageShingleRoof.glb'),export_format='GLB',export_animations=False,export_texcoords=True)
(OUT/'construction.json').write_text(json.dumps({'status':'CANDIDATE_NOT_INTEGRATED','envelope_m':[13.2,5.75,11.4],'triangles':triangles,'pieces':piece_count,'roles':list(mats),'chimney_center':[chimney_x,chimney_z],'note':'Photo material selection, matching gables, physical roof/contact/headroom, full exterior/interior world review and performance are not yet accepted.'},indent=2)+'\n')
print('COTTAGE_ROOF_CANDIDATE',triangles,piece_count)
