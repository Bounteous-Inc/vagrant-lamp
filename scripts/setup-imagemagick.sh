#!/usr/bin/env bash

if ! [ -x "$(command -v convert)" ]; then
    apt-get install imagemagick -y
fi