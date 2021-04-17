local file = io.popen("uname -a")
local is_linux = false
if file then
    if file:read("*a"):match("Linux.*") then
        is_linux = true
    end
end

<<<<<<< HEAD
function getAutomatoFiles()
    local files = {
        "asm.tl",           -- движок ассемблера для клеток
        "cell-actions.tl",  -- обработка команд клетки
        "cell.tl",          -- класс клетки
        "ex.tl",            -- экспериментальная функциональность
        "graph-render.tl",      -- рисование 3д-графиков
        "graphics-render.tl",   -- рисование 2д-анимации
        "init.tl",              -- заглавная сцена загрузки 
        "simulator-render.tl",  -- 
        "simulator-thread.tl", 
        "simulator.tl", 
        "types.tl", 
    }
    for k, v in pairs(files) do
        --files[k] = "scenes/automato/" .. v
        files[k] = "scenes\\automato\\" .. v
    end
    return files
=======
local files = {
    "asm.tl", 
    "cell-actions.tl", 
    "cell.tl", 
    "ex.tl", 
    "graph-render.tl", 
    "graphics-render.tl", 
    "init.tl", 
    "mtschemes.d.tl", 
    "simulator-render.tl", 
    "simulator-thread.tl", 
    "simulator.tl", 
    "types.tl", 
}

for k, v in pairs(files) do
    --files[k] = "scenes/automato/" .. v
    --files[k] = "scenes\\automato\\" .. v
    files[k] = "scenes/automato/" .. v
>>>>>>> 58573c8d36176a2098a9bd6d90e83887f3f1e2a3
end

local files = getAutomatoFiles()

return {
    --skip_compat53 = true,
    --gen_target = "5.1",
    --global_env_def = "love",
    --source_dir = "src",
    --build_dir = "app",
    include_dir = {
        --"assets",
        "lib",
        "src",
        "include",
        "scenes/automato/",

        --"scenes/nback2/",
        --"scenes/nback2/libs/",

        "scenes/hexfield/",
        "scenes/slog-example/",
        "scenes/imgui-bindings/",
        "scenes/fractaltree/",
    },
    include = {
        --"scenes/fractaltree/*.tl",
        "scenes/automato/*.tl",
        --"scenes/empty/*.tl",
        "src/*.tl",
        "*.tl",

        --"scenes/nback2/*.tl",
        --"scenes/imgui-bindings/*.tl",
        --"scenes/hst_reader/*.tl",
        --"scenes/hexfield/*.tl",
        --"scenes/slog-example/*.tl",
        --"scenes/code_shader/*.tl",
        --"../../*.tl",
    },
    files = files,
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
