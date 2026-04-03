#!/bin/bash

# Unpacks a love2d game
unzip -o "$1" -d unpacked

# patches
dos2unix unpacked/resources/shaders/hologram.fs
patch -p0 --fuzz=3 < patches/hologram-const.patch