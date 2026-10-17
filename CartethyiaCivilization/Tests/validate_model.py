"""Integration checks for the generated game model, not a Python animation mock."""
import json
import hashlib
import unittest
import sqlite3
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]

class ModelIntegrationTests(unittest.TestCase):
    def test_authored_animations_are_registered_and_match_granny_readback(self):
        game=ROOT/'Art/Models/Game'
        report=json.loads((game/'Animations.audit.json').read_text())
        manifest=ET.parse(ROOT/'Cartethyia Civilization (v 1).modinfo')
        files={r.text:r.get('import') for r in manifest.findall('./Files/File')}
        entries=ET.parse(game/'Cartethyia_Unit.fxsxml').findall('Animation')
        self.assertEqual({a.get('file') for a in entries},{r['file'] for r in report})
        for item in report:
            asset=game/'Animations'/item['file']
            self.assertEqual(hashlib.sha256(asset.read_bytes()).hexdigest(),item['sha256'])
            self.assertEqual(hashlib.sha256((game/'Cartethyia_Unit.gr2').read_bytes()).hexdigest(),item['model_sha256'])
            self.assertEqual(files.get('Art/Models/Game/Animations/'+asset.name),'1')
            self.assertEqual(item['bones'],27)
            self.assertLess(item['max_matrix_error'],.02)

    def test_database_resolves_single_character_and_combat_rules(self):
        from validate_databases import apply_installed_dll_schema, clear_mod_rows, load_xml_rows, GAMEPLAY_XML
        path=Path.home()/"Documents/My Games/Sid Meier's Civilization 5/cache/Civ5DebugDatabase.db"
        self.assertTrue(path.is_file(), 'Requires the installed game database for schema validation')
        with sqlite3.connect(path.as_uri()+'?mode=ro',uri=True) as source, sqlite3.connect(':memory:') as db:
            source.backup(db)
            # Only the mod's three consumed DLL columns are applied from the
            # installed SQL. This does not simulate a complete SP load.
            apply_installed_dll_schema(db)
            self.assertEqual(apply_installed_dll_schema(db), 0)
            clear_mod_rows(db)
            for xml in GAMEPLAY_XML:load_xml_rows(db,xml)
            db.executescript((ROOT/'SQL/Cartethyia_UnitArt.sql').read_text(encoding='utf8'))
            rows=db.execute('''SELECT m.NumMembers, a.Model, c.EnableActions
                FROM Units u JOIN ArtDefine_UnitInfos i ON i.Type=u.UnitArtInfo
                JOIN ArtDefine_UnitInfoMemberInfos m ON m.UnitInfoType=i.Type
                JOIN ArtDefine_UnitMemberInfos a ON a.Type=m.UnitMemberInfoType
                JOIN ArtDefine_UnitMemberCombats c ON c.UnitMemberType=a.Type
                WHERE u.Type='UNIT_CARTETHYIA' ''').fetchall()
            self.assertEqual(len(rows),1)
            count,model,actions=rows[0];self.assertEqual(count,1);self.assertEqual(model,'Cartethyia_Unit.fxsxml')
            self.assertTrue({'Idle','Run','Attack','Death'} <= set(actions.split()))
            self.assertEqual(db.execute("SELECT COUNT(*) FROM ArtDefine_UnitMemberCombatWeapons WHERE UnitMemberType='ART_DEF_UNIT_MEMBER_CARTETHYIA'").fetchone()[0],2)

    def test_granny_readback_has_material_and_compatible_rig(self):
        path = ROOT / 'Art/Models/Game/Cartethyia_Unit.audit.json'
        self.assertTrue(path.is_file(), 'Game model has not been built and read back through Granny')
        report = json.loads(path.read_text(encoding='utf8'))
        self.assertEqual(report['model_sha256'],hashlib.sha256((path.parent/'Cartethyia_Unit.gr2').read_bytes()).hexdigest())
        self.assertGreater(report['vertices'], 1000)
        self.assertGreater(report['triangles'], 1000)
        self.assertTrue(report['materials'])
        self.assertEqual(report['mesh_materials'], report['materials'])
        self.assertEqual(report['bone_names'], report['reference_bone_names'])
        self.assertFalse(report['unbound_bones'])
        self.assertEqual(report['invalid_weight_count'], 0)
        for texture in report['textures']:
            self.assertTrue((path.parent / texture).is_file(), texture)

    def test_game_can_resolve_model_and_animation_entries(self):
        unit = ET.parse(ROOT/'XML/Cartethyia_Unit.xml').findtext('./Units/Row/UnitArtInfo')
        self.assertNotEqual(unit, 'ART_DEF_UNIT_LONGSWORDSMAN', 'Unit still uses stock mesh')
        manifest = ET.parse(ROOT/'Cartethyia Civilization (v 1).modinfo')
        files = {r.text:r.get('import') for r in manifest.findall('./Files/File')}
        fxs = ROOT/'Art/Models/Game/Cartethyia_Unit.fxsxml'
        self.assertTrue(fxs.is_file())
        asset = ET.parse(fxs)
        for mesh in asset.findall('Mesh'):
            key='Art/Models/Game/'+mesh.get('file')
            self.assertEqual(files.get(key),'1',key)
            self.assertTrue((ROOT/key).is_file())
        codes={code.strip() for a in asset.findall('Animation') for code in a.get('ec','').split(',')}
        self.assertTrue({'1000','1400','1100','2100','1160','1200'} <= codes)
        for texture in asset.findall('Texture'):
            if texture.get('file').startswith('Cartethyia_'):
                self.assertEqual(files.get('Art/Models/Game/'+texture.get('file')),'1')

if __name__ == '__main__':
    unittest.main()
