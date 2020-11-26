#!/usr/bin/env bash

find . -name "*.lua" -or -name "*.wav" -or -name "*.png" | apack monochrome-tetris.zip
scp monochrome-tetris.zip dekar@visualdoj.ru:/home/dekar/www/packages
ssh dekar@visualdoj.ru /home/dekar/bin/update_index.lua
rm monochrome-tetris.zip
