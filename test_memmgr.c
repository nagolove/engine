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

#include <SDL_mutex.h>
#include <SDL_stdinc.h>
#include <SDL_thread.h>
#include <SDL_timer.h>

#include "lua_tools.h"

#include <stdatomic.h>

#ifdef DEBUG
// {{{

#define LOG(...)        \
    printf(__VA_ARGS__);\

#else

#define LOG(...) \
    do {} while(0);

// }}}
#endif // DEBUG
       
#define MAX_NAME_LEN 32     // Максимальная длина имени канала
#define MAX_CHANNELS_NUM 64
#define MAX_STR_LEN 32      // Максимальная длина строкового сообщения
#define QUEUE_SIZE 4096

#define TYPE_NUMBER     1
#define TYPE_STRING     2
#define TYPE_LSTRING    3

/*
Сколько создавать мютексов и условных переменных?
На каждый канал - свой экземппляр?
*/
typedef struct {
} Channel;

typedef struct {
    int channels_num;
    Channel *channels[MAX_CHANNELS_NUM];
} State;

typedef double ID;

State *state = NULL;

void check_argsnum(lua_State *lua, int num) {
    // {{{
    static char formated_msg[64] = {0, };
    const char *msg = "Function should receive only %d argument(s).\n";
    snprintf(formated_msg, sizeof(formated_msg), msg, num);

    int top = lua_gettop(lua);
    if (top != num) {
        lua_pushstring(lua, formated_msg);
        lua_error(lua);
    }
    // }}}
}

void channel_init(Channel *chan) {
}

Channel *channel_allocate(lua_State *lua) {
    assert(state && "state == NULL");
    Channel *chan = calloc(1, sizeof(Channel));
    return chan;
}

static int init_messenger(lua_State *lua) {
    // Имеет-ли здесь мьютекс какой-нибудь смысл?
    SDL_mutex *mut = SDL_CreateMutex();
    SDL_LockMutex(mut);
    if (lua_islightuserdata(lua, 1)) {
        state = lua_touserdata(lua, 1);
        printf("init_messenger: state was reseted\n");
        return 0;
    } else {
        state = calloc(1, sizeof(State));
        state->channels_num = 0;
        lua_pushlightuserdata(lua, state);
        return 1;
    }
    SDL_UnlockMutex(mut);
}

void channel_error(lua_State *lua, char *name, char *msg) {
    char buf[64] = {0, };
    sprintf(buf, "Channel '%s': %s\n", name, msg);
    lua_pushstring(lua, buf);
    lua_error(lua);
}

static int state_from_string(lua_State *lua) {
    LOG("state_from_string: [%s]\n", stack_dump(lua));
    const char *state_addr = luaL_checkstring(lua, 1);
    LOG("state_addr = %s\n", state_addr);
    State *tmp_state = (void*)strtouq(state_addr, NULL, 16);
    lua_pushlightuserdata(lua, tmp_state);
    return 1;
}

static int string_from_state(lua_State *lua) {
    LOG("string_from_state: [%s]\n", stack_dump(lua));
    Channel *chan = (Channel*)lua_touserdata(lua, 1);
    char buf[32] = {0, };
    sprintf(buf, "%p", chan);
    LOG("ptr = %s\n", buf);
    lua_pushstring(lua, buf);
    return 1;
}

static int free_messenger(lua_State *lua) {
    if (state) {
        for(int i = 0; state->channels_num; i++) {
            /*Channel *ch = state->channels[i];*/
            free(state->channels[i]);
        }
        free(state);
    }
    return 0;
}

int register_module(lua_State *lua) {
    static const struct luaL_Reg functions[] =
    {
        // {{{
        {"init_messenger", init_messenger},
        {"free_messenger", free_messenger},

        {"string_from_state", string_from_state},
        {"state_from_string", state_from_string},

        // DEBUGGING STUFF
        {NULL, NULL}
        // }}}
    };

    luaL_register(lua, "messenger", functions);

    // {{{ Добавление справочных констант.

    lua_pushstring(lua, "MAX_STR_LEN");
    lua_pushnumber(lua, MAX_STR_LEN);
    lua_settable(lua, -3);

    lua_pushstring(lua, "QUEUE_SIZE");
    lua_pushnumber(lua, QUEUE_SIZE);
    lua_settable(lua, -3);

    lua_pushstring(lua, "MAX_NAME_LEN");
    lua_pushnumber(lua, MAX_NAME_LEN);
    lua_settable(lua, -3);

    lua_pushstring(lua, "MAX_CHANNELS_NUM");
    lua_pushnumber(lua, MAX_CHANNELS_NUM);
    lua_settable(lua, -3);
    // }}}

    return 1; // что возвращает?
}

extern int luaopen_test_memmgr(lua_State *lua) {
    LOG("test_memmgr module was opened [%s]\n", stack_dump(lua));
    LOG("lua = %p\n", lua);
    state = NULL;

    /*atomic_int bugaga = 0;*/
    /*printf("%d\n", bugaga);*/

    return register_module(lua);
}
