"""Author the complete starter set in Blender; no old weapon geometry reused.

Coordinates below are Godot metres. Interchange uses shared external textures,
so cedar/leather are stored once for all four models, not embedded four times.
Run Blender --background --threads 2 --python this_file.py.
"""
from pathlib import Path
import bpy, bmesh, math, json, os, hashlib
from mathutils import Vector

ROOT = next(folder for folder in Path(__file__).resolve().parents if (folder/'project.godot').exists())
OUT = Path(os.environ['IMPULS_WEAPON_OUTPUT']).resolve()
assert ROOT.name == 'game' and (ROOT/'project.godot').exists()
assert (ROOT/'build').resolve() in OUT.parents
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.unit_settings.system = 'METRIC'
bpy.context.scene.unit_settings.scale_length = 1.0
preferences=bpy.context.preferences.filepaths
if hasattr(preferences,'file_preview_type'):
    preferences.file_preview_type='NONE'
elif hasattr(preferences,'use_save_preview_images'):
    preferences.use_save_preview_images=False
else:
    raise RuntimeError('Inspect this Blender version before enabling file previews')
GRIPS = {'Axe_small':(-.09865,-.18,0), 'Dagger':(.0006,-.12,0), 'Bow_Wooden':(-.070708,0,0)}
TEXTURES = {'Cedar': ROOT/'assets/staging/ui/materials/cedar/cedar.png',
            'Leather': ROOT/'assets/staging/ui/materials/leather/leather.png',
            'ForgedSteelColor': ROOT/'assets/staging/sourcechat_b24/models/oga_pbr_industrial_a52/OGA_industrial_a52_version/scratchy_metal/scratchy_metal_dark.jpg',
            'ForgedSteelNormal': ROOT/'assets/staging/sourcechat_b24/models/oga_pbr_industrial_a52/OGA_industrial_a52_version/scratchy_metal/scratchy_metal_norm.jpg',
            'ForgedSteelRoughness': ROOT/'assets/staging/sourcechat_b24/models/oga_pbr_industrial_a52/OGA_industrial_a52_version/scratchy_metal/scratchy_metal_roughness.png'}
ITEMS = {}
MATERIALS = {}

def point(v):
    return Vector((v[0], -v[2], v[1]))

def godot(v):
    return (v.x,v.z,-v.y)

def material(name, color, roughness, metallic=0, texture=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.use_backface_culling = True
    m.diffuse_color = (*color,1)
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color,1)
    p.inputs['Roughness'].default_value = roughness
    p.inputs['Metallic'].default_value = metallic
    if texture:
        image = bpy.data.images.load(str(TEXTURES[texture]), check_existing=True)
        image.name = texture
        tex = m.node_tree.nodes.new('ShaderNodeTexImage')
        tex.image = image
        # Tint is a material factor in glTF; original image pixels stay intact.
        multiply = m.node_tree.nodes.new('ShaderNodeMixRGB')
        multiply.blend_type = 'MULTIPLY'
        multiply.inputs[0].default_value = 1
        multiply.inputs[2].default_value = (*color,1)
        m.node_tree.links.new(tex.outputs['Color'],multiply.inputs[1])
        m.node_tree.links.new(multiply.outputs[0],p.inputs['Base Color'])
    MATERIALS[name] = m
    return m

material('AshWood',(.32,.38,.48),.76,texture='Cedar')
material('GripLeather',(.20,.18,.15),.8,texture='Leather')
forged=material('ForgedSteel',(.72,.74,.76),.58,.92,texture='ForgedSteelColor')
principled=forged.node_tree.nodes.get('Principled BSDF')
for key,socket in [('ForgedSteelNormal','Normal'),('ForgedSteelRoughness','Roughness')]:
    image=bpy.data.images.load(str(TEXTURES[key]),check_existing=True)
    image.colorspace_settings.name='Non-Color'
    node=forged.node_tree.nodes.new('ShaderNodeTexImage');node.image=image
    if socket=='Normal':
        normal=forged.node_tree.nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.22
        forged.node_tree.links.new(node.outputs['Color'],normal.inputs['Color'])
        forged.node_tree.links.new(normal.outputs['Normal'],principled.inputs['Normal'])
    else:forged.node_tree.links.new(node.outputs['Color'],principled.inputs[socket])
material('HonedEdge',(.42,.45,.48),.33,.96)
material('Flint',(.022,.027,.030),.58)
material('Horn',(.105,.075,.045),.5)
material('LinenCord',(.68,.61,.47),.89)
material('Feather',(.39,.34,.27),.86)
material('FeatherRib',(.24,.20,.15),.85)

def root(name):
    obj = bpy.data.objects.new(name,None)
    bpy.context.collection.objects.link(obj)
    ITEMS[name] = {'root':obj,'objects':[],'anchors':[]}
    return obj

def anchor(owner,name,position):
    obj=bpy.data.objects.new(name,None)
    bpy.context.collection.objects.link(obj)
    obj.parent=ITEMS[owner]['root'];obj.location=point(position)
    obj.empty_display_type='SPHERE';obj.empty_display_size=.008
    ITEMS[owner]['anchors'].append(obj)

def mesh(name, vertices, faces, uvs, mat, owner, smooth=True):
    data = bpy.data.meshes.new(name)
    data.from_pydata([point(v) for v in vertices],[],faces)
    data.update()
    bm = bmesh.new();bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(data);bm.free()
    layer = data.uv_layers.new(name='UVMap')
    # UV coordinates follow the original vertex index after normal recalculation.
    for face in data.polygons:
        face.use_smooth = smooth
        for loop_index in face.loop_indices:
            layer.data[loop_index].uv = uvs[data.loops[loop_index].vertex_index]
    # Weld geometric seams after assigning per-loop UVs. UV seams survive,
    # while shared vertex normals keep the round haft highlights continuous.
    bm=bmesh.new();bm.from_mesh(data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-8)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(data);bm.free()
    obj = bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(obj)
    obj.parent = ITEMS[owner]['root']
    obj.data.materials.append(MATERIALS[mat])
    ITEMS[owner]['objects'].append(obj)
    return obj

def sweep(name, centers, radii, mat, owner, sides=40, grain=.30):
    verts=[];uv=[];faces=[];distance=0
    for row,c in enumerate(centers):
        c=Vector(c)
        if row:distance+=(c-Vector(centers[row-1])).length
        tangent=(Vector(centers[min(row+1,len(centers)-1)])-Vector(centers[max(0,row-1)])).normalized()
        right=Vector((tangent.y,-tangent.x,0)).normalized()
        if right.length<.5:right=Vector((1,0,0))
        depth=tangent.cross(right).normalized()
        for side in range(sides+1):
            theta=2*math.pi*side/sides
            p=c+right*radii[row][0]*math.cos(theta)+depth*radii[row][1]*math.sin(theta)
            verts.append(tuple(p));uv.append((side/sides,distance/grain))
            if row and side<sides:
                a=(row-1)*(sides+1)+side;b=row*(sides+1)+side
                faces.append((a,a+1,b+1,b))
    faces.append(tuple(range(sides-1,-1,-1)))
    end=(len(centers)-1)*(sides+1)
    faces.append(tuple(end+i for i in range(sides)))
    return mesh(name,verts,faces,uv,mat,owner)

def grip_wrap(name, owner, center, y0, y1, radius_x, radius_z, turns):
    verts=[];uv=[];faces=[];steps=turns*64
    for i in range(steps+1):
        t=i/steps;theta=t*turns*2*math.pi
        y=y0+(y1-y0)*t
        for edge in [-1,1]:
            width=(y1-y0)/turns*.53
            verts.append((center[0]+radius_x*math.cos(theta),y+edge*width,center[2]+radius_z*math.sin(theta)))
            uv.append((t*turns*.6,(edge+1)*.08))
        if i:faces.append((2*i-2,2*i,2*i+1,2*i-1))
    obj=mesh(name,verts,faces,uv,'GripLeather',owner)
    solid=obj.modifiers.new('Thin hide edge','SOLIDIFY');solid.thickness=.00045
    bpy.context.view_layer.objects.active=obj
    bpy.ops.object.modifier_apply(modifier=solid.name)
    return obj

def bow_flex(obj):
    obj.shape_key_add(name='Basis')
    key=obj.shape_key_add(name='Draw')
    for source,target in zip(obj.data.vertices,key.data):
        x,y,z=godot(source.co)
        t=abs(y)/.55
        weight=max(0,min(1,(abs(y)-.06)/(.55-.06)))
        target.co=point((x+.07*t**2.8*weight,y*(1-.045*t*t*weight),z))

def make_axe():
    owner='Axe_small';root(owner)
    gx,gy,gz=GRIPS[owner]
    centers=[];radii=[]
    for i in range(81):
        y=-.335+.647*i/80
        d=y-gy
        centers.append((gx+.009*math.sin(d*2.8)+.006*d*d,y,.0015*math.sin(d*5)))
        knob=.0035*math.exp(-((y+.305)/.024)**2)
        radii.append((.0118+knob+.001*math.sin(i/80*math.pi),.0093+knob*.7))
    sweep('ContinuousAshHaft',centers,radii,'AshWood',owner,48)
    anchor(owner,'GripAnchor',GRIPS[owner])
    # Follow the actual curved haft through the eye, not its distant palm X.
    delta=.25-gy
    gx=gx+.009*math.sin(delta*2.8)+.006*delta*delta
    eye_z=.0015*math.sin(delta*5)
    # A real hollow eye surrounds the through-haft, including its top annulus.
    verts=[];uv=[];faces=[];N=64
    for radius_x,radius_z,y in [(.024,.020,.195),(.023,.019,.305),(.0142,.0115,.195),(.0142,.0115,.305)]:
        for i in range(N):
            a=2*math.pi*i/N;verts.append((gx+radius_x*math.cos(a),y,eye_z+radius_z*math.sin(a)));uv.append((i/N,y*3))
    for i in range(N):
        j=(i+1)%N
        faces.extend([(i,j,N+j,N+i),(2*N+i,3*N+i,3*N+j,2*N+j),(N+i,N+j,3*N+j,3*N+i),(i,2*N+i,2*N+j,j)])
    mesh('HollowForgedEye',verts,faces,uv,'ForgedSteel',owner)
    verts=[];uv=[];faces=[];columns=41;rows=25
    for side in [-1,1]:
        for col in range(columns):
            t=col/(columns-1);x=gx+.018+.210*t
            low=.204-.058*math.sin(t*math.pi/2)**1.3
            high=.300+.015*math.sin(t*math.pi/2)
            half=.015*(1-t)**.85+.00065
            for row in range(rows):
                v=row/(rows-1);y=low+(high-low)*v
                curved_x=x+.008*t**8*math.sin(v*math.pi)
                convex=.85+.15*math.sin(v*math.pi)
                forged=.00018*math.sin(t*25+v*11)*math.sin(t*13-v*17)*(1-t)
                verts.append((curved_x,y,side*(half*convex+forged)));uv.append((t,v))
                if col and row:
                    a=(0 if side<0 else columns*rows)+(col-1)*rows+row-1
                    faces.append((a,a+rows,a+rows+1,a+1))
    length=columns*rows
    for col in range(columns-1):
        for row in [0,rows-1]:
            a=col*rows+row;b=(col+1)*rows+row;faces.append((a,b,length+b,length+a))
    for col in [0,columns-1]:
        for row in range(rows-1):
            a=col*rows+row;faces.append((a,a+1,length+a+1,length+a))
    obj=mesh('BeardedForgedHead',verts,faces,uv,'ForgedSteel',owner)
    obj.data.materials.append(MATERIALS['HonedEdge'])
    for face in obj.data.polygons:
        # Follow the authored bevel column, not a world-X threshold cutting
        # across its curved vertices and producing a stepped silver border.
        u=sum(obj.data.uv_layers.active.data[i].uv.x for i in face.loop_indices)/len(face.loop_indices)
        if u>=.92:face.material_index=1

def make_knife():
    owner='Dagger';root(owner);gx,gy,gz=GRIPS[owner]
    anchor(owner,'GripAnchor',GRIPS[owner])
    centers=[];radii=[]
    for i in range(40):
        t=i/39;y=-.18+.14*t
        centers.append((gx+.0015*math.sin((y-gy)*16),y,0))
        r=.0105+.002*math.sin(math.pi*t)
        radii.append((r,r*.84))
    sweep('RoundedKnifeHaft',centers,radii,'AshWood',owner,40,.16)
    grip_wrap('LeatherKnifeBinding',owner,(gx,0,0),-.174,-.049,.0130,.0108,14)
    verts=[];uv=[];faces=[];cols=25;rows=49
    for side in [-1,1]:
        for row in range(rows):
            t=row/(rows-1);y=-.047+.217*t
            width=(.006+.019*math.sin(math.pi*t)**.70)*(1-.85*t**6)
            for col in range(cols):
                u=2*col/(cols-1)-1
                # Irregularly knapped margins and alternating conchoidal scars,
                # rather than the smooth oval of a metal proxy blade.
                phase=1.1 if u>0 else 0
                edge_variation=.5+.24*math.sin(t*31.2+phase)+.16*math.sin(t*53.1-phase)+.10*math.sin(t*11.7)
                x=gx+u*width*(1-.055*edge_variation)+.0015*math.sin(t*8)
                lens=max(0,1-u*u)**.6
                thickness=(.0045+.001*math.sin(t*7))*lens*(1-.84*t**5)+.00020
                scar=0
                for k in range(15):
                    sx=(-1 if k%2 else 1)*(.45+.25*math.sin(k*2.1))
                    sy=(k+.5)/15
                    scar-=.0018*math.exp(-((u-sx)/.31)**2-((t-sy)/.060)**2)*lens
                verts.append((x,y,side*max(.00018,thickness+scar)))
                uv.append(((u+1)/2,t))
                if row and col:
                    a=(0 if side<0 else cols*rows)+(row-1)*cols+col-1
                    faces.extend([(a,a+cols,a+1),(a+1,a+cols,a+cols+1)])
    L=cols*rows
    for row in range(rows-1):
        for col in [0,cols-1]:
            a=row*cols+col;b=(row+1)*cols+col;faces.append((a,b,L+b,L+a))
    for row in [0,rows-1]:
        for col in range(cols-1):
            a=row*cols+col;faces.append((a,a+1,L+a+1,L+a))
    mesh('FlakedStoneBlade',verts,faces,uv,'Flint',owner)
    grip_wrap('BladeTangLashing',owner,(gx,0,0),-.063,-.034,.014,.0115,6)

def make_bow():
    owner='Bow_Wooden';root(owner);gx=GRIPS[owner][0]
    anchor(owner,'GripAnchor',GRIPS[owner])
    anchor(owner,'TopStringNock',(gx+.2055,.5157,0))
    anchor(owner,'BottomStringNock',(gx+.2055,-.5157,0))
    centers=[];radii=[]
    for i in range(121):
        y=-.55+1.10*i/120;t=abs(y)/.55
        # Back surface of the horn nock meets the preserved cord anchors.
        x=gx+.2015*(abs(y)/.5157)**2.6
        centers.append((x,y,0))
        radii.append((.0125*(1-.72*t),.0084*(1-.65*t)))
    limbs=sweep('ContinuousTaperedLimbs',centers,radii,'AshWood',owner,32,.35)
    bow_flex(limbs)
    grip_wrap('BowHideGrip',owner,(gx,0,0),-.055,.055,.014,.0103,9)
    for sign in [-1,1]:
        c=[];r=[]
        for i in range(17):
            y=sign*(.497+.053*i/16);t=abs(y)/.55
            c.append((gx+.2015*(abs(y)/.5157)**2.6,y,0))
            r.append((.0046*(1-.65*i/16),.0044*(1-.65*i/16)))
        horn=sweep('HornNockTop' if sign>0 else 'HornNockBottom',c,r,'Horn',owner,24,.04)
        bow_flex(horn)
    sweep('RestCord',[(gx+.2055,-.5157,0),(gx+.2055,.5157,0)],[(.0011,.0011),(.0011,.0011)],'LinenCord',owner,10)

def make_arrow():
    owner='Arrow';root(owner)
    anchor(owner,'ArrowNockSeat',(0,-.343,0))
    anchor(owner,'ArrowTip',(0,.350,0))
    centers=[(0,-.337+i*.65/40,0) for i in range(41)]
    sweep('StraightAshShaft',centers,[(.0031,.0031)]*41,'AshWood',owner,24,.35)
    # Three curved opaque vanes: no alpha-overdraw cards or square silhouettes.
    for vane in range(3):
        angle=vane*2*math.pi/3;verts=[];faces=[];uv=[]
        for row in range(29):
            t=row/28;y=-.305+.115*t
            width=.013*math.sin(math.pi*t)**.75
            for col in range(5):
                u=col/4;r=.0030+width*u
                bend=.0012*math.sin(math.pi*t)*u*u
                verts.append((r*math.cos(angle)-bend*math.sin(angle),y,r*math.sin(angle)+bend*math.cos(angle)))
                uv.append((u,t))
                if row and col:
                    a=(row-1)*5+col-1;faces.append((a,a+1,a+6,a+5))
        obj=mesh('CurvedFeather%d'%vane,verts,faces,uv,'Feather',owner)
        solid=obj.modifiers.new('Feather thickness','SOLIDIFY');solid.thickness=.00022
        bpy.context.view_layer.objects.active=obj;bpy.ops.object.modifier_apply(modifier=solid.name)
    # Forged broadhead: closed diamond cross-section, sharpened edges and point.
    verts=[];uv=[];faces=[]
    rings=[(.300,.003,.003),(.311,.012,.0027),(.328,.007,.0018),(.350,.0001,.0001)]
    for row,(y,rx,rz) in enumerate(rings):
        for side in range(4):
            a=side*math.pi/2;verts.append((rx*math.cos(a),y,rz*math.sin(a)));uv.append((side/4,row/3))
            if row:faces.append(((row-1)*4+side,(row-1)*4+(side+1)%4,row*4+(side+1)%4,row*4+side))
    faces.extend([(3,2,1,0),(12,13,14,15)])
    mesh('ForgedArrowhead',verts,faces,uv,'HonedEdge',owner,False)
    nock=sweep('HornTailNock',[(0,-.350,0),(0,-.333,0)],[(.0037,.0037)]*2,'Horn',owner,24)
    # A physical open slot accepts the2.6mm gameplay cord instead of letting
    # the string pass through a closed solid cap.
    bpy.ops.mesh.primitive_cube_add(size=1,location=point((0,-.347,0)))
    cutter=bpy.context.object;cutter.dimensions=(.0028,.010,.008)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    boolean=nock.modifiers.new('Open string seat','BOOLEAN');boolean.operation='DIFFERENCE';boolean.solver='EXACT';boolean.object=cutter
    bpy.context.view_layer.objects.active=nock;bpy.ops.object.modifier_apply(modifier=boolean.name)
    bpy.data.objects.remove(cutter,do_unlink=True)

for function in [make_axe,make_knife,make_bow,make_arrow]:function()

manifest={'generator':str(Path(__file__).relative_to(ROOT)),'coordinate_system':'Godot Y-up metres, exported with Blender glTF conversion','geometry_reused_from_rejected_pack':False,'grips':GRIPS,'textures':[],'items':[]}
for label,path in TEXTURES.items():
    manifest['textures'].append({'label':label,'source':path.relative_to(ROOT).as_posix(),'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
for index,(name,record) in enumerate(ITEMS.items()):
    bpy.ops.object.select_all(action='DESELECT')
    record['root'].select_set(True)
    for marker in record['anchors']:marker.select_set(True)
    vertices=[];triangles=0
    for obj in record['objects']:
        obj.select_set(True);obj.data.calc_loop_triangles()
        triangles+=len(obj.data.loop_triangles)
        vertices.extend(godot(obj.matrix_world@v.co) for v in obj.data.vertices)
    lo=[min(v[i] for v in vertices) for i in range(3)];hi=[max(v[i] for v in vertices) for i in range(3)]
    assert triangles<20000, (name,triangles)
    path=OUT/(name+'.gltf')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLTF_SEPARATE',use_selection=True,export_animations=False,export_yup=True,export_morph=True,export_morph_normal=True)
    document=json.loads(path.read_text(encoding='utf-8'))
    # Blender exports the image from this multiply chain but omits its constant
    # tint. Preserve the authored linear factor explicitly in standard glTF.
    for entry in document['materials']:
        if entry['name'] in ['AshWood','GripLeather','ForgedSteel']:
            entry['pbrMetallicRoughness']['baseColorFactor']=list(MATERIALS[entry['name']].diffuse_color)
    path.write_text(json.dumps(document,indent=2)+'\n',encoding='utf-8')
    manifest['items'].append({'name':name,'triangles':triangles,'bounds_min':lo,'bounds_max':hi,'length_m':max(hi[i]-lo[i] for i in range(3)),'anchors':{o.name:godot(o.location) for o in record['anchors']},'morphs':['Draw'] if name=='Bow_Wooden' else [],'gltf_sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    # Keep the editing source easy to inspect without changing exported anchors.
for index,record in enumerate(ITEMS.values()):record['root'].location.x=(index-1.5)*.55
for image in bpy.data.images:
    if image.source=='FILE':image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'SettlerEquipment.blend'))
(OUT/'authoring-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('SETTLER_EQUIPMENT_AUTHORED',json.dumps(manifest),flush=True)
