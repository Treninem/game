"""Bake matching UV/topology normals without rays crossing thin cloth layers."""
import bpy,json,hashlib,time,os
from pathlib import Path
r=Path(__file__).resolve().parents[1];source=Path(os.environ.get('IMPULS_CHARACTER_OUTPUT',str(r/'build/asset_work/viking-humans')));out=r/'build/asset_work/viking-materials'
manifest=json.loads((out/'manifest.json').read_text());rows=manifest['maps']
for sex in ['male','female']:
    bpy.ops.wm.open_mainfile(filepath=str(source/(sex+'.blend')))
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.render.threads_mode='FIXED';scene.render.threads=2
    scene.render.bake.use_multires=True
    choices=[item.identifier for item in scene.render.bake.bl_rna.properties['type'].enum_items]
    assert 'NORMALS' in choices,choices
    scene.render.bake.type='NORMALS';scene.render.bake.margin=8;scene.render.bake.use_clear=True
    bpy.data.objects['HumanRig'].data.pose_position='REST'
    for name in ['Clothing','Boots']:
        original=bpy.data.objects[name];obj=original.copy();obj.data=original.data.copy();obj.name=name+'MultiresBake'
        bpy.context.collection.objects.link(obj);obj.shape_key_clear()
        for modifier in list(obj.modifiers):obj.modifiers.remove(modifier)
        bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
        modifier=obj.modifiers.new('CorrespondingSurface','MULTIRES')
        for _ in range(2):bpy.ops.object.multires_subdivide(modifier=modifier.name,mode='CATMULL_CLARK')
        modifier.levels=0;modifier.render_levels=2;modifier.sculpt_levels=2
        images=[]
        for slot in obj.material_slots:
            material=slot.material;image=bpy.data.images.new(sex+'-'+material.name+'-multires',width=1024,height=1024,alpha=False)
            image.colorspace_settings.name='Non-Color';image.generated_color=(.5,.5,1,1)
            node=material.node_tree.nodes.new('ShaderNodeTexImage');node.image=image;material.node_tree.nodes.active=node;images.append((material.name,image))
        start=time.monotonic();bpy.ops.object.bake_image()
        for label,image in images:
            p=out/(sex+'-'+label.lower()+'-normal.png');image.filepath_raw=str(p);image.file_format='PNG';image.save()
            rows=[row for row in rows if row['file']!=p.name]
            rows.append({'sex':sex,'material':label,'kind':'NORMAL','resolution':1024,'file':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bake_seconds':round(time.monotonic()-start,2),'method':'Multires level 0 to 2; same UV/topology, no selected-to-active ray projection'})
        bpy.data.objects.remove(obj,do_unlink=True);print('MULTIRES_NORMAL_OK',sex,name,flush=True)
manifest['maps']=rows;manifest['method']='AO from fitted rest geometry, Cycles CPU 16 samples; normals from same-topology multires, no cage rays';manifest['normal_method']='Multires level 0 to 2, tangent space, margin 8, same topology/UV, no cage rays'
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8');print('MULTIRES_WARDROBE_OK',flush=True)
