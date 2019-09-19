local AddonName, AddonTable = ...

local playerGUID = UnitGUID("player")
local _, _, _, _, sexID, name, _ = GetPlayerInfoByGUID(playerGUID)
local sex = {
   [2] = "His",
   [3] = "Her"
}
local playerInfo = { ["name"] = name, ["sex"] = sex[sexID] }
local MSG_CRITICAL_HIT = "%s's %s critically hit %s for %d damage!"
local MSG_CRITICAL_HIT_BEST = " %s previous highest was %d."
local channelID, channelName = GetChannelName("nvwow")
local localdb = {}

local defaults = {
	output = "chatframe",
	highscores = {}
}


function Critastic_OnLoad()
	local frame, events = CreateFrame("Frame"), {}
	function events:COMBAT_LOG_EVENT_UNFILTERED(...)
		cleu(..., CombatLogGetCurrentEventInfo())
	end
	function events:ADDON_LOADED(...)
		load_saved_data(...)
	end
	frame:SetScript("OnEvent", function(self, event, ...)
		-- if (event == "ADDON_LOADED" and ... == AddonName) or (event ~= "ADDON_LOADED") then
			events[event](self, ...)
		-- end
	end)
	for k, v in pairs(events) do
		frame:RegisterEvent(k)
	end
	-- frame:RegisterEvent("ADDON_LOADED");
	-- frame:RegisterEvent("PLAYER_LOGOUT");

end

function load_saved_data(...)
	print(AddonName .. " loading...")
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
	local spellId, spellName, spellSchool
	local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand

	if subevent == "SWING_DAMAGE" then
		amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
	elseif subevent == "SPELL_DAMAGE" then
		spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
	end

	if critical and sourceGUID == playerGUID then
--			local action = spellId and GetSpellLink(spellId) or "melee swing"
		local action = spellName or "melee swing"
		firstcrit = ""
		if not CritasticStats["highscores"][action] then
			CritasticStats["highscores"][action] = 0
		elseif CritasticStats["highscores"][action] ~= 0 then -- catch the weird case where 0 got stored
			firstcrit = MSG_CRITICAL_HIT_BEST:format(playerInfo["sex"], CritasticStats["highscores"][action])
		end

		if (amount > CritasticStats["highscores"][action]) then
			critMessage = MSG_CRITICAL_HIT:format(playerInfo["name"], action, destName, amount) .. firstcrit
			SendChatMessage(critMessage, "CHANNEL", "COMMON", channelID)
			CritasticStats["highscores"][action] = amount
		end
	end
end

Critastic_OnLoad()
