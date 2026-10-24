"""Blender-native original fine-grained cut-stone maps; not scanned PBR.
No external asset, image or material is downloaded/replaced.
"""
from pathlib import Path
import bpy,math,json
from mathutils import Vector,noise
R=Path(__file__).resolve().parents[1];Q=R/'build/asset_work/city-streetscape-2026-10-24';D=Q/'stone-material'
assert not D.exists();D.mkdir()
size=256;heights=[];colors=[];rough=[]
# Integer-frequency trigonometric grains and wrap-periodic noise keep every
# border seamless. Texture repeats at75cm; relief stays sub-millimetre.
for y in range(size):
 for x in range(size):
  u=x/size;v=y/size
  p=Vector((math.cos(math.tau*u),math.sin(math.tau*u),math.sin(math.tau*v)))
  coarse=noise.fractal(p*3.7,.85,2.0,3)
  grain=math.sin(math.tau*(u*31+v*17))*math.sin(math.tau*(u*23-v*29))
  fine=math.sin(math.tau*(u*83-v*71))*math.sin(math.tau*(u*67+v*89))
  pore=max(0.,fine-.76)*.10
  h=.00020*coarse+.000045*grain-.00025*pore
  heights.append(h)
  tone=coarse*.028+grain*.009+fine*.004-pore*.35
  colors.extend([.48+tone,.455+tone,.40+tone,1.])
  rough.extend([1.,max(.79,min(.98,.91-grain*.025+fine*.012)),0.,1.])
normal=[]
for y in range(size):
 for x in range(size):
  dx=(heights[y*size+(x+1)%size]-heights[y*size+(x-1)%size])/(1.5/size)
  dy=(heights[((y+1)%size)*size+x]-heights[((y-1)%size)*size+x])/(1.5/size)
  n=Vector((-dx,-dy,1)).normalized();normal.extend([n.x*.5+.5,n.y*.5+.5,n.z*.5+.5,1.])
for name,pixels,noncolor in [('stone_albedo',colors,False),('stone_normal',normal,True),('stone_orm',rough,True)]:
 image=bpy.data.images.new(name,width=size,height=size,alpha=True)
 if noncolor:image.colorspace_settings.name='Non-Color'
 image.pixels.foreach_set(pixels);image.filepath_raw=str(D/(name+'.png'));image.file_format='PNG';image.save()
(D/'construction.json').write_text(json.dumps({'original_procedural_material':True,'scanned':False,'resolution':[size,size],'normal_convention':'OpenGL tangent space','texture_period_m':.75,'relief_height_range_m':[min(heights),max(heights)],'third_party_files':0},indent=2))
print('ORIGINAL_CITY_CUT_STONE_MAPS_AUTHORED')
