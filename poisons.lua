function()

  -- lookup table of rogue stuff; true means "show even if 0"
  local poison_table = {
    ["Crippling Poison"] = {
      {["id"] = 3775, ["require"] = false, ["level"] = 20, ["rank"] = 1 }, -- Crippling Poison
      {["id"] = 3776, ["require"] = false, ["level"] = 50, ["rank"] = 2 } -- Crippling Poison II
    },
    ["Deadly Poison"] = {
      {["id"] = 2892, ["require"] = false, ["level"] = 30, ["rank"] = 1 }, -- Deadly Poison
      {["id"] = 2893, ["require"] = false, ["level"] = 38, ["rank"] = 2 }, -- Deadly Poison II
      {["id"] = 8984, ["require"] = false, ["level"] = 46, ["rank"] = 3 }, -- Deadly Poison III
      {["id"] = 8985, ["require"] = false, ["level"] = 54, ["rank"] = 4 } -- Deadly Poison IV
    },
    ["Instant Poison"] = {
      {["id"] = 6947, ["require"] = false, ["level"] = 20, ["rank"] = 1 }, -- Insant Poison
      {["id"] = 6949, ["require"] = false, ["level"] = 28, ["rank"] = 2 }, -- Instant Poison II
      {["id"] = 6950, ["require"] = false, ["level"] = 36, ["rank"] = 3 }, -- Instant Poison III
      {["id"] = 8926, ["require"] = false, ["level"] = 44, ["rank"] = 4 }, -- Instant Poison IV
      {["id"] = 8927, ["require"] = false, ["level"] = 52, ["rank"] = 5 }, -- Instant Poison V
      {["id"] = 8928, ["require"] = false, ["level"] = 60, ["rank"] = 6 } -- Instant Poison VI
    },
    ["Mind-numbing Poison"] = {
      {["id"] = 5237, ["require"] = false, ["level"] = 24, ["rank"] = 1 }, -- Mind-numbing Poison
      {["id"] = 6951, ["require"] = false, ["level"] = 38, ["rank"] = 2 }, -- Mind-numbing Poison II
      {["id"] = 9186, ["require"] = false, ["level"] = 52, ["rank"] = 3 }, -- Mind-numbing Poison III
    },
    ["Wound Poison"] = {
      {["id"] = 10918, ["require"] = false, ["level"] = 32, ["rank"] = 1 }, -- Wound Poison
      {["id"] = 10920, ["require"] = false, ["level"] = 40, ["rank"] = 2 }, -- Wound Poison II
      {["id"] = 10921, ["require"] = false, ["level"] = 48, ["rank"] = 3 }, -- Wound Poison III
      {["id"] = 10922, ["require"] = false, ["level"] = 56, ["rank"] = 4 } -- Wound Poison IV
    },
    ["Flash Powder"] = {
      {["id"] = 5140, ["require"] = true, ["level"] = 22, ["rank"] = 1 } -- Flash Powder (for Vanish), always want some
    },
    ["Blinding Powder"] = {
      {["id"] = 5530, ["require"] = true, ["level"] = 34, ["rank"] = 1 },  -- Blinding Powder, also always want this
    },
    ["Thistle Tea"] = {
      {["id"] = 7676, ["require"] = true, ["level"] = 0, ["rank"] = 1 },  -- Thistle Tea, also always want this
    }
  }

  local rank_to_rn = { "", "II", "III", "IV", "V", "VI" }

  local player_level = UnitLevel("player")

  for base_poison, poison_data in pairs(poison_table) do
    print(format("%s: %s", base_poison, poison_data[1]))
  end

    local poisons_in_bags = {}
    local items_in_bags = {}

    -- get a total of all the bag items by item ID
    for i=0,4 do
      local bagname = GetBagName(i)
      if bagname then
        local avail = GetContainerNumSlots(i)
        for slot = 1, avail do
          id = GetContainerItemID(i, slot)
          if (id) then
            texture, count, locked, quality, readable, lootable, link, isFiltered, hasNoValue, itemID = GetContainerItemInfo(i, slot)
            if (items_in_bags[id]) then
              items_in_bags[id] = items_in_bags[id] + count
            else
              items_in_bags[id] = count
            end
          end
        end
      end
    end

    -- which of those items are poisons
    local poison_list = {}
    for poisonId, mustHave in pairs(poison_ids) do
      -- if we have to have them, default to 0
      if (poison_ids[poisonId]) then
        poison_list[poisonId] = 0
      end
      if (items_in_bags[poisonId]) then
        poison_list[poisonId] = items_in_bags[poisonId]
      end
    end

    local howmany = ""
    local sorted = {}
    for k, v in pairs(poison_list) do
        table.insert(sorted,{k,v})
    end

    table.sort(sorted, function(a,b) return a[2] < b[2] end)

    for _, v in ipairs(sorted) do
        pname, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(v[1])
        num = v[2]
        -- short circuit if the API isn't fully ready
        if num == nil or pname == nil then return end
        local alert = ""
        if (num <= 5) then
            alert = "|cffff0000"
        end

        howmany = howmany .. format("%s%s: %d|r\n", alert, pname, num)
    end
    return howmany
end
