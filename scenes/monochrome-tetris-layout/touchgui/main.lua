onAndroid = love.system.getOS() == "Android"

local lg = love.graphics
log = require "log".newLog("visualdoj.ru", 10082)
local inspect = require "inspect"
local Button = require "button"
local Container = require "container"
local HSlider = require "slider"
local Camera = require "camera"
local Object = require "object"

local objects = Container:new()
local cam = Camera.new()

Object.cam = cam

function love.load()
    --print(inspect(Button))
    local bw, bh = 64, 64
    for i = 1, 4 do
        for j = 1, 4 do
            local b = Button:new((i - 1) * (bw + 5), (j - 1) * (bh + 5), 
                64, 64)
            objects:add(b)
            if (i % 2 == 0) then
                b.caption = (j % 2 == 0) and tonumber(i) or "btn " ..
                    tonumber(j)
            end
        end
    end

    local last = objects.objects[#objects.objects]
    last.onpress = function() love.event.quit() end
    last.caption = "Exit"
    last.color = {0.8, 0.1, 0.1}
    last.hoveredColor = {1, 0.2, 0.2}

    if onAndroid then
        love.window.setMode(0, 0, {fullscreen = true})
    end

    local pixw, pixh = love.window.toPixels(lg.getDimensions())
    local w, h = lg.getDimensions()
    log:print(string.format("%d * %d, pixelvalue %d * %d", w, h, pixw, pixh))
    local sliderH = 24
    local slider = HSlider:new(0, h - sliderH, w, 24)
    slider.onpress = function() cam.scale = cam.scale * 0.9 end
    objects:add(slider)
end

function love.mousemoved(x, y, dx, dy, istouch)
    if love.keyboard.isDown("lshift") then
        cam.x = cam.x - dx
        cam.y = cam.y - dy
    end
    objects:mousemoved(x, y, dx, dy, istouch)
end

function love.mousepressed(x, y, button, istouch, presses)
    objects:mousepressed(x, y, button, istouch, presses)
end

function love.wheelmoved(x, y)
    if y == -1 then
        cam.scale = cam.scale * 0.9
    elseif y == 1 then
        cam.scale = cam.scale * 1.1
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    objects:touchpressed(id, x, y, dx, dy, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    objects:touchreleased(id, x, y, dx, dy, pressure)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    objects:touchmoved(id, x, y, dx, dy, pressure)
end

function love.draw()
    cam:attach()
    objects:draw()
    cam:detach()
end

function love.update(dt)
    objects:update(dt)
end

