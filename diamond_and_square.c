// vim: set colorcolumn=85
// vim: fdm=marker

/*
// {{{
Попытка переписывания Lua модуля фрактального алгоритма генерации ландшафта.

Применение метода постоянно работающего кода.
Мыслить о задачах "наперед" - не слишком-ли долгое время займет переписывание?
(Дольше чем устройство и запуск Луа модуля как одиночной программы для
генерации кэша ландшафтов)

Возможно добавить вызов корутин для отображения прогресса генерации.
Использование различных проверок на выход на пределы массива и правильность
значений переменных.

Стоит уделять внимание прочитыванию кода всего модуля сверху-вниз. Для языка
типа C это хороший способ увидеть некоторые ошибки невнимательности.

Филосовский вопрос - стоит-ли переписывать модуль?
Практичный ответ - можно узнать итоговые различия в скорости генерации.
// }}}
*/

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

// Проверить указатель на текущее физическое пространство.
// Вызвать ошибку Lua в случае пустого указателя.
#define CHECK_SPACE \
if (!cur_space) {                                       \
    lua_pushstring(lua, "cur_space pointer is null.\n");\
    lua_error(lua);                                     \
}                                                       \

typedef struct {
    // {{{
    double *map; // 2d array of heights
    int mapSize;
    int chunkSize, initialChunkSize;
    int random_regindex; // LUA_REGISTRYINDEX функции обратного вызова ГПСЧ.
    lua_State *lua;
    // }}}
} Context;

#ifdef DEBUG
// {{{

#define LOG(...)        \
    printf(__VA_ARGS__);\

#else

#define LOG(...) \
    do {} while(0);

// }}}
#endif // DEBUG
      
       
const double SUPER_MIN = -99999;
const double SUPER_MAX =  99999;

void print_map(Context *ctx, int filenum) {
    /*
    assert(filenum >= 0);
    char fname[64] = {0, };
    sprintf(fname, "map.c.%d.txt", filenum);

    FILE *file = fopen(fname, "w+");
    for(int i = 0; i < ctx->chunkSize; i++) {
        for(int j = 0; j < ctx->chunkSize; j++) {
            printf("%f ", ctx->map[ctx->mapSize * i + j]);
            fprintf(file, "%f ", ctx->map[ctx->mapSize * i + j]);
        }
        printf("\n");
        fprintf(file, "\n");
    }
    fclose(file);
    */
}

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

// Освобождает внутренние структуры данных если объект больше не будет
// использоваться.
int diamond_and_square_internal_free(lua_State *lua) {
    check_argsnum(lua, 1);
    Context *ctx = luaL_checkudata(lua, 1, "_DiamondSquare");
    if (ctx->map) {
        free(ctx->map);
        ctx->map = NULL;
    }
    return 0;
}

inline static double map_set(Context *ctx, int i, int j, double value) {
#ifdef DEBUG
    if (i < 0 || i >= ctx->mapSize) {
        printf("map_set(): i out of range 0..%d\n", ctx->mapSize);
        abort();
    }
    if (j < 0 || j >= ctx->mapSize) {
        printf("map_set(): j out of range 0..%d\n", ctx->mapSize);
        abort();
    }
#endif
    return ctx->map[i * ctx->mapSize + j] = value;
}

inline static double map_get(Context *ctx, int i, int j) {
#ifdef DEBUG
    if (i < 0 || i >= ctx->mapSize) {
        printf("map_set(): i out of range 0..%d\n", ctx->mapSize);
        abort();
    }
    if (j < 0 || j >= ctx->mapSize) {
        printf("map_set(): j out of range 0..%d\n", ctx->mapSize);
        abort();
    }
#endif
    return ctx->map[i * ctx->mapSize + j];
}

double internal_random(Context *ctx) {
    lua_rawgeti(ctx->lua, LUA_REGISTRYINDEX, ctx->random_regindex);
    lua_call(ctx->lua, 0, 1);
    double rnd_value = lua_tonumber(ctx->lua, -1);
    lua_remove(ctx->lua, -1);

    //double value = rand() / (double)RAND_MAX;
    /*LOG("internal_random = %.3f\n", rnd_value);*/
    return rnd_value;
}

double random_range(Context *ctx, double min, double max) {
	/*local r = 4*(self.rng:random()-0.5)^3 + 0.5*/
/*--	https://www.desmos.com/calculator/toxjtsovev*/
    return min + internal_random(ctx) * (max - min);
}

void diamond_and_square_reset(Context *ctx) {
    ctx->chunkSize = ctx->initialChunkSize;

    int limit = ctx->mapSize - 1;
    struct {
        int i, j;
    } corners[4] = {
        { .i = 0, .j = 0},
        { .i = limit, .j = 0},
        { .i = limit, .j = limit},
        { .i = 0, .j = limit},
    };

    // XXX Использование константы в сравнеии (i < 4), лучше использовать
    // переменную, расчитанную от длины массива.
    for(int corner_idx = 0; corner_idx < 4; ++corner_idx) {
        int i = corners[corner_idx].i;
        int j = corners[corner_idx].j;

        double rnd_value = internal_random(ctx);
        // TODO исправить математику, откуда такие коэффициенты?
        rnd_value = 0.5 - 0.5 * cos(rnd_value * M_PI);
        /*LOG("i = %d, j = %d\n", i, j);*/
        map_set(ctx, i, j, rnd_value);
    }

    LOG("diamond_and_square_reset: [%s]\n", stack_dump(ctx->lua));
}

int diamond_and_square_new(lua_State *lua) {
    // {{{
    check_argsnum(lua, 2);
    luaL_checktype(lua, 1, LUA_TNUMBER);    // field size argument
    luaL_checktype(lua, 2, LUA_TFUNCTION);  // random function callback

    int mapn = ceil(lua_tonumber(lua, 1));

    Context *ctx = lua_newuserdata(lua, sizeof(Context));
    memset(ctx, 0, sizeof(Context));

    luaL_getmetatable(lua, "_DiamondSquare");
    // [.., ud, {M}]
    lua_setmetatable(lua, -2);
    // [.., {ud}]

    ctx->lua = lua;
    ctx->mapSize = pow(2, mapn) + 1;
    ctx->initialChunkSize = ctx->mapSize - 1;
    ctx->chunkSize = ctx->initialChunkSize;
    ctx->map = calloc(sizeof(double), ctx->mapSize * ctx->mapSize);

    lua_pushvalue(lua, 2);
    ctx->random_regindex = luaL_ref(lua, LUA_REGISTRYINDEX);
    /*lua_rawgeti(lua, LUA_REGISTRYINDEX, ctx->random_regindex); // usage example*/

    /*
    const double init_value = SUPER_MIN; // Каким значением инициализировать?
    for(int i = 0; i < ctx->mapSize; i++) {
        for(int j = 0; j < ctx->mapSize; j++) {
            map_set(ctx, i, j, init_value);
        }
    }
    // */

    LOG("diamond_and_square_new: [%s]\n", stack_dump(lua));
    diamond_and_square_reset(ctx);
    
    return 1;
    // }}}
}

inline static double *value(Context *ctx, int i, int j) {
    /*if (i >= 0 && i < ctx->mapSize && j >= 0 && j < ctx->mapSize) {*/
    if (i >= 0 && i < ctx->mapSize && j >= 0 && j < ctx->mapSize) {
        if (ctx->map[i * ctx->mapSize + j] > SUPER_MIN) {
            return &ctx->map[i * ctx->mapSize + j];
        } else {
            return NULL;
        }
    } else {
        LOG("value is NULL for [%d, %d]\n", i, j);
        return NULL;
    }
}

inline static double min_value(double a, double b) {
    /*return a < b ? a : b;*/

    if (a < b) {
        return a;
    } else {
        return b;
    }

}

inline static double max_value(double a, double b) {
    /*return a > b ? a : b;*/

    if (a > b) {
        return a;
    } else {
        return b;
    }

}

void normalize_implace(Context *ctx) {
    for(int i = 0; i < ctx->mapSize - 1; ++i) {
        for(int j = 0; j < ctx->mapSize - 1; ++j) {
            double *v = value(ctx, i, j);
            if (v) {
                if (*v > 1.) {
                    map_set(ctx, i, j, 1.);
                } else if (*v < 0) {
                    map_set(ctx, i, j, 0.);
                }
            }
        }
    }
}

void square_value(Context *ctx, int i, int j, double *min, double *max) {
    assert(min);
    assert(max);

    *min = 100000.;
    *max = -100000.;

    // Увеличение индексов
    // TODO Стоит вынести массив corners из функции и передавать как аргумент?
    struct {
        int i, j;
    } corners[4] = {
        { .i = i, .j = j},
        { .i = i + ctx->chunkSize, .j = j },
        { .i = i, .j = j + ctx->chunkSize },
        { .i = i + ctx->chunkSize, .j = j + ctx->chunkSize },
    };

    for(int corner_idx = 0; corner_idx < 4; ++corner_idx) {
        double *v = value(ctx, corners[corner_idx].i, corners[corner_idx].j);
        if (v) {

            /*
            *min = *min && min_value(*min, *v) || *v;
            *max = *max && max_value(*max, *v) || *v;
            */

            /*
            *min = *min ? min_value(*min, *v) : *v;
            *max = *max ? max_value(*max, *v) : *v;
            */

            *min = min_value(*min, *v);
            *max = max_value(*max, *v);
        }
    }
}

void square(Context *ctx) {
    LOG("square\n");
    int half = floor(ctx->chunkSize / 2.);
    // XXX Использовать -1 или -2 ??
    for(int i = 0; i < ctx->mapSize - 1; i += ctx->chunkSize) {
        for(int j = 0; j < ctx->mapSize - 1; j += ctx->chunkSize) {
    /*for(int i = 0; i < ctx->mapSize - 2; i += ctx->chunkSize) {*/
        /*for(int j = 0; j < ctx->mapSize - 2; j += ctx->chunkSize) {*/
            double min = 0., max = 0.;
            square_value(ctx, i, j, &min, &max);
            double rnd_value = random_range(ctx, min, max);
            map_set(ctx, i + half, j + half, rnd_value);
        }
    }
}

void diamond_value(
        Context *ctx, 
        int i, int j, int half, 
        double *min, double *max
) {
    *min = 100000.;
    *max = -100000.;

    struct {
        int i, j;
    } corners[4] = {
        {.i = i, .j = j - half}, 
        {.i = i  +  half, .j = j}, 
        {.i = i, .j = j  +  half}, 
        {.i = i - half, .j = j},
    };

    for(int corner_idx = 0; corner_idx < 4; ++corner_idx) {
        double *v = value(ctx, corners[corner_idx].i, corners[corner_idx].j);
        if (v) {
            *min = min_value(*min, *v);
            *max = max_value(*max, *v);
        }
    }
}

bool diamond(Context *ctx) {
    LOG("diamond\n")
    int half = floor(ctx->chunkSize / 2.);
    LOG("half = %d\n", half);
    int mapSize = ctx->mapSize;
    int chunkSize = ctx->chunkSize;
    for(int i = 0; i < mapSize - 1; i += half) {
        for(int j = (i + half) % chunkSize; j < mapSize - 1; j += chunkSize) {
            /*LOG("i: %d j: %d\n", i, j);*/
            double min = 0., max = 0.;
            diamond_value(ctx, i, j, half, &min, &max);
            /*LOG("min, max %f, %f\n", min, max);*/
            double rnd_value = random_range(ctx, min, max);
            map_set(ctx, i, j, rnd_value);
        }
    }

    LOG("ctx->chunkSize = %d\n", ctx->chunkSize);
    ctx->chunkSize = ceil(ctx->chunkSize / 2.);

    return ctx->chunkSize <= 1;
}

int diamond_and_square_eval(lua_State *lua) {
    check_argsnum(lua, 1);
    Context *ctx = luaL_checkudata(lua, 1, "_DiamondSquare");

    LOG("\n")
    LOG("diamond_and_square_eval: [%s]\n", stack_dump(lua));
    LOG("\n")

    if (!ctx->map) {
        lua_pushstring(lua, "diamond_and_square_eval: map was deallocated");
        lua_error(lua);
    }

    diamond_and_square_reset(ctx);
    int filenum = 0;
    print_map(ctx, filenum++);

    bool stop = false;
    do {
        square(ctx);

        print_map(ctx, filenum++);

        stop = diamond(ctx);

        print_map(ctx, filenum++);
    } while (!stop);

    normalize_implace(ctx);
    print_map(ctx, filenum++);

    return 0;
}

int diamond_and_square_get(lua_State *lua) {
    // {{{
    check_argsnum(lua, 3);
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    luaL_checktype(lua, 3, LUA_TNUMBER);
    Context *ctx = luaL_checkudata(lua, 1, "_DiamondSquare");
    int i = ceil(lua_tonumber(lua, 2));
    int j = ceil(lua_tonumber(lua, 3));

    /*
    char err_msg[64] = {0, };
    const char *format_msg = "diamond_and_square_get: '%s' out of range 0..%d";

    if (i < 0 || i >= ctx->mapSize) {
        sprintf(err_msg, format_msg, "i", ctx->mapSize);
        lua_pushstring(lua, err_msg);
    }

    if (j < 0 || j >= ctx->mapSize) {
        sprintf(err_msg, format_msg, "j", ctx->mapSize);
        lua_pushstring(lua, err_msg);
    }
    */

    lua_pushnumber(lua, map_get(ctx, i, j));

    return 1;
    // }}}
}

int diamond_and_square_get_mapsize(lua_State *lua) {
    check_argsnum(lua, 1);
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    Context *ctx = luaL_checkudata(lua, 1, "_DiamondSquare");
    lua_pushnumber(lua, ctx->mapSize);
    return 1;
}

int register_module(lua_State *lua) {
    static const struct luaL_Reg functions[] =
    {
        // {{{
        {"new", diamond_and_square_new},
        {NULL, NULL}
        // }}}
    };
    luaL_register(lua, "diamond_and_square", functions);
    return 1;
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

