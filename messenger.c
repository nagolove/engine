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

typedef struct {
    int alocated_size;
    char magic[32];
    char data[100];
} Messenger;

#define MAGIC_STR "wefhwjkefh"

static int init(lua_State *lua) {
    char str_buf[32] = {0, };
    int size = 1024 * 1024; // 1mb
    void *ptr = mmap(
            NULL, size, PROT_READ | PROT_WRITE, 
            MAP_ANONYMOUS | MAP_SHARED,
            /*MAP_ANONYMOUS | MAP_SHARED | MAP_POPULATE,*/
            -1, 0
    );

    Messenger *m = ptr;
    m->alocated_size = size;
    sprintf(m->magic, "%s", MAGIC_STR);

    sprintf(str_buf, "%p", ptr);

    printf("init\n");
    printf("ptr = %s\n", str_buf);

    lua_pushlightuserdata(lua, m);
    lua_pushstring(lua, str_buf);
    return 2;
}

static Messenger *channel;

static int deinit(lua_State *lua) {
    return 0;
}

static int connect(lua_State *lua) {
    check_argsnum(lua, 1);
    luaL_checktype(lua, 1, LUA_TSTRING);
    const char *addr_str = lua_tostring(lua, 1);

    printf("connect\n");
    printf("addr_str = %s\n", addr_str);
    channel = (void*)strtouq(addr_str, NULL, 16);

    printf("channel %p\n", channel);
    // XXX
    lua_pushboolean(lua, 1);

    return 1;
}

static int pop(lua_State *lua) {
    lua_pushstring(lua, (char*)channel->data);
    return 1;
}

static int push(lua_State *lua) {
    check_argsnum(lua, 1);
    luaL_checktype(lua, 1, LUA_TSTRING);
    const char * str = lua_tostring(lua, 1);

    printf("push\n");
    printf("str = %s\n", str);
    printf("channel %p\n", channel);
    /*printf("magic = %s\n", channel->magic);*/

    /*strcpy((char*)channel->data, str);*/
    return 0;
}

static int empty(lua_State *lua) {
    return 0;
}

int register_module(lua_State *lua) {
    static const struct luaL_Reg functions[] =
    {
        // {{{
        {"init", init},
        {"deinit", deinit},
        {"connect", connect},
        {"pop", pop},
        {"push", push},
        {"empty", empty},
        {NULL, NULL}
        // }}}
    };
    luaL_register(lua, "messenger", functions);
    return 1; // что возвращает?
}

/*
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
*/

extern int luaopen_messenger(lua_State *lua) {
    /*register_methods(lua, "_DiamondSquare", DiamondSquare_methods);*/
    printf("messenger module was opened [%s]\n", stack_dump(lua));
    /*srand(time(NULL));*/
    channel = NULL;
    return register_module(lua);
}

