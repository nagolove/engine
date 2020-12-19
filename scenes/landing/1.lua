-- vim: set foldmethod=manual

local engine = require "engine"
local inspect = require "inspect"
local backgroundColor = {0.000000, 0.175000, 0.250000}
local gr = love.graphics
local lp = love.physics
local pworld = lp.newWorld(0, 300, true)
local cam = require "camera".new()
local terrain = require "terrain".load
local ship = require "ship"
require "common"

local scale = require "scale"
local scalePoints2M = scale.points2M
local scalePoints2PIX = scale.points2PIX
local M2PIX = scale.M2PIX
local PIX2M = scale.PIX2M

local shipBody

local terrainMesh

local function drawTerrain(points)
    local p1, p2 = points[1], points[2]
    gr.setColor{0, 0, 0}
    local i = 3
    while i < #points do
        gr.line(p1, p2, points[i], points[i + 1])
        p1, p2 = points[i], points[i + 1]
        i = i + 2
    end
end

local function bounds()
    local w, h = gr.getDimensions()
    w, h = w * 7, h * 7

    local body = lp.newBody(pworld, 0, 0, "static")
    body:setUserData("bounds") -- <- fixme !!
    
    lp.newFixture(body, lp.newEdgeShape(
        PIX2M * 0,
        PIX2M * 0,
        PIX2M * w,
        PIX2M * 0
    ))
    lp.newFixture(body, lp.newEdgeShape(
        PIX2M * 0,
        PIX2M * h,
        PIX2M * w,
        PIX2M * h
    ))
    lp.newFixture(body, lp.newEdgeShape(
        PIX2M * 0,
        PIX2M * 0,
        PIX2M * 0,
        PIX2M * h
    ))
    lp.newFixture(body, lp.newEdgeShape(
        PIX2M * w,
        PIX2M * 0,
        PIX2M * w,
        PIX2M * h
    ))

end

local function init(lvldata)
    --print("lvldata", inspect(lvldata))
    if lvldata then
        print("mesh", lvldata.mesh)
        terrainMesh = terrain(pworld, lvldata)
        if lvldata.cam then
            cam.x, cam.y = lvldata.cam.x, lvldata.cam.y
            cam.scale = lvldata.cam.scale
            cam.rotate = lvldata.cam.rotate
        end
    end

    bounds()

    local px, py

    if lvlData then
        local shipData = lvlData.ship
        px, py = shipData.x, shipData.y
    else
        local w, h = gr.getDimensions()
        px, py = (w / 2) * PIX2M, (h / 4) * PIX2M
    end
    
    shipBody, shipMesh = ship.create(pworld, cam, px, py)
    engine.init()
end

local function quit()
end

local function onQueryBoundingBox(fixture)
    local body = fixture:getBody()
    local shape = fixture:getShape()
    stype = shape:getType()

    if stype == "edge" then

        local points = scalePoints2PIX({body:getWorldPoints(shape:getPoints())})

        --[[
           [if body:getUserData() == "terrain" then
           [    gr.setColor{1, 1, 1, 1}
           [    gr.line(points)
           [else
           [    gr.setColor{1, 1, 1, 1}
           [    gr.line(points)
           [end
           ]]

    elseif stype == "circle" then

        --local px, py = body:getWorldPoints(shape:getPoint())
        --px, py = px * M2PIX, py * M2PIX
        --gr.circle("fill", px, py, shape:getRadius() * M2PIX)

    elseif stype == "polygon" then

        gr.setColor{1, 1, 1, 1}
        ship.updateMesh(shipMesh, fixture)
        gr.draw(shipMesh)

        engine.draw(ship.getEngineInfo())

    else
        error("Unknown type")
    end

    return true
end

local function drawBodies(world)
    local bodies = world:getBodies()
    for _, body in pairs(bodies) do
        local vx, vy = body:getLinearVelocity()
        for _, fixture in pairs(body:getFixtures()) do
            onQueryBoundingBox(fixture)
        end
    end
end

local function draw()
    gr.clear(backgroundColor)
    --sky.draw()
    cam:attach()

    local w, h = gr.getDimensions()
    local tlx, tly, brx, bry = 0, 0, w, h
    tlx, tly = cam:worldCoords(tlx, tly)
    brx, bry = cam:worldCoords(brx, bry)

    pworld:queryBoundingBox(tlx * PIX2M, tly * PIX2M, brx * PIX2M, bry * PIX2M, onQueryBoundingBox)

    --[[
       [if __SELECTED_COLOR__ then
       [    gr.setColor(__SELECTED_COLOR__)
       [else
       [    gr.setColor{1, 0, 0}
       [end
       ]]

    if terrainMesh then
        gr.draw(terrainMesh)
    end
    --drawTerrain(terrainPoints)

    cam:detach()
end

local function up()
    ship.thrust()
    --applyToShip(0, -applyingValue)
end

local function down()
    --applyToShip(0, applyingValue)
end

local function left()
    ship.thrustLeft()
    --applyToShip(-applyingValue, 0)
end

local function right()
    ship.thrustRight()
    --applyToShip(applyingValue, 0)
end

local function checkKeys()
    local isDown = love.keyboard.isDown
    if isDown("up", "w") then
        up()
    elseif isDown("down", "s") then
        down()
    elseif isDown("left", "a") then
        left()
    elseif isDown("right", "d") then
        right()
    end
end

local function update(dt)
    if not __FREEZE_PHYSICS__ then
        pworld:update(dt)
    end
    ship.update()
    engine.update()

    checkKeys()
end

local function keypressed(key)
    if key == "g" then
        local dx, dy = pworld:getGravity()
        print("gravity", dx, dy)
        if dx == 0 and dy == 0 then
            pworld:setGravity(0, -100)
        else
            pworld:setGravity(0, 0)
        end
    end
end

return {
    cam = cam, 
    pworld = pworld,

    PIX2M = PIX2M,
    M2PIX = M2PIX,

    init = init,
    quit = quit,
    draw = draw,
    update = update,
    keypressed = keypressed,
}
