local imgui = require "imgui"

local tween = require "tween"

local currentShader
local gr = love.graphics
local progs = {}
local lightPos = {1, 2, 3}
local RayOrigin = {0, 3, -3}
local selectedFile = 1
local tex = love.graphics.newImage("assets/tex1.png")

local compilationErrors = {}

function findShaders()
    local shaderDirectory = "shaders"
    local files = love.filesystem.getDirectoryItems(shaderDirectory)
    local filteredFiles = {}
    for k, v in pairs(files) do
        if v:match(".*%.glsl") then
            local shader
            local filename = shaderDirectory .. "/" .. v
            local ok, errmsg = pcall(function()
                shader = gr.newShader(filename)
            end)
            if not ok then
                table.insert(compilationErrors, filename .. ":" .. errmsg)
            end
            if shader == nil then
                shader = {}
            end
            table.insert(progs, shader)
            table.insert(filteredFiles, v)
        end

        if v:match "raymarch2.+" then
            selectedFile = #progs
        end
    end
    return filteredFiles
end

function selectShader(n)
    selectedFile = n
    currentShader = progs[n]
end

love.load = function()
    files = findShaders()
    selectShader(selectedFile)
end

local img = gr.newImage("pic1.png")

local twObject = { qTime = 0.5 }
local tw = tween.new(30., twObject, { qTime = 1 }, "outBounce")

local w, h = gr.getDimensions()
local vertices = {
    {
        0, 0,
        0, 0,
        1, 1, 1, 1
    },
    {
        w, h,
        0, 0,
        1, 1, 1, 1
    },
    {
        0, h,
        0, 0,
        1, 1, 1, 1
    },

    {
        w, h,
        0, 0,
        1, 1, 1, 1
    },
    {
        w, 0,
        0, 0,
        1, 1, 1, 1
    },
    {
        0, 0,
        0, 0,
        1, 1, 1, 1
    },
}
local mesh = gr.newMesh(vertices, "triangles", "static")

local iCount = 10.

function safesend(shader, name, ...)
    if shader:hasUniform(name) then
        shader:send(name, ...)
    end
end

function RayOriginSetup()
    local lpX , stat = imgui.SliderFloat("ray x", RayOrigin[1], -100, 100)
    if stat then
        RayOrigin[1] = lpX
    end
    local lpY , stat = imgui.SliderFloat("ray y", RayOrigin[2], -100, 100)
    if stat then
        RayOrigin[2] = lpY
    end
    local lpZ , stat = imgui.SliderFloat("ray z", RayOrigin[3], -100, 100)
    if stat then
        RayOrigin[3] = lpZ
    end
end

function lightSetup()
    local lpX , stat = imgui.SliderFloat("light x", lightPos[1], -10, 10)
    if stat then
        lightPos[1] = lpX
    end
    local lpY , stat = imgui.SliderFloat("light y", lightPos[2], -10, 10)
    if stat then
        lightPos[2] = lpY
    end
    local lpZ , stat = imgui.SliderFloat("light z", lightPos[3], -10, 10)
    if stat then
        lightPos[3] = lpZ
    end
end

function hierarchyWindow()
    imgui.Begin("hierarchy", true, "ImGuiWindowFlags_AlwaysAutoResize")
    imgui.TreeNode("scene")
    imgui.TreePush("---")
    imgui.Text("blah-blah")
    imgui.TreePop()
    imgui.TreePush("---")
    imgui.Text("blah-blah")
    imgui.Text("blah-blah2")
    imgui.TreePop()
    imgui.End()
end

function shadersSelector()
    imgui.Begin("programs", true, "ImGuiWindowFlags_AlwaysAutoResize")
    local num, selected = imgui.ListBox("programs", selectedFile, files, #files, 5)
    if selected then
        selectShader(num)
    end
    lightSetup()
    RayOriginSetup()
    imgui.End()
end

function clearCompilationErrors()
    compilationErrors = {}
end

function compilationErrorsWindow()
    --if #compilationErrors ~= 0 then
    if true then
        imgui.Begin("compilation log", true, "ImGuiWindowFlags_AlwaysAutoResize")

        local ok = imgui.Button("clear")
        if ok then
            clearCompilationErrors()
        end
        for k, v in pairs(compilationErrors) do
            imgui.TextColored(1,0.5,1,1, v);
        end

        imgui.End()
    end
end

function ui()
    shadersSelector()
    compilationErrorsWindow()
    hierarchyWindow()

    imgui.Render()
end

love.draw = function()
    gr.setColor{1, 1, 1, 1}
    --gr.clear(1, 1, 1)
    local w, h = gr.getDimensions()

    --gr.setShader(sh1)
    --gr.rectangle("fill", 0, 0, w, h)

    --gr.setShader(sh2)
    

    mesh:setTexture(img)
    local mx, my = love.mouse.getPosition()
    if currentShader and type(currentShader) ~= "table" then
        safesend(currentShader, "iTime", love.timer.getTime())
        safesend(currentShader, "qTime", twObject.qTime)
        safesend(currentShader, "iTex", img)
        safesend(currentShader, "iCount", iCount)
        safesend(currentShader, "iResolution", {w, h})
        safesend(currentShader, "RayOrigin", RayOrigin)
        safesend(currentShader, "tex", tex)

        if love.keyboard.isDown("lshift") then
            safesend(currentShader, "iMouse", {mx, my})
        end

        safesend(currentShader, "lightPos", lightPos)

        gr.setShader(currentShader);
    else
        gr.setShader()
    end
    gr.draw(mesh)
    gr.setShader()

    gr.setColor(0, 0, 1)
    gr.print(string.format("fps %d", love.timer.getFPS()), 0, 0)
    gr.setColor(1, 1, 1)

    ui()
end

love.update = function(dt)
    imgui.NewFrame()
    tw:update(dt)
    local lk = love.keyboard
    if lk.isDown("z") then
        iCount = iCount + .1
    elseif lk.isDown("x") then
        iCount = iCount - .1
    end
end

function love.textinput(t)
   imgui.TextInput(t)
   if not imgui.GetWantCaptureKeyboard() then
       -- Pass event to the game
   end
end

function love.keypressed(_, key)
   imgui.KeyPressed(key)
   if not imgui.GetWantCaptureKeyboard() then
       tw = tween.new(30., twObject, { qTime = 1 }, "outBounce")
       if key == "a" then
           safesend(currentShader, "useFast", true)
       elseif key == "z" then
           safesend(currentShader, "useFast", false)
       end
       -- Pass event to the game
   end
end

function love.keyreleased(key)
   imgui.KeyReleased(key)
   if not imgui.GetWantCaptureKeyboard() then
       -- Pass event to the game
   end
end

function love.mousemoved(x, y)
   imgui.MouseMoved(x, y)
   if not imgui.GetWantCaptureMouse() then
       -- Pass event to the game
   end
end

function love.mousepressed(x, y, button)
   imgui.MousePressed(button)
   if not imgui.GetWantCaptureMouse() then
       -- Pass event to the game
   end
end

function love.mousereleased(x, y, button)
   imgui.MouseReleased(button)
   if not imgui.GetWantCaptureMouse() then
       -- Pass event to the game
   end
end

function love.wheelmoved(x, y)
   imgui.WheelMoved(y)
   if not imgui.GetWantCaptureMouse() then
       -- Pass event to the game
   end
end

