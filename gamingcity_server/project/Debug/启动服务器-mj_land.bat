@echo off

start ConfigServer.exe
ping /n 2 127.1>nul

start DBServer.exe 1
ping /n 2 127.1>nul

start LoginServer.exe 1
ping /n 2 127.1>nul

start GameServer.exe 100 maajan
ping /n 2 127.1>nul

start GameServer.exe 20 land
ping /n 2 127.1>nul

start GateServer.exe 1
ping /n 2 127.1>nul

start GmServer.exe
ping /n 2 127.1>nul