require 'love'

local serpent = require 'serpent'
local verts: {{number}} = {}
local inspect = require 'inspect'

local function init()
    for line in love.filesystem.lines('verts.txt') do
        local ok, data = serpent.load(line) as (boolean, {number})
        print('data', inspect(data))
        if ok then
            table.insert(verts, data)
        else
            error('no data in line')
        end
    end
end

local function render()
    for _, v in ipairs(verts) do
        --print('v', inspect(v))
        love.graphics.polygon('fill', v)
    end
end

return {
    init = init,
    render = render,
}
