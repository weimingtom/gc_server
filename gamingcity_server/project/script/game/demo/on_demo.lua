-- demo消息处理

local pb = require "protobuf"

require "game/net_func"
local send2client_pb = send2client_pb

require "game/lobby/base_player"
local base_player = base_player


function on_cs_demo(player, msg)
	print (player.account, msg.test)
	
	send2client_pb(player, "SC_Demo", {
		test = "hello world"
	})
	
	print ("test .................. on_cs_demo")
end
