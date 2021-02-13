local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs
























require("love")

local ChannelsTypes = {}








local Channels = {}

local threadNum = 5

local function initChannels()
   local result = {}
   for _, v in ipairs(ChannelsTypes) do
      result[v] = love.thread.getChannel(v .. tostring(threadNum))
   end
   return result
end

local chanels = initChannels()

chanels.cellrequest:push()
chanels.cellrequest:pop()
