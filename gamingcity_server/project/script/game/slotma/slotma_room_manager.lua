-- 老虎机房间

local pb = require "protobuf"

require "game/lobby/base_room_manager"
require "game/slotma/slotma_table"

-- enum GAME_SERVER_RESULT
--[[
   99  // 游戏服返回结果
  100: enum GAME_SERVER_RESULT {
  101: 	GAME_SERVER_RESULT_SUCCESS = 0;							// 操作成功
  102: 	GAME_SERVER_RESULT_IN_GAME = 1;							// 在游戏中无法退出
  103: 	GAME_SERVER_RESULT_IN_ROOM = 2;							// 玩家已经进了房间
  104: 	GAME_SERVER_RESULT_OUT_ROOM = 3;						// 玩家已经出了房间
  105: 	GAME_SERVER_RESULT_NOT_FIND_ROOM = 4;					// 没有找到相应的房间
  106: 	GAME_SERVER_RESULT_NOT_FIND_TABLE = 5;					// 没有找到相应的桌子
  107: 	GAME_SERVER_RESULT_NOT_FIND_CHAIR = 6;					// 没有找到相应的椅子
  108: 	GAME_SERVER_RESULT_PLAYER_ON_CHAIR = 7;					// 玩家已经在椅子
  109: 	GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER = 8;				// 椅子有人
  110: 	GAME_SERVER_RESULT_PLAYER_NO_CHAIR = 9;					// 玩家不在椅子
  111: 	GAME_SERVER_RESULT_OHTER_ON_CHAIR = 10;					// 其他玩家在椅子
  112: 	GAME_SERVER_RESULT_NO_GAME_SERVER = 11;					// 没有找到游戏服务器
  113: 	GAME_SERVER_RESULT_ROOM_LIMIT = 12;						// 房间分数限制
  114  }
--]]
local GAME_SERVER_RESULT_SUCCESS = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")

slotma_room_manager = base_room_manager:new()

-- 初始化房间
function slotma_room_manager:init(tb, chair_count, ready_mode,room_lua_cfg)
	base_room_manager.init(self, tb, chair_count, ready_mode,room_lua_cfg)
end

-- 创建桌子
function slotma_room_manager:create_table()
	return slotma_table:new()
end

-- 坐下处理
function slotma_room_manager:on_sit_down(player)
	print("slotma_room_manager:on_sit_down")
end

-- 快速坐下
function slotma_room_manager:auto_sit_down(player)
	print("slotma_room_manager:auto_sit_down .....................")

	local result_, table_id_, chair_id_ = base_room_manager.auto_sit_down(self, player)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end	
	return result_
end
function slotma_room_manager:get_table_players_status( player )
	base_room_manager:get_table_players_status( player )
	if not player.room_id then
		print("player room_id is nil")
		return nil
	end
	local room = self.room_list_[player.room_id]
	if not room then
		if player.room_id then
			print("room not find room_id:"..player.room_id)
		else
			print("room not find room_id")
		end
		return nil
	end	
	local tb = room:find_table(player.table_id)
	if not tb then
		if player.table_id then
			print("tablelist not find table_id:"..player.table_id)
		else
			print("tablelist not find table_id")
		end
		return nil
	end
	print(string.format("table cunt is [%d] room_id is [%d] table_id is [%d] chair_id is [%d]",#tb:get_player_list(),player.room_id,player.table_id,player.chair_id))
end
-- 坐下
function slotma_room_manager:sit_down(player, table_id_, chair_id_)
	print "slotma_room_manager:sit_down ....................."

	local result_, table_id_, chair_id_ = base_room_manager.sit_down(self, player, table_id_, chair_id_)
	
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end

-- 站起
function slotma_room_manager:stand_up(player)
	print "slotma_room_manager:stand_up ....................."
	return base_room_manager.stand_up(self, player)
end
