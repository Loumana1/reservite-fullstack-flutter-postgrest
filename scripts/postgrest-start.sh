#!/bin/bash

cd "$(dirname "$0")"
echo "current directory: $(pwd)"

source env.sh

if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* ]]; then
  taskkill //F //IM postgres.exe >/dev/null 2>&1
  taskkill //F //IM postgrest.exe >/dev/null 2>&1
else
  killall postgres
  killall postgrest
fi

if [ ! -d "../data" ]; then
    source pg-init.sh
fi
source pg-start.sh

sleep 3

postgrest ../postgrest.conf
