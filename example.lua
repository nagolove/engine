local inter = require("inter")
inter.foo()

local Inter = {}





local inspect = require("inspect")

 actions = {}






 Tool = {}





function initModule(tool)
   print("initModule", inspect(tool))
end

initModule({
   init = function()
   end,
   draw = function()
   end,


})




initModule({})
