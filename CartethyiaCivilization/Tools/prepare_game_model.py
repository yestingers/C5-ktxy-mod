"""Create a separate Civ5 bind-pose mesh/atlas from the preserved Blender source.

Run with Blender --background SOURCE.blend --python this_file.py.
Reference BR2 is exported from the user's installed Longswordsman through Nexus Buddy.
"""
import bpy, bmesh, json, math, shlex
import numpy as np
from pathlib import Path
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT/'Tools/ModelWork'
OUT = ROOT/'Art/Models/Game'
OUT.mkdir(parents=True, exist_ok=True)
source = next(o for o in bpy.data.objects if o.type == 'MESH')
arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
lines = (WORK/'reference/longswordsman.br2').read_text().splitlines()
bone_lines = lines[2:lines.index('meshes: 1')]
names, worlds = [], []
for line in bone_lines:
    parts = shlex.split(line)
    names.append(parts[1])
    values = list(map(float,parts[10:26]))
    worlds.append(Matrix([values[i:i+4] for i in range(0,16,4)]).transposed().inverted())
target = {n:worlds[i] for i,n in enumerate(names)}
index = {n:i for i,n in enumerate(names)}

# Semantic mapping, then ancestor collapse of MMD hair/cloth/accessory chains.
mapping = {'腰':'Base HumanPelvis','下半身':'Base HumanPelvis',
 '上半身':'Base HumanSpine1','上半身1':'Base HumanSpine2','上半身2':'Base HumanRibcage',
 '首':'Base HumanNeck1','頭':'Base HumanNeck2'}
segments = {}
for side in ('L','R'):
    for source_name, target_name, end_name, target_end in (
        ('腕','Upperarm','ひじ','Forearm'), ('ひじ','Forearm','手首','Palm'),
        ('足','Thigh','ひざ','Calf'), ('ひざ','Calf','足首','Foot')):
        s=f'{source_name}.{side}'; e=f'{end_name}.{side}'
        t=f'Base Human{side}{target_name}'; te=f'Base Human{side}{target_end}'
        mapping[s]=t
        segments[t]=(arm.data.bones[s].head_local.copy(),arm.data.bones[e].head_local.copy(),target[t].translation,target[te].translation)
    for src, dst in [('肩','Collarbone'),('肩P','Collarbone'),('肩C','Collarbone'),('手首','Palm'),('足首','Foot'),('つま先','Foot'),('足先EX','Foot'),('足D','Thigh'),('ひざD','Calf'),('足首D','Foot')]:
        mapping[f'{src}.{side}']=f'Base Human{side}{dst}'
    for src, dst in [('手首','Palm'),('足首','Foot')]:
        b=arm.data.bones[f'{src}.{side}'];t=f'Base Human{side}{dst}'
        # Source tail gives the hand/foot direction. Reference local X is the bone axis.
        direction=target[t].to_3x3().col[0].normalized()
        if dst=='Foot': direction=Vector((0,-1,-0.15)).normalized()
        segments[t]=(b.head_local.copy(),b.tail_local.copy(),target[t].translation,target[t].translation+direction*(b.length*65))

def target_for_group(name):
    plain=name.removeprefix('_shadow_').removeprefix('_dummy_')
    if plain in mapping:return mapping[plain]
    b=arm.data.bones.get(name)
    while b:
        if b.name in mapping:return mapping[b.name]
        b=b.parent
    return 'Base HumanPelvis'

group_target={g.index:target_for_group(g.name) for g in source.vertex_groups}
def warp_body(v):
    z=float(np.interp(v.z,[0,.121,.540,.969,1.196,1.397,1.471,1.714],[0,6,34,61.6,80,100,105.6,122]))
    return Vector((v.x*65,v.y*65,z))

def warp_segment(v, t):
    if t not in segments:return warp_body(v)
    a,b,c,d=segments[t]; sv=b-a;tv=d-c
    axis=sv.normalized(); delta=v-a;along=delta.dot(axis)
    rot=axis.rotation_difference(tv.normalized())
    return c+tv*(along/sv.length)+(rot@(delta-axis*along))*65

weights=[];positions=[]
for v in source.data.vertices:
    merged={}
    for g in v.groups:
        if g.weight>1e-6:
            t=group_target[g.group];merged[t]=merged.get(t,0)+g.weight
    pairs=sorted(merged.items(),key=lambda item:item[1],reverse=True)[:4]
    if not pairs:pairs=[('Base HumanPelvis',1)]
    total=sum(w for _,w in pairs);pairs=[(t,w/total) for t,w in pairs]
    pos=sum((warp_segment(v.co,t)*w for t,w in pairs),Vector())
    positions.append(pos);weights.append(pairs)

# Pack diffuse textures with a two-pixel gutter. Retain original materials in source.
images=[];material_tiles=[]
for m in source.data.materials:
    n=m.node_tree.nodes.get('mmd_base_tex') if m.use_nodes else None
    image=n.image if n else None
    if image not in images:images.append(image)
    material_tiles.append(images.index(image))
assert len(images)<=16
tile=512;edge=2;dim=tile*4
atlas=np.zeros((dim,dim,4),dtype=np.float32)
for i,image in enumerate(images):
    if image:
        copy=image.copy();copy.scale(tile-2*edge,tile-2*edge)
        pixels=np.array(copy.pixels[:],dtype=np.float32).reshape((tile-2*edge,tile-2*edge,4))
        bpy.data.images.remove(copy)
    else:pixels=np.ones((tile-2*edge,tile-2*edge,4),dtype=np.float32)
    y,x=divmod(i,4);atlas[y*tile:(y+1)*tile,x*tile:(x+1)*tile]=np.pad(pixels,((edge,edge),(edge,edge),(0,0)),mode='edge')
# The removed Face+ overlay frees tile 1 for the reference sword's pale metal.
atlas[0:tile,tile:tile*2]=(.65,.8,.95,1)
image=bpy.data.images.new('Cartethyia_Unit_DIFF',width=dim,height=dim,alpha=True)
image.pixels.foreach_set(atlas.ravel());image.filepath_raw=str(OUT/'Cartethyia_Unit_DIFF.png');image.file_format='PNG';image.save()

# Work on a copy so the source and its 24 packed images remain untouched.
mesh=source.data.copy();mesh.name='Cartethyia_GameMesh'
for v,p in zip(mesh.vertices,positions):v.co=p
mesh.update();mesh.calc_loop_triangles();mesh.calc_tangents()
vertices=[];triangles=[];lookup={}
excluded={i for i,m in enumerate(source.data.materials) if m.name in {'Hair_Bangs+','Hair_Back+','Up_Metal','Down_Metal','Face+','Eye_Hi','Eye_+','Facial','Star'}}
for tri in mesh.loop_triangles:
    if tri.material_index in excluded:continue
    ids=[];ti=material_tiles[tri.material_index];ty,tx=divmod(ti,4)
    for li in tri.loops:
        loop=mesh.loops[li];v=mesh.vertices[loop.vertex_index];uv=mesh.uv_layers.active.data[li].uv
        u=min(max(uv.x,0),1);vv=min(max(uv.y,0),1)
        au=(tx*tile+edge+u*(tile-2*edge))/dim
        av=(ty*tile+edge+vv*(tile-2*edge))/dim
        key=(v.index,round(au,6),round(av,6),tuple(round(n,4) for n in loop.normal))
        if key not in lookup:
            pairs=weights[v.index];bi=[index[t] for t,_ in pairs];bw=[round(w*255) for _,w in pairs];bw[0]+=255-sum(bw)
            bi += [0]*(4-len(bi));bw += [0]*(4-len(bw))
            tangent=loop.tangent;binormal=loop.normal.cross(tangent)*loop.bitangent_sign
            # Civ5 texture V is inverted compared with Blender UV.
            row=list(v.co)+list(loop.normal)+[au,1-av]+bi+bw+list(tangent)+list(binormal)
            lookup[key]=len(vertices);vertices.append(row)
        ids.append(lookup[key])
    triangles.append(ids)
# Keep the stock animated weapon geometry so attack/weapon effect anchors agree.
vstart=lines.index('vertices')+1;tstart=lines.index('triangles')
rv=[list(map(float,l.split())) for l in lines[vstart:tstart]]
rt=[list(map(int,l.split())) for l in lines[tstart+1:] if l and not l.startswith('end')]
sword_lookup={}
for tr in rt:
    if not all(int(rv[i][8+max(range(4),key=lambda k:rv[i][12+k])]) in (15,17) for i in tr):continue
    ids=[]
    for i in tr:
        if i not in sword_lookup:
            row=rv[i][:];row[6:8]=[.375,.875]
            row[8:16]=[int(v) for v in row[8:16]]
            sword_lookup[i]=len(vertices);vertices.append(row)
        ids.append(sword_lookup[i])
    triangles.append(ids)
assert len(vertices)<65536, len(vertices)
br2=WORK/'Cartethyia_Unit.br2'
with br2.open('w',encoding='ascii') as f:
    f.write('// Cartethyia game mesh on stock Longswordsman bind skeleton\nskeleton\n'+'\n'.join(bone_lines)+'\nmeshes: 1\nmesh:"Cartethyia_Unit"\nvertices\n')
    for row in vertices:f.write(' '.join(f'{v:.8f}' if isinstance(v,float) else str(v) for v in row)+'\n')
    f.write('triangles\n')
    for row in triangles:f.write(' '.join(map(str,row))+'\n')
    f.write('end\n')

# A separate Blender preview mesh uses the same atlas/UVs and exact generated positions.
preview=bpy.data.objects.new('Cartethyia_GamePreview',mesh);bpy.context.collection.objects.link(preview)
for obj in list(bpy.data.objects):
    if obj!=preview and obj.type in ('MESH','ARMATURE'):obj.hide_render=True;obj.hide_viewport=True
mat=bpy.data.materials.new('Cartethyia_GameAtlas');mat.use_nodes=True
nodes=mat.node_tree.nodes;bsdf=nodes.get('Principled BSDF');tex=nodes.new('ShaderNodeTexImage');tex.image=image
mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color']);mat.node_tree.links.new(tex.outputs['Alpha'],bsdf.inputs['Alpha']);bsdf.inputs['Roughness'].default_value=.65
mesh.materials.clear();mesh.materials.append(mat)
drop_faces=[]
for poly in mesh.polygons:
    if source.data.polygons[poly.index].material_index in excluded:drop_faces.append(poly.index)
    ti=material_tiles[source.data.polygons[poly.index].material_index];ty,tx=divmod(ti,4)
    for li in poly.loop_indices:
        uv=mesh.uv_layers.active.data[li].uv;uv.x=(tx*tile+edge+min(max(uv.x,0),1)*(tile-2*edge))/dim;uv.y=(ty*tile+edge+min(max(uv.y,0),1)*(tile-2*edge))/dim
    poly.material_index=0
bm=bmesh.new();bm.from_mesh(mesh);bm.faces.ensure_lookup_table();bmesh.ops.delete(bm,geom=[bm.faces[i] for i in drop_faces],context='FACES');bm.to_mesh(mesh);bm.free()
preview.scale=(.014,.014,.014)
bpy.ops.wm.save_as_mainfile(filepath=str(WORK/'Cartethyia_GamePreview.blend'))
(WORK/'prepared_model.json').write_text(json.dumps({'vertices':len(vertices),'triangles':len(triangles),'bones':names,'images':[i.name if i else None for i in images]},indent=2))
print('PREPARED',len(vertices),len(triangles),len(names),'bones')
