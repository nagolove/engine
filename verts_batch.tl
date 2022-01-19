require 'love'

local serpent = require 'serpent'
local verts: {{number}} = {}
local inspect = require 'inspect'

local Drawable = love.graphics.Drawable
local mesh: love.graphics.Mesh

local function load_verts()
    for line in love.filesystem.lines('verts.txt') do
        local ok, data = serpent.load(line) as (boolean, {number})
        print('data', inspect(data))
        if ok then
            table.insert(verts, data)
        else
            error('no data in line')
        end
    end
end

--[[
local record Vertex
    x: number
    y: number
    u: number
    v: number
    r: number
    g: number
    b: number
    a: number
end
--]]

local mesh_verts: {{number}} = {}
local mesh_size = 1024
local function init_mesh()
    mesh = love.graphics.newMesh(mesh_size * 6, "triangles", "dynamic")
    for _, v in ipairs(verts) do
        print('v', inspect(v))
        local vertex: {number}

        ----------- первый треугольник

        vertex = {
            v[1], v[2],
            1, 1,
            1, 1, 1, 1,
        }
        table.insert(mesh_verts, vertex)

        vertex = {
            v[3], v[4],
            1, 1,
            1, 1, 1, 1,
        }
        table.insert(mesh_verts, vertex)

        vertex = {
            v[5], v[6],
            1, 1,
            1, 1, 1, 1,
        }
        table.insert(mesh_verts, vertex)

        ----------- второй треугольник

        vertex = {
            v[1], v[2],
            1, 1,
            1, 1, 1, 1,
        }
        table.insert(mesh_verts, vertex)

        vertex = {
            v[7], v[8],
            1, 1,
            1, 1, 1, 1,
        }
        table.insert(mesh_verts, vertex)

        vertex = {
            v[5], v[6],
            1, 1,
            1, 1, 1, 1,
        }
        table.insert(mesh_verts, vertex)

    end
    --mesh:setVertices({1., 1., 1., 1., 1.})
end

local function init()
    load_verts()
    init_mesh()
end

local function render_poly()
    for _, v in ipairs(verts) do
        --print('v', inspect(v))
        love.graphics.polygon('fill', v)
    end
end

local function render_mesh()
    love.graphics.setColor {1, 1, 1, 1}

    --mesh:setVertices(mesh_verts)

    for k, v in ipairs(verts) do
        --mesh:setVertices(mesh_verts, k * 6, 6)
        mesh:setVertices(mesh_verts, (k -1 ) * 6, 6)
    end

    love.graphics.draw(mesh as Drawable)
end

return {
    init = init,
    render_poly = render_poly,
    render_mesh = render_mesh,
}
