-- [[
-- Based on https://github.com/mxgmn/ConvChain
-- ]]

local ffi = require "ffi"
local lg = love.graphics
local inspect = require "inspect"

local convchain = {}

-- [[
-- sampleImage - love.image.ImageData
-- sampleWidth - int number
-- sampleHeight - int number
-- N - receptor size
-- temperature - float value -1.0..2.0
-- size - int
-- iterations - int
-- seed - int 
-- Function returns love.ImageData object.
-- ]]
function convchain.gen(sampleImageData, sampleWidth, sampleHeight, N, temperature, size, iterations, seed, color)

    function rep(a, b)
        return a - (a / b) * b        
    end

    --prof.hookall("Lua")
    --prof.start()
    seed = math.modf(seed)
    size = math.modf(size)
    iterations = math.modf(iterations)

    local fieldLen = size * size
    local field = ffi.new("bool[?]", fieldLen)
    local weightsLen = math.pow(2, N * N)
    local weights = ffi.new("double[?]", weightsLen)
    local patternLen = N * N

    -- [[ Apply functor f(x, y) to each cell of new allocated bool array. 
    -- ]]
    function pattern(f)
        local result = ffi.new("bool[?]", N * N)
        for y = 0, N - 1 do 
            for x = 0, N - 1 do
                result[x + y * N] = f(x, y)
            end
        end
        return result
    end

    function rotate(p)
        return pattern(function(x, y) return p[N - 1 - y + x * N] end)
    end

    function reflect(p)
        return pattern(function(x, y) return p[N - 1 - x + y * N] end)
    end

    -- p - ffi double[?] weights array
    function index(p)
        local result, power = 0, 1
        for i = 0, patternLen - 1 do
            if p[patternLen - 1 - i] then result = result + power end
            power = power * 2
        end        
        return result
    end

    for y = 0, sampleHeight - 1 do
        for x = 0, sampleWidth - 1 do
            local ps = {}
            ps[1] = pattern(function(dx, dy)
                --local xp = rep(x + dx, sampleWidth)
                --local yp = rep(y + dy, sampleHeight)
                local xp = (x + dx) % sampleWidth
                local yp = (y + dy) % sampleHeight

                local r, g, b = sampleImageData:getPixel(xp, yp)
                return r > 0.9 or g > 0.9 or b > 0.9
            end)
            ps[2] = rotate(ps[1])
            ps[3] = rotate(ps[2])
            ps[4] = rotate(ps[3])
            ps[5] = reflect(ps[1])
            ps[6] = reflect(ps[2])
            ps[7] = reflect(ps[3])
            ps[8] = reflect(ps[4])
            for k = 1, 8 do
                local idx = index(ps[k])
                weights[idx] = weights[idx] + 1
            end
        end
    end

    for k = 0, weightsLen - 1 do
        if weights[k] <= 0 then
            weights[k] = 0.1
        end
    end

    love.math.setRandomSeed(seed)

    for i = 0, fieldLen - 1 do
        field[i] = love.math.random() > 0.5 and true or false        
    end
   
    
    for k = 0, iterations * size * size - 1 do
        local r = love.math.random(fieldLen - 1)        
        local x = rep(r, size)
        local y = math.modf(r / size)
        local q = 1.0

        for sy = y - N + 1, y + N - 1 do 
            for sx = x - N + 1, x + N - 1 do
                local ind, difference = 0, 0
                for dy = 0, N - 1 do
                    for dx = 0, N - 1 do
                        local X = sx + dx
                        --X = X < 0 and X + size or X - size
                        if X < 0 then X = X + size
                        elseif X >= size then X = X - size end
                        local Y = sy + dy
                        if Y < 0 then Y = Y + size
                        elseif Y >= size then Y = Y - size end
                        --Y = Y < 0 and Y + size or Y - size
                        local value = field[X + Y * size]
                        local power = math.pow(2, dy * N + dx)                        
                        if value then
                            ind = ind + power
                        end
                        if X == x and Y == y then
                            if value then difference = power else difference = -power end
                        end
                    end
                end
                local q_mul = weights[ind - difference] / weights[ind]
                q = q * q_mul
            end
        end
        
        if q >= 1 then 
            field[r] = not field[r] 
        else
            if temperature ~= 1 then 
            --print("temperature ~= 1", temperature)
              q = math.pow(q, 1.0 / temperature) 
            end
            if q > love.math.random() then field[r] = not field[r] end
        end
    end

    local imgdata = love.image.newImageData(size, size)
    for y = 0, imgdata:getHeight() - 1 do
        for x = 0, imgdata:getWidth() - 1 do
            if field[y * size + x] then
                imgdata:setPixel(x, y, color)
            end
        end
    end
    
    return imgdata
end

return convchain
