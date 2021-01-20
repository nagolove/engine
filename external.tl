require "love"

function copy(t: any): any
    local result = {}
    for k, v in pairs(t) do
        result[k] = v
    end
    return result
end

function flatCopy(src: any): any
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

global cameraSettings: CameraSettings = {
    -- знавение в пикселях
    dx = 20,
    dy = 20,

    -- значение в пикселях сглаженное относительно значения scale камеры
    relativedx = 0,
    relativedy = 0,
}

global type Camera = record
    x: number
    y: number
    scale: number
    rot: number
    smoother: function(number, number): {number, number}
end

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
