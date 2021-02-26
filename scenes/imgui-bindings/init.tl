--require "love-imgui"
require "imgui"

local showTestWindow = false
local showAnotherWindow = false
local floatValue = 0
local sliderFloat = { 0.1, 0.5 }
local clearColor = { 0.2, 0.2, 0.2 }
local comboSelection = 1
local textValue = "text"

--
-- LOVE callbacks
--
local function init()
end

local function update(dt: number)
    imgui.NewFrame()
end

local function draw()

    -- Menu
    if imgui.BeginMainMenuBar() then
        if imgui.BeginMenu("File") then
            imgui.MenuItem("Test")
            imgui.EndMenu()
        end
        imgui.EndMainMenuBar()
    end

    -- Debug window
    imgui.Text("Hello, world!")
    clearColor[1], clearColor[2], clearColor[3] = imgui.ColorEdit3("Clear color", clearColor[1], clearColor[2], clearColor[3])
    
    -- Sliders
    floatValue = imgui.SliderFloat("SliderFloat", floatValue, 0.0, 1.0)
    sliderFloat[1], sliderFloat[2] = imgui.SliderFloat2("SliderFloat2", sliderFloat[1], sliderFloat[2], 0.0, 1.0)
    
    -- Combo
    comboSelection = imgui.Combo("Combo", comboSelection, { "combo1", "combo2", "combo3", "combo4" }, 4)

    -- Windows
    if imgui.Button("Test Window") then
        showTestWindow = not showTestWindow
    end
    
    if imgui.Button("Another Window") then
        showAnotherWindow = not showAnotherWindow
    end
    
    if showAnotherWindow then
        imgui.SetNextWindowPos(50, 50, "FirstUseEver")
        showAnotherWindow = imgui.Begin("Another Window", true, "AlwaysAutoResize|NoTitleBar")
        imgui.Text("Hello")
        -- Input text
        textValue = imgui.InputTextMultiline("InputText", textValue, 200, 300, 200)
        imgui.End()
    end

    if showTestWindow then
        showTestWindow = imgui.ShowDemoWindow(true)
    end

    love.graphics.clear(clearColor)
    imgui.Render()
end

function love.quit()
    imgui.ShutDown()
end

local function textinput(t: string)
    imgui.TextInput(t)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

local function keypressed(key: string)
    imgui.KeyPressed(key)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

local function keyreleased(key: string)
    imgui.KeyReleased(key)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

local function mousemoved(x: number, y: number)
    imgui.MouseMoved(x, y)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

local function mousepressed(_: number, _: number, button: number)
    imgui.MousePressed(button)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

local function mousereleased(_: number, _: number, button: number)
    imgui.MouseReleased(button)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

local function wheelmoved(_: number, y: number)
    imgui.WheelMoved(y)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

return {
    textinput = textinput,
    keypressed = keypressed,
    keyreleased = keyreleased,
    mousemoved = mousemoved,
    mousepressed = mousepressed,
    mousereleased = mousereleased,
    wheelmoved = wheelmoved,
}
