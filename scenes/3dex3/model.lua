require "mat"
local inspect = require "inspect"

local model = {}
model.__index = model

model.meshfmt = {
    {"VertexPosition", "float", 3},
    {"VertexTexCoord", "float", 2},
    {"VertexNormal",   "float", 3},
    {"VertexColor",    "byte",  4},
}

function model.new(verts, texture, map)
    self = setmetatable({}, model)
    --print("fmt", inspect(self.meshfmt))
    --print("verts", inspect(verts))
    self.mesh     = love.graphics.newMesh(self.meshfmt, verts, "triangles", "dynamic")
    self.texture  = texture
    self.mesh:setTexture(self.texture)
    if map then self.mesh:setVertexMap(map) end
    return self
end

function model:draw(cam, x, y, z, ax, ay, az, sx, sy, sz)
    local m = mat_totransform(x, y, z, ax, ay, az, sx, sy, sz)

    print(inspect(self))
    if self.mat then
        print("send matrix", self.mat)
        --cam:sendModelMat4(self.mat:transpose(self.mat))
        --cam:sendModelMat4(self.mat:transpose(m))
        --m = m * self.mat
        --m = self.mat * m
        m = self.mat:transpose(self.mat) * m
    end
    cam:sendModelMat4(m:transpose(m))
    --cam:sendModelMat4(m)
    love.graphics.draw(self.mesh)
    cam:sendModelMat4(IDEMAT) -- reset
end

return model
