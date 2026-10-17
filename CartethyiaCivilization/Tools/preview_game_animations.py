"""Preview the serialized GR2 mesh with transforms sampled by Firaxis Granny."""
import bpy, json, shlex, sys
import numpy as np
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];WORK=ROOT/'Tools/ModelWork';OUT=ROOT/'Art/Models/Game'
ANIM=WORK/'elegance' if '--elegance' in sys.argv else WORK/'reference'
RENDERS=WORK/'elegance' if '--elegance' in sys.argv else WORK
lines=(OUT/'Cartethyia_Unit.br2').read_text().splitlines()
end=lines.index('meshes: 1');names=[];inverse=[]
for l in lines[2:end]:
    a=shlex.split(l);names.append(a[1]);inverse.append(np.array(list(map(float,a[10:26]))).reshape(4,4).T)
vs=lines.index('vertices')+1;ts=lines.index('triangles')
v=np.array([list(map(float,l.split())) for l in lines[vs:ts]])
tri=[tuple(map(int,l.split())) for l in lines[ts+1:] if l and not l.startswith('end')]
pos=np.column_stack((v[:,:3],np.ones(len(v))));boneidx=v[:,8:12].astype(int);weights=v[:,12:16]/255
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
mesh=bpy.data.meshes.new('GR2_Readback');mesh.from_pydata(v[:,:3].tolist(),[],tri);mesh.update()
obj=bpy.data.objects.new('Cartethyia_GR2',mesh);bpy.context.collection.objects.link(obj);obj.scale=(.014,)*3
uv=mesh.uv_layers.new()
for loop in mesh.loops:uv.data[loop.index].uv=(v[loop.vertex_index,6],1-v[loop.vertex_index,7])
for p in mesh.polygons:p.use_smooth=True
mat=bpy.data.materials.new('GameTexture');mat.use_nodes=True;n=mat.node_tree.nodes;tex=n.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(OUT/'Cartethyia_Unit_DIFF.png'));p=n.get('Principled BSDF');p.inputs['Roughness'].default_value=.7;mat.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color']);mat.node_tree.links.new(tex.outputs['Alpha'],p.inputs['Alpha']);mesh.materials.append(mat)
scene=bpy.context.scene
def point(o,loc):o.rotation_euler=(Vector(loc)-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(2.4,-5,2.6));cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=2.9;point(cam,(0,0,.9));scene.camera=cam
for loc,power in [((1,-3,4),450),((-3,-1,2),250),((0,3,3),500)]:
    bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.size=4;point(o,(0,0,1))
scene.world=bpy.data.worlds.new('World');scene.world.color=(.15,.15,.15)
scene.render.engine='CYCLES';scene.cycles.samples=16;scene.render.resolution_x=500;scene.render.resolution_y=600;scene.render.resolution_percentage=100
reports={}
for action in ('idlea','run','attacka'):
    data=(ANIM/f'longswordsman_{action}.na2').read_text().splitlines();count=int(data[2].split(':')[1]);cur=7;anims={}
    while cur<len(data):
        name=data[cur].strip();cur+=1
        if not name:continue
        rows=[]
        while cur<len(data) and len(data[cur].split())==16:
            rows.append(np.array(list(map(float,data[cur].split()))).reshape(4,4).T);cur+=1
        assert len(rows)==count,(name,len(rows),count)
        anims[name]=rows
    assert set(names)==set(anims)
    frames=[]
    for frame in range(count):
        transforms=np.stack([anims[name][frame]@inverse[i] for i,name in enumerate(names)])
        result=np.zeros((len(v),4))
        for j in range(4):result+=np.einsum('nij,nj->ni',transforms[boneidx[:,j]],pos)*weights[:,j,None]
        assert np.isfinite(result).all()
        assert np.max(np.ptp(result[:,:3],axis=0))<350, 'Exploding pose'
        frames.append(result[:,:3])
    reports[action]={'frames':count,'max_displacement':float(np.max(np.linalg.norm(np.stack(frames)-frames[0],axis=2)))}
    for sequence,frame in enumerate([0,count//3,2*count//3]):
        mesh.vertices.foreach_set('co',frames[frame].ravel());mesh.update();scene.render.filepath=str(RENDERS/f'{action}_{sequence}.png');bpy.ops.render.render(write_still=True)
(RENDERS/'animation_preview_report.json').write_text(json.dumps(reports,indent=2))
print('ANIMATION_REPORT',reports)
