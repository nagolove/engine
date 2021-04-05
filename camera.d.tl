
global type Camera = record
    x: number
    y: number
    scale: number
    rot: number
    smoother: function(number, number): {number, number}

    new: function(): Camera

    move: function(Camera, number, number): Camera
    attach: function(Camera)
    detach: function(Camera)
    cameraCoords: function(Camera, x: number, y:number, ox: number, oy: number, w: number, h: number): number, number
    worldCoords: function(Camera, number, number, number|nil, number:nil, number:nil, number:nil): number, number
    zoom: function(Camera, number)
    lookAt: function(Camera, number, number)
    position: function(Camera): number, number
end

return Camera
