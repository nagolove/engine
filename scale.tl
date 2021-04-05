require "camera"

-- коэффициент на который домножаю при переводе из метров в пиксели
--M2PIX = 10
global M2PIX = 5
-- коэффициент на который домножаю при переводе из пикселей в метры
global PIX2M = 1 / 5

local function scalePoints2M(t: {any: any}): {any: any}
    local res: {any: any} = {}
    for k, v in pairs(t) do
        res[k] = PIX2M * v as number
    end
    return res
end

local function scalePoints2PIX(t: {any: any}): {any: any}
    local res: {any: any} = {}
    for k, v in pairs(t) do
        res[k] = M2PIX * v as number
    end
    return res
end

local function scalePoint2CameraWorldCoords(cam: Camera, points: {number}): {number}
    local res: {number} = {}
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

