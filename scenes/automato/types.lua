local _tl_compat53 = ((tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3) and require('compat53.module'); local pcall = _tl_compat53 and _tl_compat53.pcall or pcall; require("love")
local ok, errmsg = pcall(function()
   require("mtschemes")
end)
if not ok and errmsg then
   local tmp = love.filesystem.load("scenes/automato/mtschemes.lua")
   tmp()
end

 Pos = {}




 Cell = {}










 CellSetup = {}




 Cells = {}
 Grid = {}
 GetGridFunction = {}
 InitCellFunction = {}

 CellActionsInit = {}







 Statistic = {}







 DrawNode = {}





 CommonSetup = {}







 ThreadCommandsStore = {}








 ThreadCommands = {}








 SimulatorMode = {}
