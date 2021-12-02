--local Chipmunk = require 'chipmunk'
local Cm = require 'chipmunk'
require 'pipeline'

local record PhysicsWrapper
    record Body
        body: Cm.cpBody
        --shape: Cm.cpShape
        applyImpulse: function(Body, impx: number, impy: number)
        getInfoStr: function(Body): string
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

    record EachSpaceBodyIter end
    record EachBodyShapeIter end

    -- Возвращает итератор для каждого тела в пространстве
    newEachSpaceBodyIter: function(cb: EachSpaceBodyCallback): EachSpaceBodyIter
    -- Возвращает итератор для кажлой формы тела
    newEachBodyShapeIter: function(cb: EachBodyShapeCallback): EachBodyShapeIter

    cpBody2Body: function(Cm.cpBody): Body

    eachSpaceBody: function(iter: EachSpaceBodyIter)
    eachBodyShape: function(b: Cm.cpBody, iter: EachBodyShapeIter)
end

return PhysicsWrapper
