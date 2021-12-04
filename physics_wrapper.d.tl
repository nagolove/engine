--local Chipmunk = require 'chipmunk'
local Cm = require 'chipmunk'
require 'pipeline'

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
        body: Cm.cpBody
        --shape: Cm.cpShape
        applyImpulse: function(Body, impx: number, impy: number)
        getInfoStr: function(Body): string

        --polyShapeGetCount: function(Body): number
        --polyShapeGetVert: function(Body, index: number): Cm.cpVect
    end

    -- Добавлять-ли сразу возможность работы с несколькими пространствами?
    init: function(pipeline: Pipeline)
    free: function()
    update: function(dt: number)
    --render: function()

    newVect: function(): Cm.cpVect
    newBoxBody: function(w: number, h: number): Body

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
end

return PhysicsWrapper
