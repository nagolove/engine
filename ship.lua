local vec2 = require "vector-light"
local inspect = require "inspect"
local lp = love.physics
local gr = love.graphics

local shipImg = gr.newImage("gfx/rocket.png")
local shipMesh = gr.newMesh(6, "triangles", "dynamic")

shipMesh:setTexture(shipImg)

local scale = require "scale"
local scalePoints2M = scale.points2M
local scalePoints2PIX = scale.points2PIX
local M2PIX = scale.M2PIX
local PIX2M = scale.PIX2M

local force = 150.1
local dirVec, massCenter
local cam

local function getApplyingForce()
    return force
end

local function setApplyingForce(v)
    force = v
end

local function create(pworld, camera, xc, yc)
    local w, h = gr.getDimensions()
    --local xc, yc = (w / 2) * PIX2M, (h / 4) * PIX2M
    local body = love.physics.newBody(pworld, xc, yc, "dynamic")
    body:setUserData("ship")

    local shiph = 80
    local shipw = shiph / 1.6
    local points = scalePoints2M({ 
        -- левый верхний угол
        -shipw / 2, 0, 
        -- левый нижний угол
        -shipw / 2, shiph, 
        -- правый нижний угол
        shipw / 2, shiph, 
        -- правый верхний
        shipw / 2, 0
    })
    print("ship body points", inspect(points))
    --shipEngineVec = {shipw}
    local shape = lp.newPolygonShape(unpack(points))
    local fixture = lp.newFixture(body, shape)
    print("ship mass", body:getMass())
    print("density", fixture:getDensity())
    shipBody = body

    cam = camera

    return body, shipMesh
end

local function updateMesh(mesh, fixture)
    local body = fixture:getBody()
    local shape = fixture:getShape()
    local points = scalePoints2PIX({body:getWorldPoints(shape:getPoints())})
    local verts = {
        { 
            points[5], points[6],
            0, 1,
            1, 1, 1, 1
        },
        { 
            points[7], points[8],
            0, 0,
            1, 1, 1, 1
        },
        { 
            points[3], points[4],
            1, 1,
            1, 1, 1, 1
        },
        { 
            points[1], points[2],
            1, 0,
            1, 1, 1, 1
        },
        { 
            points[3], points[4],
            1, 1,
            1, 1, 1, 1
        },
        { 
            points[7], points[8],
            0, 0,
            1, 1, 1, 1
        },
    }
    mesh:setVertices(verts)
end

local function updateDirVector(points)
    --local points = {shipBody:getWorldPoints(unpack(shapePoints))}
    local dirx, diry = points[1] - points[3], points[2] - points[4]
    dirx, diry = vec2.normalize(dirx, diry)
    return {dirx, diry}
end

local function getDirectionVec()
    return dirVec
end

local function getThrustRight()
    if dirVec then
        return {vec2.mul(2, vec2.rotate(math.pi / 8, dirVec[1], dirVec[2]))}
    end
end

local function getThrustLeft()
    if dirVec then
        return {vec2.mul(2, vec2.rotate(-math.pi / 8, dirVec[1], dirVec[2]))}
    end
end

local function thrust()
    if not dirVec then
        return
    end

    local px, py, _, _ = shipBody:getMassData()
    local gx, gy = shipBody:getWorldPoint(px, py)
    --print("global px, py", gx, gy)
    --shipBody:applyForce(0, -force/1, gx, gy)
    shipBody:applyForce(dirVec[1], dirVec[2] * force, gx, gy)
end

local function thrustLeft()
    local px, py, _, _ = shipBody:getMassData()
    local gx, gy = shipBody:getWorldPoint(px, py - 0.3)
    local dx, dy = unpack(getThrustLeft())
    --print("dx, dy", dx, dy)
    dx, dy = vec2.mul(14, dx, dy)
    shipBody:applyForce(dx, dy, gx, gy)
end

local function thrustRight()
    local px, py, _, _ = shipBody:getMassData()
    local gx, gy = shipBody:getWorldPoint(px, py - 0.3)
    local dx, dy = unpack(getThrustRight())
    dx, dy = vec2.mul(14, dx, dy)
    shipBody:applyForce(dx, dy, gx, gy)
end

local function updateMassCenterVector()
    local px, py, _, _ = shipBody:getMassData()
    local gx, gy = shipBody:getWorldPoint(px, py - 3)
    massCenter = {gx * M2PIX, gy * M2PIX}
end

local function cameraLock()
    if not massCenter then
        return
    end

    local w, h = gr.getDimensions()
    local space = 100
    --cam:lockWindow(massCenter[1], massCenter[2], space, w - space, space, h - space)
    local space = 100
    local dx, dy = shipBody:getLinearVelocity()
    dx, dy = dx * M2PIX, dy * M2PIX
    print(inspect(massCenter), w, space)
    if massCenter[1] > w - space then
        cam:move(cam.x - dx, cam.y)
    elseif massCenter[1] < space then
        cam:move(cam.x + dx, cam.y)
    elseif massCenter[2] < space then
        cam:move(cam.x, cam.y + dy)
    elseif massCenter[2] > h - space then
        cam:move(cam.x, cam.y - dy)
    end
end

local function update()
    local shape = shipBody:getFixtures()[1]:getShape()
    local shapePoints = {shape:getPoints()}
    local worldPoints = {shipBody:getWorldPoints(unpack(shapePoints))}
    local pixelPoints = scalePoints2PIX(worldPoints)

    dirVec = updateDirVector(worldPoints)

    updateMassCenterVector()

    --print("pixelPoints", inspect(pixelPoints))
    info = {
        points = {pixelPoints[3], pixelPoints[4], pixelPoints[5], pixelPoints[6] },
        dir = shallowCopy(dirVec),
        thrust = 1,
    }

    cameraLock()
end

local function getEngineInfo()
    --return x, y, dir, thrust
    if info then
        return info.points, info.dir, info.thrust
    end
end

return {
    create = create,
    updateMesh = updateMesh,
    thrust = thrust,
    thrustLeft = thrustLeft,
    thrustRight = thrustRight,
    update = update,

    setApplyingForce = setApplyingForce,
    getApplyingForce = getApplyingForce,
    getEngineInfo = getEngineInfo,

    getDirectionVec = getDirectionVec,
    getThrustLeft = getThrustLeft,
    getThrustRight = getThrustRight,
}
