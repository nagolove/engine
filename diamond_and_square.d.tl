local record DiamondAndSquare
    -- 0..1 random
    type RandomCallback = function(): number

    record Generator
        internal_free: function(Generator)

        -- XXX not implemented
        is_freed: function(Generator): boolean

        eval: function(Generator)
        -- индексация с 0 по get_mapsize() - 1
        get: function(Generator, i: integer, j: integer): number
        get_mapsize: function(Generator): integer
    end

    new: function(size: integer, rc: RandomCallback): Generator

end

return DiamondAndSquare
