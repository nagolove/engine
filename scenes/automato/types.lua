local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pcall = _tl_compat and _tl_compat.pcall or pcall; require("love")
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
