"""Blender-authored restrained skin surface detail on the existing native UVs.

No color texture, geometry, rig, morph or animation is replaced. This is an
authored procedural micro-surface, not a scan or a photorealism claim.
Default output is isolated; source .blend documents are never overwritten.
"""
from pathlib import Path
import bpy,os,json,time,hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(os.environ.get('IMPULS_SKIN_DETAIL_OUTPUT',str(ROOT/'build/asset_work/human-surfaces-2026-10-23/skin-candidate')))
assert not OUT.exists(), 'Choose a fresh output directory; do not overwrite a reviewed candidate'
OUT.mkdir(parents=True)
rows=[]
for sex in ['male','female']:
    source=ROOT/'assets/source/characters/refined_contours'/(sex+'.blend')
    bpy.ops.wm.open_mainfile(filepath=str(source))
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=1
    scene.render.threads_mode='FIXED';scene.render.threads=2
    scene.render.bake.use_selected_to_active=False;scene.render.bake.margin=12;scene.render.bake.use_clear=True
    bpy.data.objects['HumanRig'].data.pose_position='REST'
    original=bpy.data.objects['HumanBody']
    obj=original.copy();obj.data=original.data.copy();obj.name='SkinDetailBake'
    bpy.context.collection.objects.link(obj);obj.shape_key_clear()
    for modifier in list(obj.modifiers):obj.modifiers.remove(modifier)
    bpy.ops.object.select_all(action='DESELECT');obj.hide_set(False);obj.hide_render=False
    obj.select_set(True);bpy.context.view_layer.objects.active=obj
    mat=bpy.data.materials.new('AuthoredSkinMicroSurface');mat.use_nodes=True
    obj.data.materials.clear();obj.data.materials.append(mat)
    nodes=mat.node_tree.nodes;links=mat.node_tree.links;nodes.clear()
    output=nodes.new('ShaderNodeOutputMaterial');bsdf=nodes.new('ShaderNodeBsdfPrincipled');links.new(bsdf.outputs['BSDF'],output.inputs['Surface'])
    geometry=nodes.new('ShaderNodeNewGeometry')
    noise=nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=950;noise.inputs['Detail'].default_value=2.0;noise.inputs['Roughness'].default_value=.65
    links.new(geometry.outputs['Position'],noise.inputs['Vector'])
    bump=nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.3;bump.inputs['Distance'].default_value=.00010
    links.new(noise.outputs['Fac'],bump.inputs['Height']);links.new(bump.outputs['Normal'],bsdf.inputs['Normal'])
    rough=nodes.new('ShaderNodeMapRange');rough.inputs['From Min'].default_value=0;rough.inputs['From Max'].default_value=1
    rough.inputs['To Min'].default_value=.50;rough.inputs['To Max'].default_value=.68
    links.new(noise.outputs['Fac'],rough.inputs['Value']);links.new(rough.outputs['Result'],bsdf.inputs['Roughness'])
    targets=[]
    for kind in ['normal','roughness']:
        im=bpy.data.images.new(sex+'-skin-'+kind,width=2048,height=2048,alpha=False)
        im.colorspace_settings.name='Non-Color';im.generated_color=(.5,.5,1,1) if kind=='normal' else (.59,.59,.59,1)
        node=nodes.new('ShaderNodeTexImage');node.image=im;nodes.active=node
        start=time.monotonic()
        bpy.ops.object.bake(type='NORMAL' if kind=='normal' else 'ROUGHNESS',normal_space='TANGENT')
        path=OUT/(sex+'-skin-'+kind+'.png');im.filepath_raw=str(path);im.file_format='PNG';im.save()
        targets.append(path.name)
        rows.append({'sex':sex,'kind':kind,'file':path.name,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'seconds':round(time.monotonic()-start,2),'size':[2048,2048]})
        print('SKIN_DETAIL_MAP_OK',json.dumps(rows[-1]),flush=True)
    # A portable small authoring scene contains only the bake surface/material.
    # The rig/source is retained separately; exported game geometry is unchanged.
    for other in list(bpy.data.objects):
        if other!=obj:bpy.data.objects.remove(other,do_unlink=True)
    for im in bpy.data.images:
        if im.name.startswith(sex+'-skin-') and im.filepath:
            im.filepath='//'+Path(im.filepath).name
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(sex+'-skin-authoring.blend')))
manifest={'method':'Blender Cycles CPU tangent normal and linear roughness; existing native UVs; procedural 0.10 mm bump at strength 0.30; no geometry/color changes','source_family':'assets/source/characters/refined_contours','maps':rows}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('HUMAN_SKIN_DETAIL_OK maps=4',flush=True)
