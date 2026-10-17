-- Loaded by SP's UnitPanelAddin. All gameplay state belongs to the controller.
local turnEnded = false
local function Text(key, ...)
    return Locale.ConvertTextKey(key, ...)
end

local function Query(unit)
    local out = {valid=false}
    if not unit or unit:GetOwner() ~= Game.GetActivePlayer() then return out end
    LuaEvents.CartethyiaQuery(unit:GetOwner(), unit:GetID(), out)
    return out
end

local function Reason(state, field)
    if turnEnded then return "TXT_KEY_CARTETHYIA_REASON_NOT_TURN" end
    return state[field] or "TXT_KEY_CARTETHYIA_REASON_UNAVAILABLE"
end

local definitions = {
    {name="SWITCH", can="canSwitch", reason="switchReason", icon=0},
    {name="WISDOM", can="canWisdom", reason="wisdomReason", icon=1},
    {name="POWER", can="canPower", reason="powerReason", icon=2},
}

for _, definition in ipairs(definitions) do
    local d = definition
    local action = {
        Name = "CARTETHYIA_" .. d.name,
        OrderPriority = 200,
        PortraitIndex = d.icon,
        IconAtlas = "CARTETHYIA_ACTION_ATLAS",
        Title = function(_, unit)
            local state = Query(unit)
            if d.name == "SWITCH" then
                local destination = state.form == "POWER" and "WISDOM" or "POWER"
                return Text("TXT_KEY_CARTETHYIA_UI_SWITCH_TO", Text("TXT_KEY_CARTETHYIA_UI_FORM_" .. destination))
            end
            return Text("TXT_KEY_CARTETHYIA_UI_" .. d.name)
        end,
        Condition = function(_, unit) return Query(unit).valid == true end,
        Disabled = function(_, unit)
            local state = Query(unit)
            return turnEnded or not state.valid or not state[d.can]
        end,
        ToolTip = function(_, unit)
            local state = Query(unit)
            local form = state.form == "POWER" and "POWER" or "WISDOM"
            return Text("TXT_KEY_CARTETHYIA_UI_HELP_" .. d.name) .. "[NEWLINE][NEWLINE]" ..
                Text("TXT_KEY_CARTETHYIA_UI_TOOLTIP", Text("TXT_KEY_CARTETHYIA_UI_FORM_" .. form),
                    state.strength or 0, state.wisdomRemaining or 0, state.powerRemaining or 0,
                    Text(Reason(state, d.reason)))
        end,
        Action = function(_, unit, click)
            if click ~= Mouse.eLClick or turnEnded or not unit then return end
            local selected = UI.GetHeadSelectedUnit()
            if not selected or selected:GetOwner() ~= unit:GetOwner() or selected:GetID() ~= unit:GetID() then return end
            local state = Query(unit)
            if not state.valid or not state[d.can] then return end
            if d.name == "POWER" then
                LuaEvents.CartethyiaOpenDirections(unit:GetOwner(), unit:GetID())
            else
                LuaEvents.CartethyiaCommand(unit:GetOwner(), unit:GetID(), d.name, nil)
            end
        end,
    }
    LuaEvents.UnitPanelActionAddin(action)
end

Events.ActivePlayerTurnEnd.Add(function() turnEnded = true end)
Events.ActivePlayerTurnStart.Add(function() turnEnded = false end)
Events.GameplaySetActivePlayer.Add(function() turnEnded = false end)
