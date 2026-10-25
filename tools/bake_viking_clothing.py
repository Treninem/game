"""Bake UV-matched maps from the actual candidate geometry, offline on CPU.

AO uses the fitted rest-pose body/garments. Then run
bake_viking_multires_normals.py for production-candidate tangent normals.
The opt-in NORMAL mode retains the rejected cage-projection experiment for
regression comparison; it is not the accepted normal-map method.
"""
import bpy,os,json,time,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SOURCE=Path(os.environ.get('IMPULS_CHARACTER_OUTPUT',str(ROOT/'build/asset_work/viking-humans')))
OUT=Path(os.environ.get('IMPULS_WARDROBE_MAPS',str(ROOT/'build/asset_work/viking-materials')))
OUT.mkdir(parents=True,exist_ok=True)
rows=[]
if (OUT/'manifest.json').exists():rows=json.loads((OUT/'manifest.json').read_text())['maps']
for sex in ['male','female']:
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE/(sex+'.blend')))
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=16
    scene.render.threads_mode='FIXED';scene.render.threads=2
    scene.render.bake.margin=8;scene.render.bake.use_clear=True
    scene.render.bake.normal_space='TANGENT';scene.render.bake.cage_extrusion=.004
    scene.render.bake.max_ray_distance=.01
    bpy.data.objects['HumanRig'].data.pose_position='REST'
    bpy.context.view_layer.update()
    for name in ['Clothing','Boots']:
        obj=bpy.data.objects[name]
        for kind in os.environ.get('IMPULS_BAKE_KINDS','AO').split(','):
            images=[]
            for slot in obj.material_slots:
                material=slot.material;label=material.name
                image=bpy.data.images.new(sex+'-'+label+'-'+kind,width=1024,height=1024,alpha=False)
                image.colorspace_settings.name='Non-Color'
                image.generated_color=(1,1,1,1) if kind=='AO' else (.5,.5,1,1)
                node=material.node_tree.nodes.new('ShaderNodeTexImage');node.image=image
                material.node_tree.nodes.active=node;images.append((label,image))
            bpy.ops.object.select_all(action='DESELECT')
            high=None
            if kind=='NORMAL':
                high=obj.copy();high.data=obj.data.copy();high.name=name+'BakeHigh'
                bpy.context.collection.objects.link(high)
                modifier=high.modifiers.new('BakeSubdivision','SUBSURF');modifier.levels=2;modifier.render_levels=2
                high.select_set(True)
            obj.select_set(True);bpy.context.view_layer.objects.active=obj
            scene.render.bake.use_selected_to_active=kind=='NORMAL'
            start=time.monotonic();bpy.ops.object.bake(type=kind)
            for label,image in images:
                path=OUT/('%s-%s-%s.png'%(sex,label.lower(),kind.lower()))
                image.filepath_raw=str(path);image.file_format='PNG';image.save()
                rows=[row for row in rows if row['file']!=path.name]
                rows.append({'sex':sex,'material':label,'kind':kind,'resolution':1024,'file':path.name,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'bake_seconds':round(time.monotonic()-start,2),'cage_m':.004 if kind=='NORMAL' else None,'max_ray_m':.01 if kind=='NORMAL' else None})
            if high is not None:bpy.data.objects.remove(high,do_unlink=True)
            print('VIKING_BAKE_OK',sex,name,kind,flush=True)
(OUT/'manifest.json').write_text(json.dumps({'method':'Cycles CPU 16 samples; rest-pose fitted geometry AO; subdivision level 2 selected-to-active tangent normal; margin 8; cage .004m; max ray .01m','maps':rows},indent=2)+'\n',encoding='utf-8')
print('VIKING_MATERIAL_MAPS_OK',len(rows),flush=True)
