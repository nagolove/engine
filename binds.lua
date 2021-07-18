require("camera")
require("keyconfig")

local inspect = require("inspect")

local CameraSettings = {}






local cameraSettings = {

   dx = 20,
   dy = 20,


   relativedx = 0,
   relativedy = 0,
}

local Shortcut = KeyConfig.Shortcut
local animTimer = require("Timer").new()

local function bindCameraControl(camera)
   local cam = camera
   print("bindCameraControl", inspect(cam))






























   local function makeMoveFunction(xc, yc)
      return function(sc)
         local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
         cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy

         animTimer:during(0.4, function(_, time, delay)

            cam:move(-reldx * (delay - time) * xc, -reldy * (delay - time) * yc)
         end)
         return true, sc
      end
   end

   KeyConfig.bind("isdown", { key = "left" }, makeMoveFunction(1., 0), "move left", "camleft")
   KeyConfig.bind("isdown", { key = "right" }, makeMoveFunction(-1.0, 0.), "move right", "camright")
   KeyConfig.bind("isdown", { key = "up" }, makeMoveFunction(0., 1.), "move up", "camup")
   KeyConfig.bind("isdown", { key = "down" }, makeMoveFunction(0., -1.), "move down", "camdown")
end

local function cameraControlUpdate(dt)
   animTimer:update(dt)
end

return {
   bindCameraControl = bindCameraControl,
   cameraControlUpdate = cameraControlUpdate,
}
