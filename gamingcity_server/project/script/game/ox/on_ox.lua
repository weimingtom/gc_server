-- 牛牛消息处理

local pb = require "protobuf"

require "game/net_func"
local send2client_pb = send2client_pb

require "game/lobby/base_player"
local base_player = base_player

local room_manager = g_room_manager


-- 用户申请上庄
function on_cs_ox_apply_for_banker(player,msg)
	print("test.................... on_cs_ox_apply_for_banker")
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:applyforbanker(player)
	else
		log_error(string.format("guid[%d] stand up11", player.guid))
	end
end

-- 在线用户列表用户申请下庄
function on_cs_ox_leave_for_banker(player,msg)
	print("test.................... on_cs_ox_leave_for_banker")
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:leaveforbanker(player)
	else
		log_error(string.format("guid[%d] stand up11", player.guid))
	end
end

-- 在职当庄庄家申请下庄,打完这一局结算完成后下庄
function on_cs_ox_curbanker_leave(player,msg)
	print("test.................... on_cs_ox_curbanker_leave")
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:leave_cur_banker(player)
	else
		log_error(string.format("guid[%d] stand up22", player.guid))
	end
end

-- 用户叫庄
function on_cs_ox_call_banker(player, msg)
	print ("test .................. on_cs_ox_call_banker")

	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:call_banker(player, msg.call_banker)
	else
		log_error(string.format("guid[%d] stand up", player.guid))
	end
end

-- 用户开牌
function on_cs_ox_open_cards(player, msg)
	print ("test .................. on_cs_ox_open_cards")

	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:open_cards(player)
	else
		log_error(string.format("guid[%d] stand up", player.guid))
	end
end

-- 用户加注
function on_cs_ox_add_score(player, msg)
	print ("test .................. on_cs_ox_add_score")

	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:add_score(player,msg.score_area,msg.score)
	else
		log_error(string.format("guid[%d] stand up", player.guid))
	end
end

-- 计分板
function on_cs_ox_record(player,msg)
	print("test....................on_cs_ox_record")
	local tb = room_manager:find_table_by_player(player)
	if tb then
		--tb:send_ox_record(player)
	else
		log_error(string.format("guid[%d] stand up",player.guid))
	end
end

-- 获得游戏中的玩家排名
function on_cs_ox_top(player,msg)
	print("test ..................on_cs_ox_top_info")
	room_manager:get_top_info(player)

end

--玩家进入游戏

function on_cs_ox_PlayerConnectionOxMsg( player, msg )
	-- body
	print("test ..................on_cs_ox_PlayerConnectionOxMsg")
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:PlayerConnectionOxGame(player)
	else
		log_error(string.format("guid[%d] stand up", player.guid))
	end
end

-- 玩家离开游戏
function on_cs_ox_PlayerLeaveGame(player,msg)
	print("test ..................on_cs_ox_PlayerLeaveGame"..player.guid)
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:playerLeaveOxGame(player)
	else
		log_error(string.format("guid[%d] leave ox game error.", player.guid))
	end
end