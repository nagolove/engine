local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local table = _tl_compat and _tl_compat.table or table; require("love")
require("common")


local inspect = require("inspect")
local lk = love.keyboard
local IsPressed = {}

 KeyConfig = {BindAccord = {}, Shortcut = {}, }




























































local Shortcut = KeyConfig.Shortcut
local ActionFunc = KeyConfig.ActionFunc


local shortcutsDown = {}


local shortcutsPressed = {}

local List = require("list")

local shortcutsList = nil

local function combo2str(stroke)
   local res = ""
   if stroke.mod then
      for k, key in ipairs(stroke.mod) do
         res = res .. key
         if k < #stroke.mod then
            res = res .. " + "
         end
      end
      res = res .. " + " .. stroke.key
   else
      res = stroke.key
   end
   return '[' .. res .. ']'
end

function KeyConfig.prepareDrawing()
   shortcutsList = List.new(5, 5)
   for _, v in ipairs(shortcutsDown) do
      local message = v.description .. " " .. combo2str(v.combo)

      print("message", message)
      shortcutsList:add(message)
   end
   for _, v in ipairs(shortcutsPressed) do
      local message = v.description .. " " .. combo2str(v.combo)

      print("message", message)
      shortcutsList:add(message)
   end


   table.sort(shortcutsList.items, function(a, b)

      return a.message > b.message
   end)
   shortcutsList:done()
end

function KeyConfig.draw()
   if not shortcutsList then
      KeyConfig.prepareDrawing()
   end
   shortcutsList:draw()
end

function KeyConfig.updateList(dt)
   if shortcutsList then
      shortcutsList:update(dt)
   end
end

local ids = {}

function KeyConfig.compareMod(mod1, mod2)
   if #mod1 ~= #mod2 then
      return false
   else
      for i = 1, #mod1 do
         if mod1[i] ~= mod2[i] then
            return false
         end
      end
   end
   return true
end

function KeyConfig.checkExistHotkey(list, combo)
   for _, shortcut in ipairs(list) do
      if KeyConfig.compareMod(shortcut.combo.mod, combo.mod) and shortcut.combo.key == combo.key then
         return true
      end
   end
   return false
end

function KeyConfig.getHotkeyString(combo)
   local mod_str = ""
   for _, v in ipairs(combo.mod) do
      mod_str = mod_str .. v
   end
   return "[" .. mod_str .. "] + " .. combo.key
end

function KeyConfig.bind(
   btype,
   combo,
   action,
   description,
   id)

   description = description or ""
   local map = {
      ["keypressed"] = shortcutsPressed,
      ["isdown"] = shortcutsDown,
   }
   local list = map[btype]

   if KeyConfig.checkExistHotkey(list, combo) then

      assert('hotkey ' .. KeyConfig.getHotkeyString(combo))
   end
   table.insert(list, {
      combo = shallowCopy(combo),
      action = action,
      description = description,
      enabled = true,
   })
   if id then
      ids[id] = list[#list]
   end
end

function KeyConfig.printBinds()
   print("keypressed:")
   for _, stroke in ipairs(shortcutsPressed) do
      print("stroke", inspect(stroke))
   end
   print("end keypressed:")
   print("isdown:")
   for _, stroke in ipairs(shortcutsDown) do
      print("stroke", inspect(stroke))
   end
   print("end isdown:")
end

function KeyConfig.test(shortcuts, isPressed)
   for i, stroke in ipairs(shortcuts) do
      if stroke.enabled then
         local combo = stroke.combo
         local pressed = isPressed(combo.key)
         if pressed then

            if combo.mod then
               for _, mod in ipairs(combo.mod) do
                  pressed = pressed and lk.isScancodeDown(mod)
                  if not pressed then
                     break
                  end
               end
            end
            if pressed and stroke.action then
               local rebuildlist, newShortcut = stroke.action(stroke)
               if rebuildlist then
                  shortcutsList = nil
                  shortcuts[i] = shallowCopy(newShortcut)
               end
            end
         end
      end
   end
end



function KeyConfig.keypressed(key)
   KeyConfig.test(
   shortcutsPressed,
   function(str)
      return key == str
   end)

end


function KeyConfig.update()
   KeyConfig.test(
   shortcutsDown,
   function(str)
      return lk.isScancodeDown(str)
   end)

end

function KeyConfig.send(id)
   local sc = ids[id]
   if sc and sc.enabled and sc.action then
      local rebuildlist, newsc = sc.action()
      if rebuildlist then
         ids[id] = shallowCopy(newsc)
      end
   end
end

return KeyConfig
