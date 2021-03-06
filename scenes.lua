local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; require("love")
require("log")
require("common")


function loadScenes(path)
   local scenes = {}
   local scenesNames = {}
   local files = love.filesystem.getDirectoryItems(path)
   for _, v in ipairs(files) do
      local info = love.filesystem.getInfo(path .. "/" .. v)
      local scene, fname, name
      if info.type == "directory" then
         fname = string.format("%s/%s%s", path, v, "/init.lua")
         name = v
      elseif info.type == "file" then
         fname = path .. "/" .. v
         name = string.match(v, "(.+)%.lua")
      end
      logf("loading scene %s", fname)
      local chunk, errmsg = love.filesystem.load(fname)
      if chunk then
         local ok, chunkerrmsg = pcall(function()


            scene = chunk()
         end)
         if ok and scene then
            table.insert(scenes, {
               scene = scene,
               name = name,
               inited = false,
            })
            table.insert(scenesNames, name)
         else
            if chunkerrmsg then
               logferror("Error: %s", errmsg)
            else
               logferror("No file for loading: %s", fname)
            end
         end
      else
         logferror("Could'not load %s", fname, errmsg)
      end
   end
   return scenes, scenesNames
end

local scenes, scenesNames = loadScenes("scenes")

local currentScene = nil

local function getScenes()
   return scenes
end

local function initInternal(v)
   if not v.inited and v.scene.init then
      local ok, errmsg = pcall(function()
         v.scene.init()
      end)
      if not ok then


         error(string.format("Could'not init scene %s: %s", v.name, errmsg))
      end
      v.inited = true
   end
end

local function setCurrentScene(sceneName)
   for _, v in ipairs(scenes) do
      if sceneName == v.name then
         initInternal(v)
         currentScene = v.scene
      end
   end
end

local function initLoaded()
   for _, v in ipairs(scenes) do
      initInternal(v)
   end
end

local function update(dt)
   if currentScene and currentScene.update then
      currentScene.update(dt)
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

   local path = "scenes/" .. name .. "/init.lua"
   print(string.format("initOne '%s'", path))
   local chunk, errmsg = love.filesystem.load(path)
   local node = {}
   if not chunk then
      error(string.format("Could not load '%s': %s", path, errmsg))
   end
   node.scene = chunk()
   if node.scene.init then
      print("------------ ↓↓↓↓↓↓↓↓↓↓ init ↓↓↓↓↓↓↓↓↓↓ ------------")
      node.scene.init()
      print("------------ ↑↑↑↑↑↑↑↑↑↑ init ↑↑↑↑↑↑↑↑↑↑ ------------")
   end
   node.name = name
   node.inited = true
   table.insert(scenes, node)
   currentScene = scenes[#scenes].scene
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

function getSceneNames()
   return scenesNames
end

return {
   getScenes = getScenes,
   getCurrentScene = getCurrentScene,
   getSceneNames = getSceneNames,
   setCurrentScene = setCurrentScene,

   initLoaded = initLoaded,
   initOne = initOne,
   update = update,
   draw = draw,
   drawui = drawui,
   keypressed = keypressed,
   keyreleased = keyreleased,
   mousemoved = mousemoved,
   mousereleased = mousereleased,
   mousepressed = mousepressed,
   wheelmoved = wheelmoved,
   quit = quit,
}
