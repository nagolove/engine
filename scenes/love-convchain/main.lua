local lg = love.graphics
local suit = require "suit"
local convchain = require "convchain"

local textures = {}
local receptorSlider = {value = 3, min = 1, max = 4}
local temperatureSlider = {value = 1, min = -1, max = 2}
local seedSlider = {value = 12, min = 0, max = 100}
local iterationsSlider = {value = 10, min = 4, max = 320}
local resultSizeSlider = {value = 32, min = 16, max = 256}

function love.load(argv)
    for _, v in pairs(love.filesystem.getDirectoryItems("gfx")) do
        if string.find(v, ".png") then
            local imgData = love.image.newImageData("gfx/" .. v)
            local img = lg.newImage(imgData)
            assert(imgData)
            textures[#textures + 1] = {
                data = imgData,
                img = img,
                quad = lg.newQuad(0, 0, img:getWidth(), img:getHeight(), img:getWidth(), img:getHeight())
            }
        end
    end
    selectedTexture = #textures and 1 or -1
end

local w, h = lg.getDimensions()
local sliderStartX, sliderStartY = 0, 0
local SLIDER_HEIGHT = 16
local font = lg.newFont(14)
local samplePreviewY = 16

function love.update(dt)
    local x, y = sliderStartX, sliderStartY
    local gap = 10
    local sliderWidth = (w - gap * 5) / 5

    suit.Slider(receptorSlider, {font = font}, x, y, sliderWidth, SLIDER_HEIGHT)
    suit.Label(string.format("receptor size %d", receptorSlider.value), x, y + SLIDER_HEIGHT, sliderWidth, SLIDER_HEIGHT)

    x = x + sliderWidth + gap
    suit.Slider(temperatureSlider, {font = font}, x, y, sliderWidth, SLIDER_HEIGHT)
    suit.Label(string.format("temperature %.3f", temperatureSlider.value), x, y + SLIDER_HEIGHT, sliderWidth, SLIDER_HEIGHT)

    x = x + sliderWidth + gap
    suit.Slider(seedSlider, {font = font}, x, y, sliderWidth, SLIDER_HEIGHT)
    suit.Label(string.format("random generator seed %d", seedSlider.value), x, y + SLIDER_HEIGHT, sliderWidth, SLIDER_HEIGHT)

    x = x + sliderWidth + gap
    suit.Slider(iterationsSlider, {font = font}, x, y, sliderWidth, SLIDER_HEIGHT)
    suit.Label(string.format("iterations %d", iterationsSlider.value), x, y + SLIDER_HEIGHT, sliderWidth, SLIDER_HEIGHT)

    x = x + sliderWidth + gap
    suit.Slider(resultSizeSlider, {font = font}, x, y, sliderWidth, SLIDER_HEIGHT)
    suit.Label(string.format("result size %d", resultSizeSlider.value), x, y + SLIDER_HEIGHT, sliderWidth, SLIDER_HEIGHT)

    y = y + SLIDER_HEIGHT * 2
    x = sliderStartX
    suit.Label("For image generation press 'Space'", {font = font}, sliderStartX, y, w, SLIDER_HEIGHT)
    y = y + SLIDER_HEIGHT
    suit.Label("Change select sample patterns by mouse wheel", {font = font}, x, y, w, SLIDER_HEIGHT)
    samplePreviewY = y + SLIDER_HEIGHT
end

function love.draw()
    local x, y = 10, samplePreviewY
    local gap = 10
    for k, v in pairs(textures) do
        local img = v.img
        lg.draw(img, v.quad, x, y)
        if selectedTexture == k then
            lg.setColor{0.12, 0.3, 0.5}
            lg.setLineWidth(3)
            lg.rectangle("line", x, y, img:getWidth(), img:getHeight())
            lg.setColor{1, 1, 1}
        end
        x = x + img:getWidth() + gap
    end

    suit.draw()

    if outputImage then
        local scale = 1
        local x, y = (w - outputImage:getWidth() * scale) / 2, (h - outputImage:getHeight() * scale) / 2
        local q = lg.newQuad(0, 0, outputImage:getWidth(), outputImage:getHeight(), outputImage:getWidth(), outputImage:getHeight())
        lg.draw(outputImage, q, x, y, 0, scale, scale)
    end
end

function selectNextTexture()
	if selectedTexture + 1 <= #textures then
		selectedTexture = selectedTexture + 1
	end
end

function selectPrevTexture()
	if selectedTexture - 1 > 0 then
		selectedTexture = selectedTexture - 1
	end
end

function love.wheelmoved(x, y)
    if y == -1 then selectNextTexture()
    elseif y == 1 then selectPrevTexture() end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "left" then selectPrevTexture()
    elseif key == "right" then selectNextTexture()
    elseif key == "space" then
        if selectedTexture then
            local color = {1, 1, 1}
            local data = textures[selectedTexture].data
            imageData = convchain.gen(data, data:getWidth(), data:getHeight(), receptorSlider.value,
                temperatureSlider.value, resultSizeSlider.value, iterationsSlider.value, seedSlider.value, color)
            outputImage = lg.newImage(imageData)
        end
    end
end

