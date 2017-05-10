local pb = require "protobuf"

function send2game_pb(game_id, msgname, msg)
	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end
	
	game_id = game_id or 0
	if game_id == 0 then
		print( debug.traceback() )
	end
	send2game(game_id, id, stringbuffer)
end

function send2login_pb(login_id, msgname, msg)
	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end
	
	send2login(login_id, id, stringbuffer)
end