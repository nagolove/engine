global graphic_command_channel: love.thread.Channel

local yield = coroutine.yield
local gr = love.graphics
local serpent = require 'serpent'
local color = require 'height_map'.color

local map: {{number}} = {}
local square_width = 32
local mapSize = 0

local function new(data: string): {{number}}
    local ok, t = serpent.load(data) as (boolean, {{number}})
    if not ok then
        error('Could not load data to dsrender')
    end
    mapSize = #map
    return t
end

local function render()    
    local x, y = 0, 0
    for i = 1, mapSize do
        for j = 1, mapSize do
            local c = map[i] and map[i][j] or nil
            if c then
                gr.setColor(color(c^2))
                gr.rectangle("fill", 
                    x + square_width * i, y + square_width * j, 
                    square_width, square_width
                )
                --if map_n < 5 then
                    --if c < 0.75 then
                        --love.graphics.setColor(1,1,1)
                    --else
                        --love.graphics.setColor(0,0,0)
                    --end
                    --love.graphics.print(tostring(math.floor(c*100)), rez*i, rez*j)
                --end
            end
        end
    end
end

while true do
    local cmd: string

    -- команды cmd:
    -- new      - загрузить сериализованные данные высоты
    -- render   - нарисовать

    repeat
        cmd = graphic_command_channel:demand() as string

        if cmd == "new" then
            map = new(graphic_command_channel:demand() as string)
        elseif cmd == "render" then
            render()
        else
            error('dsrender unkonwn command: ' .. cmd)
        end
    until not cmd

    yield()
end
