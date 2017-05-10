start redis-server.exe redis.windows_6380.conf 
ping /n 2 127.1>nul
start redis-server.exe redis.windows_6381.conf 
ping /n 2 127.1>nul
start redis-server.exe redis.windows_6382.conf 
ping /n 2 127.1>nul

start redis-server.exe sentinel26379.conf --sentinel  
ping /n 2 127.1>nul
start redis-server.exe sentinel26479.conf --sentinel  
ping /n 2 127.1>nul
start redis-server.exe sentinel26579.conf --sentinel  
ping /n 2 127.1>nul

