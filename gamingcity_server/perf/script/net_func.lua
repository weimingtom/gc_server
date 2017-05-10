local pb = require "protobuf"


function send2server_pb(player, msgname, msg)
	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end
	
	send2server(player.client_id_, id, stringbuffer)
end

