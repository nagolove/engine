require "love"
require "camera"

function shallowCopy<T>(t: T): T
   local copy = {}
   for k, v in pairs(t as {any:any}) do
      copy[k] = v
   end
   return copy as T
end

local type anyFunc = function(any): any
function my_setfenv(f: anyFunc, env: {any: any}): anyFunc, string
    return load(string.dump(f), nil, nil, env)
end

function pointInRect(px: number, py: number, x: number, y: number, w: number, h: number): boolean
    return px > x and py > y and px < x + w and py < y + h
end

global type Scene = record
    init: function()
    quit: function()
    update: function(number|nil)
    draw: function()
    drawui: function()
    mousemoved: function(number, number, number, number)
    mousepressed: function(number, number, number)
    mousereleased: function(number, number, number)
    keypressed: function(string)
    keyreleased: function(string)
    wheelmoved: function(number, number)
    getCamera: function(): Camera
end

global type SceneMap = record
    scene: Scene
    name: string
    inited: boolean
end

global type Tool = record
    init: function(Scene)
    update: function()
    draw: function()
    keypressed: function(key: string)
    mousemoved: function(number, number, number, number)
    mousereleased: function(number, number, number)
    mousepressed: function(number, number, number)
end

function safeSend(shader: love.graphics.Shader, name: string, ...: any)
  if shader:hasUniform(name) then
    shader:send(name, (... as table))
  end
end

