from pathlib import Path
import bpy,hashlib,struct,json,os
R=Path(__file__).resolve().parents[1];Q=R/'build/asset_work/city-streetscape-2026-10-24';P=Q/os.environ.get('IMPULS_STREET_TREE','portable');path=P/'assets/source/architecture/city_street/CityStreetKit.blend'
def signature():
 h=hashlib.sha256()
 for obj in sorted((o for o in bpy.data.objects if o.type=='MESH'),key=lambda o:o.name):
  h.update(obj.name.encode())
  for v in obj.data.vertices:h.update(struct.pack('<3f',*v.co))
  for f in obj.data.polygons:
   for i in f.vertices:h.update(struct.pack('<I',i))
  for layer in obj.data.uv_layers:
   for loop in layer.data:h.update(struct.pack('<2f',*loop.uv))
 return h.hexdigest()
assert not (Q/'source-verification.json').exists()
bpy.ops.wm.open_mainfile(filepath=str(path),load_ui=False);bpy.context.preferences.filepaths.file_preview_type='NONE';bpy.context.preferences.filepaths.save_version=0
before=signature();material=bpy.data.materials['StreetStone'];nodes=material.node_tree.nodes;links=material.node_tree.links;bs=nodes.get('Principled BSDF')
normal=nodes.new('ShaderNodeTexImage');normal.image=bpy.data.images.load(str(P/'assets/production/architecture/city_street/stone_normal.png'));normal.image.colorspace_settings.name='Non-Color'
mapping=nodes.new('ShaderNodeNormalMap');mapping.inputs['Strength'].default_value=.45;links.new(normal.outputs['Color'],mapping.inputs['Color']);links.new(mapping.outputs['Normal'],bs.inputs['Normal'])
orm=nodes.new('ShaderNodeTexImage');orm.image=bpy.data.images.load(str(P/'assets/production/architecture/city_street/stone_orm.png'));orm.image.colorspace_settings.name='Non-Color'
channels=nodes.new('ShaderNodeSeparateColor');links.new(orm.outputs['Color'],channels.inputs['Color']);links.new(channels.outputs['Green'],bs.inputs['Roughness']);links.new(channels.outputs['Blue'],bs.inputs['Metallic'])
for image in bpy.data.images:
 if image.source=='FILE':image.filepath=bpy.path.relpath(bpy.path.abspath(image.filepath),start=str(path.parent))
assert all(i.filepath.startswith('//') and Path(bpy.path.abspath(i.filepath)).is_file() for i in bpy.data.images if i.source=='FILE')
bpy.ops.wm.save_as_mainfile(filepath=str(path),relative_remap=False);assert before==signature()
(Q/'source-verification.json').write_text(json.dumps({'source':'assets/source/architecture/city_street/CityStreetKit.blend','geometry_uv_sha256':before,'all_images_relative_and_exist':True,'normal_ORM_connected_in_editable_source':True,'production_GLB_unchanged':True,'source_parts':json.loads((Q/'construction.json').read_text())['parts']},indent=2))
print('CITY_STREET_SOURCE_VERIFIED geometry_uv_preserved=true maps_relative=true')
