local CritasticAddOn = select(2, ...)
local AddonName      = select(1, ...)

local Character = CritasticAddOn.Character
local Chat      = CritasticAddOn.Chat
local Crits     = CritasticAddOn.Crits

local main = CreateFrame("Frame")
CritasticAddOn.main = main

function CritasticAddOn:Init()
  Chat:Init()
  Crits:Init()
end

main:RegisterEvent("ADDON_LOADED")
main:RegisterEvent("PLAYER_ENTERING_WORLD")
main:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
main:SetScript("OnEvent", function(self, event, ...)
  if (event == "ADDON_LOADED" and ... == AddonName) then
    CritasticAddOn.Init()
  elseif (event == "PLAYER_ENTERING_WORLD") then
    Character:Init()
    Chat:Print("login " .. Character.playerInfo["name"])
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
  elseif (event == "COMBAT_LOG_EVENT_UNFILTERED") then
    Crits:Event(..., CombatLogGetCurrentEventInfo())
  end
end)
