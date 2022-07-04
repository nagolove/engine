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

typedef struct {
    int channels_num;
    Channel *channels[MAX_CHANNELS_NUM];
    SDL_mutex *channels_mut;
} State;

State *state = NULL;

Channel *find_channel(const char *name) {
    assert(state && "state == NULL");
    LOG("find_channel:\n");
    LOG("channels_num %d\n", state->channels_num);
    LOG("name %s\n", name);
    for(int i = 0; i < state->channels_num; i++) {
        LOG("channels[i]->name %s\n", state->channels[i]->name);
        if (!strcmp(name, state->channels[i]->name)) {
            return state->channels[i];
        }
    }
    return NULL;
}

void channel_new(lua_State *lua, const char *chan_name) {
    LOG("channel_new:\n")
    // [.., ]
    Channel *chan = lua_newuserdata(lua, sizeof(Channel));
    // [.., {ud}]
    memset(chan, 0, sizeof(Channel));

    luaL_getmetatable(lua, "_Channel");
    // [.., {ud}, {M}]
    lua_setmetatable(lua, -2);
    // [... {ud}]

    lua_pushvalue(lua, -1);
    // [... {ud}, {ud}]
    chan->reg_index = luaL_ref(lua, LUA_REGISTRYINDEX);
    LOG("chan->reg_index = %d\n", chan->reg_index);
    // [... {ud}]

    chan->mut = SDL_CreateMutex();
    chan->cond = SDL_CreateCond();

    const int data_size = 2048;
    chan->maxsent = data_size;
    chan->data = calloc(data_size, sizeof(double));
    chan->sent = 0;
    chan->received = 0;
    strcpy(chan->name, chan_name);
    assert(state && "state == NULL");
    state->channels[state->channels_num++] = chan;

    LOG("channel_new [%s]\n", stack_dump(lua));
}

static int new(lua_State *lua) {
    assert(state);
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

    // Добавить проверку на превышение количества доступных каналов.

    SDL_LockMutex(state->channels_mut);

    Channel *chan = find_channel(chan_name);
    if (chan) {
        LOG("chan->reg_index = %d\n", chan->reg_index);
        lua_rawgeti(lua, LUA_REGISTRYINDEX, chan->reg_index);
        // [.., {ud}]
    } else {
        channel_new(lua, chan_name);
    }

    SDL_UnlockMutex(state->channels_mut);
    LOG("new [%s]\n", stack_dump(lua));
    return 1;
}

// XXX free() для state отсутствует
static int init(lua_State *lua) {
    // Закрывать мютекс?
    
    if (lua_islightuserdata(lua, 1)) {
        state = lua_touserdata(lua, 1);
        return 0;
    } else {
        state = calloc(1, sizeof(State));
        state->channels_mut = SDL_CreateMutex();
        state->channels_num = 0;
        lua_pushlightuserdata(lua, state);
        return 1;
    }
}

int register_module(lua_State *lua) {
    static const struct luaL_Reg functions[] =
    {
        // {{{
        {"new", new},
        {"init", init},
        {NULL, NULL}
        // }}}
    };
    luaL_register(lua, "messenger", functions);
    return 1; // что возвращает?
}

static int channel_push(lua_State *lua) {
    LOG("channel_push:\n");
    Channel *chan = (Channel*)luaL_checkudata(lua, 1, "_Channel");
    double value = luaL_checknumber(lua, 2);
    SDL_LockMutex(chan->mut);

    if (chan->sent + 1 >= chan->maxsent) {
        char buf[64] = {0, };
        sprintf(
                buf, 
                "Channel '%s' in full. Maxsize = %d\n", 
                chan->name,
                chan->maxsent
               );
        lua_pushstring(lua, buf);
        lua_error(lua);
    }

    LOG("channel name %s\n", chan->name);
    LOG("pushing %f\n", value);
    LOG("sent %d\n", chan->sent);
    LOG("channels_num %d\n", state->channels_num);

    chan->data[chan->sent++] = value;
    SDL_CondBroadcast(chan->cond);

    SDL_UnlockMutex(chan->mut);
    return 0;
}

static int channel_pop(lua_State *lua) {
    assert(state && "state == NULL");
    Channel *chan = (Channel*)luaL_checkudata(lua, 1, "_Channel");

    LOG("----------------------------\n");
    LOG("channel_pop:\n");
    LOG("channel name %s\n", chan->name);
    LOG("channels_num %d\n", state->channels_num);

    SDL_LockMutex(chan->mut);

    LOG("sent %d\n", chan->sent);

    if (chan->sent - 1 < 0) {
        LOG("preemptive pushing nil\n");
        lua_pushnil(lua);
        SDL_UnlockMutex(chan->mut);
        return 1;
    }

    double value = chan->data[chan->sent--]; // Верно-ли работает?
    LOG("value %f\n", value);
    lua_pushvalue(lua, value);

    SDL_CondBroadcast(chan->cond);

    SDL_UnlockMutex(chan->mut);
    LOG("----------------------------\n");
    return 1;
}

static int channel_finalize(lua_State *lua) {
    assert(state);
    Channel *chan = (Channel*)luaL_checkudata(lua, 1, "_Channel");

    LOG("channel '%s' finalizatioin\n", chan->name);

    for(int i = 0; i < state->channels_num; ++i) {
        if (state->channels[i] == chan) {
            int k = i;
            for(int j = i + 1; j < state->channels_num; j++) {
                state->channels[k++] = state->channels[j];
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

extern int luaopen_messenger2(lua_State *lua) {
    register_methods(lua, "_Channel", Channel_methods);
    LOG("messenger2 module was opened [%s]\n", stack_dump(lua));
    LOG("lua = %p\n", lua);
    state = NULL;
    return register_module(lua);
}

