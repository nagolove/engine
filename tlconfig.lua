return {
    include_dir = {
        "scenes/automato/",

        --"scenes/nback2/",
        --"scenes/nback2/libs/",

        "scenes/hexfield/",
        "scenes/slog-example/",
        "scenes/imgui-bindings/",
    },
    --source = {
    include = {
        --"*.tl",
        "scenes/automato/*.tl",
        "scenes/empty/*.tl",

        --"scenes/nback2/*.tl",
        "scenes/imgui-bindings/*.tl",
        
        "scenes/hst_reader/*.tl",
        "scenes/hexfield/*.tl",
        "scenes/slog-example/*.tl",
        "scenes/code_shader/*.tl"
        --"../../*.tl",
    },
    exclude = {
        "*tabular.tl",
        --"scenes/automato/simulator.tl",
        --"scenes/automato/cell-actions.tl",
        --"scenes/automato/simulator-thread.tl",
        --"tools.tl",
        --"scenes/automato/*.tl",
        --"scenes/nback2/*.tl",
        "scenes/hst_reader/*.tl",
        "main.tl",
        "crash*.tl",
    }
}
