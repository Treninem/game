"""Render existing B89 candidates for visual rejection/selection.
Run with Blender --background --disable-autoexec --threads 2 --python-exit-code 1
--python tools/render_character_auditions.py from the project root.
Outputs stay in build/asset_work/human-audition; no live asset is replaced.
"""
import bpy,math,json
from pathlib import Path
from mathutils import Vector,Matrix
r=Path.cwd();folder=r/'build/asset_work/human-audition';sources=[('textured_source',folder/'pintar8.blend'),('male_homen5',folder/'HOMEN5.fbx'),('female_outfit',r/'assets/staging/sourcechat_b89/models/oga_character_pack_2026/part3/BRAVOS_GAME_BR_PART_3/Woman in Action Outfit/mulher_update3.blend')];audit=[]
# Reuse the existing physically staged B89 sources. Never download equivalent packs.
import zipfile
folder.mkdir(parents=True, exist_ok=True)
source_pack=r/'assets/staging/sourcechat_b89/models/oga_character_pack_2026'
for archive, entries in {'model3dtextura.zip':['pintar8.blend','FACE6.png','ZEGAME_OLHO3.png'],'homen5.zip':['HOMEN5.fbx']}.items():
 source_zip=next(source_pack.rglob(archive))
 with zipfile.ZipFile(source_zip) as z:
  for name in entries:(folder/name).write_bytes(z.read(name))

for tag,source in sources:
 if source.suffix=='.blend':bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False)
 else:
  bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(source))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and not o.hide_render]
 for image in bpy.data.images:
  match=folder/Path(image.filepath.replace(chr(92),'/')).name
  if match.is_file():image.filepath=str(match);image.reload()
 missing=[i.name for i in bpy.data.images if i.source=='FILE' and not i.packed_file and i.size[0]==0]
 points=[o.matrix_world@Vector(c) for o in meshes for c in o.bound_box];low=Vector([min(p[i] for p in points) for i in range(3)]);high=Vector([max(p[i] for p in points) for i in range(3)])
 conversion=Matrix.Rotation(math.pi/2,4,'X') if (high-low).y>(high-low).z*1.4 else Matrix.Identity(4)
 points=[conversion@p for p in points];low=Vector([min(p[i] for p in points) for i in range(3)]);high=Vector([max(p[i] for p in points) for i in range(3)]);height=high.z-low.z;center=Vector([(low.x+high.x)/2,(low.y+high.y)/2,low.z]);normal=Matrix.Scale(1.8/height,4)@Matrix.Translation(-center)@conversion
 for o in meshes:
  o.matrix_world=normal@o.matrix_world
  for poly in o.data.polygons:poly.use_smooth=True
 for o in list(bpy.context.scene.objects):
  if o not in meshes:bpy.data.objects.remove(o,do_unlink=True)
 scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=12;scene.render.threads_mode='FIXED';scene.render.threads=2;scene.render.resolution_x=512;scene.render.resolution_y=640;scene.render.resolution_percentage=100
 world=bpy.data.worlds.new('AuditStudio');world.use_nodes=True;background=world.node_tree.nodes.new('ShaderNodeBackground');background.inputs[0].default_value=(.16,.18,.21,1);background.inputs[1].default_value=.45;output=world.node_tree.nodes.new('ShaderNodeOutputWorld');world.node_tree.links.new(background.outputs[0],output.inputs['Surface']);scene.world=world
 for pos,power,size in [((3,-4,5),450,3),((-3,-1,3),220,3),((0,3,4),300,2)]:
  light=bpy.data.lights.new('AuditLight','AREA');light.energy=power;light.shape='DISK';light.size=size;obj=bpy.data.objects.new('AuditLight',light);scene.collection.objects.link(obj);obj.location=pos;obj.rotation_euler=(Vector((0,0,1))-obj.location).to_track_quat('-Z','Y').to_euler()
 camera=bpy.data.cameras.new('AuditCamera');obj=bpy.data.objects.new('AuditCamera',camera);scene.collection.objects.link(obj);obj.location=(2.6,-4,1.6);obj.rotation_euler=(Vector((0,0,.95))-obj.location).to_track_quat('-Z','Y').to_euler();camera.type='ORTHO';camera.ortho_scale=2.25;scene.camera=obj
 scene.render.filepath=str(folder/(tag+'.png'));scene.render.image_settings.file_format='PNG';bpy.ops.render.render(write_still=True)
 audit.append({'candidate':tag,'source':str(source),'meshes':[{'name':o.name,'vertices':len(o.data.vertices)} for o in meshes],'missing_images':missing,'preview':tag+'.png'})
(folder/'audition-audit.json').write_text(json.dumps(audit,indent=2),encoding='utf-8');print('HUMAN_AUDITIONS_RENDERED')
