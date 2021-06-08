-- Задача: в точке клика на экране появляется прямоугольник, который
-- начинает двигаться в центр экрана. По достижению центра экрана он вращается
-- на полный оборот в произвольную сторону, после чего движется в произвольный
-- угол экрана. Там он исчезает и можно снова кликать в любой точке мышкой(до
-- момента исчезновения мышь становиться заблокированной).

require "vector"

local lt = love.timer
local lg = love.graphics
local inspect = require "inspect"
local linesbuf = require "kons".new()

-- двунаправленный список с блоками
local blks: Block = nil

local record Block
    new: function(x: number, y: number): Block

    -- возвращают истину если не завершены, если завершены, то возвращают ложь.
    processEliminate: function(Block, dt: number): boolean
    setupEliminate: function(Block, dt: number): boolean
    processToCorner: function(Block, dt: number): boolean
    setupCorner: function(Block, dt: number): boolean
    processRotation: function(Block, dt: number): boolean
    setupAngle: function(Block, dt: number): boolean
    processToCenter: function(Block, dt: number): boolean

    next: Block
    prev: Block

    x: number
    y: number
    toCorner: vector

    angle: number
    zeroAngle: number
    angleDelta: number

    timestamp: number
    alphaDelta: number
    color: {number}
    exposition: number
    actions: {Callback}
    action: Callback
end

local type Callback = function(self: Block, dt: number): boolean

local Block_mt: metatable<Block> = {
    __index = Block,
}

--[[
-- Есть четыре состояния, в котором может прибывать блок. Причем состояния
-- переключаются между собой в определенном порядке, из одного состояния
-- выходит следущее. Можно описать матрицей переходов. С другой стороны - 
-- состояния здесь линейны, их можно расположить в ряд - из левого выходит
-- правое. Что если обработчики состояния записать в таблицу?
--]]

function randomRange(min: number, max: number): number
    return min + (max - min) * math.random()
end

-- положение в пикселях
function Block.new(x: number, y: number): Block
    local self = setmetatable({
        x = x, 
        y = y,
        angle = 0, -- угол в радианах
        color = {randomRange(0.6, 1), randomRange(0.6, 1), 
                 randomRange(0.6, 1), 1},
        exposition = randomRange(300, 1000), -- время анимации альфа канала до 0
    } as Block, Block_mt)

    -- тут нужно установить начальный обработчик. Все обработчики возвращают
    -- истину если их нужно запускать еще раз и ложь если они закончили свое
    -- выполнение
    self.actions = {
        self.processEliminate,
        self.setupEliminate,
        self.processToCorner,
        self.setupCorner,
        self.processRotation,
        self.setupAngle,
        self.processToCenter,
    }
    self.action = self.actions[#self.actions]

    if not blks then
        blks = self
        self.prev = nil
        self.next = nil
    else
        --TODO сделать добавление нового элемента не через цикл, а через указатель на последний элемент
        local n = blks
        while n.next do
            n = n.next
        end
        self.next = nil
        self.prev = n
        n.next = self
    end

    linesbuf:push(2, "Block:new(%d, %d)", x, y)
    return self
end

function Block:setupAngle(_: number): boolean
    -- скорость поворота
    local rotationVelocity = randomRange(0.6, 1)
    self.zeroAngle = self.angle
    self.angleDelta = math.random() and rotationVelocity or -rotationVelocity 
    --print("Block:setupAngle")
    --print("self", inspect(self))
    return false
end

function Block:processRotation(dt: number): boolean
    local ret = false
    --print("Block:processRotation()")
    --print("self", inspect(self))
    --print(string.format("self.angle %f, self.zeroAngle %f", self.angle,
        --self.zeroAngle))
    if math.abs(self.angle - self.zeroAngle) < math.pi * 2 then
        self.angle = self.angle + self.angleDelta * dt
        ret = true
        --print("processRotation()")
    end
    return ret
end

-- return true if not completed, else return false
function Block:processToCenter(dt: number): boolean
    -- [[
    -- Здесь нужно задать движение к центру от текущих координат 
    -- прямоугольника.
    -- ]]

    local ret = false
    local w, h = lg.getDimensions()
    local range = 50
    w, h = w + randomRange(-range, range), h + randomRange(-range, range)

    local speed = 50
    -- текущее положение
    local pos = vector.new(self.x, self.y)
    -- конечная точка
    local to = vector.new(w / 2, h / 2)
    -- еденичный вектор движения в нужном направлении
    local dir = (to - pos):normalizeInplace()

    if (to - pos):len() > 1 then
        pos = pos + dir * (dt * speed)
        self.x, self.y = pos:unpack()
        ret = true
    end

    return ret
end

function Block:setupCorner(_: number): boolean
    local w, h = lg.getDimensions()
    local x, y = randomRange(0, w), randomRange(0, h)
    --local corners = {vector(0, 0), vector(w, 0), vector(w, h), vector(0, h)}
    if math.random() > 0.5 then
        x = 0
    else
        y = 0
    end
    self.toCorner = vector.new(x, y)
    return false
end

function Block:processToCorner(dt: number): boolean
    local ret = false
    local speed = 70
    local pos = vector.new(self.x, self.y)
    local to = self.toCorner
    local dir = (to - pos):normalizeInplace()
    if (to - pos):len() > 1 then
        pos = pos + dir * (dt * speed)
        self.x, self.y = pos:unpack()
        ret = true
    end
    return ret
end

function Block:setupEliminate(_: number): boolean
    self.timestamp = love.timer.getTime()
    self.alphaDelta = self.color[4] / self.exposition
    return false
end

function Block:processEliminate(_: number): boolean
    local ret = false
    local time = lt.getTime()
    if time - self.timestamp < self.exposition then
        self.color[4] = self.color[4] - self.alphaDelta
        ret = true
    end
    --print("processEliminate() == false")
    return ret
end

function Block:draw()
    local w, h = lg.getDimensions()
    local rw = 32
    local halfrw = rw / 2

    lg.setColor{1, 1, 1}
    lg.line(0, h / 2, w, h / 2)
    lg.line(w / 2, 0, w / 2, h)

    lg.push("transform")

    lg.translate(self.x, self.y)
    lg.rotate(self.angle)
    lg.translate(-self.x, -self.y)

    lg.setColor(self.color)
    lg.rectangle("fill", self.x - halfrw, self.y - halfrw, rw, rw)

    lg.setColor{0, 0, 1}
    lg.circle("fill", self.x - halfrw, self.y - halfrw, 3)

    lg.pop()

    lg.setColor{0, 0.9, 0}
    lg.circle("fill", self.x, self.y, 3)
end

function Block:processActions(dt: number)
    if self.action and not self:action(dt) then
        -- выкидываю дествие из стека как завершенное
        --print("table action removed")
        print("to remove")
        if #self.actions >= 1 then
            table.remove(self.actions)
            self.action = self.actions[#self.actions]
            print("remove")
            --print("self.actions", inspect(self.actions))
        else
            --print("blk = nil")
            --blk = nil
            -- объекту нужно удалить себя из списка
            print("remove me!")
            if not self.next and self.prev then
                local prev = self.prev
                prev.next = nil
                self = nil
            elseif not self.prev then
                blks = nil
                self = nil
            else
                local prev2 = self.prev
                local next2 = self.next
                prev2.next = self.next
                next2.prev = self.prev
                self = nil
                print("removed self from center")
            end
        end
    end
end

function Block:update(dt: number)
    self:processActions(dt)
end

local function init()
    math.randomseed(os.clock())
end

local function draw()
    if blks then
        local n = blks
        while n.next do
            n:draw()
            n = n.next
        end
    end
    linesbuf:pushi("FPS %d", love.timer.getFPS())
    linesbuf:draw()
end

local function update(dt: number)
    if blks then
        local n = blks
        while n.next do
            n:update(dt)
            n = n.next
        end
    end
    if love.mouse.isDown(1) then
        --Block.new(love.mouse.getPosition())
    end
    linesbuf:update()
end

local function mousemoved(x: number, y: number)
    --print("mousepressed", x, y)
    --Block:new(x, y)
    linesbuf:push(2, "mousepressed(%d, %d)", x, y)
    if love.mouse.isDown(1) then
        Block.new(love.mouse.getPosition())
    end
end

return {
    init = init,
    draw = draw,
    update = update,
    mousemoved = mousemoved,
}
