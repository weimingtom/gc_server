-- demo消息处理

local pb = require "protobuf"

require "game/net_func"
local send2client_pb = send2client_pb

require "game/lobby/base_player"
local base_player = base_player
local room_manager = g_room_manager

function on_cs_texas_action(player, msg)
	local tb = room_manager:find_table_by_player(player)

	if msg == false then
		print ("  ||||||  error receive [[false]]  ||||||")
		msg = {}
		msg.action = ACT_CHECK
		msg.bet_money = 0
	end

	if next(msg) == nil then
		print ("  ||||||   error receive [[emprty]]    ||||||")
		msg = {}
		msg.action = ACT_CHECK
		msg.bet_money = 0
	else
		--print ("--------on_cs_texas_action------------")
		--t_var_dump(msg)
	end
	
	if tb then
		local retCode = tb:player_action(player, tb, msg.action, msg.bet_money)
		if retCode ~= CS_ERR_OK then
			send2client_pb(player,"SC_TexasError", {error=retCode})
		end
	else
		log_error(string.format("guid[%d] give_up", player.guid))
	end
	--t:broadcast2client("SC_TexasU^serAction", ret) 
end


--获取坐下玩家
function on_cs_texas_sit_down(player, msg)
	print ("    .................. on_cs_texas_get_sit_down")
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:sit_on_chair(player, player.chair_id)
		--tb:player_sit_down(player, player.chair_id)
	else
		log_error(string.format("guid[%d] get_sit_down", player.guid))
	end
end

-- 玩家离开游戏
function on_cs_texas_leave(player,msg)
	print("      ..................on_cs_texas_leave"..player.guid)
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:player_leave(player)
	else
		print("guid[%d] leave texas game error.", player.guid)
	end
end