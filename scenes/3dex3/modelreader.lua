local function makeMeshVertex(face, vdata, tdata, ndata)
    local num = tonumber
    local p = {}
    if #face > 1 then
        local vn = num(face[1] or 1)
        local tn = num(face[2] or 1)
        local nn = num(face[3] or 1)
        --print(vn, vdata[vn], tdata[vn], ndata[vn])

        local vert = vdata[vn]
        local tex  = tdata[tn]
        local norm = ndata[nn]
        
        if not vert then
            return {0, 0, 0, 0, 0}
        end
        
        p[1] = vert[1]        -- coords
        p[2] = vert[2]
        p[3] = vert[3]
        
        if tex then           -- texture coords
            p[4] = tex[1] or 0
            p[5] = tex[2] and (1 - tex[2]) or 0 -- y can be flipped
        end
        
        if norm then
            p[6] = norm and norm[1] or 1 -- normal coords
            p[7] = norm[2] or 1
            p[8] = norm[3] or 1
        end
    else
        p = vdata[num(vert)]
    end
    return p
end

local function readMaterialsFromFile(root, path)
    local split = strsplit
    local materials = {}
    
    local current = {}
    
    for line in love.filesystem.lines(root .. path) do
        local data = split(line)
        local mode = table.remove(data, 1)
        
        if mode == "newmtl" then
            local name = data[1]
            current = {}
            materials[name] = current
        end
        
        if   mode == "Ns" or mode == "Ka" 
          or mode == "Kd" or mode == "Ks"
          or mode == "Ni" or mode == "d"
          or mode == "illum" then
            current[mode] = data
        end
        
        if mode == "map_Kd" or mode == "map_d" then
            current[mode] = root .. data[1]:gsub("\\", "/")
        end
        
    end
    
    return materials
end

local function readModelFromFile(path)
    path = path:gsub("\\", "/")
    local root   = path:match("(.*/)") or ""
    
    local split  = strsplit
    local vertex = makeMeshVertex
    
    local models = {}
    local materials = {}
    
    
    local vdata = {}
    local tdata = {}
    local ndata = {}
    local gdata = {}
    local current = {fdata = {}}
    
    table.insert(models, current)
    
    for line in love.filesystem.lines(path) do
        local data = split(line, " ")
        local mode = table.remove(data, 1)

        if mode == "o" then -- new object
            if #current.fdata > 0 then
                table.insert(models, current)
            end
            print("new", data[1])
            current = {name  = data[1], fdata = {}}
            fdata = current.fdata
        end
        
        if mode == "mtllib" then
            materials = readMaterialsFromFile(root, data[1])
        end
        
        if mode == "usemtl" then
            current.material = data[1]
        end
        
        local out = mode == "v"  and vdata
                 or mode == "vt" and tdata
                 or mode == "vn" and ndata
                 or mode == "f"  and current.fdata
                 or mode == "g"  and gdata
        if out then
            table.insert(out, data)
        end
    end
    
    for i = #models, 1, -1 do
        local v = models[i]
        if #v.fdata == 0 then
            table.remove(models, i)
        end
    end
    
    for i, v in ipairs(vdata) do -- remove 4-component stuff
        for j = 4, #v do v[j] = nil end
    end
    
    for i, v in ipairs(tdata) do
        if not v[2] then v[2] = 0 end
        for j = 3, #v do v[j] = nil end
    end
    
    for _, model in ipairs(models) do
        --print("Check obj", render(model))
        model.material = materials[model.material]
        model.texture  = model.material and (model.material.map_Kd or model.material.map_d)
        
        local o = {}
        
        for i, face in ipairs(model.fdata) do
            if #face == 3 then     -- model is triangulate
                local p1 = split(face[1], "/")
                local p2 = split(face[2], "/")
                local p3 = split(face[3], "/")
                o[#o + 1] = vertex(p1, vdata, tdata, ndata)
                o[#o + 1] = vertex(p2, vdata, tdata, ndata)
                o[#o + 1] = vertex(p3, vdata, tdata, ndata)
            elseif #face == 4 then -- model is not triangulate
                local p1 = split(face[1], "/")
                local p2 = split(face[2], "/")
                local p3 = split(face[3], "/")
                local p4 = split(face[4], "/")
                p1 = vertex(p1, vdata, tdata, ndata)
                p2 = vertex(p2, vdata, tdata, ndata)
                p3 = vertex(p3, vdata, tdata, ndata)
                p4 = vertex(p4, vdata, tdata, ndata)
                
                o[#o + 1] = p1
                o[#o + 1] = p2
                o[#o + 1] = p3
                o[#o + 1] = p3
                o[#o + 1] = p4
                o[#o + 1] = p1
            end
        end
        
        model.vertices = o
    end
    
    return models
end

return {
    readModelFromFile = readModelFromFile,
}
