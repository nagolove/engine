﻿package.path = package.path .. ";scenes/fractaltree/?.lua"
local AVL = require "avltree"

g, angle = love.graphics, 26 * math.pi / 180
wid, hei = g.getWidth(), g.getHeight()

--local exampleTree = AVL:new{1,10,5,15,20,3,5,14,7,13,2,8,3,4,5,10,9,8,7}
--print("exampleTree:dump()", exampleTree:dump())

local test=AVL:new{1,10,5,15,20,3,5,14,7,13,2,8,3,4,5,10,9,8,7}

test:dump()
print("\ninsert 17:")
test=test:insert(17)
test:dump()
print("\ndelete 10:")
test=test:delete(10)
test:dump()
print("\nlist:")
print(unpack(test:toList()))

function rotate( x, y, a )
    local s, c = math.sin( a ), math.cos( a )
    local a, b = x * c - y * s, x * s + y * c
    return a, b
end

function branches( a, b, len, ang, dir )
  len = len * .76
  if len < 10 then return end
  g.setColor( len * 16, 255 - 2 * len , 0 )
  if dir > 0 then ang = ang - angle
  else ang = ang + angle 
  end
  local vx, vy = rotate( 0, len, ang )
  vx = a + vx; vy = b - vy
  g.line( a, b, vx, vy )
  branches( vx, vy, len, ang, 1 )
  branches( vx, vy, len, ang, 0 )
end

function createTree()
  local lineLen = 127
  local a, b = wid / 2, hei - lineLen
  g.setColor( 160, 40 , 0 )
  g.line( wid / 2, hei, a, b )
  branches( a, b, lineLen, 0, 1 ) 
  branches( a, b, lineLen, 0, 0 )
end

local function init()
  canvas = g.newCanvas( wid, hei )
  g.setCanvas( canvas )
  createTree()
  g.setCanvas()
end

local function draw()
  g.draw( canvas )
end

return {
    init = init,
    draw = draw,
}
