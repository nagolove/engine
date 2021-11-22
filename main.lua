local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local os = _tl_compat and _tl_compat.os or os; local package = _tl_compat and _tl_compat.package or package; local pairs = _tl_compat and _tl_compat.pairs or pairs; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; require("jitoptions").on()
require("love")
require("common")
require("log")
require("keyconfig")
require('imgui')
require('pipeline')

if love.system.getOS() == 'Windows' then
   love.filesystem.setCRequirePath(love.filesystem.getCRequirePath() .. ";lib\\?.dll")
end
print("package.path", package.path)

local IMGUI_USE_STUB = false

local inspect = require("inspect")
local scenes = require("scenes")

local showHelp = false
local imguiFontSize = 22

local lt = love.thread
local threads = {}


local main_channel = love.thread.getChannel("main_channel")
local event_channel = lt.getChannel("event_channel")






local Shortcut = KeyConfig.Shortcut
local colorize = require('ansicolors2').ansicolors
local ecodes = require("errorcodes")
local format = string.format
local pipeline = Pipeline.new()

function threaderror(thread, errorstr)
   print('threaderror')
   local fmt = "Something wrong in thread %s with %s"
   print(format(fmt, tostring(thread), errorstr))
   os.exit(ecodes.ERROR_THREAD)
end

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

local function newThread(name)
   local path = "scenes/" .. name .. "/init.lua"

   print(colorize('%{yellow}' .. format('newThread("%s")', path)))
   local thread = love.thread.newThread(path)
   if not thread then
      error('No thread created.')
   end

   threads[path] = thread
   return thread
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









   local thread = newThread(sceneName)
   thread:start()





   local waitfor = 0.1
   love.timer.sleep(waitfor)

   pipeline:pullRenderCode()

   print('threads', colorize('%{magenta}' .. inspect(threads)))




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


end

function love.resize(_, _)

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

function love.keypressed(_, key)
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

function pullMainChannel()
   local cmd = main_channel:pop()
   if cmd and type(cmd) == 'string' then
      if cmd == 'quit' then
         print(colorize('%{cyan}quit event'))
         love.event.quit()
      end
   end
end

function love.run()
   local tmp = require('parse_args')
   if love.load then love.load(tmp.parseGameArguments(arg)) end


   if love.timer then love.timer.step() end

   local dt = 0.
   local time = love.timer.getTime()


   return function()


      if love.event then
         love.event.pump()
         local events = {}
         for name, a, b, c, d, e, f in love.event.poll() do

            if name == "quit" then
               if not love.quit or not love.quit() then


                  return (a or 0)
               end
            end
            table.insert(events, { name, a, b, c, d, e, f })


         end
         event_channel:push(events)
      end

      local nt = love.timer.getTime()
      dt = nt - time
      time = nt



      for _, t in pairs(threads) do
         local errmsg = t:getError()
         if errmsg then
            errmsg = colorize("%{cyan}" .. errmsg .. "%{reset}")
            print(colorize('%{red}Error in thread'), errmsg)
            os.exit(ecodes.ERROR_THREAD)
         end
      end


      if love.timer then dt = love.timer.step() end


      if love.update then love.update(dt) end

      pipeline:pullRenderCode()
      pullMainChannel()

      if love.graphics and love.graphics.isActive() then
         love.graphics.origin()



         pipeline:waitForReady()
         pipeline:render()

         love.graphics.present()
      end


      local sleep_time = 0.001
      if love.timer then
         love.timer.sleep(sleep_time)
      end

   end
end
