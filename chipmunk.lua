--chipmunk2D ffi binding for chipmunk 6.x
local ffi = require'ffi'
require'chipmunk_h'
local C = ffi.load 'chipmunk.so'
--local C = ffi.load 'ch.so'

local colorize = require 'ansicolors2'.ansicolors

print(colorize('%{blue}preload'))
--C.cpInitChipmunk()
print(colorize('%{blue}I am loaded'))

--if not ... then require'chipmunk_demo' end

return C
