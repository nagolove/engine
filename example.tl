--[[

global record SimulatorRender
    --__index: metatable<SimulatorRender>
    new: function(): SimulatorRender
    draw: function()
end

local SimulatorRender_mt: metatable<SimulatorRender> = {
    __index = SimulatorRender,
}

function SimulatorRender.new(): SimulatorRender
    local self: SimulatorRender = {}
    --self.__index = SimulatorRender as metatable<SimulatorRender>
    --return setmetatable(self, SimulatorRender as metatable<SimulatorRender>)
    return setmetatable(self, SimulatorRender_mt)
end

local simulatorRender = SimulatorRender.new()
simulatorRender.draw()

--]]

--[[
--local chanels: {string:love.thread.Channel} = initChannels()
require "love"

local type ChannelsTypes = enum
    "cellrequest" -- = love.thread.getChannel("cellrequest" .. threadNum)
    "data" -- = love.thread.getChannel("data" .. threadNum)
    "msg" -- = love.thread.getChannel("msg" .. threadNum)
    "object" -- = love.thread.getChannel("object" .. threadNum)
    "ready" -- = love.thread.getChannel("ready" .. threadNum)
    "request" -- = love.thread.getChannel("request" .. threadNum)
    "state" -- = love.thread.getChannel("state" .. threadNum)
end
local type Channels = {string: love.thread.Channel}

local threadNum = 5

local function initChannels(): Channels
    local result: Channels = {}
    for _, v in ipairs(ChannelsTypes as {string}) do
        result[v] = love.thread.getChannel(v .. tostring(threadNum))
    end
    return result
end

local chanels: Channels = initChannels()

chanels.cellrequest:push()
chanels.cellrequest:pop()

-- ]]

--global type ChannelsTypes = enum
local ChannelsTypes: {string} = {
    "cellrequest", 
    "data", 
    "msg", 
    "object",
    "ready",
    "request",
    "state",
}

for i, v in ipairs(ChannelsTypes as {string}) do
    print(i, v)
end
