#!/usr/bin/env bash
# vim: fdm=marker
# vim: set colorcolumn=85

# Возможные ключи:
# --debug   собрать .so модули с отладочной информацией
# --jit     запуск love собранной с luajit

##### Some strict BASH rules:
set -Eeuo pipefail
set -o nounset
set -o errexit
#####

# {{{ Colors:
Black='\033[0;30m'
Dark_Gray='\033[1;30m'
Red='\033[0;31m'
Light_Red='\033[1;31m'
Green='\033[0;32m'
Light_Green='\033[1;32m'
Orange='\033[0;33m'
Yellow='\033[1;33m'
Blue='\033[0;34m'
Light_Blue='\033[1;34m'
Purple='\033[0;35m'
Light_Purple='\033[1;35m'
Cyan='\033[0;36m'
Light_Cyan='\033[1;36m'
Light_Gray='\033[0;37m'
White='\033[1;37m'
NO_COL='\033[0m' # No Color
# }}}

separate_line()
{
echo -e "${Green}||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||${NO_COL}"
}

TL="tl"
echo Teal version: $($TL --version)

separate_line

make_things()
{
    pushd ~/myprojects/xcaustic

    if [[ $# -eq 0 ]] ; then
        echo "No scene name for love"
        exit 1
    fi

    build_mode="release"
    use_jit="false"

    # Сборка новых аргументов что-бы выкинуть ключ --debug из списка.
    for i in "$@" ; do
        if [[ $i == "--debug" ]] ; then
            build_mode="debug"
        elif [[ $i == "--jit" ]] ; then
            use_jit="true"
        else
            newparams+=("$i")
        fi
    done

    # Установка новых аргуметов функции
    set -- "${newparams[@]}" 

    # Распечатать аргументы функции
    #for i in "$@" ; do
        #echo "$i"
    #done

    # Генерация lua кода из teal кода
    tl_build="$TL build"
    $tl_build
    teal_result=$?

    #eval $TL build && love . $1 $2 $3
    #eval $TL build && love . $1 $2 $3
    #if test $Tl -eq 0; then
    #$TL="tl build"
    #echo "res"$t1
    #echo $t1
    #eval $TL --wdisable unused build && love . $1 $2 $3
    #tl build && nlove .

    separate_line

    # Что значит $@ ?? Передача параметра функции?
    echo $@
    pushd scenes/$1
    echo "mode: $build_mode"
    # проверяю вызов команды сборки на успешность завершения
    if [ -f Makefile ]; then
        if ! make config=$build_mode; then
            echo "C module not compiled."
            exit
        fi
    fi
    popd

    separate_line

    echo "mode: $build_mode"
    # проверяю вызов команды сборки на успешность завершения
    if ! make config=$build_mode; then
        echo "C module not compiled."
        exit
    fi

    #readelf -Ws --dyn-syms ddd.so | grep open

    if [[ teal_result -eq 0 ]]; then
        echo 'compiled.'
        separate_line
        
        if [[ "$use_jit" == "true" ]] ; then
            echo "using jit"
            #gdb -ex run --args love . "$@"
            gdb -ex run --args ~/projects/love/src/.libs/love . "$@"
        else
            #~/projects/love_nojit/src/.libs/love . "$@"
            #gdb -ex run --args ~/projects/love_nojit/src/.libs/love . t80 

            echo "no using jit"
            gdb -ex run --args ~/projects/love_nojit/src/.libs/love . "$@"
        fi
    else
        echo 'not compiled.'
    fi

    popd
}

make_things "$@"
