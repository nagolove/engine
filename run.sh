#!/usr/bin/env bash
TL="~/projects/tl-master/tl"
eval $TL --version
eval $TL build && love . $1 $2 $3
#tl build && nlove .
