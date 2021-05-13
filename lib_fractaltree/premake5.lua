workspace "crc"
    architecture "x64"
    configurations {
        "Debug",
        "Release"
    }

project "crc32"
    --kind "StaticLib"
    kind "SharedLib"
    --targetname "crc32"
    postbuildcommands { "mv libcrc32.so crc32.so" }
    targetdir "."
    language "C++"
    includedirs {
        "/usr/include/luajit-2.1",
    }
    links {
        "luajit-5.1",
    }
    files {
        "*.c"
    }

--[[
   [project "love"
   [    kind "ConsoleApp" language "C++"
   [    
   [    defines {
   [        --"LOVE_ENABLE_LUA53=0"
   [    }
   [    --configuration "Debug"
   [        --targetdir "bin/debug"
   [
   [    --configuration "Release"
   [        --targetdir "bin/release"
   [
   [    includedirs {
   [        "/usr/include/SDL2",
   [        "/usr/include/freetype2",
   [        "src",
   [        "src/libraries",
   [        "src/libraries/LuaJIT/src",
   [        "src/libraries/enet_2/include",
   [        "src/libraries/stb",
   [        "src/libraries/tinyexr",
   [        "src/libraries/utf8",
   [        "src/modules",
   [    }
   [    links {
   [        "stdc++",
   [        "SDL2", "box2d", "ddsparse", "enet", "freetype", "glad", "glslang",
   [        "lodepng", "lua53libs", "luajit", "luasocket", "lz4", "m", "modplug",
   [        "mpg123", "noise1234", "ogg", "openal", "physfs", "pthread", "theora",
   [        "theoradec", "theoraenc", "vorbis", "vorbisenc", "vorbisfile", "wuff",
   [        "xxhash", "z",
   [        --"/usr/lib/x86_64-linux-gnu/libluajit-5.1.so"
   [    }
   [    libdirs {
   [        "src/libraries/LuaJIT/src"
   [        --"/usr/lib/x86_64-linux-gnu"
   [    }
   [    files {
   [        "src/common/**.h",
   [        "src/love.cpp",
   [        --"**.hpp",
   [        --"*.c",
   [        --"*.cpp",
   [        "src/common/**.cpp",
   [        "src/modules/**.cpp",
   [        "src/modules/**.h",
   [    }
   ]]

print(os.findlib("luajit"))

