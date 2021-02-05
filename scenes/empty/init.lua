require("love")
love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/empty/?.lua")
local i18n = require("i18n")







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
   i18n.set('en.welcome', 'welcome to this program')
   i18n.load({
      en = {
         good_bye = "good-bye!",
         age_msg = "your age is %{age}.",
         phone_msg = {
            one = "you have one new message.",
            other = "you have %{count} new messages.",
         },
      },
   })
   print("translated", i18n.translate('welcome'))
   print("translated", i18n('welcome'))
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
