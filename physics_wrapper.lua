local ffi = require 'ffi'
local colorize = require 'ansicolors2'.ansicolors

require 'chipmunk_h'

local C = ffi.load 'chipmunk'
local concolor = '%{blue}'
local DENSITY = (1.0/10000.0)
local space

local function init()
    print(colorize(concolor .. 'Chipmunk init'))
    space = C.cpSpaceNew()

	--cpSpaceSetIterations(space, 30);
	--cpSpaceSetGravity(space, cpv(0, -500));
	--cpSpaceSetSleepTimeThreshold(space, 0.5f);
	--cpSpaceSetCollisionSlop(space, 0.5f);

	local width = 50.0
	local height = 70.0
	local mass = width * height * DENSITY;
	local moment = cpMomentForBox(mass, width, height);
	
    -- Что такое момент?
	body = cpSpaceAddBody(space, cpBodyNew(mass, moment));
    
    local shape = C.cpSpaceAddShape(space, body)

    -- Что делают строчки ниже?
	--shape = cpSpaceAddShape(space, cpBoxShapeNew(body, width, height, 0.0));
	--cpShapeSetFriction(shape, 0.6);
end

local function update(dt)
    --print('pw update')
	cpSpaceStep(space, dt);
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
    update = update,
    free = free,
}
