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

function copy1(t)
    local result = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            result[k] = {}
            local newt = result[k]
            for k1, v1 in pairs(v) do
                newt[k1] = v1
            end
        else
            result[k] = v
        end
    end
    return result
end

cameraSettings = {
    -- знавение в пикселях
    dx = 20,
    dy = 20,

    -- значение в пикселях сглаженное относительно значения scale камеры
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
