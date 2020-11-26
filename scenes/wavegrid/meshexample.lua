
local MeshExample1 = {}
MeshExample1.__index = MeshExample1

local gr = love.graphics

function MeshExample1:new()
    local x, y = 0, 0
    local size = 128
    local tex = gr.newImage("tex1.png")
    local self = setmetatable({}, MeshExample1)
    self.vertices = {}

    table.insert(self.vertices, {
        x, y,
        0.3, 0.3,
        1, 1, 0, 1
    })
    table.insert(self.vertices, {
        x + size, y + size,
        0.3, 0.3,
        1, 0, 1, 1
    })
    table.insert(self.vertices, {
        x, y + size,
        0.3, 0.3,
        0, 1, 1, 1
    })

    table.insert(self.vertices, {
        x, y,
        0.2, 0.2,
        1, 1, 1, 1
    })
    table.insert(self.vertices, {
        x + size, y,
        1, 1,
        1, 1, 1, 1
    })
    table.insert(self.vertices, {
        x + size, y + size,
        1, 1,
        1, 1, 1, 1
    })

    self.mesh = gr.newMesh(6, "triangles", "dynamic")
    self.mesh:setTexture(self.image)
    return self
end

function MeshExample1:draw()
    --gr.setColor{1, 1, 1, 1}
    gr.draw(self.mesh)
end

function MeshExample1:move(dx, dy)
    for k, v in pairs(self.vertices) do
        v[1] = v[1] + dx
        v[2] = v[2] + dy
    end
    self.mesh:setVertices(self.vertices)
end

function MeshExample1:setPos(x, y)
end

return MeshExample1
