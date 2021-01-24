local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local math = _tl_compat and _tl_compat.math or math; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; require("log")
require("love")
require("camera")
require("common")


love.filesystem.setRequirePath("scenes/automato/?.lua")

local imgui = require("imgui")
local sim = require("scenes/automato/simulator")
local gr = love.graphics
local inspect = require("inspect")
local cam
local scene








local automatoScene = require("scenes/automato/init")
local underCursor = {}

local function init(currentScene)
   log("Init cell tool.")
   if currentScene then
      scene = currentScene
      cam = scene.getCamera()
      scene = scene
   end
   local mx, my = love.mouse.getPosition()
   underCursor = { x = mx, y = my }
end

local function mousemoved(x, y, dx, dy)
   local w, h = gr.getDimensions()
   local tlx, tly, brx, bry = 0, 0, w, h

   if cam then
      tlx, tly = cam:worldCoords(tlx, tly)
      brx, bry = cam:worldCoords(brx, bry)
   end

   underCursor = {
      x = math.floor(x / automatoScene.getPixSize()),
      y = math.floor(y / automatoScene.getPixSize()),
   }
end

local function getCell(pos)
   local x, y = pos.x, pos.y
   if x + 1 >= 1 and x + 1 <= sim.getGridSize() and
      y + 1 >= 1 and y + 1 <= sim.getGridSize() then
      local cell = sim.getObject(x + 1, y + 1)
      return cell
   end
   return nil
end

local function replaceCaret(str)
   return string.gsub(str, "\n", "")
end

local function drawCellInfo(cell)
   if not cell then
      return
   end

   local msg
   for k, v in pairs(cell) do
      if k ~= "code" then
         local fmt



         local a
         local tp = type(v)
         if tp == "number" then
            fmt = "%d"
            a = tonumber(a)
         elseif tp == "table" then
            fmt = "%s"
            a = replaceCaret(inspect(a))
         else
            fmt = "%s"
            a = tostring(a)
         end
         msg = string.format(fmt, a)
         imgui.LabelText(k, msg)
      end
   end
end

local function drawCellPath(cell)
   if cell and cell.moves and #cell.moves >= 4 then
      local pixSize = automatoScene.getPixSize()
      local half = pixSize / 2
      local prevx, prevy = cell.moves[1], cell.moves[2]
      local i = 3
      while i <= #cell.moves do
         gr.setColor(1, 0, 0)
         gr.line(prevx * pixSize + half,
         prevy * pixSize + half,
         cell.moves[i] * pixSize + half,
         cell.moves[i + 1] * pixSize + half)
         prevx, prevy = cell.moves[i], cell.moves[i + 1]
         i = i + 2
      end
   end
end

local function draw()
   imgui.Begin("cell", false, "ImGuiWindowFlags_AlwaysAutoResize")

   imgui.Text(string.format("mode %s", automatoScene.getMode()))

   if imgui.Button("change mode", automatoScene.getMode()) then
      automatoScene.nextMode()
   end

   if imgui.Button("reset silumation") then
      sim.create()
   end

   if sim.getStatistic() and sim.getStatistic().allEated then
      imgui.LabelText(sim.getStatistic().allEated, "all eated")
   end

   if underCursor then
      local cell = getCell(underCursor)
      drawCellInfo(cell)
      drawCellPath(cell)
   end

   imgui.End()
   gr.setColor({ 1, 1, 1, 1 })
end

function keypressed(key)
   if key == "p" then
   end
end

function update()
   local isDown = love.keyboard.isDown
   if isDown("z") then
      cam:zoom(1.01)
   elseif isDown("x") then
      cam:zoom(0.99)
   end
end

return {
   init = init,
   draw = draw,
   update = update,
   mousemoved = mousemoved,
   keypressed = keypressed,
}
