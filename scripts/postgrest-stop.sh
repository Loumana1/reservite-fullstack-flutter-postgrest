#!/bin/bash

cd "$(dirname "$0")"
echo "current directory: $(pwd)"

source env.sh

if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* ]]; then
  taskkill //F //IM postgrest.exe >/dev/null 2>&1
else
  killall postgrest
fi

source pg-stop.sh
