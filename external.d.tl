local type Camera = record
    x: number
    y: number
    scale: number
    rot: number
    smoother: function(number, number): {number, number}
end

local type External = record
    copy: function(t: any): any
    flatCopy: function(src: any): any
    copy1: function(src: any): any
    controlCamera: function(cam: Camera)
end
