"""Project-authored carved market fountain, kept private until native review."""
from pathlib import Path
import bpy,math,os,json
R=Path(__file__).resolve().parents[1];OUT=Path(os.environ.get('IMPULS_FOUNTAIN_OUTPUT',R/'build/asset_work/city-concepts-2026-10-23/fountain1'));assert not OUT.exists();OUT.mkdir(parents=True);bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.filepaths.file_preview_type='NONE';bpy.context.preferences.filepaths.save_version=0
stone=bpy.data.materials.new('FountainStone');stone.diffuse_color=(.64,.61,.55,1);stone.use_nodes=True;bs=stone.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=stone.diffuse_color;bs.inputs['Roughness'].default_value=.9
image=stone.node_tree.nodes.new('ShaderNodeTexImage');image.image=bpy.data.images.load(str(R/'assets/production/exteriors/family_home/stone.png'));stone.node_tree.links.new(image.outputs['Color'],bs.inputs['Base Color'])
water=bpy.data.materials.new('FountainWater');water.diffuse_color=(.07,.21,.23,.7);water.use_nodes=True;water.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=water.diffuse_color
def mesh(name,points,faces,material):
 data=bpy.data.meshes.new(name);data.from_pydata([(x,-z,y) for x,y,z in points],[],faces);data.materials.append(material);uv=data.uv_layers.new(name='PhysicalUV')
 for face in data.polygons:
  face.use_smooth=True
  for loop in face.loop_indices:
   vertex=data.vertices[data.loops[loop].vertex_index].co;uv.data[loop].uv=(math.atan2(vertex.y,vertex.x)/math.tau*6,vertex.z*.65)
 if hasattr(data,'set_sharp_from_angle'):data.set_sharp_from_angle(angle=.65)
 obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);return obj
profile=[(0,0),(2.60,0),(2.70,.12),(2.60,.25),(2.48,.29),(2.48,.88),(2.65,.94),(2.65,1.06),(2.34,1.06),(2.28,.88),(2.18,.32),(.48,.32),(.48,.86),(.70,.92),(.70,1.10),(.42,1.18),(.42,2.10),(.84,2.14),(1.05,2.24),(1.05,2.38),(.90,2.40),(.75,2.22),(.30,2.18),(.30,2.72),(.36,2.78),(.36,2.88),(.20,2.94),(0,2.94)]
segments=96;points=[(r*math.cos(i*math.tau/segments),y,r*math.sin(i*math.tau/segments)) for r,y in profile for i in range(segments)];faces=[]
for j in range(len(profile)-1):
 for i in range(segments):
  # Two real rim notches connect the upper water channel to the falling stream.
  notch=(i in [0,47,48,95] and min(profile[j][1],profile[j+1][1])>=2.14 and j<22)
  if notch:continue
  if profile[j][0]==0:faces.append((j*segments,(j+1)*segments+(i+1)%segments,(j+1)*segments+i))
  elif profile[j+1][0]==0:faces.append((j*segments+i,j*segments+(i+1)%segments,(j+1)*segments))
  else:faces.append((j*segments+i,j*segments+(i+1)%segments,(j+1)*segments+(i+1)%segments,(j+1)*segments+i))
body=mesh('FountainStone',points,[tuple(reversed(f)) for f in faces],stone)
def ring(name,inside,outside,y):
 p=[(r*math.cos(i*math.tau/96),y,r*math.sin(i*math.tau/96)) for r in [inside,outside] for i in range(96)];f=[(i,(i+1)%96,96+(i+1)%96,96+i) for i in range(96)];return mesh(name,p,f,water)
ring('LowerWater',.49,2.25,.75);ring('UpperWater',.31,.77,2.25)
for side in [-1,1]:
 # Narrow horizontal channels through the carved notches, inside the upper cup.
 mesh('WaterChannel',[(side*.71,2.25,-.035),(side*1.07,2.25,-.035),(side*1.07,2.25,.035),(side*.71,2.25,.035)],[(3,2,1,0) if side>0 else (0,1,2,3)],water)
 p=[(side*1.07+math.cos(i*math.tau/12)*.017,y,math.sin(i*math.tau/12)*.017) for y in [.75,2.25] for i in range(12)]
 mesh('WaterStream',p,[(12+i,12+(i+1)%12,(i+1)%12,i) for i in range(12)],water)
bpy.ops.object.select_all(action='SELECT');bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'MarketFountain.blend'))
# Shared runtime materials supply the production stone and water shader.
for link in list(stone.node_tree.links):stone.node_tree.links.remove(link)
bpy.ops.export_scene.gltf(filepath=str(OUT/'MarketFountain.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
(OUT/'construction.json').write_text(json.dumps({'state':'CANDIDATE_NOT_INTEGRATED','source':'Project-authored Blender lathe; existing CC0 production stone photograph','triangles':sum(len(p.vertices)-2 for o in bpy.data.objects if o.type=='MESH' for p in o.data.polygons),'lower_water_y':.75,'lower_rim_y':1.06,'upper_water_y':2.25,'upper_rim_y':2.4,'segments':segments,'fountain_height':2.94,'root_y':0,'notches':2,'art_acceptance':False},indent=2))
print('MARKET_FOUNTAIN_AUTHORED grounded_bowl=true actual_rim_notches=2 water_below_rims=true source_only=true')
