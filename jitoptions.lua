
local function off()
    pcall(function()
        local jit = require 'jit'
        jit.off()
    end)
end

local function on()
    pcall(function()
        local jit = require 'jit'
        jit.on()
    end)
end

return {
    on = on,
    off = off,
}
