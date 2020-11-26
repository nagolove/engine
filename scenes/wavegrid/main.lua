local inspect = require "inspect"
local getTime = love.timer.getTime
local gr = love.graphics
local mesh1 = require "meshexample":new()

local WaveGrid = {}
WaveGrid.__index = WaveGrid

function WaveGrid:new(dimx, dimy, dimsize)
    local self = setmetatable({}, WaveGrid)
    self.grid = {}
    self.dimsize = dimsize
    for i = 1, dimx do
        table.insert(self.grid, {})
        local g = self.grid[#self.grid]
        for j = 1, dimy do
            table.insert(g, { 
                i * dimsize,
                j * dimsize,

                i * dimsize + dimsize,
                j * dimsize,

                i * dimsize + dimsize,
                j * dimsize + dimsize,

                i * dimsize,
                j * dimsize + dimsize,

                x = i, 
                y = j})
        end
    end
    self.mesh = gr.newMesh(dimx * dimy * 6, "triangles", "dynamic")
    self.vertices = {}
    for i = 1, dimx * dimy * 6 do
        table.insert(self.vertices, {0, 0, 0, 0, 1, 1, 1, 1})
        --[[
           [table.insert(self.vertices, 0)
           [table.insert(self.vertices, 0)
           [table.insert(self.vertices, 0) -- u
           [table.insert(self.vertices, 0) -- v
           [table.insert(self.vertices, 1) -- r
           [table.insert(self.vertices, 1) -- g
           [table.insert(self.vertices, 1) -- b
           [table.insert(self.vertices, 1) -- a
           ]]
    end
    self:updateVertices()
    self.timestamp = getTime()
    self.counter = 0
    --print("self.grid", inspect(self.grid))
    return self
end

function printVertices(vertices)
    --[[
       [local i = 1
       [while i <= #vertices do
       [    print(string.format("x %f y %f u %f v %f r %f g %f b %f a %f", 
       [        vertices[i], vertices[i + 1],
       [        vertices[i + 2], vertices[i + 3],
       [        vertices[i + 4], vertices[i + 5], 
       [        vertices[i + 6], vertices[i + 7]))
       [    i = i + 8
       [end
       ]]
end

function WaveGrid:updateVertices()
    for i = 1, #self.grid do
        local c = #self.grid[1]
        for j = 1, c do
            local cell = self.grid[i][j]
            --self.vertices[(i * c + j) * 8 + 1] = cell[1]
            --self.vertices[(i * c + j) * 8 + 2] = cell[2]
            --self.vertices[(i * c + j) * 8 + 1] = cell[1]
            --self.vertices[(i * c + j) * 8 + 2] = cell[2]
            print(cell[1], cell[2])
        end
    end
    self.mesh:setVertices(self.vertices, 1)
    printVertices(self.vertices)
end

function WaveGrid:update(dt)
    local now = getTime()
    --print(now - self.timestamp)
    if now - self.timestamp > 0.010 then
        self.timestamp = now

        for i = 1, #self.grid do
            local c = #self.grid[1]
            for j = 1, c do
                local cell = self.grid[i][j]
                --cell[1] = cell[1] + math.cos(now)
                cell[2] = cell[2] + math.sin(now + i / 10)
                --cell[7] = cell[7] + math.cos(now)
                cell[8] = cell[8] + math.sin(now + i / 10)

                --cell[3] = cell[3] + math.cos(now)
                cell[4] = cell[4] + math.sin(now + i / 10)
                --cell[5] = cell[5] + math.cos(now)
                cell[6] = cell[6] + math.sin(now + i / 10)
            end
        end

        self.counter = self.counter + 1
    end
end

function WaveGrid:draw()
    for i = 1, #self.grid do
        local c = #self.grid[1]
        for j = 1, c do
            local gr = love.graphics
            local cell = self.grid[i][j]
            gr.setColor{0.5, 0.5, 0.75}
            gr.polygon("line", cell[1], cell[2], cell[3], cell[4], cell[5], 
                cell[6], cell[7], cell[8])
        end
    end
    gr.draw(self.mesh, 100, 100)

    mesh1:draw()
end

love.load = function()
    waveGrid = WaveGrid:new(4, 4, 16)
end

love.draw = function()
    waveGrid:draw()
    mesh1:draw()
end

love.update = function(dt)
    local lk = love.keyboard
    local assoc = {
        ["left"] = {-1, 0},
        ["right"] = {1, 0},
        ["up"] = {0, -1},
        ["down"] = {0, 1},
    }
    for k, v in pairs(assoc) do
        if lk.isDown(k) then
            mesh1:move(v[1], v[2])
        end
    end

    waveGrid:update(dt)
end

love.keypressed = function(_, k)
    if k == "escape" then
        love.event.quit()
    end
end
