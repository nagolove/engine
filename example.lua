local IsPressed = {}

local KeyConfig_ = {BindAccord = {}, Shortcut = {}, }
























local Shortcut = KeyConfig_.Shortcut
local ActionFunc = KeyConfig_.ActionFunc

function KeyConfig_.bind(
   _,
   _,
   _,
   _,
   _)


end

local Tank = {}






function Tank:left() end
function Tank:right() end
function Tank:down() end

local playerTank

local function bindDirection(direction)
   KeyConfig_.bind(
   "isdown", { key = direction },
   function(sc)
      local E = {}






      return false, sc
   end,
   "move tank " .. direction,
   "mt" .. direction)


end
