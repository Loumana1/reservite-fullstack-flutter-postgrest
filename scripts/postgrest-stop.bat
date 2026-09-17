@echo off
taskkill /F /IM postgrest.exe
pg_ctl stop -D ../data -w -m fast
taskkill /F /IM postgres.exe
