require("love")
love.filesystem.setRequirePath("scenes/empty/?.lua")







local gr = love.graphics








local function drawui()
end

local function draw()
   gr.clear(0.5, 0.5, 0.5)
   gr.setColor({ 0, 0, 0 })
   gr.print("TestTest")
end

local function update(dt)
end

local function keypressed(key)
   if key == "escape" then
      love.event.quit()
   end
end

local function init()
end

local function quit()
end

local function mousemoved(x, y, _, _)
end

local function wheelmoved(x, y)
end

return {
   init = init,
   quit = quit,
   draw = draw,
   drawui = drawui,
   update = update,
   keypressed = keypressed,
   mousemoved = mousemoved,
   wheelmoved = wheelmoved,
}
