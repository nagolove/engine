local cpml = require 'cpml'

local vec3 = cpml.vec3
local mat4 = cpml.mat4

local cam = {}
cam.__index = cam

function cam.new(fow, w, h)
    self = setmetatable({}, cam)
    self.fow    = fow or 60 -- угол обзора?
    self.width  = w or love.graphics.getWidth()
    self.height = h or love.graphics.getHeight()

    self.perspective = mat4.from_perspective(self.fow, self.width/self.height, 0.1, 10000)
    self.position    = vec3(0, 0, 0) -- положение в пространстве
    self.angle       = vec3(0, 0, 0) -- наверное вектор взгляда из точки position
    self.scrbuf      = love.graphics.newCanvas(self.width, self.height)
    self.depth       = love.graphics.newCanvas(self.width, self.height, {readable=true, format="depth16"})
    --self.scrbuf:setFilter("nearest")
    self.depth:setFilter("nearest")
    self.matrix      = mat4()
    self.perspective:transpose(self.perspective)
    self.conf = {
        {self.scrbuf},
        depth        = true, 
        depthstencil = self.depth
    }
    return self
end

function cam:resize(w, h)
    self.width  = w or love.graphics.getWidth()
    self.height = h or love.graphics.getHeight()
    
    self.perspective = mat4.from_perspective(60, self.width/self.height, 0.1, 10000)
    self.position    = vec3(0, 0, 0)
    self.angle       = vec3(0, 0, 0)
    self.scrbuf      = love.graphics.newCanvas(self.width, self.height)
    self.depth       = love.graphics.newCanvas(self.width, self.height, {readable=true, format="depth24"})
    self.matrix      = mat4()
    self.perspective:transpose(self.perspective)
    self.conf = {
        {self.scrbuf},
        depth        = true, 
        depthstencil = self.depth
    }
end

function cam:sendModelMat4(mat4)
    self.shader:send("ModelMatrix", mat4)
end

cam.shader = love.graphics.newShader[[
    uniform mat4 ViewMatrix;
    uniform mat4 ModelMatrix;
    
    #ifdef VERTEX
        uniform bool isInstanced;
        // InstanceMat is matrix of current instance
        // Used is instance drawing is available
        attribute vec4 InstanceMat0;
        attribute vec4 InstanceMat1;
        attribute vec4 InstanceMat2;
        attribute vec4 InstanceMat3;
        attribute vec3 NormalVector;
        
        // Projection is love2d 2d stuff, so it unused
        vec4 position(mat4 Projection, vec4 Vertex) {
            mat4 Model = ModelMatrix;
            
            if (isInstanced) {
                Model[0] = InstanceMat0; // sending matrix
                Model[1] = InstanceMat1; // as pack
                Model[2] = InstanceMat2; // of vectors
                Model[3] = InstanceMat3; // hack
                Model *= ModelMatrix;
            }
            
            return ViewMatrix * Model * Vertex;
        }
    #endif

    #ifdef PIXEL
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec4 texturecolor = Texel(texture, texture_coords);
            return color * texturecolor;
        }
    #endif
]]

function cam:getView()
    local m = self.matrix:reset()
    m:rotate(m, self.angle.x, vec3.unit_x)
    m:rotate(m, self.angle.y, vec3.unit_y)
    m:rotate(m, self.angle.z, vec3.unit_z)
    m:translate(m, self.position)

    return self.perspective * m:transpose(m)
end

function cam:getWorldToScreen(x, y, z)
    local view = self:getView()
    local quat = cpml.quat(x, y, z, 1)
    --print("mat * quat", render(view), render(quat))
    local worldPos = view.mul_vec4({}, view, quat)
    local x, y, z, w = worldPos[1], worldPos[2], worldPos[3], worldPos[4]
    
    local ndcPos = vec3( x/w, -y/w, z/w )
    
    local sx = (ndcPos.x + 1.0) / 2.0 * self.width
    local sy = (ndcPos.y + 1.0) / 2.0 * self.height
    
    return sx, sy
end

function cam:start()
    love.graphics.push("all")
    love.graphics.setDepthMode("less", true)
    love.graphics.setCanvas(self.conf)
    
    love.graphics.setShader(self.shader)
    love.graphics.clear(.5, .5, .5)
    self.shader:send('ViewMatrix', self:getView())
end

function cam:stop()
    love.graphics.pop()
end

function cam:setPosition(x, y, z)
    local pos = self.position
    pos.x = x or 0
    pos.y = y or 0
    pos.z = z or 0
end

function cam:move(x, y, z)
    local pos = self.position
    pos.x = pos.x + (x or 0)
    pos.y = pos.y + (y or 0)
    pos.z = pos.z + (z or 0)
end

return setmetatable({
    new = cam.new,
}, {__call = function(_, ...) return cam.new(...) end})
