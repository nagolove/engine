local gr = love.graphics
local inspect = require "inspect"
local pworld, cam
local scene

local scale = require "scale"
local scalePoints2M = scale.points2M
local scalePoints2PIX = scale.points2PIX
local scalePoint2CameraWorldCoords = scale.point2CameraWorldCoords
local M2PIX = scale.M2PIX
local PIX2M = scale.PIX2M

local underCursor = {}

local shapePoint

local function init(currentScene)
    if currentScene.pworld then
        pworld = currentScene.pworld
        scene = currentScene
        cam = scene.cam
        scene = scene
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
        
        gr.polygon("fill", points)

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

        -- перевожу из глобальных координат камеры в метры. Потом - в локальные координаты шейпа
        gr.setColor{1, 1, 0}
        gr.circle("fill", mx, my, 3)
    else
        shapePoint = nil
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

local function drawBodyStat(body)
    local msg

    msg = string.format("%f kg", body:getMass())
    imgui.LabelText("mass", msg)

    local px, py = body:getPosition()
    msg = string.format("%f, %f", px, py)
    imgui.LabelText("position", msg)

    local px, py = body:getLocalCenter()
    msg = string.format("%f, %f", px, py)
    imgui.LabelText("center of mass(local)", msg)

    imgui.LabelText("body type", tostring(body:getType()))

    local inertia = body:getInertia()
    msg = string.format("%f, %f", px, py)
    imgui.LabelText("rotational inertia", msg)

    local scale = body:getGravityScale()
    msg = string.format("%f", scale)
    imgui.LabelText("rotational inertia", msg)

    local angle = body:getAngle()
    msg = string.format("%f", angle)
    imgui.LabelText("angle", msg)

    local angle = body:getAngularVelocity()
    msg = string.format("%f", angle)
    imgui.LabelText("angular velocity(rad/sec)", msg)

    local damping = body:getAngularDamping()
    msg = string.format("%f", damping)
    imgui.LabelText("angular damping", msg)

    local damping = body:getLinearDamping()
    msg = string.format("%f", damping)
    imgui.LabelText("linear damping", msg)

    if shapePoint then
        imgui.LabelText("shape point", string.format("%.3f, %.3f", shapePoint.x, shapePoint.y))
    end
end

function drawBox2dInfo()
    imgui.Begin("box2d", false, "ImGuiWindowFlags_AlwaysAutoResize")

    if underCursor[1] then
        local body = underCursor[1]:getBody()
        drawBodyStat(body)
    end
    imgui.Text(string.format("__FREEZE_PHYSICS__ = %s", tostring(__FREEZE_PHYSICS__ or false)))

    imgui.End()
    gr.setColor{1, 1, 1, 1}

    if #underCursor then
        for _, v in pairs(underCursor) do
            drawFixture(v)
        end
    end
end

function keypressed(key)
    if key == "p" then
        if __FREEZE_PHYSICS__ then
            __FREEZE_PHYSICS__ = not __FREEZE_PHYSICS__
        else
            __FREEZE_PHYSICS__ = true
        end
    end
end

function update()
    local isDown = love.keyboard.isDown
    if isDown("z") then
        cam:zoom(1.01)
    elseif isDown("x") then
        cam:zoom(0.99)
    end
end

return {
    init = init,
    draw = drawBox2dInfo,
    update = update,
    mousemoved = mousemoved,
    keypressed = keypressed,
}

