local ffi = require 'ffi'
local colorize = require 'ansicolors2'.ansicolors

require'chipmunk_h'
local C = ffi.load'chipmunk'

local concolor = '%{blue}'

local function init()
    print(colorize(concolor .. 'Chipmunk init'))
end

local function update()
    print('pw update')
end

local function free()
    print(colorize(concolor .. 'Chipmunk free'))
end

return {
    init = init,
    update = update,
    free = free,
}
