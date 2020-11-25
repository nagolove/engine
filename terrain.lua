local inspect = require "inspect"
local lp = love.physics

local scale = require "scale"
local scalePoints2M = scale.points2M
local scalePoints2PIX = scale.points2PIX
local M2PIX = scale.M2PIX
local PIX2M = scale.PIX2M

--[[
-- Загружает ребра в физический мир из десериализованной таблицы
--]]
local function load(pworld, t)
    print("terrain.load", inspect(t))
    local w, h = love.graphics.getDimensions()
    local mesh = love.graphics.newMesh(t.mesh)

    local body = lp.newBody(pworld, 0, 0, "static")
    local lines = t.lines
    local i = 1
    while i + 3 <= #lines do
        local fixture = lp.newEdgeShape(lines[i] * PIX2M, lines[i + 1] * PIX2M,
            lines[i + 2] * PIX2M, lines[i + 3] * PIX2M)
        lp.newFixture(body, fixture)
        i = i + 4
    end

    print("shapes done")

    return mesh
end

return {
    load = load,
}
