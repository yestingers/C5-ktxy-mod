--
-- 文件名: KatishaUnitForms.sql
-- 作用: 在数据库中定义卡提希娅形态切换相关数据
-- 用途: 定义单位切换形态时的语言字符串和平衡设定
--

-- 重新定义大卡单位的描述，强调动态战斗力
UPDATE Language_en_US SET Text='大卡·战争形态 - 拥有"终焉洪流"技能和动态战斗力' WHERE Tag='TXT_KEY_UNIT_KATISHA_BIG_DESC';
UPDATE Language_zh_CN SET Text='大卡·战争形态 - 拥有"终焉洪流"技能和动态战斗力' WHERE Tag='TXT_KEY_UNIT_KATISHA_BIG_DESC';

UPDATE Language_en_US SET Text='卡提希娅的战争形态，战斗力随您文明的人口和城市数量动态变化，配备毁灭性的终焉洪流技能' WHERE Tag='TXT_KEY_UNIT_KATISHA_BIG_PEDIA';
UPDATE Language_zh_CN SET Text='卡提希娅的战争形态，战斗力随您文明的人口和城市数量动态变化，配备毁灭性的终焉洪流技能' WHERE Tag='TXT_KEY_UNIT_KATISHA_BIG_PEDIA';

UPDATE Language_en_US SET Text='切换到战争形态使卡提希娅成为强大的战斗单位，战斗力根据文明发展程度动态变化，可使用大范围破坏技能' WHERE Tag='TXT_KEY_UNIT_KATISHA_BIG_STRATEGY';
UPDATE Language_zh_CN SET Text='切换到战争形态使卡提希娅成为强大的战斗单位，战斗力根据文明发展程度动态变化，可使用大范围破坏技能' WHERE Tag='TXT_KEY_UNIT_KATISHA_BIG_STRATEGY';

UPDATE Language_en_US SET Text='战争形态 - 动态战斗单位，战斗力随人口(0.4/人)和城市数量(2/城)增长，最高可达135，可释放终焉洪流技能' WHERE Tag='TXT_KEY_UNIT_KATISHA_BIG_HELP';
UPDATE Language_zh_CN SET Text='战争形态 - 动态战斗单位，战斗力随人口(0.4/人)和城市数量(2/城)增长，最高可达135，可释放终焉洪流技能' WHERE Tag='TXT_KEY_UNIT_KATISHA_BIG_HELP';

-- 添加动态战斗力的描述
INSERT OR REPLACE INTO Language_en_US (Tag, Text) VALUES
    ('TXT_KEY_ABILITY_KATISHA_DYNAMIC_COMBAT', '动态战斗力'),
    ('TXT_KEY_ABILITY_KATISHA_DYNAMIC_COMBAT_HELP', '战斗力 = 35 + 0.4 × 总人口 + 2 × 城市数量，每3回合更新一次，最高不超过135');

INSERT OR REPLACE INTO Language_zh_CN (Tag, Text) VALUES
    ('TXT_KEY_ABILITY_KATISHA_DYNAMIC_COMBAT', '动态战斗力'),
    ('TXT_KEY_ABILITY_KATISHA_DYNAMIC_COMBAT_HELP', '战斗力 = 35 + 0.4 × 总人口 + 2 × 城市数量，每3回合更新一次，最高不超过135');