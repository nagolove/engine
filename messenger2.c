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

    int8_t *queue;
    int count;

    double *number_data;        //
    char *short_string_data;    //
    int number_count;
    int short_string_count;

    int received, sent;
    char name[MAX_NAME_LEN];
} Channel;

typedef struct {
    int channels_num;
    Channel *channels[MAX_CHANNELS_NUM];
    SDL_mutex *channels_mut;
} State;

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
            free(state->channels[i]->number_data);
            free(state->channels[i]->short_string_data);
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

void push_number(lua_State *lua) {
    Channel *chan = (Channel*)lua_touserdata(lua, 1);
    double value = lua_tonumber(lua, 2);
    SDL_LockMutex(chan->mut);

    // Правильность + 1 в условии
    if (chan->count == QUEUE_SIZE) {
        channel_error(lua, chan->name, "queue is full");
    }

    if (chan->number_count == QUEUE_SIZE) {
        channel_error(lua, chan->name, "number queue is full");
    }

    /*
    LOG("channel name %s\n", chan->name);
    LOG("pushing %f\n", value);
    LOG("sent %d\n", chan->sent);
    LOG("channels_num %d\n", state->channels_num);
    */

    chan->number_data[chan->number_count++] = value;
    chan->queue[chan->count++] = TYPE_NUMBER;

    SDL_CondBroadcast(chan->cond);
    SDL_UnlockMutex(chan->mut);
}

char *channel_get_string(Channel *ch, int index) {
    assert(ch && "Channel is NULL");
    assert(index < ch->short_string_count);
    return &ch->short_string_data[(MAX_STR_LEN + 1) * index];
}

void channel_print_strings(Channel *ch) {
    for(int i = 0; i < ch->short_string_count; ++i) {
        printf("%s ", channel_get_string(ch, i));
    }
    printf("\n");
}

void channel_print_numbers(Channel *ch) {
    for(int i = 0; i < ch->number_count; ++i) {
        printf("%.3f ", ch->number_data[i]);
    }
    printf("\n");
}

static int channel_print_strings_l(lua_State *lua) {
    Channel *ch = lua_touserdata(lua, 1);
    channel_print_strings(ch);
    return 0;
}

static int channel_print_numbers_l(lua_State *lua) {
    Channel *ch = lua_touserdata(lua, 1);
    channel_print_numbers(ch);
    return 0;
}

void push_string(lua_State *lua) {
    Channel *chan = (Channel*)lua_touserdata(lua, 1);
    const char *value = lua_tostring(lua, 2);
    SDL_LockMutex(chan->mut);

    if (chan->count == QUEUE_SIZE) {
        channel_error(lua, chan->name, "queue is full");
    }

    if (chan->short_string_count == QUEUE_SIZE) {
        channel_error(lua, chan->name, "string queue is full");
    }

    /*
       LOG("channel name %s\n", chan->name);
       LOG("pushing %f\n", value);
       LOG("sent %d\n", chan->sent);
       LOG("channels_num %d\n", state->channels_num);
       */

    int index = chan->short_string_count * (MAX_STR_LEN + 1);
    strcpy(&chan->short_string_data[index], value);
    chan->short_string_count++;
    chan->queue[chan->count++] = TYPE_STRING;

    SDL_CondBroadcast(chan->cond);
    SDL_UnlockMutex(chan->mut);
}

static int channel_push(lua_State *lua) {
    LOG("channel_push:\n");

    if (lua_isnumber(lua, 2)) {
        push_number(lua);
    } else if (lua_isstring(lua, 2)) {
        push_string(lua);
    } else {
        char buf[128] = {0, };
        const char *tname = lua_typename(lua, lua_type(lua, 2));
        sprintf(buf, "%s type is not allowed", tname);
        lua_pushstring(lua, buf);
        lua_error(lua);
    }

    return 0;
}

#define CHANNEL_POP
static int channel_pop(lua_State *lua) {
    assert(state && "state == NULL");
    Channel *chan = (Channel*)lua_touserdata(lua, 1);

#ifdef CHANNEL_POP
    LOG("----------------------------\n");
    LOG("channel_pop [%s]:\n", stack_dump(lua));
    LOG("name %s\n", chan->name);
    LOG("sent, received %d, %d\n", chan->sent, chan->received);
    LOG("count %d\n", chan->count);
    LOG("number_count %d\n", chan->number_count);
    LOG("short_string_count %d\n", chan->short_string_count);
#endif

    SDL_LockMutex(chan->mut);
    if (chan->count == 0) {
        LOG("preemptive pushing nil\n");
        lua_pushnil(lua);
    } else {
        uint32_t type = chan->queue[chan->sent--]; // Верно-ли работает?
        if (type == TYPE_STRING) {
            if (chan->short_string_count == 0) {
                channel_error(lua, chan->name, "string queue is empty");
            } else {
                char *s = channel_get_string(chan, chan->short_string_count--);
                lua_pushstring(lua, s);
            }
        } else if (type == TYPE_NUMBER) {
            if (chan->number_count == 0) {
                channel_error(lua, chan->name, "number queue is empty");
            } else {
                lua_pushnumber(lua, chan->number_data[chan->number_count--]);
            }
        } else {
            channel_error(lua, chan->name, "internal type error");
        }
    }
    SDL_CondBroadcast(chan->cond);
    SDL_UnlockMutex(chan->mut);

    LOG("channel_pop: [%s]\n", stack_dump(lua));
    LOG("----------------------------\n");
    return 1;
}
#undef CHANNEL_POP

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
        {"init_messenger", init_messenger},
        {"free_messenger", free_messenger},

        {"new", channel_new},
        {"free", channel_free},

        {"push", channel_push},
        {"pop", channel_pop},

        // DEBUGGING STUFF
        // Напечатать всю очередь строк
        {"channel_print_strings", channel_print_strings_l},
        // Напечать всю очередь чисел
        {"channel_print_numbers", channel_print_numbers_l},
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

