-- vim: set colorcolumn=85
-- vim: fdm=marker

-- XXX Видео драйвер не поддерживает
--format = "DXT1",

global graphic_command_channel: love.thread.Channel
global SCENE_PREFIX: string

require 'love'
require "common"

local colorize = require('ansicolors2').ansicolors
local yield = coroutine.yield
local gr = love.graphics
local inspect = require "inspect"
local ceil = math.ceil
local get_color = require 'height_map'.color

local dirname = ""
local mapn: integer
local rng_state: string

-- Зачем хранить карту как глобальную переменную модуля?
local map: {{number}} = {}
local mapSize: integer = 0
local mapWidthPix: integer

-- Размер одного прямоугольника карты в пикселях.
-- TODO Перенести в параметры
--local rez = 8
--local rez = 32
local rez = 64

--local rez = 128 + 64 + 32 + 32
local x_pos, y_pos = 0., 0.
--local canvasSize = 1024 * 4
local canvasSize = 1024 -- in pixels

-- Условие качественного тайлинга
assert(canvasSize % rez == 0, "canvasSize % rez == 0")

local font = gr.newFont(64 * 2)
local format = string.format
local type Drawer = function(camx: integer, camy: integer)
local drawlist: {Drawer} = {}

-- i1, i2, j1, j2 - индексы
-- dx, dy - _необязательное_ смещение в пикслелях для всей картинки
local function sub_draw(
    i1: integer, i2: integer, j1: integer, j2: integer, 
    dx: number,
    dy: number
)
    -- {{{
    local x = dx or 0
    local y = dy or 0

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
                gr.rectangle(
                    "fill", 
                    x + rez * abs_i, 
                    y + rez * abs_j, 
                    rez, rez
                )
            end
            abs_j = abs_j + 1
        end
        abs_i = abs_i + 1
    end
    -- }}}
end

--[[
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
--]]

--[[
local record CanvasNode
    canvas: gr.Canvas
    -- индексы
    i1: integer
    i2: integer
    j1: integer
    j2: integer
end
--]]

local record Node
    i: integer
    j: integer
end

local canvas_nodes: {integer:{integer:gr.Image}} = {}
local loaded_order: {Node} = {} -- Новые добавляются в конец
-- Максимальное количество загруженных текстур
local max_loaded_num: integer = 10 

local function new_texture(i: integer, j: integer)
    if not canvas_nodes[i][j] then
        if #loaded_order >= max_loaded_num then
            -- Удалить первую загруженную текстуру
            local node = loaded_order[1]
            assert(node.i == i and node.j == node.j, "indexes are equal")
            local obj = canvas_nodes[node.i][node.j] as love.Object
            obj:release()
            canvas_nodes[node.i][node.j] = nil
            table.remove(loaded_order, 1)
        end
        local path = format(
            "%s/%s_%s.png", 
            dirname, 
            zerofyNum(i), zerofyNum(j)
        )
        canvas_nodes[i][j] = gr.newImage(path)
        table.insert(loaded_order, { i = i, j = j})
    end
end

--[[
local function newCanvasNode(
    i1: integer, i2: integer, j1: integer, j2: integer,
    canvas_w: integer, canvas_h: integer
): CanvasNode
    --local w, h = rez * ceil(mapSize / 2), rez * ceil(mapSize / 2)
    --table.insert(canvas_nodes, {
    return {
        canvas = gr.newCanvas(canvas_w, canvas_h, {
        }),
        i1 = i1,
        i2 = i2,
        j1 = j1,
        j2 = j2,
    }
end
--]]

local function bake_and_save_canvas(
    i1: integer, j1: integer, 
    i2: integer, j2: integer,
    name: string
)
    gr.setColor{1, 1, 1, 1}
    local canvas = gr.newCanvas(canvasSize, canvasSize)
    gr.setCanvas(canvas)

    print("i1, i2, j1, j2", i1, i2, j1, j2) 

    -- Почему смещение -rez ??
    sub_draw(i1, i2, j1, j2, -rez, -rez) 

    local prevfont = gr.getFont()
    gr.setColor{1, 0, 0, 1}
    gr.setFont(font)
    local index_str = format("(%d, %d)", i1, j1)

    local x, y = rez, rez
    gr.print(index_str, x, y)
    y = y + ceil(gr.getFont():getHeight())
    gr.print(name, x, y)
    gr.setFont(prevfont)

    gr.setCanvas()
    local fname = dirname .. "/" .. name .. ".png"
    canvas:newImageData():encode('png', fname)
    local object = canvas as love.Object
    object:release()
end

--[[
-- Если карта от соответствующего семени генератора псевдослучайных чисел
-- уже отображалась, то записывать в холст куски карты с диска.
-- Какое максимальное количество карт хранить, по объему места на диске?
local function save_bakes()
    for k, node in ipairs(canvas_nodes) do
        local fname = dirname .. "/" .. zerofyNum(k) .. ".png"
        node.canvas:newImageData():encode('png', fname)
    end
end
--]]

local enum Command
    "map"               -- загрузить сжатую карту
    "set_position"      -- установить координаты рисования
    "flush"             -- рисовать
    "set_rez"           -- установить размер квадратика поля
end

local cmd_circle_buf: {Command} = {}
--local cmd_circle_buf_maxnum = 16 * 2

--[[
local function push_cbuf(cmd: Command)
    if #cmd_circle_buf >= cmd_circle_buf_maxnum then
        table.remove(cmd_circle_buf, 1)
    end
    table.insert(cmd_circle_buf, cmd)
end
--]]

local function print_stack()
    print(colorize(
        "%{blue}cmd stack: " .. 
        inspect(cmd_circle_buf) .. 
        "%{reset}"
    ))
end

local i_poses: {integer: boolean} = {}
local j_poses: {integer: boolean} = {}

local function bake_canvases()
    --[[
    TODO Автоматически исходя из размера максимально возможного размера
    текстуры подбирать наилучшее количество нод.
    * Разрешение экрана
    * Максимальный размер текстуры
    * Размер карты в пикселях
    Запечь необходимое видимое количество канвасов
    Добавить канвасы в список
    Проверить номера видимых блоков
    Если есть незагруженные блоки, то запечь новые канвасы
    Проверить список, удалить давно использованные
    --]]

    --[[
    -- {{{
    -- Перевести в циклы
    newCanvasNode(
        1, ceil(mapSize / 2), 
        1, ceil(mapSize / 2),
        canvas_w, canvas_h
    )
    newCanvasNode(
        1, ceil(mapSize / 2), 
        ceil(mapSize / 2), mapSize,
        canvas_w, canvas_h
    )
    newCanvasNode(
        ceil(mapSize / 2), mapSize, 
        ceil(mapSize / 2), mapSize,
        canvas_w, canvas_h
    )
    newCanvasNode(
        ceil(mapSize / 2), mapSize, 
        1, ceil(mapSize / 2),
        canvas_w, canvas_h
    )
    -- }}}
    --]]

    mapWidthPix = mapSize * rez
    print('mapWidthPix', mapWidthPix)
    local canvasNum = ceil(mapWidthPix / canvasSize)
    print('canvasNum', canvasNum)
    local canvas_w, canvas_h = canvasSize, canvasSize
    local i, j = 1, 1

    print('step_1', ceil(#map / canvasNum)) -- Шаг индексов для одного холста.
    local step = ceil(canvasSize / rez) -- Шаг индексов для одного холста.
    print('step', step)

    --print('os.exit()')
    --os.exit()

    print('#map', #map)
    print('step', step)
    local num = 0

    for y = 0, canvasNum - 1 do
        j = 1
        for x = 0, canvasNum - 1 do

            num = num + 1
            --print('canvas', num)
            --print('i, i + step', i, i + step)
            --print('j, j + step', j, j + step)
            print("y, x", y, x)

            print('i', i)
            print('j', j)

            -- {{{
            local uniq_color = {1, math.random(), math.random(), 1}
            table.insert(drawlist, function(camx: integer, camy: integer)

                --print('i', i)
                --print('j', j)

                local i_pos = i * rez
                local j_pos = j * rez
                local scrw, scrh = gr.getDimensions()

                local i_visible = i_pos >= camx and i_pos <= camx + scrw
                local j_visible = j_pos >= camy and j_pos <= camy + scrh

                gr.setColor(uniq_color)

                local prevFont = gr.getFont()
                gr.setFont(font)

                if not i_poses[i_pos] then
                    i_poses[i_pos] = true
                    print('i_pos', i_pos)
                end
                if not j_poses[j_pos] then
                    j_poses[j_pos] = true
                    print('j_pos', j_pos)
                end

                gr.rectangle(
                    'fill', 
                    i_pos, j_pos, 
                    canvas_w, canvas_h 
                )

                if i_visible and j_visible then
                    gr.setColor{0, 0, 0, 1}
                    local str = format("(%d, %d)", i, j)
                    --gr.print(str, i * rez, j * rez)
                    gr.print(str, i, j)

                    gr.setColor{0, 1, 0, 1}
                    gr.circle("fill", 0, 0, 200)
                    --print('drawing')
                end

                gr.setFont(prevFont)

            end)
            -- }}}

            --print('node', inspect(node))
            bake_and_save_canvas(
                i, i + step,
                j, j + step,
                zerofyNum(x + 1) .. "_" .. zerofyNum(y + 1)
            )
            j = j + step
        end
        i = i + step
    end
end

local commands = {}

function commands.set_rez(): boolean
    rez = graphic_command_channel:demand() as integer
    return false
end

-- Загрузить карту и нарисовать ее в холст.
function commands.map(): boolean
    --local fname = graphic_command_channel:demand() as string
    mapn = graphic_command_channel:demand() as integer
    if type(mapn) ~= 'number' then
        error('mapn should be a number, not a ' .. type(mapn))
    end

    rng_state = graphic_command_channel:demand() as string
    if type(rng_state) ~= 'string' then
        error('rng_state should be a string, not a ' .. type(rng_state))
    end

    dirname = zerofyNum(mapn) .. "_" .. rng_state
    local fname = dirname .. "/map.data.bin"

    print('commands.map: fname', fname)
    local mapFile = love.filesystem.newFile(fname, 'r')
    if mapFile == nil then
        error('mapFile equal nil')
    end

    local struct = require 'struct'
    local decompress = love.data.decompress
    local ulong_size = 8 -- Размер модификатора L в struct.pack()
    local content = mapFile:read(ulong_size)

    mapSize = ceil(struct.unpack('L', content) as number)

    map = {} -- Двумерный массив высот
    for _ = 1, mapSize do
        local row_len_s = mapFile:read(ulong_size)
        local row_len = struct.unpack('L', row_len_s) as number
        local compressed = mapFile:read(row_len)
        local uncompressed = decompress("string", 'gzip', compressed)

        local ok, errmsg = pcall(function()
            map[#map + 1] = load(uncompressed as string)() as {number}
        end) as (boolean, string)
        if not ok then
            error('diamondsquare: Could not load map data:' .. errmsg)
        end
    end

    mapFile:close()

    bake_canvases()

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
    --local ok, errmsg = pcall(function()

    local camx = ceil(graphic_command_channel:demand() as number)
    local camy = ceil(graphic_command_channel:demand() as number)

    -- Добавить обработку отрицательных положений камеры

    local index_i = ceil(mapWidthPix / camx)
    local index_j = ceil(mapWidthPix / camy)
    --print('index_i, index_j', index_i, index_j)
    --print('camx, camy', camx, camy)

    --crazy_test()

    local w, h = gr.getDimensions()
    gr.setScissor(0, 0, w, h)

    gr.setColor{1, 1, 1, 1}

    local inrange_i = index_i > 1 and index_i < #map
    local inrange_j = index_j > 1 and index_j < #map

    if inrange_i and inrange_j then
        --[[
        Какова структура для хранения и поиска холстов?
        Добавить список порядка использования для удаления лишних холстов.

        Определить область видимости.
        Определить индексы
        --]]

        --[[
        for _, node in ipairs(canvas_nodes) do
        local x, y = x_pos + node.i1 * rez, y_pos + node.j1 * rez
        gr.draw(node.canvas as gr.Drawable, x, y)
        end
        --]]

        gr.setColor{1, 0, 0, 1}
        gr.rectangle('line', 0, 0, mapSize * rez, mapSize * rez)
    end

    --print('#drawlist', #drawlist)
    for _, draw_func in ipairs(drawlist) do
        draw_func(camx, camy)
    end

    --print('i_poses', inspect(i_poses))
    --print('j_poses', inspect(j_poses))

    --[[
    end) as (boolean, string)
    if not ok then
        error('commands.flush():' .. errmsg)
    end
    --]]

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
