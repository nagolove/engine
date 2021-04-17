require "camera"
require "keyconfig"

local inspect = require "inspect"

local type CameraSettings = record
    dx: number
    dy: number
    relativedx: number
    relativedy: number
end

local cameraSettings: CameraSettings = {}

cameraSettings = {
    -- знавение в пикселях
    dx = 20,
    dy = 20,

    -- значение в пикселях сглаженное относительно значения scale камеры
    relativedx = 0,
    relativedy = 0,
}

local Shortcut = KeyConfig.Shortcut
local animTimer = require "Timer".new()

local function bindCameraControl(camera: Camera)
    local cam = camera
    print("bindCameraControl", inspect(cam))

    -- не прямой а квадратичный зум?
    --local zoomStartTime = 0
    --local zoomDirection = 0 -- -1 or 1
    --local zoomFactor = 0.001

    --[[
    KeyConfig.bind(
        "isdown",
        { key = "z" },
        function(sc: Shortcut): boolean, Shortcut
            cam:zoom(1.01)
            return false, sc
        end,
        "zoom camera out",
        "zoomout"
    )

    KeyConfig.bind(
        "isdown",
        { key = "x" },
        function(sc: Shortcut): boolean, Shortcut
            cam:zoom(0.99)
            return false, sc
        end,
        "zoom camera in",
        "zoomin"
    )
    --]]

    local function makeMoveFunction(xc: number, yc: number): function(sc: Shortcut): boolean, Shortcut
        return function(sc: Shortcut): boolean, Shortcut
            local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
            cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy
            -- когда идет нажатие повлиять на цвет части текста
            animTimer:during(0.4, function(_: number, time: number, delay: number)
                --print("dt, timer, delay", dt, time, delay)
                cam:move(-reldx * (delay - time) * xc, -reldy * (delay - time) * yc)
            end)
            return true, sc
        end
    end

    KeyConfig.bind( "isdown", { key = "left" }, makeMoveFunction(1., 0), "move left", "camleft")
    KeyConfig.bind( "isdown", { key = "right" }, makeMoveFunction(-1.0, 0.), "move right", "camright") 
    KeyConfig.bind( "isdown", { key = "up" }, makeMoveFunction(0., 1.), "move up", "camup") 
    KeyConfig.bind( "isdown", { key = "down" }, makeMoveFunction(0., -1.), "move down", "camdown")
end

local function cameraControlUpdate(dt: number)
    animTimer:update(dt)
end

return {
    bindCameraControl = bindCameraControl,
    cameraControlUpdate = cameraControlUpdate,
}
