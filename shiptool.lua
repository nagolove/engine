local gr = love.graphics
local inspect = require "inspect"
local pworld, cam
local ship = require "ship"

local scale = require "scale"
local scalePoints2M = scale.points2M
local scalePoints2PIX = scale.points2PIX
local scalePoint2CameraWorldCoords = scale.point2CameraWorldCoords
local M2PIX = scale.M2PIX
local PIX2M = scale.PIX2M

local underCursor = {}
local currentScene

local function init(scene)
    if scene and scene.pworld then
        pworld = scene.pworld
        cam = scene.cam
        currentScene = scene
    end
end

local function drawThrust(masscx, masscy, vecx, vecy, color)
    gr.setColor(color)
    gr.line(masscx, masscy, masscx + vecx, masscy + vecy)
end

local function drawThrustVectors(masscx, masscy)
    local dirVec = ship.getDirectionVec()
    local mult = 30
    if dirVec then
        drawThrust(masscx, masscy, dirVec[1] * mult, dirVec[2] * mult, {0, 0, 1})
        --gr.setColor{0, 0, 1}
        --gr.line(masscx, masscy, masscx + dirVec[1], masscy + dirVec[2])
        --gr.circle("fill", masscx, masscy, 2)
    end
    local leftThrust = ship.getThrustLeft()
    if leftThrust then
        drawThrust(masscx, masscy, leftThrust[1] * 10, leftThrust[2] * 10, {0, 0, 1})
    end
    local rightThrust = ship.getThrustRight()
    if rightThrust then
        drawThrust(masscx, masscy, rightThrust[1] * 10, rightThrust[2] * 10, {0, 0, 1})
    end
end

local function drawBodyVectors(body)
    local masscx, masscy, _, _ = body:getMassData()
    masscx, masscy = body:getWorldPoints(masscx, masscy)
    masscx, masscy = M2PIX * masscx, M2PIX * masscy

    gr.setColor{1, 0, 0}
    gr.circle("fill", masscx, masscy, 3)

    local vx, vy = body:getLinearVelocity()

    gr.setColor(0.7, 0, 0)
    gr.line(masscx, masscy, masscx + vx, masscy + vy)

    drawThrustVectors(masscx, masscy)
end

local function drawFixture(fixture)
    
    local body = fixture:getBody()
    local shape = fixture:getShape()
    stype = shape:getType()

    local prevColor = {gr.getColor()}
    gr.setColor{0, 1, 0}

    if stype == "edge" then

        local points = scalePoints2PIX({body:getWorldPoints(shape:getPoints())})
        --points = scalePoint2CameraWorldCoords(cam, points)

        --print("edge points", inspect(points))
        --local points = {body:getWorldPoints(shape:getPoints())}
        --print("points", inspect(points))
        
        gr.line(points)

    elseif stype == "circle" then

        local px, py = body:getWorldPoints(shape:getPoint())
        px, py = px * M2PIX, py * M2PIX
        --px, py = cam:worldCoords(px, py)

        gr.circle("fill", px, py, shape:getRadius() * M2PIX)

    elseif stype == "polygon" then

        local points = scalePoints2PIX({body:getWorldPoints(shape:getPoints())})
        --points = scalePoint2CameraWorldCoords(cam, points)
        --local points = {body:getWorldPoints(shape:getPoints())}
        
        --gr.polygon("fill", points)

    else
        error("Unknown type")
    end

    gr.setColor{0, 0, 0}
    drawBodyVectors(body)

    gr.setColor(prevColor)
end

local function onQueryBoundingBox(fixture)
    local mx, my = cam:worldCoords(love.mouse.getPosition())
    mx, my = mx * PIX2M, my * PIX2M
    --print("onQueryBoundingBox underCursor")

    if fixture:testPoint(mx, my) then
        table.insert(underCursor, fixture)
    end

    return true
    --return false
end

function mousemoved(x, y, dx, dy)
    --print("x, y, dx, dy", x, y, dx, dy)
    if not pworld then
        return
    end
    --print("cam", cam)

    local w, h = gr.getDimensions()
    local tlx, tly, brx, bry = 0, 0, w, h
    --local w, h = 0.01, 0.01
    --local tlx, tly, brx, bry = x - w, y - h, x + w, y + h
    tlx, tly = cam:worldCoords(tlx, tly)
    brx, bry = cam:worldCoords(brx, bry)

    underCursor = {}
    pworld:queryBoundingBox(tlx * PIX2M, tly * PIX2M, brx * PIX2M, bry * PIX2M, onQueryBoundingBox)
end

local forceOrImpulse = "force"

local function drawShipSetup()
    imgui.Begin("ship setup", true, "ImGuiWindowFlags_AlwaysAutoResize")

    local ok1 = imgui.RadioButton("use impulse", forceOrImpulse == "impulse")
    if ok1 then
        forceOrImpulse = "impulse"
    end

    local ok2 = imgui.RadioButton("use force", forceOrImpulse == "force")
    if ok2 then
        forceOrImpulse = "force"
    end

    imgui.LabelText("applaying force", ship.getApplyingForce())

    local v, ok = imgui.SliderFloat("force", ship.getApplyingForce(), 0, 300, 0.9)
    ship.setApplyingForce(v)

    imgui.End()

    gr.setColor{1, 1, 1, 1}

    if #underCursor then
        for _, v in pairs(underCursor) do
            drawFixture(v)
        end
    end
end

function keypressed(key)
end

function update()
end

return {
    init = init,
    draw = drawShipSetup,
    update = update,
    mousemoved = mousemoved,
    keypressed = keypressed,
}

