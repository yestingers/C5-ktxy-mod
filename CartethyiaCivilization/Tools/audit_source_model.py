import bpy, json
from pathlib import Path
root=Path(__file__).resolve().parent/'ModelWork'
mesh=next(o for o in bpy.data.objects if o.type=='MESH')
arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
used={g.group for v in mesh.data.vertices for g in v.groups if g.weight>0.001}
data={'mesh_matrix':[list(r) for r in mesh.matrix_world], 'arm_matrix':[list(r) for r in arm.matrix_world],
 'bones':[{'name':b.name,'parent':b.parent.name if b.parent else None,'head':list(arm.matrix_world@b.head_local),'tail':list(arm.matrix_world@b.tail_local)} for b in arm.data.bones],
 'groups':[g.name for g in mesh.vertex_groups if g.index in used],
 'materials':[{'name':m.name,'diffuse':list(m.diffuse_color),'nodes':[{'name':n.name,'type':n.type,'image':n.image.name if n.type=='TEX_IMAGE' and n.image else None} for n in m.node_tree.nodes] if m.use_nodes else [],'mmd_texture':str(getattr(getattr(m,'mmd_material',None),'texture',''))} for m in mesh.data.materials]}
(root/'source_audit.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf8')
print('AUDIT',len(data['bones']),len(data['groups']),len(data['materials']))
