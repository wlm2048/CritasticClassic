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
CritasticAddOn.Utils = {}

local Utils = CritasticAddOn.Utils

function Utils:TableLength(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

function Utils:FirstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function Utils:TableSlice(tbl, first, last, step)
  local sliced = {}
  for i = first or 1, last or #tbl, step or 1 do
    sliced[#sliced+1] = tbl[i]
  end
  return sliced
end

function Utils:GetKeysSortedByValue(...)
  local tbl, sortFunction, max = ...
  local keys = {}
  for key in pairs(tbl) do
    table.insert(keys, key)
  end

  table.sort(keys, function(a, b)
    return sortFunction(tbl[a], tbl[b])
  end)

  if (max) then
    keys = Utils:TableSlice(keys, 1, max, 1)
  end

  return keys
end
