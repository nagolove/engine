local scenes = require "scenes"
local currentSceneNum = 1

local function init()
end

local function draw()
    imgui.Begin("scenes", true, "ImGuiWindowFlags_AlwaysAutoResize")
    local scns = {}
    for k, v in pairs(scenes.getScenes()) do
        table.insert(scns, v.name)
    end
    --local num, selected = imgui.ListBox("scenes", currentSceneNum, scenesNames, #scenesNames, 5)
    --local num, selected = imgui.ListBox("scenes", currentSceneNum, scns, #scns, 5)
    local num, selected = imgui.ListBox("scenes", currentSceneNum, scns, #scns)
    if selected then
        currentSceneNum = num
    end

    if imgui.Button("select") then
        print("currentSceneNum", currentSceneNum)
        scenes.setCurrentScene(scns[currentSceneNum])
    end

    imgui.End()
end

local function update(dt)
end

local function mousemoved(x, y)
end

local function keypressed(key)
end

local function mousepressed(x, y, btn)
end

local function mousereleased(x, y, btn)
end

return {
    init = init,
    draw = draw,
    update = update,
    mousemoved = mousemoved,
    keypressed = keypressed,
    mousepressed = mousepressed,
    mousereleased = mousereleased,
}

