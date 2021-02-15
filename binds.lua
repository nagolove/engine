require("camera")
require("keyconfig")

local inspect = require("inspect")

local CameraSettings = {}






local cameraSettings = {}

cameraSettings = {

   dx = 20,
   dy = 20,


   relativedx = 0,
   relativedy = 0,
}

local Shortcut = KeyConfig.Shortcut

local function bindCameraControl(camera)
   local cam = camera
   print("bindCameraControl", inspect(cam))






   KeyConfig.bind(
   "isdown",
   { key = "z" },
   function(sc)
      cam:zoom(1.01)
      return false, sc
   end,
   "zoom camera out",
   "zoomout")


   KeyConfig.bind(
   "isdown",
   { key = "x" },
   function(sc)
      cam:zoom(0.99)
      return false, sc
   end,
   "zoom camera in",
   "zoomin")


   KeyConfig.bind(
   "isdown",
   { key = "left" },
   function(sc)
      local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
      cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy

      cam:move(-reldx, 0)
      return true, sc
   end,
   "move left",
   "camleft")


   KeyConfig.bind(
   "isdown",
   { key = "right" },
   function(sc)
      local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
      cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy
      cam:move(reldx, 0)
      print("camera right")
      return false, sc
   end,
   "move right",
   "camright")


   KeyConfig.bind(
   "isdown",
   { key = "up" },
   function(sc)
      local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
      cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy
      cam:move(0, -reldy)
      return false, sc
   end,
   "move up",
   "camup")


   KeyConfig.bind(
   "isdown",
   { key = "down" },
   function(sc)
      local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
      cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy
      cam:move(0, reldy)
      return false, sc
   end,
   "move down",
   "camdown")

end

return {
   bindCameraControl = bindCameraControl,
}
