--[[
local record Vec
    x: number
    y: number

    metamethod __mul: function(a: Vec|number, b:Vec|number): Vec|number
    metamethod __add: function(a: Vec, b: Vec): Vec
    --metamethod __add: function(a: Vec|number, b: Vec|number): Vec
end

local a, b: Vec = { x = 0, y = 0}, { x = 1, y = 1 }
local c = a + a * b
--]]


--function deepcopy(orig: any)
    --local orig_type = type(orig)
    --local copy = {}
    --if orig_type == 'table' then
        --copy = {}
        ----for orig_key, orig_value in next, orig , nil do
        --for orig_key, orig_value in next(orig as {any:any}), orig do
            --copy[deepcopy(orig_key)] = deepcopy(orig_value)
        --end
        --setmetatable(copy, deepcopy(getmetatable(orig)))
    --else -- number, string, boolean, etc
        --copy = orig
    --end
    --return copy
--end


--local a = { 
    --a = { 
        --k = false 
    --}, 
    --0, 
    --1 
--}

--local inspect = require("inspect")
--print(inspect(deepcopy(a)))

local t = {
    1, 2, "false", k = {}
}
for key,value in next,t,nil do print(key,value) end

