"""Blender data-map authoring for the existing CC0 B29 plaster photograph.

Diffuse remains unmodified. Normals and roughness are restrained authored
approximations from high-frequency image detail, not scanned PBR measurements.
"""
from pathlib import Path
import bpy,numpy as np,os,json,hashlib
R=Path(__file__).resolve().parents[1]
SOURCE=R/'assets/staging/sourcechat_b29/models/oga_modular_medieval_building_pack/74697_HousePack2_2Upload_blend/Plaster.jpg'
OUT=Path(os.environ.get('IMPULS_PLASTER_OUTPUT',R/'build/asset_work/region-art-2026-10-23/plaster1'))
assert not OUT.exists();OUT.mkdir(parents=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
image=bpy.data.images.load(str(SOURCE));image.colorspace_settings.name='Non-Color';image.scale(512,384)
rgb=np.array(image.pixels[:],dtype=np.float32).reshape(384,512,4)[::-1,:,:3];gray=rgb@np.array([.2126,.7152,.0722]);smooth=gray.copy()
for _ in range(6):smooth=(smooth+np.roll(smooth,1,0)+np.roll(smooth,-1,0)+np.roll(smooth,1,1)+np.roll(smooth,-1,1))/5
height=(gray-smooth)*.001
dx=(np.roll(height,-1,1)-np.roll(height,1,1))*512/4
dy=(np.roll(height,-1,0)-np.roll(height,1,0))*384/4
normal=np.stack([-dx,dy,np.ones_like(dx)],axis=2);normal/=np.linalg.norm(normal,axis=2)[:,:,None];normal=normal*.5+.5
orm=np.stack([np.ones_like(gray),np.clip(.93+(smooth-gray)*.10,.88,.98),np.zeros_like(gray)],axis=2)
rows=[]
for name,data in [('plaster_normal',normal),('plaster_orm',orm)]:
 rgba=np.ones((384,512,4),dtype=np.float32);rgba[:,:,:3]=data
 result=bpy.data.images.new(name,width=512,height=384,alpha=False);result.colorspace_settings.name='Non-Color';result.pixels.foreach_set(rgba[::-1].copy().ravel());result.filepath_raw=str(OUT/(name+'.png'));result.file_format='PNG';result.save()
 rows.append({'file':name+'.png','sha256':hashlib.sha256((OUT/(name+'.png')).read_bytes()).hexdigest()})
(OUT/'construction.json').write_text(json.dumps({'source':str(SOURCE.relative_to(R)),'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'license':'Existing Daniel Andersson B29 CC0 source','maps':rows,'dimensions':[512,384],'normal_height_amplitude_m':.001,'normal_strength_recommended':.35,'orm':'R=1 (no invented cavity AO), G=authored roughness, B=0','claim':'Authored approximations from a photograph, not scanned PBR','status':'CANDIDATE_NOT_INTEGRATED'},indent=2)+'\n')
print('PLASTER_SURFACE_AUTHORED maps=2 diffuse_unchanged=true')
