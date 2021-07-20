--[[
local type IsPressed = function(str: string): boolean

local type KeyConfig_ = record

    type BindAccord = record
        mod: {string}
        key: string
        mousekey: string
    end
    type Shortcut = record
        combo: BindAccord
        action: ActionFunc
        description: string
        enabled: boolean
    end
    type ActionFunc = function(Shortcut): boolean, Shortcut
    type BindType = enum
        "keypressed"
        "isdown"
    end
    bind: function( btype: BindType, 
                    combo: BindAccord, 
                    action: ActionFunc, 
                    description: string, 
                    id: string|nil)
end

local Shortcut = KeyConfig_.Shortcut
local ActionFunc = KeyConfig_.ActionFunc

function KeyConfig_.bind(
    _: KeyConfig_.BindType,
    _: KeyConfig_.BindAccord,
    _: ActionFunc, 
    _: string, 
    _: string|nil)

    -- do something ..
end

local record Tank
    left: function(Tank)
    right: function(Tank)
    up: function(Tank)
    down: function(Tank)
end

function Tank:left() end
function Tank:right() end
function Tank:down() end

local playerTank: Tank

local function bindDirection(direction: string)
    KeyConfig_.bind(
        "isdown", { key = direction },
        function(sc: Shortcut): boolean, Shortcut
            local enum E
                "left"
                "right"
                "down"
                "up"
            end
            --playerTank[direction as E](playerTank)
            return false, sc
        end,
        "move tank " .. direction, 
        "mt" .. direction
    )
end

--]]

--bindDirection("left")
