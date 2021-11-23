--[[
Не хочется писать обертку, но придется?
Какие функции для физики будут нужны во внешнем мире?
Какие объекты нужно будет создавать?
К каким свойствам объектов нужно получать доступ?
Что можно полностью скрыть?
Как не просвечивать механизмом FFI?
Определиться с видами объектов.
--]]

local ffi = require 'ffi'
local colorize = require 'ansicolors2'.ansicolors
local inspect = require "inspect"

require 'chipmunk_h'

local C = ffi.load 'chipmunk'
local concolor = '%{blue}'
local DENSITY = (1.0/10000.0)
local space
local body
-- Pipeline
local pl

local function col_begin(arb, space, data)
    print('begin')
end

local function col_preSolve(arb, space, data)
    print('pres')
end

local function col_postSolve(arb, space, data)
    print('posts')
end

local function col_separate(arb, space, data)
    print('sep')
end

local col_begin_C = ffi.cast("cpCollisionBeginFunc", col_begin)
local col_preSolve_C = ffi.cast("cpCollisionPreSolveFunc", col_preSolve)
local col_postSolve_C = ffi.cast("cpCollisionPostSolveFunc", col_postSolve)
local col_separate_C = ffi.cast( "cpCollisionSeparateFunc", col_separate)

local collison_data = ffi.new('char[1024]')
local void_collision_data = ffi.cast('void*', collison_data)

local function init(pipeline)
    assert(pipeline and 'Pipeline is nil')

    print(colorize(concolor .. 'Chipmunk init'))
    space = C.cpSpaceNew()

	--cpSpaceSetIterations(space, 30);
	--cpSpaceSetGravity(space, cpv(0, -500));
	--cpSpaceSetSleepTimeThreshold(space, 0.5f);
	--cpSpaceSetCollisionSlop(space, 0.5f);

    pl = pipeline
	local width = 150.0
	local height = 170.0
	local mass = width * height * DENSITY;
	local moment = C.cpMomentForBox(mass, width, height);
	
    -- Что такое момент?
	body = C.cpSpaceAddBody(space, C.cpBodyNew(mass, moment));

    -- box is PolyShape
    local shape = C.cpBoxShapeNew(body, width, height, 0.)
    shape = C.cpSpaceAddShape(space, shape)

    local force = ffi.new('cpVect')
    force.x = 0
    force.y = 0
    local r = ffi.new('cpVect')
    r.x = 0
    r.y = 0
    C.cpBodyApplyForceAtLocalPoint(body, force, r)

    -- Что делают строчки ниже?
	--shape = cpSpaceAddShape(space, cpBoxShapeNew(body, width, height, 0.0));
	--cpShapeSetFriction(shape, 0.6);

    --[[ Не работает вызов функции. Найти аналог в современном интерфейсе.
    C.cpSpaceSetDefaultCollisionHandler(
        space,
        col_begin_C,
        col_preSolve_C,
        col_postSolve_C,
        col_separate_C
    )
    --]]

    pl:pushCode("rect", [[
    local col = {1, 1, 1, 1}
    --love.graphics.setColor(col)
    while true do
        --love.graphics.setColor(col)
        love.graphics.rectangle('fill', 0, 0, 1000, 1000)
        coroutine.yield()
    end
    ]])

    pl:pushCode("poly_shape", [[
    local col = {1, 0, 0, 1}
    --love.graphics.setColor(col)
    local inspect = require "inspect"
    while true do
        love.graphics.setColor(col)
        local verts = graphic_command_channel:demand()
        print('poly_shape: verts', inspect(verts))
        --love.graphics.rectangle('fill', 0, 0, 1000, 1000)
        love.graphics.polygon('fill', verts)
        coroutine.yield()
    end
    ]])
end

local shape_data = ffi.new('char[1024]')
local void_shape_data = ffi.cast('void*', shape_data)

local function eachShape(body, shape, data)
    print('eachShape')
    print('body, shape, data:', body, shape, data)
    --C.cpShapeSetFriction
    local shape_type = shape.klass_private.type
    if shape_type == C.CP_CIRCLE_SHAPE then
        print('I am circle.')
    elseif shape_type == C.CP_SEGMENT_SHAPE then
        print('I am segment.')
    elseif shape_type == C.CP_POLY_SHAPE then
        print('I am poly.')
        --local poly_shape = fff.cast('cpPolyShape*', shape)
        local num = C.cpPolyShapeGetCount(shape)
        local verts = {}
        for i = 0, num - 1 do
            local vert = C.cpPolyShapeGetVert(shape, i)
            --print(inspect(vert))
            print('x, y', vert.x, vert.y)

            table.insert(verts, vert.x)
            table.insert(verts, vert.y)
        end
        pl:open('poly_shape')
        pl:push(verts)
        pl:close()
    end
end

local eachShape_C = ffi.cast('cpBodyShapeIteratorFunc', eachShape)

local function eachBody(body, data)
    --print('eachBody')
    --print('body, data', body, data)

    -- Вызвать функции для перечисления всех форм тела.
    -- Отправить вершины тел на рисовку.
    -- Как лучше отправлять вершины? Что-бы делать более редкие передачи
    -- данных.

    C.cpBodyEachShape(body, eachShape_C, void_shape_data)
end

local eachBody_C = ffi.cast("cpSpaceBodyIteratorFunc", eachBody)

local internal_data = ffi.new('char[1024]')
local void_internal_data = ffi.cast('void*', internal_data)

local function render()
    C.cpSpaceEachBody(space, eachBody_C, void_internal_data)
end

local function update(dt)
    --print('pw update')
	C.cpSpaceStep(space, dt);
end

local function free()

    --[[
    -- Пример функции для удаления всех объектов - детей
void
ChipmunkDemoFreeSpaceChildren(cpSpace *space)
{
	// Must remove these BEFORE freeing the body or you will access dangling pointers.
	cpSpaceEachShape(space, (cpSpaceShapeIteratorFunc)postShapeFree, space);
	cpSpaceEachConstraint(space, (cpSpaceConstraintIteratorFunc)postConstraintFree, space);
	
	cpSpaceEachBody(space, (cpSpaceBodyIteratorFunc)postBodyFree, space);
}
--]]

    print(colorize(concolor .. 'Chipmunk free start'))
    C.cpSpaceFree(space)
    print(colorize(concolor .. 'Chipmunk free done'))
end

return {
    init = init,
    render = render,
    update = update,
    free = free,
}
