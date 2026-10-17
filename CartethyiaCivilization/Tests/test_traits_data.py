"""Data-boundary checks for the dual-form rules; run with unittest discover.

The yield fixtures model only this mod's XML contributions. They do not claim
to replace in-game verification of DLL yield or promotion behavior.
"""

from pathlib import Path
import sqlite3
import unittest
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
BASE = "BUILDING_DUAL_RESONANCE"
CAPITAL = "BUILDING_CARTETHYIA_CAPITAL"
WISDOM = "BUILDING_CARTETHYIA_WISDOM"
YIELDS = ("FOOD", "PRODUCTION", "GOLD", "SCIENCE", "CULTURE", "FAITH")


def read_xml(name):
    return ET.parse(ROOT / "XML" / name).getroot()


class TraitDataTests(unittest.TestCase):
    def setUp(self):
        self.building = read_xml("Cartethyia_Building.xml")
        self.unit = read_xml("Cartethyia_Unit.xml")
        self.db = sqlite3.connect(":memory:")
        self.addCleanup(self.db.close)
        for table in ("Building_YieldChanges", "Building_YieldModifiers"):
            self.db.execute(f"CREATE TABLE {table} (BuildingType TEXT, YieldType TEXT, Yield INTEGER, PRIMARY KEY (BuildingType, YieldType))")
            for row in self.building.findall(f"{table}/Row"):
                self.db.execute(f"INSERT INTO {table} VALUES (?, ?, ?)",
                                (row.findtext("BuildingType"), row.findtext("YieldType"), int(row.findtext("Yield"))))

    def city_yields(self, buildings):
        """Apply declared flat bonuses, then additive city percentage modifiers."""
        result = []
        for kind in YIELDS:
            contributions = []
            for table in ("Building_YieldChanges", "Building_YieldModifiers"):
                placeholders = ",".join("?" for _ in buildings)
                contributions.append(self.db.execute(
                    f"SELECT COALESCE(SUM(Yield), 0) FROM {table} WHERE YieldType = ? AND BuildingType IN ({placeholders})",
                    ("YIELD_" + kind, *buildings)).fetchone()[0])
            flat, percent = contributions
            result.append((20 + flat) * (100 + percent) / 100)
        return result

    def test_ordinary_city_has_three_ten_percent_bonuses(self):
        self.assertEqual(self.city_yields([BASE]), [20, 22, 20, 22, 22, 20])

    def test_capital_bonus_totals_twenty_percent(self):
        self.assertEqual(self.city_yields([BASE, CAPITAL]), [20, 24, 20, 24, 24, 20])

    def test_wisdom_applies_flat_yields_before_additive_percentages(self):
        self.assertEqual(self.city_yields([BASE, WISDOM]), [39, 42, 39, 42, 42, 39])
        self.assertEqual(self.city_yields([BASE, CAPITAL, WISDOM]), [39, 45, 39, 45, 45, 39])
        for table in ("Building_YieldChanges", "Building_YieldModifiers"):
            kinds = {row[0] for row in self.db.execute(f"SELECT DISTINCT YieldType FROM {table}")}
            self.assertTrue(kinds.issubset({"YIELD_" + kind for kind in YIELDS}),
                            "The six-yield ability must not grant tourism or other SP yields")

    def test_bonuses_use_separate_hidden_nonbuildable_noncapturable_classes(self):
        rows = {row.findtext("Type"): row for row in self.building.findall("Buildings/Row")}
        self.assertEqual(set(rows), {BASE, CAPITAL, WISDOM})
        classes = {row.findtext("Type"): row.findtext("DefaultBuilding") for row in self.building.findall("BuildingClasses/Row")}
        self.assertEqual(len({row.findtext("BuildingClass") for row in rows.values()}), 3)
        for name, row in rows.items():
            with self.subTest(building=name):
                self.assertEqual(classes[row.findtext("BuildingClass")], name)
                self.assertEqual(row.findtext("Cost"), "-1")
                self.assertEqual(row.findtext("FaithCost"), "-1")
                self.assertEqual(row.findtext("GreatWorkCount"), "-1")
                self.assertEqual(row.findtext("NeverCapture"), "true")
                self.assertEqual(row.findtext("ConquestProb"), "0")

    def test_new_hero_is_unique_wisdom_form_using_existing_art(self):
        heroes = self.unit.findall("Units/Row")
        self.assertEqual(len(heroes), 1)
        hero = heroes[0]
        self.assertEqual(hero.findtext("Type"), "UNIT_CARTETHYIA")
        self.assertEqual(hero.findtext("Combat"), "6")
        self.assertEqual(hero.findtext("Moves"), "2")
        self.assertEqual(hero.findtext("BaseSightRange"), "2")
        self.assertEqual(hero.findtext("Domain"), "DOMAIN_LAND")
        self.assertEqual(hero.findtext("CombatClass"), "UNITCOMBAT_MELEE")
        self.assertEqual(hero.findtext("NoMaintenance"), "true")
        self.assertEqual(hero.findtext("CannotBeEstablishedCorps"), "true")
        self.assertEqual(hero.findtext("Cost"), "-1")
        self.assertEqual(hero.findtext("FaithCost"), "-1")
        self.assertEqual(hero.findtext("UnitArtInfo"), "ART_DEF_UNIT_CARTETHYIA")
        unit_class = self.unit.find("UnitClasses/Row")
        self.assertEqual(unit_class.findtext("MaxPlayerInstances"), "1")
        self.assertEqual(unit_class.findtext("DefaultUnit"), "UNIT_CARTETHYIA")
        free_promotions = [(row.findtext("UnitType"), row.findtext("PromotionType"))
                           for row in self.unit.findall("Unit_FreePromotions/Row")]
        self.assertEqual(free_promotions, [("UNIT_CARTETHYIA", "PROMOTION_CARTETHYIA_IDENTITY")],
                         "Only permanent identity protection is free; power effects require the power form")

    def test_power_promotions_supply_effects_without_being_level_choices(self):
        path = ROOT / "XML" / "Cartethyia_Promotions.xml"
        self.assertTrue(path.exists(), "Power-form promotion definitions are missing")
        promotions = ET.parse(path).getroot()
        rows = {row.findtext("Type"): row for row in promotions.findall("UnitPromotions/Row")}
        expected = {
            "PROMOTION_CARTETHYIA_IDENTITY": {"CannotBeCaptured": "true"},
            "PROMOTION_CARTETHYIA_WIND": {"MovesChange": "1", "IgnoreTerrainCost": "true"},
            "PROMOTION_CARTETHYIA_AURA": {"NearbyEnemyCombatMod": "-50", "NearbyEnemyCombatRange": "1"},
            "PROMOTION_CARTETHYIA_FREE": {"IgnoreZOC": "true"},
            "PROMOTION_CARTETHYIA_SHIELD": {"RangedDefenseMod": "25"},
            "PROMOTION_CARTETHYIA_UNYIELDING": {"FightWellDamaged": "true"},
        }
        self.assertEqual(set(rows), set(expected))
        for promotion, effects in expected.items():
            with self.subTest(promotion=promotion):
                self.assertEqual(rows[promotion].findtext("CannotBeChosen"), "true")
                for field, value in effects.items():
                    self.assertEqual(rows[promotion].findtext(field), value)
        self.assertEqual(int(self.unit.findtext("Units/Row/Moves")) + int(rows["PROMOTION_CARTETHYIA_WIND"].findtext("MovesChange")), 3)

    def test_gameplay_description_keys_resolve_in_all_three_languages(self):
        path = ROOT / "XML" / "Cartethyia_Promotions.xml"
        self.assertTrue(path.exists(), "Power-form promotion descriptions are missing")
        required = set()
        for root in (self.building, self.unit, ET.parse(path).getroot()):
            for node in root.iter():
                if node.text and node.text.startswith("TXT_KEY_"):
                    required.add(node.text)
        languages = read_xml("Cartethyia_Text.xml")
        for language in ("Language_en_US", "Language_zh_CN", "Language_zh_Hant_HK"):
            with self.subTest(language=language):
                rows = languages.findall(language + "/Row")
                localized = {row.attrib["Tag"]: row.findtext("Text") for row in rows}
                self.assertEqual(len(localized), len(rows), "Duplicate localization tag")
                self.assertEqual(required - localized.keys(), set())
                self.assertTrue(all(localized[key] for key in required))


if __name__ == "__main__":
    unittest.main()
