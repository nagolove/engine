local ffi = require 'ffi'
local colorize = require 'ansicolors2'.ansicolors

require 'chipmunk_h'

local C = ffi.load 'chipmunk'
local concolor = '%{blue}'
local DENSITY = (1.0/10000.0)
local space
local body
-- Pipeline
local pl

local function init(pipeline)
    assert(pipeline and 'Pipeline is nil')

    print(colorize(concolor .. 'Chipmunk init'))
    space = C.cpSpaceNew()

	--cpSpaceSetIterations(space, 30);
	--cpSpaceSetGravity(space, cpv(0, -500));
	--cpSpaceSetSleepTimeThreshold(space, 0.5f);
	--cpSpaceSetCollisionSlop(space, 0.5f);

    pl = pipeline
	local width = 50.0
	local height = 70.0
	local mass = width * height * DENSITY;
	local moment = C.cpMomentForBox(mass, width, height);
	
    -- Что такое момент?
	body = C.cpSpaceAddBody(space, C.cpBodyNew(mass, moment));

    local shape = C.cpBoxShapeNew(body, width, height, 0.)
    shape = C.cpSpaceAddShape(space, shape)

    -- Что делают строчки ниже?
	--shape = cpSpaceAddShape(space, cpBoxShapeNew(body, width, height, 0.0));
	--cpShapeSetFriction(shape, 0.6);

    pl:pushCode("rect", [[
    local col = {1, 1, 1, 1}
    love.graphics.setColor(col)
    while true do
        love.graphics.rectangle('fill', 0, 0, 1000, 1000)
        coroutine.yield()
    end
    ]])
end

local function eachBody(body, data)
    print('eachBody')
end

local internal_data = ffi.new('char[1024]')
local void_internal_data = ffi.cast('void*', internal_data)

local function render()
    print('body', body)
    C.cpSpaceEachBody(space, body, void_internal_data)

    --pl:open("rect")
    --pl:close()
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
