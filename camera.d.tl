
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
end

return Camera
