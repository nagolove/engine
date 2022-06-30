-- vim: set colorcolumn=85
-- vim: fdm=marker

global graphic_command_channel: love.thread.Channel
global SCENE_PREFIX: string

require 'love'
require "common"

local im = require 'imgui'
local yield = coroutine.yield
local serpent = require 'serpent'
--local gr = love.graphics
local inspect = require "inspect"
local ceil = math.ceil

local channel = love.thread.getChannel("mapgen_ui")

local record Settings
    mapSize: integer
end

local settings: Settings = {
    mapSize = 5,
}
channel:clear()
channel:push(serpent.dump(settings))

local enum Command
    "flush"             -- рисовать
end

local commands = {}

function commands.flush(): boolean
    --mapn = graphic_command_channel:demand() as integer
    im.NewFrame()
    local ok: boolean
    local mapSize: number
    mapSize, ok = im.SliderInt('map size', mapSize, 0, 12)
    im.Render()
    print('mapSize, ok', mapSize, ok)
    settings.mapSize = ceil(mapSize)

    channel:clear()
    channel:push(serpent.dump(settings))

    return false
end

while true do
    local cmd: Command

    repeat
        cmd = graphic_command_channel:demand() as Command

        local fun = commands[cmd]
        if not fun then
            --print_stack()
            error('mapgen_ui unknown command: ' .. cmd)
        end
        if not fun() then
            break
        end

    until not cmd

    yield()
end
