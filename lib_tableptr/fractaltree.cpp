#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include <stdlib.h>

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

int table_ptr(lua_State *lua) {
    // return 0; XXX ???
    return 1;
}

/*static const struct luaL_reg map_lib[] = {*/
static const struct luaL_Reg tableptr_lib[] = {
    {"table_ptr", table_ptr},
	{ NULL, NULL }
};

extern "C" int luaopen_tableptr(lua_State *L)
{
    luaL_register(L, "tableptr", tableptr_lib);

	return 1;
}
