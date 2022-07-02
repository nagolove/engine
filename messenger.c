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

int register_module(lua_State *lua) {
    static const struct luaL_Reg functions[] =
    {
        // {{{
        {"new", diamond_and_square_new},
        {NULL, NULL}
        // }}}
    };
    luaL_register(lua, "messenger", functions);
    return 1; // что возвращает?
}

static int diamond_and_square_get_as_string(lua_State *lua) {
    return 0;
}

static const struct luaL_Reg DiamondSquare_methods[] =
{
    // {{{
    {"internal_free", diamond_and_square_internal_free},
    {"eval", diamond_and_square_eval},

    // Возращащает значение ячейки по индексу
    {"get", diamond_and_square_get},
    // Возвращает размер карты
    {"get_mapsize", diamond_and_square_get_mapsize},
    // Возвращает карту в виде строчки
    {"get_as_string", diamond_and_square_get_as_string},

    {NULL, NULL}
    // }}}
};

extern int luaopen_diamond_and_square(lua_State *lua) {
    register_methods(lua, "_DiamondSquare", DiamondSquare_methods);
    printf("diamond&square module was opened [%s]\n", stack_dump(lua));
    srand(time(NULL));
    return register_module(lua);
}

