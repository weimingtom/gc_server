-- 梭哈消息处理

local pb = require "protobuf"

require "game/net_func"
local send2client_pb = send2client_pb

require "game/lobby/base_player"
local base_player = base_player

local room_manager = g_room_manager


-- 用户加注
function on_cs_showhand_add_score(player, msg)
	print ("test .................. on_cs_showhand_add_score")

	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:add_score(player, msg.score_type, msg.score)
	else
		log_error(string.format("guid[%d] stand up", player.guid))
	end
end

-- 放弃跟注
--function on_cs_showhand_give_up(player, msg)
--	print ("test .................. on_cs_showhand_give_up")
--	local tb = room_manager:find_table_by_player(player)
--	if tb then
--		tb:give_up(player)
--	else
--		log_error(string.format("guid[%d] stand up", player.guid))
--	end
--end
