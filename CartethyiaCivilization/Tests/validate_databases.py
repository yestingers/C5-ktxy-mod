from __future__ import annotations

import argparse
import re
import shutil
import sqlite3
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GAMEPLAY_XML = [
    ROOT / "XML" / "Cartethyia_Art.xml",
    ROOT / "XML" / "Cartethyia_Building.xml",
    ROOT / "XML" / "Cartethyia_Trait.xml",
    ROOT / "XML" / "Cartethyia_Promotions.xml",
    ROOT / "XML" / "Cartethyia_Unit.xml",
    ROOT / "XML" / "Cartethyia_Leader.xml",
    ROOT / "XML" / "Cartethyia_Civilization.xml",
]
TEXT_XML = [ROOT / "XML" / name for name in ("Cartethyia_Text.xml", "Cartethyia_UIText.xml")]
LANGUAGES = ("Language_en_US", "Language_zh_CN", "Language_zh_Hant_HK")


def row_values(row: ET.Element) -> tuple[list[str], list[str | int]]:
    columns = list(row.attrib)
    values = [row.attrib[column] for column in columns]
    columns.extend(child.tag for child in row)
    values.extend((child.text or "") for child in row)
    return columns, [1 if value == "true" else 0 if value == "false" else value for value in values]


def apply_installed_dll_schema(connection: sqlite3.Connection) -> int:
    """Apply only required missing columns, using the installed DLL's actual SQL.

    This is an installed-schema simulation, not a complete SP database rebuild.
    The allowlist names fields we consume; their SQL types/defaults come solely
    from the installed source rather than a synthetic schema in this test.
    """
    mods = Path.home() / "Documents/My Games/Sid Meier's Civilization 5/MODS"
    sources = list(mods.glob("*CIV5MPDLL*"))
    required = (
        ("UnitPromotions", "FightWellDamaged", "PROMOTIONS/NewPromotions_DDL.sql"),
        ("UnitPromotions", "CannotBeCaptured", "PROMOTIONS/NewPromotions_DDL.sql"),
        ("Units", "CannotBeEstablishedCorps", "GLOBAL/TroopsAndCrops.sql"),
    )
    applied = 0
    for table, column, relative in required:
        present = {row[1] for row in connection.execute(f'PRAGMA table_info("{table}")')}
        if column in present:
            continue
        paths = [path for source in sources for path in source.glob("**/DB/" + relative)]
        if len(paths) != 1:
            raise AssertionError(f"Expected one installed DLL source for {relative}, found {paths}")
        sql = paths[0].read_text(encoding="utf-8-sig")
        pattern = (rf"(?im)^\s*ALTER\s+TABLE\s+{table}\s+ADD\s+(?:COLUMN\s+)?"
                   rf"['\"\[]?{column}['\"\]]?\s+[^;]+;")
        statements = re.findall(pattern, sql)
        if len(statements) != 1:
            raise AssertionError(f"Cannot resolve unique installed ALTER for {table}.{column}")
        connection.execute(statements[0])
        applied += 1
    return applied


def owned_xml_rows() -> dict[str, tuple[str, set[str], int]]:
    """Use this mod's exact identity values; never clear base-game rows."""
    owned = {}
    keys = ("Type", "Atlas", "BuildingType", "UnitType", "LeaderType", "CivilizationType")
    for path in GAMEPLAY_XML:
        for table in ET.parse(path).getroot():
            for row in table.findall("Row"):
                key = next((key for key in keys if row.findtext(key) and
                            ("CARTETHYIA" in row.findtext(key) or "DUAL_RESONANCE" in row.findtext(key))), None)
                if key is None:
                    raise AssertionError(f"Cannot safely identify owned rows in {table.tag}")
                previous_key, values, count = owned.get(table.tag, (key, set(), 0))
                if key != previous_key:
                    raise AssertionError(f"Inconsistent ownership key for {table.tag}")
                values.add(row.findtext(key))
                owned[table.tag] = (key, values, count + 1)
    return owned


def clear_mod_rows(connection: sqlite3.Connection) -> None:
    """Clean only this mod's rows in a disposable copy before simulating reload."""
    for table, (key, values, _) in owned_xml_rows().items():
        placeholders = ",".join("?" for _ in values)
        connection.execute(f'DELETE FROM "{table}" WHERE "{key}" IN ({placeholders})', tuple(values))
    for table, key in (
        ("ArtDefine_UnitInfos", "Type"),
        ("ArtDefine_UnitInfoMemberInfos", "UnitInfoType"),
        ("ArtDefine_UnitMemberInfos", "Type"),
        ("ArtDefine_UnitMemberCombats", "UnitMemberType"),
        ("ArtDefine_UnitMemberCombatWeapons", "UnitMemberType"),
        ("ArtDefine_StrategicView", "StrategicViewType"),
    ):
        connection.execute(f'DELETE FROM "{table}" WHERE "{key}" IN (?, ?)',
                           ("ART_DEF_UNIT_CARTETHYIA", "ART_DEF_UNIT_MEMBER_CARTETHYIA"))


def load_xml_rows(connection: sqlite3.Connection, path: Path, replace: bool = True) -> int:
    count = 0
    root = ET.parse(path).getroot()
    for table in root:
        for row in table.findall("Row"):
            columns, values = row_values(row)
            quoted = ", ".join(f'"{column}"' for column in columns)
            placeholders = ", ".join("?" for _ in values)
            verb = "INSERT OR REPLACE" if replace else "INSERT"
            sql = f'{verb} INTO "{table.tag}" ({quoted}) VALUES ({placeholders})'
            connection.execute(sql, values)
            count += 1
    connection.commit()
    return count


def validate_gameplay(source: Path, destination: Path) -> None:
    shutil.copy2(source, destination)
    connection = sqlite3.connect(destination)
    try:
        applied = apply_installed_dll_schema(connection)
        if apply_installed_dll_schema(connection) != 0:
            raise AssertionError("Installed schema extension was not idempotent")
        # The cache may contain a previous version. Repeat a clean load to catch
        # duplicate relationship rows in tables that have no UNIQUE constraint.
        for _ in range(2):
            clear_mod_rows(connection)
            inserted = sum(load_xml_rows(connection, path, replace=False) for path in GAMEPLAY_XML)
            connection.executescript((ROOT / "SQL/Cartethyia_UnitArt.sql").read_text(encoding="utf-8"))
            validate_gameplay_contract(connection)
        print(f"[PASS] gameplay accepted {inserted} XML rows plus unit-art SQL on two clean loads; {applied} installed DLL ALTERs applied")
    finally:
        connection.close()


def validate_gameplay_contract(connection: sqlite3.Connection) -> None:
    for table, (key, values, expected) in owned_xml_rows().items():
        placeholders = ",".join("?" for _ in values)
        actual = connection.execute(f'SELECT COUNT(*) FROM "{table}" WHERE "{key}" IN ({placeholders})', tuple(values)).fetchone()[0]
        if actual != expected:
            raise AssertionError(f"{table}: expected {expected} owned rows, got {actual}")

    bonuses = ("BUILDING_DUAL_RESONANCE", "BUILDING_CARTETHYIA_CAPITAL", "BUILDING_CARTETHYIA_WISDOM")
    six = {"YIELD_FOOD", "YIELD_PRODUCTION", "YIELD_GOLD", "YIELD_SCIENCE", "YIELD_CULTURE", "YIELD_FAITH"}
    national = {"YIELD_PRODUCTION", "YIELD_SCIENCE", "YIELD_CULTURE"}
    for table in ("Building_YieldChanges", "Building_YieldModifiers"):
        for building in bonuses:
            rows = connection.execute(f'SELECT b.YieldType, b.Yield, y.Type FROM "{table}" b LEFT JOIN Yields y ON y.Type=b.YieldType WHERE b.BuildingType=?', (building,)).fetchall()
            expected = ({kind: 10 for kind in six} if building == bonuses[2] else {}) if table == "Building_YieldChanges" else {kind: 30 if building == bonuses[2] else 10 for kind in (six if building == bonuses[2] else national)}
            if {kind: value for kind, value, _ in rows} != expected or len(rows) != len(expected) or any(resolved is None for _, _, resolved in rows):
                raise AssertionError(f"Invalid or unresolved six-yield bonuses: {table}.{building}: {rows}")
            flags = connection.execute("SELECT Cost, FaithCost, GreatWorkCount, NeverCapture, NukeImmune, ConquestProb FROM Buildings WHERE Type=?", (building,)).fetchone()
            if flags != (-1, -1, -1, 1, 1, 0):
                raise AssertionError(f"Invalid hidden building flags: {building}: {flags}")

    hero = connection.execute("SELECT Combat, Moves, BaseSightRange, NoMaintenance, CannotBeEstablishedCorps, MilitaryProduction, ShowInPedia FROM Units WHERE Type='UNIT_CARTETHYIA'").fetchone()
    if hero != (6, 2, 2, 1, 1, 0, 0):
        raise AssertionError(f"Initial wisdom form or SQLite boolean conversion is invalid: {hero}")
    if connection.execute("SELECT MaxPlayerInstances FROM UnitClasses WHERE Type='UNITCLASS_CARTETHYIA'").fetchone() != (1,):
        raise AssertionError("Hero class must allow one instance per player")
    free = connection.execute("SELECT PromotionType FROM Unit_FreePromotions WHERE UnitType='UNIT_CARTETHYIA'").fetchall()
    if free != [("PROMOTION_CARTETHYIA_IDENTITY",)]:
        raise AssertionError(f"Unexpected permanent hero promotions: {free}")
    effects = {
        "IDENTITY": {"CannotBeCaptured": 1}, "WIND": {"MovesChange": 1, "IgnoreTerrainCost": 1},
        "AURA": {"NearbyEnemyCombatMod": -50, "NearbyEnemyCombatRange": 1}, "FREE": {"IgnoreZOC": 1},
        "SHIELD": {"RangedDefenseMod": 25}, "UNYIELDING": {"FightWellDamaged": 1},
    }
    for suffix, fields in effects.items():
        columns = ", ".join(["CannotBeChosen", *fields])
        actual = connection.execute(f"SELECT {columns} FROM UnitPromotions WHERE Type=?", ("PROMOTION_CARTETHYIA_" + suffix,)).fetchone()
        if actual != (1, *fields.values()):
            raise AssertionError(f"Invalid hero promotion: {suffix}: {actual}")
    art = connection.execute("""SELECT m.NumMembers, a.Model FROM Units u
        JOIN ArtDefine_UnitInfoMemberInfos m ON m.UnitInfoType=u.UnitArtInfo
        JOIN ArtDefine_UnitMemberInfos a ON a.Type=m.UnitMemberInfoType
        WHERE u.Type='UNIT_CARTETHYIA'""").fetchall()
    if art != [(1, "Cartethyia_Unit.fxsxml")]:
        raise AssertionError(f"Hero unit-art SQL did not resolve a single character: {art}")


def validate_localization(source: Path, destination: Path) -> None:
    shutil.copy2(source, destination)
    connection = sqlite3.connect(destination)
    try:
        expected = {}
        for table in LANGUAGES:
            rows = [row for path in TEXT_XML for row in ET.parse(path).findall(f"./{table}/Row")]
            expected[table] = {row.attrib["Tag"]: row.findtext("Text") for row in rows}
            if len(expected[table]) != len(rows) or not rows:
                raise AssertionError(f"Duplicate or missing localization tags in {table}")
        if any(set(expected[table]) != set(expected[LANGUAGES[0]]) for table in LANGUAGES):
            raise AssertionError("The three languages do not provide the same gameplay and UI tags")
        for _ in range(2):
            for table, rows in expected.items():
                placeholders = ",".join("?" for _ in rows)
                connection.execute(f'DELETE FROM "{table}" WHERE Tag IN ({placeholders})', tuple(rows))
            inserted = sum(load_xml_rows(connection, path, replace=False) for path in TEXT_XML)
            for table, rows in expected.items():
                placeholders = ",".join("?" for _ in rows)
                actual = connection.execute(f'SELECT Tag, Text FROM "{table}" WHERE Tag IN ({placeholders})', tuple(rows)).fetchall()
                if len(actual) != len(rows) or dict(actual) != rows:
                    raise AssertionError(f"{table} did not preserve every gameplay and UI text row")
        print(f"[PASS] localization accepted {inserted} gameplay and UI XML rows in three languages on two clean loads")
    finally:
        connection.close()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("gameplay_db", type=Path)
    parser.add_argument("localization_db", type=Path)
    args = parser.parse_args()

    with tempfile.TemporaryDirectory(prefix="cartethyia_schema_") as temp:
        temp_path = Path(temp)
        validate_gameplay(args.gameplay_db, temp_path / "Civ5DebugDatabase.db")
        validate_localization(args.localization_db, temp_path / "Localization-Merged.db")

    print("Installed-schema simulation completed successfully; this is not a full SP load or in-game test.")


if __name__ == "__main__":
    main()
