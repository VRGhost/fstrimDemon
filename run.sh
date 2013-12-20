#!/bin/sh

MODE="DEBUG" \
    ETC_PATH="$(dirname '$0')/etc"\
    exec "$(dirname '$0')/usr/sbin/fstrimDemon.sh" "$@"