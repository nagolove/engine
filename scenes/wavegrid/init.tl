require "log"
local inspect = require "inspect"
local getTime = love.timer.getTime
local gr = love.graphics

-- FIXME HACK
package.path = package.path .. ";scenes/wavegrid/?.lua"

--local mesh1 = require "meshexample":new()

local record WaveGrid 
    new: function(dimx: integer, dimy: integer, dimsize: integer): WaveGrid

    updateVertices: function(WaveGrid)

    record Node
        {number}
        x: number
        y: number
    end

    grid: {{Node}}
    dimsize: integer
    mesh: gr.Mesh
    timestamp: number
    counter: integer

    record Vertex
        x: number
        y: number
        u: number
        v: number
        r: number
        g: number
        b: number
        a: number
        --metamethod __call: function(Vertex, {number}): Vertex
        metamethod __call: function({number}): WaveGrid.Vertex
        --function WaveGrid.Vertex.__call(verts_arr: {number}): WaveGrid.Vertex
        new: function({number}): Vertex
    end
    vertices: {Vertex}

    getVerticesToNumbers: function(Vertex, verts: {Vertex}): {number}

end

local Vertex_mt:metatable<WaveGrid.Vertex> = {
    --__call = function(verts_arr: {number}): WaveGrid.Vertex,
    __index = WaveGrid.Vertex,
}

function WaveGrid.Vertex.new(verts_arr: {number}): WaveGrid.Vertex
    local self = setmetatable({} as WaveGrid.Vertex, Vertex_mt)
    self.x = verts_arr[1]
    self.y = verts_arr[2]
    self.u = verts_arr[3]
    self.v = verts_arr[4]
    self.r = verts_arr[5]
    self.g = verts_arr[6]
    self.b = verts_arr[7]
    self.a = verts_arr[8]
    return self
end

--local Vertex_mt: WaveGrid.Vertex = {
    ----__call = function(verts_arr: {number}): WaveGrid.Vertex,
    --new =  function(verts_arr: {number}): WaveGrid.Vertex
        --local self = setmetatable({} as WaveGrid.Vertex, Vertex_mt)
        --self.x = verts_arr[1]
        --self.y = verts_arr[2]
        --self.u = verts_arr[3]
        --self.v = verts_arr[4]
        --self.r = verts_arr[5]
        --self.g = verts_arr[6]
        --self.b = verts_arr[7]
        --self.a = verts_arr[8]
        --return self
    --end
--}

--function Vertex_mt.__call(verts_arr: {number}): WaveGrid.Vertex
    --local self = setmetatable({} as WaveGrid.Vertex, Vertex_mt)
    --self.x = verts_arr[1]
    --self.y = verts_arr[2]
    --self.u = verts_arr[3]
    --self.v = verts_arr[4]
    --self.r = verts_arr[5]
    --self.g = verts_arr[6]
    --self.b = verts_arr[7]
    --self.a = verts_arr[8]
    --return self
--end

local WaveGrid_mt: metatable<WaveGrid> = {
    __index = WaveGrid,
}

function WaveGrid.new(dimx: integer, dimy: integer, dimsize: integer): WaveGrid
    local self = setmetatable({} as WaveGrid, WaveGrid_mt)
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
    for _ = 1, dimx * dimy * 6 do
        table.insert(self.vertices, WaveGrid.Vertex.new({0, 0, 0, 0, 1, 1, 1, 1}))
    end
    self:updateVertices()
    self.timestamp = getTime()
    self.counter = 0
    --print("self.grid", inspect(self.grid))
    return self
end

function WaveGrid:getVerticesToNumbers(verts: {WaveGrid.Vertex}): {{number}}
    local result: {{number}} = {}
    for _, v in ipairs(verts) do
        table.insert(result, { v.x, v.y, v.u, v.v, v.r, v.g, v.b, v.a, })
    end
    return result
end

function printVertices(_: {WaveGrid.Vertex})
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
    -- переношу из сетки в вершины координаты
    for i = 1, #self.grid do
        local c = #self.grid[1]
        for j = 1, c do
            local cell = self.grid[i][j]

            --self.vertices[(i * c + j) * 8].x = cell[1]
            --self.vertices[(i * c + j) * 8].y = cell[1]
            print("cell", inspect(cell))
            print("len", #self.grid[i])

            self.vertices[(i * c + j) * 8 + 1].x = cell[1]
            self.vertices[(i * c + j) * 8 + 2].y = cell[2]
--self.vertices[(i * c + j) * 8 + 1].x = cell[1]
--self.vertices[(i * c + j) * 8 + 2].y = cell[2]

            --self.vertices[(i * c + j) * 8 + 1] = cell[1]
            --self.vertices[(i * c + j) * 8 + 2] = cell[2]
            --self.vertices[(i * c + j) * 8 + 1] = cell[1]
            --self.vertices[(i * c + j) * 8 + 2] = cell[2]

            --print(cell[1][1], cell[2])
        end
    end
    --self.mesh:setVertices(self.vertices, 1)
    self.mesh:setVertices(self:getVerticesToNumbers(self.vertices), 1)
    printVertices(self.vertices)
end

function WaveGrid:update(_: number)
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
            local cell = self.grid[i][j]
            gr.setColor{0.5, 0.5, 0.75}
            gr.polygon("line", cell[1], cell[2], cell[3], cell[4], cell[5], 
                cell[6], cell[7], cell[8])
        end
    end
    gr.draw(self.mesh as gr.Drawable, 100, 100)

    --mesh1:draw()
end

local waveGrid: WaveGrid

function init()
    waveGrid = WaveGrid.new(4, 4, 16)
end

local function draw()
    waveGrid:draw()
    --mesh1:draw()
end

function update(dt: number)
    local lk = love.keyboard
    local assoc = {
        ["left"] = {-1, 0},
        ["right"] = {1, 0},
        ["up"] = {0, -1},
        ["down"] = {0, 1},
    }

    --for k, v in pairs(assoc) do
        --if lk.isDown(k) then
            --mesh1:move(v[1], v[2])
        --end
    --end

    waveGrid:update(dt)
end

function keypressed (k: string)
    if k == "escape" then
        love.event.quit()
    end
end

return {
    init = init,
    draw = draw,
    update = update,
    keypressed = keypressed,
}
