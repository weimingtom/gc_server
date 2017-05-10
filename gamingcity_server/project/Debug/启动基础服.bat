@echo off

start DBServer.exe
ping /n 2 127.1>nul

start RedisProxy.exe
ping /n 2 127.1>nul

start LoginServer.exe
ping /n 2 127.1>nul

start CenterServer.exe
ping /n 2 127.1>nul

start GateServer.exe
ping /n 2 127.1>nul
