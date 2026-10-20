"""Build clothed, morphable CC0 MakeHuman characters on an authored native rig.

Run with Blender --background --factory-startup --disable-autoexec --python ...
Outputs go to build/asset_work/realistic_humans for inspection before promotion.
No MPFB executable code is required or embedded in the game.
"""
from pathlib import Path
import bpy, json, math, gzip, re, os
from mathutils import Vector, Matrix, Quaternion

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / 'assets/staging/characters/makehuman_mpfb_core'
SYSTEM = ROOT / 'assets/staging/characters/makehuman_system_selected'
OUT = Path(os.environ.get('IMPULS_CHARACTER_OUTPUT', str(ROOT / 'build/asset_work/realistic_humans')))
OUT.mkdir(parents=True, exist_ok=True)
CONVERT = Matrix.Rotation(math.pi / 2, 4, 'X')

def read_obj(path):
    verts, uv, faces, face_uv, groups = [], [], [], [], []
    group = ''
    for line in path.read_text(encoding='utf-8').splitlines():
        words = line.split()
        if not words: continue
        if words[0] == 'v': verts.append(Vector(map(float, words[1:4])))
        elif words[0] == 'vt': uv.append(tuple(map(float, words[1:3])))
        elif words[0] == 'g': group = words[1]
        elif words[0] == 'f':
            parts = [w.split('/') for w in words[1:]]
            faces.append([int(w[0])-1 for w in parts])
            face_uv.append([int(w[1])-1 if len(w)>1 and w[1] else -1 for w in parts])
            groups.append(group)
    return verts, uv, faces, face_uv, groups

BASE, UV, FACES, FACE_UV, GROUPS = read_obj(CORE / '3dobjs/base.obj')
RIG = json.loads((CORE/'rigs/standard/rig.mixamo.json').read_text())['bones']
W = [{} for _ in BASE]
for name, values in json.loads((CORE/'rigs/standard/weights.mixamo.json').read_text())['weights'].items():
    for index, weight in values: W[index][name.split(':')[-1]] = weight

def target(name):
    result = {}
    for line in gzip.decompress((CORE/'targets'/name).read_bytes()).decode().splitlines():
        a=line.split()
        if len(a)==4 and not line.startswith('#'): result[int(a[0])] = Vector(map(float,a[1:]))
    return result

def morph(points, change, value=1):
    result = [p.copy() for p in points]
    for i, delta in change.items(): result[i] += delta * value
    return result

BOTTOM = 0.0
BODY_SCALE = 0.1
def coord(p): return CONVERT @ ((p - Vector((0, BOTTOM, 0))) * BODY_SCALE)

def mapping(path):
    records=[];scales={};deleted=set();state=''
    for line in path.read_text().splitlines():
        a=line.split()
        if not a or a[0].startswith('#'): continue
        if a[0] in ['x_scale','y_scale','z_scale']:scales[a[0][0]]=(int(a[1]),int(a[2]),float(a[3]))
        elif a[0]=='verts':state='verts'
        elif a[0]=='delete_verts':state='deleted'
        elif state=='verts' and a[0][0].isdigit():
            records.append(([int(x) for x in a[:3]],list(map(float,a[3:6])),Vector(map(float,a[6:9]))) if len(a)>=9 else ([int(a[0])],[1.0],Vector()))
        elif state=='deleted':
            for match in re.finditer(r'(\d+)\s*-\s*(\d+)|(\d+)',line):
                deleted.update(range(int(match[1]),int(match[2])+1) if match[1] else [int(match[3])])
    return records,scales,deleted

def fitted(points, records, scales):
    factors={axis:abs(points[a]['xyz'.index(axis)]-points[b]['xyz'.index(axis)])/distance for axis,(a,b,distance) in scales.items()}
    result=[]
    for indices, weights, offset in records:
        p=sum((points[i]*w for i,w in zip(indices,weights)),Vector())
        result.append(p+Vector(tuple(offset[i]*factors.get(axis,1) for i,axis in enumerate('xyz'))))
    return result

def fitted_weights(records):
    result=[]
    for indices, weights, _ in records:
        values={}
        for i,w in zip(indices,weights):
            for bone,v in W[i].items(): values[bone]=values.get(bone,0)+max(0,w)*v
        selected=sorted(values.items(),key=lambda x:-x[1])[:4];total=sum(v for _,v in selected)
        result.append({b:v/total for b,v in selected} if total else {'Hips':1})
    return result

def smooth_weights(weights, faces):
    neighbours=[set() for _ in weights]
    edge_uses={}
    for face in faces:
        for a,b in zip(face,face[1:]+face[:1]):
            neighbours[a].add(b);neighbours[b].add(a)
            edge=tuple(sorted((a,b)));edge_uses[edge]=edge_uses.get(edge,0)+1
    # The authored body mask meets the neckline, cuffs and hems exactly.
    # Diffusing weights over these openings makes skin poke through the collar.
    boundary={v for edge,count in edge_uses.items() if count==1 for v in edge}
    anchored=boundary|{v for b in boundary for v in neighbours[b]}
    original=weights
    for _ in range(12):
        result=[]
        for i,values in enumerate(weights):
            if i in anchored:
                result.append(original[i]);continue
            mixed={bone:value*.5 for bone,value in values.items()}
            for j in neighbours[i]:
                for bone,value in weights[j].items():mixed[bone]=mixed.get(bone,0)+value*.5/max(1,len(neighbours[i]))
            selected=sorted(mixed.items(),key=lambda pair:-pair[1])[:4];total=sum(v for _,v in selected)
            result.append({bone:value/total for bone,value in selected})
        weights=result
    return weights

def fit_garment(points, records, scales):
    fitted_points=fitted(points,records,scales)
    # The authored male sleeves can extend over a smaller female hand. End the
    # fitted cuff at the native wrist rather than hiding fingers in the sleeve.
    for side in ['l','r']:
        def joint(part):
            ids=set(i for f,g in zip(FACES,GROUPS) if g=='joint-'+side+'-'+part for i in f)
            return sum((points[i] for i in ids),Vector())/len(ids)
        wrist=joint('hand');direction=(wrist-joint('elbow')).normalized()
        for p in fitted_points:
            distance=(p-wrist).length*BODY_SCALE;along=(p-wrist).dot(direction)*BODY_SCALE
            if distance<.18 and along>-.015:p-=direction*((along+.015)/BODY_SCALE)
    return fitted_points

def create_garment(points, variations, rig):
    source=SYSTEM/'clothes/male_casualsuit01/male_casualsuit01'
    records,scales,deleted=mapping(source.with_suffix('.mhclo'))
    _,uv,faces,fuv,_=read_obj(source.with_suffix('.obj'))
    garment=mesh('Clothing',fit_garment(points,records,scales),faces,uv,fuv,smooth_weights(fitted_weights(records),faces),rig,material('ClothTunic',(.28,.20,.11,1)),{name:fit_garment(other,records,scales) for name,other in variations.items()})
    garment.data.materials.append(material('ClothTrousers',(.085,.075,.055,1)))
    # The authored UV islands separate shirt panels from trousers, while the
    # physical seam is joined. Keep colors on these islands, never a height cut.
    uv_faces={}
    for i,indices in enumerate(fuv):
        for index in indices:uv_faces.setdefault(index,set()).add(i)
    unseen=set(range(len(faces)));fitted_points=fit_garment(points,records,scales)
    while unseen:
        stack=[next(iter(unseen))];piece=set()
        while stack:
            i=stack.pop()
            if i in piece:continue
            piece.add(i)
            for index in fuv[i]:stack.extend(uv_faces[index]-piece)
        unseen-=piece
        index=0 if max(coord(fitted_points[v]).z for f in piece for v in faces[f])>1.2 else 1
        for i in piece:garment.data.polygons[i].material_index=index
    garment_clearance(garment)
    return garment

def garment_clearance(garment):
    # Preserve the authored folds while separating coincident cloth/skin by
    # three millimetres. Apply the same shell to every synchronized morph.
    normals=[v.normal.copy() for v in garment.data.vertices]
    for shape in garment.data.shape_keys.key_blocks:
        for vertex,normal in zip(shape.data,normals):vertex.co+=normal*.003
    garment.data.update()

def create_variations(points):
    changes={
        'FaceWidth':target('head/head-scale-horiz-incr.target.gz'),
        'FaceHeight':target('head/head-scale-vert-incr.target.gz'),
        'FaceDepth':target('head/head-scale-depth-incr.target.gz'),
        'Nose':target('nose/nose-scale-depth-incr.target.gz'),
        'NoseWidth':target('nose/nose-scale-horiz-incr.target.gz'),
        'NoseHeight':target('nose/nose-scale-vert-incr.target.gz'),
        'Jaw':target('chin/chin-width-incr.target.gz')}
    # Use the authored head-axis fields on every fitted part, not a bone scale.
    head_size={}
    for axis in ['FaceWidth','FaceHeight','FaceDepth']:
        for index,delta in changes[axis].items():
            head_size[index]=head_size.get(index,Vector())+delta*.6
    changes['HeadSize']=head_size
    result={name:morph(points,delta) for name,delta in changes.items()}
    build=[p.copy() for p in points]
    for i,p in enumerate(build):
        influence=sum(value for bone,value in W[i].items() if bone in ['Hips','Spine','Spine1','Spine2'])
        p.x*=1+.13*influence;p.z*=1+.10*influence
    result['Build']=build
    return result

def create_body(points, variations, rig, sex):
    _,_,deleted=mapping(SYSTEM/'clothes/male_casualsuit01/male_casualsuit01.mhclo')
    _,_,shoe_mask=mapping(SYSTEM/'clothes/shoes03/shoes03.mhclo')
    deleted|=shoe_mask
    skin=material('SkinHuman',image=SYSTEM/('skins/young_caucasian_'+sex+'/young_lightskinned_'+sex+'_diffuse.png'),roughness=.72)
    keep=[i for i,(face,group) in enumerate(zip(FACES,GROUPS)) if group=='body' and not any(v in deleted for v in face)]
    return mesh('HumanBody',points,[FACES[i] for i in keep],UV,[FACE_UV[i] for i in keep],W,rig,skin,variations)

def texture(path):
    image=bpy.data.images.load(str(path),check_existing=True)
    if max(image.size)>2048:image.scale(2048,2048)
    return image

def material(name, color=(1,1,1,1), image=None, alpha=False, roughness=.8):
    m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=color
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=color;p.inputs['Roughness'].default_value=roughness
    if image:
        t=m.node_tree.nodes.new('ShaderNodeTexImage');t.image=texture(image);m.node_tree.links.new(t.outputs['Color'],p.inputs['Base Color'])
        if alpha:
            m.node_tree.links.new(t.outputs['Alpha'],p.inputs['Alpha']);m.surface_render_method='DITHERED';m.use_backface_culling=False
    return m

def mesh(name, points, faces, uvs, face_uv, weights, rig, mat, variations=None):
    used=sorted(set(i for f in faces for i in f));remap={v:i for i,v in enumerate(used)}
    data=bpy.data.meshes.new(name);data.from_pydata([coord(points[i]) for i in used],[],[[remap[i] for i in f] for f in faces]);data.update()
    obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);obj.parent=rig;data.materials.append(mat)
    layer=data.uv_layers.new(name='UVMap')
    for poly,source in zip(data.polygons,face_uv):
        poly.use_smooth=True
        for loop,index in zip(poly.loop_indices,source):layer.data[loop].uv=uvs[index] if index>=0 else (0,0)
    for bone in rig.data.bones:
        group=obj.vertex_groups.new(name=bone.name)
        for old,new in remap.items():
            value=weights[old].get(bone.name,0)
            if value>1e-5:group.add([new],value,'REPLACE')
    mod=obj.modifiers.new('AuthoredWeights','ARMATURE');mod.object=rig
    if variations:
        obj.shape_key_add(name='Basis')
        for key,other in variations.items():
            shape=obj.shape_key_add(name=key);shape.slider_min=-1;shape.slider_max=1
            for old,new in remap.items():shape.data[new].co=coord(other[old])
    return obj

def create_rig(points):
    bpy.ops.object.armature_add();rig=bpy.context.object;rig.name='HumanRig';bpy.ops.object.mode_set(mode='EDIT')
    rig.data.edit_bones.remove(rig.data.edit_bones[0])
    def position(spec):
        if spec['strategy']=='MEAN':ids=spec['vertex_indices']
        elif spec['strategy']=='CUBE':
            ids=set(i for f,g in zip(FACES,GROUPS) if g==spec['cube_name'] for i in f)
        else:return Vector(spec['default_position'])
        return coord(sum((points[i] for i in ids),Vector())/len(ids))
    for name,desc in RIG.items():
        bone=rig.data.edit_bones.new(name.split(':')[-1]);bone.head=position(desc['head']);bone.tail=position(desc['tail']);bone.roll=desc.get('roll',0)
    for name,desc in RIG.items():
        if desc.get('parent'):rig.data.edit_bones[name.split(':')[-1]].parent=rig.data.edit_bones[desc['parent'].split(':')[-1]]
    bpy.ops.object.mode_set(mode='OBJECT');return rig

def constrain_knees(rig):
    hips=rig.pose.bones['Hips']
    frame=hips.matrix.to_quaternion()@hips.bone.matrix_local.to_quaternion().inverted()
    right=frame@Vector((1,0,0));forward=frame@Vector((0,-1,0))
    changed=[]
    for side in ['Left','Right']:
        thigh=rig.pose.bones[side+'UpLeg'];shin=rig.pose.bones[side+'Leg'];foot=rig.pose.bones[side+'Foot']
        hip=thigh.head.copy();knee=shin.head.copy();ankle=foot.head.copy()
        upper=knee-hip;lower=ankle-knee
        if upper.cross(lower).dot(right)>=-0.00001:continue
        # Two-bone IK chooses the forward knee solution for the same ankle.
        # A mirrored, backward knee can otherwise pass surface-stretch tests.
        l1=upper.length;l2=lower.length;axis=ankle-hip;distance=axis.length;axis.normalize()
        distance=min(l1+l2-0.000001,max(abs(l1-l2)+0.000001,distance))
        along=(l1*l1-l2*l2+distance*distance)/(2*distance)
        height=math.sqrt(max(0,l1*l1-along*along))
        pole=forward-axis*forward.dot(axis)
        if pole.length<.0001:pole=(frame@Vector((0,0,1)))-axis*(frame@Vector((0,0,1))).dot(axis)
        desired_knee=hip+axis*along+pole.normalized()*height
        foot_rotation=foot.matrix.to_quaternion().copy()
        rotation=upper.normalized().rotation_difference((desired_knee-hip).normalized())
        thigh.matrix=Matrix.Translation(hip)@(rotation@thigh.matrix.to_quaternion()).to_matrix().to_4x4();bpy.context.view_layer.update()
        current=foot.head-shin.head;desired=ankle-shin.head
        rotation=current.normalized().rotation_difference(desired.normalized())
        shin.matrix=Matrix.Translation(shin.head)@(rotation@shin.matrix.to_quaternion()).to_matrix().to_4x4();bpy.context.view_layer.update()
        assert (foot.head-ankle).length<.0001,('IK changed foot contact',side,(foot.head-ankle).length)
        foot.matrix=Matrix.Translation(foot.head)@foot_rotation.to_matrix().to_4x4();bpy.context.view_layer.update()
        changed.extend([thigh,shin,foot])
    return changed

def retarget(rig):
    before=set(bpy.data.objects);before_actions=set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/production/characters/citizen/citizen.glb'))
    source_objects=set(bpy.data.objects)-before;source=next(o for o in source_objects if o.type=='ARMATURE');actions=list(set(bpy.data.actions)-before_actions)
    for track in list(source.animation_data.nla_tracks):source.animation_data.nla_tracks.remove(track)
    idle=next(a for a in actions if a.name.split('.')[0]=='Idle')
    source.animation_data.action=idle
    if idle.slots:source.animation_data.action_slot=idle.slots[0]
    bpy.context.scene.frame_set(round(idle.frame_range[0]));bpy.context.view_layer.update()
    source_right=(source.matrix_world @ source.pose.bones['LeftArm'].head)-(source.matrix_world @ source.pose.bones['RightArm'].head)
    target_right=rig.data.bones['LeftArm'].head_local-rig.data.bones['RightArm'].head_local
    source_right.z=0;target_right.z=0;align=source_right.normalized().rotation_difference(target_right.normalized())
    reference={b.name:(source.matrix_world@b.matrix).to_quaternion() for b in source.pose.bones}
    source_hip=source.matrix_world@source.pose.bones['Hips'].head
    bind_side=(source.matrix_world@source.data.bones['LeftUpLeg'].head_local)-(source.matrix_world@source.data.bones['RightUpLeg'].head_local)
    bind_side.z=0
    bind_frame=bind_side.normalized().rotation_difference(target_right.normalized())
    rig.animation_data_create();ordered=sorted(rig.pose.bones,key=lambda b:len(b.parent_recursive));clips=[]
    # Idle uses the native relaxed stance. Other clips normalize their actor
    # frame separately from the source bind frame before direction/roll fitting.
    for side,sign in [('Left',1),('Right',-1)]:
        for part,direction in [('Arm',Vector((sign*.12,0,-1))),('ForeArm',Vector((0,-.06,-1)))]:
            b=rig.pose.bones[side+part];current=b.matrix.to_3x3()@Vector((0,1,0));rotation=current.rotation_difference(direction.normalized())
            b.matrix=Matrix.Translation(b.head)@(rotation@b.matrix.to_quaternion()).to_matrix().to_4x4();bpy.context.view_layer.update()
    relaxed={b.name:b.matrix.to_quaternion().copy() for b in rig.pose.bones}
    for original in actions:
        name=original.name.split('|')[-1].split('.')[0]
        if name not in ['Idle','Walk','Run','Jump','Punch','Working','Death','Axe_Chop','Bow_Attack_Shoot','Bow_Attack_Draw']:continue
        source.animation_data.action=original
        if original.slots:source.animation_data.action_slot=original.slots[0]
        bpy.context.scene.frame_set(round(original.frame_range[0]));bpy.context.view_layer.update()
        posed_side=(source.matrix_world@source.pose.bones['LeftUpLeg'].head)-(source.matrix_world@source.pose.bones['RightUpLeg'].head)
        posed_side.z=0
        clip_frame=posed_side.normalized().rotation_difference(target_right.normalized())
        clip=bpy.data.actions.new(name+'_new');rig.animation_data.action=clip
        for frame in range(round(original.frame_range[0]),round(original.frame_range[1])+1):
            bpy.context.scene.frame_set(frame)
            for b in ordered:b.matrix_basis=Matrix.Identity(4)
            bpy.context.view_layer.update()
            for bone in ordered:
                if bone.name not in source.pose.bones:continue
                sb=source.pose.bones[bone.name]
                if name=='Idle':
                    delta=(source.matrix_world@sb.matrix).to_quaternion() @ reference[bone.name].inverted()
                    desired=align@delta@align.inverted()@relaxed[bone.name]
                else:
                    # Normalize bind and authored clip actor frames separately.
                    # Referencing every action to combat Idle bakes its lean and
                    # sideways hips into otherwise upright walking/running.
                    srest=bind_frame@(source.matrix_world@sb.bone.matrix_local).to_quaternion()
                    spose=clip_frame@(source.matrix_world@sb.matrix).to_quaternion()
                    trest=bone.bone.matrix_local.to_quaternion()
                    fit=(trest@Vector((0,1,0))).rotation_difference(srest@Vector((0,1,0)))
                    desired=spose@srest.inverted()@fit@trest
                local=bone.bone.matrix_local if bone.parent is None else bone.parent.bone.matrix_local.inverted()@bone.bone.matrix_local
                base=local if bone.parent is None else bone.parent.matrix@local
                position=base.translation.copy()
                if bone.name=='Hips':position.z+=(source.matrix_world@sb.head).z-source_hip.z
                bone.matrix=Matrix.Translation(position)@desired.to_matrix().to_4x4();bone.keyframe_insert('rotation_quaternion',frame=frame)
                if bone.name=='Hips':bone.keyframe_insert('location',frame=frame)
                bpy.context.view_layer.update()
            for bone in constrain_knees(rig):bone.keyframe_insert('rotation_quaternion',frame=frame)
            if name not in ['Jump','Death']:
                soles=bpy.data.objects['Boots'].evaluated_get(bpy.context.evaluated_depsgraph_get());data=soles.to_mesh()
                lowest=min((soles.matrix_world@v.co).z for v in data.vertices);soles.to_mesh_clear()
                hip=rig.pose.bones['Hips'];matrix=hip.matrix.copy();matrix.translation.z-=lowest;hip.matrix=matrix
                hip.keyframe_insert('location',frame=frame);bpy.context.view_layer.update()
        track=rig.animation_data.nla_tracks.new();track.name=name;track.strips.new(name,1,clip);track.mute=True;clips.append((name,clip))
    for obj in source_objects:bpy.data.objects.remove(obj,do_unlink=True)
    for action in actions:bpy.data.actions.remove(action)
    for name,clip in clips:clip.name=name
    rig.animation_data.action=next(a for name,a in clips if name=='Idle');bpy.context.scene.frame_set(1);bpy.context.view_layer.update()
    return [name for name,_ in clips]

def build_all():
    global BOTTOM, BODY_SCALE
    for sex in ['male','female']:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        points=morph(BASE,target('macrodetails/caucasian-'+sex+'-young.target.gz'))
        body_indices=set(i for f,g in zip(FACES,GROUPS) if g=='body' for i in f)
        BOTTOM=min(points[i].y for i in body_indices)
        BODY_SCALE=1.8/(max(points[i].y for i in body_indices)-BOTTOM)
        variations=create_variations(points)
        rig=create_rig(points)
        create_body(points,variations,rig,sex)
        garment=create_garment(points,variations,rig)
        boots=SYSTEM/'clothes/shoes03/shoes03'
        rec,scale,_=mapping(boots.with_suffix('.mhclo'))
        _,uv,faces,fuv,_=read_obj(boots.with_suffix('.obj'))
        mesh('Boots',fitted(points,rec,scale),faces,uv,fuv,fitted_weights(rec),rig,material('LeatherBoots',(.085,.048,.026,1),roughness=.86),{key:fitted(other,rec,scale) for key,other in variations.items()})
        for name,prefix,matname,img,alpha in [
            ('Eyes','eyes/low-poly/low-poly','EyesHuman','eyes/materials/brown_eye.png',False),
            ('HairShort','hair/short01/short01','HairHuman','hair/short01/short01_diffuse.png',True),
            ('HairPonytail','hair/ponytail01/ponytail01','HairHuman','hair/ponytail01/ponytail01_diffuse.png',True),
            ('Brows','eyebrows/eyebrow001/eyebrow001','BrowsHuman','eyebrows/eyebrow001/eyebrow001.png',True)]:
            p=SYSTEM/prefix
            if not p.with_suffix('.obj').exists():continue
            rec,scale,_=mapping(p.with_suffix('.mhclo'));_,uv,faces,fuv,_=read_obj(p.with_suffix('.obj'))
            obj=mesh(name,fitted(points,rec,scale),faces,uv,fuv,fitted_weights(rec),rig,material(matname,image=SYSTEM/img,alpha=alpha),{key:fitted(other,rec,scale) for key,other in variations.items()})
            if name=='HairPonytail':obj.hide_render=True
        clips=retarget(rig)
        soles=bpy.data.objects['Boots'].evaluated_get(bpy.context.evaluated_depsgraph_get())
        sole_mesh=soles.to_mesh()
        rig.location.z=-min((soles.matrix_world@v.co).z for v in sole_mesh.vertices)
        soles.to_mesh_clear();bpy.context.view_layer.update()
        bpy.ops.export_scene.gltf(filepath=str(OUT/(sex+'.glb')),export_format='GLB',export_animation_mode='ACTIONS',export_force_sampling=True,export_morph=True,export_morph_normal=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(sex+'.blend')))
        print('REALISTIC_CHARACTER_BUILT',sex,'clips',clips,flush=True)

if __name__ == "__main__":
    build_all()
