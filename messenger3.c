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

typedef struct Node {
    int8_t type;
    union {
        double number;
        char string[MAX_NAME_LEN];
    };
    struct Node *next;
} Node;

/*
Сколько создавать мютексов и условных переменных?
На каждый канал - свой экземппляр?
*/
typedef struct {
    SDL_mutex *mut;
    SDL_cond *cond;

    Node *allocated;
    // Начало очереди, конец очереди, список свободных узлов.
    Node *queue_start, *queue_end, *free_start; 

    int count, number_count, string_count;
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

void channel_init(Channel *chan) {
    assert(chan);

#ifdef DEBUG
    memset(chan->allocated, 0, sizeof(chan->allocated[0]) * QUEUE_SIZE);
#endif
    chan->count = 0;
    chan->number_count = 0;
    chan->string_count = 0;

    Node *node = chan->allocated;

    /*
    -- Порядок создания списка:
    node->next = &chan->allocated[1];
    node = &chan->allocated[1];
    node->next = &chan->allocated[2];
    node = &chan->allocated[2];
    */

    for(int i = 1; i < QUEUE_SIZE; i++) {
        node->next = &chan->allocated[i];
        node = &chan->allocated[i];
    }
    node->next = NULL;
    
    chan->free_start = &chan->allocated[0];
    chan->queue_start = NULL;
    chan->queue_end = NULL;

    chan->sent = 0;
    chan->received = 0;
}

Channel *channel_allocate(lua_State *lua) {
    Channel *chan = calloc(1, sizeof(Channel));
    chan->mut = SDL_CreateMutex();
    chan->cond = SDL_CreateCond();
    chan->allocated = calloc(QUEUE_SIZE, sizeof(*chan->allocated));
    return chan;
}

static int channel_new(lua_State *lua) {
    assert(state && "state == NULL");
    const char *chan_name = luaL_checkstring(lua, 1);

    if (strlen(chan_name) >= MAX_NAME_LEN) {
        char buf[64] = {0, };
        sprintf(buf, "Channel name '%s' too long.", chan_name);
        lua_pushstring(lua, buf);
        lua_error(lua);
    }

    SDL_LockMutex(state->channels_mut);

    if (state->channels_num == MAX_CHANNELS_NUM) {
        printf("channels_num: %d\n", state->channels_num);
        lua_pushstring(lua, "Not enough free channels.");
        lua_error(lua);
    }

    Channel *chan = channel_find(chan_name);
    if (!chan) {
        chan = channel_allocate(lua);
    }

    channel_init(chan);
    strcpy(chan->name, chan_name);
    state->channels[state->channels_num++] = chan;
    lua_pushlightuserdata(lua, chan);
    SDL_UnlockMutex(state->channels_mut);
    LOG("channel_new: [%s]\n", stack_dump(lua));

    return 1;
}

static int free_messenger(lua_State *lua) {
    if (state) {
        SDL_LockMutex(state->channels_mut);
        for(int i = 0; state->channels_num; i++) {
            SDL_DestroyMutex(state->channels[i]->mut);
            free(state->channels[i]->allocated);
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

    Node *new = chan->free_start;
    assert(chan->free_start);
    chan->free_start = chan->free_start->next;
    new->type = TYPE_NUMBER;
    new->number = value;
    new->next = NULL;

    // Может-ли queue_start == queue_end ?
    if (!chan->queue_start) {
        chan->queue_start = new;
    } else {
        new->next = chan->queue_start;
        chan->queue_start = new;
    }

    chan->number_count++;
    chan->count++;
    chan->sent++;

    SDL_CondBroadcast(chan->cond);
    SDL_UnlockMutex(chan->mut);

    return chan->sent;
}

/*
// Только для отлаживания
const char *channel_get_string(Channel *ch, int index) {
    assert(ch && "Channel is NULL");
    assert(index >= 0);
    assert(index < ch->string_count);
    Node *node = ch->queue_start;
    for(int i = 0; i < ch->string_count; i++) {
        node = node->next;
    }
    return node->string;
}

double channel_get_number(Channel *ch, int index) {
    assert(ch && "Channel is NULL");
    assert(index >= 0);
    assert(index < ch->number_count);
    Node *node = ch->queue_start;
    for(int i = 0; i < ch->number_count; i++) {
        node = node->next;
    }
    return ch->number_data[index];
}
*/

/*
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
*/

/*
static int channel_print_strings_l(lua_State *lua) {
    Channel *ch = lua_touserdata(lua, 1);
    if (ch) {
        channel_print_strings(ch);
    } else {
        lua_pushstring(lua, "No Channel userdata.\n");
        lua_error(lua);
    }
    return 0;
}

static int channel_print_numbers_l(lua_State *lua) {
    Channel *ch = lua_touserdata(lua, 1);
    if (ch) {
        channel_print_numbers(ch);
    } else {
        lua_pushstring(lua, "No Channel userdata.\n");
        lua_error(lua);
    }
    return 0;
}
*/

ID push_string(lua_State *lua) {
    Channel *chan = (Channel*)lua_touserdata(lua, 1);
    const char *value = lua_tostring(lua, 2);
    SDL_LockMutex(chan->mut);

    if (strlen(value) > MAX_STR_LEN) {
        lua_pushstring(lua, "Too long string.\n");
        lua_error(lua);
    }

    if (chan->count == QUEUE_SIZE) {
        channel_error(lua, chan->name, "queue is full");
    }

    if (chan->string_count == QUEUE_SIZE) {
        channel_error(lua, chan->name, "string queue is full");
    }

    Node *new = chan->free_start;
    assert(chan->free_start);
    chan->free_start = chan->free_start->next;
    new->type = TYPE_STRING;
    strcpy(new->string, value);
    new->next = NULL;

    // Может-ли queue_start == queue_end ?
    if (!chan->queue_start) {
        chan->queue_start = new;
    } else {
        new->next = chan->queue_start;
        chan->queue_start = new;
    }

    chan->string_count++;
    chan->count++;
    chan->sent++;

    SDL_CondBroadcast(chan->cond);
    SDL_UnlockMutex(chan->mut);

    return chan->sent;
}

// Добавление в конец очереди.
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

    SDL_LockMutex(chan->mut);
    if (chan->count == 0) {
        return false;
    } else {
        Node *first = chan->queue_start;
        assert(first);
        if (first->type == TYPE_STRING) {
            assert(chan->string_count == 0 && "string queue is empty");
            lua_pushstring(lua, first->string);
            --chan->string_count;
        } else if (first->type == TYPE_NUMBER) {
            assert(chan->number_count == 0 && "number queue is empty");
            lua_pushnumber(lua, first->number);
            --chan->number_count;
        } else {
            channel_error(lua, chan->name, "pop: internal type error");
        }
#ifdef DEBUG
        memset(first, 0, sizeof(*first));
#endif
        chan->queue_start = chan->queue_start->next;
        // Верное утверждение? Может остаться один лишний элемент?
        assert(chan->queue_start); 
        Node *free_start = chan->free_start;
        first->next = free_start;
        chan->free_start = first;
        chan->count--;
    }

    chan->received++;
    SDL_CondBroadcast(chan->cond);
    SDL_UnlockMutex(chan->mut);

    return true;
}
#undef CHANNEL_POP_INTERNAL

// Удаление с начала очереди.
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

    int sent = chan->sent;
    channel_init(chan);
    chan->sent = sent;
    chan->received = chan->sent;

    SDL_CondBroadcast(chan->cond);
    SDL_UnlockMutex(chan->mut);
    return 0;
}

static int channel_peek(lua_State *lua) {
    assert(state);
    Channel *chan = (Channel*)lua_touserdata(lua, 1);
    SDL_LockMutex(chan->mut);

    if (chan->count == 0) {
        lua_pushnil(lua);
    } else {
        Node *first = chan->queue_start;
        assert(first);
        if (first->type == TYPE_STRING) {
            assert(chan->string_count == 0 && "string queue is empty");
            lua_pushstring(lua, first->string);
        } else if (first->type == TYPE_NUMBER) {
            assert(chan->number_count == 0 && "number queue is empty");
            lua_pushnumber(lua, first->number);
        } else {
            channel_error(lua, chan->name, "peek: internal type error");
        }
    }
    SDL_UnlockMutex(chan->mut);

    return 1;
}

void channel_demand_no_timeout(lua_State *lua, Channel *chan) {
    SDL_LockMutex(chan->mut);

    while (!channel_pop_internal(lua, chan)) {
        SDL_CondBroadcast(chan->cond);
    }

    SDL_UnlockMutex(chan->mut);
}

void channel_demand_timeout(lua_State *lua, Channel *chan, double timeout) {
    SDL_LockMutex(chan->mut);

    while (timeout > 0) {
        if (channel_pop_internal(lua, chan)) {
            break;
        }

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
    LOG("string_count %d\n", chan->string_count);
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
    Channel *chan = lua_touserdata(lua, 1);
    if (chan) {
        Node *node = chan->queue_start;
        while (node) {
            if (node->type == TYPE_STRING) {
                printf("%s ", node->string);
            } else if (node->type == TYPE_NUMBER) {
                printf("%.3f ", node->number);
            }
            node = node->next;
        }
        printf("\n");
    } else {
        lua_pushstring(lua, "No Channel userdata.");
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

extern int luaopen_messenger3(lua_State *lua) {
    LOG("messenger2 module was opened [%s]\n", stack_dump(lua));
    LOG("lua = %p\n", lua);
    state = NULL;

    /*atomic_int bugaga = 0;*/
    /*printf("%d\n", bugaga);*/

    return register_module(lua);
}
