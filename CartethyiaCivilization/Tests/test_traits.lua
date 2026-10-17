local path = "Lua/Cartethyia_Rules.lua"
local file = io.open(path, "r")
assert(file, "missing dual-form rule module")
file:close()
dofile(path)
local R = CartethyiaRules
local eras = {"ANCIENT","CLASSICAL","MEDIEVAL","RENAISSANCE","INDUSTRIAL","MODERN","WORLDWAR","POSTMODERN","INFORMATION","FUTURE"}
local power = {30,40,55,75,100,130,170,220,300,400}
for i,era in ipairs(eras) do
    assert(R.Strength("ERA_"..era,"POWER")==power[i])
    assert(R.Strength("ERA_"..era,"WISDOM")==power[i]/5)
end
assert(R.Strength("UNSUPPORTED", "POWER")==nil)
local state = {form="WISDOM", wisdomReady=0, powerReady=0, actedTurn=-1}
local ctx = {moves=60, attacked=false, city=true, production=true, direction=true, targets=true}
assert(R.CanAct(state,ctx,"WISDOM",10))
R.Commit(state,"WISDOM",10,20)
assert(state.wisdomReady==30 and not R.Ready(state,"WISDOM",29) and R.Ready(state,"WISDOM",30))
assert(not R.CanAct(state,ctx,"SWITCH",10))
assert(R.CanAct(state,ctx,"SWITCH",11))
R.Commit(state,"SWITCH",11,20)
assert(state.form=="POWER" and state.wisdomReady==30)
assert(not R.CanAct(state,ctx,"POWER",11))
assert(R.CanAct(state,ctx,"POWER",12))
R.Commit(state,"POWER",12,20)
assert(state.powerReady==17 and not R.Ready(state,"POWER",16))
ctx.attacked=true
assert(not R.CanAct(state,ctx,"SWITCH",13))
ctx.attacked=false; ctx.moves=0
assert(not R.CanAct(state,ctx,"SWITCH",13))
ctx.moves=60
assert(R.CanAct(state,ctx,"SWITCH",13))
R.Commit(state,"SWITCH",13,20)
assert(state.form=="WISDOM" and state.powerReady==17)
assert(not R.CanAct(state,ctx,"WISDOM",29))
assert(R.CanAct(state,ctx,"WISDOM",30))
ctx.city=false; assert(not R.CanAct(state,ctx,"WISDOM",30)); ctx.city=true
ctx.production=false; assert(not R.CanAct(state,ctx,"WISDOM",30))
assert(R.Damage(200,1)==140 and R.Damage(100,2)==60 and R.Damage(100,3)==50)
local ray=R.Ray(0,0,function(p,d) if p<2 then return p+1 end end)
assert(#ray==2 and ray[2].distance==2)
ray=R.Ray(0,0,function(p,d) return (p+1)%2 end)
assert(#ray==1 and ray[1].plot==1)
assert(#R.Ray(0,6,function() error("invalid direction must not query") end)==0)
print("PASS: Lua rules - ten eras, shared actions, persistent cooldowns, boundaries and damage")
