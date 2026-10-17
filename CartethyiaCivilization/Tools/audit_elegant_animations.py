"""Compare actual Firaxis GR2 SampleBone output against authored matrices."""
import hashlib, json, shlex
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[1];WORK=ROOT/'Tools/ModelWork/elegance';GAME=ROOT/'Art/Models/Game'
lines=(GAME/'Cartethyia_Unit.br2').read_text().splitlines()
names=[shlex.split(s)[1] for s in lines[2:lines.index('meshes: 1')]]
report=[]
for path in sorted((GAME/'Animations').glob('Cartethyia_*.gr2')):
 source=json.loads(path.with_suffix('.na2.source.json').read_text())
 for key,file in [('animation_sha256',path),('model_sha256',GAME/'Cartethyia_Unit.gr2'),('sample_sha256',path.with_suffix('.na2'))]:
  assert source[key]==hashlib.sha256(file.read_bytes()).hexdigest(),f'Stale native readback: {file}'
 action=path.stem.removeprefix('Cartethyia_');data=path.with_suffix('.na2').read_text().splitlines();n=int(data[2].split(':')[1]);i=7;tracks={}
 while i<len(data):
  name=data[i];i+=1;tracks[name]=np.array([list(map(float,s.split())) for s in data[i:i+n]]).reshape(n,4,4).transpose(0,2,1);i+=n
 assert set(tracks)==set(names),(path,'incomplete tracks')
 actual=np.stack([tracks[name] for name in names],axis=1)
 expected=np.load(WORK/f'{action}.expected.npz')['world']
 assert actual.shape==expected.shape,(path,actual.shape,expected.shape)
 error=float(np.max(np.abs(actual-expected)));assert error<.02,(path,error)
 assert np.isfinite(actual).all()
 report.append({'file':path.name,'sha256':source['animation_sha256'],'model_sha256':source['model_sha256'],'frames':n,'bones':len(tracks),'max_matrix_error':error})
assert len(report)==31,len(report)
(GAME/'Animations.audit.json').write_text(json.dumps(report,indent=2))
print(f'{len(report)} animations, {sum(a["frames"] for a in report)} frames: max matrix error {max(a["max_matrix_error"] for a in report):.6f}')
