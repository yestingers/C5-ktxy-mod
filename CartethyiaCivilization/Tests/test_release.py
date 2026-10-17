"""Check runnable manifest, localization coverage and installed DLL schema loading."""
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path
from validate_v02 import parse_xml_files, test_art

ROOT = Path(__file__).resolve().parents[1]

class ReleaseTests(unittest.TestCase):
    def test_manifest_registers_runtime_once_and_all_files_resolve(self):
        root=ET.parse(ROOT/'Cartethyia Civilization (v 1).modinfo').getroot()
        self.assertEqual(root.get('version'),'6')
        self.assertEqual(root.findtext('Properties/Name'),'卡提希娅—启明之国 v1.0')
        files={r.text:r.get('import') for r in root.findall('Files/File')}
        self.assertEqual(len(files),len(root.findall('Files/File')))
        for name,flag in files.items():
            self.assertTrue((ROOT/name).is_file(),name)
            if name.endswith(('.lua','.dds','.gr2','.fxsxml')) or name.startswith('UI/'):
                self.assertEqual(flag,'1',name)
        for name in ['Lua/Cartethyia_Rules.lua','XML/Cartethyia_Promotions.xml','XML/Cartethyia_UIText.xml','SQL/Cartethyia_Events.sql']:
            self.assertIn(name,files)
        actions=[r.text for r in root.findall('Actions/OnModActivated/UpdateDatabase')]
        self.assertIn('XML/Cartethyia_UIText.xml',actions)
        self.assertIn('SQL/Cartethyia_Events.sql',actions)
        self.assertLess(actions.index('XML/Cartethyia_Promotions.xml'),actions.index('XML/Cartethyia_Unit.xml'))
        entries=[(e.get('type'),e.get('file')) for e in root.findall('EntryPoints/EntryPoint')]
        self.assertEqual(entries.count(('InGameUIAddin','Lua/Cartethyia_StartUnit.lua')),1)
        self.assertIn(('UnitPanelAddin','UI/Cartethyia_Actions.lua'),entries)
        self.assertIn(('InGameUIAddin','UI/Cartethyia_Panel.xml'),entries)

    def test_localization_resolves_every_custom_key_and_has_language_parity(self):
        texts={lang:{} for lang in ('Language_en_US','Language_zh_CN','Language_zh_Hant_HK')}
        for name in ('Cartethyia_Text.xml','Cartethyia_UIText.xml'):
            root=ET.parse(ROOT/'XML'/name)
            for lang,tags in texts.items():
                for row in root.findall(f'./{lang}/Row'):
                    tag=row.get('Tag');self.assertNotIn(tag,tags)
                    tags[tag]=row.findtext('Text');self.assertTrue(tags[tag].strip())
        en=texts['Language_en_US']
        for tags in texts.values():self.assertEqual(set(tags),set(en))
        for path in list((ROOT/'XML').glob('*.xml'))+list((ROOT/'UI').glob('*.xml')):
            if path.name.endswith('Text.xml'):continue
            for element in ET.parse(path).iter():
                values=list(element.attrib.values())+[element.text or '']
                for value in values:
                    if value.startswith('TXT_KEY_') and 'CARTETHYIA' in value or value.startswith('TXT_KEY_TRAIT_DUAL_RESONANCE') or value.startswith('TXT_KEY_BUILDING_DUAL_RESONANCE'):
                        self.assertIn(value,en,str(path))

    def test_art_atlases_remain_valid(self):
        test_art(parse_xml_files())

if __name__=='__main__':unittest.main()
