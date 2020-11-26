local cpml = require 'cpml'
vec3 = cpml.vec3
mat4 = cpml.mat4

function transpose(mat)
    local  m = cpml.mat4.new()
    return cpml.mat4.transpose(m, mat)
end

TMPMAT = mat4()
IDEMAT = mat4()
IDEMAT:transpose(IDEMAT)

--[[
-- Что значат параметры x, y, z? Перемещение
-- Что значат параметры ax, ay, az? Поворот
-- Что значат параметры sx, sy, sz? Масштаб
-- Возвращает матрицу трансформации.
--]]
function mat_totransform(x, y, z, ax, ay, az, sx, sy, sz)
    sx = sx or 1
    sy = sy or sx or 1
    sz = sz or sx or 1

    local s = vec3( sx, sy, sz )
    local m = mat4()
    m:reset()
    m:rotate(m, ax or 0, vec3.unit_x)
    m:rotate(m, ay or 0, vec3.unit_y)
    m:rotate(m, az or 0, vec3.unit_z)
    m:scale(m, s)
    m:translate(m, vec3(x or 0, y or 0, z or 0))
    
    return m
end


