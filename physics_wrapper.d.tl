--local Chipmunk = require 'chipmunk'
local Cm = require 'chipmunk'
local Pipeline = require 'pipeline'

-- Teal - поддержка числовых перечислений. Как может выглядеть?
--global CP_CIRCLE_SHAPE = 0
--global CP_SEGMENT_SHAPE = 1
--global CP_POLY_SHAPE = 2

local record PhysicsWrapper
    CP_CIRCLE_SHAPE: number
    CP_SEGMENT_SHAPE: number
    CP_POLY_SHAPE: number

    record EachSpaceBodyIter end
    record EachBodyShapeIter end
    --record Vert end

    record Body
        user_data: any
        body: Cm.cpBody
        applyImpulse: function(Body, impx: number, impy: number)
        getInfoStr: function(Body): string
        getPos: function(Body): Cm.cpVect
        bodySetPosition: function(Body, x: number, y: number)

        --shape: Cm.cpShape
        --polyShapeGetCount: function(Body): number
        --polyShapeGetVert: function(Body, index: number): Cm.cpVect
        --setUserData: function(Body, data: any)
        --getUserData: function(Body): any
    end

    -- Добавлять-ли сразу возможность работы с несколькими пространствами?
    init: function(pipeline: Pipeline)
    free: function()
    update: function(dt: number)
    --render: function()

    newVect: function(): Cm.cpVect
    
    record Options
        use_print: boolean
    end
    newBoxBody: function(w: number, h: number, params: Options): Body

    getBodies: function(): {Body}

    --type EachCallback = function(Body)
    type EachSpaceBodyCallback = function(Cm.cpBody)
    type EachBodyShapeCallback = function(Cm.cpBody, Cm.cpShape)

    -- Возвращает итератор для каждого тела в пространстве
    newEachSpaceBodyIter: function(cb: EachSpaceBodyCallback): EachSpaceBodyIter
    -- Возвращает итератор для кажлой формы тела
    newEachBodyShapeIter: function(cb: EachBodyShapeCallback): EachBodyShapeIter

    cpBody2Body: function(Cm.cpBody): Body

    eachSpaceBody: function(iter: EachSpaceBodyIter)
    eachBodyShape: function(b: Cm.cpBody, iter: EachBodyShapeIter)

    polyShapeGetCount: function(Cm.cpShape): number
    polyShapeGetVert: function(Cm.cpShape, index: number): Cm.cpVect
    polyShapeGetType: function(Cm.cpShape): number

    for_each_body: function(any, any)
end

return PhysicsWrapper
