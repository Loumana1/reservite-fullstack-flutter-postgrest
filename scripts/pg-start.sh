#!/bin/bash

cd $(dirname "$0")
echo "Le script s'exécute dans : $(pwd)"

if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* ]]; then
  taskkill //F //IM postgres.exe >/dev/null 2>&1
else
  killall postgres
fi

pg_ctl restart -D ../data -w -m fast