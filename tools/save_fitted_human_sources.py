"""Save portable editable sources without packing duplicate source textures.

Run in factory Blender after build_viking_humans.py. The candidate directory
is selected by IMPULS_CHARACTER_OUTPUT; production GLBs are never written.
"""
from pathlib import Path
import os
import bpy

ROOT = Path(__file__).resolve().parents[1]
candidate = Path(os.environ.get('IMPULS_CHARACTER_OUTPUT', str(ROOT/'build/asset_work/lined-humans')))
target = ROOT/'assets/source/characters/fitted_outfit'
target.mkdir(parents=True, exist_ok=True)
for sex in ['male', 'female']:
    bpy.ops.wm.open_mainfile(filepath=str(candidate/(sex+'.blend')))
    bpy.context.preferences.filepaths.file_preview_type = 'NONE'
    for image in bpy.data.images:
        if image.source != 'FILE' or not image.filepath:
            continue
        path = Path(bpy.path.abspath(image.filepath)).resolve()
        assert path.is_relative_to(ROOT) and path.is_file(), (image.name, str(path))
        image.filepath = '//'+os.path.relpath(path, target).replace('\\', '/')
    bpy.ops.wm.save_as_mainfile(filepath=str(target/(sex+'.blend')), relative_remap=False)
    print('PORTABLE_FITTED_SOURCE_OK', sex, flush=True)
