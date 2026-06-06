-- 卡提希娅文明 V0.1
-- 仅负责在首都建立后赠送一次卡提希娅，不包含其他玩法逻辑。

local civilizationID = GameInfoTypes.CIVILIZATION_CARTETHYIA
local unitID = GameInfoTypes.UNIT_CARTETHYIA
local attackAI = GameInfoTypes.UNITAI_ATTACK
local saveData = Modding.OpenSaveData()

if civilizationID == nil or unitID == nil then
  print("Cartethyia V0.1: missing civilization or unit database entry.")
  return
end

local function GetSaveKey(playerID)
  -- 地图种子用于降低不同战局之间键名冲突的概率。
  -- Modding.OpenSaveData 的跨读档行为仍需要在本机环境中验证。
  local mapSeed = 0
  if PreGame.GetMapSeed ~= nil then
    mapSeed = PreGame.GetMapSeed()
  end
  return "CARTETHYIA_V01_GRANTED_" .. tostring(mapSeed) .. "_" .. tostring(playerID)
end

local function PlayerAlreadyHasUnit(player)
  for unit in player:Units() do
    if unit:GetUnitType() == unitID then
      return true
    end
  end
  return false
end

local function TryGrantStartUnit(playerID)
  local player = Players[playerID]
  if player == nil or not player:IsAlive() then
    return
  end

  if player:IsMinorCiv() or player:IsBarbarian() then
    return
  end

  if player:GetCivilizationType() ~= civilizationID then
    return
  end

  local saveKey = GetSaveKey(playerID)
  if tonumber(saveData.GetValue(saveKey)) == 1 then
    return
  end

  -- 兼容首次加入脚本的旧存档：已有单位时只补记状态，不重复生成。
  if PlayerAlreadyHasUnit(player) then
    saveData.SetValue(saveKey, 1)
    return
  end

  local capital = player:GetCapitalCity()
  if capital == nil then
    return
  end

  local unit = player:InitUnit(unitID, capital:GetX(), capital:GetY(), attackAI)
  if unit ~= nil then
    saveData.SetValue(saveKey, 1)
    print("Cartethyia V0.1: granted start unit to player " .. tostring(playerID) .. ".")
  else
    print("Cartethyia V0.1: failed to create start unit for player " .. tostring(playerID) .. ".")
  end
end

local function GrantForAllMajorPlayers()
  for playerID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
    TryGrantStartUnit(playerID)
  end
end

-- 新游戏初始化时立即尝试；若首都尚未存在，则在玩家回合开始时继续尝试。
Events.SequenceGameInitComplete.Add(GrantForAllMajorPlayers)
GameEvents.PlayerDoTurn.Add(TryGrantStartUnit)

print("Cartethyia V0.1: start unit script loaded.")
