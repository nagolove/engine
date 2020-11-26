#!/usr/bin/env bash
archivename="touchgui$(date +"%m_%d_%Hh%Mm%Ss").zip"
dest=~/myprojects/autoupdate/server/archives_examples

apack $archivename \
button.lua \
logthread.lua \
log.lua \
object.lua \
container.lua \
slider.lua \
camera.lua \
container.lua \
inspect.lua \
main.lua

#mv $archivename $dest
scp $archivename dekar@visualdoj.ru:~/myprojects
rm $archivename
#ls $dest
