-- Execute the actual controller and SP SaveUtils; only Civ5 objects are mocked.
local saveUtils = "C:/Users/hunxi/Documents/My Games/Sid Meier's Civilization 5/MODS/(2) Super Power - Rise of Hegemony (v 10FF)-d3da5f3/Gameplay/Lua/Utility/SaveUtils.lua"
local function events()
  return setmetatable({}, {__index=function(t,k)
    local e={handlers={}}
    e.Add=function(fn) e.handlers[#e.handlers+1]=fn end
    setmetatable(e,{__call=function(self,...) local result; for _,fn in ipairs(self.handlers) do local r=fn(...); if r~=nil then result=r end end; return result end})
    rawset(t,k,e); return e
  end})
end
local function iter(list)
  local i=0; return function() repeat i=i+1 until not list[i] or not list[i].dead; return list[i] end
end
local function setup(existing, deadSave, options)
  options=options or {}
  Events=events(); GameEvents=events(); LuaEvents=events()
  GameInfoTypes={CIVILIZATION_CARTETHYIA=1,UNIT_CARTETHYIA=10,BUILDING_DUAL_RESONANCE=20,BUILDING_CARTETHYIA_CAPITAL=21,BUILDING_CARTETHYIA_WISDOM=22,UNITAI_ATTACK=0,
    PROMOTION_CARTETHYIA_WIND=30,PROMOTION_CARTETHYIA_AURA=31,PROMOTION_CARTETHYIA_FREE=32,PROMOTION_CARTETHYIA_SHIELD=33,PROMOTION_CARTETHYIA_UNYIELDING=34,PROMOTION_CARTETHYIA_IDENTITY=35}
  DomainTypes={DOMAIN_LAND=0,DOMAIN_SEA=1,DOMAIN_AIR=2}
  OrderTypes={ORDER_TRAIN=0,ORDER_CONSTRUCT=1,ORDER_CREATE=2,ORDER_MAINTAIN=3}
  CommandTypes={COMMAND_GIFT=1,COMMAND_DELETE=2,COMMAND_UPGRADE=3}
  local w={turn=options.turn or 0,active=0,plots={},nextID=100,created=0}
  Game={GetGameTurn=function()return w.turn end,GetActivePlayer=function()return w.active end,GetGameSpeedType=function()return 0 end}
  GameDefines={MAX_MAJOR_CIVS=2,MAX_CIV_PLAYERS=2,MOVE_DENOMINATOR=60}
  GameInfo={Eras={[0]={Type="ERA_ANCIENT"},[9]={Type="ERA_FUTURE"}},GameSpeeds={[0]={BuildPercent=100,ConstructPercent=100}},Units={[10]={Type="UNIT_CARTETHYIA",Class="UNITCLASS_CARTETHYIA"},[11]={Class="UNITCLASS_WARRIOR"},[12]={Class="UNITCLASS_SETTLER",Found=true}},Buildings={[40]={BuildingClass="BUILDINGCLASS_TEST"}},Projects={[50]={}}}
  GameInfo.UnitPromotions=function()return iter({{ID=30,Type="PROMOTION_CARTETHYIA_WIND"},{ID=31,Type="PROMOTION_CARTETHYIA_AURA"},{ID=32,Type="PROMOTION_CARTETHYIA_FREE"},{ID=33,Type="PROMOTION_CARTETHYIA_SHIELD"},{ID=34,Type="PROMOTION_CARTETHYIA_UNYIELDING"},{ID=35,Type="PROMOTION_CARTETHYIA_IDENTITY"},{ID=99,Type="PROMOTION_DRILL"},{ID=98,Type="PROMOTION_RAPID_MARCH",RemoveAfterXTurns=1},{ID=97,Type="PROMOTION_LOSE_SUPPLY",RemoveAfterFullyHeal=true}})end
  PreGame={GetMapSeed=function()return 123 end}
  Modding={OpenSaveData=function()return {GetValue=function()return nil end} end}
  Map={GetPlot=function(x,y)return w.plots[x..","..y] end,PlotDirection=function(x,y,d)
    local offsets={{1,0},{0,1},{-1,1},{-1,0},{0,-1},{1,-1}}
    return w.plots[(x+offsets[d+1][1])..","..(y+offsets[d+1][2])]
  end}
  Teams={[0]={IsAtWar=function(self,team)return team==1 end,GetProjectCount=function()return w.projects or 0 end},[1]={}}
  function w.plot(x,y)
    local p={x=x,y=y,units={},visible=true}
    function p:GetX()return self.x end; function p:GetY()return self.y end
    function p:IsCity()return self.city~=nil end; function p:GetPlotCity()return self.city end
    function p:GetNumUnits()return #self.units end; function p:GetUnit(i)return self.units[i+1] end
    function p:IsVisible()return self.visible end
    function p:GetPlotIndex()return self.x+100*self.y end
    function p:IsWater()return self.water or false end;function p:IsMountain()return self.mountain or false end
    function p:IsImpassable()return self.impassable or false end;function p:GetOwner()return self.city and self.city.owner or self.owner or -1 end
    w.plots[x..","..y]=p; return p
  end
  function w.unit(owner,p,hero)
    w.nextID=w.nextID+1
    local u={id=w.nextID,owner=owner,plot=p,hero=hero,moves=120,attacks=0,promotions={},damage=17,xp=45,strength=30,domain=0,combat=true}
    function u:GetID()return self.id end; function u:GetOwner()return self.owner end
    function u:GetUnitType()return self.typeID or (self.hero and 10 or 11) end; function u:GetPlot()return self.plot end
    function u:GetX()return self.plot.x end; function u:GetY()return self.plot.y end
    function u:GetBaseCombatStrength()return self.strength end; function u:SetBaseCombatStrength(n)self.strength=n end
    function u:SetHasPromotion(id,on)self.promotions[id]=on end; function u:IsHasPromotion(id)return self.promotions[id]==true end
    function u:MovesLeft()return self.moves end; function u:SetMoves(n)self.moves=n end; function u:FinishMoves()self.moves=0 end
    function u:GetNumAttacksMadeThisTurn()return self.attacks end; function u:SetMadeAttack(v)if v then self.attacks=self.attacks+1 end end
    function u:IsEmbarked()return self.embarked or false end; function u:IsBusy()return false end
    function u:IsDead()return self.dead or false end; function u:IsDelayedDeath()return self.dead or false end
    function u:GetDomainType()return self.domain end; function u:IsCombatUnit()return self.combat end
    function u:IsInvisible(team,debug)return self.invisible or false end
    function u:GetMaxHitPoints()return self.hp or 100 end; function u:GetDamage()return self.damage end
    function u:SetDamage(n)assert(type(n)=="number");self.damage=n end
    function u:GetExperience()return self.xp end;function u:SetExperience(n)assert(type(n)=="number");self.xp=n end
    function u:GetExperienceTimes100()return self.xp100 or self.xp*100 end
    function u:SetExperienceTimes100(n)assert(type(n)=="number");self.xp100=n;self.xp=math.floor(n/100) end
    function u:GetLevel()return self.level or 1 end;function u:SetLevel(n)assert(type(n)=="number");self.level=n end
    function u:GetNameNoDesc()return self.name or "" end;function u:SetName(n)assert(type(n)=="string");self.name=n end
    function u:ChangeDamage(n,player,id)self.damage=self.damage+n; self.source={player,id}; if self.damage>=self:GetMaxHitPoints() then self.dead=true end end
    p.units[#p.units+1]=u; Players[owner].units[#Players[owner].units+1]=u; return u
  end
  function w.city(owner,p)
    local c={owner=owner,plot=p,id=#Players[owner].cities,buildings={},queue={OrderTypes.ORDER_CONSTRUCT,40},progress=10,cost=100,allowed=true,pops=0}
    function c:GetOwner()return self.owner end; function c:GetID()return self.id end
    function c:GetX()return self.plot.x end; function c:GetY()return self.plot.y end; function c:Plot()return self.plot end
    function c:GetName()return "City" end; function c:IsCapital()return Players[self.owner].capital==self end
    function c:GetNumRealBuilding(id)return self.buildings[id] or 0 end
    function c:SetNumRealBuilding(id,n)self.buildings[id]=n end
    function c:GetOrderQueueLength()return self.queue and 1 or 0 end
    function c:GetOrderFromQueue()if self.queue then return self.queue[1],self.queue[2],0,false,false end end
    function c:CanConstruct()return self.allowed end; function c:CanTrain()return self.allowed end; function c:CanCreate()return self.allowed end
    function c:GetProduction()return self.progress end; function c:GetProductionNeeded()return self.cost end
    function c:SetProduction(n)self.progress=n end
    function c:PopOrder(i,finish,choose)
      -- The installed Civ5 Lua binding requires numeric flags, not Lua booleans.
      -- A permissive mock previously hid the in-game 'number expected' error.
      assert(type(i)=="number" and type(finish)=="number" and type(choose)=="number", "PopOrder expects numeric arguments")
      assert(i==0 and finish==1 and choose==1); self.pops=self.pops+1
      if self.fail then return end
      local kind,id=self.queue[1],self.queue[2]
      if kind==OrderTypes.ORDER_CONSTRUCT then self.buildings[id]=(self.buildings[id] or 0)+1
      elseif kind==OrderTypes.ORDER_CREATE then w.projects=(w.projects or 0)+1
      elseif kind==OrderTypes.ORDER_TRAIN then w.unit(self.owner,self.plot,false) end
      self.queue=nil; self.progress=0
    end
    p.city=c; Players[owner].cities[#Players[owner].cities+1]=c; return c
  end
  Players={}
  for id=0,1 do
    local p={id=id,units={},cities={},script="",era=0}
    function p:IsAlive()return true end; function p:IsMinorCiv()return false end; function p:IsBarbarian()return false end
    function p:IsHuman()return self.id==0 end; function p:IsTurnActive()return w.active==self.id end
    function p:GetID()return self.id end; function p:GetTeam()return self.id end
    function p:GetCivilizationType()return self.id==0 and 1 or 2 end
    function p:Units()return iter(self.units) end; function p:Cities()return iter(self.cities) end
    function p:GetCapitalCity()return self.capital end; function p:GetCurrentEra()return self.era end
    function p:GetStartingPlot()return self.start end
    function p:GetScriptData()return self.script end; function p:SetScriptData(v)self.script=v end
    function p:GetUnitByID(uid)for _,u in ipairs(self.units)do if u.id==uid and not u.dead then return u end end end
    function p:GetCityByID(cid)for _,c in ipairs(self.cities)do if c.id==cid then return c end end end
    function p:GetNumUnits()local n=0;for u in self:Units()do n=n+1 end;return n end
    function p:InitUnit(typeID,x,y,ai)
      assert(type(typeID)=="number" and type(x)=="number" and type(y)=="number" and type(ai)=="number")
      if w.failInit then return nil end
      w.created=w.created+1
      local unit=w.unit(self.id,Map.GetPlot(x,y),true)
      if w.configureCreated then w.configureCreated(unit) end
      return unit
    end
    Players[id]=p
  end
  for x=0,4 do w.plot(x,0) end
  w.capital=w.city(0,w.plots["0,0"]); Players[0].capital=w.capital
  w.second=w.city(0,w.plot(0,1))
  Players[0].start=w.plots["0,0"]
  if options.noCapital then
    Players[0].capital=nil;Players[0].cities={};w.capital.plot.city=nil;w.second.plot.city=nil
  end
  if options.prepare then options.prepare(w) end
  if existing then w.hero=w.unit(0,w.capital.plot,true);w.hero.promotions[99]=true end
  function include(name)
    if name=="SaveUtils" then dofile(saveUtils) else dofile("Lua/"..name..".lua") end
  end
  include("SaveUtils")
  if deadSave then save(Players[0],"START_UNIT_GRANTED",true,"CARTETHYIA_V02",0) end
  save(Players[0],"OTHER",42,"ANOTHER_MOD",0)
  dofile("Lua/Cartethyia_StartUnit.lua")
  Events.SequenceGameInitComplete()
  function w.findHero()for u in Players[0]:Units()do if u.hero then return u end end end
  w.hero=w.hero or w.findHero()
  function w.query()local out={};LuaEvents.CartethyiaQuery(0,w.hero.id,out);return out end
  function w.command(action,d)LuaEvents.CartethyiaCommand(0,w.hero.id,action,d)end
  function w.nextTurn()
    w.turn=w.turn+1
    for u in Players[0]:Units()do u.moves=180;u.attacks=0 end
    GameEvents.PlayerDoTurn(0);w.hero=w.findHero()
  end
  function w.reload()
    Events=events();GameEvents=events();LuaEvents=events()
    dofile("Lua/Cartethyia_StartUnit.lua");Events.SequenceGameInitComplete();w.hero=w.findHero()
  end
  function w.kill()
    local hero=w.hero
    GameEvents.UnitPrekill(0,hero.id,10,hero:GetX(),hero:GetY(),true,1)
    GameEvents.UnitPrekill(0,hero.id,10,hero:GetX(),hero:GetY(),false,1)
    hero.dead=true;w.hero=nil;return hero
  end
  return w
end

-- Removing capital-independent start selection must fail this regression.
local w=setup(false,false,{noCapital=true,prepare=function(world)
  local settler=world.unit(0,world.plots["2,0"],false);settler.typeID=12;settler.combat=false
end})
assert(w.created==1 and w.hero and w.hero:GetX()==2,"new game grants at the settler before any capital exists")
assert(w.query().form=="WISDOM" and w.hero.strength==6)
w.reload();GameEvents.PlayerDoTurn(0)
assert(w.created==1,"loading and first-turn callbacks cannot duplicate the start hero")

-- A military stack or an illegal tile must never be selected as a spawn slot.
w=setup(false,false,{noCapital=true,prepare=function(world)
  world.unit(0,world.plots["0,0"],false)
  world.plots["1,0"].water=true
end})
assert(w.hero and w.hero:GetX()==0 and w.hero:GetY()==1,"blocked start searches nearby passable land without moving the blocker")
assert(Players[0].units[1]:GetX()==0 and Players[0].units[1]:GetY()==0)
w=setup(false,false,{noCapital=true,prepare=function(world)world.failInit=true end})
assert(not w.hero and not load(Players[0],"START_UNIT_GRANTED","CARTETHYIA_V02",0),"failed creation must remain retryable")
w.failInit=false;w.nextTurn();assert(w.created==1 and w.hero,"next own turn retries the initial grant")

w=setup()
assert(w.created==1 and w.query().valid, "controller must expose the new hero service")
assert(w.query().form=="WISDOM" and w.hero.strength==6)
assert(w.capital.buildings[20]==1 and w.capital.buildings[21]==1 and w.capital.buildings[22]==1)
assert(w.second.buildings[20]==1 and w.second.buildings[21]==nil and w.second.buildings[22]==nil)
assert(load(Players[0],"OTHER","ANOTHER_MOD",0)==42, "other mod save namespace preserved")
w.command("SWITCH")
assert(w.query().form=="POWER" and w.hero.strength==30 and w.hero.moves==0)
assert(w.hero.damage==17 and w.hero.xp==45 and w.hero.promotions[31])
assert(w.capital.buildings[22]==0 and not w.query().canPower)
w.hero.moves=180;w.command("SWITCH");assert(w.query().form=="POWER", "no external moves refund bypass")
w.nextTurn();w.hero.attacks=1;w.command("SWITCH");assert(w.query().form=="POWER", "multiattack unit cannot switch after first attack")
w.hero.attacks=0;w.command("SWITCH");assert(w.query().form=="WISDOM" and not w.hero.promotions[31])
w.nextTurn();w.command("WISDOM")
assert(w.capital.pops==1 and w.capital.buildings[40]==1 and w.query().wisdomRemaining==20)
assert(w.hero.moves==0 and not w.query().canSwitch)
w.hero.moves=180;w.command("WISDOM");assert(w.capital.pops==1)
w.nextTurn();w.command("SWITCH");assert(w.query().wisdomRemaining==19)
Players[0].era=9;GameEvents.PlayerSetEra(0,9,false)
assert(w.hero.strength==400 and w.hero.damage==17)
Players[0].capital=w.second;GameEvents.CapitalChanged(0,w.second.id,w.capital.id)
assert(w.capital.buildings[21]==0 and w.second.buildings[21]==1)
w.nextTurn()
local enemy=w.unit(1,w.plots["1,0"],false); enemy.damage=0;enemy.hp=200
local invisible=w.unit(1,w.plots["1,0"],false);invisible.damage=0;invisible.invisible=true
local enemy2=w.unit(1,w.plots["2,0"],false);enemy2.damage=50
local friend=w.unit(0,w.plots["2,0"],false);friend.damage=0
local civilian=w.unit(1,w.plots["3,0"],false);civilian.combat=false;civilian.damage=0
local hidden=w.unit(1,w.plots["3,0"],false);hidden.damage=0;w.plots["3,0"].visible=false
w.command("POWER",0)
assert(enemy.damage==140 and enemy.source[1]==0 and enemy.source[2]==w.hero.id)
assert(enemy2.dead and invisible.damage==0 and friend.damage==0 and civilian.damage==0 and hidden.damage==0)
assert(w.query().powerRemaining==5 and w.hero.attacks==1 and w.hero.moves==0)
Events=events();GameEvents=events();LuaEvents=events()
dofile("Lua/Cartethyia_StartUnit.lua");Events.SequenceGameInitComplete()
assert(w.query().powerRemaining==5 and w.query().wisdomRemaining==18 and not w.query().canSwitch, "both cooldowns and spent actions survive actual serialization")
assert(GameEvents.CanDoCommand(0,w.hero.id,CommandTypes.COMMAND_GIFT)==false)
assert(GameEvents.PlayerCanGiftUnit(0,1,w.hero.id)==false)

-- Old living hero keeps identity/progression; serialized state survives reloading controller.
w=setup(true)
assert(w.created==0 and w.query().form=="POWER" and w.hero.promotions[99] and w.hero.damage==17)
w.command("SWITCH")
local serialized=Players[0].script
assert(type(serialized)=="string" and #serialized>0)
Events=events();GameEvents=events();LuaEvents=events()
dofile("Lua/Cartethyia_StartUnit.lua");Events.SequenceGameInitComplete()
assert(w.query().form=="WISDOM" and not w.query().canSwitch and w.created==0)
w.hero.plot=w.second.plot;GameEvents.UnitSetXY(0,w.hero.id,0,1)
assert(w.capital.buildings[22]==0 and w.second.buildings[22]==1)
GameEvents.UnitPrekill(0,w.hero.id,10,0,1,true,1)
assert(w.second.buildings[22]==0, "prekill clears local buff immediately")
w.hero.dead=true;GameEvents.PlayerDoTurn(0);assert(w.created==0)
w=setup(false,true);assert(w.created==0 and not w.hero,"dead old save must wait before respawning")

-- Failed completion leaves no free progress and no consumed cooldown.
w=setup();w.capital.fail=true;w.command("WISDOM")
assert(w.capital.progress==10 and w.query().wisdomRemaining==0 and w.hero.moves==120)
w.capital.fail=false;w.capital.queue={OrderTypes.ORDER_MAINTAIN,0};w.command("WISDOM")
assert(w.capital.pops==1 and w.query().wisdomRemaining==0)
w.capital.queue={OrderTypes.ORDER_CREATE,50};w.command("WISDOM")
assert(w.projects==1 and w.query().wisdomRemaining==20)

-- Ownership changes remove every foreign trait building immediately.
w=setup()
w.capital.owner=1;Players[1].cities={w.capital};Players[0].cities={w.second}
GameEvents.CityCaptureComplete(0,true,0,0,1,1,true)
assert(w.capital.buildings[20]==0 and w.capital.buildings[21]==0 and w.capital.buildings[22]==0)

-- An engine exception must not poison the synchronization guard for the session.
w=setup()
local setStrength=w.hero.SetBaseCombatStrength
w.hero.SetBaseCombatStrength=function(self,n) self.SetBaseCombatStrength=setStrength; error("injected strength failure") end
Players[0].era=9
assert(pcall(function()GameEvents.PlayerSetEra(0,9,false)end), "sync must contain callback exceptions")
GameEvents.PlayerSetEra(0,9,false)
assert(w.hero.strength==80, "sync guard must recover")

-- Partial damage is consumed, but the controller is usable on subsequent turns.
w=setup();w.command("SWITCH");w.nextTurn()
local first=w.unit(1,w.plots["1,0"],false);first.damage=0
local second=w.unit(1,w.plots["2,0"],false);second.damage=0
second.ChangeDamage=function()error("injected damage failure")end
assert(pcall(function()w.command("POWER",0)end), "action must contain callback exceptions")
assert(first.damage==70 and w.query().powerRemaining==5 and not w.query().canSwitch)
w.nextTurn();assert(w.query().canSwitch, "execution guard must recover without free damage replay")

-- Failure while adding production restores the uncompleted item's prior progress.
w=setup()
local setProduction=w.capital.SetProduction
w.capital.SetProduction=function(self,n)self.progress=n;self.SetProduction=setProduction;error("injected production failure")end
assert(pcall(function()w.command("WISDOM")end))
assert(w.capital.progress==10 and w.hero.moves==120 and w.query().wisdomRemaining==0)
w.command("WISDOM");assert(w.capital.buildings[40]==1 and w.query().wisdomRemaining==20)

-- The deadline is death turn + 10, survives serialization, and ignores duplicate death callbacks.
w=setup();w.command("WISDOM");w.nextTurn();w.command("SWITCH");w.nextTurn()
local target=w.unit(1,w.plots["1,0"],false);target.damage=0;w.command("POWER",0)
w.hero.xp=73;w.hero.xp100=7375;w.hero.level=4;w.hero.name="Cartethyia ' Dawn"
w.hero.promotions[99]=true;w.hero.promotions[98]=true;w.hero.promotions[97]=true
local fallen=w.kill()
assert(w.capital.buildings[22]==0,"death immediately removes the wisdom city bonus")
for i=3,6 do w.nextTurn();assert(not w.hero,"no resurrection before the deadline") end
GameEvents.UnitPrekill(0,fallen.id,10,0,0,false,1)
w.reload()
for i=7,11 do w.nextTurn();assert(not w.hero,"loading and the delayed prekill cannot shorten or extend the wait") end
w.turn=12;Players[0].era=9;Players[0].capital=w.second
w.reload();assert(not w.hero,"initialization must not resurrect even when already due")
GameEvents.PlayerCityFounded(0,0,1);assert(not w.findHero(),"city events cannot resurrect outside the owner turn callback")
GameEvents.PlayerDoTurn(1);assert(not w.findHero(),"other players cannot process this hero's deadline")
GameEvents.PlayerDoTurn(0);w.hero=w.findHero()
assert(w.created==2 and w.hero,"death on turn 2 returns on own turn 12")
assert(w.hero:GetX()==0 and w.hero:GetY()==1,"resurrection follows the current capital")
assert(w.query().form=="WISDOM" and w.hero.strength==80 and w.hero.damage==0,"resurrection restores full health and current-era wisdom strength")
assert(w.hero.xp==73 and w.hero.level==4 and w.hero.name=="Cartethyia ' Dawn" and w.hero.promotions[99],"resurrection retains name and earned progression")
assert(w.hero:GetExperienceTimes100()==7375,"the installed DLL's fractional XP survives resurrection")
assert(not w.hero.promotions[30] and not w.hero.promotions[31] and not w.hero.promotions[98] and not w.hero.promotions[97],"power and temporary promotions must not return")
assert(w.query().wisdomRemaining==8 and w.query().powerRemaining==0,"absolute cooldowns advance while dead")
assert(w.hero.moves==0 and not w.query().canSwitch,"the resurrection turn is spent")
GameEvents.UnitPrekill(0,fallen.id,10,0,0,false,1)
w.reload();GameEvents.PlayerDoTurn(0)
assert(w.created==2 and w.hero and w.hero.xp==73 and not w.query().canSwitch,"late death callbacks and reload cannot duplicate or reset the resurrected hero")
w.nextTurn();assert(w.query().canSwitch,"the revived hero can act on its following turn")
w.kill();for i=1,9 do w.nextTurn();assert(not w.hero)end
w.nextTurn();assert(w.hero and w.created==3,"each later death gets a fresh ten-turn wait")

-- A due resurrection waits for a genuinely available current capital; it never displaces units.
w=setup();w.kill();Players[0].capital=nil
for i=1,10 do w.nextTurn()end
assert(not w.hero,"no capital keeps the due resurrection pending")
Players[0].capital=w.capital;w.capital.owner=1;w.nextTurn()
assert(not w.hero,"a captured/stale capital reference is not a legal destination")
w.capital.owner=0
local blocker=w.unit(0,w.capital.plot,false);w.nextTurn()
assert(not w.hero and blocker:GetPlot()==w.capital.plot and not blocker.dead,"own military occupation delays without deleting or moving its unit")
w.reload();blocker.dead=true;w.failInit=true;w.nextTurn()
assert(not w.hero,"failed resurrection creation remains pending")
w.failInit=false;w.nextTurn();assert(w.hero and w.created==2,"clearing the destination retries the original due resurrection")

-- Dead legacy saves have no known death date; migrate once using the first observed turn.
w=setup(false,true,{turn=50});assert(not w.hero)
for i=1,4 do w.nextTurn();assert(not w.hero)end
w.reload()
for i=5,9 do w.nextTurn();assert(not w.hero,"legacy deadline does not restart after load")end
w.nextTurn();assert(w.hero and w.created==1 and w.query().form=="WISDOM","legacy migration at turn 50 returns on turn 60")
assert(load(Players[0],"OTHER","ANOTHER_MOD",0)==42,"lifecycle persistence preserves other mods' script data")

-- Reused engine IDs must not leave a new instance marked as the former dying unit.
w=setup();fallen=w.kill();w.nextID=fallen.id-1
for i=1,10 do w.nextTurn()end
assert(w.hero and w.query().valid and w.query().form=="WISDOM","reused unit IDs do not inherit the old death marker")

-- A partially restored engine object is reserved and cannot act or be cloned on retry.
w=setup();w.hero.xp=88;w.hero.xp100=8825;w.kill()
w.configureCreated=function(unit)
  local restore=unit.SetExperienceTimes100
  unit.SetExperienceTimes100=function(self,n)self.SetExperienceTimes100=restore;error("injected restoration failure")end
end
for i=1,10 do w.nextTurn()end
assert(w.created==2 and w.hero and w.hero.moves==0 and not w.query().canSwitch,"failed restoration remains reserved with no usable action")
w.reload();assert(w.created==2 and w.hero:GetExperienceTimes100()==8825,"reload retries restoration on the same object")
assert(w.hero.moves==0 and not w.query().canSwitch)
print("PASS: actual controller + SP SaveUtils: start grant, ten-turn lifecycle, progression, blockers, migration, actions and persistence")
