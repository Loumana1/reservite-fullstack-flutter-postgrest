@echo off

taskkill /F /IM postgres.exe
taskkill /F /IM postgrest.exe

if not exist "..\data" (
    git-bash.exe pg-init.sh
)

start "PostgreSQL" /min postgres -D ..\data
ping -n 3 127.0.0.1 > NUL
start "PostgREST" /min postgrest.exe ..\postgrest.conf