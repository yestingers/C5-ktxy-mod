import bpy, math, sys
from mathutils import Vector
from pathlib import Path
work=Path(__file__).resolve().parent/'ModelWork'
scene=bpy.context.scene
if '--source-materials' in sys.argv:
    original=bpy.data.objects['Cartethyia_Civ5_Model'].data
    generated=bpy.data.objects['Cartethyia_GamePreview'].data
    generated.materials.clear()
    for m in original.materials:generated.materials.append(m)
    for p in generated.polygons:p.material_index=original.polygons[p.index].material_index
    for src,dst in zip(original.uv_layers.active.data,generated.uv_layers.active.data):dst.uv=src.uv
def point(obj,loc):obj.rotation_euler=(Vector(loc)-obj.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(2.5,-5,2.4))
cam=bpy.context.object;point(cam,(0,0,.85));cam.data.type='ORTHO';cam.data.ortho_scale=2.3;scene.camera=cam
for loc,power,size in [((1,-3,4),450,4),((-3,-1,2),250,3),((0,3,3),500,3)]:
    bpy.ops.object.light_add(type='AREA',location=loc);light=bpy.context.object;light.data.energy=power;light.data.shape='DISK';light.data.size=size;point(light,(0,0,1))
if scene.world is None:scene.world=bpy.data.worlds.new('PreviewWorld')
scene.world.color=(.1,.1,.1)
scene.render.engine='CYCLES';scene.cycles.samples=24
scene.render.resolution_x=800;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.render.filepath=str(work/'bind_preview.png')
bpy.ops.render.render(write_still=True)
