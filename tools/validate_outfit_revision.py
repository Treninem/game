"""Independent GLB preservation gate for a default-outfit occlusion revision.

The new body may omit covered faces; every retained skin/morph point must be
native. Exposed head/neck/hands, five standalone parts, original outer-cloth
triangles, bind frames, images and every animation channel must be preserved.
"""
import argparse
import hashlib
import json
import struct
import itertools
from pathlib import Path


class GLB:
    def __init__(self,path):
        raw=path.read_bytes()
        assert raw[:4]==b'glTF'
        length=struct.unpack_from('<I',raw,12)[0]
        self.data=json.loads(raw[20:20+length])
        self.binary=raw[28+length:]

    def accessor(self,index):
        a=self.data['accessors'][index]
        components={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
        fmt='<'+{5120:'b',5121:'B',5122:'h',5123:'H',5125:'I',5126:'f'}[a['componentType']]*components
        size=struct.calcsize(fmt)
        result=[tuple(0 for _ in range(components)) for i in range(a['count'])]
        if 'bufferView' in a:
            view=self.data['bufferViews'][a['bufferView']]
            offset=view.get('byteOffset',0)+a.get('byteOffset',0)
            stride=view.get('byteStride',size)
            result=[struct.unpack_from(fmt,self.binary,offset+i*stride) for i in range(a['count'])]
        if 'sparse' in a:
            sparse=a['sparse'];indices=sparse['indices'];values=sparse['values']
            iv=self.data['bufferViews'][indices['bufferView']]
            vv=self.data['bufferViews'][values['bufferView']]
            ifmt='<'+{5121:'B',5123:'H',5125:'I'}[indices['componentType']]
            start=iv.get('byteOffset',0)+indices.get('byteOffset',0)
            data_start=vv.get('byteOffset',0)+values.get('byteOffset',0)
            for i in range(sparse['count']):
                index=struct.unpack_from(ifmt,self.binary,start+i*struct.calcsize(ifmt))[0]
                result[index]=struct.unpack_from(fmt,self.binary,data_start+i*size)
        return result

    def meshes(self):
        return {n['name']:self.data['meshes'][n['mesh']] for n in self.data['nodes'] if 'mesh' in n}

    def image_hashes(self):
        result={}
        for image in self.data['images']:
            assert 'uri' not in image,'Production GLB has an external image'
            view=self.data['bufferViews'][image['bufferView']]
            start=view.get('byteOffset',0)
            result[image['name']]=hashlib.sha256(self.binary[start:start+view['byteLength']]).hexdigest()
        return result


def equivalent(a,b,label):
    assert len(a)==len(b),(label,len(a),len(b))
    assert all(len(x)==len(y) and all(abs(p-q)<1e-6 for p,q in zip(x,y)) for x,y in zip(a,b)),label


def vertex_match(source_positions,source_uv,points,uvs):
    # Spatial buckets only accelerate lookup. Acceptance remains one micrometre
    # for position/UV; decimal-round boundaries cannot reject equivalent floats.
    buckets={}
    def cell(point):return tuple(round(v*10000) for v in point)
    for i,p in enumerate(source_positions):buckets.setdefault(cell(p),[]).append(i)
    matches=[]
    for p,uv in zip(points,uvs):
        center=cell(p);found=None
        for delta in itertools.product([-1,0,1],repeat=3):
            for i in buckets.get(tuple(a+b for a,b in zip(center,delta)),[]):
                if all(abs(a-b)<1e-6 for a,b in zip(source_positions[i]+source_uv[i],p+uv)):
                    found=i;break
            if found is not None:break
        matches.append(found)
    return matches


def check(before,after,sex):
    a=GLB(before);b=GLB(after)
    am=a.meshes();bm=b.meshes()
    parts={'HumanBody','Clothing','Boots','Eyes','HairShort','HairPonytail','Brows'}
    assert set(am)==set(bm)==parts,(sex,set(am),set(bm))
    assert a.image_hashes()==b.image_hashes(),(sex,'authored image changed')
    for part in parts-{'HumanBody','Clothing'}:
        pa=am[part]['primitives'];pb=bm[part]['primitives']
        assert len(pa)==len(pb)
        assert am[part].get('extras',{}).get('targetNames')==bm[part].get('extras',{}).get('targetNames')
        for left,right in zip(pa,pb):
            assert left['attributes'].keys()==right['attributes'].keys()
            for key in left['attributes']:equivalent(a.accessor(left['attributes'][key]),b.accessor(right['attributes'][key]),(sex,part,key))
            equivalent(a.accessor(left['indices']),b.accessor(right['indices']),(sex,part,'topology'))
            assert len(left['targets'])==len(right['targets'])==9
            for i,(ta,tb) in enumerate(zip(left['targets'],right['targets'])):
                assert ta.keys()==tb.keys()
                for key in ta:equivalent(a.accessor(ta[key]),b.accessor(tb[key]),(sex,part,'morph',i,key))
    old_cloth=am['Clothing']['primitives'];new_cloth=bm['Clothing']['primitives']
    def roles(g,primitives):return {g.data['materials'][p['material']]['name']:p for p in primitives}
    old_roles=roles(a,old_cloth);new_roles=roles(b,new_cloth)
    assert set(old_roles)=={'VikingTunic','VikingPants'}
    assert set(new_roles)==set(old_roles)|{'OutfitLining'},'Original outfit material roles lost or unexpected new material'
    lining_material=b.data['materials'][new_roles['OutfitLining']['material']]
    assert 'normalTexture' not in lining_material and 'occlusionTexture' not in lining_material,'Lining uses unrelated baked surface maps'
    assert lining_material['pbrMetallicRoughness'].get('roughnessFactor',1)>=.9
    for label in old_roles:
        pa=old_roles[label];pb=new_roles[label]
        ap=a.accessor(pa['attributes']['POSITION']);bp=b.accessor(pb['attributes']['POSITION'])
        au=a.accessor(pa['attributes']['TEXCOORD_0']);bu=b.accessor(pb['attributes']['TEXCOORD_0'])
        mapping=vertex_match(bp,bu,ap,au)
        assert all(i is not None for i in mapping),(sex,'original cloth point/UV lost')
        for key in pa['attributes']:
            left=a.accessor(pa['attributes'][key]);right=b.accessor(pb['attributes'][key])
            equivalent(left,[right[i] for i in mapping],(sex,'original cloth',key))
        for ta,tb in zip(pa['targets'],pb['targets']):
            for key in ta:
                left=a.accessor(ta[key]);right=b.accessor(tb[key])
                equivalent(left,[right[i] for i in mapping],(sex,'original cloth morph',key))
        old_indices=[mapping[x[0]] for x in a.accessor(pa['indices'])]
        new_indices=[x[0] for x in b.accessor(pb['indices'])]
        def canonical(ids):
            return {min(tuple(ids[i+j:i+3]+ids[i:i+j]) for j in range(3)) for i in range(0,len(ids),3)}
        assert canonical(old_indices)<=canonical(new_indices),(sex,'original garment triangle changed')
    na={n['name']:n for n in a.data['nodes']};nb={n['name']:n for n in b.data['nodes']}
    assert na.keys()==nb.keys()
    for name in na:
        for key in ['translation','rotation','scale','matrix']:
            equivalent([na[name].get(key,[])],[nb[name].get(key,[])],(sex,name,'bind',key))
    aa={v['name']:v for v in a.data['animations']};ab={v['name']:v for v in b.data['animations']}
    assert aa.keys()==ab.keys() and len(aa)==10
    for name in aa:
        def channels(g,animation):
            result={}
            for channel in animation['channels']:
                target=channel['target'];label=(g.data['nodes'][target['node']]['name'],target['path'])
                sampler=animation['samplers'][channel['sampler']]
                result[label]=(g.accessor(sampler['input']),g.accessor(sampler['output']))
            return result
        ca=channels(a,aa[name]);cb=channels(b,ab[name]);assert ca.keys()==cb.keys()
        for channel in ca:
            for i in range(2):equivalent(ca[channel][i],cb[channel][i],(sex,name,channel,i))
    pa=am['HumanBody']['primitives'][0];pb=bm['HumanBody']['primitives'][0]
    ap=a.accessor(pa['attributes']['POSITION']);bp=b.accessor(pb['attributes']['POSITION'])
    au=a.accessor(pa['attributes']['TEXCOORD_0']);bu=b.accessor(pb['attributes']['TEXCOORD_0'])
    retained=vertex_match(ap,au,bp,bu)
    assert all(i is not None for i in retained),(sex,'non-native skin point/UV')
    for ta,tb in zip(pa['targets'],pb['targets']):
        left=a.accessor(ta['POSITION']);right=b.accessor(tb['POSITION'])
        equivalent([left[i] for i in retained],right,(sex,'native body morph'))
    exposed_mapping=vertex_match(bp,bu,ap,au)
    old_node=next(n for n in a.data['nodes'] if n['name']=='HumanBody')
    new_node=next(n for n in b.data['nodes'] if n['name']=='HumanBody')
    old_skin=a.data['skins'][old_node['skin']];new_skin=b.data['skins'][new_node['skin']]
    equivalent(a.accessor(old_skin['inverseBindMatrices']),b.accessor(new_skin['inverseBindMatrices']),(sex,'inverse bind frames'))
    for label in ['JOINTS_0','WEIGHTS_0']:
        left=a.accessor(pa['attributes'][label]);right=b.accessor(pb['attributes'][label])
        equivalent([left[i] for i in retained],right,(sex,'native body',label))
    joints=a.data['skins'][old_node['skin']]['joints']
    bone_names=[a.data['nodes'][i]['name'] for i in joints]
    bones=a.accessor(pa['attributes']['JOINTS_0']);weights=a.accessor(pa['attributes']['WEIGHTS_0'])
    exposed=0
    for i,(p,uv) in enumerate(zip(ap,au)):
        dominant=bone_names[bones[i][max(range(4),key=lambda j:weights[i][j])]]
        if any(part in dominant for part in ['Head','Neck','Hand','Jaw','Eye']):
            assert exposed_mapping[i] is not None,(sex,'exposed skin removed',dominant,p)
            exposed+=1
    triangles_before=len(a.accessor(pa['indices']));triangles_after=len(b.accessor(pb['indices']))
    assert 0<triangles_after<triangles_before
    return {'sex':sex,'unchanged_other_parts':5,'original_clothing_triangles_preserved':True,'unchanged_clips':10,'morphs':9,'exposed_skin_vertices_retained':exposed,
            'body_triangles_before':triangles_before//3,'body_triangles_after':triangles_after//3,
            'all_retained_body_positions_uv_and_morphs_native':True,'all_authored_images_unchanged':True}


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--baseline',type=Path,required=True)
    parser.add_argument('--candidate',type=Path,required=True)
    parser.add_argument('--report',type=Path,required=True)
    args=parser.parse_args()
    rows=[check(args.baseline/(sex+'.glb'),args.candidate/(sex+'.glb'),sex) for sex in ['male','female']]
    args.report.write_text(json.dumps(rows,indent=2),encoding='utf-8')
    print('OUTFIT_REVISION_PRESERVATION_OK',json.dumps(rows))
