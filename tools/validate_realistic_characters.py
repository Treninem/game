"""Check the actual skinned production geometry in 100 animation poses.
Blender creates a separate Icosphere bone widget on glTF import; it is not
exported character geometry. Require all seven skinned model parts instead.
"""
import bpy,json,math,os
from mathutils import Vector
from pathlib import Path
r=Path(__file__).resolve().parents[1];q=Path(os.environ.get('IMPULS_CHARACTER_OUTPUT',str(r/'assets/production/characters/realistic')));results=[]
for sex in ['male','female']:
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(q/(sex+'.glb')))
 rig=next(o for o in bpy.data.objects if o.type=='ARMATURE');meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.parent==rig];assert len(meshes)==7,[(o.name,o.parent.name if o.parent else '') for o in meshes]
 for track in list(rig.animation_data.nla_tracks):rig.animation_data.nla_tracks.remove(track)
 actions=list(bpy.data.actions);assert len(actions)==10
 for action in actions:
  rig.animation_data.action=action
  if action.slots:rig.animation_data.action_slot=action.slots[0]
  # Cuff refitting must preserve a real surface, not collapse its authored
  # rings into zero-area triangles. Ignore unrelated tiny facial geometry.
  cloth=next(o for o in meshes if o.name=='Clothing')
  cloth.data.calc_loop_triangles()
  degenerate=sum(1 for triangle in cloth.data.loop_triangles if triangle.area<1e-10)
  assert degenerate==0,(sex,'degenerate garment triangles',degenerate)
  max_edge=0;detail=None
  for fraction in [0,.25,.5,.75,1]:
   # Check combined facial extremes on the actual animated skin, hair, eyes
   # and fitted clothes, not merely the presence of slider names in the UI.
   for obj in meshes:
    assert obj.data.shape_keys is not None,(sex,obj.name,'missing shape keys')
    keys=obj.data.shape_keys.key_blocks
    for name in ['HeadSize','FaceWidth','FaceHeight','FaceDepth','Nose','NoseWidth','NoseHeight','Jaw','Build']:
     assert name in keys,(sex,obj.name,'missing shape',name)
     keys[name].slider_min=-.5
     keys[name].value=(fraction-.5)
     if obj.name=='HumanBody' and fraction==0:
      displacement=max((v.co-b.co).length for v,b in zip(keys[name].data,keys['Basis'].data))
      assert .00001<displacement<.5,(sex,name,'empty or excessive shape',displacement)
   start,end=action.frame_range;bpy.context.scene.frame_set(round(start+(end-start)*fraction))
   for obj in meshes:
    evaluated=obj.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=evaluated.to_mesh();points=[obj.matrix_world@v.co for v in mesh.vertices]
    assert all(math.isfinite(x) for p in points for x in p),(sex,action.name,obj.name,'nonfinite')
    for edge in mesh.edges:
     length=(points[edge.vertices[0]]-points[edge.vertices[1]]).length
     if length>max_edge:max_edge=length;detail=(obj.name,fraction,list(edge.vertices))
    evaluated.to_mesh_clear()
  assert max_edge<.35,(sex,action.name,'stretched skin/cloth',max_edge,detail)
  if action.name in ['Walk','Run']:
   minimum=180.0;minimum_lean=180.0
   for sample in range(25):
    start,end=action.frame_range;bpy.context.scene.frame_set(round(start+(end-start)*sample/24))
    torso=rig.pose.bones['Head'].head-rig.pose.bones['Hips'].head;lean=math.degrees(math.atan2(-torso.y,torso.z));minimum_lean=min(minimum_lean,lean)
    assert lean>=-8.0,(sex,action.name,'backward torso lean',sample,lean)
    hips=rig.pose.bones['Hips'];right=(hips.matrix.to_quaternion()@hips.bone.matrix_local.to_quaternion().inverted())@Vector((1,0,0))
    for side in ['Left','Right']:
     h=rig.pose.bones[side+'UpLeg'].head;k=rig.pose.bones[side+'Leg'].head;a=rig.pose.bones[side+'Foot'].head;u=(k-h).normalized();v=(a-k).normalized()
     angle=math.degrees(math.atan2(u.cross(v).dot(right),u.dot(v)));minimum=min(minimum,angle)
     assert angle>=-1.0,(sex,action.name,'backward knee',side,sample,angle)
   print('ANATOMICAL_KNEES_OK',sex,action.name,'minimum_deg',minimum,flush=True)
  if action.name in ['Idle','Walk','Run']:
   for fraction in [0,.25,.5,.75,1]:
    start,end=action.frame_range;bpy.context.scene.frame_set(round(start+(end-start)*fraction))
    for side in ['Left','Right']:
     for finger in ['Index','Middle','Ring','Pinky']:
      a,b,c=[rig.pose.bones[side+'Hand'+finger+str(i)].head for i in [1,2,3]]
      angle=math.degrees((b-a).angle(c-b))
      assert 5.0<angle<50.0,(sex,action.name,'unnatural free finger',side,finger,fraction,angle)
   print('NATIVE_RELAXED_HANDS_OK',sex,action.name,flush=True)
  results.append({'sex':sex,'clip':action.name,'maximum_edge_m':round(max_edge,5),**({'minimum_knee_angle_deg':round(minimum,5),'minimum_forward_lean_deg':round(minimum_lean,5)} if action.name in ['Walk','Run'] else {})})
(r/'build/acceptance/realistic-character-surfaces.json').write_text(json.dumps(results,indent=2),encoding='utf-8');print('REALISTIC_SURFACES_OK',len(results),'clips,100 poses')
