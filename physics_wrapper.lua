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
local format = string.format
local dprint = require 'debug_print'
local debug_print = dprint.debug_print

-- След строка нужна?
require 'chipmunk_h'
local C = ffi.load 'chipmunk'

local concolor = '%{blue}'
local DENSITY = (1.0/10000.0)
-- Текущее пространство
local cur_space
-- Pipeline
local pl
local indexType = 'uint64_t'
local ptrType = 'cpDataPointer'

local bodies = {}

--[[
local bodiesnum = 1024 * 2
--local bodies_C = ffi.new('(void*)[?]', bodiesnum)
local bodies_C = ffi.new('cpDataPointer[?]', bodiesnum)
local function fillbodies()
    for i = 0, bodiesnum - 1 do
        bodies_C[i] = ffi.cast(ptrType, 0)
    end
end
--]

--[[
local function col_begin(arb, space, data)
    print('begin')
    print('arb, space, data', arb, space, data)
end

local function col_preSolve(arb, space, data)
    print('pres')
    print('arb, space, data', arb, space, data)
end

local function col_postSolve(arb, space, data)
    print('posts')
    print('arb, space, data', arb, space, data)
end

local function col_separate(arb, space, data)
    print('sep')
    print('arb, space, data', arb, space, data)
end
--]]

--local col_begin_C = ffi.cast("cpCollisionBeginFunc", col_begin)
--local col_preSolve_C = ffi.cast("cpCollisionPreSolveFunc", col_preSolve)
--local col_postSolve_C = ffi.cast("cpCollisionPostSolveFunc", col_postSolve)
--local col_separate_C = ffi.cast( "cpCollisionSeparateFunc", col_separate)

--local collison_data = ffi.new('char[1024]')
--local void_collision_data = ffi.cast('void*', collison_data)

local function init(pipeline)
    assert(pipeline and 'Pipeline is nil')

    print(colorize(concolor .. 'Chipmunk init'))
    cur_space = C.cpSpaceNew()

	--cpSpaceSetIterations(space, 30);
	--cpSpaceSetGravity(space, cpv(0, -500));
	--cpSpaceSetSleepTimeThreshold(space, 0.5f);
	--cpSpaceSetCollisionSlop(space, 0.5f);

    print("C.CP_CIRCLE_SHAPE", C.CP_CIRCLE_SHAPE)
    print("C.CP_SEGMENT_SHAPE", C.CP_SEGMENT_SHAPE)
    print("C.CP_POLY_SHAPE", C.CP_POLY_SHAPE)
    print("C.CP_NUM_SHAPES", C.CP_NUM_SHAPES)

    pl = pipeline

    --[[
	local width = 150.0
	local height = 170.0
	local mass = width * height * DENSITY;
	local moment = C.cpMomentForBox(mass, width, height);

    -- Что такое момент?
	body = C.cpSpaceAddBody(cur_space, C.cpBodyNew(mass, moment));

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
    --]]

    --[[ Не работает вызов функции. Найти аналог в современном интерфейсе.
    C.cpSpaceSetDefaultCollisionHandler(
        space,
        col_begin_C,
        col_preSolve_C,
        col_postSolve_C,
        col_separate_C
    )
    --]]

end

--local shape_data = ffi.new('char[1024]')
--local void_shape_data = ffi.cast('void*', shape_data)

--local function eachShape(body, shape, data)
local function eachShape(_, shape, _)

    --print('eachShape')
    --print('body, shape, data:', body, shape, data)

    --C.cpShapeSetFriction
    local shape_type = shape.klass_private.type
    --if shape_type == C.CP_CIRCLE_SHAPE then
        --print('I am circle.')
    --elseif shape_type == C.CP_SEGMENT_SHAPE then
        --print('I am segment.')
    --elseif shape_type == C.CP_POLY_SHAPE then

    if shape_type == C.CP_POLY_SHAPE then
        --print('I am poly.')
        --local poly_shape = fff.cast('cpPolyShape*', shape)
        local num = C.cpPolyShapeGetCount(shape)
        local verts = {}
        for i = 0, num - 1 do
            local vert = C.cpPolyShapeGetVert(shape, i)
            --print(inspect(vert))
            --print('x, y', vert.x, vert.y)

            table.insert(verts, vert.x)
            table.insert(verts, vert.y)
        end
        pl:open('poly_shape')
        pl:push(verts)
        pl:close()
    end
end

--local eachShape_C = ffi.cast('cpBodyShapeIteratorFunc', eachShape)

--[[
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
--]]

--local internal_data = ffi.new('char[1024]')
--local void_internal_data = ffi.cast('void*', internal_data)

--local function render()
    --C.cpSpaceEachBody(space, eachBody_C, void_internal_data)
--end

local function update(dt)
    --print('pw update', dt)
    C.cpSpaceStep(cur_space, dt);
	--C.cpSpaceStep(cur_space, 0.1);
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
    C.cpSpaceFree(cur_space)
    print(colorize(concolor .. 'Chipmunk free done'))
end

local Body = {
    getPos = function(self)
        self.pos = C.cpBodyGetPosition(self.body)
        return self.pos
    end,

    applyImpulse = function(self, impx, impy)
        --print('self', inspect(self))
        --print('impx, impy', impx, impy)
        -- Как выделить переменные impulse и point?
        -- Оптимизируется ли вызов ffi.new()?
        -- Или использовать заранее выделенные переменные?
      
        --C.cpBodyApplyImpulseAtLocalPoint(self.body, impulse, point)
        self.impulse.x, self.impulse.y = impx, impy
        self.point.x, self.point.y = 0., 0.

        --print('self.impulse', self.impulse.x, self.impulse.y)
        --print('self.point', self.point.x, self.point.y)
        C.cpBodyApplyImpulseAtLocalPoint(self.body, self.impulse, self.point)
    end,

    getInfoStr = function(self)
        --print(colorize('%{blue}' .. 'self: ' .. inspect(self)))
        local b = self.body
        --print('self.body', b)
        local buf = ''
        buf = buf .. format('mass: %.3f\n', b.m)
        buf = buf .. format('inertia moment: %.3f\n', b.i)
        buf = buf .. format('gravity center: (%.3f, %.3f)\n', b.cog.x, b.cog.y)
        buf = buf .. format('pos: (%.3f, %.3f)\n', b.p.x, b.p.y)
        buf = buf .. format('vel: (%.3f, %.3f)\n', b.v.x, b.v.y)
        buf = buf .. format('force: (%.3f, %.3f)\n', b.f.x, b.f.y)
        buf = buf .. format('angle: %.3f\n', b.a)
        buf = buf .. format('angular vel: %.3f\n', b.w)
        buf = buf .. format('torque: %.3f', b.t)
        return buf
    end,

    bodySetPosition = function(self, x, y)
        self.pos.x, self.pos.y = x, y
        C.cpBodySetPosition(self.body, self.pos)
    end,

    setUserData = function(self, data)
    end,
    getUserData = function(self)
    end,
}

local Body_mt = {
    __index = Body,
}

local function newBoxBody(width, height, params)
    local use_print = params and params.use_print

    --print('use_print', use_print)
    --print('params', inspect(params))
    --os.exit(-1)

    local self = setmetatable({}, Body_mt)
    table.insert(bodies, self)

	local mass = width * height * DENSITY;
    if use_print then
        print('mass', mass)
    end

    -- Что такое момент?
    local moment = C.cpMomentForBox(mass, width, height);
	--local moment = 1.
    if use_print then
        print('moment', moment)
    end

    self.body = C.cpBodyNew(mass, moment);
	C.cpSpaceAddBody(cur_space, self.body)
    if use_print then
        print('self.body', self.body)
    end

    local index = #bodies
    self.body.userData = ffi.cast(ptrType, index)
    if use_print then
        print('index', index)
    end

    -- box is PolyShape
    local shape = C.cpBoxShapeNew(self.body, width, height, 0.)
    C.cpSpaceAddShape(cur_space, shape)

    --C.cpSpaceAddBody(cur_space, body)

    self.impulse = ffi.new('cpVect')
    self.point = ffi.new('cpVect')
    self.pos = ffi.new('cpVect')

    --[[
    local force = ffi.new('cpVect')
    force.x = 0
    force.y = 0
    local r = ffi.new('cpVect')
    r.x = 0
    r.y = 0
    C.cpBodyApplyForceAtLocalPoint(body, force, r)
    --]]

    return self
end

local function newEachSpaceBodyIter(cb)
    local eachBody_C = ffi.cast("cpSpaceBodyIteratorFunc", cb)
    return eachBody_C
end

--local internal_data = ffi.new('char[1024]')
--local void_internal_data = ffi.cast('void*', internal_data)

-- Почему при одном теле на сцене коллбэк вызывается два раза?
local function eachSpaceBody(iter)
    -- Обходное решение для передачи параметра
    C.cpSpaceEachBody(cur_space, iter, nil)
end

local function eachBodyShape(body, iter)
    --print('eachBodyShape')
    --print('body, iter', inspect(body), inspect(iter))
    --print('body, iter', body, iter)
    C.cpBodyEachShape(body, iter, nil)
end

local function cpBody2Body(cpbody)
    local index = ffi.cast(indexType, cpbody.userData)
    index = tonumber(index)
    --print('cpBody2Body')
    --print('index', index)
    return bodies[index]
end

local function newEachBodyShapeIter(cb)
    local eachShape_C = ffi.cast('cpBodyShapeIteratorFunc', cb)
    --local eachShape_C = ffi.cast('cpBodyShapeIteratorFunc', eachShape)
    return eachShape_C
end

return {
    init = init,
    --render = render,
    update = update,
    free = free,

    newEachSpaceBodyIter = newEachSpaceBodyIter,
    newEachBodyShapeIter = newEachBodyShapeIter,
    newBoxBody = newBoxBody,

    getBodies = function()
        return bodies
    end,

    eachSpaceBody = eachSpaceBody,
    eachBodyShape = eachBodyShape,

    cpBody2Body = cpBody2Body,

    polyShapeGetCount = function(shape)
        assert(shape)
        return C.cpPolyShapeGetCount(shape)
    end,
    polyShapeGetVert = function(shape, index)
        assert(shape)
        local lvert = C.cpPolyShapeGetVert(shape, index)
        local body = C.cpShapeGetBody(shape)
        local wvert = C.cpBodyLocalToWorld(body, lvert)
        return wvert
    end,
    polyShapeGetType = function(shape)
        assert(shape)
        local t = tonumber(shape.klass_private.type)
        --print('t', t)
        return t
    end,

    CP_CIRCLE_SHAPE = 0,
    CP_SEGMENT_SHAPE = 1,
    CP_POLY_SHAPE = 2,
}
