-- Pure Lua 5.1 rules shared by the controller and offline tests.
CartethyiaRules = {}
local R = CartethyiaRules
local strength = {
  ERA_ANCIENT=30, ERA_CLASSICAL=40, ERA_MEDIEVAL=55,
  ERA_RENAISSANCE=75, ERA_INDUSTRIAL=100, ERA_MODERN=130,
  ERA_WORLDWAR=170, ERA_POSTMODERN=220, ERA_INFORMATION=300, ERA_FUTURE=400
}
local function reason(name) return "TXT_KEY_CARTETHYIA_REASON_" .. name end
function R.Strength(era, form)
  local value = strength[era]
  if not value then return nil end
  return form == "POWER" and value or value / 5
end
function R.Ready(state, action, turn)
  if action == "WISDOM" then return turn >= (state.wisdomReady or 0) end
  if action == "POWER" then return turn >= (state.powerReady or 0) end
  return true
end
function R.CanAct(state, ctx, action, turn)
  if ctx.embarked then return false, reason("EMBARKED") end
  if ctx.busy then return false, reason("BUSY") end
  if ctx.attacked then return false, reason("ATTACKED") end
  if state.actedTurn == turn then return false, reason("ACTED") end
  if ctx.moves <= 0 then return false, reason("NO_MOVES") end
  if action == "SWITCH" then return true, reason("READY") end
  if action ~= "WISDOM" and action ~= "POWER" then return false, reason("UNAVAILABLE") end
  if state.form ~= action then return false, reason("WRONG_FORM") end
  if not R.Ready(state,action,turn) then return false, reason("COOLDOWN") end
  if action == "WISDOM" then
    if not ctx.city then return false, reason("NO_CITY") end
    if not ctx.production then return false, reason("NO_PROJECT") end
  else
    if not ctx.direction then return false, reason("INVALID_DIRECTION") end
    if not ctx.targets then return false, reason("NO_TARGET") end
  end
  return true, reason("READY")
end
function R.Commit(state, action, turn, wisdomCooldown)
  if action == "SWITCH" then
    state.form = state.form == "POWER" and "WISDOM" or "POWER"
  elseif action == "WISDOM" then state.wisdomReady = turn + wisdomCooldown
  elseif action == "POWER" then state.powerReady = turn + 5 end
  state.actedTurn = turn
end
function R.Damage(maxHP, distance)
  return math.floor(maxHP * ({70,60,50})[distance] / 100)
end
function R.Ray(origin, direction, nextPlot, key)
  if type(direction) ~= "number" or direction % 1 ~= 0 or direction < 0 or direction > 5 then return {} end
  key = key or function(p) return p end
  local seen, result, plot = {[key(origin)]=true}, {}, origin
  for distance=1,3 do
    plot = nextPlot(plot, direction)
    if plot == nil or seen[key(plot)] then break end
    seen[key(plot)] = true
    result[#result+1] = {plot=plot, distance=distance, percent=({70,60,50})[distance]}
  end
  return result
end
