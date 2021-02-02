#!/usr/bin/env bash

./compile.sh

apack game.zip \
addline2mesh.lua \
ansicolors.lua \
assets \
box2dtool.lua \
camera.lua \
cameratool.lua \
celltool.lua \
colorselector.lua \
common.lua \
compat53 \
conf.lua \
debug.lua \
docks \
drawing_bitmap.lua \
external.lua \
fonts \
gfx \
hotkeystool.lua \
hsx.lua \
imgui.so \
inspect.lua \
inter.lua \
keyconfig.lua \
kons.lua \
list.lua \
log.lua \
main.lua \
matrix.lua \
menu.lua \
mobdebug.lua \
neural_network.lua \
NeuralNetwork.lua \
nohup.out \
particlestool.lua \
profi.lua \
qtree.lua \
render_scene.lua \
scale.lua \
scenes/automato/* \
scenes/empty/* \
scenes.lua \
scenetool.lua \
serpent.lua \
ship.lua \
shiptool.lua \
struct.lua \
tabular.lua \
terrain.lua \
terraintool.lua \
Timer.lua \
tools.lua \
vector-light.lua \
vector.lua \
jprof.lua \
MessagePack.lua


CURRENT_DIR=$(pwd)
echo $CURRENT_DIR

LOVE_ANDROID=/home/testuser/projects/love-android
mv game.zip game.love
cp game.love $LOVE_ANDROID/app/src/main/assets/game.love
pushd $LOVE_ANDROID

./gradlew bundleEmbed
./gradlew assembleEmbed

cp app/build/outputs/bundle/embedDebug/app-embed-debug.aab $CURRENT_DIR
cp app/build/outputs/apk/embed/debug/app-embed-debug.apk $CURRENT_DIR

popd
adb uninstall org.love2d.android.embed
adb install ./app-embed-debug.apk

