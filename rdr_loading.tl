-- vim: set colorcolumn=85
-- vim: fdm=marker

global SCENE_PREFIX: string
global graphic_command_channel: love.thread.Channel
local gr = love.graphics
local yield = coroutine.yield
local colorize = require 'ansicolors2'.ansicolors

local fontName = "/DejaVuSansMono.ttf" -- Когда получать параметры шрифта?
--local fontSize = 128
local fontSize = 110

local font = gr.newFont(SCENE_PREFIX .. fontName, fontSize)
if not font then
    error("Could not load font '" .. fontName .. "'")
end

local color = {0.9, 0, 0, 1}
local value = 0.
local message: string = "Карта создается"
local barLength = 20
local bar = ""

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
    bar = makeProgressBar(barLength, value)
end

function commands.flush(): boolean
    local x, y = 0., 0.
    local prevFont = gr.getFont()
    local prevColor = {gr.getColor()}

    gr.setFont(font)
    gr.setColor(color)

    --print('commands.flush()')

    local list = boxifyTextParagraph(
        {
            message,
            bar,
        },
        'center'
    )

    --[[
    for k, v in ipairs(list) do
        print(v)
    end
    --]]

    local scrW, scrH = gr.getDimensions()
    y = math.ceil((scrH - #list * font:getHeight()) / 2) 

    for k, line in ipairs(list) do
        gr.print(line, x, y)
        y = y + gr.getFont():getHeight()
    end

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

