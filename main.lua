local jit = require "jit"
--_G['print'] = function() end
--jit.off()
-- :setlocal foldmethod=manual
--require "mobdebug".start()
print("package.path", package.path)

local imgui
local ok, errmsg = pcall(function()
	--imgui = require "imgui"
    --imgui = package.loadlib("./love-imgui.dll", "luaopen_imgui2")
    imgui = require "imgui"
    --imgui()
	--imgui = require "love-imgui"
	--imgui = require "afflove-imgui"
end)
if not ok then
	print(errmsg)
end

package.cpath = package.cpath .. ";?.dll"
local cwd = love.filesystem.getWorkingDirectory()
errmsg = errmsg or ""

love.filesystem.write("log.txt", errmsg)

love.draw = function( )
    local y = 10
	love.graphics.print(errmsg, 10, y)
    y = y + love.graphics.getFont():getHeight() * 20
	love.graphics.print("cwd:" .. cwd, 10, y)

    local w, h = love.graphics.getDimensions()
    local limit = math.ceil(w * 0.8)
    y = y + love.graphics.getFont():getHeight() * 3
	love.graphics.printf("package.path" .. package.path, 10, y, limit)

    y = y + love.graphics.getFont():getHeight() * 3
	love.graphics.printf("package.cpath" .. package.cpath, 10, y, limit)
end

--local imgui = require "love-imgui"
