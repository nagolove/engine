local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local package = _tl_compat and _tl_compat.package or package; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; require("jitoptions").on()

require("love")



print("package.path", package.path)

if love.system.getOS() == 'Windows' then
   print('1 getCRequirePath() = ', love.filesystem.getCRequirePath())
   love.filesystem.setCRequirePath(love.filesystem.getCRequirePath() .. ";lib\\?.dll")
   print('2 getCRequirePath() = ', love.filesystem.getCRequirePath())
end

require('imgui')
local IMGUI_USE_STUB = false

local inspect = require("inspect")
local scenes = require("scenes")

require("common")
require("log")
require("keyconfig")

local showHelp = false
local gr = love.graphics
local imguiFontSize = 22

love.filesystem.write("syslog.txt", "identity = " .. love.filesystem.getIdentity())

local Shortcut = KeyConfig.Shortcut

local function bindKeys()
   KeyConfig.bind(
   "keypressed",
   { key = "f1" },
   function(sc)
      print("tools toggle")
      showHelp = not showHelp
      return false, sc
   end,
   "show hotkeys and documentation",
   "help")


   KeyConfig.bind(
   "isdown",
   { key = "f2" },
   function(sc)
      print("keybind example")
      return false, sc
   end,
   "keybind example",
   "nope")

end

function printGraphicsInfo()
   local name, version, vendor, device = love.graphics.getRendererInfo()
   print(name, version, vendor, device)
   local stats = love.graphics.getStats()
   print("stats", inspect(stats))
   local features = love.graphics.getSupported()
   print("features", inspect(features))
   local limits = love.graphics.getSystemLimits()
   print("limits", inspect(limits))
   local texturetypes = love.graphics.getTextureTypes()
   print("texturetypes", inspect(texturetypes))


   local imageformats = love.graphics.getImageFormats()
   print("imageformats", inspect(imageformats))
   local canvasformats = love.graphics.getCanvasFormats()
   print("canvasformats", inspect(canvasformats))
end


local function searchArg(arg, paramName)
   if type(paramName) ~= 'string' then
      error(string.format('searchArg() paramName =  "%s"', paramName or ""))
   end
   print("searchArg", paramName)

   for _, v in ipairs(arg) do
      if v == paramName then
         return true
      end
   end

   return false
end


local function findCommand(arg)
   local commands = {}
   for i = 1, #arg do
      local s = arg[i]
      local ok, errmsg = pcall(function()
         if string.sub(s, 1, 1) ~= '-' and string.sub(s, 2, 2) ~= '-' then
            table.insert(commands, s)
         end
      end)
      if not ok then
         error('something strange in findCommand: ' .. errmsg)
      end
   end


   if #commands > 1 then
      colprint('More then one command, sorry.')
      return nil
   end










   return commands[1]
end














function love.load(arg)
   if not IMGUI_USE_STUB then
      imgui.Init()
      imgui.SetGlobalFontFromArchiveTTF("fonts/DroidSansMono.ttf", imguiFontSize)
   end
   printGraphicsInfo()
   bindKeys()

   if searchArg(arg, '--debug') then
      require("mobdebug").start()
   end

   if searchArg(arg, '--silent') then
      require("mobdebug").start()
   end










   print("love.load() arg", inspect(arg))

   local sceneName = findCommand(arg)








   print("sceneName", sceneName)
   if sceneName then
      scenes.initOne(sceneName)
   else
      colprint("Empty scene will be runned.")
      scenes.initOne("empty")
   end



end

local lastGCTime = love.timer.getTime()
local GCPeriod = 1 * 60 * 5


local function collectGarbage()
   local now = love.timer.getTime()
   if now - lastGCTime > GCPeriod then
      collectgarbage()
      lastGCTime = now
   end
end

local lastWindowHeaderUpdateTime = love.timer.getTime()
local quant = 1
local titlePrefix = "caustic engine "


function love.update(dt)
   local now = love.timer.getTime()
   if now - lastWindowHeaderUpdateTime > quant then
      love.window.setTitle(titlePrefix .. love.timer.getFPS())
   end

   if showHelp then
      KeyConfig.updateList(dt)
   end
   KeyConfig.update()
   collectGarbage()

   scenes.update(dt)
end

function love.resize(w, h)
   scenes.resize(w, h)
end

function love.draw()
   gr.setColor({ 1, 1, 1 })
   scenes.draw()
   gr.setColor({ 1, 1, 1 })

   if not IMGUI_USE_STUB then
      imgui.NewFrame()
      scenes.drawui()
      imgui.Render();
   end

   if showHelp then
      KeyConfig.draw()
   end
end

function love.quit()
   scenes.quit()
   if not IMGUI_USE_STUB then
      imgui.ShutDown();
   end
end

function love.textinput(t)
   if not IMGUI_USE_STUB then
      imgui.TextInput(t)
      if not imgui.GetWantCaptureKeyboard() then

         scenes.textinput(t)
      end
   end
end









function love.keyreleased(key, _)

   if not IMGUI_USE_STUB then
      imgui.KeyReleased(key)
      if not imgui.GetWantCaptureKeyboard() then
         scenes.keyreleased(key)
      end
   end
end


function love.keypressed(key)
   print(key)
   if not IMGUI_USE_STUB then
      imgui.KeyPressed(key)
      if not imgui.GetWantCaptureKeyboard() then
         KeyConfig.keypressed(key)
         scenes.keypressed(key)

      end
   end
end

function love.mousemoved(x, y, dx, dy)
   if not IMGUI_USE_STUB then
      imgui.MouseMoved(x, y)
      if not imgui.GetWantCaptureMouse() then

         scenes.mousemoved(x, y, dx, dy)
      end
   end
end

function love.mousepressed(x, y, button)
   if not IMGUI_USE_STUB then
      imgui.MousePressed(button)
      if not imgui.GetWantCaptureMouse() then

         scenes.mousepressed(x, y, button)
      end
   end
end

function love.mousereleased(x, y, button)
   if not IMGUI_USE_STUB then
      imgui.MouseReleased(button)
      if not imgui.GetWantCaptureMouse() then

         scenes.mousereleased(x, y, button)
      end
   end
end

function love.wheelmoved(x, y)
   if not IMGUI_USE_STUB then
      imgui.WheelMoved(y)
      if not imgui.GetWantCaptureMouse() then
         scenes.wheelmoved(x, y)
      end
   end
end

function love.run()

   local tmp = require('parse_args')

   if love.load then love.load(tmp.parseGameArguments(arg)) end


   if love.timer then love.timer.step() end

   local dt = 0.


   return function()

      if love.event then
         love.event.pump()
         for name, a, b, c, d, e, f in love.event.poll() do

            if name == "quit" then
               if not love.quit or not love.quit() then


                  return (a or 0)
               end
            end
            tmp.callHandler(name, a, b, c, d, e, f)

         end
      end


      if love.timer then dt = love.timer.step() end




      if love.update then love.update(dt) end

      if love.graphics and love.graphics.isActive() then
         love.graphics.origin()
         love.graphics.clear(love.graphics.getBackgroundColor())

         if love.draw then love.draw() end

         love.graphics.present()
      end

      if love.timer then love.timer.sleep(0.001) end

   end
end
