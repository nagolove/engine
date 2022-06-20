-- vim: fdm=marker
-- vim: set colorcolumn=85

print('generator_thread: started')

local args = {...} -- mapn, rng_state

local inspect = require 'inspect'
print('args', inspect(args))

require 'love.timer'
require "love.thread"
require "love.math"
require 'common'

local gen_status_channel = love.thread.getChannel("gen_status_channel")
local yield = coroutine.yield
local das = require "diamond_and_square"
local serpent = require 'serpent'

local mapn = args[1] as integer

if type(mapn) ~= 'number' then
    error("'mapn' type should be a number, not " .. type(mapn))
end
local low_range, high_range = 1, 12
if mapn < low_range or mapn > high_range then
    error(string.format(
        'mapn out on range(%d..%d) - %d', 
        low_range, high_range,
        mapn
    ))
end

local rng_state = args[2] as string

if type(rng_state) ~= 'string' then
    error("'rng_state' should be a string nor " .. type(rng_state))
end

local rng = love.math.newRandomGenerator()
rng:setState(rng_state)

print('mapn, state', mapn, rng_state)

local gen = das.new(
    mapn,
    function(): number
        return rng:random()
    end
)

function write2file(): string
    -- Сделать построчную обработку, без создания {{number}}
    local map: {{number}} = {}
    for i = 1, gen:get_mapsize() do
        map[#map + 1] = {}
        for j = 1, gen:get_mapsize() do
            map[#map][j] = gen:get(i - 1, j - 1)
        end
    end

    --local fname = "map.data." .. randomFilenameStr() .. ".txt"
    local dir_name = zerofyNum(mapn) .. "_" .. rng_state
    love.filesystem.createDirectory(dir_name)

    local fname = dir_name .. "/map.data.bin"
    print('write2file: fname', fname)

    local compress = love.data.compress
    local struct = require 'struct'
    local packed_mapsize = struct.pack("L", gen:get_mapsize())

    love.filesystem.write(fname, "", 0)
    love.filesystem.append(fname, packed_mapsize, #packed_mapsize)

    print('map', #map)
    local packed_mapsize = struct.pack("L", gen:get_mapsize())

    for i = 1, #map do
        local row = map[i]
        local uncompressed = serpent.dump(row)
        local compressed = compress('string', 'gzip', uncompressed, 9) as string

        --print(format('row[%d]', i))
        --print('#uncompressed', size2human(#uncompressed))
        --print('#compressed', size2human(#compressed))

        local packed_rowlen = struct.pack("L", #compressed)
        love.filesystem.append(fname, packed_rowlen, #packed_rowlen)
        love.filesystem.append(fname, compressed, #compressed)
    end
    --]]

    return fname
end

local tstart = love.timer.getTime()
gen:eval()
local tfinish = love.timer.getTime()
print('map generated for', (tfinish - tstart) * 1000., "sec.")

--[[
    coro = gen:newCoroutine()
    stop = false
    repeat
        stop = coroutine.resume(coro)
        -- Данные о прогрессе
        gen_status_channel:push()
    until not stop
--]]

local fname = write2file()
--gen_status_channel:push(fname)
--gen_status_channel:push(mapn, rng_state)
gen_status_channel:push(true)

print('generator_thread: finished')
