local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; require("log")
require("common")
require("love")
local imgui = require("imgui")

local function loadTools()
   local tools = {}
   local files = love.filesystem.getDirectoryItems("")
   for _, file in ipairs(files) do
      if file:match("%.*tool%.lua") then
         local chunk, errmsg = love.filesystem.load(file)
         if chunk then
            local _, chunkerrmsg = pcall(function()
               table.insert(tools, (chunk)())
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

local tools = loadTools()

local devshow

function initTools(currentScene)
   for _, v in ipairs(tools) do
      if v.init then
         v.init(currentScene)
      end
   end
end

function updateTools()
   if devshow then
      for _, v in ipairs(tools) do
         if v.update then
            v.update()
         end
      end
   end
end

function drawTools()
   if devshow then
      imgui.NewFrame()
      for _, v in ipairs(tools) do
         if v.draw then
            v.draw()
         end
      end
      love.graphics.setColor({ 1, 1, 1 })
      imgui.Render()
   end
end

function toggleTools()
   print("toggleTools")
   devshow = not devshow
end

function keypressedTools(key)
   if not devshow then
      return
   end

   for _, v in ipairs(tools) do
      if v.keypressed then
         v.keypressed(key)
      end
   end
end

function mousemovedTools(x, y, dx, dy)
   if not devshow then
      return
   end

   for _, v in ipairs(tools) do
      if v.mousemoved then
         v.mousemoved(x, y, dx, dy)
      end
   end
end

function mousereleasedTools(x, y, btn)
   if not devshow then
      return
   end

   for _, v in ipairs(tools) do
      if v.mousereleased then
         v.mousereleased(x, y, btn)
      end
   end
end

function mousepressedTools(x, y, btn)
   if not devshow then
      return
   end

   for _, v in ipairs(tools) do
      if v.mousepressed then
         v.mousepressed(x, y, btn)
      end
   end
end
