-- vim: fdm=marker
-- vim: set colorcolumn=85

require "love.thread"

local generator_channel = love.thread.getChannel("generator_channel")
local yield = coroutine.yield

local enum Command
    "gen"
end

--[[
local cmd_circle_buf: {Command} = {}
local cmd_circle_buf_maxnum = 16 * 2

local function push_cbuf(cmd: Command)
    if #cmd_circle_buf >= cmd_circle_buf_maxnum then
        table.remove(cmd_circle_buf, 1)
    end
    table.insert(cmd_circle_buf, cmd)
end

local function print_stack()
    print(colorize(
        "%{blue}cmd stack: " .. 
        inspect(cmd_circle_buf) .. 
        "%{reset}"
    ))
end
--]]

local commands = {}

function commands.gen(): boolean
    return false
end

while true do
    local cmd: Command

    repeat
        cmd = generator_channel:demand() as Command
        --push_cbuf(cmd)

        local fun = commands[cmd]
        if not fun then
            print_stack()
            error('generator_thread unknown command: ' .. cmd)
        end
        if not fun() then
            break
        end

    until not cmd
end
