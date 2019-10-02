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
CritasticAddOn.Chat = {}

---@class Chat
local Chat  = CritasticAddOn.Chat
local Debug = CritasticAddOn.Debug
local Crits = CritasticAddOn.Crits

--------------------------------------
-- Defaults
--------------------------------------
Chat.command = "/crit"
Chat.commands = {
    ["help"] = function()
        print(" ")
        Chat:Print("List of commands:")
        Chat:Print("/crit show [all] - show your best 3 (or all) crits")
        Chat:Print("/crit channel [nvwow | print] - selects output for crits")
        Chat:Print("/crit reset - clear your crits")
        print(" ")
    end,
    ["show"] = function(all)
      if (Crits == nil) then Crits = CritasticAddOn.Crits end
      Crits:Show(all)
    end,
    ["reset"] = function()
      if (Crits == nil) then Crits = CritasticAddOn.Crits end
      CritasticStats = nil
      Crits:Init()
    end,
    ["debug"] = function(level)
      if (Debug == nil) then Debug = CritasticAddOn.Debug end
      if (string.match(level, "[0-3]")) then
        Debug:SetDebugLevel(level)
        Chat:Print("Debug level set to: " .. level)
      else
        Chat:Print("Unknown debug level: " .. level)
        Chat.commands.help()
      end
    end,
    ["channel"] = function(channel)
      if (channel == "nvwow" or channel == "print") then
        CritasticStats["output"] = channel
        Chat:SetOutput(channel)
        Chat:Print("Output set to: " .. channel)
      else
        Chat:Print("Incorrect output channel: " .. channel)
        Chat.commands.help()
      end
    end

    -- ["example"] = {
    -- 	["test"] = function(...)
    -- 		Chat:Print("My Value:", tostringall(...));
    -- 	end
    -- }
}

--------------------------------------
-- Chat functions
--------------------------------------
function Chat:Print(...)
  local prefix = string.format("|cffff0000%s|r", addonName)
  DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ...))
end

function Chat:SetOutput(output)
  if (output == "nvwow") then
    self.output = function(msg)
      if (not Chat.channelID) then Chat.channelID = GetChannelName("nvwow") end
      SendChatMessage(format("%s", msg), "CHANNEL", "COMMON", Chat.channelID)
    end
  else
    self.output = function(msg)
      Chat:Print(msg)
    end
  end
end

function Chat:Report(msg)
  Chat.output(msg)
end

function Chat:JoinedChannel(...)
  local type, _, _, numname, _, _, type, number, name = ...
  if (name ~= "nvwow") then return end
  Chat.channelID = GetChannelName("nvwow")
  Chat:Print("Joined channel " .. name)
end

--------------------------------------
-- Lifecycle Events
--------------------------------------
---
---Initializes the chat slash commands
function Chat:Init()
    SLASH_Critastic1 = self.command
    SlashCmdList["Critastic"] = function(msg)
        local str = msg
        if (#str == 0) then
            -- User just entered "/todo" with no additional args.
            Chat.commands.help()
            return
        end

        local args = {}
        for _, arg in ipairs({string.split(" ", str)}) do
            if (#arg > 0) then
                table.insert(args, arg)
            end
        end

        local path = Chat.commands -- required for updating found table.

        for id, arg in ipairs(args) do
            if (#arg > 0) then -- if string length is greater than 0.
                arg = arg:lower()
                if (path[arg]) then
                    if (type(path[arg]) == "function") then
                        -- all remaining args passed to our function!
                        path[arg](select(id + 1, unpack(args)))
                        return
                    elseif (type(path[arg]) == "table") then
                        path = path[arg] -- another sub-table found!
                    end
                else
                    -- does not exist!
                    Chat.commands.help()
                    return
                end
            end
        end
    end
end
