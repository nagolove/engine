local ffi = require 'ffi'

require'chipmunk_h'
local C = ffi.load'chipmunk'

local function init()
    
end

local function update()

end

local function free()

end

return {
    init = init,
    update = update,
    free = free,
}
