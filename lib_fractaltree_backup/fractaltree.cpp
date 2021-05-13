#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include <stdlib.h>

int map_create(lua_State *lua);
int map_slice(lua_State *lua);

/*
int main(int argc, char **argv){
	lua_State *lua = lua_open();
	luaL_openlibs(lua);

	static const struct luaL_reg map_lib[] = {
		{"create", map_create},
		{"slice", map_slice},
		{NULL, NULL}};

	luaL_openlib(lua, "Map", map_lib, 0);

	luaL_dostring(lua, "map = Map.create(256, 256)");
	luaL_dostring(lua, "s = Map.slice(map, 256, 0, 0, 5, 5)");
	luaL_dostring(lua, "for i=0,4 do print(table.concat(s,' ',5*i, 5*i+4)) end");

	return 0;
}
*/

int map_create(lua_State *lua){
	int w = luaL_checkinteger(lua, 1);
	int h = luaL_checkinteger(lua, 2);

	unsigned char *map = (unsigned char*)malloc(w * h);

	int n;
	for(n = 0; n != w * h; n++){
		map[n] = n % 10;
	}

	lua_pushlightuserdata(lua, map);
	return 1;
}

int map_slice(lua_State *lua) {
	unsigned char *map = (unsigned char*)lua_touserdata(lua, 1);
	int map_width = luaL_checkinteger(lua, 2);
	int x = luaL_checkinteger(lua, 3); int y = luaL_checkinteger(lua, 4);
	int w = luaL_checkinteger(lua, 5); int h = luaL_checkinteger(lua, 6);

	lua_newtable(lua);

	int cx, cy;
	for(cy = 0; cy != h; cy++)
		for(cx = 0; cx != w; cx++){
			lua_pushnumber(lua, cx + w * cy);
			lua_pushnumber(lua, map[x + cx + (y + cy) * map_width]);
			lua_settable(lua, -3);
		}

	return 1;
}

int fractaltree_new(lua_State *lua) {
    return 1; // return 0; XXX ???
}

int fractaltree_setSheetCount(lua_State *lua) {
    return 1;
}

int fractaltree_draw(lua_State *lua) {
    return 1;
}

/*static const struct luaL_reg map_lib[] = {*/
static const struct luaL_Reg fractaltree[] = {
    //{"create", map_create},
    //{"slice", map_slice},
    {"new", fractaltree_new},
    {"setSheetCount", fractaltree_setSheetCount},
    {"draw", fractaltree_draw},
	{ NULL, NULL }
};

/*
    Fractal API.
    ```lua
    local tree = require "fractaltree".new(maxmemusage)
    love.draw = function()
        tree:draw()
    end

    local count = 100

    love.load = function()
        -- инициализация
        tree:setSheetCount(count)
    end

    love.update = function()
        if love.keyboard.isDown("q") then
            count = count - 100
        elseif love.keyboard.isDown("e") then
            count = count + 100
        end
        tree:setSheetCount(count)
    end
    ```
 *
 */

extern "C" int luaopen_fractaltree(lua_State *L)
{
    //printf("luaopen_imgui\n");
	/*lua_newtable(L);*/
	/*lua_pushvalue(L, -1);*/
	/*lua_setglobal(L, "imgui");*/
    /*wrap_imgui::addImguiWrappers(L);*/
    /*luaL_register(L, nullptr, imguilib);*/
    //luaL_openlib(lua, "Map", map_lib, 0);

    //lua_newtable(L);
	//lua_pushvalue(L, -1);
	//lua_setglobal(L, "imgui");
    //wrap_imgui::addImguiWrappers(L);
    //luaL_register(L, nullptr, fractaltree);

    //luaL_register(L, nullptr, fractaltree);

	return 1;
}
