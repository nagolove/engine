local ffi = require("ffi")

pcall(ffi.cdef, [[
typedef struct ImageData_Pixel
{
    uint8_t r, g, b, a;
} ImageData_Pixel;
typedef struct Grid_Data
{
    /*
    state bits [0, 1, 2, 3, 4, 5, 6, 7, 8]
    0 - food
    1 - cell
    */
    uint8_t state;
} Grid_Data;
]])

local gridptr = ffi.typeof("Grid_Data*")

local Grid = {}
Grid.__index = Grid

function Grid:new()
end
function Grid:fillZero()
end
function Grid:isFood(i, j)
end
function Grid:setFood(i, j)
end

function newGrid(size)
    return setmetatable({}, Grid)
end

return {
    new = newGrid,
}

