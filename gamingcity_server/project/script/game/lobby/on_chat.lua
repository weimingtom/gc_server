-- 聊天消息处理

local pb = require "protobuf"

require "game/net_func"
local send2client_pb = send2client_pb
local send2login_pb = send2login_pb

require "game/lobby/base_player"
local base_player = base_player

require "game/lobby/base_room_manager"
local room_manager = g_room_manager

-- 世界聊天
function on_cs_chat_world(player, msg)
	local chat = {
		chat_content = msg.chat_content,
		chat_guid = player.guid,
		chat_name = player.account,
	}
	room_manager:broadcast2client_by_player("SC_ChatWorld", chat)
	
	print "...................................on_cs_chat_world"
end

-- 私聊
function on_cs_chat_private(player, msg)
	local chat = {
		chat_content =  msg.chat_content,
		private_guid = msg.private_name,
		chat_name = player.account,
	}

	send2client_pb(player, "SC_ChatPrivate", chat)

	local target = base_player:find_by_account(msg.private_name)
	if target then
		send2client_pb(target,  "SC_ChatPrivate", chat)
	else
		send2login_pb("SC_ChatPrivate", chat)
	end
end
function on_sc_chat_private(msg)
	local target = base_player:find_by_account(msg.private_name)
	if target then
		send2client_pb(target,  "SC_ChatPrivate", msg)
	end
end

-- 同服聊天
function on_cs_chat_server(player, msg)
	local chat = {
		chat_content = msg.chat_content,
		chat_guid = player.guid,
		chat_name = player.account,
	}
	room_manager:broadcast2client_by_player("SC_ChatServer", chat)
	
	print "...................................on_cs_chat_server"
end

-- 房间聊天
function on_cs_chat_room(player, msg)
	local room = room_manager:find_room_by_player(player)
	if room then
		local chat = {
			chat_content = msg.chat_content,
			chat_guid = player.guid,
			chat_name = player.account,
		}
		room:broadcast2client_by_player("SC_ChatRoom", chat)
	end

	print "...................................on_cs_chat_room"
end

-- 同桌聊天
function on_cs_chat_table(player, msg)
	local tb = room_manager:find_table_by_player(player)
	if tb then
		local chat = {
			chat_content = msg.chat_content,
			chat_guid = player.guid,
			chat_name = player.account,
		}
		tb:broadcast2client("SC_ChatTable", chat)
	end

	print "...................................on_cs_chat_table"
end

