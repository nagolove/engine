-- vim: set colorcolumn=85
-- vim: fdm=marker

local file = io.popen("uname -a")
local is_windows = false
local is_linux = false
if file then
    if file:read("*a"):match("Linux.*") then
        is_linux = true
        is_window = false
    else
        is_linux = false
        is_windows = false
    end
else
    error("No file opened.")
end
print("is_linux", is_linux)
print("is_windows", is_windows)

--[[
-- Написать функцию-сборщик файлов движка.
function getAutomatoFiles()
    -- {{{
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
        if is_windows then
            --files[k] = "scenes/automato/" .. v
            files[k] = "scenes\\automato\\" .. v
        else
            files[k] = "scenes/automato/" .. v
        end
    end
    return files
    -- }}}
end
--]]

print("is_linux", is_linux)

local files = nil
if is_windows then
    --files = getAutomatoFiles()
end
--print("files", files)

return {
    --skip_compat53 = true,
    --gen_target = "5.1",
    global_env_def = "love",
    --source_dir = "src",
    --build_dir = "app",
    include_dir = {
        "ddd",
        "ddd/target/debug",
        "lib",
        "src",
        "include",

        "scenes/t80/",
        "scenes/sri/",
    },
    include = {
        "scenes/empty/*.tl",
        "scenes/empty_mt/*.tl",
        "scenes/mt_coro/*.tl",
        "scenes/chipmunk_mt/*.tl",

        "src/*.tl",
        "*.tl",

        "scenes/sri/*.tl",
        "scenes/t80/*.tl",
        'scenes/colored_text_transform_mt/*.tl',
        'scenes/textured_quad/*.tl',
        'scenes/debug_print_mt/*.tl',
        'scenes/dynlib/*.tl',
    },
    --files = files,
    exclude = {
    }
}
