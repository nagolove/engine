local cam = require "camera".new()
local timer = require "Timer"()
local lg = love.graphics
local colors = {
    { 0, 0, 0, 0 },
    { 61 / 255, 193 / 255, 211 / 255, 1
    }, { 87 / 255, 75 / 255, 144 / 255, 1 },
    { 245 / 255, 205 / 255, 121 / 255, 1 },
    { 247 / 255, 143 / 255, 179 / 255, 1 }
}
local antColor = { 89 / 255, 98 / 255, 117 / 255, 1.0 }
local grid = { }
local ants = { }
local width = 500
local height = 500
local cells = width * height
local centerX = math.floor(width / 2)
local centerY = math.floor(height / 2)
local imageData = love.image.newImageData(width, height)
local image = lg.newImage(imageData)
image:setFilter("nearest")
love.graphics.setBackgroundColor(48 / 255, 57 / 255, 82 / 255)
local firstReset = true
local updateDelta = 0
local waitReset = false
local resetTimer = 0
local resetTime = 3
local filled = 0
local clearMode = false
local nextStep
nextStep = function(i)
    if i == 1 then
        filled = filled + 1
    end
    i = i + 1
    if i == #colors + 1 then
        i = 2
    end
    return i
end

function antsReset()

    grid = { }
    ants = { }
    updateDelta = 0
    waitReset = false
    resetTimer = 0
    filled = 0
    if not firstReset then
        imageData:mapPixel(function()
            return 0, 0, 0, 0
        end)
        image:replacePixels(imageData)
    else
        firstReset = false
    end
    local i = 0
    while i < width do
        grid[i] = { }
        local j = 0
        while j < height do
            grid[i][j] = 1
            j = j + 1
        end
        i = i + 1
    end
    for x = (centerX - 3), (centerX + 3) do
        for y = (centerY - 3), (centerY + 3) do
            table.insert(ants, {
                x = x,
                y = y
            })
        end
    end
end

local updateEach = 0.01
local modeSpeed = 0.1

function antsUpdate(dt)
  if filled >= cells - 100 then
    modeSpeed = 0.5
    clearMode = true
    local startup = false
  end
  if filled <= 600 and clearMode then
    clearMode = false
    modeSpeed = 0
  end
  if modeSpeed <= 1 and modeSpeed >= 0 then
    if clearMode then
      modeSpeed = modeSpeed - (dt / 10)
    else
      modeSpeed = modeSpeed + (dt / 10)
    end
    if modeSpeed > 1 then
      modeSpeed = 1
    end
    if modeSpeed < 0 then
      modeSpeed = 0
    end
  end
  updateDelta = updateDelta + dt
  while updateDelta > updateEach do
    for i, ant in ipairs(ants) do
      imageData:setPixel(ant.x, ant.y, unpack(colors[grid[ant.x][ant.y]]))
      ant.x = ant.x + (math.floor(love.math.random(3)) - 2)
      ant.y = ant.y + (math.floor(love.math.random(3)) - 2)
      if ant.x < 0 then
        ant.x = 0
      else
        if ant.x > width - 1 then
          ant.x = width - 1
        end
      end
      if ant.y < 0 then
        ant.y = 0
      else
        if ant.y > height - 1 then
          ant.y = height - 1
        end
      end
      if (i / #ants) > modeSpeed then
        if grid[ant.x][ant.y] > 1 then
          filled = filled - 1
        end
        grid[ant.x][ant.y] = 1
      else
        grid[ant.x][ant.y] = nextStep(grid[ant.x][ant.y])
      end
      image:replacePixels(imageData)
    end
    updateDelta = updateDelta - updateEach
  end
end

function drawMasked(bg)
  love.graphics.setBlendMode("alpha")
  cam:attach()
  love.graphics.draw(image)
  cam:detach()
  bg()
  love.graphics.draw(mask)
  love.graphics.print(love.timer.getFPS(),16,16)
end

function updateMask()
    love.graphics.setCanvas(mask)
    local mode, alphamode = lg.getBlendMode()
    love.graphics.setBlendMode("multiply","premultiplied")
    love.graphics.clear(0,0,0)
    local x, y = love.mouse.getPosition()
    love.graphics.draw(hole, x, y, 0, 2, 2, hole:getWidth()/2, hole:getHeight()/2)
    love.graphics.setCanvas()
    lg.setBlendMode(mode, alphamode)
end

function initMask()
    mask = love.graphics.newCanvas()
    love.graphics.setCanvas(mask)
    love.graphics.clear(0,0,0)
    love.graphics.setCanvas()

    hole = love.graphics.newImage('Hole.png')
end

function love.load()
    initMask()
    antsReset()
end

function love.update(dt)
    timer:update(dt)
    updateMask()
    antsUpdate(dt)

    local mx, my = love.mouse.getPosition()
    cam:lookAt(mx, my)
end

function love.wheelmoved(x, y)
    if y == 1 then
        timer:during(0.5, function()
            cam:zoom(1.01)
        end)
    elseif y == -1 then
        timer:during(0.5, function()
            cam:zoom(0.99)
        end)
    end
end

function love.draw()
  --lg.scale(5)
  --return lg.draw(image)
  drawMasked(function()
      --lg.draw(image)
  end)
end
