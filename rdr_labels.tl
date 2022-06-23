--[[
Модуль отображения надписей на объектах.
Код ниже - кал. Будет отменен.
--]]

local gr = love.graphics
local yield = coroutine.yield
--local serpent = require 'serpent'

local enum Command
    "flush"
    "get_values"
end

--[[
local record Label
    label: string
    x: number
    y: number
end
--]]

--local labels: {Label} = {}

local commands = {}

function commands.flush(): boolean
    return false
end

function commands.get_values(): boolean
    return false
end

while true do
    local cmd: Command

    local oldfont = gr.getFont()
    repeat
        cmd = graphic_command_channel:demand() as Command

        local fun = commands[cmd]
        if not fun then
            error('labels unknown command: ' .. cmd)
        end
        if not fun() then
            break
        end

    until not cmd
    gr.setFont(oldfont)

    yield()
end

