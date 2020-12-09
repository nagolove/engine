local struct = require "struct"
local histPath = "c:/users/dekar/AppData/Roaming/MetaQuotes/Terminal/287469DEA9630EA94D0715D755974F1B/history/Alpari-Demo/EURUSD999.hst"
local imgui = require "imgui"
local thread

local function init()
    thread = love.thread.newThread("file-thread.lua")
    love.thread.getChannel("fname"):push(histPath)
    thread.start(1)
end

local function quit()
end

local function draw()
end

local function update(dt)
end

local function keypressed(key)
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
}
