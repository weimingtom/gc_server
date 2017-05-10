@echo off

start ConfigServer.exe
ping /n 2 127.1>nul

start DBServer.exe 1
ping /n 2 127.1>nul

start LoginServer.exe 1
ping /n 2 127.1>nul

start GameServer.exe 20 land
ping /n 2 127.1>nul
start GameServer.exe 21 land
ping /n 2 127.1>nul
start GameServer.exe 22 land
ping /n 2 127.1>nul
start GameServer.exe 23 land
ping /n 2 127.1>nul
start GameServer.exe 30 zhajinhua
ping /n 2 127.1>nul
start GameServer.exe 31 zhajinhua
ping /n 2 127.1>nul
start GameServer.exe 32 zhajinhua
ping /n 2 127.1>nul
start GameServer.exe 33 zhajinhua
ping /n 2 127.1>nul
start GameServer.exe 34 zhajinhua
ping /n 2 127.1>nul
start GameServer.exe 50 ox
ping /n 2 127.1>nul
start GameServer.exe 51 ox
ping /n 2 127.1>nul
start GameServer.exe 90 slotma
ping /n 2 127.1>nul
start GameServer.exe 92 slotma
ping /n 2 127.1>nul
start GameServer.exe 93 slotma
ping /n 2 127.1>nul


start GateServer.exe 1
ping /n 2 127.1>nul

start GmServer.exe
ping /n 2 127.1>nul