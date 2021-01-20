local _tl_compat53 = ((tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3) and require('compat53.module'); local pairs = _tl_compat53 and _tl_compat53.pairs or pairs; require("love")
require("camera")

function copy(t)
   local result = {}
   for k, v in pairs(t) do
      result[k] = v
   end
   return result
end

function flatCopy(src)
   local dst = {}
   for k, v in pairs(src) do
      if type(v) ~= "table" and type(v) ~= "function" and type(v) ~= "thread" then
         dst[k] = v
      end
   end
   return dst
end

local CameraSettings = {}






local cameraSettings = {}

cameraSettings = {

   dx = 20,
   dy = 20,


   relativedx = 0,
   relativedy = 0,
}

function controlCamera(cam)
   local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
   cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy
   local isDown = love.keyboard.isDown
   if isDown("lshift") then
      if isDown("left") then
         cam:move(-reldx, 0)
      elseif isDown("right") then
         cam:move(reldx, 0)
      elseif isDown("up") then
         cam:move(0, -reldy)
      elseif isDown("down") then
         cam:move(0, reldy)
      end
   end
end
