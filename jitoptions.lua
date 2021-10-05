local jit = require 'jit'

local function off()
    jit.off()
end

local function on()
    jit.on()
end

return {
    on = on,
    off = off,
}
