#!/bin/bash

cd "$(dirname "$0")"
echo "current directory: $(pwd)"

pg_ctl stop -D ../data -w -m fast

if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* ]]; then
  taskkill //F //IM postgres.exe >/dev/null 2>&1
else
  killall postgres
fi
