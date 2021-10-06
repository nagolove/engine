require "love"
love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/empty/?.lua")
local i18n = require "i18n"

--require "external"
--require "common"

--package.path = package.path .. ";scenes/automato/?.lua"

--local cam = require "camera".new()
--local gr = love.graphics
--local imgui = require "imgui"
--local inspect = require "inspect"
--local keyconfig = require "keyconfig"
--local mtschemes = require "mtschemes"
--local next = next
--local sim = require "simulator"
--local timer = require "Timer"

local function drawui()
end

local function draw2(graphic_command_channel: love.thread.Thread)
    -- Как понять сколько можно доставать результатов?
end

local function draw(): string
    return [[
    gr.clear(0.5, 0.5, 0.5)
    gr.setColor{0, 0, 0}
    gr.print("TestTest")
    ]]
end

local function update()
end

local function keypressed(key: string)
    if key == "escape" then
        love.event.quit()
    end
end

local function init()
    i18n.set('en.welcome', 'welcome to this program')
    i18n.load({
        en = {
            good_bye = "good-bye!",
            age_msg = "your age is %{age}.",
            phone_msg = {
                one = "you have one new message.",
                other = "you have %{count} new messages."
            }
        }
    })
    print("translated", i18n.translate('welcome'))
    print("translated", i18n('welcome'))
end

local function quit()
end

--local function mousemoved(x: number, y: number, _: number, _: number)
--end

--local function wheelmoved(x: number, y: number)
--end

return {
    init = init,
    quit = quit,
    draw = draw,
    --drawui = drawui,
    update = update,
    keypressed = keypressed,
    --mousemoved = mousemoved,
    --wheelmoved = wheelmoved
}


