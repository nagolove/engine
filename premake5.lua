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

    project "diamond_and_square"
        files { "**.h", "diamond_and_square.c" }

    project "messenger"
        files { "**.h", "messenger.c" }
        
    project "messenger2"
        files { "**.h", "messenger2.c" }
        includedirs { "/usr/include/SDL2" }
        links { "pthread", "SDL2" }
        buildoptions { "-D_REENTRANT" }

    filter "configurations:Debug"
    defines { "DEBUG" }
    symbols "On"

    filter "configurations:Release"
    defines { "NDEBUG" }
    optimize "On"
