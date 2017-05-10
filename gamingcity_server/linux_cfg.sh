protoc --cpp_out=./server/code/BaseGame/cfg --proto_path=./server/code/BaseGame/cfg ./server/code/BaseGame/cfg/GameServerConfig.proto
protoc --cpp_out=./server/code/DBServer/cfg --proto_path=./server/code/DBServer/cfg ./server/code/DBServer/cfg/DBServerConfig.proto
protoc --cpp_out=./server/code/GateServer/cfg --proto_path=./server/code/GateServer/cfg ./server/code/GateServer/cfg/GateServerConfig.proto
protoc --cpp_out=./server/code/LoginServer/cfg --proto_path=./server/code/LoginServer/cfg ./server/code/LoginServer/cfg/LoginServerConfig.proto

cd common/pb
./linux_pbcreate.sh
