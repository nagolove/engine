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

#define TYPE_NUMBER 1
#define TYPE_STRING 2

/*
Сколько создавать мютексов и условных переменных?
На каждый канал - свой экземппляр?
*/
typedef struct {
    SDL_mutex *mut;
    SDL_cond *cond;

    /*
    int8_t *type_queue;
    int type_count, type_maxcount, type_i, type_j;
    */

    int8_t *queue;
    int count, maxcount, queue_i, queue_j;

    double *number_queue;
    int number_count, number_i, number_j;

    char *string_queue; 
    int string_count, string_i, string_j;

    int received, sent;
    char name[MAX_NAME_LEN];
} Channel;

typedef struct {
    int channels_num;
    Channel *channels[MAX_CHANNELS_NUM];
    SDL_mutex *channels_mut;
} State;

typedef double ID;

/*
// {{{
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
// }}}
*/

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

Channel *channel_find(const char *name) {
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

Channel *channel_allocate(lua_State *lua, const char *chan_name) {
    assert(state && "state == NULL");
    LOG("channel_new:\n")
    Channel *chan = calloc(1, sizeof(Channel));

    chan->mut = SDL_CreateMutex();
    chan->cond = SDL_CreateCond();
    chan->count = 0;
    chan->queue = calloc(QUEUE_SIZE, sizeof(chan->queue[0]));
    chan->number_queue = calloc(QUEUE_SIZE, sizeof(double));
    chan->string_queue = calloc(
            QUEUE_SIZE, (MAX_STR_LEN + 1) * sizeof(char)
    );
    chan->maxcount = QUEUE_SIZE;

    chan->sent = 0;
    chan->received = 0;
    strcpy(chan->name, chan_name);

    state->channels[state->channels_num++] = chan;

    LOG("channel_new [%s]\n", stack_dump(lua));
    return chan;
}

static int channel_new(lua_State *lua) {
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

    Channel *chan = channel_find(chan_name);
    if (!chan) {
        chan = channel_allocate(lua, chan_name);
    }

    lua_pushlightuserdata(lua, chan);

    SDL_UnlockMutex(state->channels_mut);
    LOG("new [%s]\n", stack_dump(lua));
    return 1;
}

static int free_messenger(lua_State *lua) {
    if (state) {
        SDL_LockMutex(state->channels_mut);
        for(int i = 0; state->channels_num; i++) {
            SDL_DestroyMutex(state->channels[i]->mut);
            free(state->channels[i]->queue);
            free(state->channels[i]->number_queue);
            free(state->channels[i]->string_queue);
            free(state->channels[i]);
        }
        SDL_UnlockMutex(state->channels_mut);
        SDL_DestroyMutex(state->channels_mut);
        free(state);
    }
    return 0;
}

static int init_messenger(lua_State *lua) {
    // Имеет-ли здесь мьютекс какой-нибудь смысл?
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

void channel_error(lua_State *lua, char *name, char *msg) {
    char buf[64] = {0, };
    sprintf(buf, "Channel '%s': %s\n", name, msg);
    lua_pushstring(lua, buf);
    lua_error(lua);
}

void push2queue(lua_State *lua, Channel *chan, int8_t type) {
    assert(type == TYPE_NUMBER || type == TYPE_STRING);
    assert(chan);

    if (chan->count < chan->maxcount) {
        chan->queue[chan->queue_i] = type;
        chan->queue_i = (chan->queue_i + 1) % chan->maxcount;
        chan->count++;
    } else {
        lua_pushstring(lua, "queue is full");
        lua_error(lua);
    }
}

ID push_number(lua_State *lua) {
    Channel *chan = (Channel*)lua_touserdata(lua, 1);
    double value = lua_tonumber(lua, 2);
    SDL_LockMutex(chan->mut);

    if (chan->count == QUEUE_SIZE) {
        channel_error(lua, chan->name, "queue is full");
    }

    if (chan->number_count == QUEUE_SIZE) {
        channel_error(lua, chan->name, "number queue is full");
    }

    push2queue(lua, chan, TYPE_NUMBER);

    if (chan->number_count < chan->maxcount ) {
        chan->number_queue[chan->number_i] = value;
        chan->number_i = (chan->number_i + 1) % chan->maxcount;
        chan->number_count++;
        chan->sent++;
    } else {
        lua_pushstring(lua, "number queue is full");
        lua_error(lua);
    }

    SDL_CondBroadcast(chan->cond);
    SDL_UnlockMutex(chan->mut);

    return chan->sent;
}

char *channel_get_string(Channel *ch, int index) {
    assert(ch && "Channel is NULL");
    /*printf("index = %d, string_count = %d\n", index, ch->string_count);*/
    // Верное утверждение?
    /*assert(index <= ch->maxcount - ch->string_count);*/
    return &ch->string_queue[(MAX_STR_LEN + 1) * index];
}

double channel_get_number(Channel *ch, int index) {
    assert(ch && "Channel is NULL");
    assert(index <= ch->number_count);
    return ch->number_queue[index];
}

ID push_string(lua_State *lua) {
    Channel *chan = (Channel*)lua_touserdata(lua, 1);
    const char *value = lua_tostring(lua, 2);
    SDL_LockMutex(chan->mut);

    if (strlen(value) > MAX_STR_LEN) {
        lua_pushstring(lua, "Too long string.\n");
        lua_error(lua);
    }

    if (chan->string_count < chan->maxcount) {
        int index = chan->string_i * (MAX_STR_LEN + 1);
        chan->string_i = (chan->string_i + 1) % chan->maxcount;
        strcpy(&chan->string_queue[index], value);
        push2queue(lua, chan, TYPE_STRING);
        chan->string_count++;

        chan->sent++;
    } else {
        lua_pushstring(lua, "string queue is full");
        lua_error(lua);
    }

    SDL_CondBroadcast(chan->cond);
    SDL_UnlockMutex(chan->mut);

    return chan->sent;
}

static int channel_push(lua_State *lua) {
    /*LOG("channel_push:\n");*/

    ID id = -1;
    if (lua_isnumber(lua, 2)) {
        id = push_number(lua);
    } else if (lua_isstring(lua, 2)) {
        id = push_string(lua);
    } else {
        char buf[128] = {0, };
        const char *tname = lua_typename(lua, lua_type(lua, 2));
        sprintf(buf, "%s type is not allowed", tname);
        lua_pushstring(lua, buf);
        lua_error(lua);
    }

    lua_pushnumber(lua, id);

    return 1;
}

#define CHANNEL_POP_INTERNAL 1
// Возвращает истину если удалось снять значение
bool channel_pop_internal(lua_State *lua, Channel *chan) {
    assert(chan);
#ifdef CHANNEL_POP_INTERNAL
    LOG("----------------------------\n");
    LOG("channel_pop_internal [%s]:\n", stack_dump(lua));
    LOG("name %s\n", chan->name);
    LOG("sent, received %d, %d\n", chan->sent, chan->received);
    LOG("count %d\n", chan->count);
    LOG("number_count %d\n", chan->number_count);
    LOG("string_count %d\n", chan->string_count);
#endif

    bool ret = true;

    // Можно блокировать мьютекс до проверки chan->count ??
    SDL_LockMutex(chan->mut);
    if (chan->count == 0) {
        ret = false;
        goto cleanup;
    } else {
        /*printf("chan->count = %d\n", chan->count);*/
        int8_t type = chan->queue[chan->queue_j];
        chan->queue_j = (chan->queue_j + 1) % chan->maxcount;
        chan->count--;

        if (type == TYPE_STRING) {
            if (chan->string_count == 0) {
                channel_error(lua, chan->name, "string queue is empty");
            } else {
                /*printf("chan->string_j = %d\n", chan->string_j);*/
                char *s = channel_get_string(chan, chan->string_j);
                assert(s);
                chan->string_j = (chan->string_j + 1) % chan->maxcount;
                chan->string_count--;
                lua_pushstring(lua, s);
            }
        } else if (type == TYPE_NUMBER) {
            if (chan->number_count == 0) {
                channel_error(lua, chan->name, "number queue is empty");
            } else {
                lua_pushnumber(lua, chan->number_queue[chan->number_j]);
                chan->number_j = (chan->number_j + 1) % chan->maxcount;
                chan->number_count--;
            }
        } else {
            channel_error(lua, chan->name, "pop: internal type error");
        }

    }
    chan->received++;
    SDL_CondBroadcast(chan->cond);

cleanup:
    SDL_UnlockMutex(chan->mut);

    LOG("channel_pop_internal: [%s]\n", stack_dump(lua));
    LOG("----------------------------\n");
    return ret;
}
#undef CHANNEL_POP_INTERNAL

static int channel_pop(lua_State *lua) {
    Channel *chan = (Channel*)lua_touserdata(lua, 1);
    assert(chan);

    if (!channel_pop_internal(lua, chan)) {
        lua_pushnil(lua);
    } 

    return 1;
}

static int channel_free(lua_State *lua) {
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

static int channel_clear(lua_State *lua) {
    assert(state);
    Channel *chan = (Channel*)lua_touserdata(lua, 1);
    assert(chan);

    SDL_LockMutex(chan->mut);
    chan->count = 0;
    chan->number_count = 0;
    chan->string_count = 0;
    chan->number_i = chan->number_j = 0;
    chan->string_i = chan->string_j = 0;
    chan->queue_i = chan->queue_j = 0;

    chan->received = chan->sent;

    /*
#ifdef DEBUG
    memset(chan->queue, 0, sizeof(chan->queue[0]) * QUEUE_SIZE);
    memset(chan->number_data, 0, sizeof(double) * QUEUE_SIZE);
    memset(
            chan->short_string_data, 
            0, 
            sizeof(char) * (MAX_STR_LEN + 1) * QUEUE_SIZE
    );
#endif
*/

    SDL_CondBroadcast(chan->cond);
    SDL_UnlockMutex(chan->mut);
    return 0;
}

static int channel_peek(lua_State *lua) {
    assert(state);
    Channel *chan = (Channel*)lua_touserdata(lua, 1);
    SDL_LockMutex(chan->mut);

    int8_t type = chan->queue[chan->queue_j];

    if (type == TYPE_STRING) {
        if (chan->string_count == 0) {
            channel_error(lua, chan->name, "string queue is empty");
        } else {
            char *s = channel_get_string(chan, chan->string_j);
            assert(s);
            lua_pushstring(lua, s);
        }
    } else if (type == TYPE_NUMBER) {
        if (chan->number_count == 0) {
            channel_error(lua, chan->name, "number queue is empty");
        } else {
            lua_pushnumber(lua, chan->number_queue[chan->number_j]);
        }
    } else {
        channel_error(lua, chan->name, "pop: internal type error");
    }

    SDL_UnlockMutex(chan->mut);
    return 1;
}

void channel_demand_no_timeout(lua_State *lua, Channel *chan) {
    SDL_LockMutex(chan->mut);

    while (!channel_pop_internal(lua, chan))
        SDL_CondBroadcast(chan->cond);

    SDL_UnlockMutex(chan->mut);
}

void channel_demand_timeout(lua_State *lua, Channel *chan, double timeout) {
    SDL_LockMutex(chan->mut);

    while (timeout > 0) {
        if (channel_pop_internal(lua, chan)) break;

        uint64_t start = SDL_GetTicks64();
        SDL_CondWaitTimeout(chan->cond, chan->mut, timeout * 1000);
        uint64_t stop = SDL_GetTicks64();

        timeout -= (stop - start);
    }

    SDL_UnlockMutex(chan->mut);
}

#define CHANNEL_DEMAND
static int channel_demand(lua_State *lua) {
    assert(state);
    Channel *chan = (Channel*)lua_touserdata(lua, 1);

#ifdef CHANNEL_DEMAND
    LOG("channel_demand [%s]:\n", stack_dump(lua));
    LOG("name %s\n", chan->name);
    LOG("sent, received %d, %d\n", chan->sent, chan->received);
    LOG("count %d\n", chan->count);
    LOG("number_count %d\n", chan->number_count);
    LOG("short_string_count %d\n", chan->short_string_count);
#endif

    if (lua_isnone(lua, 2)) {
        channel_demand_no_timeout(lua, chan);
    } else {
        double timeout = lua_tonumber(lua, 2);
        channel_demand_timeout(lua, chan, timeout);
    }

    return 1;
}
#undef CHANNEL_DEMAND

int static channel_has_read(lua_State *lua) {
    Channel *chan = (Channel*)lua_touserdata(lua, 1);
    if (!chan) {
        lua_pushstring(lua, "channel_has_read: channel is nil");
        lua_error(lua);
    }

    if (!lua_isnumber(lua, 2)) {
        lua_pushstring(lua, "channel_has_read: 'timeout' argument is nil");
        lua_error(lua);
    }

    double id = lua_tonumber(lua, 2);
    bool value = chan->received >= floor(id);
    lua_pushboolean(lua, value);
    return 1;
}

int static channel_get_count(lua_State *lua) {
    Channel *chan = (Channel*)lua_touserdata(lua, 1);
    if (!chan) {
        lua_pushstring(lua, "channel_has_read: channel is nil");
        lua_error(lua);
    }
    lua_pushnumber(lua, chan->count);
    return 1;
}

void channel_supply_no_timeout(lua_State *lua, Channel *chan) {
    SDL_LockMutex(chan->mut);

    ID id = -1;
    if (lua_isnumber(lua, 2)) {
        id = push_number(lua);
    } else if (lua_isstring(lua, 2)) {
        id = push_string(lua);
    } else {
        char buf[128] = {0, };
        const char *tname = lua_typename(lua, lua_type(lua, 2));
        sprintf(buf, "%s type is not allowed", tname);
        lua_pushstring(lua, buf);
        lua_error(lua);
    }

    while (chan->received < id) {
        SDL_CondWait(chan->cond, chan->mut);
    }

    SDL_UnlockMutex(chan->mut);
}

void channel_supply_timeout(lua_State *lua, Channel *chan, double timeout) {
    assert(timeout > 0);
    SDL_LockMutex(chan->mut);

    ID id = -1;
    if (lua_isnumber(lua, 2)) {
        id = push_number(lua);
    } else if (lua_isstring(lua, 2)) {
        id = push_string(lua);
    } else {
        char buf[128] = {0, };
        const char *tname = lua_typename(lua, lua_type(lua, 2));
        sprintf(buf, "%s type is not allowed", tname);
        lua_pushstring(lua, buf);
        lua_error(lua);
    }

    while (timeout >= 0) {
        if (chan->received >= id) {
            break;
        }

        double start = SDL_GetTicks64();
        SDL_CondWaitTimeout(chan->cond, chan->mut, timeout * 1000);
        double stop = SDL_GetTicks64();

        timeout -= (stop - start);
    }

    SDL_UnlockMutex(chan->mut);
}

int static channel_supply(lua_State *lua) {
    Channel *chan = (Channel*)lua_touserdata(lua, 1);
    if (!chan) {
        lua_pushstring(lua, "channel_supply: channel is nil");
        lua_error(lua);
    }

    if (lua_isnil(lua, 2)) {
        channel_supply_no_timeout(lua, chan);
    } else {
        double timeout = lua_tonumber(lua, 2);
        channel_supply_timeout(lua, chan, timeout);
    }

    return 0;
}

int channel_print(lua_State *lua) {
    Channel *ch = lua_touserdata(lua, 1);
    if (ch) {
        int count = ch->count;
        int queue_j = ch->queue_j;
        int number_j = ch->number_j;
        int string_j = ch->string_j;
        while (count > 0) {
            int type = ch->queue[queue_j];
            queue_j = (queue_j + 1) % ch->maxcount;
            if (type == TYPE_NUMBER) {
                printf("%f ", ch->number_queue[number_j]);
                number_j = (number_j + 1) % ch->maxcount;
            } else if (type == TYPE_STRING) {
                int index = string_j * (MAX_STR_LEN + 1);
                printf("%s ", &ch->string_queue[index]);
                string_j = (string_j + 1) % ch->maxcount;
            } else {
                abort();
            }
            count--;
        }
        printf("\n");
    } else {
        lua_pushstring(lua, "No Channel userdata.\n");
        lua_error(lua);
    }
    return 0;
}

int register_module(lua_State *lua) {
    static const struct luaL_Reg functions[] =
    {
        // {{{
        {"init_messenger", init_messenger},
        {"free_messenger", free_messenger},

        {"new", channel_new},
        {"free", channel_free},

        {"push", channel_push},
        {"pop", channel_pop},
        {"clear", channel_clear},
        {"peek", channel_peek},
        {"demand", channel_demand},
        {"has_read", channel_has_read},
        {"get_count", channel_get_count},
        {"supply", channel_supply},

        // DEBUGGING STUFF
        
        // Напечатать всю очередь строк
        /*{"print_strings", channel_print_strings_l},*/
        // Напечать всю очередь чисел
        /*{"print_numbers", channel_print_numbers_l},*/

        {"print", channel_print},
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

extern int luaopen_messenger2(lua_State *lua) {
    LOG("messenger2 module was opened [%s]\n", stack_dump(lua));
    LOG("lua = %p\n", lua);
    state = NULL;

    /*atomic_int bugaga = 0;*/
    /*printf("%d\n", bugaga);*/

    return register_module(lua);
}
