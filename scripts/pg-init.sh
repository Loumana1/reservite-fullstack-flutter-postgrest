#!/bin/bash

cd "$(dirname "$0")"
echo "current directory: $(pwd)"

source env.sh

if [ -f ../data/postmaster.pid ]; then
	pg_ctl -D ../data stop
fi

if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* ]]; then
  taskkill //F //IM postgres.exe >/dev/null 2>&1
  taskkill //F //IM postgrest.exe >/dev/null 2>&1
else
  killall postgres
  killall postgrest
fi

if [ -d ../data ]; then
	rm -rf ../data
fi

mkdir ../data
initdb -D ../data --locale=C --encoding=UTF8

pg_ctl -D ../data start

sleep 3

createuser -s postgres

psql -U postgres -c "
create role authenticator noinherit login password 'mysecretpassword';
create role anon nologin;
create role authenticated nologin;
"
psql -U postgres -c "alter user postgres password 'dummy123'"

psql -U postgres -c "ALTER DATABASE template0 SET timezone = 'Europe/Brussels';"

createdb -T template0 "$DB_NAME"

pg_ctl stop -D ../data -w -m fast