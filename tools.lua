local tools = {}

tools[1] = love.filesystem.load("colorselector.lua")()
tools[2] = love.filesystem.load("box2dtool.lua")()
tools[3] = love.filesystem.load("cameratool.lua")()
tools[4] = love.filesystem.load("hotkeystool.lua")()
tools[5] = love.filesystem.load("terraintool.lua")()
tools[6] = love.filesystem.load("particlestool.lua")()
tools[7] = love.filesystem.load("shiptool.lua")()

local devshow 

function initTools(currentScene)
    for k, v in pairs(tools) do
        if v.init then
            v.init(currentScene)
        end
    end
end

function updateTools()
    if devshow then
        for k, v in pairs(tools) do
            if v.update then
                v.update()
            end
        end
    end
end

function drawTools()
    if devshow then
        imgui.NewFrame()
        for k, v in pairs(tools) do
            if v.draw then
                v.draw()
            end
        end
        love.graphics.setColor{1, 1, 1}
        imgui.Render();
    end
end

function toggleTools()
    devshow = not devshow
end

function keypressedTools(key)
    if not devshow then
        return
    end

    for k, v in pairs(tools) do
        if v.keypressed then
            v.keypressed(key)
        end
    end
end

function mousemovedTools(x, y, dx, dy)
    if not devshow then
        return
    end

    for k, v in pairs(tools) do
        if v.mousemoved then
            v.mousemoved(x, y, dx, dy)
        end
    end
end

function mousereleasedTools(x, y, btn)
    if not devshow then
        return
    end

    for k, v in pairs(tools) do
        if v.mousereleased then
            v.mousereleased(x, y, btn)
        end
    end
end

function mousepressedTools(x, y, btn)
    if not devshow then
        return
    end

    for k, v in pairs(tools) do
        if v.mousepressed then
            v.mousepressed(x, y, btn)
        end
    end
end
