#!/usr/bin/env bash
TL="~/projects/tl-master/tl"
eval $TL --version
eval $TL build && love .
#tl build && nlove .
