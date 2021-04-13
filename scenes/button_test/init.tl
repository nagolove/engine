local btn = require "button".new("hz", 100, 100, 64, 128)

local function init()

end

local function draw()
    btn:draw()
end

local function update(dt: number)
    btn:update(dt)
end

local function quit()

end

return {
    init = init,
    draw = draw,
    update = update,
    quit = quit,
}
