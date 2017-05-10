@echo off

start GameServer.exe ../config/ShuihuZhuanServerConfig.pb
ping /n 2 127.1>nul

