local AddonTable = select(2, ...)
local AddonName  = select(1, ...)

local tick = 1
local max_delay = 20

local playerGUID = UnitGUID("player")
local playerInfo = {["sex"] = "Their", ["name"] = "Someone"}
local MSG_CRITICAL_HIT = "%s's %s critically hit %s for %d damage!"
local MSG_CRITICAL_HIT_BEST = " %s previous highest was %d."
local channelID, channelName = GetChannelName("nvwow")
local localdb = {}

local defaults = {
  debug = 0,
	output = "print",
	highscores = {
    ["harming"] = {},
    ["healing"] = {}
  }
}

function getPIBG()
  local _, _, _, _, sexID, name, _ = GetPlayerInfoByGUID(playerGUID)
  if name ~= nil then
    local sex = {
       [2] = "His",
       [3] = "Her"
    }
    playerInfo = { ["name"] = name, ["sex"] = sex[sexID] }
    return true
  else
    return false
  end
end

function update_player_info(...)
  for i=1,max_delay do
    local ret = getPIBG()
    if ret then return end
  end
  C_Timer.After(tick, update_player_info)
end

function Critastic_OnLoad()
	local frame = CreateFrame("Frame")
  frame:RegisterEvent("ADDON_LOADED")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	frame:SetScript("OnEvent", function(self, event, ...)
		if event == "ADDON_LOADED" and ... == AddonName then
			load_saved_data(...)
			self:UnregisterEvent("ADDON_LOADED")
		elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
			cleu(..., CombatLogGetCurrentEventInfo())
    elseif event == "PLAYER_ENTERING_WORLD" then
      update_player_info(...)
      if CritasticStats["debug"] >= 1 then
        print(AddonName .. " loaded for " .. playerInfo["name"])
      end
		else
      print("Event: " .. event)
			-- Add other events here
		end
  end)

  SlashCmdList["Critastic"] = Critastic_SlashCrit
  SLASH_Critastic1 = "/Critastic"
  SLASH_Critastic2 = "/crit"
end

function table.removeKey(t, k)
	local i = 0
	local keys, values = {},{}
	for k,v in pairs(t) do
		i = i + 1
		keys[i] = k
		values[i] = v
	end

	while i>0 do
		if keys[i] == k then
			table.remove(keys, i)
			table.remove(values, i)
			break
		end
		i = i - 1
	end

	local a = {}
	for i = 1,#keys do
		a[keys[i]] = values[i]
	end

	return a
end

function load_saved_data(...)
	CritasticStats = copyDefaults(defaults, CritasticStats)
  -- update old true|false to current level based debug
  if (CritasticStats["output"] == "chatframe") then
    CritasticStats["output"] = "print"
  end
  if (type(CritasticStats["debug"]) == "boolean") then
    if CritasticStats["debug"] then
      CritasticStats["debug"] = 1
    else
      CritasticStats["debug"] = 0
    end
  end
  -- move old crits to the new categories
  for action, max in pairs(CritasticStats["highscores"]) do
    if not (action == "harming" or action == "healing") then
      if (action == "Holy Light" or action == "Flash of Light") then
        CritasticStats["highscores"]["healing"][action] = max
      else
        CritasticStats["highscores"]["harming"][action] = max
      end
      CritasticStats["highscores"] = table.removeKey(CritasticStats["highscores"], action)
    end
  end
end

function copyDefaults(src, dst)
	if not src then return { } end
	if not dst then dst = { } end
	for k, v in pairs(src) do
		if type(v) == "table" then
			dst[k] = copyDefaults(v, dst[k])
		elseif type(v) ~= type(dst[k]) then
			dst[k] = v
		end
	end
	return dst
end

function cleu(event, ...)
	local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...
	if (sourceGUID ~= playerGUID) then
		return
	end
  if CritasticStats["debug"] >= 3 then
    print(...)
  end
  local type = "harming"
	local spellId, spellName, spellSchool
	local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
	if subevent == "SWING_DAMAGE" then
		amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
	elseif subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" then
		spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
  elseif subevent == "SPELL_HEAL" then
    spellId, spellName, spellSchool, amount, _, _, critical = select(12, ...)
    type = "healing"
	end

if critical and sourceGUID == playerGUID then
		local action = spellName or "melee swing"
		firstcrit = ""
    lastcrit = 0
		if not CritasticStats["highscores"][type][action] or CritasticStats["highscores"][type][action] == 0 then
			CritasticStats["highscores"][type][action] = 0
		else
			firstcrit = MSG_CRITICAL_HIT_BEST:format(playerInfo["sex"], CritasticStats["highscores"][type][action])
      lastcrit = CritasticStats["highscores"][type][action]
		end

		if (amount > CritasticStats["highscores"][type][action]) then
			critMessage = MSG_CRITICAL_HIT:format(playerInfo["name"], action, destName, amount) .. firstcrit
			showOutput(critMessage)
			CritasticStats["highscores"][type][action] = amount
    elseif CritasticStats["debug"] >= 2 then
      print("Already got " .. action .. ". last: " .. lastcrit .. " just now: " .. amount)
		end
	end
end

function table.slice(tbl, first, last, step)
  local sliced = {}

  for i = first or 1, last or #tbl, step or 1 do
    sliced[#sliced+1] = tbl[i]
  end

  return sliced
end

function getKeysSortedByValue(...)
  local tbl, sortFunction, max = ...
  local keys = {}
  for key in pairs(tbl) do
    table.insert(keys, key)
  end

  table.sort(keys, function(a, b)
    return sortFunction(tbl[a], tbl[b])
  end)

  if (max) then
    keys = table.slice(keys, 1, max, 1)
  end

  return keys
end

function showOutput(data)
  if (CritasticStats["output"] ~= "nvwow") then
    print(format("%s", data))
  else
    SendChatMessage(format("%s", data), "CHANNEL", "COMMON", channelID)
  end
end

function tableLength(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function Critastic_SlashCrit(msg)
	local slashcmd = "/crit"
	local f, u, cmd, param = string.find(msg, "^([^ ]+) (.+)$")
	if ( not cmd ) then
		cmd = msg
		param = ""
	end
  if cmd == "show" then
    local show_top = 3
    if (param == "all") then show_top = nil end
    showOutput("Max crits for " .. playerInfo["name"] .. ":")
    local types = {"harming", "healing"}
    for _, type in ipairs(types) do
      if (tableLength(CritasticStats["highscores"][type]) > 0) then
        showOutput(format(" %s:", firstToUpper(type)))
        local sorted_keys = getKeysSortedByValue(CritasticStats["highscores"][type], function(a, b) return a > b end, show_top)
        for _, key in ipairs(sorted_keys) do
          showOutput(format("  %s: %d", key, CritasticStats["highscores"][type][key]))
        end
      end
    end
  elseif cmd == "reset" and param ~= "really" then
    print("Run '" .. slashcmd .. " reset really' to actually reset your scores.")
  elseif cmd == "reset" and param == "really" then
    print("Resetting crits for " .. playerInfo["name"])
    CritasticStats["highscores"] = {
      ["harming"] = {},
      ["healing"] = {}
    }
  elseif cmd == "debug" then
    if param == "1" or param == "2" or param == "3" then
      CritasticStats["debug"] = tonumber(param)
      print("Debug on: " .. param)
    elseif param == "0" then
      CritasticStats["debug"] = false
      print("Debug off")
    elseif param == "" then
      print("Debug set to: " .. CritasticStats["debug"])
    else
      print("debug " .. param .. " not understood, use debug [ 0 | 1 | 2 | 3 ]")
    end
  elseif cmd == "channel" then
      if param == "nvwow" then
        CritasticStats["output"] = "nvwow"
      else
        CritasticStats["output"] = "print"
      end
      print(format("%s output set to %s", AddonName, CritasticStats["output"]))
  else
    print("end of cmd check: " .. cmd)
  end
end

Critastic_OnLoad()
