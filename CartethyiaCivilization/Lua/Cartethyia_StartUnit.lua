-- Cartethyia v1.0: one dual-form hero, with a persistent ten-turn return.
include("SaveUtils")
include("Cartethyia_Rules")
local R = CartethyiaRules
local SAVE, GRANTED, STATE = "CARTETHYIA_V02", "START_UNIT_GRANTED", "DUAL_FORM_STATE_V1"
local civID, unitType = GameInfoTypes.CIVILIZATION_CARTETHYIA, GameInfoTypes.UNIT_CARTETHYIA
local baseBuilding, capitalBuilding, wisdomBuilding = GameInfoTypes.BUILDING_DUAL_RESONANCE, GameInfoTypes.BUILDING_CARTETHYIA_CAPITAL, GameInfoTypes.BUILDING_CARTETHYIA_WISDOM
local powerPromotions = {}
for _,name in ipairs({"WIND","AURA","FREE","SHIELD","UNYIELDING"}) do
  local id = GameInfoTypes["PROMOTION_CARTETHYIA_"..name]
  if id == nil then print("Cartethyia: missing promotion "..name); return end
  powerPromotions[#powerPromotions+1] = id
end
if not civID or not unitType or not baseBuilding or not capitalBuilding or not wisdomBuilding then
  print("Cartethyia: required V0.3 database entries missing; controller disabled."); return
end
local legacy = Modding.OpenSaveData()
local syncing, executing, endingTurn = false, false, false
local dying, completion = {}, nil
local function Reason(s) return "TXT_KEY_CARTETHYIA_REASON_"..s end
local function Protected(label,fn)
  local ok,result=pcall(fn)
  if not ok then print("Cartethyia "..label..": "..tostring(result)) end
  return ok,result
end
local function IsPlayer(p)
  return p and p:IsAlive() and not p:IsMinorCiv() and not p:IsBarbarian() and p:GetCivilizationType()==civID
end
local function IsHero(u) return u and u:GetUnitType()==unitType end
local function Dead(u)
  return (u.IsDead and u:IsDead()) or (u.IsDelayedDeath and u:IsDelayedDeath())
    or dying[u:GetOwner()..":"..u:GetID()]
end
local function FindHero(p)
  for u in p:Units() do if IsHero(u) and not Dead(u) then return u end end
end
local function Store(p,state) save(p,STATE,state,SAVE,0) end
local function ReadState(p,u,initialForm)
  local state = load(p,STATE,SAVE,0)
  if type(state)~="table" then state={form=initialForm or "POWER",wisdomReady=0,powerReady=0,actedTurn=-1} end
  if state.form~="WISDOM" and state.form~="POWER" then state.form="POWER" end
  state.wisdomReady=tonumber(state.wisdomReady) or 0
  state.powerReady=tonumber(state.powerReady) or 0
  state.actedTurn=tonumber(state.actedTurn) or -1
  if u then state.unitID=u:GetID() end
  return state
end
local function Granted(p,id)
  if load(p,GRANTED,SAVE,0)==true then return true end
  local seed=PreGame.GetMapSeed and PreGame.GetMapSeed() or 0
  if tonumber(legacy.GetValue("CARTETHYIA_V01_GRANTED_"..tostring(seed).."_"..id))==1 then
    save(p,GRANTED,true,SAVE,0); return true
  end
  return false
end
local function SpawnPlot(p,plot)
  if not plot or plot:IsWater() or plot:IsMountain() or plot:IsImpassable() then return false end
  local owner=plot:GetOwner()
  if owner~=-1 and owner~=p:GetID() then return false end
  for i=0,plot:GetNumUnits()-1 do
    local u=plot:GetUnit(i)
    if u and not Dead(u) and (u:GetOwner()~=p:GetID()
      or (u:IsCombatUnit() and u:GetDomainType()~=DomainTypes.DOMAIN_AIR)) then return false end
  end
  return true
end
local function StartingPlot(p)
  local origin=p:GetStartingPlot()
  for u in p:Units() do
    local row=GameInfo.Units[u:GetUnitType()]
    if row and (row.Found==true or row.Found==1) then origin=u:GetPlot();break end
  end
  if not origin then return nil end
  local queue={{plot=origin,distance=0}}
  local seen={[origin:GetPlotIndex()]=true}
  local index=1
  while queue[index] do
    local step=queue[index];index=index+1
    if SpawnPlot(p,step.plot) then return step.plot end
    if step.distance<3 then
      for direction=0,5 do
        local plot=Map.PlotDirection(step.plot:GetX(),step.plot:GetY(),direction)
        if plot and not seen[plot:GetPlotIndex()] then
          seen[plot:GetPlotIndex()]=true
          queue[#queue+1]={plot=plot,distance=step.distance+1}
        end
      end
    end
  end
end
local function Flag(value) return value==true or value==1 end
local function Snapshot(u)
  local excluded={}
  for _,id in ipairs(powerPromotions) do excluded[id]=true end
  local result={experience=u:GetExperience(),level=u:GetLevel(),name=u:GetNameNoDesc(),promotions={}}
  if u.GetExperienceTimes100 and u.SetExperienceTimes100 then result.experience100=u:GetExperienceTimes100() end
  for promotion in GameInfo.UnitPromotions() do
    if u:IsHasPromotion(promotion.ID) and not excluded[promotion.ID]
      and (tonumber(promotion.RemoveAfterXTurns) or 0)<=0 and not Flag(promotion.AutoRemoveDoneTurn)
      and not Flag(promotion.RemoveAfterFullyHeal) and not Flag(promotion.RemoveWithLuaCheck) then
      result.promotions[#result.promotions+1]=promotion.ID
    end
  end
  return result
end
local function RestoreHero(p,hero,state)
  -- Reserve form/action state before setters that can trigger engine callbacks or fail.
  state.form="WISDOM"
  state.unitID=hero:GetID()
  state.actedTurn=Game.GetGameTurn()
  state.rebornTurn=Game.GetGameTurn()
  Store(p,state)
  hero:SetMoves(0)
  local snapshot=state.snapshot or {}
  if snapshot.experience100 and hero.SetExperienceTimes100 then hero:SetExperienceTimes100(snapshot.experience100)
  elseif snapshot.experience then hero:SetExperience(snapshot.experience) end
  if snapshot.level then hero:SetLevel(snapshot.level) end
  if snapshot.name and snapshot.name~="" then hero:SetName(snapshot.name) end
  for _,id in ipairs(snapshot.promotions or {}) do hero:SetHasPromotion(id,true) end
  hero:SetDamage(0)
  state.returnTurn=nil;state.snapshot=nil;state.reviveUnitID=nil
  Store(p,state)
end
local function EnsureHero(p,id,revive)
  local hero=FindHero(p)
  if hero then
    if not Granted(p,id) then save(p,GRANTED,true,SAVE,0) end
    local state=ReadState(p,hero)
    if state.reviveUnitID==hero:GetID() then RestoreHero(p,hero,state)
    elseif type(load(p,STATE,SAVE,0))~="table" then Store(p,state) end
    return hero
  end
  if Granted(p,id) then
    local state=ReadState(p)
    if not state.returnTurn then
      -- Pre-v1 dead saves have no death date. Migrate once, without shortening the wait.
      state.returnTurn=Game.GetGameTurn()+10;Store(p,state)
    end
    if not revive or Game.GetGameTurn()<state.returnTurn then return nil end
    local capital=p:GetCapitalCity()
    if not capital or capital:GetOwner()~=id then return nil end
    local plot=Map.GetPlot(capital:GetX(),capital:GetY())
    if not SpawnPlot(p,plot) then return nil end
    hero=p:InitUnit(unitType,plot:GetX(),plot:GetY(),GameInfoTypes.UNITAI_ATTACK)
    if hero then
      dying[id..":"..hero:GetID()]=nil
      -- Reserve the new identity before setters/events, so retrying cannot create a second unit.
      state.reviveUnitID=hero:GetID();state.unitID=hero:GetID();Store(p,state)
      RestoreHero(p,hero,state)
    end
    return hero
  end
  local plot=StartingPlot(p)
  if not plot then return nil end
  hero=p:InitUnit(unitType,plot:GetX(),plot:GetY(),GameInfoTypes.UNITAI_ATTACK)
  if hero then save(p,GRANTED,true,SAVE,0);Store(p,ReadState(p,hero,"WISDOM")) end
  return hero
end
local function Strength(p,state)
  local era=GameInfo.Eras[p:GetCurrentEra()]
  return era and R.Strength(era.Type,state.form)
end
local function ApplyForm(p,u,state)
  local n=Strength(p,state)
  if n and u:GetBaseCombatStrength()~=n then u:SetBaseCombatStrength(n) end
  for _,id in ipairs(powerPromotions) do
    local enabled=state.form=="POWER"
    if u:IsHasPromotion(id)~=enabled then u:SetHasPromotion(id,enabled) end
  end
  local identity=GameInfoTypes.PROMOTION_CARTETHYIA_IDENTITY
  if identity and not u:IsHasPromotion(identity) then u:SetHasPromotion(identity,true) end
  if state.rebornTurn==Game.GetGameTurn() then u:SetMoves(0) end
end
local function SetBuilding(city,id,on)
  local n=on and 1 or 0
  if city:GetNumRealBuilding(id)~=n then city:SetNumRealBuilding(id,n) end
end
local function OwnCity(p,u)
  if u:IsEmbarked() then return nil end
  local plot=u:GetPlot()
  local city=plot and plot:IsCity() and plot:GetPlotCity()
  if city and city:GetOwner()==p:GetID() then return city end
end
local function SyncPlayer(id,grant,revive)
  local p=Players[id]
  if not p or not p:IsAlive() then return end
  local enabled=IsPlayer(p)
  local hero=enabled and (grant and EnsureHero(p,id,revive) or FindHero(p))
  local wisdomCity
  if hero then
    local state=ReadState(p,hero)
    ApplyForm(p,hero,state)
    if state.form=="WISDOM" then wisdomCity=OwnCity(p,hero) end
  end
  local capital=enabled and p:GetCapitalCity()
  for city in p:Cities() do
    SetBuilding(city,baseBuilding,enabled)
    SetBuilding(city,capitalBuilding,enabled and capital and city:GetID()==capital:GetID())
    SetBuilding(city,wisdomBuilding,enabled and wisdomCity and city:GetID()==wisdomCity:GetID())
  end
end
local function SyncAll()
  if syncing or executing then return end
  syncing=true
  Protected("city synchronization",function()
    for id=0,(GameDefines.MAX_CIV_PLAYERS or GameDefines.MAX_MAJOR_CIVS)-1 do SyncPlayer(id,false) end
  end)
  syncing=false
end
local function Changed()
  LuaEvents.CartethyiaChanged()
  Events.SerialEventUnitInfoDirty()
end
local function PlayerTurn(id)
  if syncing or executing then return end
  syncing=true
  Protected("player synchronization",function()SyncPlayer(id,true,true)end)
  syncing=false
end
local function Initialize()
  if syncing then return end
  syncing=true
  Protected("initialization",function()
    for id=0,(GameDefines.MAX_CIV_PLAYERS or GameDefines.MAX_MAJOR_CIVS)-1 do SyncPlayer(id,true) end
  end)
  syncing=false
  Changed()
end
local function Project(city)
  if not city or city:GetOrderQueueLength()<1 then return nil end
  local kind,id=city:GetOrderFromQueue(0)
  local valid=false
  if kind==OrderTypes.ORDER_TRAIN then valid=city:CanTrain(id,1)
  elseif kind==OrderTypes.ORDER_CONSTRUCT then valid=city:CanConstruct(id,1)
  elseif kind==OrderTypes.ORDER_CREATE then valid=city:CanCreate(id,1) end
  if not valid or city:GetProductionNeeded()<=0 then return nil end
  return {kind=kind,id=id,cost=city:GetProductionNeeded(),progress=city:GetProduction()}
end
local function Ray(u,direction)
  return R.Ray(u:GetPlot(),direction,function(plot,d)
    return Map.PlotDirection(plot:GetX(),plot:GetY(),d)
  end,function(plot) return plot:GetX()..":"..plot:GetY() end)
end
local function Targets(p,u,direction)
  local result,preview,seen={},{},{}
  local team=p:GetTeam()
  for _,step in ipairs(Ray(u,direction)) do
    local plot=step.plot
    if plot:IsVisible(team,false) then
      preview[#preview+1]={x=plot:GetX(),y=plot:GetY(),percent=step.percent}
      for i=0,plot:GetNumUnits()-1 do
        local target=plot:GetUnit(i)
        if target and not Dead(target) and target:IsCombatUnit() and target:GetDomainType()~=DomainTypes.DOMAIN_AIR then
          local owner=Players[target:GetOwner()]
          local key=target:GetOwner()..":"..target:GetID()
          if owner and Teams[team]:IsAtWar(owner:GetTeam()) and not target:IsInvisible(team,false) and not seen[key] then
            seen[key]=true
            result[#result+1]={unit=target,damage=R.Damage(target:GetMaxHitPoints(),step.distance)}
          end
        end
      end
    end
  end
  return result,preview
end
local function Context(p,u,direction)
  local city=OwnCity(p,u)
  local targets={}
  local hasDirection=type(direction)=="number" and direction%1==0 and direction>=0 and direction<=5
  if hasDirection then targets=Targets(p,u,direction) end
  return {
    moves=u:MovesLeft(),attacked=u:GetNumAttacksMadeThisTurn()>0,
    embarked=u:IsEmbarked(),busy=u.IsBusy and u:IsBusy(),
    city=city~=nil,production=Project(city)~=nil,direction=hasDirection,targets=#targets>0
  }
end
local function Access(playerID,uid)
  local p=Players[playerID]
  local u=p and p:GetUnitByID(uid)
  if not IsPlayer(p) or not IsHero(u) or Dead(u) then return nil,nil,Reason("NOT_HERO") end
  return p,u
end
local function Active(p)
  return not endingTurn and p:GetID()==Game.GetActivePlayer() and p:IsTurnActive()
end
local function Can(p,u,state,action,direction)
  if not Active(p) then return false,Reason("NOT_TURN") end
  if executing then return false,Reason("BUSY") end
  if not Strength(p,state) then return false,Reason("UNSUPPORTED_ERA") end
  return R.CanAct(state,Context(p,u,direction),action,Game.GetGameTurn())
end
local function CanPower(p,u,state)
  local why=Reason("NO_TARGET")
  for direction=0,5 do
    local yes,reason=Can(p,u,state,"POWER",direction)
    if yes then return true,reason end
    why=reason
  end
  return false,why
end
local function Query(playerID,uid,out)
  local p,u,reason=Access(playerID,uid)
  out.valid=p~=nil
  if not p then out.switchReason=reason;out.wisdomReason=reason;out.powerReason=reason;return end
  local state=ReadState(p,u)
  out.form=state.form;out.strength=Strength(p,state) or 0
  out.wisdomRemaining=math.max(0,state.wisdomReady-Game.GetGameTurn())
  out.powerRemaining=math.max(0,state.powerReady-Game.GetGameTurn())
  out.canSwitch,out.switchReason=Can(p,u,state,"SWITCH")
  out.canWisdom,out.wisdomReason=Can(p,u,state,"WISDOM")
  out.canPower,out.powerReason=CanPower(p,u,state)
end
local function Preview(playerID,uid,direction,out)
  local p,u,reason=Access(playerID,uid)
  out.valid=false;out.plots={};out.targets=0;out.reason=reason
  if not p then return end
  out.valid,out.reason=Can(p,u,ReadState(p,u),"POWER",direction)
  local targets,plots=Targets(p,u,direction)
  out.targets=#targets;out.plots=plots
end
local function CountProduction(p,city,project)
  if project.kind==OrderTypes.ORDER_CONSTRUCT then return city:GetNumRealBuilding(project.id) end
  if project.kind==OrderTypes.ORDER_CREATE then return Teams[p:GetTeam()]:GetProjectCount(project.id) end
  local count=0
  for unit in p:Units() do if unit:GetUnitType()==project.id then count=count+1 end end
  return count
end
local function CompleteProduction(p,city)
  local project=Project(city)
  if not project then return false end
  local counted,before=Protected("production preflight",function()return CountProduction(p,city,project)end)
  if not counted then return false end
  completion={player=p:GetID(),city=city:GetID(),kind=project.kind,id=project.id,confirmed=false}
  -- PopOrder executes normal creation/rewards/events. Its return is not a success boolean.
  Protected("production completion",function()
    if project.progress<project.cost then city:SetProduction(project.cost) end
    -- Civ5's Lua wrapper reads bFinish/bChoose as integer flags (luaL_optinteger).
    city:PopOrder(0,1,1)
  end)
  local readOK,after=Protected("production verification",function()return CountProduction(p,city,project)end)
  local success=completion.confirmed or (readOK and after>before)
  completion=nil
  if success then return true end
  local restored,sameItem=Protected("production rollback",function()
    local kind,id=city:GetOrderFromQueue(0)
    if kind~=project.kind or id~=project.id then return false end
    city:SetProduction(project.progress)
    return true
  end)
  if readOK and restored and sameItem then return false end
  -- An uncertain/partially completed engine operation must not be replayed for free.
  print("Cartethyia: production result uncertain; retained skill reservation.")
  return nil
end
local function WisdomCooldown()
  local speed=GameInfo.GameSpeeds[Game.GetGameSpeedType()]
  return math.max(1,math.ceil(20*(speed and speed.ConstructPercent or 100)/100))
end
local function Command(playerID,uid,action,direction)
  local p,u=Access(playerID,uid)
  if not p then return end
  local state=ReadState(p,u)
  if not Can(p,u,state,action,direction) then return end
  executing=true
  Protected("hero action",function()
    local previous=ReadState(p,u)
    local moves=u:MovesLeft()
    local targets=action=="POWER" and Targets(p,u,direction) or nil
    if targets and #targets==0 then return end
    -- Reserve before engine callbacks, including city completion reward callbacks.
    R.Commit(state,action,Game.GetGameTurn(),WisdomCooldown());Store(p,state)
    u:SetMoves(0)
    if action=="WISDOM" then
      if CompleteProduction(p,OwnCity(p,u))==false then
        Store(p,previous);u:SetMoves(moves)
        return
      end
    elseif action=="POWER" then
      u:SetMadeAttack(true)
      for _,target in ipairs(targets) do
        if not Dead(target.unit) then
          local remaining=target.unit:GetMaxHitPoints()-target.unit:GetDamage()
          target.unit:ChangeDamage(math.min(target.damage,remaining),playerID,uid)
        end
      end
    end
    if not Dead(u) then ApplyForm(p,u,state);u:SetMoves(0) end
  end)
  completion=nil
  executing=false
  SyncAll();Changed()
end
local function Produced(kind,playerID,cityID,itemID)
  if completion and completion.player==playerID and completion.city==cityID and completion.kind==kind
    and (kind==OrderTypes.ORDER_TRAIN or completion.id==itemID) then completion.confirmed=true end
end
local function Prekill(playerID,uid,typeID)
  if typeID~=unitType then return end
  local p=Players[playerID]
  local u=p and p:GetUnitByID(uid)
  if IsPlayer(p) and IsHero(u) then
    local state=ReadState(p)
    if state.unitID and state.unitID~=uid then return end
    dying[playerID..":"..uid]=true
    save(p,GRANTED,true,SAVE,0)
    if not state.returnTurn then
      state.unitID=uid;state.returnTurn=Game.GetGameTurn()+10
      state.snapshot=Snapshot(u);state.reviveUnitID=nil
      Store(p,state)
    end
    for city in p:Cities() do SetBuilding(city,wisdomBuilding,false) end
  end
end
local function BlockCommand(playerID,uid,command)
  local p=Players[playerID];local u=p and p:GetUnitByID(uid)
  if IsHero(u) and (command==CommandTypes.COMMAND_GIFT or command==CommandTypes.COMMAND_DELETE or command==CommandTypes.COMMAND_UPGRADE) then return false end
  return true
end
local function BlockUpgrade(playerID,uid)
  local p=Players[playerID];return not IsHero(p and p:GetUnitByID(uid))
end
local function Add(events,name,callback)
  if events[name] then events[name].Add(callback) end
end
LuaEvents.CartethyiaQuery.Add(Query)
LuaEvents.CartethyiaPreview.Add(Preview)
LuaEvents.CartethyiaCommand.Add(Command)
Events.SequenceGameInitComplete.Add(Initialize)
GameEvents.PlayerDoTurn.Add(PlayerTurn)
GameEvents.PlayerCityFounded.Add(function(id)
  if syncing or executing then return end
  syncing=true
  Protected("city founding synchronization",function()SyncPlayer(id,true,false)end)
  syncing=false
end)
Add(GameEvents,"UnitSetXY",function(id,uid)local p=Players[id];if p and IsHero(p:GetUnitByID(uid)) then SyncAll() end end)
Add(GameEvents,"CityCaptureComplete",SyncAll)
Add(GameEvents,"CapitalChanged",SyncAll)
Add(GameEvents,"PlayerSetEra",function()SyncAll();Changed()end)
Add(GameEvents,"TeamSetEra",function()SyncAll();Changed()end)
Add(GameEvents,"UnitPrekill",Prekill)
Add(GameEvents,"CanDoCommand",BlockCommand)
Add(GameEvents,"CanHaveAnyUpgrade",BlockUpgrade)
Add(GameEvents,"CanHaveUpgrade",BlockUpgrade)
Add(GameEvents,"PlayerCanGiftUnit",function(major,minor,uid)return BlockUpgrade(major,uid)end)
Add(GameEvents,"CityTrained",function(p,c,u)Produced(OrderTypes.ORDER_TRAIN,p,c,u)end)
Add(GameEvents,"CityConstructed",function(p,c,b)Produced(OrderTypes.ORDER_CONSTRUCT,p,c,b)end)
Add(GameEvents,"CityCreated",function(p,c,j)Produced(OrderTypes.ORDER_CREATE,p,c,j)end)
Add(Events,"SerialEventCityInfoDirty",SyncAll)
Add(Events,"SerialEventUnitInfoDirty",SyncAll)
Add(Events,"ActivePlayerTurnEnd",function()endingTurn=true;Changed()end)
Add(Events,"ActivePlayerTurnStart",function()endingTurn=false;SyncAll();Changed()end)
Add(Events,"GameplaySetActivePlayer",function()endingTurn=false;SyncAll();Changed()end)
print("Cartethyia v1.0: dual-form lifecycle controller loaded.")
