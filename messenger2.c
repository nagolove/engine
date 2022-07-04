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
#include "SDL_stdinc.h"
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
#define MAX_STR_LEN 32
#define QUEUE_SIZE 4096
#define INDEX_THRESHOLD 4096

/*
Сколько создавать мютексов и условных переменных?
На каждый канал - свой экземппляр?
*/
typedef struct {
    SDL_mutex *mut;
    SDL_cond *cond;

    uint32_t *queue;

    double *number_data;        // 1
    char *short_string_data;    // 2
    /*char *string_data;*/
    int number_count;
    int short_string_count;

    int received, sent, maxsent;
    char name[MAX_NAME_LEN];
    /*int reg_index;*/
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

Channel *channel_new(lua_State *lua, const char *chan_name) {
    assert(state && "state == NULL");
    LOG("channel_new:\n")
    Channel *chan = calloc(1, sizeof(Channel));

    const int data_size = 2048;

    chan->mut = SDL_CreateMutex();
    chan->cond = SDL_CreateCond();
    chan->maxsent = data_size;

    chan->queue = calloc(QUEUE_SIZE, sizeof(uint32_t));
    chan->number_data = calloc(QUEUE_SIZE, sizeof(double));
    chan->short_string_data = calloc(
            QUEUE_SIZE, (MAX_STR_LEN + 1) * sizeof(char)
    );

    chan->sent = 0;
    chan->received = 0;
    strcpy(chan->name, chan_name);

    state->channels[state->channels_num++] = chan;

    LOG("channel_new [%s]\n", stack_dump(lua));
    return chan;
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
    if (!chan) {
        chan = channel_new(lua, chan_name);
    }

    lua_pushlightuserdata(lua, chan);

    SDL_UnlockMutex(state->channels_mut);
    LOG("new [%s]\n", stack_dump(lua));
    return 1;
}

// XXX free() для state отсутствует
static int init(lua_State *lua) {
    // Имеет-ли здесб мьютекс какой-нибудь смысл?
    SDL_mutex *mut = SDL_CreateMutex();
    SDL_LockMutex(mut);
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
    SDL_UnlockMutex(mut);
}

void channel_full_error(lua_State *lua, char *name, int maxsent) {
    char buf[64] = {0, };
    sprintf(buf, "Channel '%s' in full. Maxsize = %d\n", name, maxsent);
    lua_pushstring(lua, buf);
    lua_error(lua);
}

static int channel_push(lua_State *lua) {
    LOG("channel_push:\n");
    Channel *chan = (Channel*)lua_touserdata(lua, 1);

    if (lua_isnumber(lua, 2)) {
        double value = lua_tonumber(lua, 2);
        SDL_LockMutex(chan->mut);

        // Правильность + 1 в условии
        if (chan->sent + 1 == chan->maxsent) {
            channel_full_error(lua, chan->name, chan->maxsent);
        }

        LOG("channel name %s\n", chan->name);
        LOG("pushing %f\n", value);
        LOG("sent %d\n", chan->sent);
        LOG("channels_num %d\n", state->channels_num);

        /*chan->data[chan->sent++] = value;*/
        chan->queue[chan->sent++] = value;
        SDL_CondBroadcast(chan->cond);

        SDL_UnlockMutex(chan->mut);
    } else if (lua_isstring(lua, 2)) {
    } else {
        char buf[128] = {0, };
        const char *tname = lua_typename(lua, lua_type(lua, 2));
        sprintf(buf, "%s type is not allowed", tname);
        lua_pushstring(lua, buf);
        lua_error(lua);
    }

    return 0;
}

static int channel_pop(lua_State *lua) {
    assert(state && "state == NULL");
    Channel *chan = (Channel*)lua_touserdata(lua, 1);

    LOG("----------------------------\n");
    LOG("channel_pop:\n");
    LOG("channel name %s\n", chan->name);
    LOG("channels_num %d\n", state->channels_num);

    SDL_LockMutex(chan->mut);

    LOG("sent %d\n", chan->sent);

    if (chan->sent == -1) {
        LOG("preemptive pushing nil\n");
        lua_pushnil(lua);
        SDL_CondBroadcast(chan->cond);
        SDL_UnlockMutex(chan->mut);
        return 1;
    }

    /*double value = chan->data[chan->sent--]; // Верно-ли работает?*/
    /*LOG("value %f\n", value);*/
    /*lua_pushnumber(lua, value);*/

    SDL_CondBroadcast(chan->cond);

    SDL_UnlockMutex(chan->mut);
    LOG("channel_pop: [%s]\n", stack_dump(lua));
    LOG("----------------------------\n");
    return 1;
}

static int channel_finalize(lua_State *lua) {
    assert(state);
    Channel *chan = (Channel*)lua_touserdata(lua, 1);

    LOG("channel '%s' finalizatioin\n", chan->name);

    SDL_LockMutex(state->channels_mut);

    bool found = false;
    for(int i = 0; i < state->channels_num; ++i) {
        if (state->channels[i] == chan) {
            found = true;
            break;
        }
    }

    if (found) {
        SDL_UnlockMutex(chan->mut);
        SDL_DestroyMutex(chan->mut);
        SDL_DestroyCond(chan->cond);
        /*free(chan->data);*/

        for(int i = 0; i < state->channels_num; ++i) {
            if (state->channels[i] == chan) {
                int k = i;
                for(int j = i + 1; j < state->channels_num; j++) {
                    state->channels[k++] = state->channels[j];
                }
            }
        }
    }

    SDL_UnlockMutex(state->channels_mut);

    return 0;
}

int register_module(lua_State *lua) {
    static const struct luaL_Reg functions[] =
    {
        // {{{
        {"new", new},
        {"init", init},
        {"push", channel_push},
        {"pop", channel_pop},
        {"free", channel_finalize},
        {NULL, NULL}
        // }}}
    };
    luaL_register(lua, "messenger", functions);
    return 1; // что возвращает?
}

extern int luaopen_messenger2(lua_State *lua) {
    LOG("messenger2 module was opened [%s]\n", stack_dump(lua));
    LOG("lua = %p\n", lua);
    state = NULL;
    return register_module(lua);
}

