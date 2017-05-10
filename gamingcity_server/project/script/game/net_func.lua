local pb = require "protobuf"

function send2db_pb(msgname, msg)
	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end
	
	send2db(id, stringbuffer)
end

function send2cfg_pb(msgname, msg)
	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end
	
	send2cfg(id, stringbuffer)
end

function get_msg_id_str(msgname, msg)
	
	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end

	return id, stringbuffer
end

function send2client_pb_str(player_or_guid, msgid, msg_str)
	local player = player_or_guid
	if type(player) ~= "table" then
		player = base_player:find(player_or_guid)
		if not player then
			log_warning("game[send2client_pb] not find player:" .. player_or_guid)
			return
		end
	end

	if player.is_android or not player.is_player then
		--print("----player is robot,send2client_pb return")
		return
	end

	if not player.online then
		print(string.format("game[send2client_pb] offline, guid:%d  msgid:%d",player.guid,msgid))
		return
	end

	send2client(player.guid, player.gate_id, msgid, msg_str)
end

function send2client_pb(player_or_guid, msgname, msg)
	local player = player_or_guid
	if type(player) ~= "table" then
		player = base_player:find(player_or_guid)
		if not player then
			log_warning("game[send2client_pb] not find player:" .. player_or_guid)
			print("------------send2client_pb return")
			return
		end
	end

	if player.is_android or not player.is_player then
		--print("----player is robot,send2client_pb return")
		return
	end

	if not player.online then
		print(string.format("game[send2client_pb] offline, guid:%d  msg:%s",player.guid,msgname))
		print("------------send2client_pb return")
		return
	end

	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end
	
	send2client(player.guid, player.gate_id, id, stringbuffer)
end

function send2client_login(session_id, gate_id, msgname, msg)
	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end
	
	send2client(session_id, gate_id, id, stringbuffer)
end

function send2login_pb(msgname, msg)
	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end
	
	send2login(id, stringbuffer)
end


function send2loginid_pb(server_id, msgname, msg)
	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s", msgname))
	
	local stringbuffer = ""
	if msg then
		stringbuffer = pb.encode(msgname, msg)
	end
	
	send2login_id(server_id, id, stringbuffer)
end

