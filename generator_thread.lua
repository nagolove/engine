local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string


print('generator_thread: started')

local args = { ... }

local inspect = require('inspect')
print('args', inspect(args))

require('love.timer')
require("love.thread")
require("love.math")
require('common')

local gen_status_channel = love.thread.getChannel("gen_status_channel")

local das = require("diamond_and_square")
local serpent = require('serpent')

local mapn = args[1]

if type(mapn) ~= 'number' then
   error("'mapn' type should be a number, not " .. type(mapn))
end
local low_range, high_range = 1, 12
if mapn < low_range or mapn > high_range then
   error(string.format(
   'mapn out on range(%d..%d) - %d',
   low_range, high_range,
   mapn))

end

local rng_state = args[2]

if type(rng_state) ~= 'string' then
   error("'rng_state' should be a string nor " .. type(rng_state))
end

local rng = love.math.newRandomGenerator()
rng:setState(rng_state)

print('mapn, state', mapn, rng_state)

local gen = das.new(
mapn,
function()
   return rng:random()
end)


function write2file()

   local map = {}
   for i = 1, gen:get_mapsize() do
      map[#map + 1] = {}
      for j = 1, gen:get_mapsize() do
         map[#map][j] = gen:get(i - 1, j - 1)
      end
   end


   local dir_name = zerofyNum(mapn) .. "_" .. rng_state
   love.filesystem.createDirectory(dir_name)

   local fname = dir_name .. "/map.data.bin"
   print('write2file: fname', fname)

   local compress = love.data.compress
   local struct = require('struct')
   local packed_mapsize = struct.pack("L", gen:get_mapsize())

   love.filesystem.write(fname, "", 0)
   love.filesystem.append(fname, packed_mapsize, #packed_mapsize)

   print('map', #map)

   for i = 1, #map do
      local row = map[i]
      local uncompressed = serpent.dump(row)
      local compressed = compress('string', 'gzip', uncompressed, 9)





      local packed_rowlen = struct.pack("L", #compressed)
      love.filesystem.append(fname, packed_rowlen, #packed_rowlen)
      love.filesystem.append(fname, compressed, #compressed)
   end

end

local tstart = love.timer.getTime()
gen:eval()
local tfinish = love.timer.getTime()
print('map generated for', (tfinish - tstart) * 1000., "sec.")












write2file()


gen_status_channel:push(true)

print('generator_thread: finished')
