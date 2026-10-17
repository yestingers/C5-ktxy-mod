"""Offline checks for v1 presentation contracts; live layout/audio still need Civ5."""
from pathlib import Path
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
GAME = Path("D:/steam/steamapps/common/Sid Meier's Civilization V")


class PresentationTests(unittest.TestCase):
    def setUp(self):
        self.civ = ET.parse(ROOT / "XML/Cartethyia_Civilization.xml").find("Civilizations/Row")
        self.unit = ET.parse(ROOT / "XML/Cartethyia_Unit.xml").find("Units/Row")
        self.texts = {
            language.tag: {row.get("Tag"): row.findtext("Text") for row in language}
            for language in ET.parse(ROOT / "XML/Cartethyia_Text.xml").getroot()
        }

    def test_setup_names_do_not_repeat_leader_as_civilization(self):
        for language, nation, leader in (
            ("Language_en_US", "Nation of Enlightenment", "Cartethyia"),
            ("Language_zh_CN", "启明之国", "卡提希娅"),
            ("Language_zh_Hant_HK", "啟明之國", "卡提希婭"),
        ):
            with self.subTest(language=language):
                tags = self.texts[language]
                self.assertEqual(tags[self.civ.findtext("ShortDescription")], nation)
                self.assertEqual(tags[self.civ.findtext("Description")], nation)
                self.assertEqual(tags["TXT_KEY_LEADER_CARTETHYIA"], leader)
                self.assertNotIn(nation, tags["TXT_KEY_TRAIT_DUAL_RESONANCE_SHORT"])

    def test_setup_summary_has_three_short_lines_and_separate_dawn_quote(self):
        # SP's card is 128px tall; 675px wrap, TwCenMT18, tight leading.
        # These conservative character budgets catch accidental full-rule paste.
        for language, tags in self.texts.items():
            with self.subTest(language=language):
                lines = tags["TXT_KEY_TRAIT_DUAL_RESONANCE"].split("[NEWLINE]")
                self.assertEqual(len(lines), 3)
                self.assertTrue(all(len(line) <= (85 if language == "Language_en_US" else 38)
                                    for line in lines), lines)
                self.assertLessEqual(len(tags["TXT_KEY_TRAIT_DUAL_RESONANCE_SHORT"]),
                                     24 if language == "Language_en_US" else 10)
                self.assertNotIn("[NEWLINE]", tags["TXT_KEY_CIV_CARTETHYIA_DAWN"])

    def test_lifecycle_help_matches_start_and_ten_turn_return(self):
        for language, start, returning, obsolete in (
            ("Language_en_US", "game start", "10 turns", "cannot be replaced after death"),
            ("Language_zh_CN", "开局", "10回合", "阵亡后不再生成"),
            ("Language_zh_Hant_HK", "開局", "10回合", "陣亡後不再生成"),
        ):
            with self.subTest(language=language):
                tags = self.texts[language]
                help_text = tags["TXT_KEY_UNIT_CARTETHYIA_HELP"]
                self.assertIn(start, help_text)
                self.assertIn(returning, help_text)
                self.assertNotIn(obsolete, " ".join(tags.values()))
                self.assertNotIn("V0.3.0 Alpha", " ".join(tags.values()))
                # The concise card must not delete the detailed skill numbers.
                detail = tags["TXT_KEY_UNIT_CARTETHYIA_PEDIA"]
                for value in ("70%", "60%", "50%", "30", "400", "80", "20", "5", "10"):
                    self.assertIn(value, detail)

    def test_unit_portrait_resolves_to_person_not_civilization_emblem(self):
        self.assertEqual(self.unit.findtext("IconAtlas"), "CARTETHYIA_LEADER_ATLAS")
        self.assertNotEqual(self.unit.findtext("IconAtlas"), self.civ.findtext("IconAtlas"))
        self.assertEqual(self.unit.findtext("UnitFlagAtlas"), "CARTETHYIA_UNIT_FLAG_ATLAS")

    def test_action_addin_registers_three_distinct_portraits(self):
        # Execute the shipped addin. Only the unavailable engine event boundary
        # is captured; assertions inspect the actual emitted registration data.
        script = '''
local actions = {}
LuaEvents = {UnitPanelActionAddin = function(action) actions[#actions + 1] = action end}
local event = {Add = function() end}
Events = {ActivePlayerTurnEnd = event, ActivePlayerTurnStart = event, GameplaySetActivePlayer = event}
dofile("UI/Cartethyia_Actions.lua")
for _, action in ipairs(actions) do
    print(action.Name .. "|" .. action.IconAtlas .. "|" .. action.PortraitIndex)
end
'''
        with tempfile.TemporaryDirectory(prefix="cartethyia_ui_") as temporary:
            path = Path(temporary) / "action_icons.lua"
            path.write_text(script, encoding="utf-8")
            result = subprocess.run([str(ROOT / "Tests/native_lua_host.exe"), str(path)],
                                    cwd=ROOT, capture_output=True, text=True, check=True)
        self.assertEqual(result.stdout.splitlines(), [
            "CARTETHYIA_SWITCH|CARTETHYIA_ACTION_ATLAS|0",
            "CARTETHYIA_WISDOM|CARTETHYIA_ACTION_ATLAS|1",
            "CARTETHYIA_POWER|CARTETHYIA_ACTION_ATLAS|2",
        ])

    def test_native_music_fields_resolve_without_packaged_audio(self):
        self.assertEqual(self.civ.findtext("SoundtrackTag"), "England")
        script_id = self.civ.findtext("DawnOfManAudio")
        self.assertEqual(script_id, "AS2D_LEADER_MUSIC_ELIZABETH_PEACE")
        scripts = ET.parse(GAME / "Assets/Sounds/XML/ElizabethAudio2DScripts.xml")
        script = next(row for row in scripts.findall("Script2DSounds/Script2DSound")
                      if row.findtext("ScriptID") == script_id)
        self.assertEqual(script.findtext("SoundType"), "GAME_MUSIC")
        self.assertEqual(script.findtext("bIsMusic"), "True")
        sounds = ET.parse(GAME / "Assets/Sounds/XML/ElizabethAudioDefines.xml")
        sound = next(row for row in sounds.findall("SoundDatas/SoundData")
                     if row.findtext("SoundID") == script.findtext("SoundID"))
        self.assertTrue((GAME / "Assets/Sounds/Streamed/Music/Leader Music" /
                         (sound.findtext("Filename") + ".ogg")).is_file())


if __name__ == "__main__":
    unittest.main()
