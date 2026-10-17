"""Author local curves on the exact shipped skeleton. Run with Blender Python."""
import json, math, shlex, sys
import numpy as np
from pathlib import Path
from mathutils import Matrix, Vector, Quaternion
ROOT=Path(__file__).resolve().parents[1];WORK=ROOT/'Tools/ModelWork';REF=WORK/'reference';OUT=WORK/'elegance';OUT.mkdir(exist_ok=True)
lines=(ROOT/'Art/Models/Game/Cartethyia_Unit.br2').read_text().splitlines();names=[];parents=[];bind=[]
for s in lines[2:lines.index('meshes: 1')]:
 a=shlex.split(s);names.append(a[1]);parents.append(int(a[2]));v=list(map(float,a[10:26]));bind.append(Matrix([v[j:j+4] for j in range(0,16,4)]).transposed().inverted())
ix={n:i for i,n in enumerate(names)}
def read_na2(path):
 data=path.read_text().splitlines();count=int(data[2].split(':')[1]);i=7;tracks={}
 while i<len(data):
  name=data[i];i+=1;rows=[]
  for line in data[i:i+count]:
   v=list(map(float,line.split()));assert len(v)==16;rows.append(Matrix([v[j:j+4] for j in range(0,16,4)]).transposed())
  tracks[name]=rows;i+=count
 assert set(tracks)==set(names)
 return [[tracks[n][f] for n in names] for f in range(count)]
def local(w):return [w[p].inverted()@m if p>=0 else m.copy() for p,m in zip(parents,w)]
def world(l):
 out=[]
 for p,m in zip(parents,l):out.append(out[p]@m if p>=0 else m.copy())
 return out
def mix(a,b,t):
 pa,qa,sa=a.decompose();pb,qb,sb=b.decompose()
 return Matrix.LocRotScale(pa.lerp(pb,t),qa.slerp(qb,t),sa.lerp(sb,t))
def descendants(i):
 r=[i]
 for j in range(len(names)):
  if parents[j] in r:r.append(j)
 return set(r)
def transform(w,i,delta):
 for j in descendants(i):w[j]=delta@w[j]
def aim(w,bone,child,direction):
 i,j=ix[bone],ix[child];p=w[i].translation;old=w[j].translation-p
 q=old.normalized().rotation_difference(Vector(direction).normalized())
 transform(w,i,Matrix.Translation(p)@q.to_matrix().to_4x4()@Matrix.Translation(-p))
def serialize(frames,path):
 loc=[local(w) for w in frames];tracks=[]
 for i,name in enumerate(names):
  t={'name':name,'position':[],'orientation':[],'scale':[]};prev=None
  for frame in loc:
   p,q,s=frame[i].decompose();q.normalize()
   if prev is not None and q.dot(prev)<0:q.negate()
   prev=q.copy();t['position']+=list(p);t['orientation'] += [q.x,q.y,q.z,q.w];t['scale'] += [s.x,0,0,0,s.y,0,0,0,s.z]
  tracks.append(t)
 path.write_text(json.dumps({'duration':(len(frames)-1)/30,'times':[i/30 for i in range(len(frames))],'tracks':tracks}))
stock_idle=read_na2(REF/'longswordsman_idlea.na2')
if '--roundtrip' in sys.argv:
 serialize(stock_idle,WORK/'curve_roundtrip.json');print('ROUNDTRIP_INPUT');raise SystemExit

# Upright neutral stance with arms close to the body and a lowered sword.
neutral=[m.copy() for m in bind]
for side,sgn in [('L',1),('R',-1)]:
 aim(neutral,f'Base Human{side}Thigh',f'Base Human{side}Calf',(sgn*.08,0,-1))
 aim(neutral,f'Base Human{side}Calf',f'Base Human{side}Foot',(0,.04,-1))
 aim(neutral,f'Base Human{side}Upperarm',f'Base Human{side}Forearm',(sgn*.12,-.10,-1))
 aim(neutral,f'Base Human{side}Forearm',f'Base Human{side}Palm',(sgn*.10,-.32,-1))
palm=ix['Base HumanRPalm'];sword=ix['Point_SWORD_CON'];tip=ix['Base HumanSword02'];blade=ix['Base HumanSword01']
grip=stock_idle[0][palm].inverted()@stock_idle[0][sword]
new=neutral[palm]@grip;transform(neutral,sword,new@neutral[sword].inverted())
p=neutral[sword].translation;q=(neutral[tip].translation-neutral[blade].translation).normalized().rotation_difference(Vector((-.65,-.15,-.75)).normalized())
transform(neutral,sword,Matrix.Translation(p)@q.to_matrix().to_4x4()@Matrix.Diagonal(Vector((.72,.72,.72,1)))@Matrix.Translation(-p))
elegant_local=local(neutral)
serialize([neutral,neutral],OUT/'neutral.json')

for path in sorted(REF.glob('longswordsman_*.na2')):
 action=path.stem.removeprefix('longswordsman_')
 frames=read_na2(REF/f'longswordsman_{action}.na2');out=[]
 for f,original in enumerate(frames):
  t=f/(len(frames)-1);old=local(original)
  is_attack='attack' in action
  is_move=action in ('run','charge_run','shuffle','stop_run','stop_run_trans_idleb')
  is_death='death' in action
  if not (is_attack or is_move or is_death):
   pose=[m.copy() for m in elegant_local]
   i=ix['Base HumanSpine2'];pose[i]=pose[i]@Matrix.Rotation(math.radians(.7)*math.sin(t*math.tau),4,'Z')
   i=ix['Base HumanNeck2'];pose[i]=pose[i]@Matrix.Rotation(math.radians(.5)*math.sin(t*math.tau),4,'Y')
  elif is_move:
   pose=[m.copy() for m in old]
   for i in range(len(names)):
    if i in range(3,14) or i>=24:pose[i]=mix(elegant_local[i],old[i],.20)
   # Keep the stock legs and root trajectory so feet retain their original timing.
   if action.startswith('stop_run'):
    smooth=t*t*(3-2*t);pose=[mix(m,elegant_local[i],smooth) for i,m in enumerate(pose)]
  elif is_attack:
   # Same hit timing as the source. Smooth preparation and recovery to the new idle.
   weight=min(1,t/.24,(1-t)/.26);weight=max(0,weight);weight=weight*weight*(3-2*weight)
   pose=[mix(elegant_local[i],old[i],weight) for i in range(len(names))]
  else:pose=old
  w=world(pose)
  if is_move:
   new=w[palm]@neutral[palm].inverted()@neutral[sword];transform(w,sword,new@w[sword].inverted())
  elif is_attack or is_death:
   # Preserve the authored attack sword motion while reducing the oversized weapon.
   anchor=w[sword].translation;current=w[sword].to_scale().x;scale=.72/current
   transform(w,sword,Matrix.Translation(anchor)@Matrix.Diagonal(Vector((scale,scale,scale,1)))@Matrix.Translation(-anchor))
  out.append(w)
 serialize(out,OUT/f'{action}.json')
 np.savez_compressed(OUT/f'{action}.expected.npz',world=np.array([[[list(row) for row in m] for m in frame] for frame in out]))
print('AUTHORED',OUT)
