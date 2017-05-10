-- 诈金花房间

local pb = require "protobuf"

require "game/lobby/base_room_manager"
require "game/zhajinhua/zhajinhua_table"

-- enum GAME_SERVER_RESULT
local GAME_SERVER_RESULT_SUCCESS = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")

local GAME_SERVER_RESULT_SUCCESS = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
local GAME_SERVER_RESULT_IN_GAME = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_GAME")
local GAME_SERVER_RESULT_IN_ROOM = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_ROOM")
local GAME_SERVER_RESULT_OUT_ROOM = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OUT_ROOM")
local GAME_SERVER_RESULT_NOT_FIND_ROOM = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
local GAME_SERVER_RESULT_NOT_FIND_TABLE = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
local GAME_SERVER_RESULT_NOT_FIND_CHAIR = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_CHAIR")
local GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER")
local GAME_SERVER_RESULT_PLAYER_NO_CHAIR = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_PLAYER_NO_CHAIR")
local GAME_SERVER_RESULT_OHTER_ON_CHAIR = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OHTER_ON_CHAIR")

-- 等待开始
local ZHAJINHUA_STATUS_FREE = 1


zhajinhua_room_manager = base_room_manager:new()

-- 初始化房间
function zhajinhua_room_manager:init(tb, chair_count, ready_mode,room_lua_cfg)
	base_room_manager.init(self, tb, chair_count, ready_mode,room_lua_cfg)
end

-- 创建桌子
function zhajinhua_room_manager:create_table()
	return zhajinhua_table:new()
end

-- 坐下处理
function zhajinhua_room_manager:on_sit_down(player)
	local tb = self:find_table_by_player(player)
	if tb then
		local chat = {
			chat_content = player.account .. " sit down!",
			chat_guid = player.guid,
			chat_name = player.account,
		}
		tb:broadcast2client("SC_ChatTable", chat)
	end
end

-- 快速坐下
function zhajinhua_room_manager:auto_sit_down(player)
	print "test zhajinhua auto sit down ....................."

	local result_, table_id_, chair_id_ = base_room_manager.auto_sit_down(self, player)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end

-- 坐下
function zhajinhua_room_manager:sit_down(player, table_id_, chair_id_)
	print "test zhajinhua sit down ....................."

	local result_, table_id_, chair_id_ = base_room_manager.sit_down(self, player, table_id_, chair_id_)
	
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end

-- 站起
function zhajinhua_room_manager:stand_up(player)
	print "test zhajinhua stand up ....................."

	local tb = self:find_table_by_player(player)
	if tb then
		local chat = {
		chat_content = player.account .. " stand up!",
			chat_guid = player.guid,
			chat_name = player.account,
		}
		tb:broadcast2client("SC_ChatTable", chat)
	end
	return base_room_manager.stand_up(self, player)
end

-- 玩家掉线
function zhajinhua_room_manager:player_offline(player)
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
function zhajinhua_room_manager:stand_up_and_exit_room(player)
	print("zhajinhua_room_manager:stand_up_and_exit_room=============================1")
	if not player.room_id then
		return GAME_SERVER_RESULT_OUT_ROOM
	end
	print("=============================2")
	if not player.table_id then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
print("=============================3")
	if not player.chair_id then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end
print("=============================4")
	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end
print("=============================5")
	local tb = room:find_table(player.table_id)
	if not tb then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

print("=============================7")
	local chair = tb:get_player(player.chair_id)
	if not chair then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end
print("=============================8")
	if chair.guid ~= player.guid then
		return GAME_SERVER_RESULT_OHTER_ON_CHAIR
	end
print("=============================9")
	local tableid = player.table_id
	local chairid = player.chair_id
	tb:player_stand_up(player, false)
print("=============================10")
	local notify = {
			table_id = tableid,
			chair_id = chairid,
			guid = player.guid,
		}
	tb:foreach(function (p)
		p:on_notify_stand_up(notify)
	end)
print("=============================11")
	tb:check_start(true)

	local roomid = player.room_id
	room:player_exit_room(player)
	print("=============================12")
	return GAME_SERVER_RESULT_SUCCESS, roomid, tableid, chairid
end