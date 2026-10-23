"""Author a human-scale street-house review kit in Blender; never edit live assets.

The old B29 house shells were inspected (4-face plaster/112-face beam parts).
New shells have real window apertures, reveals, shutters, cornices and curved
roof tiles. Reuse the compatible CC0 B29 balcony instead of duplicating it.
Outputs remain private until native, physical, export and art review.
"""
from pathlib import Path
import bpy,bmesh,math,os,json,random,numpy as np
from mathutils import Vector
R=Path(__file__).resolve().parents[1];OUT=Path(os.environ.get('IMPULS_TOWNHOUSE_OUTPUT',R/'build/asset_work/city-concepts-2026-10-23/townhouse1'));assert not OUT.exists();OUT.mkdir(parents=True)
# Restrained project-authored unglazed-clay microvariation, not scanned PBR.
noise=np.random.default_rng(231026).normal(0,1,(256,256)).astype(np.float32);soft=noise.copy()
for _ in range(12):soft=(soft+np.roll(soft,1,0)+np.roll(soft,-1,0)+np.roll(soft,1,1)+np.roll(soft,-1,1))/5
variation=np.clip(1+soft*.24+noise*.012,.85,1.15)
albedo=variation[:,:,None]*np.array([.48,.245,.135],dtype=np.float32)
height=noise*.00018+soft*.0005;dx=(np.roll(height,-1,1)-np.roll(height,1,1))*16;dy=(np.roll(height,-1,0)-np.roll(height,1,0))*16
normal=np.stack([-dx,dy,np.ones_like(dx)],axis=2);normal/=np.linalg.norm(normal,axis=2)[:,:,None];normal=normal*.5+.5
orm=np.stack([np.ones_like(soft),np.clip(.92+soft*.06,.87,.97),np.zeros_like(soft)],axis=2)
for name,data in [('clay_albedo',albedo),('clay_normal',normal),('clay_orm',orm)]:
 image=bpy.data.images.new(name,width=256,height=256,alpha=False);image.colorspace_settings.name='Non-Color';rgba=np.concatenate([data,np.ones((256,256,1))],axis=2).astype(np.float32);image.pixels.foreach_set(rgba[::-1].ravel());image.filepath_raw=str(OUT/(name+'.png'));image.file_format='PNG';image.save()
balcony_source=R/'assets/staging/sourcechat_b29/models/oga_modular_medieval_building_pack/74698_BalconyUpload_blend/BalconyUpload.blend'
with bpy.data.libraries.load(str(balcony_source),link=False) as (src,dst):dst.objects=['Balcony4','Balcony4Handles']
balcony=[]
for obj in dst.objects:
 points=[obj.matrix_world@v.co for v in obj.data.vertices];uv=obj.data.uv_layers.active
 balcony.append((points,[list(p.vertices) for p in obj.data.polygons],[[tuple(uv.data[i].uv) if uv else (0,0) for i in p.loop_indices] for p in obj.data.polygons]))
all_points=[p for part in balcony for p in part[0]];lo=Vector(tuple(min(p[i] for p in all_points) for i in range(3)));hi=Vector(tuple(max(p[i] for p in all_points) for i in range(3)))
reports=[]
for stories in [2,3]:
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.filepaths.file_preview_type='NONE';rng=random.Random(231026+stories);vertices=[];faces=[];roles=[];uvs=[];parts={}
 roles_order=['Plaster','Timber','Stone','RoofTiles','Glass','Metal']
 colors=[(.84,.81,.72,1),(.30,.21,.13,1),(.52,.49,.43,1),(.90,.85,.80,1),(.017,.027,.030,1),(.09,.085,.07,1)]
 materials=[]
 texture_paths={'Plaster':R/'assets/production/interiors/materials/lime_plaster/albedo.jpg','Timber':R/'assets/production/exteriors/family_home/cedar.png','Stone':R/'assets/production/exteriors/family_home/stone.png','RoofTiles':OUT/'clay_albedo.png'}
 for role,color in zip(roles_order,colors):
  material=bpy.data.materials.new(role);material.diffuse_color=color;material.use_nodes=True;bs=material.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=color;bs.inputs['Roughness'].default_value=.22 if role=='Glass' else .85;bs.inputs['Metallic'].default_value=.55 if role=='Metal' else .15 if role=='Glass' else 0
  if role in texture_paths:
   path=texture_paths[role];assert path.is_file(),path
   image=material.node_tree.nodes.new('ShaderNodeTexImage');image.image=bpy.data.images.load(str(path),check_existing=True);multiply=material.node_tree.nodes.new('ShaderNodeMixRGB');multiply.blend_type='MULTIPLY';multiply.inputs[0].default_value=1;multiply.inputs[2].default_value=color;material.node_tree.links.new(image.outputs['Color'],multiply.inputs[1]);material.node_tree.links.new(multiply.outputs[0],bs.inputs['Base Color'])
  materials.append(material)
 def add(points,polys,role,label,coordinates=None):
  start=len(vertices);vertices.extend((p[0],-p[2],p[1]) for p in points)
  for j,poly in enumerate(polys):
   faces.append(tuple(start+i for i in poly));roles.append(roles_order.index(role))
   if coordinates:uvs.append(coordinates[j])
   else:
    p=[points[i] for i in poly];spans=[max(v[i] for v in p)-min(v[i] for v in p) for i in range(3)];axes=sorted(range(3),key=lambda i:spans[i],reverse=True)[:2];vaxis,uaxis=axes
    uvs.append([(v[uaxis]*3.0,v[vaxis]*.45) for v in p])
  parts[label]=parts.get(label,0)+1
 def block(center,size,role,label,angle=0):
  x,y,z=center;w,h,d=size;c=math.cos(angle);s=math.sin(angle)
  points=[]
  for a,b,e in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]:
   px=a*w*.5;pz=e*d*.5;points.append((x+px*c+pz*s,y+b*h*.5,z-px*s+pz*c))
  add(points,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(3,7,6,2),(0,4,7,3),(1,2,6,5)],role,label)
 def wall(side,level):
  front=side in ['front','back'];span=8 if front else 10;sign=1 if side in ['front','right'] else -1;y0=level*3.12;holes=[]
  centers=[-2.4,0,2.4] if front and level>0 else [-2.4,2.4] if front else [-2.7,2.7]
  for center in centers:
   is_french=side=='front' and level==1 and center==0
   low=y0+.12 if is_french else y0+.96;high=y0+2.53;half=.68 if is_french else .59;holes.append((center-half,center+half,low,high))
  if side=='front' and level==0:holes.append((-.72,.72,.04,2.43))
  cuts=sorted(set([-span*.5,span*.5]+[v for hole in holes for v in hole[:2]]));ys=sorted(set([y0,y0+3.12]+[v for hole in holes for v in hole[2:]]))
  for a,b in zip(cuts,cuts[1:]):
   for low,high in zip(ys,ys[1:]):
    mid=((a+b)*.5,(low+high)*.5)
    if any(l<mid[0]<r and bottom<mid[1]<top for l,r,bottom,top in holes):continue
    if front:block(((a+b)*.5,(low+high)*.5,sign*5),(b-a,high-low,.22),'Plaster','wall_panel')
    else:block((sign*4,(low+high)*.5,(a+b)*.5),(.22,high-low,b-a),'Plaster','wall_panel')
  for left,right,low,high in holes:
   center=(left+right)*.5;width=right-left;height=high-low;door=side=='front' and level==0 and abs(center)<.1
   # Construct in the front frame, then rotate side/back frames as a unit.
   angle={'front':0,'right':math.pi*.5,'back':math.pi,'left':-math.pi*.5}[side]
   normal_distance=5 if front else 4
   def member(a,b,c,size,role,label):
    px=a*math.cos(angle)+(normal_distance+c)*math.sin(angle);pz=-a*math.sin(angle)+(normal_distance+c)*math.cos(angle)
    block((px,b,pz),size,role,label,angle)
   for x in [left-.065,right+.065]:member(x,(low+high)*.5,.035,(.13,height+.24,.25),'Timber','jamb')
   for y in [low-.055,high+.065]:member(center,y,.035,(width+.26,.13,.28),'Timber','sill_lintel')
   member(center,(low+high)*.5,-.035,(width-.035,height-.035,.055),'Timber' if door else 'Glass','door' if door else 'glazing')
   if door:
    for y in [.52,1.82]:member(center,y,.015,(width-.08,.065,.065),'Metal','door_strap')
    member(right-.18,1.08,.055,(.06,.14,.09),'Metal','latch')
   else:
    member(center,(low+high)*.5,.015,(.045,height,.085),'Timber','mullion');member(center,low+height*.58,.015,(width,.045,.085),'Timber','transom')
    if not (side=='front' and level==1 and abs(center)<.1):
     for edge in [-1,1]:
      shutter=center+edge*(width*.5+.31)
      member(shutter,(low+high)*.5,.12,(.43,height-.08,.075),'Timber','shutter')
      for y in [low+.2,high-.2]:member(shutter,y,.175,(.46,.055,.07),'Timber','shutter_brace')
 for level in range(stories):
  for side in ['front','back','left','right']:wall(side,level)
  y=level*3.12
  for z in [-5.16,5.16]:
   block((0,y+3.06,z),(8.35,.19,.18),'Timber','floor_plate')
   for x in [-4,-1.3,1.3,4]:block((x,y+1.55,z),(.16,3.02,.18),'Timber','upright')
  for x in [-4.16,4.16]:
   block((x,y+3.06,0),(.18,.19,10.35),'Timber','side_plate')
   for z in [-4.9,0,4.9]:block((x,y+1.55,z),(.18,3.02,.16),'Timber','side_upright')
 # A continuous stone plinth with a genuine break at the front threshold.
 for side in [-1,1]:
  block((side*2.45,.26,5.16),(3.35,.46,.27),'Stone','front_plinth')
  block((side*4.12,.26,0),(.28,.46,10.3),'Stone','side_plinth')
 block((0,.26,-5.15),(8.3,.46,.28),'Stone','back_plinth')
 roof_y=stories*3.12;ridge=3.8;half=4.4;depth=10.9;slope=math.atan2(ridge,4.0);length=half/math.cos(slope)
 for sign in [-1,1]:
  deck=[]
  for normal in [-.10,0]:
   for along,z in [(-.02,-depth*.5),(length,-depth*.5),(length,depth*.5),(-.02,depth*.5)]:
    deck.append((sign*(along*math.cos(slope)+normal*math.sin(slope)),roof_y+ridge-along*math.sin(slope)+normal*math.cos(slope),z))
  deck_faces=[(0,3,2,1),(4,5,6,7),(0,1,5,4),(3,7,6,2),(0,4,7,3),(1,2,6,5)]
  add(deck,[tuple(reversed(p)) if sign>0 else p for p in deck_faces],'Timber','closed_roof_deck')
  # Clay barrels follow the real pitched roof, with staggered overlaps.
  cols=10;rows=36
  for row in range(rows):
   z=-depth*.5+(row+.5)*depth/rows
   for col in range(cols):
    t=(col+.5)/cols;along=t*length
    points=[]
    for end in [-1,1]:
     for k in range(6):
      a=math.pi*k/5;side=math.cos(a)*.158;lift=.012+math.sin(a)*.052+end*.010;u=along+end*.34
      points.append((sign*(u*math.cos(slope)+lift*math.sin(slope)),roof_y+ridge-u*math.sin(slope)+lift*math.cos(slope),z+side))
    tile_faces=[(k,k+1,k+7,k+6) for k in range(5)]
    points.extend((p[0]-sign*.014*math.sin(slope),p[1]-.014*math.cos(slope),p[2]) for p in points[6:12])
    tile_faces.extend((k+6,k+7,k+13,k+12) for k in range(5))
    add(points,[tuple(reversed(p)) if sign>0 else p for p in tile_faces],'RoofTiles','curved_tile')
  for z in [-depth*.5,depth*.5]:
   # Slim raking bargeboard, authored as a sloped prism.
   start=Vector((0,roof_y+ridge+.015,z));end=Vector((sign*half,roof_y+ridge-half*math.tan(slope),z));direction=end-start;normal=Vector((-direction.y,direction.x,0)).normalized()*.065
   pts=[tuple(p+n+Vector((0,0,d))) for d in [-.09,.09] for p,n in [(start,-normal),(end,-normal),(end,normal),(start,normal)]]
   add(pts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(3,7,6,2),(0,4,7,3),(1,2,6,5)],'Timber','bargeboard')
 ridge_points=[(math.cos(math.pi*k/6)*.22,roof_y+ridge-.20+math.sin(math.pi*k/6)*.32,z) for z in [-depth*.5,depth*.5] for k in range(7)]
 add(ridge_points,[(k,k+1,k+8,k+7) for k in range(6)],'RoofTiles','ridge_cap')
 for z in [-5,5]:
  # Closed gable; the small central attic window has a real cutout.
  for left,right in [(-4,-.55),(-.55,.55),(.55,4)]:
   top_left=roof_y+ridge*(1-abs(left)/4.0);top_right=roof_y+ridge*(1-abs(right)/4.0)
   ranges=[(roof_y,roof_y+.85),(roof_y+2.05,None)] if left==-.55 else [(roof_y,None)]
   for bottom,top in ranges:
    upper_left=top if top is not None else top_left;upper_right=top if top is not None else top_right
    points=[(left,bottom,z-.11),(right,bottom,z-.11),(right,upper_right,z-.11),(left,upper_left,z-.11),(left,bottom,z+.11),(right,bottom,z+.11),(right,upper_right,z+.11),(left,upper_left,z+.11)]
    add(points,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(3,7,6,2),(0,4,7,3),(1,2,6,5)],'Plaster','closed_gable')
  block((0,roof_y+1.45,z),(1.08,1.19,.06),'Glass','attic_glass')
  for x in [-.61,.61]:block((x,roof_y+1.45,z+math.copysign(.13,z)),(.12,1.4,.18),'Timber','attic_jamb')
  for y in [roof_y+.78,roof_y+2.12]:block((0,y,z+math.copysign(.13,z)),(1.34,.12,.18),'Timber','attic_lintel')
  block((0,roof_y+1.45,z+math.copysign(.15,z)),(.04,1.2,.07),'Timber','attic_mullion')
 # Reuse the inspected, compatible CC0 balcony assembly at the French door.
 for points,polys,coords in balcony:
  rebased=[((p.x-(lo.x+hi.x)*.5)*6.2/(hi.x-lo.x),3.0+(p.z-lo.z),5.12+(hi.y-p.y)*1.18/(hi.y-lo.y)) for p in points]
  add(rebased,polys,'Timber','b29_balcony',coords)
 # Compact brick chimney, cap and projecting corbels.
 chimney_base=roof_y+ridge-2.45*math.tan(slope)-.2
 for course in range(10):
  y=chimney_base+course*.18
  for sign in [-1,1]:
   block((2.45+sign*.31,y,-2.7),(.18,.17,.8),'Stone','chimney_course')
   block((2.45,y,-2.7+sign*.31),(.8,.17,.18),'Stone','chimney_course')
 block((2.45,chimney_base+1.85,-2.7),(.98,.15,.98),'Stone','chimney_cap')
 mesh=bpy.data.meshes.new('Street house masonry carpentry and curved tiles');mesh.from_pydata(vertices,[],faces)
 for material in materials:mesh.materials.append(material)
 uv=mesh.uv_layers.new(name='PhysicalUV')
 for polygon,role,coords in zip(mesh.polygons,roles,uvs):
  polygon.material_index=role
  for loop,coord in zip(polygon.loop_indices,coords):uv.data[loop].uv=coord
 obj=bpy.data.objects.new('Townhouse_'+str(stories),mesh);bpy.context.collection.objects.link(obj);bpy.context.view_layer.objects.active=obj;obj.select_set(True)
 # Small edge highlights without inflating every roof tile or changing openings.
 bm=bmesh.new();bm.from_mesh(mesh);weights=bm.edges.layers.float.new('bevel_weight_edge')
 for edge in bm.edges:
  edge[weights]=1.0 if len(edge.link_faces)==2 and all(f.material_index in [1,2,5] for f in edge.link_faces) and abs(edge.calc_face_angle())>.70 else 0.0
 bm.to_mesh(mesh);bm.free()
 bevel=obj.modifiers.new('Measured timber and masonry edge highlights','BEVEL');bevel.width=.012;bevel.segments=1;bevel.limit_method='WEIGHT';bpy.ops.object.modifier_apply(modifier=bevel.name)
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(OUT/('Townhouse_'+str(stories)+'.blend')))
 # Runtime materials are shared external Godot resources; avoid embedding the
 # same photographs in every GLB. Editable .blend retains its texture nodes.
 for material in materials:
  bs=material.node_tree.nodes.get('Principled BSDF')
  for link in list(material.node_tree.links):
   if link.to_node==bs:material.node_tree.links.remove(link)
 bpy.ops.export_scene.gltf(filepath=str(OUT/('Townhouse_'+str(stories)+'.glb')),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
 triangles=sum(len(p.vertices)-2 for p in obj.data.polygons);bounds=[min(v.co[i] for v in obj.data.vertices) for i in range(3)]+[max(v.co[i] for v in obj.data.vertices) for i in range(3)]
 reports.append({'stories':stories,'triangles':triangles,'bounds_blender':bounds,'parts':parts,'balcony_source':str(balcony_source),'runtime_material_roles':roles_order});print('TOWNHOUSE_AUTHORED',stories,'triangles',triangles)
(OUT/'construction.json').write_text(json.dumps({'state':'CANDIDATE_NOT_INTEGRATED','houses':reports,'concept_reference':'User ImPULS_20_locations (2).zip, capital residential street and market; reference only','art_acceptance':False},indent=2))
