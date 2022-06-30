local type Timer = record
    type DuringFunc = function(dt: number, time: number, delay: number)

    type Tag = string

    new: function(): Timer
    update: function(Timer, dt: number)

    after: function(
        self: Timer, delay: number, action: function(number), tag:string
    ): Tag
    every: function(
        self: Timer, delay: number, action: function(number), 
        count: number, after: function, tag:string
    ): Tag
    during: function(
        self: Timer, delay: number, action: DuringFunc, 
        after: function, tag:string
    ): Tag
    tween: function(
        self: Timer, delay: number, subject: any, target: any, 
        method: string, after: function, tag: string, ...:any
    ): Tag
    cancel: function(self: Timer, tag: Tag) -- disable timer by tag
    destroy: function(self: Timer) -- disable all timers

    --script: function(self: Timer) -- wrap to coroutine
    --metamethod __call: function(self: Timer): Timer
end

return Timer
