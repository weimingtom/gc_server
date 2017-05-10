-- 房间操作消息处理

local pb = require "protobuf"

require "game/net_func"
local send2client_pb = send2client_pb

require "game/lobby/base_player"
local base_player = base_player

--require "game/lobby/base_room_manager"
local room_manager = g_room_manager

local def_game_id = def_game_id
local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type

-- 进入房间并坐下
function on_cs_enter_room_and_sit_down(player, msg)
	local result_, room_id_, table_id_, chair_id_, tb = room_manager:enter_room_and_sit_down(player)
	player:on_enter_room_and_sit_down(room_id_, table_id_, chair_id_, result_, tb)
	room_manager:get_table_players_status(player)
	print ("test .................. on_cs_enter_room_and_sit_down")
	print(string.format("result [%d]",result_))
end

-- 站起并离开房间
function on_cs_stand_up_and_exit_room(player, msg)
	local result_, room_id_, table_id_, chair_id_ = room_manager:stand_up_and_exit_room(player)
	print (result_)
	player:on_stand_up_and_exit_room(room_id_, table_id_, chair_id_, result_)	
	print ("test .................. on_cs_stand_up_and_exit_room")
	print (result_)
	print(string.format("result [%d]",result_))
end

-- 切换座位
function on_cs_change_chair(player, msg)
	local result_, table_id_, chair_id_, tb = room_manager:change_chair(player)
	player:on_change_chair(table_id_, chair_id_, result_, tb)
	
	print ("test .................. on_cs_change_chair")
end

-- 进入房间
function on_cs_enter_room(player, msg)
	local result_ = room_manager:enter_room(player, msg.room_id)
	player:on_enter_room(msg.room_id, result_)
	
	print ("test .................. on_cs_enter_room")
end

-- 离开房间
function on_cs_exit_room(player, msg)
	local result_, room_id_ = room_manager:exit_room(player)
	player:on_exit_room(room_id_, result_)
	
	print ("test .................. on_cs_exit_room")
end

-- 快速进入房间
function on_cs_auto_enter_room(player, msg)
	local result_, room_id_ = room_manager:auto_enter_room(player)
	player:on_enter_room(room_id_, result_)

	print ("test .................. on_cs_auto_enter_room")
end

-- 快速坐下
function on_cs_auto_sit_down(player, msg)
	local result_, table_id_, chair_id_ = room_manager:auto_sit_down(player)
	player:on_sit_down(table_id_, chair_id_, result_)
	room_manager:get_table_players_status(player)
	print ("test .................. on_cs_auto_sit_down")
end

-- 坐下
function on_cs_sit_down(player, msg)
	local result_, table_id_, chair_id_  = room_manager:sit_down(player, msg.table_id, msg.chair_id)
	player:on_sit_down(table_id_, chair_id_, result_)
	room_manager:get_table_players_status(player)
	print ("test .................. on_cs_sit_down")
end

-- 站起
function on_cs_stand_up(player, msg)
	local result_, table_id_, chair_id_  = room_manager:stand_up(player)
	player:on_stand_up(table_id_, chair_id_, result_)
	
	print ("test .................. on_cs_stand_up")
end

-- 准备开始
function on_cs_ready(player, msg)
	if player.disable == 1 then
		print("player is Freeaz forced_exit")
		-- 强行T下线
		player:forced_exit();
		return
	end
	if player.chair_id then
		print("on_cs_ready chair_id is :"..player.chair_id)
	end
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:ready(player)
	end

	print ("test .................. on_cs_ready")
end

function on_cs_change_table(player,msg)
	print ("test .................. on_cs_change_table")
	-- body
	room_manager:change_table(player)
end

function on_cs_exit(player,msg)
	print ("test .................. on_cs_exit")
	-- body
	room_manager:exit_server(player,true)
end

function on_cs_Trusteeship(player,msg)
	print ("test .................. on_cs_Trusteeship")
	-- body
	room_manager:CS_Trusteeship(player)
end

-- 加载玩家数据
function on_cs_read_game_info(player)
	if player.is_offline then
		print("-------------------------1")
	end
	if room_manager:isPlay(player) then
		print("-------------------------2")
	end
	if player.is_offline and room_manager:isPlay(player) then
		print("=====================================send SC_ReadGameInfo")
		local notify = {
			pb_gmMessage = {
				first_game_type = def_first_game_type,
				second_game_type = def_second_game_type,
				room_id = player.room_id,
				table_id = player.table_id,
				chair_id = player.chair_id,
			}
		}
		send2client_pb(player,  "SC_ReadGameInfo", notify)
		room_manager:player_online(player)
		return
	end
	print("--------on_cs_read_game_info========")
	send2client_pb(player,  "SC_ReadGameInfo", nil)	
end

--请求玩家数据
function on_cs_ReconnectionPlayMsg( player, msg )
	-- body
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:ReconnectionPlayMsg(player)
	else
		log_error(string.format("guid[%d] stand up", player.guid))
	end
end