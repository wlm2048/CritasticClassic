local AddonTable = select(2, ...)
local AddonName  = select(1, ...)

local tick = 1
local max_delay = 10

local playerGUID = UnitGUID("player")
local playerInfo = {["sex"] = "Their", ["name"] = "Someone"}
local MSG_CRITICAL_HIT = "%s's %s critically hit %s for %d damage!"
local MSG_CRITICAL_HIT_BEST = " %s previous highest was %d."
local channelID, channelName = GetChannelName("nvwow")
local localdb = {}

local defaults = {
  debug = false,
	output = "chatframe",
	highscores = {}
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
      if CritasticStats["debug"] then
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


function load_saved_data(...)
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
	elseif subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" then
		spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
  elseif subevent == "SPELL_HEAL" then
    spellId, spellName, spellSchool, amount, _, _, critical = select(12, ...)
	end

if critical and sourceGUID == playerGUID then
		local action = spellName or "melee swing"
		firstcrit = ""
    lastcrit = 0
		if not CritasticStats["highscores"][action] or CritasticStats["highscores"][action] == 0 then
			CritasticStats["highscores"][action] = 0
		else
			firstcrit = MSG_CRITICAL_HIT_BEST:format(playerInfo["sex"], CritasticStats["highscores"][action])
      lastcrit = CritasticStats["highscores"][action]
		end

		if (amount > CritasticStats["highscores"][action]) then
			critMessage = MSG_CRITICAL_HIT:format(playerInfo["name"], action, destName, amount) .. firstcrit
			SendChatMessage(critMessage, "CHANNEL", "COMMON", channelID)
			CritasticStats["highscores"][action] = amount
    elseif CritasticStats["debug"] then
      print("Already got " .. action .. ". last: " .. lastcrit .. " just now: " .. amount)
		end
	end
end


function showgui()
  local guiFrame = CreateFrame("Frame")

  guiFrame:SetMovable(true)
  guiFrame:EnableMouse(true)
  guiFrame:RegisterForDrag("LeftButton")
  guiFrame:SetScript("OnDragStart", guiFrame.StartMoving)
  guiFrame:SetScript("OnDragStop", guiFrame.StopMovingOrSizing)

  guiFrame:SetPoint("CENTER"); guiFrame:SetWidth(64); guiFrame:SetHeight(40);
  local tex = guiFrame:CreateTexture("ARTWORK");
  tex:SetAllPoints();
  tex:SetTexture(1.0, 0.5, 0); tex:SetAlpha(0.5);

  local btnReport = CreateFrame("Button","myButton",UIParent,"UIPanelButtonTemplate")

  btnReport:SetPoint("CENTER", guiFrame, "CENTER", 0,0)

  btnReport:SetWidth(70)
  btnReport:SetHeight(22)
  btnReport:SetText("Report")
end

function Critastic_SlashCrit(msg)
	local slashcmd = "/crit"
	local f, u, cmd, param = string.find(msg, "^([^ ]+) (.+)$")
	if ( not cmd ) then
		cmd = msg
		param = ""
	end
  if cmd == "" then
    showgui()
  elseif cmd == "show" then
    SendChatMessage("Max crits for " .. playerInfo["name"] .. ":", "CHANNEL", "COMMON", channelID)
    for action, max in pairs(CritasticStats["highscores"]) do
      SendChatMessage(action .. ": " .. max, "CHANNEL", "COMMON", channelID)
    end
  elseif cmd == "reset" and param ~= "really" then
    print("Run '" .. slashcmd .. " reset really' to actually reset your scores.")
  elseif cmd == "reset" and param == "really" then
    print("Resetting crits for " .. playerInfo["name"])
    CritasticStats["highscores"] = {}
  elseif cmd == "debug" then
    if param == "on" then
      CritasticStats["debug"] = true
      print("Debug on")
    elseif param == "off" then
      CritasticStats["debug"] = false
      print("Debug off")
    else
      print("debug " .. param .. " not understood, use debug [on|off]")
    end
  else
    print("end of cmd check: " .. cmd)
  end
end

Critastic_OnLoad()
