global graphic_command_channel: love.thread.Channel
local yield = coroutine.yield
local gr = love.graphics
local inspect = require "inspect"
local ceil = math.ceil
local get_color = require 'height_map'.color
local map: {{number}} = {}

local mapSize: integer = 0
-- Размер одного прямоугольника карты в пикселях.
local rez = 32

local function sub_draw(i1: integer, i2: integer, j1: integer, j2: integer)
    local x = 0
    local y = 0

    --print('diamondsquare')
    --print('draw')
    --print('mapSize', mapSize)
    --print('#map, #map[1]', #map, #map[1])

    --for i = 1, mapSize do
    --for j = 1, mapSize do

    -- индексы для рисования
    local abs_i, abs_j: integer, integer = i1, j1
    -- i, j - индексы для выборки из карты
    for i = i1, i2 do
        abs_j = j1
        for j = j1, j2 do
            local c = map[i] and map[i][j] or nil
            if c then
                local color = get_color(c ^ 2)
                --print('color', inspect(color))

                gr.setColor(color)
                --gr.rectangle("fill", x + rez*i, y + rez*j, rez, rez)
                gr.rectangle("fill", x + rez * abs_i, y + rez * abs_j, rez, rez)

                --if map_n < 5 then
                --if c < 0.75 then
                --love.graphics.setColor(1,1,1)
                --else
                --love.graphics.setColor(0,0,0)
                --end
                --love.graphics.print(tostring(math.floor(c*100)), rez*i, rez*j)
                --end

            end
            abs_j = abs_j + 1
        end
        abs_i = abs_i + 1
    end
end

local function crazy_test()
    local r = math.random()
    if r < 1 / 4 then
        sub_draw(1, ceil(mapSize / 2), 1, ceil(mapSize / 2))
    elseif r > 1 /4 and r < 1/4 *2 then
        sub_draw(1, ceil(mapSize / 2), ceil(mapSize / 2), mapSize)
    elseif r > 1/4 *2 and r < 1/4*3 then
        sub_draw(ceil(mapSize / 2), mapSize, ceil(mapSize / 2), mapSize)
    else
        sub_draw(ceil(mapSize / 2), mapSize, 1, ceil(mapSize / 2))
    end
end

local function flush()
    --crazy_test()

    sub_draw(1, ceil(mapSize / 2), 1, ceil(mapSize / 2))
    sub_draw(1, ceil(mapSize / 2), ceil(mapSize / 2), mapSize)
    sub_draw(ceil(mapSize / 2), mapSize, ceil(mapSize / 2), mapSize)
    sub_draw(ceil(mapSize / 2), mapSize, 1, ceil(mapSize / 2))
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
    --local s = 'wefefwe'
    local uncompressed = decompress("string", 'gzip', compressed)
    --local uncompressed = decompress("string", 'gzip', s)

    local ok, errmsg = pcall(function()
        map = load(uncompressed as string)() as {{number}}
        --print('map', inspect(map))
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
