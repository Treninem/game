"""Project-authored domestic kit from the owner's house concept, in metres.
Rounded bedding, pleated curtains, bordered woven rugs and an arched hearth.
Uses shared reviewed production materials in Godot, no embedded image copies.
"""
from pathlib import Path
import bpy, math
from mathutils import Vector
root = Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
mats = {}
for name, color in [('Timber',(.3,.2,.12,1)), ('Stone',(.5,.46,.4,1)), ('Soot',(.08,.06,.04,1)), ('Iron',(.12,.12,.12,1)), ('Sheets',(.5,.22,.15,1)), ('Pillow',(.85,.8,.65,1)), ('Curtain',(.85,.8,.65,1)), ('Rug',(.35,.2,.12,1)), ('Border',(.65,.45,.25,1))]:
    mat = bpy.data.materials.new(name); mat.diffuse_color=color; mats[name]=mat

def group(name):
    obj=bpy.data.objects.new(name,None); bpy.context.collection.objects.link(obj); return obj
def cube(parent,name,size,point,material,bevel=.01):
    x,y,z=point; bpy.ops.mesh.primitive_cube_add(size=1,location=(x,-z,y)); obj=bpy.context.object; obj.name=name
    obj.dimensions=(size[0],size[2],size[1]); bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    obj.data.materials.append(mats[material]); obj.parent=parent
    if bevel:
        mod=obj.modifiers.new('Soft worked edges','BEVEL');mod.width=bevel;mod.segments=4;bpy.ops.object.modifier_apply(modifier=mod.name)
    if material == 'Pillow':
        for uv in obj.data.uv_layers.active.data:uv.uv=(.64+.32*uv.uv.x,.64+.32*uv.uv.y)
    return obj
def surface(parent,name,columns,rows,point,material,border=False):
    vertices=[point(i/columns,j/rows) for j in range(rows+1) for i in range(columns+1)]
    faces=[]
    for j in range(rows):
        for i in range(columns):
            a=j*(columns+1)+i; faces.append((a,a+columns+1,a+columns+2,a+1))
    mesh=bpy.data.meshes.new(name);mesh.from_pydata([(x,-z,y) for x,y,z in vertices],[],faces);mesh.update()
    obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj);obj.parent=parent;mesh.materials.append(mats[material])
    if border:mesh.materials.append(mats['Border'])
    uv=mesh.uv_layers.new(name='Fabric swatch')
    for poly in mesh.polygons:
        j,i=divmod(poly.index,columns)
        diamond=abs((i+.5)/columns-.5)+abs((j+.5)/rows-.5)
        if border and (i<2 or i>=columns-2 or j<2 or j>=rows-2 or .12<diamond<.21):poly.material_index=1
        for loop in poly.loop_indices:
            index=mesh.loops[loop].vertex_index; v,u=divmod(index,columns+1)
            uv.data[loop].uv=(.64+.32*u/columns,.64+.32*v/rows)
        poly.use_smooth=True
    return obj

linen=group('BedLinen')
cube(linen,'Covered mattress',(1.48,.14,2.02),(0,-.07,0),'Pillow',.065)
def quilt(u,v):
    x=(u-.5)*1.5;z=-.5+v*1.5
    y=.025+.012*math.sin(v*18+u*7)+.008*math.cos(u*28)
    y-=max(0,(abs(x)-.65)/.1)*.18
    return x,y,z
surface(linen,'Quilt with hanging sides',32,32,quilt,'Sheets')
pillow=cube(linen,'Soft pillow',(1.2,.18,.44),(0,.10,-.74),'Pillow',.075)
# Crop the reviewed cloth atlas to its unprinted linen swatch.
for poly in pillow.data.polygons:
    poly.use_smooth=True

curtain=group('WindowCurtains')
for side in [-1,1]:
    def drape(u,v,side=side):
        x=side*(.66+u*.34+v*.035); y=.76-v*1.58+.014*math.sin(u*12)*v
        z=.25+.07*math.sin(u*math.pi*10)*(1-.12*v)
        return x,y,z
    surface(curtain,'Pleated linen',32,28,drape,'Curtain')
cube(curtain,'Curtain rod',(2.10,.045,.045),(0,.83,.25),'Timber',.018)

rug=group('WovenRug')
surface(rug,'Bound textile',24,32,lambda u,v:((u-.5)*1.3,.012+.003*math.sin(u*17)*math.sin(v*11),(v-.5)*2),'Rug',True)

hearth=group('ArchedHearth')
cube(hearth,'Hearth slab',(1.16,.12,.46),(0,.06,0),'Stone',.025)
for side in [-1,1]:
    for row in range(3):
        cube(hearth,'Worked jamb stone',(.22,.18,.40),(side*.45,.21+row*.18,0),'Stone',.014)
cube(hearth,'Sooted back',(.72,.74,.05),(0,.48,-.18),'Soot',.005)
for segment in range(11):
    angle=(segment+.5)*math.pi/11
    verts=[]
    for z in [-.2,.2]:
        for r,a in [(.34,segment*math.pi/11+.008),(.56,segment*math.pi/11+.008),(.56,(segment+1)*math.pi/11-.008),(.34,(segment+1)*math.pi/11-.008)]:
            verts.append((r*math.cos(a),-z,.66+r*math.sin(a)))
    mesh=bpy.data.meshes.new('Arch voussoir');mesh.from_pydata(verts,[],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])
    obj=bpy.data.objects.new('Arch stone',mesh);bpy.context.collection.objects.link(obj);obj.parent=hearth;mesh.materials.append(mats['Stone'])
    bpy.context.view_layer.objects.active=obj;obj.select_set(True);mod=obj.modifiers.new('Stone edges','BEVEL');mod.width=.008;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name);obj.select_set(False)
cube(hearth,'Mantel',(1.26,.10,.48),(0,1.28,0),'Timber',.015)
cube(hearth,'Chimney breast',(.82,1.47,.33),(0,2.065,-.045),'Stone',.02)
cube(hearth,'Pot suspension',(.025,.32,.025),(0,.96,.04),'Iron',.004)
for x,z,angle in [(-.15,.08,.2),(.15,.02,-.3),(0,-.03,.05)]:
    bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=.055,depth=.62,location=(x,-z,.18),rotation=(0,math.pi/2,angle))
    obj=bpy.context.object;obj.name='Split firewood';obj.parent=hearth;obj.data.materials.append(mats['Timber'])

for parent in [linen,curtain,rug,hearth]:
    meshes=[obj for obj in parent.children if obj.type=='MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for obj in meshes:obj.select_set(True)
    bpy.context.view_layer.objects.active=meshes[0]
    bpy.ops.object.join()
    bpy.context.object.name=parent.name+'Mesh'
bpy.context.preferences.filepaths.file_preview_type='NONE'
bpy.ops.wm.save_as_mainfile(filepath=str(root/'assets/source/interiors/HouseLivingDetails.blend'))
bpy.ops.export_scene.gltf(filepath=str(root/'assets/production/interiors/architecture/HouseLivingDetails.glb'),export_format='GLB',export_yup=True)
print('HOUSE_LIVING_DETAILS_BUILT')
