"""Export the editable ImPuls canal kit in Blender; never overwrite a source.

Set IMPULS_CANAL_TREE to a new private output directory. Optionally select
IMPULS_CANAL_SOURCE to inspect another saved revision of the editable kit.
Shared photo/normal maps stay in their canonical production folders.
"""
from pathlib import Path
import os, json, hashlib
import bpy

ROOT=Path(__file__).resolve().parents[1]
SOURCE=Path(os.environ.get('IMPULS_CANAL_SOURCE',ROOT/'assets/source/architecture/capital_canal/CapitalCanalKit.blend')).resolve()
destination=os.environ.get('IMPULS_CANAL_TREE')
if not destination:raise RuntimeError('Select a new private IMPULS_CANAL_TREE output directory')
DEST=Path(destination).resolve()
if DEST.exists():raise FileExistsError(DEST)
assert SOURCE.is_file(),SOURCE
source_sha=hashlib.sha256(SOURCE.read_bytes()).hexdigest()
DEST.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE),load_ui=False)
bpy.context.preferences.filepaths.file_preview_type='NONE'
expected={'DeckAndApproaches':1408,'MeasuredArchVaults':14784,'ParapetsAndCaps':10736,'PiersAndSpandrels':13504,'QuayWall6m':2916}
counts={obj.name:sum(len(p.vertices)-2 for p in obj.data.polygons) for obj in bpy.data.objects if obj.type=='MESH'}
assert counts==expected,counts
images={}
for img in bpy.data.images:
 if img.source!='FILE' or not img.users:continue
 assert img.filepath.startswith('//'),img.filepath
 path=Path(bpy.path.abspath(img.filepath));assert path.is_file(),path
 images[img.name]={'relative_path':img.filepath,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
assert len(images)>=3,images
# Godot uses the selected canonical textures, not copies embedded into each
# bridge instance. Keep editable .blend material connections intact on disk.
for material in bpy.data.materials:
 if material.node_tree:
  for link in list(material.node_tree.links):
   if link.from_node.type=='TEX_IMAGE':material.node_tree.links.remove(link)
target=DEST/'CapitalCanalKit.glb'
bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',export_apply=True,export_yup=True)
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==source_sha
report={'source_sha256':source_sha,'source_modified':False,'parts':counts,'triangles':sum(counts.values()),'relative_images':images,'output_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'third_party_downloads':0}
(DEST/'export-proof.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('CAPITAL_CANAL_EDITABLE_EXPORT_OK',json.dumps(report))
