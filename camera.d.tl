
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
    worldCoords: function(Camera, number, number, number|nil, number:nil, number:nil, number:nil): number, number
    zoom: function(Camera, number)
    lookAt: function(Camera, number, number)
end

return Camera
