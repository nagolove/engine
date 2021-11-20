local record Chipmunk
    type cpFloat = number

    record cpVect
        x: cpFloat
        y: cpFloat
    end

    record cpMat2x2
        a: cpFloat
        b: cpFloat
        c: cpFloat
        d: cpFloat
    end

    record cpBB
        l: cpFloat
        b: cpFloat
        r: cpFloat
        t: cpFloat
    end

    type cpDataPointer = any

    record cpBody
        --cpBodyVelocityFunc velocity_func;
        --cpBodyPositionFunc position_func;
        m: cpFloat
        m_inv: cpFloat
        i: cpFloat
        i_: cpFloat
        p: cpVect
        v: cpVect
        f: cpVect
        a: cpFloat
        w: cpFloat
        t: cpFloat
        r: cpVect
        data: cpDataPointer
        v_limit: cpFloat
        w_limit: cpFloat
        --v_bias_private: cpVect
        --cpFloat w_bias_private;
        --cpSpace *space_private;
        --cpShape *shapeList_private;
        --cpArbiter *arbiterList_private;
        --cpConstraint *constraintList_private;
        --cpComponentNode node_private;
    end

end

return Chipmunk
