local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local table = _tl_compat and _tl_compat.table or table; require('love')

local serpent = require('serpent')
local verts = {}
local inspect = require('inspect')

local Drawable = love.graphics.Drawable

local function load_verts()
   for line in love.filesystem.lines('verts.txt') do
      local ok, data = serpent.load(line)
      print('data', inspect(data))
      if ok then
         table.insert(verts, data)
      else
         error('no data in line')
      end
   end
end














local mesh
local mesh_verts = {}
local mesh_size = 1024

local function init_mesh()
   mesh = love.graphics.newMesh(mesh_size * 6, "triangles", "dynamic")
   for _, v in ipairs(verts) do
      print('v', inspect(v))
      local vertex



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

end

local function init()
   load_verts()
   init_mesh()
end

local function render_poly()
   for _, v in ipairs(verts) do

      love.graphics.polygon('fill', v)
   end
end

local function render_mesh()
   love.graphics.setColor({ 1, 1, 1, 1 })



   for k, _ in ipairs(verts) do
      local sub_vert = {}




      mesh:setVertices(mesh_verts, (k - 1) * 6, 6)
   end

   love.graphics.draw(mesh)
end

return {
   init = init,
   render_poly = render_poly,
   render_mesh = render_mesh,
}
