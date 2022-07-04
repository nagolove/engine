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

#include "SDL_mutex.h"
#include "lua_tools.h"

#include <SDL_thread.h>

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

/*
    SDL_DestroyMutex(mutex);
    SDL_LockMutex(mutex);
    SDL_UnlockMutex(mutex);
    cond = SDL_CreateCond();
    SDL_DestroyCond(cond);
    SDL_CondSignal(cond);
    SDL_CondBroadcast(cond);

bool Conditional::wait(thread::Mutex *_mutex, int timeout)
{
    // Yes, I realise this can be dangerous,
    // however, you're asking for it if you're
    // mixing thread implementations.
    Mutex *mutex = (Mutex *) _mutex;
    if (timeout < 0)
        return !SDL_CondWait(cond, mutex->mutex);
    else
        return (SDL_CondWaitTimeout(cond, mutex->mutex, timeout) == 0);
}

*/

#define MAX_NAME_LEN 32
#define MAX_CHANNELS_NUM 64

/*
Сколько создавать мютексов и условных переменных?
На каждый канал - свой экземппляр?
*/
typedef struct {
    SDL_mutex *mut;
    SDL_cond *cond;
    double *data;
    int received, sent, maxsent;
    char name[MAX_NAME_LEN];
    int reg_index;
} Channel;

int channels_num;
Channel *channels[MAX_CHANNELS_NUM] = {0, };
SDL_mutex *channels_mut = NULL;

Channel *find(const char *name) {
    for(int i = 0; i < channels_num; i++) {
        if (!strcmp(name, channels[i]->name)) {
            return channels[i];
        }
    }
    return NULL;
}

void init(lua_State *lua, const char *chan_name) {
    Channel *chan = lua_newuserdata(lua, sizeof(Channel));
    memset(chan, 0, sizeof(Channel));

    luaL_getmetatable(lua, "_Channel");
    // [.., {ud}, {M}]
    lua_setmetatable(lua, -2);
    // [... {ud}]

    lua_pushvalue(lua, -1);
    // [... {ud}, {ud}]
    chan->reg_index = luaL_ref(lua, LUA_REGISTRYINDEX);
    // [... {ud}]

    chan->mut = SDL_CreateMutex();
    chan->cond = SDL_CreateCond();

    const int data_size = 2048;
    chan->maxsent = data_size;
    chan->data = calloc(data_size, sizeof(double));
    chan->sent = 0;
    chan->received = 0;
}

static int new(lua_State *lua) {
    const char *chan_name = luaL_checkstring(lua, 1);

    if (strlen(chan_name) >= MAX_NAME_LEN) {
        char buf[64] = {0, };
        sprintf(
                buf, 
                "Channel name too long. %d >= %d\n", 
                (int)strlen(chan_name),
                MAX_NAME_LEN
               );
        lua_pushstring(lua, buf);
        lua_error(lua);
    }

    Channel *chan = find(chan_name);
    if (chan) {
        lua_rawgeti(lua, LUA_REGISTRYINDEX, chan->reg_index);
        // [.., {ud}]
    } else {
        init(lua, chan_name);
    }

    return 1;
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
    Channel *chan = (Channel*)luaL_checkudata(lua, 1, "_Channel");
    double value = luaL_checknumber(lua, 2);

    return 0;
}

static int channel_pop(lua_State *lua) {
    return 0;
}

static int channel_finalize(lua_State *lua) {
    Channel *chan = (Channel*)luaL_checkudata(lua, 1, "_Channel");
    for(int i = 0; i < channels_num; ++i) {
        if (channels[i] == chan) {
            int k = i;
            for(int j = i + 1; j < channels_num; j++) {
                channels[k++] = channels[j];
            }
        }
    }
    luaL_unref(lua, LUA_REGISTRYINDEX, chan->reg_index);
    SDL_UnlockMutex(chan->mut);
    SDL_DestroyMutex(chan->mut);
    SDL_DestroyCond(chan->cond);
    free(chan->data);
    return 0;
}

static const struct luaL_Reg Channel_methods[] =
{
    // {{{
    {"push", channel_push},
    {"pop", channel_pop},
    {"__gc", channel_finalize},
    {NULL, NULL},
    // }}}
};

extern int luaopen_messenger(lua_State *lua) {
    register_methods(lua, "_Channel", Channel_methods);
    printf("messenger2 module was opened [%s]\n", stack_dump(lua));
    channels_num = 0;
    channels_mut = SDL_CreateMutex();
    return register_module(lua);
}

