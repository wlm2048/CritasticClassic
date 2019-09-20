local AddonName, AddonTable = ...

local playerGUID = UnitGUID("player")
local playerInfo = {}
local MSG_CRITICAL_HIT = "%s's %s critically hit %s for %d damage!"
local MSG_CRITICAL_HIT_BEST = " %s previous highest was %d."
local channelID, channelName = GetChannelName("nvwow")
local localdb = {}

local defaults = {
	output = "chatframe",
	highscores = {}
}


function Critastic_OnLoad()
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("ADDON_LOADED")
	frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	frame:SetScript("OnEvent", function(self, event, ...)
		if event == "ADDON_LOADED" then
			load_saved_data(...)
			self:UnregisterEvent("ADDON_LOADED")
		elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
			cleu(..., CombatLogGetCurrentEventInfo())
    elseif event == "PLAYER_ENTERING_WORLD" then
      update_player_info(...)
		else
      print("Event: " .. event)
			-- Add other events here
		end
  end)

  SlashCmdList["Critastic"] = Critastic_SlashCrit
  SLASH_Critastic1 = "/Critastic"
  SLASH_Critastic2 = "/crit"
end

function update_player_info(...)
  local _, _, _, _, sexID, name, _ = GetPlayerInfoByGUID(playerGUID)
  local sex = {
     [2] = "His",
     [3] = "Her"
  }
  playerInfo = { ["name"] = name, ["sex"] = sex[sexID] }
end

function load_saved_data(...)
	print(AddonName .. " loading..." .. ...)
	CritasticStats = copyDefaults(defaults, CritasticStats)
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
  if not playerInfo["sex"] then
    update_player_info(...)
  end
	local spellId, spellName, spellSchool
	local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
	if subevent == "SWING_DAMAGE" then
		amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
	elseif subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" then
		spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
	end

if critical and sourceGUID == playerGUID then
--			local action = spellId and GetSpellLink(spellId) or "melee swing"
		local action = spellName or "melee swing"
		firstcrit = ""
		if not CritasticStats["highscores"][action] then
			CritasticStats["highscores"][action] = 0
		else
			firstcrit = MSG_CRITICAL_HIT_BEST:format(playerInfo["sex"], CritasticStats["highscores"][action])
		end

		if (amount > CritasticStats["highscores"][action]) then
			critMessage = MSG_CRITICAL_HIT:format(playerInfo["name"], action, destName, amount) .. firstcrit
			SendChatMessage(critMessage, "CHANNEL", "COMMON", channelID)
			CritasticStats["highscores"][action] = amount
		end
	end
end

function Critastic_SlashCrit(msg)
	local slashcmd = "/crit"
  if not playerInfo["name"] then
    update_player_info()
  end

	-- InitializeSetup()
	-- DEFAULT_CHAT_FRAME:AddMessage("Critastic set to " .. CritasticOptions.Status .. " and is now ready.")
	-- if ( msg ~= "" ) then msg = string.lower(msg) end
	local f, u, cmd, param = string.find(msg, "^([^ ]+) (.+)$")
	if ( not cmd ) then
		cmd = msg
		param = ""
	end
  if cmd == "show" then
    SendChatMessage("Max crits for " .. playerInfo["name"] .. ":", "CHANNEL", "COMMON", channelID)
    for action, max in pairs(CritasticStats["highscores"]) do
      SendChatMessage(action .. ": " .. max, "CHANNEL", "COMMON", channelID)
    end
  elseif cmd == "reset" and param ~= "really" then
    print("Run '" .. slashcmd .. " reset really' to actually reset your scores.")
  elseif cmd == "reset" and param == "really" then
    print("Resetting crits for " .. playerInfo["name"])
    CritasticStats["highscores"] = {}
  end
end

Critastic_OnLoad()
