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

local function bindCameraControl(camera: Camera)
    local cam = camera
    print("bindCameraControl", inspect(cam))

    -- не прямой а квадратичный зум?
    --local zoomStartTime = 0
    --local zoomDirection = 0 -- -1 or 1
    --local zoomFactor = 0.001

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

    KeyConfig.bind(
        "isdown",
        { key = "left" },
        function(sc: Shortcut): boolean, Shortcut
            local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
            cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy
            -- когда идет нажатие повлиять на цвет части текста
            cam:move(-reldx, 0)
            return true, sc
        end,
        "move left",
        "camleft"
    )

    KeyConfig.bind(
        "isdown",
        { key = "right" },
        function(sc: KeyConfig.Shortcut): boolean, KeyConfig.Shortcut
            local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
            cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy
            cam:move(reldx, 0)
            return false, sc
        end,
        "move right",
        "camright"
    )

    KeyConfig.bind(
        "isdown",
        { key = "up" },
        function(sc: KeyConfig.Shortcut): boolean, KeyConfig.Shortcut
            local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
            cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy
            cam:move(0, -reldy)
            return false, sc
        end,
        "move up",
        "camup"
    )

    KeyConfig.bind(
        "isdown",
        { key = "down" },
        function(sc: KeyConfig.Shortcut): boolean, KeyConfig.Shortcut
            local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
            cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy
            cam:move(0, reldy)
            return false, sc
        end,
        "move down",
        "camdown"
    )
end

return {
    bindCameraControl = bindCameraControl,
}
