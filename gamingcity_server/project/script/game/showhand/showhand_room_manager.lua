-- 梭哈房间

local pb = require "protobuf"

require "game/lobby/base_room_manager"
require "game/showhand/showhand_table"

-- enum GAME_SERVER_RESULT
local GAME_SERVER_RESULT_SUCCESS = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")

-- 等待开始
local SHOWHAND_STATUS_FREE = 1


showhand_room_manager = base_room_manager:new()

-- 初始化房间
function showhand_room_manager:init(tb, chair_count, ready_mode)
	base_room_manager.init(self, tb, chair_count, ready_mode)
end

-- 创建桌子
function showhand_room_manager:create_table()
	return showhand_table:new()
end

-- 坐下处理
function showhand_room_manager:on_sit_down(player)
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
function showhand_room_manager:auto_sit_down(player)
	print "test showhand auto sit down ....................."
	local result_, table_id_, chair_id_ = base_room_manager.auto_sit_down(self, player)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end

-- 坐下
function showhand_room_manager:sit_down(player, table_id_, chair_id_)
	print "test showhand sit down ....................."

	local result_, table_id_, chair_id_ = base_room_manager.sit_down(self, player, table_id_, chair_id_)
	
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end

-- 站起
function showhand_room_manager:stand_up(player)
	print "test showhand stand up ....................."

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

