
local lg = love.graphics
local inspect = require "inspect"

local Object = {
    commonshader = lg.newShader [[
    uniform vec2 param;

    float dist(vec2 p1, vec2 p2) {
        return sqrt((p1.x - p2.x) * (p1.x - p1.x) + 
            (p1.y - p2.y) * (p1.y - p2.y));
    }

    vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {
        vec4 pixel = Texel(image, uvs);

        float avg = (pixel.r + pixel.g + pixel.b) / 3.0;
        //float len = dist(param, uvs);
        float len = dist(param, screen_coords);

        //pixel.r = avg;
        //pixel.g = avg;
        //pixel.b = avg;
        //pixel.r = param.x
        pixel.r = len;

        //return pixel * av;
        //return pixel;
        return color * pixel;
    }
    ]] ,
}

function Object:preDraw()
    local x, y = love.mouse.getPosition()
    local w, h = lg.getDimensions()
    --print(x / w, y / h)
    --lg.setShader(self.commonshader)
    --self.commonshader:send("param", { x / w, y / h})
end

function Object:postDraw()
    --lg.setShader()
end

function Object:inside(mx, my, x, y, w, h)
    if self.cam then
        mx, my = self.cam:worldCoords(mx, my)
    end
    return mx >= x and mx <= (x + w) and my >= y and my <= (y + h)
end

return Object
