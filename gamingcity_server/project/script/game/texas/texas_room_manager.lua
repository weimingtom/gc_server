-- texas房间
local pb = require "protobuf"
require "game/lobby/base_room_manager"
require "game/texas/texas_table"

-- 等待开始
local TEXAS_STATUS_BETTING_ROUND_TIME = 2	--2s
-- 获取排行的间隔
local TEXAS_SEND_CARDS_INTERVAL = 1	--1s

texas_room_manager = base_room_manager:new()  

-- 初始化房间
function texas_room_manager:init(tb, chair_count, ready_mode, room_lua_cfg)
	base_room_manager.init(self, tb, chair_count, ready_mode, room_lua_cfg)

	self.user_count = 0;
end

-- 创建桌子
function texas_room_manager:create_table()
	return texas_table:new()
end


-- 坐下处理
function texas_room_manager:on_sit_down(player)
	local tb = self:find_table_by_player(player)
	if tb then
		print("========== texas_room_manager:on_sit_down ============")
		local chat = {
			chat_content = player.account .. " sit down!",
			chat_guid = player.guid,
			chat_name = player.account,
		}
		tb:broadcast2client("SC_ChatTable", chat)
	end
end

-- 快速坐下
function texas_room_manager:auto_sit_down(player)
	print("========== texas_room_manager:auto_sit_down ============")

	local result_, table_id_, chair_id_ = base_room_manager.auto_sit_down(self, player)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end

-- 坐下
function texas_room_manager:sit_down(player, table_id_, chair_id_)
	local result_, table_id_, chair_id_ = base_room_manager.sit_down(self, player, table_id_, chair_id_)
	
	print("========== texas_room_manager:sit_down ============")
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end

-- 站起
function texas_room_manager:stand_up(player)
	local tb = self:find_table_by_player(player)
	if tb then
		print("========== texas_room_manager:stand_up ============")
		local chat = {
			chat_content = player.account .. " stand up!",
			chat_guid = player.guid,
			chat_name = player.account,
		}
		tb:broadcast2client("SC_ChatTable", chat)
	end
	return base_room_manager.stand_up(self, player)
end


--获取本房间的所有玩家信息
function texas_room_manager:get_usr_list(player)
	if get_second_time() > (TEXAS_STATUS_BETTING_ROUND_TIME + self.last_get_top_time) then
		-- 获取新的排行数据
		self.count_all_player =0
		-- 所有房间
		local playerinfo = {}
		for i,room in ipairs(self.room_list_) do
			-- print_table(room.room_player_list_,"ROOM player list")
			self.count_all_player = self.count_all_player + room.cur_player_count_
			for j,player in pairs(room.room_player_list_) do
				-- print_table(room.room_player_list_)
				table.insert(playerinfo,{guid = player.guid,head_id = 10001,nickname =player.nickname,money =player.base_info.money})
			end
		end

		table.sort(playerinfo, function (a, b)
			if a.money == b.money then
				return a.guid < b.guid
			else
				return a.money > b.money
			end
		end)
	end

	local msg = { count_all = self.count_all_player}
	send2client_pb(player,"SC_OxTop",msg)
end



-- 玩家掉线
function texas_room_manager:player_offline(player)
	local room = self:find_room(player.room_id)
	if not room then

	print("is ready_mode off line   1")
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	local tb = room:find_table(player.table_id)
	if not tb then
		print("is ready_mode off line   2")
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
	
		local chair = tb:get_player(player.chair_id)
	if not chair then
	print("is ready_mode off line   3")
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	if chair.guid ~= player.guid then
	print("is ready_mode off line   4")
		return GAME_SERVER_RESULT_OHTER_ON_CHAIR
	end

	local tableid, chairid = player.table_id, player.chair_id

	if tb:player_stand_up(player, true) then
		local notify = {
			table_id = tableid,
			chair_id = chairid,
			guid = player.guid,
		}
		tb:foreach(function (p)
			p:on_notify_stand_up(notify)
		end)

		tb:check_start(true)

	print("is ready_mode off line   5")
		return GAME_SERVER_RESULT_SUCCESS, false
	end

	local notify = {
		table_id = tableid,
		chair_id = chairid,
		guid = player.guid,
		is_offline = true,
	}
	tb:foreach_except(chairid, function (p)
		if not tb.isPlay then
			print("AAAAAAAAAA~~~~~~~~~~~!", tb.status ~= ZHAJINHUA_STATUS_PLAY , tb.status)
			p:on_notify_stand_up(notify)
		end
	end)
	print("is ready_mode off line   0")
	return GAME_SERVER_RESULT_SUCCESS, true
end

-- 站起并离开房间
function texas_room_manager:stand_up_and_exit_room(player)
	print("texas_room_manager:stand_up_and_exit_room=============================")
	if not player.room_id then
		return GAME_SERVER_RESULT_OUT_ROOM
	end
	
	if not player.table_id then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	if not player.chair_id then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	local room = self:find_room(player.room_idA)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end
	local tb = room:find_table(player.table_id)
	if not tb then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	local chair = tb:get_player(player.chair_id)
	if not chair then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	if chair.guid ~= player.guid then
		return GAME_SERVER_RESULT_OHTER_ON_CHAIR
	end

	local tableid = player.table_id
	local chairid = player.chair_id
	tb:player_stand_up(player, false)

	local notify = {
			table_id = tableid,
			chair_id = chairid,
			guid = player.guid,
		}
	tb:foreach(function (p)
		p:on_notify_stand_up(notify)
	end)
	
	tb:check_start(true)

	local roomid = player.room_id
	room:player_exit_room(player)
	print("=============================12")
	return GAME_SERVER_RESULT_SUCCESS, roomid, tableid, chairid
end


function texas_room_manager:on_stand_up()
	print("texas_room_manager: on_stand_up() =============================")
end


function texas_room_manager:change_table(player)
	print("texas_room_manager: change_table() =============================")

	local tb = self:find_table_by_player(player)
	if tb then
		local room = self:find_room_by_player(player)
		if room then	
			local newTable, newChair, newTbID = self:get_suitable_table(room,player,true)
			if newTable then
				--离开当前桌子
				local result_, table_id_, chair_id_ = self:stand_up(player)
				player:on_stand_up(table_id_, chair_id_, result_)

				newTable:player_sit_down(player, newChair)
				--player.table_id = newTbID
				--player.chair_id = newChair
				room:player_enter_room(player, room.id)
				newTable:sit_on_chair(player, newChair)
				
				--check if useful
				--player:change_table(player.room_id, newTbID, newChair, GAME_SERVER_RESULT_SUCCESS, newTable)
				return
			end	
		else
			print(" ====== change_table  ====== not in room")
		end
	else
		print(" ====== change_table  ====== no find tb")
	end

	-- local l_player = player
	-- local chair = l_player.chair_id
	-- local guid = l_player.guid
	-- local tb = self:find_table_by_player(player)
	-- base_room_manager:change_table(player)
	-- tb:player_stand_up(player, 0)
end