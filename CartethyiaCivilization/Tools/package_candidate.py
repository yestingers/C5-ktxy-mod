"""Build a runtime-only candidate from the mod manifest, then verify every entry."""
from pathlib import Path
import hashlib
import json
import zipfile
import xml.etree.ElementTree as ET
import argparse

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'Cartethyia Civilization (v 1).modinfo'
OUT = ROOT.parent / 'artifacts' / 'CartethyiaCivilization_ModelCandidate_2026-10-17.zip'

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--output',type=Path,default=OUT)
    parser.add_argument('--folder',default='CartethyiaCivilization_V0.2')
    args=parser.parse_args()
    output=args.output.resolve()
    assert args.folder and '/' not in args.folder and '\\' not in args.folder and args.folder not in ('.','..')
    files = [r.text for r in ET.parse(MANIFEST).findall('./Files/File')]
    files.append(MANIFEST.name)
    assert len(files) == len(set(files)), 'Duplicate manifest path'
    hashes = {}
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name in files:
            source = (ROOT / name).resolve()
            assert source.is_relative_to(ROOT) and source.is_file(), name
            data = source.read_bytes()
            hashes[name] = hashlib.sha256(data).hexdigest()
            archive.writestr(args.folder + '/' + name, data)
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
        assert len(archive.namelist()) == len(files)
        for name, expected in hashes.items():
            assert hashlib.sha256(archive.read(args.folder + '/' + name)).hexdigest() == expected
    output.with_suffix('.manifest.json').write_text(json.dumps(hashes, indent=2, ensure_ascii=False), encoding='utf8')
    print(f'Verified {len(files)} files: {output}')

if __name__ == '__main__':
    main()
