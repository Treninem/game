"""Apply the selected portable production maps to the editable Blender roof.

Geometry is not re-exported: Godot uses shared .tres overrides. This updates
only an explicitly selected source output. Replacing a file requires its exact
owned hash, and a production-source write also requires a fresh main check.
"""
from pathlib import Path
import bpy,os,hashlib,subprocess
R=Path(__file__).resolve().parents[1]
SOURCE=Path(os.environ['IMPULS_ROOF_BLEND_INPUT']);OUTPUT=Path(os.environ['IMPULS_ROOF_BLEND_OUTPUT'])
assert SOURCE.is_file()
expected=os.environ.get('IMPULS_ROOF_BLEND_OWNED_SHA256')
if OUTPUT.exists():assert expected and hashlib.sha256(OUTPUT.read_bytes()).hexdigest()==expected,'Do not overwrite another authoring file'
bpy.ops.wm.open_mainfile(filepath=str(SOURCE),load_ui=False)
family=R/'assets/production/exteriors/family_home';plaster=R/'assets/production/interiors/materials/lime_plaster'
entries={'RoofShingle':(family/'roof_shingles.jpg',(.9,.87,.81,1)),'Timber':(family/'cedar.png',(.5,.46,.38,1)),'Stone':(family/'stone.png',(.8,.78,.72,1)),'Plaster':(plaster/'albedo.jpg',(.88,.87,.81,1))}
for role,(path,color) in entries.items():
 material=bpy.data.materials.get(role);assert material is not None
 material.use_nodes=True;nodes=material.node_tree.nodes;links=material.node_tree.links;bs=nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.9
 tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(path),check_existing=True);tex.image.colorspace_settings.name='sRGB'
 multiply=nodes.new('ShaderNodeMixRGB');multiply.blend_type='MULTIPLY';multiply.inputs[0].default_value=1;multiply.inputs[2].default_value=color;links.new(tex.outputs['Color'],multiply.inputs[1]);links.new(multiply.outputs[0],bs.inputs['Base Color'])
 if role=='Plaster':
  coordinate=nodes.new('ShaderNodeTexCoord');scale=nodes.new('ShaderNodeVectorMath');scale.operation='SCALE';scale.inputs['Scale'].default_value=.5;links.new(coordinate.outputs['Object'],scale.inputs[0]);links.new(scale.outputs[0],tex.inputs['Vector']);tex.projection='BOX';tex.projection_blend=.2
  for label in ['normal','orm']:
   image=nodes.new('ShaderNodeTexImage');image.image=bpy.data.images.load(str(plaster/(label+'.png')),check_existing=True);image.image.colorspace_settings.name='Non-Color';image.projection='BOX';image.projection_blend=.2;links.new(scale.outputs[0],image.inputs['Vector'])
   if label=='normal':
    normal=nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.35;links.new(image.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs[0],bs.inputs['Normal'])
   else:
    separate=nodes.new('ShaderNodeSeparateColor');links.new(image.outputs['Color'],separate.inputs[0]);links.new(separate.outputs['Green'],bs.inputs['Roughness'])
for image in bpy.data.images:
 if image.source=='FILE':image.filepath=bpy.path.relpath(bpy.path.abspath(image.filepath),start=str(OUTPUT.parent))
if OUTPUT.is_relative_to(R/'assets'):
 remote=subprocess.check_output(['git','ls-remote','origin','refs/heads/main'],cwd=R).decode();assert os.environ['IMPULS_EXPECTED_MAIN'] in remote
 if OUTPUT.exists():assert expected and hashlib.sha256(OUTPUT.read_bytes()).hexdigest()==expected
bpy.context.preferences.filepaths.file_preview_type='NONE';bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT),relative_remap=False)
print('REGION_ROOF_AUTHORING_LINKED portable_images=6 geometry_unchanged=true')
