--
-- 文件名: KatishaUnitLogic.lua
-- 作用: 实现卡提希娅单位的游戏逻辑（第一、二、三、四、五阶段完整版）
-- 用途: 处理单位的形态切换、驻城加成、技能系统、AOE技能和动态战斗力
--

-- 导入必要模块
include("FLuaVector.lua")

-- 从各个子系统导入相关函数（如果可用）
-- 动态战斗力系统相关
BASE_BIG_FORM_COMBAT = BASE_BIG_FORM_COMBAT or 35
POPULATION_FACTOR = POPULATION_FACTOR or 0.4
CITY_FACTOR = CITY_FACTOR or 2
UPDATE_INTERVAL = UPDATE_INTERVAL or 3
MAX_COMBAT_BONUS = MAX_COMBAT_BONUS or 100

-- 存储动态战斗力信息
g_DynamicCombatInfo = g_DynamicCombatInfo or {}

-- 全局变量定义
g_KatishaForm = g_KatishaForm or {}
g_KatishaCooldowns = g_KatishaCooldowns or {}
g_KatishaCityBonuses = g_KatishaCityBonuses or {}
g_KatishaCityBonusBuildings = g_KatishaCityBonusBuildings or {}

-- 定义常量
KATISHA_FORM_SMALL = "SMALL"    -- 小卡形态（智慧）
KATISHA_FORM_BIG = "BIG"        -- 大卡形态（战争）

-- 加成数值常量
KATISHA_SCIENCE_BONUS = 0.20    -- 科研加成20%
KATISHA_PRODUCTION_BONUS = 0.25 -- 生产加成25%
KATISHA_FOOD_BONUS = 0.30       -- 粮食加成30%
KATISHA_GREAT_PERSON_BONUS = 0.25 -- 伟人点数加成25%

-- 技能相关常量
SKILL_COOLDOWN_TURNS = 5        -- 一般技能冷却回合数
SCIENCE_PROGRESS_PERCENT = 0.30 -- 文明推演技能提供的科技进度百分比
SKILL_GOLD_REWARD = 50         -- 技能奖励的黄金数量
SKILL_CULTURE_REWARD = 25      -- 技能奖励的文化数量

-- 形态切换常量
MORPH_COOLDOWN_TURNS = 3       -- 形态切换冷却回合数

-- AOE技能常量
KATISHA_AOE_RANGE = 3              -- AOE攻击范围（前方3格）
KATISHA_AOE_DAMAGE_BASE = 30       -- 基础伤害值
KATISHA_CITY_DAMAGE_MULTIPLIER = 0.5 -- 对城市伤害倍率
KATISHA_AOE_COOLDOWN = 5           -- 技能冷却回合数

-- 平衡限制常量
MAX_DYNAMIC_COMBAT = 135           -- 动态战斗力上限（基础35 + 最大100加成）

-- 检查单位是否为卡提希娅系列单位
function IsKatishaUnit(unit)
    if not unit then return false end
    return unit:GetUnitType() == GameInfo.Units.UNIT_KATISHA.ID or
           unit:GetUnitType() == GameInfo.Units.UNIT_KATISHA_BIG.ID
end

-- 检查单位是否为小卡形态
function IsSmallForm(unit)
    if not IsKatishaUnit(unit) then return false end
    return unit:GetUnitType() == GameInfo.Units.UNIT_KATISHA.ID
end

-- 检查单位是否为大卡形态
function IsBigForm(unit)
    if not IsKatishaUnit(unit) then return false end
    return unit:GetUnitType() == GameInfo.Units.UNIT_KATISHA_BIG.ID
end

-- 获取单位形态（基于单位类型）
function GetKatishaActualForm(unit)
    if IsSmallForm(unit) then
        return KATISHA_FORM_SMALL
    elseif IsBigForm(unit) then
        return KATISHA_FORM_BIG
    else
        return nil
    end
end

-- 保存单位形态的函数
function SaveKatishaForm(iPlayer, iUnit, form)
    local player = Players[iPlayer]
    local unit = player:GetUnitByID(iUnit)

    if unit ~= nil and IsKatishaUnit(unit) then
        g_KatishaForm[unit:GetID()] = form
        -- 根据形态调整单位属性
        UpdateKatishaAttributes(unit, form)

        -- 如果切换到大卡形态，立即计算动态战斗力
        if form == KATISHA_FORM_BIG then
            UpdateUnitDynamicCombat(iPlayer, iUnit)
        end
    end
end

-- 获取单位形态的函数（从存储数据获取，如果不是转换后的单位）
function GetStoredKatishaForm(iPlayer, iUnit)
    local player = Players[iPlayer]
    local unit = player:GetUnitByID(iUnit)

    if unit ~= nil and IsKatishaUnit(unit) then
        return g_KatishaForm[unit:GetID()] or GetKatishaActualForm(unit)
    end

    return GetKatishaActualForm(unit) or KATISHA_FORM_SMALL
end

-- 根据形态更新单位属性
function UpdateKatishaAttributes(unit, form)
    if not IsKatishaUnit(unit) then
        return
    end

    local actualForm = GetKatishaActualForm(unit)
    if actualForm == KATISHA_FORM_SMALL then
        -- 小卡形态：低战斗力，专注辅助
        print("卡提希娅保持小卡形态（智慧）")
    elseif actualForm == KATISHA_FORM_BIG then
        -- 大卡形态：高战斗力，专注战斗
        print("卡提希娅保持大卡形态（战争）")
    end
end

-- 设置单位冷却时间的函数
function SetKatishaCooldown(iPlayer, iUnit, cooldownType, turns)
    local player = Players[iPlayer]
    local unit = player:GetUnitByID(iUnit)

    if unit ~= nil and IsKatishaUnit(unit) then
        local unitID = unit:GetID()
        if g_KatishaCooldowns[unitID] == nil then
            g_KatishaCooldowns[unitID] = {}
        end
        g_KatishaCooldowns[unitID][cooldownType] = {
            turns = turns,
            startTime = Game.GetGameTurn()
        }
    end
end

-- 检查单位冷却时间的函数
function CheckKatishaCooldown(iPlayer, iUnit, cooldownType)
    local player = Players[iPlayer]
    local unit = player:GetUnitByID(iUnit)

    if unit ~= nil and IsKatishaUnit(unit) then
        local unitID = unit:GetID()
        if g_KatishaCooldowns[unitID] ~= nil and
           g_KatishaCooldowns[unitID][cooldownType] ~= nil then

            local cooldown = g_KatishaCooldowns[unitID][cooldownType]
            local elapsedTurns = Game.GetGameTurn() - cooldown.startTime

            if elapsedTurns >= cooldown.turns then
                -- 冷却已结束
                g_KatishaCooldowns[unitID][cooldownType] = nil
                return true
            else
                -- 冷却仍在进行
                return false
            end
        end
        -- 没有冷却或已过期
        return true
    end

    return true
end

-- 计算大卡形态的实际战斗力
function CalculateDynamicCombatStrength(playerID)
    local player = Players[playerID]

    if not player then
        return BASE_BIG_FORM_COMBAT
    end

    -- 获取玩家的总人口
    local totalPopulation = 0
    for i, city in player:Cities() do
        totalPopulation = totalPopulation + city:GetPopulation()
    end

    -- 获取玩家的城市数量
    local cityCount = player:GetNumCities()

    -- 根据公式计算动态战斗力
    -- Combat = 35 + 0.4 × 总人口 + 2 × 城市数量
    local populationBonus = POPULATION_FACTOR * totalPopulation
    local cityBonus = CITY_FACTOR * cityCount
    local calculatedCombat = BASE_BIG_FORM_COMBAT + populationBonus + cityBonus

    -- 限制最大战斗力加成
    local maxAllowedCombat = MAX_DYNAMIC_COMBAT
    local finalCombat = math.min(calculatedCombat, maxAllowedCombat)

    print("玩家 " .. playerID .. " 战斗力计算: 基础(" .. BASE_BIG_FORM_COMBAT .. ") + 人口加成(" ..
          math.floor(populationBonus) .. ") + 城市加成(" .. cityBonus .. ") = " .. math.floor(finalCombat))

    return math.floor(finalCombat)
end

-- 更新特定单位的动态战斗力记录
function UpdateUnitDynamicCombat(iPlayer, iUnit)
    local player = Players[iPlayer]
    local unit = player:GetUnitByID(iUnit)

    if not unit or not IsKatishaUnit(unit) then
        return
    end

    -- 只为大卡形态计算动态战斗力
    if GetStoredKatishaForm(iPlayer, iUnit) == KATISHA_FORM_BIG then
        local combatStrength = CalculateDynamicCombatStrength(iPlayer)

        -- 存储单位的动态战斗力信息
        local unitID = unit:GetID()
        if not g_DynamicCombatInfo[unitID] then
            g_DynamicCombatInfo[unitID] = {}
        end

        g_DynamicCombatInfo[unitID] = {
            strength = combatStrength,
            lastUpdateTurn = Game.GetGameTurn(),
            owner = iPlayer
        }

        print("更新单位 " .. unitID .. " 动态战斗力: " .. combatStrength)
    end
end

-- 获取单位的动态战斗力
function GetKatishaDynamicCombat(unit)
    if not unit or not IsKatishaUnit(unit) then
        if unit then
            return unit:GetBaseCombatStrength()
        else
            return 0
        end
    end

    local unitID = unit:GetID()
    local form = GetStoredKatishaForm(unit:GetOwner(), unitID)

    -- 只有大卡形态才使用动态战斗力
    if form == KATISHA_FORM_BIG then
        -- 如果已有记录且仍在有效期内，直接返回
        if g_DynamicCombatInfo[unitID] then
            local info = g_DynamicCombatInfo[unitID]
            return info.strength
        end

        -- 否则计算并保存
        local combatStrength = CalculateDynamicCombatStrength(unit:GetOwner())
        g_DynamicCombatInfo[unitID] = {
            strength = combatStrength,
            lastUpdateTurn = Game.GetGameTurn(),
            owner = unit:GetOwner()
        }

        return combatStrength
    else
        -- 小卡形态使用固定的低战斗力
        return 15  -- 在XML中定义的小卡战斗力
    end
end

-- 获取单位当前所在的城市
function GetUnitCity(unit)
    if unit == nil then
        return nil
    end

    local plot = unit:GetPlot()
    if plot ~= nil then
        return plot:GetPlotCity()
    end
    return nil
end

-- 检查城市是否有卡提希娅加成
function HasKatishaBonus(playerID, cityID)
    local cityKey = playerID .. "_" .. cityID
    return g_KatishaCityBonuses[cityKey] == true
end

-- 检查并应用/移除城市中的卡提希娅加成建筑
function UpdateKatishaCityBonus(iPlayer, iCity)
    local player = Players[iPlayer]
    local city = player:GetCityByID(iCity)

    if city == nil then
        return
    end

    local cityKey = iPlayer .. "_" .. iCity
    local hasKatisha = false
    local katishaForm = KATISHA_FORM_SMALL

    -- 检查城市中是否有卡提希娅单位且为小卡形态
    local cityX, cityY = city:GetX(), city:GetY()
    for i, unit in player:Units() do
        if IsKatishaUnit(unit) and
           unit:GetX() == cityX and unit:GetY() == cityY then
            hasKatisha = true
            katishaForm = GetStoredKatishaForm(iPlayer, unit:GetID())
            break
        end
    end

    -- 只有在小卡形态时才应用加成
    if hasKatisha and katishaForm == KATISHA_FORM_SMALL and
       not city:IsHasBuilding(GameInfo.Buildings.BUILDING_KATISHA_PRESENCE.ID) then
        -- 建造加成建筑
        city:SetNumRealBuilding(GameInfo.Buildings.BUILDING_KATISHA_PRESENCE.ID, 1)
        print("在城市 '" .. city:GetName() .. "' 激活卡提希娅存在加成")

        -- 记录加成状态
        g_KatishaCityBonuses[cityKey] = true
    elseif (not hasKatisha or katishaForm ~= KATISHA_FORM_SMALL) and
           city:IsHasBuilding(GameInfo.Buildings.BUILDING_KATISHA_PRESENCE.ID) then
        -- 移除加成建筑
        city:SetNumRealBuilding(GameInfo.Buildings.BUILDING_KATISHA_PRESENCE.ID, 0)
        print("从城市 '" .. city:GetName() .. "' 移除卡提希娅存在加成")

        -- 移除加成状态
        g_KatishaCityBonuses[cityKey] = nil
    end
end

-- 切换单位形态（从小卡到大卡，或从大卡到小卡）
function ToggleKatishaForm(iPlayer, iUnit)
    local player = Players[iPlayer]
    local unit = player:GetUnitByID(iUnit)

    if unit == nil or not IsKatishaUnit(unit) then
        print("不是有效的卡提希娅单位，无法切换形态")
        return false
    end

    -- 检查形态切换是否在冷却中
    if not CheckKatishaCooldown(iPlayer, iUnit, "FORM_TOGGLE") then
        print("形态切换仍在冷却中，无法切换")
        return false
    end

    local currentForm = GetStoredKatishaForm(iPlayer, iUnit)
    local newUnitType

    if currentForm == KATISHA_FORM_SMALL then
        -- 切换到大卡形态
        newUnitType = GameInfo.Units.UNIT_KATISHA_BIG.ID
        print("卡提希娅切换到大卡形态（战争）")
    else
        -- 切换到小卡形态
        newUnitType = GameInfo.Units.UNIT_KATISHA.ID
        print("卡提希娅切换到小卡形态（智慧）")
    end

    -- 获取当前单位的位置和属性
    local x, y = unit:GetX(), unit:GetY()
    local currentHP = unit:GetCurrHitPoints()
    local currentMoves = unit:MovesRemaining()
    local currentExperience = unit:GetExperience()
    local currentLevel = unit:GetLevel()
    local promotions = {}

    -- 保存当前单位的晋升
    for promotion in GameInfo.UnitPromotions() do
        if unit:IsHasPromotion(promotion.ID) then
            table.insert(promotions, promotion.Type)
        end
    end

    -- 保存当前的冷却状态
    local unitID = unit:GetID()
    local cooldowns = g_KatishaCooldowns[unitID]

    -- 杀死当前单位（不计入损失统计）
    unit:Kill(false, PlayerTypes.NO_PLAYER)

    -- 创建新形态的单位
    local newUnit = player:InitUnit(newUnitType, x, y)
    if newUnit then
        -- 恢复生命值
        newUnit:SetCurrHitPoints(currentHP)

        -- 恢复移动力
        newUnit:SetMoves(currentMoves)

        -- 恢复经验和等级
        newUnit:SetLevel(currentLevel)
        newUnit:ChangeExperience(currentExperience)

        -- 恢复晋升
        for _, promotionType in ipairs(promotions) do
            local promotionInfo = GameInfo.UnitPromotions[promotionType]
            if promotionInfo then
                newUnit:SetHasPromotion(promotionInfo.ID, true)
            end
        end

        -- 保存新单位的形态和冷却信息
        local newForm = (currentForm == KATISHA_FORM_SMALL) and KATISHA_FORM_BIG or KATISHA_FORM_SMALL
        g_KatishaForm[newUnit:GetID()] = newForm
        g_KatishaCooldowns[newUnit:GetID()] = cooldowns

        -- 如果是大卡形态，计算动态战斗力
        if newForm == KATISHA_FORM_BIG then
            UpdateUnitDynamicCombat(iPlayer, newUnit:GetID())
        end

        -- 设置形态切换冷却
        SetKatishaCooldown(iPlayer, newUnit:GetID(), "FORM_TOGGLE", MORPH_COOLDOWN_TURNS)

        print("形态切换成功，新形态: " .. newForm)

        -- 更新城市加成
        local city = GetUnitCity(newUnit)
        if city then
            UpdateKatishaCityBonus(iPlayer, city:GetID())
        end

        return true
    else
        print("创建新形态单位失败")
        return false
    end
end

-- 实现文明推演技能
function UseCivilizationProjectionSkill(iPlayer, iUnit)
    local player = Players[iPlayer]
    local unit = player:GetUnitByID(iUnit)

    if unit == nil or not IsKatishaUnit(unit) then
        print("非卡提希娅单位，无法使用技能")
        return false
    end

    -- 检查技能是否处于冷却中
    if not CheckKatishaCooldown(iPlayer, iUnit, "SKILL_CIVILIZATION_PROJECTION") then
        print("文明推演技能仍在冷却中，无法使用")
        return false
    end

    -- 只有小卡形态才能使用文明推演技能
    if GetStoredKatishaForm(iPlayer, iUnit) ~= KATISHA_FORM_SMALL then
        print("只有小卡形态才能使用文明推演技能")
        return false
    end

    -- 获取玩家当前正在研究的科技
    local currentTech = player:GetCurrentResearch()
    if currentTech ~= -1 then
        local techInfo = GameInfo.Technologies[currentTech]
        if techInfo ~= nil then
            local techCost = player:GetResearchCost(currentTech)
            local currentProgress = player:GetResearchProgress(currentTech)

            -- 计算技能提供的进度
            local skillProgress = math.floor(techCost * SCIENCE_PROGRESS_PERCENT)

            -- 增加科技研究进度
            player:ChangeResearchProgress(currentTech, skillProgress, iPlayer)

            print("使用文明推演技能，为 '" .. Locale.ConvertTextKey(techInfo.Description) .. "' 增加 " .. skillProgress .. " 进度")
        end
    end

    -- 给予黄金和文化奖励
    player:ChangeGold(SKILL_GOLD_REWARD)
    player:ChangeJONSCulture(SKILL_CULTURE_REWARD)

    print("获得 " .. SKILL_GOLD_REWARD .. " 黄金和 " .. SKILL_CULTURE_REWARD .. " 文化")

    -- 设置技能冷却
    SetKatishaCooldown(iPlayer, iUnit, "SKILL_CIVILIZATION_PROJECTION", SKILL_COOLDOWN_TURNS)

    return true
end

-- 实现终焉洪流技能（AOE攻击）
function UseFinalityFloodSkill(iPlayer, iUnit, targetX, targetY)
    local player = Players[iPlayer]
    local katishaUnit = player:GetUnitByID(iUnit)

    if katishaUnit == nil or not IsKatishaUnit(katishaUnit) then
        print("非卡提希娅单位，无法使用技能")
        return false
    end

    -- 检查技能是否处于冷却中
    if not CheckKatishaCooldown(iPlayer, iUnit, "SKILL_FINALITY_FLOOD") then
        print("终焉洪流技能仍在冷却中，无法使用")
        return false
    end

    -- 只有大卡形态才能使用终焉洪流技能
    if GetStoredKatishaForm(iPlayer, iUnit) ~= KATISHA_FORM_BIG then
        print("只有大卡形态才能使用终焉洪流技能")
        return false
    end

    -- 获取扇形参数：以卡提希娅位置为中心，朝向目标方向
    local katishaX, katishaY = katishaUnit:GetX(), katishaUnit:GetY()

    -- 如果没有提供目标坐标，使用单位朝向
    if not targetX or not targetY then
        -- 简化：使用单位周围的某个方向作为目标
        targetX, targetY = katishaX, katishaY - 1  -- 默认朝北
    end

    print("使用终焉洪流技能，朝向目标(" .. targetX .. ", " .. targetY .. ")")

    -- 获取扇形范围内的所有目标
    local targets = GetTargetsInAoeRange(katishaUnit, 60, KATISHA_AOE_RANGE)  -- 60度扇形，3格范围

    -- 获取当前战斗力来计算伤害
    local currentCombat = GetKatishaDynamicCombat(katishaUnit)
    local damageMultiplier = currentCombat / 45.0  -- 基于45的标准战斗力缩放伤害

    -- 对每个目标造成伤害
    local targetsHit = 0

    -- 对单位造成伤害
    for _, unit in ipairs(targets.units) do
        local baseDamage = math.floor(KATISHA_AOE_DAMAGE_BASE * damageMultiplier)
        local damage = CalculateAoeDamage(katishaUnit, unit, "unit", baseDamage)
        ApplyDamageToTarget(katishaUnit, unit, damage, "unit")
        print("对敌方单位造成 " .. damage .. " 点伤害")
        targetsHit = targetsHit + 1
    end

    -- 对城市造成伤害
    for _, city in ipairs(targets.cities) do
        local baseDamage = math.floor(KATISHA_AOE_DAMAGE_BASE * 0.5 * damageMultiplier)  -- 城市伤害额外降低
        local damage = CalculateAoeDamage(katishaUnit, city, "city", baseDamage)
        ApplyDamageToTarget(katishaUnit, city, damage, "city")
        print("对敌方城市造成 " .. damage .. " 点伤害")
        targetsHit = targetsHit + 1
    end

    -- 显示技能结果
    print("终焉洪流技能完成，共击中 " .. targetsHit .. " 个目标")

    -- 设置技能冷却
    SetKatishaCooldown(iPlayer, iUnit, "SKILL_FINALITY_FLOOD", KATISHA_AOE_COOLDOWN)

    -- 技能使用后禁止移动
    katishaUnit:SetMoves(0)

    -- 可能需要触发视觉特效
    print("终焉洪流技能特效播放")

    return true
end

-- 扩展AOE伤害计算以支持动态伤害
function CalculateAoeDamage(katishaUnit, target, targetType, baseDamage)
    local damage = baseDamage or KATISHA_AOE_DAMAGE_BASE

    -- 如果是城市，降低伤害
    if targetType == "city" then
        damage = math.floor(damage * KATISHA_CITY_DAMAGE_MULTIPLIER)
    end

    return damage
end

-- 扩展伤害应用以支持更好的战斗反馈
function ApplyDamageToTarget(katishaUnit, target, damage, targetType)
    if targetType == "unit" then
        -- 对单位造成伤害
        local unitOwner = Players[target:GetOwner()]
        if unitOwner ~= nil then
            print("对敌方单位造成 " .. damage .. " 点伤害")

            -- 伤害单位（简化：立即击杀血量低于伤害的单位）
            local currentHP = target:GetCurrHitPoints()
            local newHP = math.max(0, currentHP - damage)
            target:SetCurrHitPoints(newHP)

            if newHP <= 0 then
                print("敌方单位被消灭")
                target:Kill(true, katishaUnit:GetOwner())  -- 作为击杀者
            end
        end
    elseif targetType == "city" then
        -- 对城市造成伤害（文明5中城市伤害处理复杂）
        print("对敌方城市造成 " .. damage .. " 点伤害")

        -- 在实际游戏中，这可能需要更复杂的城市耐久度系统
        local cityOwner = Players[target:GetOwner()]
        if cityOwner ~= nil then
            print("城市受到结构损伤")
        end
    end
end

-- 扩展扇形范围检测以支持更精确的目标选择
function GetTargetsInAoeRange(katishaUnit, angleWidth, maxRange)
    local centerX, centerY = katishaUnit:GetX(), katishaUnit:GetY()
    local facingDirection = 0  -- 简化处理：假设单位朝北

    local targets = {
        units = {},
        cities = {},
        plots = {}
    }

    -- 简化的扇形范围搜索
    for dx = -maxRange, maxRange do
        for dy = -maxRange, maxRange do
            local targetX = centerX + dx
            local targetY = centerY + dy

            local plot = Map.GetPlot(targetX, targetY)
            if plot ~= nil then
                -- 简化：假设扇形朝北（0度），60度扇形角
                local distance = math.sqrt(dx*dx + dy*dy)
                if distance > 0 and distance <= maxRange then
                    -- 检查是否大致在前方扇形区域（简化为三角锥形）
                    local angle = math.deg(math.atan2(dy, dx))
                    local adjustedAngle = (90 - angle) % 360

                    -- 假设扇形角度为60度，朝北
                    local inFront = false
                    if dx <= 0 then  -- 在前方半平面
                        local tanAngle = math.abs(dy) / math.max(math.abs(dx), 0.001)  -- 避免除零
                        -- 30度的正切值约为0.577
                        if tanAngle <= 0.6 and dx < 0 then  -- 简化判断，约±30度范围
                            inFront = true
                        end
                    end

                    if inFront then
                        table.insert(targets.plots, plot)

                        -- 检查地块上的单位
                        if plot:IsUnit() then
                            for i = 0, plot:GetNumUnits() - 1 do
                                local unit = plot:GetUnit(i)
                                if unit ~= katishaUnit and unit:GetOwner() ~= katishaUnit:GetOwner() then
                                    table.insert(targets.units, unit)
                                end
                            end
                        end

                        -- 检查地块上的城市
                        if plot:IsCity() then
                            local city = plot:GetPlotCity()
                            if city and city:GetOwner() ~= katishaUnit:GetOwner() then
                                table.insert(targets.cities, city)
                            end
                        end
                    end
                end
            end
        end
    end

    return targets
end

-- 单位初始化事件
function OnKatishaInitialize(iPlayer, iUnit)
    local player = Players[iPlayer]
    local unit = player:GetUnitByID(iUnit)

    if unit ~= nil and IsKatishaUnit(unit) then
        -- 初始化形态（如果是小卡单位）
        local form = GetKatishaActualForm(unit)
        if form then
            g_KatishaForm[unit:GetID()] = form
        end

        print("卡提希娅单位已初始化，当前形态：" .. (form or "未知"))

        -- 如果是大卡形态，计算动态战斗力
        if form == KATISHA_FORM_BIG then
            UpdateUnitDynamicCombat(iPlayer, iUnit)
        end

        -- 检查单位是否在城市上，如果是则应用加成
        local city = GetUnitCity(unit)
        if city ~= nil then
            UpdateKatishaCityBonus(iPlayer, city:GetID())
        end
    end
end

-- 单位移动事件 - 检查是否进出城市以应用/移除加成
function OnUnitSetXY(iPlayer, iUnit, iX, iY)
    local player = Players[iPlayer]
    local unit = player:GetUnitByID(iUnit)

    if unit ~= nil and IsKatishaUnit(unit) then
        -- 检查单位之前的位置是否有城市
        local prevPlot = Map.GetPlot(unit:GetX(), unit:GetY())
        if prevPlot ~= nil then
            local prevCity = prevPlot:GetPlotCity()
            if prevCity ~= nil then
                -- 更新之前城市的加成状态
                UpdateKatishaCityBonus(iPlayer, prevCity:GetID())
            end
        end

        -- 检查新位置是否有城市需要更新加成
        local newPlot = Map.GetPlot(iX, iY)
        if newPlot ~= nil then
            local newCity = newPlot:GetPlotCity()
            if newCity ~= nil then
                -- 更新新城市的加成状态
                UpdateKatishaCityBonus(iPlayer, newCity:GetID())
            end
        end
    end
end

-- 回合开始事件
function OnPlayerDoTurn(iPlayer)
    local player = Players[iPlayer]

    -- 只对有卡提希娅文明的玩家处理特殊逻辑
    if player:GetCivilizationType() ~= GameInfo.Civilizations.CIVILIZATION_KATISHA.ID then
        return
    end

    -- 每隔几回合更新所有卡提希娅单位的战斗力
    local currentTurn = Game.GetGameTurn()
    if currentTurn % UPDATE_INTERVAL == 0 then
        for i, unit in player:Units() do
            if IsKatishaUnit(unit) and GetStoredKatishaForm(iPlayer, unit:GetID()) == KATISHA_FORM_BIG then
                UpdateUnitDynamicCombat(iPlayer, unit:GetID())
            end
        end
    end

    -- 更新冷却状态
    for i, unit in player:Units() do
        if IsKatishaUnit(unit) then
            local unitID = unit:GetID()

            -- 更新各种冷却时间
            if g_KatishaCooldowns[unitID] ~= nil then
                local removeCooldowns = {}
                for cooldownType, cooldownData in pairs(g_KatishaCooldowns[unitID]) do
                    local elapsedTurns = Game.GetGameTurn() - cooldownData.startTime
                    if elapsedTurns >= cooldownData.turns then
                        table.insert(removeCooldowns, cooldownType)
                    end
                end

                -- 移除已完成的冷却
                for _, cooldownType in ipairs(removeCooldowns) do
                    g_KatishaCooldowns[unitID][cooldownType] = nil
                end
            end

            -- 检查单位是否在城市上并更新加成
            local city = GetUnitCity(unit)
            if city ~= nil then
                UpdateKatishaCityBonus(iPlayer, city:GetID())
            end
        end
    end
end

-- 游戏加载时触发
function OnGameLoad()
    print("正在重新加载卡提希娅单位数据...")

    -- 清空现有数据
    g_KatishaForm = {}
    g_KatishaCooldowns = {}
    g_KatishaCityBonuses = {}
    g_DynamicCombatInfo = {}

    -- 重新初始化所有卡提希娅单位的状态
    for iPlayer = 0, GameDefines.MAX_PLAYERS - 1 do
        local player = Players[iPlayer]
        if player:IsAlive() and player:GetCivilizationType() == GameInfo.Civilizations.CIVILIZATION_KATISHA.ID then
            for i, unit in player:Units() do
                if IsKatishaUnit(unit) then
                    -- 保存单位的当前形态
                    local form = GetKatishaActualForm(unit)
                    if form then
                        g_KatishaForm[unit:GetID()] = form
                    end

                    -- 如果是大卡形态，计算动态战斗力
                    if form == KATISHA_FORM_BIG then
                        UpdateUnitDynamicCombat(iPlayer, unit:GetID())
                    end

                    -- 更新所在城市的加成
                    local city = GetUnitCity(unit)
                    if city ~= nil then
                        UpdateKatishaCityBonus(iPlayer, city:GetID())
                    end
                end
            end
        end
    end

    print("卡提希娅单位数据重载完成")
end

-- 城市建造事件
function OnCityBuilt(iPlayer, iCity)
    local player = Players[iPlayer]
    local city = player:GetCityByID(iCity)

    if city ~= nil then
        -- 检查是否有卡提希娅单位在这个城市上
        for i, unit in player:Units() do
            if IsKatishaUnit(unit) and
               unit:GetX() == city:GetX() and unit:GetY() == city:GetY() then
                UpdateKatishaCityBonus(iPlayer, iCity)
                break
            end
        end
    end
end

-- 单位死亡事件 - 清理相关数据
function OnUnitLost(iPlayer, iUnit)
    local player = Players[iPlayer]
    local unit = player:GetUnitByID(iUnit)

    if unit ~= nil and IsKatishaUnit(unit) then
        -- 清理单位相关的形态和冷却数据
        if g_KatishaForm[unit:GetID()] then
            g_KatishaForm[unit:GetID()] = nil
        end

        if g_KatishaCooldowns[unit:GetID()] then
            g_KatishaCooldowns[unit:GetID()] = nil
        end

        -- 清理动态战斗力数据
        if g_DynamicCombatInfo[unit:GetID()] then
            g_DynamicCombatInfo[unit:GetID()] = nil
        end

        -- 如果单位在城市上，更新该城市的加成
        local city = GetUnitCity(unit)
        if city ~= nil then
            UpdateKatishaCityBonus(iPlayer, city:GetID())
        end
    end
end

-- 处理用户输入事件（用于技能和形态切换）
function OnCustomModEvent(majorPlayerID, data1, data2, data3, otherPlayerID)
    if data1 == 9999 then  -- 自定义技能触发代码
        if data2 == 1 then  -- 文明推演技能
            return UseCivilizationProjectionSkill(majorPlayerID, data3)
        elseif data2 == 2 then  -- 形态切换技能
            return ToggleKatishaForm(majorPlayerID, data3)
        elseif data2 == 3 then  -- 终焉洪流技能
            -- 终焉洪流需要目标坐标，简化处理：使用单位位置+方向
            local player = Players[majorPlayerID]
            local unit = player:GetUnitByID(data3)
            if unit then
                local x, y = unit:GetX(), unit:GetY()
                -- 简化：使用单位朝向的前一格作为目标
                return UseFinalityFloodSkill(majorPlayerID, data3, x, y - 1)
            end
        end
    end
    return true
end

-- 注册游戏事件监听器
GameEvents.UnitCreated.Add(OnKatishaInitialize)
GameEvents.UnitSetXY.Add(OnUnitSetXY)
GameEvents.PlayerDoTurn.Add(OnPlayerDoTurn)
GameEvents.CityBuilt.Add(OnCityBuilt)
GameEvents.UnitLost.Add(OnUnitLost)
GameEvents.LoadScreenClose.Add(OnGameLoad)
Events.SerialEventGameMessage.Add(OnCustomModEvent)

print("卡提希娅单位逻辑脚本已完全加载（第一、二、三、四、五阶段）")