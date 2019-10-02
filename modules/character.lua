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
CritasticAddOn.Character = {}

---@class Character
local Character = CritasticAddOn.Character

function Character:Init()
  self.guid = UnitGUID("player")
  local _, _, _, _, sexID, name, _ = GetPlayerInfoByGUID(self.guid)
  local sex = { [2] = "His", [3] = "Her" }
  self.playerInfo = { ["name"] = name, ["sex"] = sex[sexID] }
end
