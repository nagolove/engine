
local type TCamera = record
    x: number
    y: number
    scale: number
    rot: number
    smoother: function(number, number): {number, number}

    new: function(): TCamera

    move: function(TCamera, number, number): TCamera
    attach: function(TCamera)
    detach: function(TCamera)
    cameraCoords: function(TCamera, x: number, y:number, ox: number, oy: number, w: number, h: number): number, number
    worldCoords: function(TCamera, number, number, number|nil, number:nil, number:nil, number:nil): number, number
    zoom: function(TCamera, number)
    lookAt: function(TCamera, number, number)
    position: function(TCamera): number, number
end

return TCamera
