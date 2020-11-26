local modelBatch = {}
modelBatch.__index = modelBatch

modelBatch.batchfmt = {
    {"InstanceMat0", "float", 4},
    {"InstanceMat1", "float", 4},
    {"InstanceMat2", "float", 4},
    {"InstanceMat3", "float", 4},
}

function modelBatch:new(model, instancecount)
    self = setmetatable({}, self)
    self.model     = model
    self.batch     = love.graphics.newMesh(self.batchfmt, instancecount or 10000, "points", "dynamic")
    self.count     = 0
    return self
end

function modelBatch:clear()
    self.count = 0
end

function modelBatch:add(x, y, z, ax, ay, az, sx, sy, sz)
    self.count = self.count + 1
    local m = mat_totransform(x, y, z, ax, ay, az, sx, sy, sz)
    self.batch:setVertex(self.count, m)
    return self.count
end

function modelBatch:set(idx, x, y, z, ax, ay, az, sx, sy, sz)
    local m = mat_totransform(x, y, z, ax, ay, az, sx, sy, sz)
    self.batch:setVertex(idx, m)
end

function modelBatch:draw(cam, x, y, z, ax, ay, az, sx, sy, sz)
    local m = mat_totransform(x, y, z, ax, ay, az, sx, sy, sz)
    cam:sendModelMat4(m:transpose(m))
    
    cam.shader:send("isInstanced", true)

    self.model.mesh:attachAttribute("InstanceMat0", self.batch, "perinstance")
    self.model.mesh:attachAttribute("InstanceMat1", self.batch, "perinstance")
    self.model.mesh:attachAttribute("InstanceMat2", self.batch, "perinstance")
    self.model.mesh:attachAttribute("InstanceMat3", self.batch, "perinstance")
    
    love.graphics.drawInstanced(self.model.mesh, self.count)
    
    self.model.mesh:detachAttribute("InstanceMat0", self.batch, "perinstance")
    self.model.mesh:detachAttribute("InstanceMat1", self.batch, "perinstance")
    self.model.mesh:detachAttribute("InstanceMat2", self.batch, "perinstance")
    self.model.mesh:detachAttribute("InstanceMat3", self.batch, "perinstance")
    
    cam.shader:send("isInstanced", false)
    cam:sendModelMat4(IDEMAT)
end

