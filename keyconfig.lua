local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table
require("love")
local lk = love.keyboard
local lg = love.graphics

local Shortcut = {}







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

local function prepareDrawing()
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

local function drawList()
   if not shortcutsList then
      prepareDrawing()
   end
   shortcutsList:draw()
end

local function updateList(dt)
   if shortcutsList then
      shortcutsList:update(dt)
   end
end


local function drawShortcutsList(x0, y0)
   x0 = x0 and x0 or 0
   y0 = y0 and y0 or 0
   local x, y = x0, y0

   local maxStringWidth = 0
   local delimiter = "+"


   function makeTextList(list)
      local textList = {}
      for _, v in pairs(list) do
         local keyCombination = ""
         for k, keyValue in ipairs(v.combo) do
            if k < #v.combo then
               keyCombination = keyValue .. delimiter .. keyCombination
            else
               keyCombination = keyCombination .. keyValue
            end
         end
         local common = {}
         common[#common + 1] = { 1, 0, 0 }
         common[#common + 1] = "\"" .. keyCombination .. "\""
         common[#common + 1] = { 0, 1, 0 }
         common[#common + 1] = ": " .. v.description
         table.insert(textList, common)
         local textLen = string.len(common[2]) + string.len(common[4])
         maxStringWidth = textLen > maxStringWidth and textLen or maxStringWidth
      end
      return textList
   end


   function calcHeight(list)
      local h = 0
      for _, _ in pairs(list) do
         h = h + lg.getFont():getHeight()
      end
      return h
   end

   local tmpFont = lg.getFont()



   local list1, list2 = makeTextList(shortcutsPressed), makeTextList(shortcutsDown)



   local str = ""
   for i = 1, maxStringWidth do
      str = str .. "z"
   end


   local rectW, rectH = lg.getFont():getWidth(str), (calcHeight(shortcutsDown) + calcHeight(shortcutsPressed))

   lg.rectangle("fill", x0, y0, rectW, rectH)
   local oldWidth = lg.getLineWidth()
   local delta = 1
   lg.setLineWidth(3)
   lg.setColor({ 1, 0, 1 })
   lg.rectangle("line", x0 - delta, y0 - delta, rectW + delta, rectH + delta)
   lg.setLineWidth(oldWidth)
   lg.setColor({ 1, 1, 1 })

   local function drawList(list)
      for _, v in ipairs(list) do
         lg.print(v, x, y)
         y = y + lg.getFont():getHeight()
      end
   end

   drawList(list1)
   drawList(list2)
   lg.setFont(tmpFont)
end





local function bindKeyDown(stringID, keyCombination, action, description)
   assert(action, "action == nil in bindKey()")
   assert(stringID, "stringID should'not be empty")
   assert(action, "action == nil in bindKeyDown()")











   description = description and description or ""
   shortcutsDown[stringID] = { combo = keyCombination, action = action,
description = description, enabled = true, }
end

local function bindKeyPressed(stringID, keyCombination, action, description)
   assert(action, "action == nil in bindKeyPressed()")
   assert(description, "description == nil in bindKeyPressed()")
   shortcutsPressed[stringID] = { combo = keyCombination, action = action,
description = description, enabled = true, }
end



local function checkPressedKeys(key)
   for _, v in pairs(shortcutsPressed) do
      if v.enabled then


         local pressed = key == v.combo[1]


         for i = 2, #v.combo do

            pressed = pressed and lk.isDown(v.combo[i])
            if not pressed then break end
         end
         if pressed and v.action then

            v.action()
         end
      end
   end
end




local function checkDownKeys()

   for _, v in pairs(shortcutsDown) do
      if v.enabled then
         local pressed = true
         for _, keyValue in ipairs(v.combo) do
            pressed = pressed and lk.isScancodeDown(keyValue)
            if not pressed then break end
         end
         if pressed and v.action then

            v.action()
         end
      end
   end
end

local function send(stringID)
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

return {
   bindKeyPressed = bindKeyPressed,
   bindKeyDown = bindKeyDown,
   checkDownKeys = checkDownKeys,
   checkPressedKeys = checkPressedKeys,
   shortcutsPressed = shortcutsPressed,
   drawShortcutsList = drawShortcutsList,
   send = send,

   updateList = updateList,
   drawList = drawList,
}
