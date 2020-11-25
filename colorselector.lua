local rgb2hsv = require "hsx".rgb2hsv
local hsv2rgb = require "hsx".hsv2rgb
local gr = love.graphics
local h, s, v = 1, 1, 1
local r, g, b

local function drawColorWindow()
    imgui.Begin("hsv", true, "ImGuiWindowFlags_AlwaysAutoResize")

    --gr.clear(r, g, b)

    h, res = imgui.DragFloat("h", h, 0.01, 0, 1)
    s, res = imgui.DragFloat("s", s, 0.01, 0, 1)
    v, res = imgui.DragFloat("v", v, 0.01, 0, 1)
    r, g, b = hsv2rgb(h, s, v)

    __SELECTED_COLOR__ = {r, g, b}

    local pressed = imgui.Button("copy2clpbrd")
    if pressed then
        love.system.setClipboardText(string.format("{%f, %f, %f}", r, g, b))
    end

    imgui.End()
    gr.setColor{1, 1, 1, 1}
end

return {
    draw = drawColorWindow,
}

