--------------------------------------
-- Imports
--------------------------------------
---@class CritasticAddOn
local CritasticAddOn = select(2, ...)
---@type string
local addonName = select(1, ...)

--------------------------------------
-- Declarations
--------------------------------------
CritasticAddOn.Crits = {}

---@class Crits
local Crits     = CritasticAddOn.Crits
local Character = CritasticAddOn.Character
local Chat      = CritasticAddOn.Chat

Crits.MSG_CRITICAL_HIT = "%s's %s critically hit %s for %d damage!"
Crits.MSG_CRITICAL_HIT_BEST = " %s previous highest was %d."

function Crits:Init()
  if (not CritasticStats) then
    CritasticStats = {
      debug = 0,
      output = "print",
      highscores = {
        ["harming"] = {},
        ["healing"] = {}
      }
    }
  end
  Chat:SetOutput(CritasticStats["output"])
end

function Crits:Event(event, ...)
  local subevent, _, sourceGUID = select(2, ...)
  if (sourceGUID ~= Character.guid) then return end

  local type = "harming"
  local spellName, amount, critical
  if subevent == "SWING_DAMAGE" then
    amount, _, _, _, _, _, critical = select(12, ...)
  elseif subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" then
    spellName, _, amount, _, _, _, _, _, critical = select(13, ...)
  elseif subevent == "SPELL_HEAL" then
    spellName, _, amount, _, _, critical = select(13, ...)
    type = "healing"
  end

  if critical then
    local action = spellName or "melee swing"
    local firstcrit = ""
    local lastcrit = 0
    if not CritasticStats["highscores"][type][action] or CritasticStats["highscores"][type][action] == 0 then
      CritasticStats["highscores"][type][action] = 0
    else
      firstcrit = self.MSG_CRITICAL_HIT_BEST:format(Character.playerInfo["sex"], CritasticStats["highscores"][type][action])
      lastcrit = CritasticStats["highscores"][type][action]
    end

    if (amount > CritasticStats["highscores"][type][action]) then
      critMessage = self.MSG_CRITICAL_HIT:format(Character.playerInfo["name"], action, destName, amount) .. firstcrit
      Chat:Report(critMessage)
      CritasticStats["highscores"][type][action] = amount
    -- elseif CritasticStats["debug"] >= 2 then
    elseif true then
      Chat:Report(format("%s Already has %s. Best: %d, Now: %d", Character.playerInfo["name"], action, lastcrit, amount))
    end
  end
end
