-- Keep the stock Longswordsman combat/animation rules; replace only this unit's mesh.
INSERT INTO ArtDefine_UnitInfos (Type, DamageStates, Formation)
SELECT 'ART_DEF_UNIT_CARTETHYIA', DamageStates, Formation
FROM ArtDefine_UnitInfos WHERE Type = 'ART_DEF_UNIT_LONGSWORDSMAN';

INSERT INTO ArtDefine_UnitInfoMemberInfos (UnitInfoType, UnitMemberInfoType, NumMembers)
VALUES ('ART_DEF_UNIT_CARTETHYIA', 'ART_DEF_UNIT_MEMBER_CARTETHYIA', 1);

INSERT INTO ArtDefine_UnitMemberInfos
    (Type, Scale, ZOffset, Domain, Model, MaterialTypeTag, MaterialTypeSoundOverrideTag)
SELECT 'ART_DEF_UNIT_MEMBER_CARTETHYIA', Scale * 1.5, ZOffset, Domain,
    'Cartethyia_Unit.fxsxml', MaterialTypeTag, MaterialTypeSoundOverrideTag
FROM ArtDefine_UnitMemberInfos WHERE Type = 'ART_DEF_UNIT_MEMBER_LONGSWORDSMAN';

INSERT INTO ArtDefine_UnitMemberCombats
    (UnitMemberType, EnableActions, ShortMoveRadius, ShortMoveRate, TargetHeight, HasRefaceAfterCombat)
SELECT 'ART_DEF_UNIT_MEMBER_CARTETHYIA', EnableActions, ShortMoveRadius, ShortMoveRate, TargetHeight, HasRefaceAfterCombat
FROM ArtDefine_UnitMemberCombats WHERE UnitMemberType = 'ART_DEF_UNIT_MEMBER_LONGSWORDSMAN';

INSERT INTO ArtDefine_UnitMemberCombatWeapons
    (UnitMemberType, "Index", SubIndex, VisKillStrengthMin, VisKillStrengthMax,
     WeaponTypeTag, WeaponTypeSoundOverrideTag, MissTargetSlopRadius)
SELECT 'ART_DEF_UNIT_MEMBER_CARTETHYIA', "Index", SubIndex, VisKillStrengthMin, VisKillStrengthMax,
     WeaponTypeTag, WeaponTypeSoundOverrideTag, MissTargetSlopRadius
FROM ArtDefine_UnitMemberCombatWeapons WHERE UnitMemberType = 'ART_DEF_UNIT_MEMBER_LONGSWORDSMAN';

INSERT INTO ArtDefine_StrategicView (StrategicViewType, TileType, Asset)
SELECT 'ART_DEF_UNIT_CARTETHYIA', TileType, Asset
FROM ArtDefine_StrategicView WHERE StrategicViewType = 'ART_DEF_UNIT_LONGSWORDSMAN';
