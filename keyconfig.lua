local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local pairs = _tl_compat and _tl_compat.pairs or pairs; local table = _tl_compat and _tl_compat.table or table
require("love")
local lk = love.keyboard
local lg = love.graphics

local Shortcut = {}






 KeyConfig = {}












local shortcutsDown = {}


local shortcutsPressed = {}

local List = require("list")
local shortcutsList = nil

local function combo2str(comboTbl)
   local res = "["
   for k, v in pairs(comboTbl) do
      res = res .. v
      if (k) < #comboTbl then
         res = res .. "+"
      end
   end
   return res .. "]"
end

function KeyConfig.prepareDrawing()
   shortcutsList = List.new(5, 5)
   for k, v in pairs(shortcutsDown) do
      shortcutsList:add(v.description .. " " .. combo2str(v.combo), k)
   end
   for k, v in pairs(shortcutsPressed) do
      shortcutsList:add(v.description .. " " .. combo2str(v.combo), k)
   end
   table.sort(shortcutsList.items, function(a, b)
      return a.id < b.id
   end)
   shortcutsList:done()
end

function KeyConfig.drawList()
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






















































































function KeyConfig.bindKeyDown(stringID, keyCombination, action, description)
   assert(action, "action == nil in bindKey()")
   assert(stringID, "stringID should'not be empty")
   assert(action, "action == nil in bindKeyDown()")











   description = description and description or ""
   shortcutsDown[stringID] = { combo = keyCombination, action = action,
description = description, enabled = true, }
end

function KeyConfig.bindKeyPressed(stringID, keyCombination, action, description)
   assert(action, "action == nil in bindKeyPressed()")
   assert(description, "description == nil in bindKeyPressed()")
   shortcutsPressed[stringID] = { combo = keyCombination, action = action,
description = description, enabled = true, }
end



function KeyConfig.checkPressedKeys(key)
   for _, v in pairs(shortcutsPressed) do
      if v.enabled then


         local pressed = key == v.combo[1]


         for i = 2, #v.combo do

            pressed = pressed and lk.isDown(v.combo[i])
            if not pressed then break end
         end
         if pressed and v.action then

            shortcutsList = nil
            v.action()
         end
      end
   end
end



function KeyConfig.checkDownKeys()

   for _, v in pairs(shortcutsDown) do
      if v.enabled then
         local pressed = true
         for _, keyValue in ipairs(v.combo) do
            pressed = pressed and lk.isScancodeDown(keyValue)
            if not pressed then break end
         end
         if pressed and v.action then
            shortcutsList = nil


            v.action()
         end
      end
   end
end

function KeyConfig.send(stringID)
   local t = shortcutsDown[stringID]
   if t and t.enabled and t.action then
      t.action()
   else
      t = shortcutsPressed[stringID]
      if t and t.enabled and t.action then
         t.action()
      end
   end
end

return KeyConfig
