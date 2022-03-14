global graphic_command_channel: love.thread.Channel
local yield = coroutine.yield
local gr = love.graphics
local inspect = require "inspect"
local color = require 'height_map'.color
local map: {{number}} = {}

local mapSize: integer = 0
-- Размер одного прямоугольника карты в пикселях.
local rez = 32

local function draw()
    local x = 0
    local y = 0

    print('diamondsquare')
    print('draw')
    print('mapSize', mapSize)
    print('#map, #map[1]', #map, #map[1])

    for i = 1, mapSize do
        for j = 1, mapSize do
            local c = map[i] and map[i][j] or nil
            if c then
                gr.setColor(color(c^2))
                gr.rectangle("fill", x + rez*i, y + rez*j, rez, rez)

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

local function flush()
    draw()
end

local function read_map()
    mapSize = graphic_command_channel:demand() as integer
    if type(mapSize) ~= 'number' then
        error('diamondsquare: mapSize should be an integer value.')
    end

    local compressed = graphic_command_channel:demand() as string
    if type(compressed) ~= 'string' then
        error('diamondsquare: map data should be a string value.')
    end

    local decompress = love.data.decompress
    local s = 'wefefwe'
    --local uncompressed = decompress("string", 'gzip', compressed)
    local uncompressed = decompress("string", 'gzip', s)
    if not uncompressed then
        error('diamondsquare: could not decompress map data.')
    end

    local ok, errmsg = pcall(function()
        --map = load(uncompressed)()
        map = load(uncompressed as string) as {{number}}
        print('map', inspect(map))
    end) as (boolean, string)
    if not ok then
        error('diamondsquare: Could not load map data.')
    end
end

while true do
    local cmd: string

    repeat
        cmd = graphic_command_channel:demand() as string

        -- Загрузить карту и нарисовать ее в холст.
        if cmd == "map" then
            read_map()
            break
        -- Рисовать карту из холста.
        elseif cmd == 'flush' then
            flush()
            break
        else
            error('diamondsquare unkonwn command: ' .. cmd)
        end

    until not cmd

    yield()
end
