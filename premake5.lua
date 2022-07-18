workspace "xcaustic"
    configurations { "Debug", "Release" }

    includedirs { 
        "/usr/include/luajit-2.1",
        --"~/projects/Chipmunk2D/include"
        "/home/nagolove/projects/Chipmunk2D/include",
        "/home/nagolove/myprojects/lua_capi",
    }
    buildoptions { 
        "-ggdb3",
        "-fPIC",
        "-Wall",
        "-Werror",
        "-Wno-strict-aliasing",
        --"-Wno-unused-function",
    }
    links { 
        --"luajit-5.1", 
        "lua5.1",
        "chipmunk",
        "mem_guard",
        "lua_tools",
    }
    libdirs { 
        "/home/nagolove/projects/Chipmunk2D/src/",
        "/home/nagolove/myprojects/c_guard",
        "/home/nagolove/myprojects/lua_capi",
    }
    language "C"
    kind "SharedLib"
    --targetdir "bin/%{cfg.buildcfg}"
    --targetdir "bin/%{cfg.buildcfg}"
    targetprefix ""
    targetdir "."

    -- Генератор ландшафта
    project "diamond_and_square"
        files { "**.h", "diamond_and_square.c" }

    -- Библиотека для замены love.thread.Channel
    -- Стек вместо очереди
    project "messenger"
        files { "**.h", "messenger.c" }
        
    -- Библиотека для замены love.thread.Channel
    -- На циклическом списке
    project "messenger2"
        files { "**.h", "messenger2.c" }
        includedirs { "/usr/include/SDL2" }
        links { "pthread", "SDL2" }
        buildoptions { "-D_REENTRANT" }

    -- Библиотека для замены love.thread.Channel
    -- Очередь на списке. Заброшено
    project "messenger3"
        files { "**.h", "messenger3.c" }
        includedirs { "/usr/include/SDL2" }
        links { "pthread", "SDL2" }
        buildoptions { "-D_REENTRANT" }

    -- Библиотека для проверки корректности работы менеджера памяти при
    -- разделении состояния на несколько потоков.
    project ""
        files { "**.h", "test_memmgr.c" }
        includedirs { "/usr/include/SDL2" }
        links { "pthread", "SDL2" }
        buildoptions { "-D_REENTRANT" }


    filter "configurations:Debug"
    defines { "DEBUG" }
    symbols "On"

    filter "configurations:Release"
    defines { "NDEBUG" }
    optimize "On"
