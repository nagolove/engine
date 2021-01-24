require "camera"
--function shallowCopy(t)
    --local res = {}
    --for k, v in pairs(t) do
        --res[k] = v
    --end
    --return res
--end

global type Scene = record
    init: function()
    quit: function()
    draw: function()
    drawui: function()
    update: function()
    keypressed: function()
    mousemov: function()
    keypressed: function()
    wheelmoved: function()
    getCamera: function(): Camera
end

global type Tool = record
    init: function
    update: function
    draw: function()
    keypressed: function(key: string)
    mousemoved: function(number, number, number, number)
    mousereleased: function(number, number, number)
    mousepressed: function(number, number, number)
end
