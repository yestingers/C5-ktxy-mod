from __future__ import annotations

import struct
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
MODINFO = ROOT / "Cartethyia Civilization (v 1).modinfo"
XML_DIR = ROOT / "XML"
ART_DIR = ROOT / "Art" / "Atlases"


def check(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def parse_xml_files() -> dict[Path, ET.Element]:
    files = [MODINFO, *sorted(XML_DIR.glob("*.xml"))]
    return {path: ET.parse(path).getroot() for path in files}


def dds_size(path: Path) -> tuple[int, int]:
    header = path.read_bytes()[:128]
    check(header[:4] == b"DDS ", f"{path.name}: invalid DDS magic")
    height, width = struct.unpack_from("<II", header, 12)
    return width, height


def test_modinfo(roots: dict[Path, ET.Element]) -> None:
    root = roots[MODINFO]
    check(root.attrib.get("version") == "4", "modinfo version must be 4")
    check(root.findtext("./Properties/Name") == "卡提希娅文明 V0.2", "wrong mod name")

    file_rows = {row.text: row.attrib.get("import") for row in root.findall("./Files/File")}
    action_rows = [row.text for row in root.findall("./Actions/OnModActivated/UpdateDatabase")]
    required_xml = [
        "XML/Cartethyia_Art.xml",
        "XML/Cartethyia_Text.xml",
        "XML/Cartethyia_Building.xml",
        "XML/Cartethyia_Trait.xml",
        "XML/Cartethyia_Unit.xml",
        "XML/Cartethyia_Leader.xml",
        "XML/Cartethyia_Civilization.xml",
        "SQL/Cartethyia_UnitArt.sql",
    ]
    check(action_rows == required_xml, "database update order is incorrect")

    for relative, import_value in file_rows.items():
        check((ROOT / relative).is_file(), f"modinfo references missing file: {relative}")
        if relative.endswith(".dds") or relative.endswith(".lua"):
            check(import_value == "1", f"{relative} must import into VFS")

    actual_dds = {path.name for path in ART_DIR.glob("*.dds")}
    listed_dds = {Path(path).name for path in file_rows if path.startswith("Art/Atlases/") and path.endswith(".dds")}
    check(actual_dds == listed_dds, "modinfo DDS list does not match generated DDS files")


def test_localization(roots: dict[Path, ET.Element]) -> None:
    root = roots[XML_DIR / "Cartethyia_Text.xml"]
    tables = ["Language_en_US", "Language_zh_CN", "Language_zh_Hant_HK"]
    tag_sets: list[set[str]] = []

    for table_name in tables:
        rows = root.findall(f"./{table_name}/Row")
        tags = [row.attrib["Tag"] for row in rows]
        check(len(tags) == len(set(tags)), f"duplicate Tag in {table_name}")
        check(all((row.findtext("Text") or "").strip() for row in rows), f"empty text in {table_name}")
        tag_sets.append(set(tags))

    check(tag_sets[0] == tag_sets[1] == tag_sets[2], "language tables have different Tag sets")
    check(len(tag_sets[0]) == 40, "unexpected localization Tag count")


def test_art(roots: dict[Path, ET.Element]) -> None:
    root = roots[XML_DIR / "Cartethyia_Art.xml"]
    registered_atlases: dict[str, set[int]] = {}

    for row in root.findall("./IconTextureAtlases/Row"):
        atlas = row.findtext("Atlas")
        icon_size = int(row.findtext("IconSize", "0"))
        filename = row.findtext("Filename")
        path = ART_DIR / filename
        check(path.is_file(), f"missing atlas file: {filename}")
        columns = int(row.findtext("IconsPerRow", "1"))
        rows = int(row.findtext("IconsPerColumn", "1"))
        check(columns > 0 and rows > 0, f"{filename}: invalid atlas grid")
        check(dds_size(path) == (icon_size * columns, icon_size * rows), f"{filename}: wrong dimensions")
        registered_atlases.setdefault(atlas, set()).add(icon_size)

    expected = {
        "CARTETHYIA_LEADER_ATLAS": {256, 128, 80, 64, 45, 32},
        "CARTETHYIA_ICON_ATLAS": {256, 128, 80, 64, 45, 32},
        "CARTETHYIA_ALPHA_ATLAS": {256, 128, 80, 64, 48, 32, 24, 16},
        "CARTETHYIA_UNIT_FLAG_ATLAS": {32},
    }
    version = int(ET.parse(ROOT / "Cartethyia Civilization (v 1).modinfo").getroot().get("version", "0"))
    if version >= 6:
        expected["CARTETHYIA_ACTION_ATLAS"] = {64,45,32}
    check(registered_atlases == expected, "atlas size registration is incomplete")
    check(dds_size(ART_DIR / "Cartethyia_DOM.dds") == (1024, 768), "wrong DOM dimensions")
    check(dds_size(ART_DIR / "Cartethyia_Map.dds") == ((360,412) if version >= 6 else (512,512)), "wrong map dimensions")

    for filename in ("Cartethyia_Alpha_256.dds", "Cartethyia_UnitFlag_32.dds"):
        image = Image.open(ART_DIR / filename).convert("RGBA")
        low, high = image.getchannel("A").getextrema()
        check(low < high, f"{filename}: alpha channel is flat")

    atlas_names = set(registered_atlases)
    for filename in ("Cartethyia_Building.xml", "Cartethyia_Civilization.xml", "Cartethyia_Leader.xml", "Cartethyia_Unit.xml"):
        root = roots[XML_DIR / filename]
        for tag in ("IconAtlas", "AlphaIconAtlas", "UnitFlagAtlas"):
            for node in root.findall(f".//{tag}"):
                check(node.text in atlas_names, f"{filename}: unknown {tag} {node.text}")


def test_gameplay_data(roots: dict[Path, ET.Element]) -> None:
    unit_root = roots[XML_DIR / "Cartethyia_Unit.xml"]
    unit = unit_root.find("./Units/Row")
    expected = {
        "Combat": "30",
        "Moves": "2",
        "BaseSightRange": "2",
        "Cost": "-1",
        "FaithCost": "-1",
        "NoMaintenance": "true",
    }
    for key, value in expected.items():
        check(unit.findtext(key) == value, f"unit {key} must be {value}")

    building_root = roots[XML_DIR / "Cartethyia_Building.xml"]
    yields = {
        (row.findtext("YieldType"), int(row.findtext("Yield", "0")))
        for row in building_root.findall("./Building_YieldModifiers/Row")
    }
    check(yields == {("YIELD_SCIENCE", 5), ("YIELD_PRODUCTION", 5)}, "trait yields are incorrect")


def test_lua_contract() -> None:
    lua = (ROOT / "Lua" / "Cartethyia_StartUnit.lua").read_text(encoding="utf-8")
    required = [
        'include("SaveUtils")',
        'MOD_SAVE_KEY = "CARTETHYIA_V02"',
        'GRANTED_KEY = "START_UNIT_GRANTED"',
        "save(player, GRANTED_KEY, true, MOD_SAVE_KEY)",
        "GameEvents.PlayerCityFounded.Add(OnCityFounded)",
        "GameEvents.PlayerDoTurn.Add(OnPlayerTurn)",
        "Events.SequenceGameInitComplete.Add(InitializeAllPlayers)",
        "city:SetNumRealBuilding(buildingID, targetCount)",
    ]
    for fragment in required:
        check(fragment in lua, f"Lua stability contract missing: {fragment}")


def test_state_model() -> None:
    def run_turn(state: dict[str, object]) -> None:
        if not state["is_cartethyia"] or not state["alive"]:
            return
        state["city_buildings"] = [1 for _ in state["city_buildings"]]
        if state["capital"] and not state["granted"]:
            state["unit_alive"] = True
            state["granted"] = True

    state = {
        "is_cartethyia": True,
        "alive": True,
        "capital": True,
        "granted": False,
        "unit_alive": False,
        "city_buildings": [0],
    }
    run_turn(state)
    check(state["granted"] and state["unit_alive"], "fresh game did not grant the unit")
    check(state["city_buildings"] == [1], "capital did not receive trait building")

    state["unit_alive"] = False
    run_turn(state)
    check(not state["unit_alive"], "dead unit respawned")

    state["city_buildings"].append(0)
    run_turn(state)
    check(state["city_buildings"] == [1, 1], "new city did not receive trait building")

    loaded = dict(state)
    run_turn(loaded)
    check(not loaded["unit_alive"], "loading a save respawned the dead unit")


def main() -> int:
    # Keep the historical V0.2 checks for snapshot use; current releases have
    # a dedicated executable-Lua and data suite instead of the old Python model.
    if int(ET.parse(MODINFO).getroot().get("version", "0")) >= 5:
        import subprocess
        return subprocess.run([sys.executable, str(ROOT / "Tests" / "validate_all.py")], cwd=ROOT).returncode
    try:
        roots = parse_xml_files()
        print("[PASS] XML parse")
        for name, test in (
            ("modinfo", lambda: test_modinfo(roots)),
            ("localization", lambda: test_localization(roots)),
            ("art assets", lambda: test_art(roots)),
            ("gameplay data", lambda: test_gameplay_data(roots)),
            ("Lua contract", test_lua_contract),
            ("save/new-city/death model", test_state_model),
        ):
            test()
            print(f"[PASS] {name}")
    except (AssertionError, ET.ParseError, OSError, ValueError) as error:
        print(f"[FAIL] {error}")
        return 1

    print("V0.2 offline validation completed successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
