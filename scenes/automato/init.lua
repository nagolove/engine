local _tl_compat53 = ((tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3) and require('compat53.module'); local ipairs = _tl_compat53 and _tl_compat53.ipairs or ipairs; local math = _tl_compat53 and _tl_compat53.math or math; local package = _tl_compat53 and _tl_compat53.package or package; local string = _tl_compat53 and _tl_compat53.string or string






require("external")
require("types")
require("love")

local imgui = require("imgui")
local cam = require("camera").new()
local inspect = require("inspect")
local gr = love.graphics

 ViewState = {}





local viewState = "sim"


local MouseCapture = {}






local mouseCapture


local graphCanvas = gr.newCanvas(gr.getWidth() * 4, gr.getHeight())


local MAX_ENERGY_COLOR = { 1, 0.5, 0.7, 1 }
local MID_ENERGY_COLOR = { 0.8, 0.3, 0.7, 1 }
local MIN_ENERGY_COLOR = { 0.6, 0.1, 1, 1 }





local mode = "continuos"

package.path = package.path .. ";scenes/automato/?.lua"
local sim = require("simulator")


local pixSize = 10




local commonSetup = {

   gridSize = 100,

   cellsNum = 2000,

   initialEnergy = { 5000, 10000 },

   codeLen = 32,

   threadCount = 1,
}

local function getMode()
   return mode
end

function drawCells()
   local drawlist = sim.getDrawLists()
   if drawlist then
      for _, v in ipairs(drawlist) do
         if v.food then
            gr.setColor(0, 1, 0)
            gr.rectangle("fill", (v.x - 1) * pixSize, (v.y - 1) * pixSize, pixSize, pixSize)
         else
            gr.setColor(0.5, 0.5, 0.5)
            gr.rectangle("fill", (v.x - 1) * pixSize, (v.y - 1) * pixSize, pixSize, pixSize)
         end
      end
   end
end

function drawGrid()
   if sim.getMode() == "stop" then
      gr.setColor(1, 1, 1)
      gr.print("No simulation", 100, 100)
   else
      gr.setColor(0.5, 0.5, 0.5)
      local gridSize = sim.getGridSize()
      local schema = sim.getSchema()
      if schema then
         for _, v in ipairs(sim.getSchema()) do
            local dx, dy = v.draw[1] * pixSize * gridSize, v.draw[2] * pixSize * gridSize
            for i = 0, sim.getGridSize() do

               gr.line(dx + i * pixSize, dy + 0, dx + i * pixSize, dy + gridSize * pixSize)

               gr.line(dx + 0, dy + i * pixSize, dx + gridSize * pixSize, dy + i * pixSize)
            end
         end
      else
         local dx, dy = 0, 0
         for i = 0, sim.getGridSize() do

            gr.line(dx + i * pixSize, dy + 0, dx + i * pixSize, dy + gridSize * pixSize)

            gr.line(dx + 0, dy + i * pixSize, dx + gridSize * pixSize, dy + i * pixSize)
         end
      end
   end
end

function drawStatisticTable()
   local y0 = 0
   gr.setColor(1, 0, 0)

   y0 = y0 + gr.getFont():getHeight()
   local statistic = sim.getStatistic()
   if statistic then
      if statistic.maxEnergy then
         gr.setColor(1, 0, 0)
         gr.print(string.format("max energy in cell %d", statistic.maxEnergy), 0, y0)
         y0 = y0 + gr.getFont():getHeight()
      end
      if statistic.minEnergy then
         gr.setColor(1, 0, 0)
         gr.print(string.format("min energy in cell %d", statistic.minEnergy), 0, y0)
         y0 = y0 + gr.getFont():getHeight()
      end
      if statistic.midEnergy then
         gr.setColor(1, 0, 0)
         gr.print(string.format("mid energy in cell %d", statistic.midEnergy), 0, y0)
         y0 = y0 + gr.getFont():getHeight()
      end
   end
end

function drawAxises()
   gr.setColor(0, 1, 0)
   local w, h = gr.getDimensions()
   gr.setLineWidth(3)
   gr.line(0, h, 0, 0)
   gr.line(0, h, w, h)
   gr.setLineWidth(1)
end

local function drawLegends()
   local y0 = 0

   gr.setColor(MAX_ENERGY_COLOR)
   gr.print("max energy", 0, y0)
   y0 = y0 + gr.getFont():getHeight()

   gr.setColor(MID_ENERGY_COLOR)
   gr.print("mid energy", 0, y0)
   y0 = y0 + gr.getFont():getHeight()

   gr.setColor(MIN_ENERGY_COLOR)
   gr.print("min energy", 0, y0)
   y0 = y0 + gr.getFont():getHeight()
end

local function drawGraphs()
   drawAxises()
   drawLegends()
   gr.draw(graphCanvas)
end

local function nextMode()
   if mode == "continuos" then
      mode = "step"
   elseif mode == "step" then
      mode = "continuos"
   end
   sim.setMode(mode)
end

local function replaceCaret(str)
   return string.gsub(str, "\n", "")
end

local function drawui()
   imgui.Begin("sim", false, "ImGuiWindowFlags_AlwaysAutoResize")

   imgui.Text(string.format("mode %s", getMode()))

   if imgui.Button("change mode", getMode()) then
      nextMode()
   end

   if imgui.Button("reset silumation") then
      collectgarbage()
      sim.create(commonSetup)
   end

   if imgui.Button("start") then
      sim.create(commonSetup)

   end

   if imgui.Button("step") then
      sim.step()
   end

   imgui.Text(replaceCaret(inspect(sim.getStatistic)))

   imgui.End()
end

local function draw()
   if viewState == "sim" then
      cam:attach()
      drawGrid()
      drawCells()

      cam:detach()
   elseif viewState == "graph" then

   end
end

local function checkMouse()
   if love.mouse.isDown(1) then
      if not mouseCapture then
         mouseCapture = {
            x = love.mouse.getX(),
            y = love.mouse.getY(),
            dx = 0,
            dy = 0,
         }
      else
         mouseCapture.dx = mouseCapture.x - love.mouse.getX()
         mouseCapture.dy = mouseCapture.y - love.mouse.getY()
      end
   else
      mouseCapture = nil
   end
end


















































local function update()
   controlCamera(cam)

   sim.step()


   checkMouse()
end

function setViewState(stateName)
   viewState = stateName
end

local function keypressed(key)
   if key == "1" then
      setViewState("sim")
   elseif key == "2" then
      setViewState("graph")
   end
   if key == "p" then
      nextMode()
   elseif key == "s" then
      sim.doStep()
   end
end

local function init()
   math.randomseed(love.timer.getTime())
end

local function quit()
end

return {
   getPixSize = function()
      return pixSize
   end,

   getMode = getMode,
   nextMode = nextMode,

   cam = cam,




   init = init,
   quit = quit,
   draw = draw,
   drawui = drawui,
   update = update,
   keypressed = keypressed,
}
