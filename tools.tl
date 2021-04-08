--[[
-- нужна ли здесь динамическая загрузка? или можно обойтись require()?
local function loadTools(): {Tool}
    local tools: {Tool} = {}
    local files = love.filesystem.getDirectoryItems("")
    for _, file in ipairs(files) do
        if file:match("%.*tool%.lua") then
            local chunk, errmsg: any, string = love.filesystem.load(file)
            if chunk then
                local _, chunkerrmsg: boolean, string = pcall(function()
                    table.insert(tools, (chunk as function)() as Tool)
                end)
                if errmsg then
                    logferror("Error in %s: %s", file, chunkerrmsg)
                else
                    logf("Tool %s loaded", file)
                end
            else
                logferror("Error in loading %s %s", file, errmsg)
            end
        end
    end
    return tools
end

local tools: {Tool} = loadTools()

local devshow: boolean

--local function initTools(currentScene: Scene)
    --for _, v in ipairs(tools) do
        --if v.init then
            --v.init(currentScene)
        --end
    --end
--end

local function update()
    if devshow then
        for _, v in ipairs(tools) do
            if v.update then
                v.update()
            end
        end
    end
end

local function draw()
    if devshow then
        imgui.NewFrame()
        for _, v in ipairs(tools) do
            if v.draw then
                v.draw()
            end
        end
        love.graphics.setColor{1, 1, 1}
        imgui.Render();
    end
end

local function toggle()
    print("toggleTools")
    devshow = not devshow
end

local function keypressed(key: string)
    if not devshow then
        return
    end

    for _, v in ipairs(tools) do
        if v.keypressed then
            v.keypressed(key)
        end
    end
end

function mousemoved(x: number, y: number, dx: number, dy: number)
    if not devshow then
        return
    end

    for _, v in ipairs(tools) do
        if v.mousemoved then
            v.mousemoved(x, y, dx, dy)
        end
    end
end

function mousereleased(x: number, y: number, btn: number)
    if not devshow then
        return
    end

    for _, v in ipairs(tools) do
        if v.mousereleased then
            v.mousereleased(x, y, btn)
        end
    end
end

local function mousepressed(x: number, y: number, btn: number)
    if not devshow then
        return
    end

    for _, v in ipairs(tools) do
        if v.mousepressed then
            v.mousepressed(x, y, btn)
        end
    end
end

return {
    update = update,
    draw = draw,
    toggle = toggle,
    mousepressed = mousepressed,
    keypressed = keypressed,
    mousemoved = mousemoved,
    mousereleased = mousereleased,
}
--]]
