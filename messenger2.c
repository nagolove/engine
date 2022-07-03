// vim: set colorcolumn=85
// vim: fdm=marker

// {{{ Includes
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>
#include <stdlib.h>
#include <time.h>

#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
// }}} 

#include "lua_tools.h"

#include <sys/mman.h>

#ifdef DEBUG
// {{{

#define LOG(...)        \
    printf(__VA_ARGS__);\

#else

#define LOG(...) \
    do {} while(0);

// }}}
#endif // DEBUG
      
       
void check_argsnum(lua_State *lua, int num) {
    static char formated_msg[64] = {0, };
    const char *msg = "Function should receive only %d argument(s).\n";
    snprintf(formated_msg, sizeof(formated_msg), msg, num);

    int top = lua_gettop(lua);
    if (top != num) {
        lua_pushstring(lua, formated_msg);
        lua_error(lua);
    }
}

static int new(lua_State *lua) {
    return 0;
}

int register_module(lua_State *lua) {
    static const struct luaL_Reg functions[] =
    {
        // {{{
        {"new", new},
        {NULL, NULL}
        // }}}
    };
    luaL_register(lua, "messenger", functions);
    return 1; // что возвращает?
}

static int channel_push(lua_State *lua) {
    return 0;
}

static int channel_pop(lua_State *lua) {
    return 0;
}

static const struct luaL_Reg Channel_methods[] =
{
    // {{{
    {"push", channel_push},
    {"pop", channel_pop},
    {NULL, NULL},
    // }}}
};

extern int luaopen_messenger(lua_State *lua) {
    register_methods(lua, "_Channel", Channel_methods);
    printf("messenger2 module was opened [%s]\n", stack_dump(lua));
    return register_module(lua);
}

