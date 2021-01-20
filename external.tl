require "love"
require "camera"

function copy<T>(t:T):T
    local result = {}
    for k, v in pairs(t as {any: any}) do
        result[k] = v
    end
    return result as T
end

function flatCopy(src: table): table
    local dst = {}
    for k, v in pairs(src) do
        if type(v) ~= "table" and type(v) ~= "function" and type(v) ~= "thread" then
            dst[k] = v
        end
    end
    return dst
end

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

function controlCamera(cam: Camera)
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
