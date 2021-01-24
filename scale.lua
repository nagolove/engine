local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pairs = _tl_compat and _tl_compat.pairs or pairs; require("camera")



M2PIX = 5

PIX2M = 1 / 5

local function scalePoints2M(t)
   local res = {}
   for k, v in pairs(t) do
      res[k] = PIX2M * v
   end
   return res
end

local function scalePoints2PIX(t)
   local res = {}
   for k, v in pairs(t) do
      res[k] = M2PIX * v
   end
   return res
end

local function scalePoint2CameraWorldCoords(cam, points)
   local res = {}
   for i = 1, #points - 1 do
      local x, y = cam:worldCoords(points[i], points[i + 1])
      res[#res + 1] = x
      res[#res + 1] = y
   end
   return res
end

return {
   M2PIX = M2PIX,
   PIX2M = PIX2M,
   points2PIX = scalePoints2PIX,
   points2M = scalePoints2M,
   point2CameraWorldCoords = scalePoint2CameraWorldCoords,
}
