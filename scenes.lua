local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string


require("love")
require("log")
require("common")



local currentScene = nil

local function update(dt)
   if currentScene and currentScene.update then
      currentScene.update(dt)
   end
end

local function resize(neww, newh)
   if currentScene and currentScene.resize then
      currentScene.resize(neww, newh)
   end
end

local function draw()
   if currentScene and currentScene.draw then
      currentScene.draw()
   end
end

local function drawui()
   if currentScene and currentScene.drawui then
      currentScene.drawui()
   end
end

local function keypressed(key)
   if currentScene and currentScene.keypressed then
      currentScene.keypressed(key)
   end
end

local function initOne(name)
   local errmsg
   local ok = false

   local path = "scenes/" .. name .. "/init.lua"
   print(string.format("initOne '%s'", path))
   local chunk
   chunk, errmsg = love.filesystem.load(path)
   local node = {}
   if not chunk then
      error(string.format("Could not load '%s': %s", path, errmsg))
   end




   local ok2, errmsg2 = pcall(function()
      node.scene = (chunk)()
   end)

   if not ok2 then
      error('Something wrong in chunk:' .. errmsg2)
   end

   local ok3, errmsg3 = pcall(function()
      if node.scene.init then
         print("------------ ↓↓↓↓↓↓↓↓↓↓ init ↓↓↓↓↓↓↓↓↓↓ ------------")



         node.scene.init()
         print("------------ ↑↑↑↑↑↑↑↑↑↑ init ↑↑↑↑↑↑↑↑↑↑ ------------")
      end
   end)

   if not ok3 then
      error('Something wrong in chunk:' .. errmsg3)
   end

   node.name = name
   node.inited = true
   currentScene = node.scene
end

local function mousemoved(x, y, dx, dy)
   if currentScene and currentScene.mousemoved then
      currentScene.mousemoved(x, y, dx, dy)
   end
end

local function mousereleased(x, y, btn)
   if currentScene and currentScene.mousereleased then
      currentScene.mousereleased(x, y, btn)
   end
end

local function mousepressed(x, y, btn)
   if currentScene and currentScene.mousepressed then
      currentScene.mousepressed(x, y, btn)
   end
end

local function keyreleased(_, key)
   if currentScene and currentScene.keyreleased then
      currentScene.keyreleased(key)
   end
end

local function wheelmoved(x, y)
   if currentScene and currentScene.wheelmoved then
      currentScene.wheelmoved(x, y)
   end
end

local function quit()
   if currentScene and currentScene.quit then
      currentScene.quit()
   end
end

local function getCurrentScene()
   return currentScene
end

local function textinput(text)
   if currentScene and currentScene.textinput then
      currentScene.textinput(text)
   end
end

return {



   getCurrentScene = getCurrentScene,
   initOne = initOne,
   update = update,
   draw = draw,
   drawui = drawui,
   textinput = textinput,
   keypressed = keypressed,
   keyreleased = keyreleased,
   mousemoved = mousemoved,
   mousereleased = mousereleased,
   mousepressed = mousepressed,
   wheelmoved = wheelmoved,
   resize = resize,
   quit = quit,
}
