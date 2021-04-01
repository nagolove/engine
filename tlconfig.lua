
function getAutomatoFiles()
    local files = {
        "asm.tl", 
        "cell-actions.tl", 
        "cell.tl", 
        "ex.tl", 
        "graph-render.tl", 
        "graphics-render.tl", 
        "init.tl", 
        "simulator-render.tl", 
        "simulator-thread.tl", 
        "simulator.tl", 
        "types.tl", 
    }
    for k, v in pairs(files) do
        --files[k] = "scenes/automato/" .. v
        files[k] = "scenes\\automato\\" .. v
    end
    return files
end

local files = getAutomatoFiles()

return {
    include_dir = {
        "scenes/automato/",

        --"scenes/nback2/",
        --"scenes/nback2/libs/",

        "scenes/hexfield/",
        "scenes/slog-example/",
        "scenes/imgui-bindings/",
        "scenes/fractaltree/",
    },
    include = {
        "scenes/fractaltree/*.tl",
        "scenes/automato/*.tl",
        "scenes/empty/*.tl",
        "*.tl",

        --"scenes/nback2/*.tl",
        --"scenes/imgui-bindings/*.tl",
        --"scenes/hst_reader/*.tl",
        --"scenes/hexfield/*.tl",
        --"scenes/slog-example/*.tl",
        --"scenes/code_shader/*.tl",
        --"../../*.tl",
    },
    --files = files,
    exclude = {
        "*tabular.tl",
        --"scenes/automato/simulator.tl",
        --"scenes/automato/cell-actions.tl",
        --"scenes/automato/simulator-thread.tl",
        --"tools.tl",
        --"scenes/automato/*.tl",
        --"scenes/nback2/*.tl",
        --"scenes/hst_reader/*.tl",
        --"main.tl",
        --"crash*.tl",
    }
}
