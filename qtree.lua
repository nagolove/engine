--[[
-- Класс запросов к прямоугольникам. Представляет собой quad-tree для плоскости.
--]]

local inspect = require "inspect"

local QTree = {}
QTree.__index = QTree

function QTree.new()
    local self = {}
    return setmetatable({}, QTree)
end

function QTree:add(x, y, w, h)
end

function QTree:query(x, y)
end

return {
    new = QTree.new,
}
