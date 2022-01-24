local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local table = _tl_compat and _tl_compat.table or table


DEBUG_KEYCONFIG = false

require("love")
require("common")
require("list")



local inspect = require("inspect")
local lk = love.keyboard
local IsPressed = {}

local idGen = 0

 KeyConfig = {BindAccord = {}, Shortcut = {}, }
















































































local shortcutsDown = {}


local shortcutsPressed = {}




local BindReference = {}




local ids = {}

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

function KeyConfig.clear()
   shortcutsDown = {}

   ids = {}
end





function KeyConfig.prepareDrawing()
































end

function KeyConfig.draw(x, y)








end

function KeyConfig.updateList(dt)





end

function KeyConfig.getShortcutsDown()
   return shortcutsDown
end

function KeyConfig.getShortcutsPressed()
   return shortcutsPressed
end













function KeyConfig.compareMod(mod1, mod2)
   if mod1 and mod2 then
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
end

function KeyConfig.checkExistHotkey(list, combo)
   for _, shortcut in ipairs(list) do
      if DEBUG_KEYCONFIG then
         print("shortcut.combo.mod, combo.mod)", shortcut.combo.mod, combo.mod)
      end
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

   idGen = idGen + 1

   local map = {
      ["keypressed"] = shortcutsPressed,
      ["isdown"] = shortcutsDown,
   }
   local list = map[btype]
   if KeyConfig.checkExistHotkey(list, combo) then
      assert('hotkey ' .. KeyConfig.getHotkeyString(combo))
   end
   if DEBUG_KEYCONFIG then
      print("KeyConfig.bind()")
   end
   description = description or ""
   table.insert(list, {
      combo = shallowCopy(combo),
      action = action,
      description = description,
      enabled = true,
      id = id,
      intid = idGen,
   })
   if id then
      if DEBUG_KEYCONFIG then
         print("id", id)
         print("ids[id]", inspect(ids[id]))
      end
      if ids[id] then

      end
      ids[id] = { index = #list, list = list }
   end


   KeyConfig.prepareDrawing()
   return idGen
end

function KeyConfig.unbindid(id)
   local string_id_1, string_id_2
   for i, v in ipairs(shortcutsDown) do
      if v.intid == id then
         string_id_1 = v.id
         table.remove(shortcutsDown, i)
      end
   end
   for i, v in ipairs(shortcutsPressed) do
      if v.intid == id then
         string_id_2 = v.id
         table.remove(shortcutsPressed, i)
      end
   end
   if ids[string_id_1] then
      ids[string_id_1] = nil
   end
   if ids[string_id_2] then
      ids[string_id_2] = nil
   end
end

function KeyConfig.unbind(id)
   local ref = ids[id]
   if ref then









      table.remove(ref.list, ref.index)









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

   for _, stroke in ipairs(shortcuts) do
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
   local ref = ids[id]
   local sc = ref.list[ref.index]
   if sc and sc.enabled and sc.action then
      local rebuildlist, newsc = sc.action()
      if rebuildlist then
         ref.list[ref.index] = shallowCopy(newsc)
      end
   end
end

return KeyConfig
