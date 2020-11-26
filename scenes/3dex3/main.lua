local inspect = require "inspect"
local imgui = require "imgui"
local cpml = require 'cpml'

local gr = love.graphics
local keyDown = love.keyboard.isDown

require "mat"

local mesh = {}

function mesh.new(vert)
  return verts
end

local Rect = setmetatable({}, {__index = mesh})

-- x, y, z - центр прямоугольника или только его угол?
function Rect.new(x, y, z, w, h, ax, ay, az)
	local points = {
    --   x  y  z  ?  ?
		{0, 0, 0, 0, 0},
		{1, 0, 0, 1, 0},
		{1, 1, 0, 1, 1},
		{0, 0, 0, 0, 0},
		{1, 1, 0, 1, 1},
		{0, 1, 0, 0, 1},
	}
	
	local m = mat4()
	m:rotate(m, (ax or 0) + math.pi/2, vec3.unit_x)
	m:rotate(m, ay or 0, vec3.unit_y)
	m:rotate(m, az or 0, vec3.unit_z)
	m:scale(m, vec3(w or 1, h or 1, 1))
	
	m:translate(m, vec3(x or 0, y or 0, z or 0))
	--m:transpose(m)
	
	local point = {0, 0, 0, 1}
	
	for i = 1, #points do
		local p = points[i]
		mat4.mul_vec3(p, m, p)
	end

    --print("rect.new()", inspect(points))
	
	return points
end


local function strsplit(str, sep)
	local list = {}
	sep = sep or ' '
	for c in (str .. sep):gmatch("(.-)" .. sep) do
		list[#list + 1] = c
	end
	return list
end

local models = {}
local model_list = {}

local default = gr.newImage("black.png")

local VERTS = 0
for i, v in ipairs(models) do
	local texture = v.texture and gr.newImage(v.texture)
	if not texture then
		print("Not found", v.texture)
		texture = default
	end
	
	print("create", v.name)
	local m = model:new(v.vertices, texture)
	VERTS = VERTS + #v.vertices
	table.insert(model_list, m)
end


--print(require'inspect'(suzanne))
--m:addVerticies(additionalVerts)
--love.mouse.setRelativeMode(true)
--print("camera3", inspect(require "camera3".new()))

local camera = require "camera3".new()

local function makeTexture(color, w, h)
    w = w or 128
    h = h or 128
    local data = love.image.newImageData(w, h)
    data:mapPixel(function(x, y, r, g, b, a)
        return unpack(color)
    end)
    local image = love.graphics.newImage(data)
    return image
end

local model = require "model"
local r = Rect.new(0, 0, 0, 5, 7, 0, 0, 0)

table.insert(model_list, model.new(r, gr.newImage("img.png")))
table.insert(model_list, model.new(r, gr.newImage("black.png")))
table.insert(model_list, model.new(Rect.new(0, 1, 0, 5, 17, 0, 0, 0), gr.newImage("black.png")))

table.insert(model_list, model.new({
    { 5, -160, 0, 0,   0, 0, 0,           0, 0, 1, 1},
    { 10, 0, 0,    0, 0,   0, 0, 0,      1, 0, 0, 1}, -- верхняя точка
    { 100, -60, 0,    0, 0,   0, 0, 0,    0, 1, 0, 1},

    { 5, -160, 0, 0,   0, 0, 0,           0, 0, 1, 1},
    { 10, 0, 0,    0, 0,   0, 0, 0,      1, 0, 0, 1}, -- верхняя точка
    { 300, -60, 0,    0, 0,   0, 0, 0,    0, 0, 1, 1},
}))
table.insert(model_list, model.new({
    { 0, -160, 5, 0,   0, 0, 0,           0, 0, 1, 1},
    { 0, 0, 10,    0, 0,   0, 0, 0,      1, 0, 0, 1}, -- верхняя точка
    { 0, -60, 100,    0, 0,   0, 0, 0,    0, 0, 1, 1},
}))
table.insert(model_list, model.new({
    { -160, 0, 0,   0, 0, 0,           0, 0, 1, 1},
    { 0, 0, 0,   0, 0,   0, 0, 0,      1, 0, 0, 1}, -- верхняя точка
    { -60, 0, 0,    0, 0,   0, 0, 0,    0, 0, 1, 1},
}))

--[[
   [table.insert(model_list, model.new({
   [    { 5, -60, 0, 0,   0, 0, 0,    1, 0, 0, 0},
   [    { 10, -60, 1,    0, 0,   0, 0, 0,    1, 0, 0, 0},
   [    { 10, -60, 0,    0, 0,   0, 0, 0,    1, 0, 0, 0},
   [}))
   [table.insert(model_list, model.new({
   [    { 5, -60, 0, 0,   0, 0, 0,           1, 0, 0, 1},
   [    { 0, -60, 1,    0, 0,   0, 0, 0,     0, 1, 0, 1},
   [    { 10, -60, 0,    0, 0,   0, 0, 0,    1, 0, 0, 1},
   [}))
   ]]

-- три перпендикулярные плоскоти
--[[
   [table.insert(model_list, model.new({
   [    { 0, 10, 10,    0, 0, 0, 0, 0,      1, 0, 0, 1},
   [    { 0, 80, 80,    0, 0, 0, 0, 0,      1, 0, 0, 1},
   [    { 0, 1000, 1000,    0, 0, 0, 0, 0,      1, 0, 0, 1},
   [}))
   [table.insert(model_list, model.new({
   [    { 10, 0, 10,    0, 0, 0, 0, 0,      0, 1, 0, 1},
   [    { 30, 0, 30,    0, 0, 0, 0, 0,      0, 1, 0, 1},
   [    { 100, 0, 100,    0, 0, 0, 0, 0,      0, 1, 0, 1},
   [}))
   [table.insert(model_list, model.new({
   [    { 10, 10, 0,    0, 0, 0, 0, 0,      0, 0, 1, 1},
   [    { 30, 30, 0,    0, 0, 0, 0, 0,      0, 0, 1, 1},
   [    { 100, 100, 0,    0, 0, 0, 0, 0,      0, 0, 1, 1},
   [}))
   ]]

for i = 0, 10 do
    table.insert(model_list, model.new(Rect.new(1, 1, i * 10, 5, 17, 0, 0, 0), 
        makeTexture({math.cos(i) * 1, 1 - math.cos(i) * 1, 0})))
end

function love.load()
	camera:move(0, 0, -1)
    love.graphics.setLineWidth(3)
    love.graphics.setLineStyle('rough')
end

function cameraControl()
    if keyDown("lshift") then
        if keyDown("1") then
            camera.position.z = camera.position.z - 0.05
        elseif keyDown("2") then
            camera.position.z = camera.position.z + 0.05
        end
        if keyDown("3") then
            camera.position.x = camera.position.x - 0.05
        elseif keyDown("4") then
            camera.position.x = camera.position.x + 0.05
        end
        if keyDown("5") then
            camera.position.y = camera.position.y - 0.05
        elseif keyDown("6") then
            camera.position.y = camera.position.y + 0.05
        end
    else
        if keyDown("1") then
            camera.angle.z = camera.angle.z - 0.05
        elseif keyDown("2") then
            camera.angle.z = camera.angle.z + 0.05
        end
        if keyDown("3") then
            camera.angle.x = camera.angle.x - 0.05
        elseif keyDown("4") then
            camera.angle.x = camera.angle.x + 0.05
        end
        if keyDown("5") then
            camera.angle.y = camera.angle.y - 0.05
        elseif keyDown("6") then
            camera.angle.y = camera.angle.y + 0.05
        end
    end
end

function love.update(dt)
	local sin, cos = math.sin, math.cos
	local halfpi = math.pi / 2
	
	local vec = vec3(0, 0, 0)
	local spd = 50
	
	local vx = math.cos(camera.angle.y + halfpi) * dt * spd
	local vy = camera.angle.x * dt
	local vz = math.sin(camera.angle.y + halfpi) * dt * spd

	local pos = camera.position
	if keyDown("w") then camera:move( vx,  vy,  vz) end
	if keyDown("s") then camera:move(-vx, -vy, -vz) end

	if keyDown("a") then
		vx = math.cos(camera.angle.y) * dt * spd
		vz = math.sin(camera.angle.y) * dt * spd
		
		camera:move(vx, 0, vz)
	end
	
	if keyDown("d") then
		vx = math.cos(camera.angle.y) * dt * spd
		vz = math.sin(camera.angle.y) * dt * spd
		
		camera:move(-vx, 0, -vz)
	end

	if keyDown("space") then camera:move(0, -dt * spd, 0) end

	if keyDown("c") then camera:move(0, dt * spd, 0) end

    cameraControl()

    imgui.NewFrame()
end

function mousemoved(x, y, vx, vy)
    if math.abs(vx) > 10 or math.abs(vy) > 10 then return end
    camera.angle.x = camera.angle.x + vy / 100
    camera.angle.y = camera.angle.y + vx / 100
    
    if camera.angle.x >  math.pi / 2 then camera.angle.x =  math.pi / 2 end
    if camera.angle.x < -math.pi / 2 then camera.angle.x = -math.pi / 2 end
end

local SCALE = 1
function wheelmoved(_, vy)
	SCALE = SCALE * (vy > 0 and 2 or .5)
end

function love.keypressed(key)
    imgui.KeyPressed(key)
end

function love.keyreleased(key)
    imgui.KeyReleased(key)
end

function love.mousemoved(x, y, vx, vy)
    if not imgui.MouseMoved(x, y) then
        if keyDown("lshift") then
            love.mouse.setRelativeMode(true)
            mousemoved(x, y, vx, vy)
        else
            love.mouse.setRelativeMode(false)
        end
    end
end

function love.mousepressed(x, y, button)
    imgui.MousePressed(button)
end

function love.mousereleased(x, y, button)
    imgui.MouseReleased(button)
end

function love.wheelmoved(x, y)
    if not imgui.WheelMoved(y) then
        wheelmoved(x, y)
    end
end

--local triMesh = require "triMesh".new()
--print("triMesh", inspect(triMesh))

function mat4tostr(m)
	local str = "[ "
    local newline
	for i = 1, 16 do
		str = str .. string.format("%+0.3f", m[i])
		if i < 16 then
			str = str .. ", "
		end
        if i < 16 and i % 4 == 0 then
            str = str .. "\n"
        end
	end
	str = str .. " ]"
    return str
end

local triangle_transform = {
    x = 0, y = 0, z = 0,
    ax = 0, ay = 0, az = 0,
    sx = 1, sy = 1, sz = 1
}
local triangle_transform_mat

function triangleTransformWindow()
    imgui.Begin("triangle transform", true, { "ImGuiWindowFlags_AlwaysAutoResize" })
    local value, status

    local from, to = -1, 1

    value, status = imgui.SliderFloat("x", triangle_transform.x, from, to);
    if status then
        triangle_transform.x = value
    end
    value, status = imgui.SliderFloat("y", triangle_transform.y, from, to);
    if status then
        triangle_transform.y = value
    end
    value, status = imgui.SliderFloat("z", triangle_transform.z, from, to);
    if status then
        triangle_transform.z = value
    end

    value, status = imgui.SliderFloat("ax", triangle_transform.ax, from, to);
    if status then
        triangle_transform.ax = value
    end
    value, status = imgui.SliderFloat("ay", triangle_transform.ay, from, to);
    if status then
        triangle_transform.ay = value
    end
    value, status = imgui.SliderFloat("az", triangle_transform.az, from, to);
    if status then
        triangle_transform.az = value
    end

    value, status = imgui.SliderFloat("sx", triangle_transform.sx, from, to);
    if status then
        triangle_transform.sx = value
    end
    value, status = imgui.SliderFloat("sy", triangle_transform.sy, from, to);
    if status then
        triangle_transform.sy = value
    end
    value, status = imgui.SliderFloat("sz", triangle_transform.sz, from, to);
    if status then
        triangle_transform.sz = value
    end

    triangle_transform_mat = mat_totransform(triangle_transform.x, triangle_transform.y, triangle_transform.z,
        triangle_transform.ax, triangle_transform.ay, triangle_transform.az,
        triangle_transform.sx, triangle_transform.sy, triangle_transform.sz)
    imgui.Text(mat4tostr(triangle_transform_mat))
    imgui.End()
end

function love.draw()
	love.window.setTitle("Vertices: " .. VERTS .. " fps: " .. love.timer.getFPS())
	
    --print("model_list", inspect(model_list))
	camera:start()
		for i, v in ipairs(model_list) do
            v.mat = triangle_transform_mat
            --print("from cycle", inspect(v))
            v:draw(camera)
			--v:draw(camera, triangle_transform.x, triangle_transform.y, triangle_transform.z,
                --triangle_transform.ax, triangle_transform.ay, triangle_transform.az,
                --triangle_transform.sx, triangle_transform.sy, triangle_transform.sz)
		end

--[[
   [        love.graphics.setColor{0, 1, 0}
   [        local w, h = love.graphics.getDimensions()
   [        love.graphics.line(0, 0, w, h)
   [        love.graphics.line(0, h / 2, w, h / 2)
   [        love.graphics.setColor{0, 0, 0}
   [        love.graphics.circle("fill", w / 2, h / 2, 200)
   [
   [        love.graphics.setColor(.8, 1, 1)
   [        love.graphics.circle("fill", w, h, 20)
   [        love.graphics.setColor(0, 0, 0)
   [        love.graphics.circle("fill", 0, 0, 1)
   ]]
        
	camera:stop()

    gr.setColor(1, 1, 1)
	gr.draw(camera.scrbuf, 0, love.graphics.getHeight(), 0, 1, -1)

    gr.setColor(0, 1, 0, .5)
    gr.rectangle("fill", 0, 0, 100, 100)
	
	gr.print('pos '.. inspect{ang = tostring(camera.angle), pos = tostring(camera.position)}, 0, 10)

    gr.setColor(1, 1, 1)
    imgui.Begin("camera", true, { "ImGuiWindowFlags_AlwaysAutoResize" })
    imgui.Text(inspect(camera))
    imgui.End()
    triangleTransformWindow()
    imgui.Render()
end

function love.keypressed(key)
	if key == 'escape' then
		love.event.quit()
	end
end
