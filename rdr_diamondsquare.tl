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

-- Общее смещение при рисовании ландшафта
local x_pos, y_pos = 0., 0.

-- Зачем хранить карту как глобальную переменную модуля?
local map: {{number}} = {}
local mapSize: integer = 0
local mapWidthPix: integer

-- Размер одного прямоугольника карты в пикселях.
-- TODO Перенести в параметры
local rez = 64

local canvasSize = 256 -- in pixels

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

local record Node
    i: integer
    j: integer
end

local canvas_nodes: {integer:{integer:gr.Image}} = {}
local loaded_order: {Node} = {} -- Новые добавляются в конец
-- Максимальное количество загруженных текстур
local max_loaded_num: integer = 10 

local function new_texture(i: integer, j: integer)
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

local function draw_texture(i: integer, j: integer)
    if not canvas_nodes[i][j] then
        new_texture(i, j)
    end
    local tex = canvas_nodes[i][j]
    -- Нужен-ли i-1 считать или лучше i брать от 0??
    local x, y = x_pos + canvasSize * (i - 1), y_pos + canvasSize * (j - 1)
    gr.draw(tex as gr.Drawable, x, y)
end

local function bake_and_save_canvas(
    i1: integer, i2: integer, j1: integer, j2: integer,
    name: string
)
    gr.setColor{1, 1, 1, 1}
    local canvas = gr.newCanvas(canvasSize, canvasSize)
    gr.setCanvas(canvas)

    -- Почему смещение -rez ??
    sub_draw(i1, i2, j1, j2, -rez, -rez) 

    local prevfont = gr.getFont()
    gr.setColor{1, 0, 0, 1}
    gr.setFont(font)

    local ij_str = format("(%d-%d,%d-%d)", i1, i2, j1, j2)

    local x, y = rez, rez
    gr.print(ij_str, x, y)
    y = y + ceil(gr.getFont():getHeight())
    gr.print(name, x, y)
    gr.setFont(prevfont)

    gr.setCanvas()
    local fname = dirname .. "/" .. name .. ".png"
    canvas:newImageData():encode('png', fname)
    local object = canvas as love.Object
    object:release()
end

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

            print("y, x", y, x)
            print('i, j', i, j)

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
                zerofyNum(y + 1) .. "_" .. zerofyNum(x + 1)
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

local scrw, scrh = gr.getDimensions()
-- Часть экрана, видимая зрителю.
local view_port = {0, 0, scrw, scrh}

-- Рисовать карту из холста.
function commands.flush(): boolean
    local camx = ceil(graphic_command_channel:demand() as number)
    local camy = ceil(graphic_command_channel:demand() as number)

    -- Добавить обработку отрицательных положений камеры

    local index_i = ceil(camx / canvasSize)
    local index_j = ceil(camy / canvasSize)
    local local_view_port = {
        view_port[1] + camx,
        view_port[2] + camy,
        view_port[3] + camx,
        view_port[4] + camy,
    }
    print('index_i, index_j', index_i, index_j)
    --print('camx, camy', camx, camy)

    local w, h = gr.getDimensions()
    gr.setScissor(0, 0, w, h)

    gr.setColor{1, 1, 1, 1}

    local inrange_i = index_i > 1 and index_i < #map
    local inrange_j = index_j > 1 and index_j < #map

    if inrange_i and inrange_j then
        --[[
        Определить область видимости.
        Определить индексы
        --]]

        --draw_inner_textures()
        --[[
        for _, node in ipairs(canvas_nodes) do
        local x, y = x_pos + node.i1 * rez, y_pos + node.j1 * rez
        gr.draw(node.canvas as gr.Drawable, x, y)
        end
        --]]
        local i, j: integer = 0, 0
        repeat
            repeat
                draw_texture(i, j)
            until true
        until true

        gr.setColor{1, 0, 0, 1}
        gr.rectangle('line', 0, 0, mapSize * rez, mapSize * rez)
    end

    --print('#drawlist', #drawlist)
    --for _, draw_func in ipairs(drawlist) do
        --draw_func(camx, camy)
    --end

    local msg = format('index_i, index_j: %d, %d', index_i, index_j)
    gr.print(msg, w / 2, h / 2)
    gr.print(msg, camx - w/2 + w / 2, camy -h/2 + h / 2)

    --print('i_poses', inspect(i_poses))
    --print('j_poses', inspect(j_poses))

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
