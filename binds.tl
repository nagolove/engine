require "keyconfig"
require "camera"

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

local function bindCameraControl(keyconfig: KeyConfig, cam: Camera)

    keyconfig.bind(
        "isdown",
        {"z"},
        function(sc: Shortcut): boolean, Shortcut
            print("zoout")
            cam:zoom(1.01)
            -- false - не пересобирать список
            -- true - пересобирать список
            return false, sc
        end,
        "zoom camera out",
        "zoomout"
    )

    keyconfig.bind(
        "isdown",
        {"x"},
        function(sc: Shortcut): boolean, Shortcut
            cam:zoom(0.99)
            return false, sc
        end,
        "zoom camera in",
        "zoomin"
    )

    keyconfig.bind(
        "isdown",
        {"left"},
        function(sc:Shortcut): boolean, Shortcut
            local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
            cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy
            -- когда идет нажатие повлиять на цвет части текста
            cam:move(-reldx, 0)
            return true, sc
        end,
        "move left",
        "camleft"
    )

    keyconfig.bind(
        "isdown",
        {"right"},
        function(sc: Shortcut): boolean, Shortcut
            local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
            cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy
            cam:move(reldx, 0)
            return false, sc
        end,
        "move right",
        "camright"
    )

    keyconfig.bind(
        "isdown",
        {"up"},
        function(sc: Shortcut): boolean, Shortcut
            local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
            cameraSettings.relativedx, cameraSettings.relativedy = reldx, reldy
            cam:move(0, -reldy)
            return false, sc
        end,
        "move up",
        "camup"
    )

    keyconfig.bind(
        "isdown",
        {"down"},
        function(sc: Shortcut): boolean, Shortcut
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
