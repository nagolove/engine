local btn = require("button").new("hz", 100, 100, 64, 128)

local function init()



   btn.onMouseReleased = function(_)
      print("onMouseReleased")
   end

end

local function draw()
   btn:draw()
end

local function update(dt)
   btn:update(dt)
end

local function quit()

end

local function mousereleased(x, y, mouseBtn)
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
