-- vim: set colorcolumn=85
-- vim: fdm=marker

--[[ {{{ Documentation
record LinesBuffer
    -- добавить идентификатор и запись. 
    -- Цикл обработки команд не прерывается.
    add: function(id: string|number, message: string)

    -- Удалить запись из словаря.
    remove: function(id: string, message: string)

    -- Очистить словарь и прервать цикл обработки команд.
    clear: function()

    -- Рисовать и прервать цикл обработки команд.
    flush: function()

    -- Прервать цикл обработки команд.
    -- Используется при множественном добавлении или удалении.
    enough: function()

    -- Рисовать рамку вокруг таблицы или нет.
    -- Перерасчитывает ширину рамки.
    border: function(boolean)

    -- Установить рисование таблицы по центру экрана.
    align_center: function()

    -- Установить точку рисования таблицы. 
    -- Сбрасывается вызовом align_center()
    pos: function(x: number, y: number)
end
-- }}} 
--]] 
    
global SCENE_PREFIX: string
global graphic_command_channel: love.thread.Channel
local gr = love.graphics
local yield = coroutine.yield
local colorize = require 'ansicolors2'.ansicolors

local fontName = "/DejaVuSansMono.ttf" -- Когда получать параметры шрифта?
local fontSize = 128

local font = gr.newFont(SCENE_PREFIX .. fontName, fontSize)
if not font then
    error("Could not load font '" .. fontName .. "'")
end

local color = {0.9, 0, 0, 1}
local value = 0.

local enum Command
    'flush'
    'progress'
    'reset'
end

local commands = {}

function commands.reset(): boolean
    value = 0.
    return false
end

-- Двигает полоску прогресса от 0. до 1.
function commands.progress(): boolean
    local v = graphic_command_channel:demand() as number
    if v > 1. or v < 0. then
        error('Progress value should ve in 0..1 range.')
    end
    value = v
end

function commands.flush(): boolean
    local x, y = 0, 0
    local prevFont = gr.getFont()
    local prevColor = {gr.getColor()}

    gr.setFont(font)
    gr.setColor(color)

    gr.print('Загрузка карты', x, y)

    gr.setFont(prevFont)
    gr.setColor(prevColor)
    return false
end

while true do
    local cmd: Command
    --print('lines_buf: cmd', cmd)

    local oldfont = gr.getFont()
    repeat
        cmd = graphic_command_channel:demand() as Command

        local fun = commands[cmd]
        if not fun then
            error('lines_buf unkonwn command: ' .. cmd)
        end
        if not fun() then
            break
        end

    until not cmd
    gr.setFont(oldfont)

    yield()
end

