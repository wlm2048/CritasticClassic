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

local Debug = CritasticAddOn.Debug

Debug.Levels = {
  NONE = 0,
  INFO = 1,
  DEBUG = 2,
  TRACE = 3
}

function Debug:SetDebugLevel(level)
  Debug.level = level
  CritasticStats["debug"] = tostring(level)
end

Debug.Is = function(level)
  return tonumber(Debug.level) >= tonumber(Debug.Levels[level])
end
