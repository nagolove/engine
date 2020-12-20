local threadNum = ...
print("thread", threadNum, "is running")

require "love.timer"
require "external"

local randseed = love.timer.getTime()
math.randomseed(randseed)


local inspect = require "inspect"
local serpent = require "serpent"

--package.path = package.path .. ";scenes/automato/?.lua"
--local grid = require "grid".new()

-- массив всех клеток
local cells = {}

-- массив массивов [x][y] с клетками по индексам
-- TODO Переработать интерфейс взаимодействия с сеткой на использования класса
-- Grid на основе C-массива 2Д
local grid = {}
-- размер сетки
local gridSize
-- длина кода генерируемого новой клетке
local codeLen
-- сколько клеток создавать корутиной в начальном впрыске
local cellsNum
-- разброс границы энергии клетки при создании, массив двух элементов
local initialEnergy = {}
-- текущая итерация
local iter = 0
-- таблица общей статистики
local statistic = {}
-- список еды
local meal = {}
-- флаг остановки потока
local stop = false
-- схема многопоточности
local schema
-- кортеж координат для сдвига площадки рисования одного потока
local drawCoefficients
-- шагнуть при шаговом режиме
local doStep = false
-- шаговый или продолжительный режим
local checkStep = false
-- команды таблички управления нитью
local commands = {}

local chan = love.thread.getChannel("msg" .. threadNum)
local data = love.thread.getChannel("data" .. threadNum)
local log = love.thread.getChannel("log")
local request = love.thread.getChannel("request" .. threadNum)

package.path = package.path .. ";scenes/automato/?.lua"
local actionsModule = require "cell-actions"

local function getCodeValues()
  local codeValues = {}
  for k, v in pairs(actionsModule.actions) do
    
    print("k", k)
    if k == "left" then k = "left2"
    elseif k == "right" then k = "right2"
    elseif k == "up" then k = "up2"
    elseif k == "down" then k = "down2"
    end

    table.insert(codeValues, k)
  end
  return codeValues
end

local codeValues = getCodeValues()

local actions
local removed = {}
local experimentCoro

-- генератор кода
function genCode()
  local code = {}
  local len = #codeValues
  for i = 1, codeLen do
    table.insert(code, codeValues[math.random(1, len)])
  end
  return code
end

-- t.pos, t.code
-- конструктор клетки
function initCell(t)
  t = t or {}
  local self = {}
  self.pos = {}
  if t.pos and t.pos.x then
    self.pos.x = t.pos.x
  else
    self.pos.x = math.random(1, gridSize)
  end
  if t.pos and t.pos.y then
    self.pos.y = t.pos.y
  else
    self.pos.y = math.random(1, gridSize)
  end
  if t.code then
    self.code = copy(t.code)
  else
    self.code = genCode()
  end
  self.ip = 1
  self.energy = math.random(initialEnergy[1], initialEnergy[2])
  self.mem = {}
  self.diedCoro = coroutine.create(function()
      for i = 1, 2 do
        return coroutine.yield()
      end
      self.died = true
    end)
  self.died = false
  table.insert(cells, self)
  return self
end

-- возвращает [boolean], [cell table]
-- isalive, cell
function updateCell(cell)
  -- прокрутка кода клетки по кругу
  if cell.ip >= #cell.code then
    cell.ip = 1
  end
  if cell.energy > 0 then
    actions[cell.code[cell.ip]](cell)
    cell.ip = cell.ip + 1
    cell.energy = cell.energy - 1
    return true, cell
  else
    return false, cell
  end
end

-- заполнить решетку пустыми значениями. В качестве значений используются
-- пустые таблицы {}
function getFalseGrid()
  local res = {}
  for i = 1, gridSize do
    local t = {}
    for j = 1, gridSize do
      t[#t + 1] = {}
    end
    res[#res + 1] = t
  end
  return res
end

function updateGrid()
  for _, v in pairs(cells) do
    grid[v.pos.x][v.pos.y] = v
  end
  for _, v in pairs(meal) do
    grid[v.pos.x][v.pos.y] = v
  end
end

-- не работает нормально. Нужно отсылал с некоторой периодичностью в виде 
-- сообщений в основную нить
function gatherStatistic(cells)
  local maxEnergy = 0
  local minEnergy = initialEnergy[2]
  local sumEnergy = 0
  for _, v in pairs(cells) do
    if v.energy > maxEnergy then
      maxEnergy = v.energy
    end
    if v.energy < minEnergy then
      minEnergy = v.energy
    end
    sumEnergy = sumEnergy + v.energy
  end
  local num = #cells > 0 and #cells or 1
  if sumEnergy == 0 then
    sumEnergy = 1
  end
  return { 
    maxEnergy = maxEnergy,
    minEnergy = minEnergy,
    midEnergy = sumEnergy / #cells,
    allEated = actionsModule.getAllEated(),
  }
end


function emitFoodInRandomPoint()
  local x = math.random(1, gridSize)
  local y = math.random(1, gridSize)
  local t = grid[x][y]
  -- если клетка пустая
  if not t.energy then
    local self = {
      food = true,
      pos = {x = x, y = y}
    }
    table.insert(meal, self)
    grid[x][y] = self
    return true, grid[x][y]
  else
    return false, grid[x][y]
  end
end


function emitFood(iter)
  --print(math.log(iter) / 1)
  for i = 1, math.log(iter) * 10 do
    local emited, gridcell = emitFoodInRandomPoint()
    if not emited then
      -- здесь исследовать причины смерти яцейки
      --print("not emited gridcell", inspect(gridcell))
    end
  end
end

function saveDeadCellsLog(cells)
  local filename = string.format("cells%d.gzip", threadNum)
  local file = io.open(filename, "w")
  for _, cell in pairs(cells) do
    local celldump = serpent.dump(cell)
    local compressedcellstr = love.data.compress("string", celldump, "gzip")
    if not compressedcellstr then
      error("Not compressed cell")
    end
    local struct = require "struct"
    local len = compressedcellstr:len()
    -- записываю 4 байта длины сжатой строки
    file:write(struct.pack("<d", compressedcellstr))
    file:write(compressedcell)
  end
  file:close()
end

function updateCells()
  local alive = {}
  for k, cell in pairs(cells) do
    local isalive, c = updateCell(cell)
    if isalive then
      table.insert(alive, c)
    else
      local ok = true
      local diedCell
      while ok do
        ok, diedCell = coroutine.resume(c.diedCoro)
      end

      if diedCell.pos then
        print("copyed")
        grid[diedCell.pos.x][diedCell.pos.y].died = true
      end

      table.insert(removed, c)
    end
  end
  return alive
end

local function initCellOneCommandCode(command, steps)
  local cell = initCell()
  cell.code = {}
  for i = 1, steps do
    table.insert(cell.code, command)
  end
end

local function cloneCell(cell, newx, newy)
  if not isAlive(newx, newy) then
    local new = {}
    for k, v in pairs(cell) do
      if type(v) ~= "table" then
        new[k] = v
      else
        new[k] = {}
        for k1, v1 in pairs(v) do
          new[k][k1] = v1
        end
      end
    end
    new.pos.x, new.pos.y = newx, newy
    print("cloned cell")
    table.insert(cells, new)
    return new
  else
    print("nothing in clone")
    return nil
  end
end

function initialEmit()
  if threadNum == 1 then
    for i = 1, cellsNum do
      --coroutine.yield(initCell())
    end
    --elseif threadNum == 2 then
  else
    for i = 1, cellsNum / 100 do
      coroutine.yield(initCell())
    end
  end

  if threadNum == 1 then
    for i = 1, 2 do
      local steps = 5
      --local c = initCell()
      --cloneCell(c, 10, 10)
      initCellOneCommandCode("right", steps)
      initCellOneCommandCode("left", steps)
      initCellOneCommandCode("up", steps)
      initCellOneCommandCode("down", steps)
    end
  end
end

function postinitialEmit(iter)
  local bound = math.log(iter) / 1000
  for i = 1, bound do
    print("i", i)
    coroutine.yield()
    initCell()
  end
end

local function updateMeal(meal)
  local alive = {}
  for k, dish in pairs(meal) do
    if dish.food == true then
      table.insert(alive, dish)
    end
  end
  return alive
end

function experiment()
  local initialEmitCoro = coroutine.create(initialEmit)
  while coroutine.resume(initialEmitCoro) do end

  grid = getFalseGrid()
  updateGrid()
  statistic = gatherStatistic(cells)

  coroutine.yield()

  local postinitialEmitCoro = coroutine.create(postinitialEmit)

  print("hello from coro")

  while #cells > 0 do
    -- дополнительное создание клеток в зависимости от iter
    if coroutine.resume(postinitialEmitCoro) then
    end
    print("step of thread", threadNum)
    -- создать сколько-то еды
    emitFood(iter)

    -- проход по списку клеток и вызов их программ. уничтожение некоторых клеток
    cells = updateCells(cells)

    -- проход по списку еды и проверка на съеденность.
    meal = updateMeal(meal)

    -- сброс решетки
    grid = getFalseGrid()

    -- обновление решетки по списку живых клеток и списку еды
    updateGrid()

    -- обновить статистику за такт
    statistic = gatherStatistic()

    iter = iter + 1

    -- можно возвращать сдесь какое-то состояние клеток из нити
    coroutine.yield(stepStatistic)
  end

--    saveDeadCellsLog(removed)
end

local experimentErrorPrinted = false

local function logfwarn(...)
  love.thread.getChannel("log"):push({threadNum, string.format(...)})
end

local function step()
  local err, errmsg = coroutine.resume(experimentCoro)
  if not err and not experimentErrorPrinted then
    experimentErrorPrinted = true
    logfwarn("coroutine error %s", errmsg)
  end
end

-- для интерфейса в другой модуль
local function getGrid()
  return grid
end

local function pushDrawList()
  local drawlist = {}
  for k, v in pairs(cells) do
    table.insert(drawlist, { 
        x = v.pos.x + gridSize * drawCoefficients[1],
        y = v.pos.y + gridSize * drawCoefficients[2],
      })
  end
  for k, v in pairs(meal) do
    table.insert(drawlist, { 
        x = v.pos.x + gridSize * drawCoefficients[1],
        y = v.pos.y + gridSize * drawCoefficients[2], 
        food = true
      })
  end
  -- нужное-ли условие?
  if data:getCount() < 5 then
    data:push(drawlist)
  end
end

function commands.stop()
  stop = true
end

function commands.getobject()
  local x, y = chan:pop(), chan:pop()
  local ok, errmsg = pcall(function()
      if grid then
        local cell = grid[x][y]
        if cell then
          request:push(serpent.dump(cell))
        end
      end
    end)
  if not ok then
    print("Error in getobject operation", errmsg)
  end
end

function commands.step()
  checkStep = true
  doStep = true
end

function commands.continuos()
  checkStep = false
end

function commands.isalive()
  local x, y = chan:pop(), chan:pop()
  local ok, errmsg = pcall(function()
      if x >= 1 and x <= gridSize and y >= 1 and y <= gridSize then
        local cell = grid[x][y]
        local state = cell.energy and cell.energy > 0
        request:push(state)
      end
    end)
  if not ok then
    error(errmsg)
  end
end

function commands.insertcell()
  local newcellfun, err = loadstring(chan:pop())
  if err then
    error(err)
  end
  local newcell = newcellfun()
  table.insert(cells, newcell)
end

local function popCommand()
  local cmd = chan:pop()
  if cmd then
    local command = commands[cmd]
    if command then
      command()
    else
      error(string.format("Unknown command", cmd))
    end
  end
end

local function doSetup()
  local setupName = "setup" .. threadNum
  local initialSetup = love.thread.getChannel(setupName):pop()

  print("thread", threadNum)
  print("initialSetup", inspect(initialSetup))

  gridSize = initialSetup.gridSize
  codeLen = initialSetup.codeLen
  cellsNum = initialSetup.cellsNum
  initialEnergy[1], initialEnergy[2] = initialSetup.initialEnergy[1], initialSetup.initialEnergy[2]

  local sschema = love.thread.getChannel(setupName):pop()

  local schemafun, err = loadstring(sschema)
  if err then
    error("Could'not get schema for thread")
  end
  local schemaRestored = schemafun()
  print("schemaRestored", inspect(schemaRestored))
  schema = flatCopy(schemaRestored)

  drawCoefficients = flatCopy(schemaRestored.draw)

  print("schema", inspect(schema))
  print("drawCoefficients", inspect(drawCoefficients))

  experimentCoro = coroutine.create(function()
      local ok, errmsg = pcall(experiment)
      if not ok then
        logferror("Error %s", errmsg)
      end
    end)
  -- первый запуск корутины, прогревочный 
  coroutine.resume(experimentCoro)

  actionsModule.init({
      getGridFunc = getGrid,
      gridSize = gridSize,
      schema = schema,
      threadNum = threadNum,
      initCell_fn = initCell,
    })

  -- установка ссылки на таблицу действий - язык клетки.
  actions = actionsModule.actions
end

local function main()
  local syncChan = love.thread.getChannel("sync")
  while not stop do
    popCommand()

    if checkStep then
      if doStep then
        step()
      end
      love.timer.sleep(0.02)
    else
      step()
    end
    pushDrawList()

    local syncMsg = syncChan:demand(0.001)
    --local syncMsg = syncChan:demand()
    --local syncMsg = syncChan:pop()
    --print(threadNum, syncMsg)

    doStep = false

    local iterChan = love.thread.getChannel("iter")
    iterChan:push(iter)
  end
end

doSetup()
main()
