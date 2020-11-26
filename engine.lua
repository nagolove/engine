local inspect = require "inspect"
local gr = love.graphics
local img = gr.newImage("gfx/fire1.png")
local vec2 = require "vector-light"
local ps
local lastTime
require "log"

local scale, x, y = 0.031, 10.309, 0
local imgScale = 0.062

local function init()
    log("engine init")
    ps = gr.newParticleSystem(img)

    ps:setParticleLifetime(1, 3) -- Particles live at least 2s and at most 5s.
    ps:setEmissionRate(50)
    ps:setSizeVariation(1)
    ps:setColors(1, 1, 1, 1, 1, 1, 1, 0) -- Fade to transparency.
    ps:setLinearAcceleration(0, 1, 0, -100)
    
    lastTime = love.timer.getTime()
end

local function setLinearAcceleration(direction)
    --print("len", vec2.len(direction[1], direction[2]))
    local d = { direction[1], direction[2] }
    d[1], d[2] = vec2.mul(100, d[1], d[2])
end

--[[
-- points - table with x, y pairs of drawing points
-- direction - table vector
-- thrust - percentage 0..1
--]]
local function draw(points, direction, thrust)
    local tx, ty = vec2.normalize(-direction[1], -direction[2])

    function getPos(i, j)
        local lx, ly = points[i], points[j]
        lx, ly = vec2.add(lx, ly, vec2.mul(img:getHeight() * scale, tx, ty))
        return lx, ly
    end

    local angle = vec2.toPolar(direction[1], direction[2])
    gr.setColor{1, 1, 1}

    local x1, y1 = getPos(1, 2)
    x1, y1 = vec2.add(x1, y1, vec2.mul(x, vec2.perpendicular(tx, ty)))
    gr.draw(ps, x1, y1, angle + math.pi * 3 / 2, imgScale)

    local x2, y2 = getPos(3, 4)
    x2, y2 = vec2.add(x2, y2, vec2.mul(-x, vec2.perpendicular(tx, ty)))
    gr.draw(ps, x2, y2, angle + math.pi * 3 / 2, imgScale)
end

local function update()
    local now = love.timer.getTime()
    ps:update(now - lastTime)
    lastTime = now
end

local function getEmissionRate()
    return ps and ps:getEmissionRate() or nil
end

local function getScale()
    return scale
end

local function setScale(v)
    scale = v
end

local function setX(v)
    x = v
end

local function setY(v)
    y = v
end

local function getX()
    return x
end

local function getY()
    return y
end

local function getImgScale()
    return imgScale
end

local function setImgScale(v)
    imgScale = v
end

return {
    init = init,
    draw = draw,
    update = update,

    getEmissionRate = getEmissionRate,
    getScale = getScale,
    setScale = setScale,
    setX = setX,
    setY = setY,
    getX = getX,
    getY = getY,
    getImgScale = getImgScale,
    setImgScale = setImgScale,
}
