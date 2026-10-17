include("FLuaVector")

local turnEnded, cityScreen, directionsOpen = false, false, false
local selectedPlayer, selectedUnit, selectedForm
local highlighted = {}
local highlightColor = Vector4(1.0, 0.72, 0.18, 0.8)
local highlightStyle = "GUHB"
local directions = {
    {control="DirectionNE", value=DirectionTypes.DIRECTION_NORTHEAST},
    {control="DirectionE", value=DirectionTypes.DIRECTION_EAST},
    {control="DirectionSE", value=DirectionTypes.DIRECTION_SOUTHEAST},
    {control="DirectionSW", value=DirectionTypes.DIRECTION_SOUTHWEST},
    {control="DirectionW", value=DirectionTypes.DIRECTION_WEST},
    {control="DirectionNW", value=DirectionTypes.DIRECTION_NORTHWEST},
}

local function Text(key, ...) return Locale.ConvertTextKey(key, ...) end

local function ClearPreview()
    for _, hex in ipairs(highlighted) do
        Events.SerialEventHexHighlight(hex, false, highlightColor, highlightStyle)
    end
    highlighted = {}
end

local function CloseDirections()
    directionsOpen = false
    ClearPreview()
    Controls.DirectionBox:SetHide(true)
    Controls.CartethyiaPanel:SetSizeY(236)
end

local function QuerySelected()
    local unit = UI.GetHeadSelectedUnit()
    local state = {valid=false}
    if unit and unit:GetOwner() == Game.GetActivePlayer() then
        LuaEvents.CartethyiaQuery(unit:GetOwner(), unit:GetID(), state)
    end
    return state, unit
end

local function Reason(state, field)
    if turnEnded then return Text("TXT_KEY_CARTETHYIA_REASON_NOT_TURN") end
    return Text(state[field] or "TXT_KEY_CARTETHYIA_REASON_UNAVAILABLE")
end

local function Refresh()
    local state, unit = QuerySelected()
    if not state.valid or cityScreen then
        CloseDirections()
        Controls.CartethyiaPanel:SetHide(true)
        selectedPlayer, selectedUnit, selectedForm = nil, nil, nil
        return
    end
    local playerID, unitID = unit:GetOwner(), unit:GetID()
    if selectedPlayer ~= playerID or selectedUnit ~= unitID or selectedForm ~= state.form then CloseDirections() end
    selectedPlayer, selectedUnit, selectedForm = playerID, unitID, state.form
    if turnEnded or not state.canPower then CloseDirections() end
    local form = state.form == "POWER" and "POWER" or "WISDOM"
    Controls.CartethyiaPanel:SetHide(false)
    Controls.FormLabel:SetText(Text("TXT_KEY_CARTETHYIA_UI_FORM_STRENGTH", Text("TXT_KEY_CARTETHYIA_UI_FORM_" .. form), state.strength or 0))
    Controls.SwitchStatus:SetText(Text("TXT_KEY_CARTETHYIA_UI_SWITCH_STATUS", Reason(state, "switchReason")))
    Controls.WisdomStatus:SetText(Text("TXT_KEY_CARTETHYIA_UI_SKILL_STATUS", Text("TXT_KEY_CARTETHYIA_UI_WISDOM"), state.wisdomRemaining or 0, Reason(state, "wisdomReason")))
    Controls.PowerStatus:SetText(Text("TXT_KEY_CARTETHYIA_UI_SKILL_STATUS", Text("TXT_KEY_CARTETHYIA_UI_POWER"), state.powerRemaining or 0, Reason(state, "powerReason")))
    Controls.SwitchStatus:SetToolTipString(Text("TXT_KEY_CARTETHYIA_UI_HELP_SWITCH"))
    Controls.WisdomStatus:SetToolTipString(Text("TXT_KEY_CARTETHYIA_UI_HELP_WISDOM"))
    Controls.PowerStatus:SetToolTipString(Text("TXT_KEY_CARTETHYIA_UI_HELP_POWER"))
end

local function Preview(direction)
    ClearPreview()
    local state, unit = QuerySelected()
    if not directionsOpen or turnEnded or cityScreen or not state.valid or not state.canPower or
        unit:GetOwner() ~= selectedPlayer or unit:GetID() ~= selectedUnit then
        CloseDirections()
        return nil
    end
    local out = {valid=false, reason="TXT_KEY_CARTETHYIA_REASON_UNAVAILABLE", plots={}, targets=0}
    LuaEvents.CartethyiaPreview(unit:GetOwner(), unit:GetID(), direction, out)
    -- The controller has already filtered out every invisible plot and target.
    for _, plot in ipairs(out.plots or {}) do
        local hex = ToHexFromGrid(Vector2(plot.x, plot.y))
        Events.SerialEventHexHighlight(hex, true, highlightColor, highlightStyle)
        highlighted[#highlighted + 1] = hex
    end
    if out.valid then
        Controls.PreviewLabel:SetText(Text("TXT_KEY_CARTETHYIA_UI_PREVIEW", out.targets or 0))
    else
        Controls.PreviewLabel:SetText(Text(out.reason or "TXT_KEY_CARTETHYIA_REASON_UNAVAILABLE"))
    end
    return out, unit
end

local function OpenDirections(playerID, unitID)
    Refresh()
    local state, unit = QuerySelected()
    if not state.valid or not state.canPower or turnEnded or cityScreen then return end
    if playerID ~= nil and (unit:GetOwner() ~= playerID or unit:GetID() ~= unitID) then return end
    directionsOpen = true
    Controls.DirectionBox:SetHide(false)
    Controls.CartethyiaPanel:SetSizeY(462)
    Controls.PreviewLabel:SetText(Text("TXT_KEY_CARTETHYIA_UI_DIRECTION_HINT"))
end

for _, definition in ipairs(directions) do
    local direction = definition.value
    local button = Controls[definition.control]
    button:RegisterCallback(Mouse.eMouseEnter, function() Preview(direction) end)
    button:RegisterCallback(Mouse.eMouseExit, function()
        ClearPreview()
        if directionsOpen then Controls.PreviewLabel:SetText(Text("TXT_KEY_CARTETHYIA_UI_DIRECTION_HINT")) end
    end)
    button:RegisterCallback(Mouse.eLClick, function()
        local out, unit = Preview(direction)
        if out and out.valid then
            local playerID, unitID = unit:GetOwner(), unit:GetID()
            CloseDirections()
            LuaEvents.CartethyiaCommand(playerID, unitID, "POWER", direction)
            Refresh()
        end
    end)
end

Controls.CloseDirections:RegisterCallback(Mouse.eLClick, CloseDirections)
ContextPtr:SetInputHandler(function(message, key)
    if message == KeyEvents.KeyDown and key == Keys.VK_ESCAPE and directionsOpen then
        CloseDirections()
        return true
    end
    return false
end)

LuaEvents.CartethyiaOpenDirections.Add(OpenDirections)
LuaEvents.CartethyiaChanged.Add(function() ClearPreview(); Refresh() end)
Events.SerialEventUnitInfoDirty.Add(Refresh)
Events.UnitSelectionChanged.Add(function() CloseDirections(); Refresh() end)
Events.ActivePlayerTurnEnd.Add(function() turnEnded = true; CloseDirections(); Refresh() end)
Events.ActivePlayerTurnStart.Add(function() turnEnded = false; Refresh() end)
Events.GameplaySetActivePlayer.Add(function()
    turnEnded = false
    CloseDirections()
    Controls.CartethyiaPanel:SetHide(true)
    selectedPlayer, selectedUnit, selectedForm = nil, nil, nil
end)
Events.SerialEventEnterCityScreen.Add(function() cityScreen = true; CloseDirections(); Refresh() end)
Events.SerialEventExitCityScreen.Add(function() cityScreen = false; Refresh() end)
Refresh()
