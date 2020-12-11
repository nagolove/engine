local struct = require "struct"
--local histPath = "c:/users/dekar/AppData/Roaming/MetaQuotes/Terminal/287469DEA9630EA94D0715D755974F1B/history/Alpari-Demo/EURUSD999.hst"
local histPath = [[C:/Users/dekar/Desktop/tick history/EURUSD999.hst]]
local imgui = require "imgui"
local cam = require "camera".new()
local gr = love.graphics
local thread

--package.path = package.path .. ";scenes/hst_reader/?.lua"
local threadPath = "scenes/hst_reader/file-thread.lua"

local function init()
    thread = love.thread.newThread(threadPath)
    love.thread.getChannel("fname"):push(histPath)
    thread:start(1)
end

-- стартовые позиции для рисования
local sx, sy = 0, 0

local function quit()
end

local function drawBar(x, record)

end

local function draw()
    cam:attach()
    for i = 1, 100 do
    end
    cam:detach()
end

local function update(dt)
end

local function keypressed(key)
end

local function wheelmoved(x, y)
    print(x, y)
end

return {
    cam = cam, 

    PIX2M = PIX2M,
    M2PIX = M2PIX,

    init = init,
    quit = quit,
    draw = draw,
    update = update,
    keypressed = keypressed,
    wheelmoved = wheelmoved,
}
