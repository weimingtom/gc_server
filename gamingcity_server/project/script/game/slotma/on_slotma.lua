-- 老虎机消息处理

local pb = require "protobuf"

require "game/net_func"
local send2client_pb = send2client_pb

require "game/lobby/base_player"
local base_player = base_player

local room_manager = g_room_manager


--玩家进入游戏
function on_cs_slotma_PlayerConnectionMsg( player, msg )
	-- body
	print("test ..................on_cs_slotma_PlayerConnectionMsg")
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:PlayerConnectionSlotmaGame(player)
	else
		log_error(string.format("guid[%d] stand up", player.guid))
	end
end

-- 玩家离开游戏
function on_cs_slotma_PlayerLeaveGame(player,msg)
	print("test ..................on_cs_slotma_PlayerLeaveGame"..player.guid)
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:playerLeaveSlotmaGame(player)
	else
		log_error(string.format("guid[%d] leave slotma game error.", player.guid))
	end
end

-- 用户叫分
function on_cs_slotma_start(player, msg)
	print ("test .................. on_cs_slotma_start")
	
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:slotma_start(player, msg)
	else
		log_error(string.format("guid[%d] player not find in the room", player.guid))
	end
end