--
-- 文件名: Katisha.sql
-- 作用: 在数据库中创建卡提希娅文明的相关数据
-- 用途: 游戏启动时自动执行，注册新的文明、领袖、单位
--

-- 删除旧数据防止重复插入
DELETE FROM Language_en_US WHERE Tag LIKE 'TXT_KEY_%KATISHA%';

-- 插入文明字符串定义
INSERT INTO Language_en_US
    (Tag, Text)
VALUES
    ('TXT_KEY_CIV_KATISHA_DESC', '鸣潮-卡提希娅'),
    ('TXT_KEY_CIV_KATISHA_SHORT_DESC', '卡提希娅文明'),
    ('TXT_KEY_CIV_KATISHA_ADJECTIVE', '卡提希娅的'),
    ('TXT_KEY_CIV_KATISHA_PEDIA', '鸣潮世界中的卡提希娅文明'),

    -- 领袖字符串定义
    ('TXT_KEY_LEADER_KATISHA_DESC', '卡提希娅'),
    ('TXT_KEY_LEADER_KATISHA_PEDIA', '卡提希娅是来自鸣潮世界的神秘存在'),
    ('TXT_KEY_LEADER_KATISHA_PEDIA_TAG', '卡提希娅领袖'),

    -- 小卡单位字符串定义
    ('TXT_KEY_UNIT_KATISHA_DESC', '小卡·智慧形态'),
    ('TXT_KEY_UNIT_KATISHA_PEDIA', '鸣潮世界中的独特人物卡提希娅，当前为智慧形态'),
    ('TXT_KEY_UNIT_KATISHA_STRATEGY', '作为初始特殊单位，可在智慧形态和战争形态间切换以适应不同需求'),
    ('TXT_KEY_UNIT_KATISHA_HELP', '卡提希娅拥有独特的双重形态：智慧形态（小卡）支持城市发展，战争形态（大卡）进行战斗'),

    -- 大卡单位字符串定义
    ('TXT_KEY_UNIT_KATISHA_BIG_DESC', '大卡·战争形态 - 拥有"终焉洪流"技能和动态战斗力'),
    ('TXT_KEY_UNIT_KATISHA_BIG_PEDIA', '卡提希娅的战争形态，战斗力随您文明的人口和城市数量动态变化，配备毁灭性的终焉洪流技能'),
    ('TXT_KEY_UNIT_KATISHA_BIG_STRATEGY', '切换到战争形态使卡提希娅成为强大的战斗单位，战斗力根据文明发展程度动态变化，可使用大范围破坏技能'),
    ('TXT_KEY_UNIT_KATISHA_BIG_HELP', '战争形态 - 动态战斗单位，战斗力随人口(0.4/人)和城市数量(2/城)增长，最高可达135，可释放终焉洪流技能'),

    -- 晋升字符串定义
    ('TXT_KEY_PROMOTION_KATISHA_CITY_BONUS', '城市支持'),
    ('TXT_KEY_PROMOTION_KATISHA_CITY_BONUS_HELP', '当卡提希娅驻扎在城市时提供科研、生产、粮食和伟人点数加成'),
    ('TXT_KEY_PROMOTION_KATISHA_CITY_BONUS_PEDIA', '卡提希娅的智慧形态可以显著提升所在城市的效率'),

    -- 技能字符串定义
    ('TXT_KEY_ACTION_KATISHA_SKILL', '文明推演'),
    ('TXT_KEY_ACTION_KATISHA_SKILL_HELP', '使用技能"文明推演"，立即获得当前科技30%的研究进度，以及少量文化和黄金'),

    -- 建筑字符串定义
    ('TXT_KEY_BUILDING_KATISHA_PRESENCE', '卡提希娅存在'),
    ('TXT_KEY_BUILDING_KATISHA_PRESENCE_PEDIA', '当卡提希娅在城市中时，她的知识和能量会显著提升城市的发展效率'),
    ('TXT_KEY_BUILDING_KATISHA_PRESENCE_STRATEGY', '这种效果只有当卡提希娅单位驻扎在城市中时才会激活，提供科研、生产和食物加成'),
    ('TXT_KEY_BUILDING_KATISHA_PRESENCE_HELP', '+20%科研, +25%生产, +30%食物, +25%伟人点数产出'),

    -- 动态战斗力描述
    ('TXT_KEY_ABILITY_KATISHA_DYNAMIC_COMBAT', '动态战斗力'),
    ('TXT_KEY_ABILITY_KATISHA_DYNAMIC_COMBAT_HELP', '战斗力 = 35 + 0.4 × 总人口 + 2 × 城市数量，每3回合更新一次，最高不超过135'),

    -- AOE技能描述
    ('TXT_KEY_ABILITY_KATISHA_AOE', '终焉洪流'),
    ('TXT_KEY_ABILITY_KATISHA_AOE_HELP', '向前方扇形区域释放毁灭性能量波，对区域内所有敌人造成伤害');

-- 如果需要多语言支持，也可以添加其他语言
DELETE FROM Language_zh_CN WHERE Tag LIKE 'TXT_KEY_%KATISHA%';

INSERT INTO Language_zh_CN
    (Tag, Text)
VALUES
    ('TXT_KEY_CIV_KATISHA_DESC', '鸣潮-卡提希娅'),
    ('TXT_KEY_CIV_KATISHA_SHORT_DESC', '卡提希娅文明'),
    ('TXT_KEY_CIV_KATISHA_ADJECTIVE', '卡提希娅的'),
    ('TXT_KEY_CIV_KATISHA_PEDIA', '鸣潮世界中的卡提希娅文明'),

    ('TXT_KEY_LEADER_KATISHA_DESC', '卡提希娅'),
    ('TXT_KEY_LEADER_KATISHA_PEDIA', '卡提希娅是来自鸣潮世界的神秘存在'),
    ('TXT_KEY_LEADER_KATISHA_PEDIA_TAG', '卡提希娅领袖'),

    ('TXT_KEY_UNIT_KATISHA_DESC', '小卡·智慧形态'),
    ('TXT_KEY_UNIT_KATISHA_PEDIA', '鸣潮世界中的独特人物卡提希娅，当前为智慧形态'),
    ('TXT_KEY_UNIT_KATISHA_STRATEGY', '作为初始特殊单位，可在智慧形态和战争形态间切换以适应不同需求'),
    ('TXT_KEY_UNIT_KATISHA_HELP', '卡提希娅拥有独特的双重形态：智慧形态（小卡）支持城市发展，战争形态（大卡）进行战斗'),

    ('TXT_KEY_UNIT_KATISHA_BIG_DESC', '大卡·战争形态 - 拥有"终焉洪流"技能和动态战斗力'),
    ('TXT_KEY_UNIT_KATISHA_BIG_PEDIA', '卡提希娅的战争形态，战斗力随您文明的人口和城市数量动态变化，配备毁灭性的终焉洪流技能'),
    ('TXT_KEY_UNIT_KATISHA_BIG_STRATEGY', '切换到战争形态使卡提希娅成为强大的战斗单位，战斗力根据文明发展程度动态变化，可使用大范围破坏技能'),
    ('TXT_KEY_UNIT_KATISHA_BIG_HELP', '战争形态 - 动态战斗单位，战斗力随人口(0.4/人)和城市数量(2/城)增长，最高可达135，可释放终焉洪流技能'),

    ('TXT_KEY_PROMOTION_KATISHA_CITY_BONUS', '城市支持'),
    ('TXT_KEY_PROMOTION_KATISHA_CITY_BONUS_HELP', '当卡提希娅驻扎在城市时提供科研、生产、粮食和伟人点数加成'),
    ('TXT_KEY_PROMOTION_KATISHA_CITY_BONUS_PEDIA', '卡提希娅的智慧形态可以显著提升所在城市的效率'),

    ('TXT_KEY_ACTION_KATISHA_SKILL', '文明推演'),
    ('TXT_KEY_ACTION_KATISHA_SKILL_HELP', '使用技能"文明推演"，立即获得当前科技30%的研究进度，以及少量文化和黄金'),

    ('TXT_KEY_BUILDING_KATISHA_PRESENCE', '卡提希娅存在'),
    ('TXT_KEY_BUILDING_KATISHA_PRESENCE_PEDIA', '当卡提希娅在城市中时，她的知识和能量会显著提升城市的发展效率'),
    ('TXT_KEY_BUILDING_KATISHA_PRESENCE_STRATEGY', '这种效果只有当卡提希娅单位驻扎在城市中时才会激活，提供科研、生产和食物加成'),
    ('TXT_KEY_BUILDING_KATISHA_PRESENCE_HELP', '+20%科研, +25%生产, +30%食物, +25%伟人点数产出'),

    ('TXT_KEY_ABILITY_KATISHA_DYNAMIC_COMBAT', '动态战斗力'),
    ('TXT_KEY_ABILITY_KATISHA_DYNAMIC_COMBAT_HELP', '战斗力 = 35 + 0.4 × 总人口 + 2 × 城市数量，每3回合更新一次，最高不超过135'),

    ('TXT_KEY_ABILITY_KATISHA_AOE', '终焉洪流'),
    ('TXT_KEY_ABILITY_KATISHA_AOE_HELP', '向前方扇形区域释放毁灭性能量波，对区域内所有敌人造成伤害');