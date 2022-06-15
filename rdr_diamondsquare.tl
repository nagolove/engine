global graphic_command_channel: love.thread.Channel
global SCENE_PREFIX: string

require 'love'

local colorize = require('ansicolors2').ansicolors
local yield = coroutine.yield
local gr = love.graphics
local inspect = require "inspect"
local ceil = math.ceil
local get_color = require 'height_map'.color
local map: {{number}} = {}

local mapSize: integer = 0
-- Размер одного прямоугольника карты в пикселях.
-- TODO Перенести в параметры
local rez = 8
--local rez = 128
--local rez = 128 + 64 + 32 + 32
local x_pos, y_pos = 0., 0.

-- i1, i2, j1, j2 - индексы
-- dx, dy - _необязательное_ смещение в пикслелях для всей картинки
local function sub_draw(
    i1: integer, i2: integer, j1: integer, j2: integer, 
    dx: number,
    dy: number
)
    local x = dx or 0
    local y = dy or 0

    --print('diamondsquare')
    --print('draw')
    --print('mapSize', mapSize)
    --print('#map, #map[1]', #map, #map[1])

    --for i = 1, mapSize do
    --for j = 1, mapSize do

    local abs_i_init, abs_j_init = 1, 1
    --local abs_i_init, abs_j_init = i1, j1

    -- индексы для рисования
    local abs_i, abs_j: integer, integer = abs_i_init, abs_j_init
    -- i, j - индексы для выборки из карты
    for i = i1, i2 do
        abs_j = abs_j_init
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

local record CanvasNode
    canvas: gr.Canvas

    -- индексы
    i1: integer
    i2: integer
    j1: integer
    j2: integer
end

local canvas_nodes: {CanvasNode} = {}

local function newCanvasNode(i1: integer, i2: integer, j1: integer, j2: integer)
    local w, h = rez * ceil(mapSize / 2), rez * ceil(mapSize / 2)
    table.insert(canvas_nodes, {canvas = gr.newCanvas(w, h),
        i1 = i1,
        i2 = i2,
        j1 = j1,
        j2 = j2,
    })
end

local function bake()
    gr.setColor{1, 1, 1, 1}
    for _, node in ipairs(canvas_nodes) do
        gr.setCanvas(node.canvas)
        sub_draw(node.i1, node.i2, node.j1, node.j2, -rez, -rez)
        gr.setCanvas()
    end
end

local function draw_bakes()
    gr.setColor{1, 1, 1, 1}
    for _, node in ipairs(canvas_nodes) do
        local x, y = x_pos + node.i1 * rez, y_pos + node.j1 * rez
        gr.draw(node.canvas as gr.Drawable, x, y)
    end
end

local function save_bakes()
    for k, node in ipairs(canvas_nodes) do
        node.canvas:newImageData():encode('png', "map" .. tostring(k) .. ".png")
    end
end

local enum Command
    "map"               -- загрузить сжатую карту
    "set_position"      -- установить координаты рисования
    "flush"             -- рисовать
    "set_rez"           -- установить размер квадратика поля
end

local cmd_circle_buf: {Command} = {}
local cmd_circle_buf_maxnum = 16 * 2

local function push_cbuf(cmd: Command)
    if #cmd_circle_buf >= cmd_circle_buf_maxnum then
        table.remove(cmd_circle_buf, 1)
    end
    table.insert(cmd_circle_buf, cmd)
end

local function print_stack()
    print(colorize(
        "%{blue}cmd stack: " .. 
        inspect(cmd_circle_buf) .. 
        "%{reset}"
    ))
end

local commands = {}

function commands.set_rez(): boolean
    rez = graphic_command_channel:demand() as integer
    return false
end

-- Загрузить карту и нарисовать ее в холст.
function commands.map(): boolean
    canvas_nodes = {}

    --[[
    mapSize = graphic_command_channel:demand() as integer
    if type(mapSize) ~= 'number' then
        error('diamondsquare: mapSize should be an integer value.')
    end

    local compressed = graphic_command_channel:demand() as string
    print('commands.map, #compressed', size2human(#compressed))
    if type(compressed) ~= 'string' then
        error('diamondsquare: map data should be a string value.')
    end

    local decompress = love.data.decompress
    local uncompressed = decompress("string", 'gzip', compressed)

    local ok, errmsg = pcall(function()
        map = load(uncompressed as string)() as {{number}}
    end) as (boolean, string)
    if not ok then
        error('diamondsquare: Could not load map data.')
    end
    --]]

    local fname = graphic_command_channel:demand() as string
    print('commands.map: fname', fname)
    local content, size = love.filesystem.read(fname)
    local struct = require 'struct'

    mapSize = struct.unpack('L', content) as integer
    print('mapSize', mapSize)

    -- Откусывание начиная с 9 байта, до конца строчки
    local compressed = string.sub(content, 9, -1)

    local decompress = love.data.decompress
    local uncompressed = decompress("string", 'gzip', compressed)

    local serpent = require 'serpent'
    local ok, errmsg = pcall(function()
        --map = load(uncompressed as string)() as {{number}}
        local ok: boolean
        ok, map = serpent.load(uncompressed as string) as (boolean, {{number}})
    end) as (boolean, string)
    if not ok then
        error('diamondsquare: Could not load map data.')
    end

    -- TODO Автоматически исходя из размера максимально возможного размера
    -- текстуры подбирать наилучшее количество нод.
    newCanvasNode(1, ceil(mapSize / 2), 1, ceil(mapSize / 2))
    newCanvasNode(1, ceil(mapSize / 2), ceil(mapSize / 2), mapSize)
    newCanvasNode(ceil(mapSize / 2), mapSize, ceil(mapSize / 2), mapSize)
    newCanvasNode(ceil(mapSize / 2), mapSize, 1, ceil(mapSize / 2))

    bake()
    save_bakes()
    return false
end

function commands.set_position(): boolean
    local x = graphic_command_channel:demand() as number
    local y = graphic_command_channel:demand() as number
    x_pos, y_pos = x, y
    return false
end

-- Рисовать карту из холста.
function commands.flush(): boolean
    --crazy_test()

    draw_bakes()

    gr.setColor{1, 0, 0, 1}
    gr.rectangle('line', 0, 0, mapSize * rez, mapSize * rez)
    return false
end

-- счетчик команд
local cmd_num = 0

while true do
    local cmd: Command

    repeat
        cmd = graphic_command_channel:demand() as Command
        --push_cbuf(cmd)

        local fun = commands[cmd]
        if not fun then
            print_stack()
            error('diamonandsquare unknown command: ' .. cmd)
        end
        if not fun() then
            break
        end

        cmd_num = cmd_num + 1
    until not cmd

    yield()
end
