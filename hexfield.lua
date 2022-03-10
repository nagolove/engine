local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table




require("love")
require("common")


local vec = require("vector")
local gr = love.graphics


function getHexPolygonWidth(hex)
   return distance(hex[3], hex[4], hex[11], hex[12])
end

function getHexPolygonHeight(hex)
   return distance(hex[1], hex[2], hex[7], hex[8])
end

 Hex = {}














local Hex_mt = {
   __index = Hex,
}

function Hex:getVertices()
   local vertices = {}
   for i = 1, 6 do
      table.insert(vertices, self[i])
   end
   return vertices
end




function Hex:getAABB()
   local w, h = getHexPolygonWidth(self) / 2, getHexPolygonHeight(self) / 2
   return { self.cx - w, self.cy - h, self.cx + w, self.cx + h }, w * 2, h * 2
end

function Hex:getDebugCanvas()



   local t, w, h = self:getAABB()








   local canvas = gr.newCanvas(gr.getDimensions())


   gr.setCanvas(canvas)
   gr.clear(0, 0, 1)

   gr.push()


   local vi = 1
   for i = 1, #self - 2, 2 do
      gr.setColor({ 1, 1, 1, 1 })
      gr.print(string.format("(%d)", vi), self[i], self[i + 1])
      vi = vi + 1
   end
   gr.line(t[1], t[2], t[3], t[4])
   gr.setColor({ 1, 0, 0 })
   gr.rectangle("line", t[1], t[2], w, h)

   gr.pop()
   gr.setCanvas()

   return canvas
end

function Hex:setMesh(mesh, endindex)
   self.mesh = mesh
   self.endindex = endindex
end

function Hex:setVertexColor(index, _)
   local vertex = { self.mesh:getVertex(self.endindex - index + 0) }


   self.mesh:setVertex(self.endindex - index + 0, vertex)
end

function Hex:setColor(color)
   for i = 1, 6 do
      self:setVertexColor(i, color)
   end
end

local function newHexPolygon(cx, cy, rad)
   local hex = setmetatable({}, Hex_mt)

   local d = math.pi * 2 / 6
   local c = 0.0
   for _ = 1, 7 do
      local x, y = cx + math.sin(c) * rad, cy + math.cos(c) * rad
      table.insert(hex, x)
      table.insert(hex, y)
      c = c + d
   end

   hex.rad = rad
   hex.selected = false
   hex.cx, hex.cy = cx, cy

   return hex
end

function addVertex(array, x, y, color)
   table.insert(array, {
      math.floor(x), math.floor(y),
      0, 0,
      color[1], color[2], color[3], color[4],
   })
   return #array
end

function addHex(data, hex, color)
   addVertex(data, hex.cx, hex.cy, color)
   addVertex(data, hex[1], hex[2], color)
   addVertex(data, hex[3], hex[4], color)

   addVertex(data, hex.cx, hex.cy, color)
   addVertex(data, hex[3], hex[4], color)
   addVertex(data, hex[5], hex[6], color)

   addVertex(data, hex.cx, hex.cy, color)
   addVertex(data, hex[5], hex[6], color)
   addVertex(data, hex[7], hex[8], color)

   addVertex(data, hex.cx, hex.cy, color)
   addVertex(data, hex[7], hex[8], color)
   addVertex(data, hex[9], hex[10], color)

   addVertex(data, hex.cx, hex.cy, color)
   addVertex(data, hex[9], hex[10], color)
   addVertex(data, hex[11], hex[12], color)

   addVertex(data, hex.cx, hex.cy, color)
   addVertex(data, hex[11], hex[12], color)
   return addVertex(data, hex[1], hex[2], color)
end

function addVertex2(array, x, y)
   table.insert(array, {
      math.floor(x), math.floor(y),

      0, 0,
      1, 1, 1, 1,
   })
end


function addLine(array, x1, y1, x2, y2)

   local len = distance(x1, y1, x2, y2)


   print("array", type(array))
   print("x1", type(x1))
   print("y1", type(y1))
   print("x2", type(x2))
   print("y2", type(y2))
   print("len", type(len))





   local dir1, dir2 = vec.new(x2 - x1, y2 - y1) / len, vec.new(x1 - x2, y1 - y2) / len

   local width = 3
   local p1 = vec(x1, y1) + dir1:perpendicular() * width
   local p2 = vec(x1, y1) + dir2:perpendicular() * width
   local p3 = vec(x2, y2) + dir1:perpendicular() * width
   local p4 = vec(x2, y2) + dir2:perpendicular() * width

   addVertex2(array, p1.x, p1.y)
   addVertex2(array, p2.x, p2.y)
   addVertex2(array, p3.x, p3.y)

   addVertex2(array, p4.x, p4.y)
   addVertex2(array, p3.x, p3.y)
   addVertex2(array, p2.x, p2.y)
end

function addBorder(data, hex)
   addLine(data, hex[1], hex[2], hex[3], hex[4])
   addLine(data, hex[3], hex[4], hex[5], hex[6])
   addLine(data, hex[5], hex[6], hex[7], hex[8])
   addLine(data, hex[7], hex[8], hex[9], hex[10])
   addLine(data, hex[9], hex[10], hex[11], hex[12])
   addLine(data, hex[11], hex[12], hex[1], hex[2])
end

 HexField = {}








local function newHexField(
   startcx, startcy,
   map,
   rad,
   color)





   local xcount = #map
   local ycount = #map[1]
   assert(xcount == ycount)

   local Handler = {
      map = {},
   }
   Handler.__index = Handler

   for k, v in ipairs(map) do
      Handler.map[k] = {}
      for _, v2 in ipairs(v) do
         table.insert(Handler.map[k], v2)
      end
   end





   local result = {}
   setmetatable(result, Handler)


   local mesh = gr.newMesh((6 * 3 + 6 * 6) * xcount * ycount, "triangles", "dynamic")
   local meshData = {}

   local cx, cy = startcx, startcy
   local hasWH = false
   local w, h

   local horizon = {}
   local prevHorizon = nil

   for j = 1, ycount do
      for i = 1, xcount do
         local last = newHexPolygon(cx, cy, rad)
         last.j = j
         last.i = i



         local visible = map[j][i] ~= 0

         if visible then


            table.insert(horizon, last)
         end









         last.refs = {}

         if not hasWH then
            w, h = getHexPolygonWidth(last), getHexPolygonHeight(last)
         end

         local lastIndex
         if visible then
            lastIndex = addHex(meshData, last, color)
            addBorder(meshData, last)
            last:setMesh(mesh, lastIndex)
         end

         cx = cx + w
      end

      for _, v in ipairs(horizon) do
         table.insert(result, v)
      end
      prevHorizon = horizon
      horizon = {}

      cy = cy + h * 3 / 4
      cx = j % 2 == 1 and startcx + w / 2 or startcx
   end



   mesh:setVertices(meshData)


   return result, mesh
end

return {
   newHexField = newHexField,
   newHexPolygon = newHexPolygon,
}
