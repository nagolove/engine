local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local table = _tl_compat and _tl_compat.table or table; require('love')

local serpent = require('serpent')
local verts = {}
local inspect = require('inspect')

local function init()
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

local function render()
   for _, v in ipairs(verts) do

      love.graphics.polygon('fill', v)
   end
end

return {
   init = init,
   render = render,
}
