-- Real Lua 5.1 smoke test. Only the unavailable Civ5 engine boundary is simulated.
-- Catches wrong command payloads, stale callbacks, hidden-map leaks and UI cleanup.
local function read(path)
    local f = io.open(path, "r")
    assert(f, "missing UI feature file: " .. path)
    local value = f:read("*a"); f:close(); return value
end
read("UI/Cartethyia_Actions.lua")
local panelXML = read("UI/Cartethyia_Panel.xml")
local textXML = read("XML/Cartethyia_UIText.xml")
local function eventBus()
    return setmetatable({}, {__index = function(t, name)
        local callbacks = {}
        local e = setmetatable({Add = function(fn) callbacks[#callbacks + 1] = fn end}, {
            __call = function(_, ...) for _, fn in ipairs(callbacks) do fn(...) end end
        })
        rawset(t, name, e); return e
    end})
end
local Events, LuaEvents = eventBus(), eventBus()
local actions, commands, highlights = {}, {}, {}
local activePlayer = 0
local hero = {GetOwner = function() return 0 end, GetID = function() return 9 end}
local selected = hero
local state = {valid=true, form="WISDOM", strength=18, wisdomRemaining=7, powerRemaining=0,
    canSwitch=true, switchReason="TXT_KEY_CARTETHYIA_REASON_READY",
    canWisdom=false, wisdomReason="TXT_KEY_CARTETHYIA_REASON_COOLDOWN",
    canPower=false, powerReason="TXT_KEY_CARTETHYIA_REASON_WRONG_FORM"}
local preview = {valid=true, reason="TXT_KEY_CARTETHYIA_REASON_READY", targets=2,
    plots={{x=4,y=5,percent=70},{x=5,y=5,percent=60}}}
LuaEvents.CartethyiaQuery.Add(function(playerID, unitID, out)
    assert(playerID == 0 and unitID == 9, "query must address the selected hero")
    for k,v in pairs(state) do out[k]=v end
end)
LuaEvents.CartethyiaPreview.Add(function(playerID, unitID, direction, out)
    assert(playerID == 0 and unitID == 9 and direction >= 0 and direction <= 5)
    for k,v in pairs(preview) do out[k]=v end
end)
LuaEvents.CartethyiaCommand.Add(function(...) commands[#commands+1]={...} end)
LuaEvents.UnitPanelActionAddin.Add(function(a) actions[a.Name]=a end)
Events.SerialEventHexHighlight.Add(function(hex, on, color, style)
    highlights[#highlights+1]={hex=hex,on=on,color=color,style=style}
end)
local translations = {}
local english = assert(textXML:match("<Language_en_US>(.-)</Language_en_US>"))
for key, value in english:gmatch('<Row Tag="([^"]+)"><Text>(.-)</Text></Row>') do translations[key]=value end
local function localize(key, ...)
    assert(translations[key], "UI localization is missing: " .. tostring(key))
    local args={...}
    return translations[key]:gsub("{(%d+)[^}]*}", function(i) return tostring(args[tonumber(i)]) end)
end
for key in panelXML:gmatch('String="([^"]+)"') do assert(translations[key], "untranslated XML label: "..key) end
for _, language in ipairs({"zh_CN", "zh_Hant_HK"}) do
    local content = assert(textXML:match("<Language_"..language..">(.-)</Language_"..language..">"))
    for key in pairs(translations) do assert(content:find('Tag="'..key..'"',1,true), language.." missing "..key) end
end
local controls = {}
for id in panelXML:gmatch('ID="([^"]+)"') do
    controls[id]={callbacks={}, hidden=false, disabled=false}
    local c=controls[id]
    function c:SetText(v) self.text=v end
    function c:SetHide(v) self.hidden=v end
    function c:SetDisabled(v) self.disabled=v end
    function c:SetAlpha(v) self.alpha=v end
    function c:SetToolTipString(v) self.tooltip=v end
    function c:SetSizeY(v) self.height=v end
    function c:CalculateSize() end
    function c:ReprocessAnchoring() end
    function c:RegisterCallback(kind, fn) self.callbacks[kind]=fn end
end
setmetatable(controls, {__index=function(_, k) error("UI control is absent from XML: "..k) end})
local mouse={eLClick=1,eRClick=2,eMouseEnter=3,eMouseExit=4}
local function environment()
    return setmetatable({Events=Events, LuaEvents=LuaEvents, Mouse=mouse,
        Game={GetActivePlayer=function() return activePlayer end},
        UI={GetHeadSelectedUnit=function() return selected end},
        Locale={ConvertTextKey=localize}, Controls=controls,
        ContextPtr={SetInputHandler=function(self,fn) self.input=fn end},
        KeyEvents={KeyDown=1}, Keys={VK_ESCAPE=27},
        Vector2=function(x,y) return {x=x,y=y} end,
        Vector4=function(x,y,z,w) return {x=x,y=y,z=z,w=w} end,
        ToHexFromGrid=function(p) return {x=p.x+1000,y=p.y+2000} end,
        DirectionTypes={DIRECTION_NORTHEAST=0,DIRECTION_EAST=1,DIRECTION_SOUTHEAST=2,
            DIRECTION_SOUTHWEST=3,DIRECTION_WEST=4,DIRECTION_NORTHWEST=5},
        include=function() end,
    }, {__index=_G})
end
local function loadContext(path)
    local chunk, err=loadfile(path); assert(chunk,err)
    local env=environment(); setfenv(chunk,env); chunk(); return env
end
loadContext("UI/Cartethyia_Actions.lua")
local panel=loadContext("UI/Cartethyia_Panel.lua")
local switch=assert(actions.CARTETHYIA_SWITCH)
local wisdom=assert(actions.CARTETHYIA_WISDOM)
local power=assert(actions.CARTETHYIA_POWER)
local count=0; for _ in pairs(actions) do count=count+1 end; assert(count==3)
assert(switch.Condition(switch,hero) and not switch.Disabled(switch,hero))
assert(wisdom.Disabled(wisdom,hero) and power.Disabled(power,hero))
assert(switch.ToolTip(switch,hero):find("7",1,true), "tooltip must show current cooldown")
switch.Action(switch,hero,mouse.eRClick); assert(#commands==0, "right click must not issue command")
switch.Action(switch,hero,mouse.eLClick)
assert(#commands==1 and commands[1][1]==0 and commands[1][2]==9 and commands[1][3]=="SWITCH")
state.canSwitch=false; state.switchReason="TXT_KEY_CARTETHYIA_REASON_ACTED"
switch.Action(switch,hero,mouse.eLClick); assert(#commands==1, "callback must re-query availability")
state.canWisdom=true
wisdom.Action(wisdom,hero,mouse.eLClick)
assert(#commands==2 and commands[2][3]=="WISDOM")
state.form="POWER"; state.canPower=true; state.canWisdom=false
state.powerReason="TXT_KEY_CARTETHYIA_REASON_READY"
LuaEvents.CartethyiaChanged()
assert(not controls.CartethyiaPanel.hidden)
assert(controls.FormLabel.text:find("Power",1,true) and controls.FormLabel.text:find("18",1,true))
power.Action(power,hero,mouse.eRClick)
assert(controls.DirectionBox.hidden and #commands==2)
power.Action(power,hero,mouse.eLClick)
assert(not controls.DirectionBox.hidden and #commands==2, "power action opens picker without firing")
controls.DirectionNE.callbacks[mouse.eMouseEnter]()
assert(#highlights==2 and highlights[1].hex.x==1004 and highlights[1].hex.y==2005)
assert(highlights[2].hex.x==1005, "preview must use only returned visible plots")
assert(controls.PreviewLabel.text:find("2",1,true))
controls.DirectionNE.callbacks[mouse.eLClick]()
assert(#commands==3 and commands[3][3]=="POWER" and commands[3][4]==0)
assert(controls.DirectionBox.hidden and highlights[#highlights].on==false)
power.Action(power,hero,mouse.eLClick)
preview.valid=false; preview.reason="TXT_KEY_CARTETHYIA_REASON_NO_TARGET"; preview.targets=0
controls.DirectionE.callbacks[mouse.eLClick]()
assert(#commands==3 and controls.PreviewLabel.text:find("target",1,true), "empty direction must explain why")
preview.valid=true; preview.reason="TXT_KEY_CARTETHYIA_REASON_READY"; preview.targets=2
controls.DirectionE.callbacks[mouse.eMouseEnter]()
controls.CloseDirections.callbacks[mouse.eLClick]()
assert(controls.DirectionBox.hidden and highlights[#highlights].on==false)
power.Action(power,hero,mouse.eLClick)
Events.ActivePlayerTurnEnd()
controls.DirectionNE.callbacks[mouse.eLClick]()
power.Action(power,hero,mouse.eLClick)
assert(#commands==3 and controls.DirectionBox.hidden, "turn end must block stale callbacks")
Events.ActivePlayerTurnStart()
power.Action(power,hero,mouse.eLClick)
selected=nil; Events.UnitSelectionChanged(0,9,0,0,0,false)
assert(controls.CartethyiaPanel.hidden and controls.DirectionBox.hidden)
power.Action(power,hero,mouse.eLClick); assert(#commands==3, "stale unit action must be ignored")
selected=hero; Events.SerialEventUnitInfoDirty()
power.Action(power,hero,mouse.eLClick)
Events.GameplaySetActivePlayer(1,0); activePlayer=1
assert(controls.DirectionBox.hidden, "hotseat change cancels targeting")
activePlayer=0; Events.GameplaySetActivePlayer(0,1); Events.SerialEventUnitInfoDirty()
Events.SerialEventEnterCityScreen(); assert(controls.CartethyiaPanel.hidden)
Events.SerialEventExitCityScreen(); assert(not controls.CartethyiaPanel.hidden)
power.Action(power,hero,mouse.eLClick)
assert(panel.ContextPtr.input(1,27,0)==true and controls.DirectionBox.hidden)
state.valid=false; LuaEvents.CartethyiaChanged(); assert(controls.CartethyiaPanel.hidden)
state.valid=true; Events.ActivePlayerTurnStart()
local directionCases={{"DirectionNE",0},{"DirectionE",1},{"DirectionSE",2},
    {"DirectionSW",3},{"DirectionW",4},{"DirectionNW",5}}
for _, case in ipairs(directionCases) do
    local before=#commands
    power.Action(power,hero,mouse.eLClick)
    controls[case[1]].callbacks[mouse.eMouseEnter]()
    controls[case[1]].callbacks[mouse.eLClick]()
    assert(#commands==before+1 and commands[#commands][4]==case[2], "wrong command direction: "..case[1])
end
print("PASS: UI - commands, live state, three languages, six-direction preview, turn/selection cleanup")
