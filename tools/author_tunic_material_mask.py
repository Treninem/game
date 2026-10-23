"""Blender authoring of a UV-aligned steel/cloth response for the CC0 tunic.

R: metal amount on neutral ring highlights, G: roughness. The original diffuse,
normal, AO and garment mesh are never repainted or modified.
"""
from pathlib import Path
import bpy,numpy as np,json,hashlib,os
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(os.environ.get('IMPULS_TUNIC_OUTPUT',ROOT/'build/asset_work/hair-shape-2026-10-23/tunic-mask'))
SOURCE=ROOT/'assets/staging/characters/makehuman_viking_selected/clothes/rehmanpolanski_viking_tunic/TUNIC_Viking.png'
def polygon_mask(x,y,points):
    inside=np.zeros(x.shape,dtype=bool)
    for (a,b),(c,d) in zip(points,points[1:]+points[:1]):
        if b==d:continue
        inside^=((b>y)!=(d>y)) & (x<(c-a)*(y-b)/(d-b)+a)
    return inside
def build():
    assert not OUT.exists(),'Preserve previous authoring evidence';OUT.mkdir(parents=True)
    image=bpy.data.images.load(str(SOURCE),check_existing=False)
    image.colorspace_settings.name='Non-Color'
    rgba=np.array(image.pixels[:],dtype=np.float32).reshape(image.size[1],image.size[0],4)[::-1]
    assert image.size[:]==(2048,2048)
    # Average the original atlas at 2x2 texels; the map stays shared by both UVs.
    rgb=rgba[:,:,:3].reshape(1024,2,1024,2,3).mean(axis=(1,3))
    y,x=np.mgrid[:1024,:1024];x=(x+.5)/1024;y=(y+.5)/1024
    panel=[(.090,.180),(.130,.174),(.168,.190),(.215,.195),(.268,.180),(.315,.176),(.357,.192),(.326,.228),(.304,.270),(.305,.315),(.351,.324),(.351,.459),(.092,.459),(.092,.324),(.140,.314),(.137,.270),(.115,.228)]
    other=[(a+.468,b) for a,b in panel]
    domain=polygon_mask(x,y,panel)|polygon_mask(x,y,other)
    # Preserve the front embroidered raven as thread rather than steel.
    domain &= ((x-.207)/.053)**2+((y-.294)/.063)**2>1
    maximum=rgb.max(axis=2);minimum=rgb.min(axis=2)
    chroma=(maximum-minimum)/np.maximum(maximum,.001)
    neutral=np.clip((.36-chroma)/.20,0,1)
    highlight=np.clip((maximum-.12)/.27,0,1)
    metal=.72*domain*neutral*highlight*(maximum<.85)
    roughness=.88-.40*(metal/.72)
    pixels=np.zeros((1024,1024,4),dtype=np.float32);pixels[:,:,0]=metal;pixels[:,:,1]=roughness;pixels[:,:,3]=1
    result=bpy.data.images.new('Tunic steel and cloth response',width=1024,height=1024,alpha=True)
    result.colorspace_settings.name='Non-Color';result.pixels.foreach_set(pixels[::-1].copy().ravel())
    result.filepath_raw=str(OUT/'tunic-metal-roughness.png');result.file_format='PNG';result.save()
    row={'source':SOURCE.relative_to(ROOT).as_posix(),'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'width':1024,'height':1024,'metal_pixels_above_0_1':int((metal>.1).sum()),'metal_maximum':float(metal.max()),'roughness_minimum':float(roughness.min()),'roughness_cloth':.88,'channels':{'R':'metal amount','G':'roughness','B':'unused','A':'opaque'},'shared_bodies':2,'new_albedo_textures':0,'new_meshes':0}
    assert row['metal_pixels_above_0_1']>10000
    (OUT/'construction.json').write_text(json.dumps(row,indent=2)+'\n')
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'tunic-material-authoring.blend'))
    print('TUNIC_MATERIAL_AUTHORED',json.dumps(row),flush=True)
if __name__=='__main__':build()
