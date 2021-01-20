
global type Camera = record
    x: number
    y: number
    scale: number
    rot: number
    smoother: function(number, number): {number, number}

    move: function(Camera, number, number): Camera
end

return Camera
