"""Relink copied city sources within a matching assets/source + production tree.

Run in Blender with IMPULS_CITY_PORTABLE_ROOT pointing at a new private tree.
The same relative paths remain valid when the tree is promoted to the project.
No source geometry, UV, normals or exported GLB is changed.
"""
from pathlib import Path
import bpy,os,json,hashlib,struct
P=Path(os.environ['IMPULS_CITY_PORTABLE_ROOT'])
bpy.context.preferences.filepaths.file_preview_type='NONE';bpy.context.preferences.filepaths.save_version=0
def signature():
 h=hashlib.sha256()
 for obj in sorted((o for o in bpy.data.objects if o.type=='MESH'),key=lambda o:o.name):
  h.update(obj.name.encode())
  for vertex in obj.data.vertices:h.update(struct.pack('<3f',*vertex.co))
  for face in obj.data.polygons:
   for index in face.vertices:h.update(struct.pack('<I',index))
  for layer in obj.data.uv_layers:
   for loop in layer.data:h.update(struct.pack('<2f',*loop.uv))
 return h.hexdigest()
entries=[]
for family,names in [('townhouse',['Townhouse_2','Townhouse_3']),('market_court',['MarketFountain'])]:
 for name in names:
  path=P/'assets/source/architecture'/family/(name+'.blend')
  bpy.ops.wm.open_mainfile(filepath=str(path),load_ui=False);before=signature()
  for image in bpy.data.images:
   if image.source!='FILE':continue
   filename=Path(bpy.path.abspath(image.filepath)).name
   if filename.startswith('clay_'):target=P/'assets/production/architecture/townhouse'/filename
   elif filename=='albedo.jpg':target=P/'assets/production/interiors/materials/lime_plaster'/filename
   elif filename in ['cedar.png','stone.png']:target=P/'assets/production/exteriors/family_home'/filename
   else:raise AssertionError('Unreviewed source image '+filename)
   assert target.is_file(),target
   image.filepath=bpy.path.relpath(str(target),start=str(path.parent))
  bpy.ops.wm.save_as_mainfile(filepath=str(path),relative_remap=False)
  assert signature()==before
  entries.append({'source':path.relative_to(P).as_posix(),'geometry_uv_sha256':before,'all_images_relative_and_exist':all(i.filepath.startswith('//') and Path(bpy.path.abspath(i.filepath)).is_file() for i in bpy.data.images if i.source=='FILE')})
  assert entries[-1]['all_images_relative_and_exist']
(P/'source-verification.json').write_text(json.dumps(entries,indent=2))
print('CITY_AUTHORING_PORTABLE_OK sources=3 geometry_uv_preserved=true relative_images=true')
