-- 诈金花消息处理

local pb = require "protobuf"

require "game/net_func"
local send2client_pb = send2client_pb

require "game/lobby/base_player"
local base_player = base_player

local room_manager = g_room_manager


-- 用户加注
function on_cs_zhajinhua_add_score(player, msg)
	print ("test .................. on_cs_zhajinhua_add_score")

	local tb = room_manager:find_table_by_player(player)
	if tb then
		if msg.score then
			tb:add_score(player, msg.score)
		else
			log_error(string.format("guid[%d] add score No score", player.guid))
		end
	else
		log_error(string.format("guid[%d] add_score", player.guid))
	end
end

-- 放弃跟注
function on_cs_zhajinhua_give_up(player, msg)
	print ("test .................. on_cs_zhajinhua_give_up")
	
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:give_up(player)
	else
		log_error(string.format("guid[%d] give_up", player.guid))
	end
end

-- 看牌
function on_cs_zhajinhua_look_card(player, msg)
	print ("test .................. on_cs_zhajinhua_look_card")

	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:look_card(player)
	else
		log_error(string.format("guid[%d] look_card", player.guid))
	end
end

-- 比牌
function on_cs_zhajinhua_compare_card(player, msg)
	print ("test .................. on_cs_zhajinhua_compare_card")
	
	local tb = room_manager:find_table_by_player(player)
	if tb then
		if msg.compare_chair_id then
			tb:compare_card(player, msg.compare_chair_id)
		else
			log_error(string.format("guid[%d] compare card  no chair id", player.guid))
		end
	else
		log_error(string.format("guid[%d] compare_card", player.guid))
	end
end

--获取玩家状态
function on_cs_zhajinhua_get_player_status(player, msg)
	print ("test .................. on_cs_zhajinhua_get_player_status")
	
	local tb = room_manager:find_table_by_player(player)
	if tb then
			tb:get_play_Status(player)
	else
		log_error(string.format("guid[%d] get_player_status", player.guid))
	end
end


--获取坐下玩家
function on_cs_zhajinhua_get_sit_down(player, msg)
	print ("test .................. on_cs_zhajinhua_get_sit_down")
	
	local tb = room_manager:find_table_by_player(player)
	if tb then
			tb:get_sit_down(player)
	else
		log_error(string.format("guid[%d] get_sit_down", player.guid))
	end
end
