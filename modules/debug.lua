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
CritasticAddOn.Debug = {}

Debug.OFF   = 0
Debug.INFO  = 1
Debug.DEBUG = 2
Debug.TRACE = 3

function Debug:SetDebugLevel(level)
  self.level = level
  CritasticStats["debug"] = tostring(level)
end

Debug.level = function()
  return tonumber(self.level)
end
