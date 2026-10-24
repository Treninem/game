"""REJECTED ART TRIAL: material-only salvage of the existing starter weapon set.

Reuses the verified CC0 source geometry/cedar/rock. Nothing in live production
is overwritten. Material images are shared; Godot production wrappers assign
their resources in the isolated review only. Native frames on 2026-10-23
rejected the angular silhouette and overly dark steel. Do not integrate this
trial, or treat the geometry checks as artistic approval.
"""
from pathlib import Path
import bpy,bmesh,numpy as np,os,json,hashlib,math
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(os.environ.get('IMPULS_WEAPON_OUTPUT',ROOT/'build/asset_work/woodland-kit-2026-10-23/candidate'))
SOURCE=ROOT/'assets/production/weapons/woodland'
CEDAR=ROOT/'assets/staging/ui/materials/cedar/cedar.png'
ROCK=ROOT/'assets/staging/materials/oga_ground_texture_set/ground/rock1.png'
METAL={'Steel','LightSteel','DarkSteel'}
WOOD={'LightWood','DarkWood'}
COLORS={'Steel':(.36,.38,.40,1),'LightSteel':(.57,.59,.61,1),'DarkSteel':(.18,.19,.20,1),'LightWood':(.90,.90,.88,1),'DarkWood':(.55,.52,.48,1),'White':(.65,.58,.45,1),'DarkRed':(.23,.11,.065,1),'Flint':(.80,.82,.82,1)}

def pixels(path):
 image=bpy.data.images.load(str(path),check_existing=False);image.colorspace_settings.name='Non-Color'
 raw=np.array(image.pixels[:],dtype=np.float32).reshape(image.size[1],image.size[0],4)[::-1]
 if image.size[:]==(1024,1024):raw=raw.reshape(512,2,512,2,4).mean(axis=(1,3))
 assert raw.shape[:2]==(512,512)
 return raw[:,:,:3]

def save_image(name,rgb,alpha=None):
 rgba=np.ones((512,512,4),dtype=np.float32);rgba[:,:,:3]=np.clip(rgb,0,1)
 if alpha is not None:rgba[:,:,3]=np.clip(alpha,0,1)
 image=bpy.data.images.new(name,width=512,height=512,alpha=True)
 image.colorspace_settings.name='Non-Color';image.pixels.foreach_set(rgba[::-1].copy().ravel())
 path=OUT/'surfaces'/(name+'.png');image.filepath_raw=str(path);image.file_format='PNG';image.save()
 return {'file':path.name,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'size':512,'channels':'RGB color' if alpha is None else 'RGB tangent normal / A roughness'}

def detail(height,roughness,width_m,height_m):
 dx=(np.roll(height,-1,axis=1)-np.roll(height,1,axis=1))*512/(2*width_m)
 dy=(np.roll(height,-1,axis=0)-np.roll(height,1,axis=0))*512/(2*height_m)
 normal=np.stack([-dx,dy,np.ones_like(dx)],axis=2)
 normal/=np.linalg.norm(normal,axis=2)[:,:,None]
 return normal*.5+.5,roughness

def author_maps():
 (OUT/'surfaces').mkdir();rows=[]
 wood=pixels(CEDAR);gray=wood@np.array([.2126,.7152,.0722])
 color=wood*.55+gray[:,:,None]*.45
 color=color.mean(axis=(0,1))[None,None,:]+(color-color.mean(axis=(0,1))[None,None,:])*.68
 rows.append(save_image('wood_color',color))
 normal,rough=detail((gray-gray.mean())*.00008,.74+.13*(1-gray),.08,.30)
 rows.append(save_image('wood_detail',normal,rough))
 rng=np.random.default_rng(231026)
 grain=rng.normal(0,1,(512,512))
 for _ in range(2):grain=(np.roll(grain,1,axis=0)+grain+np.roll(grain,-1,axis=0))/3
 scratches=np.zeros((512,512))
 for _ in range(100):
  x=int(rng.integers(0,512));start=int(rng.integers(0,440));length=int(rng.integers(12,72))
  scratches[start:start+length,x]+=float(rng.uniform(-.000006,.000006))
 normal,rough=detail(grain*.0000015+scratches,np.clip(.40+grain*.04,.33,.49),.15,.15)
 rows.append(save_image('steel_detail',normal,rough))
 stone=pixels(ROCK)@np.array([.2126,.7152,.0722])
 rows.append(save_image('flint_color',np.repeat((.22+stone*.16)[:,:,None],3,axis=2)))
 normal,rough=detail((stone-stone.mean())*.000008,.72+.12*(1-stone),.10,.10)
 rows.append(save_image('flint_detail',normal,rough))
 return rows

def weld_and_bevel(obj,name):
 mesh=obj.data;bm=bmesh.new();bm.from_mesh(mesh)
 bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6);bm.normal_update()
 weight=bm.edges.layers.float.get('bevel_weight_edge') or bm.edges.layers.float.new('bevel_weight_edge')
 count=0
 for edge in bm.edges:
  eligible=len(edge.link_faces)==2 and all(mesh.materials[f.material_index].name in METAL for f in edge.link_faces)
  if eligible and edge.calc_face_angle(0)>math.radians(40):edge[weight]=1;count+=1
 bm.to_mesh(mesh);bm.free()
 if mesh.has_custom_normals:mesh.normals_split_custom_set([(0,0,0)]*len(mesh.loops))
 for face in mesh.polygons:face.use_smooth=True
 if hasattr(mesh,'set_sharp_from_angle'):mesh.set_sharp_from_angle(angle=math.radians(45))
 if count and name!='Bow_Wooden':
  scale=float(np.mean(np.abs(tuple(obj.matrix_world.to_scale()))))
  bevel=obj.modifiers.new('Small forged edge highlights','BEVEL');bevel.limit_method='WEIGHT'
  bevel.width=(.0012 if name=='Axe_small' else .00025)/scale;bevel.segments=2;bevel.use_clamp_overlap=True;bevel.harden_normals=True
  if 'LightSteel' in [m.name for m in mesh.materials]:bevel.material=[m.name for m in mesh.materials].index('LightSteel')
  bpy.context.view_layer.objects.active=obj;bpy.ops.object.modifier_apply(modifier=bevel.name)
  weighted=obj.modifiers.new('Retain broad forged faces','WEIGHTED_NORMAL');weighted.keep_sharp=True
  bpy.ops.object.modifier_apply(modifier=weighted.name)
 return count

def stone_knife():
 """Keep the accepted wood grip, replace the metal blade/guard with stone."""
 obj=next(o for o in bpy.context.scene.objects if o.type=='MESH');mesh=obj.data
 names=[m.name for m in mesh.materials];dark=names.index('DarkWood')
 bm=bmesh.new();bm.from_mesh(mesh);remove=[]
 for face in bm.faces:
  label=names[face.material_index]
  if label in WOOD:continue
  # Retain the lower pommel geometry as a carved wooden butt, not a guard.
  if label=='DarkSteel' and max((obj.matrix_world@v.co).z for v in face.verts)<-.146:
   face.material_index=dark
  else:remove.append(face)
 bmesh.ops.delete(bm,geom=remove,context='FACES')
 bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
 bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6);bm.to_mesh(mesh);bm.free()
 for f in mesh.polygons:f.use_smooth=True
 if mesh.has_custom_normals:mesh.normals_split_custom_set([(0,0,0)]*len(mesh.loops))
 parent=obj.parent
 # Fixed dimensions in the original normalized Blender world (Z is up).
 levels=[(-.074,.009,.003),(-.055,.022,.0045),(-.015,.027,.0055),(.025,.029,.006),(.065,.028,.006),(.105,.024,.0055),(.14,.016,.004),(.175,0,0)]
 rng=np.random.default_rng(731);verts=[];faces=[];cols=5
 edge_chips={(row,column):float(rng.uniform(-.0015,.0015)) for row in range(1,len(levels)-1) for column in [0,cols-1]}
 for side in [-1,1]:
  for row,(z,width,thick) in enumerate(levels):
   for column in range(cols):
    f=-1+2*column/(cols-1);jitter=float(rng.uniform(.88,1.10))
    edge=edge_chips.get((row,column),0)
    verts.append((.00060126+f*max(0,width+edge),side*thick*(1-abs(f))*(1 if row in [0,len(levels)-1] else jitter),z))
  offset=0 if side==-1 else len(levels)*cols
  for row in range(len(levels)-1):
   for column in range(cols-1):
    a=offset+row*cols+column;b=a+1;c=a+cols;d=c+1
    pair=[(a,b,c),(b,d,c)] if (row+column)%2 else [(a,b,d),(a,d,c)]
    faces.extend(pair if side==-1 else [tuple(reversed(p)) for p in pair])
 # A shared chipped perimeter and closed insertion end prevent light leaking
 # through the blade when it is inspected from the edge.
 back=len(levels)*cols
 for column in range(cols-1):faces.append((column,column+1,back+column+1,back+column))
 data=bpy.data.meshes.new('Knapped flint blade');data.from_pydata(verts,[],faces);data.materials.append(bpy.data.materials.new('Flint'))
 blade=bpy.data.objects.new('StoneBlade',data);bpy.context.collection.objects.link(blade)
 blade.parent=parent;blade.matrix_parent_inverse=parent.matrix_world.inverted()
 bm=bmesh.new();bm.from_mesh(data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
 bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=1e-8)
 bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(data);bm.free()
 curve=bpy.data.curves.new('Hand-bound blade lashing','CURVE');curve.dimensions='3D';curve.resolution_u=1;curve.bevel_depth=.00065;curve.bevel_resolution=1;curve.use_fill_caps=True
 spline=curve.splines.new('POLY');spline.points.add(95)
 for i,p in enumerate(spline.points):
  t=i/95;angle=t*math.tau*4;radius=.0148*(1-.18*t)
  p.co=(.00060126+radius*math.cos(angle),radius*math.sin(angle),-.078+t*.030,1)
 rope=bpy.data.objects.new('BladeLashing',curve);bpy.context.collection.objects.link(rope)
 rope.parent=parent;rope.matrix_parent_inverse=parent.matrix_world.inverted()
 curve.materials.append(bpy.data.materials.get('White') or bpy.data.materials.new('White'))
 bpy.ops.object.select_all(action='DESELECT');rope.select_set(True);bpy.context.view_layer.objects.active=rope;bpy.ops.object.convert(target='MESH')
 return {'new_blade':'knapped stone','grip_world_blender':[.00060126,0,-.12],'metal_guard_removed':True,'blade_triangles':len(data.polygons),'binding_turns':4}

def author_uvs(obj):
 mesh=obj.data;points=np.array([tuple(v.co) for v in mesh.vertices]);uv=mesh.uv_layers.new(name='WeaponSurfaceUV')
 wood_ids=sorted({i for f in mesh.polygons if mesh.materials[f.material_index].name in WOOD for i in f.vertices})
 frame=None
 if wood_ids:
  cloud=points[wood_ids];center=cloud.mean(axis=0);_,axes=np.linalg.eigh((cloud-center).T@(cloud-center))
  along=axes[:,-1];across=axes[:,1];normal=np.cross(along,across)
  if along[np.argmax(np.abs(along))]<0:along=-along
  s=(points-center)@along;low=s[wood_ids].min();high=s[wood_ids].max();stations=np.linspace(low,high,96)
  centers=[]
  for station in stations:
   weights=np.exp(-((s[wood_ids]-station)/max((high-low)/24,1e-5))**2);centers.append((cloud*weights[:,None]).sum(axis=0)/weights.sum())
  centers=np.array(centers);arc=np.concatenate([[0],np.cumsum(np.linalg.norm(np.diff(centers,axis=0),axis=1))])
  scale=float(np.mean(np.abs(tuple(obj.matrix_world.to_scale()))));frame=(center,along,across,normal,s,stations,centers,arc,scale)
 for face in mesh.polygons:
  role=mesh.materials[face.material_index].name;values=[]
  for loop in face.loop_indices:
   i=mesh.loops[loop].vertex_index;p=points[i]
   if role in WOOD:
    center,along,across,normal,s,stations,centers,arc,scale=frame
    c=np.array([np.interp(s[i],stations,centers[:,a]) for a in range(3)]);delta=p-c
    u=math.atan2(float(delta@normal),float(delta@across))/math.tau+.5
    v=float(np.interp(s[i],stations,arc))*scale/.30;values.append((loop,u,v))
   else:
    normal_world=obj.matrix_world.to_3x3().inverted().transposed()@face.normal
    omit=max(range(3),key=lambda a:abs(normal_world[a]));axes2=[a for a in range(3) if a!=omit]
    world=obj.matrix_world@Vector(p);period=.10 if role=='Flint' else .15
    values.append((loop,float(world[axes2[0]])/period,float(world[axes2[1]])/period))
  if role in WOOD and max(x[1] for x in values)-min(x[1] for x in values)>.5:values=[(i,u+1 if u<.5 else u,v) for i,u,v in values]
  for loop,u,v in values:uv.data[loop].uv=(u,v)

def material(role,authored):
 m=bpy.data.materials.new(role+' authoring' if authored else role+' fallback');m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=COLORS[role]
 bs.inputs['Metallic'].default_value=.85 if role in METAL else 0
 bs.inputs['Roughness'].default_value=.4 if role in METAL else .82
 if not authored:return m
 family='wood' if role in WOOD else ('steel' if role in METAL else ('flint' if role=='Flint' else ''))
 if not family:return m
 if family in ['wood','flint']:
  tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(OUT/'surfaces'/(family+'_color.png')),check_existing=True);tex.image.colorspace_settings.name='sRGB'
  mix=m.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=COLORS[role]
  m.node_tree.links.new(tex.outputs['Color'],mix.inputs[1]);m.node_tree.links.new(mix.outputs[0],bs.inputs['Base Color'])
 tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(OUT/'surfaces'/(family+'_detail.png')),check_existing=True);tex.image.colorspace_settings.name='Non-Color'
 normal=m.node_tree.nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.7
 m.node_tree.links.new(tex.outputs['Color'],normal.inputs['Color']);m.node_tree.links.new(normal.outputs[0],bs.inputs['Normal']);m.node_tree.links.new(tex.outputs['Alpha'],bs.inputs['Roughness'])
 return m

def build():
 assert not OUT.exists(),'Keep previous candidates and their evidence';OUT.mkdir(parents=True);(OUT/'authoring').mkdir()
 bpy.ops.wm.read_factory_settings(use_empty=True);maps=author_maps();rows=[]
 for name in ['Axe_small','Dagger','Bow_Wooden','Arrow']:
  bpy.ops.wm.read_factory_settings(use_empty=True);source=SOURCE/(name+'.glb')
  bpy.ops.import_scene.gltf(filepath=str(source));bpy.context.view_layer.update()
  revision=stone_knife() if name=='Dagger' else {}
  parts=[]
  for obj in list(bpy.context.scene.objects):
   if obj.type!='MESH':continue
   bevels=weld_and_bevel(obj,name) if name!='Dagger' else 0;author_uvs(obj)
   parts.append({'node':obj.name,'vertices':len(obj.data.vertices),'faces':len(obj.data.polygons),'beveled_edges':bevels,'roles':[m.name for m in obj.data.materials]})
  roles={m.name for o in bpy.context.scene.objects if o.type=='MESH' for m in o.data.materials}
  fallbacks={role:material(role,False) for role in roles};authored={role:material(role,True) for role in roles}
  for obj in bpy.context.scene.objects:
   if obj.type=='MESH':
    for i,m in enumerate(list(obj.data.materials)):obj.data.materials[i]=fallbacks[m.name]
  # Give glTF stable semantic material names, with no duplicate texture images.
  for role,m in fallbacks.items():m.name=role+'.placeholder'
  path=OUT/(name+'.glb')
  bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_animations=False,export_texcoords=True)
  for obj in bpy.context.scene.objects:
   if obj.type=='MESH':
    for i,m in enumerate(list(obj.data.materials)):obj.data.materials[i]=authored[m.name.removesuffix('.placeholder')]
  for image in bpy.data.images:
   if image.source=='FILE':image.filepath=bpy.path.relpath(bpy.path.abspath(image.filepath),start=str(OUT/'authoring'))
  bpy.context.preferences.filepaths.file_preview_type='NONE';bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'authoring'/(name+'.blend')),relative_remap=False)
  row={'name':name,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'glb_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'parts':parts,'knife_revision':revision};rows.append(row);print('WEAPON_KIT_BUILT',json.dumps(row),flush=True)
 report={'maps':maps,'models':rows,'sources':[{'file':p.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [CEDAR,ROCK]]}
 (OUT/'construction.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':build()
