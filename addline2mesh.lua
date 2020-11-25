
return function addLine2Mesh(mesh, index, p1x, p1y, p2x, p2y)
    local v
    local dist = -8000

    v = {
        p1x, p1y,
        0, 0,
        0.5, 0.5, 0.5,
    }
    mesh:setVertex(index, v)

    v = {
        p2x, p2y,
        0, 0,
        0.5, 0.5, 0.5,
    }
    mesh:setVertex(index + 1, v)

    v = {
        p1x, p1y - dist,
        0, 0,
        0.5, 0.5, 0.5,
    }
    mesh:setVertex(index + 2, v)

    v = {
        p1x, p1y,
        0, 0,
        0.5, 0.5, 0.5,
    }
    mesh:setVertex(index + 3, v)

    v = {
        p2x, p2y,
        0, 0,
        0.5, 0.5, 0.5,
    }
    mesh:setVertex(index + 4, v)

    v = {
        p2x, p2y - dist,
        0, 0,
        0.5, 0.5, 0.5,
    }
    mesh:setVertex(index + 5, v)
end

