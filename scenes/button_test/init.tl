local btn = require "button".new("hz", 100, 100, 64, 128)

local function init()
    --btn.onRelease = function(Button b)
    --end

    btn.onMouseReleased = function(_: Button)
        print("onMouseReleased")
    end

end

local function draw()
    btn:draw()
end

local function update(dt: number)
    btn:update(dt)
end

local function quit()

end

local function mousereleased(x: number, y: number, mouseBtn: number)
    print("button_test :: mousereleased")
    btn:mouseReleased(x, y, mouseBtn)
end

return {
    init = init,
    draw = draw,
    update = update,
    quit = quit,
    mousereleased = mousereleased,
}
