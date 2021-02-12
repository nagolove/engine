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

