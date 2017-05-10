-- 房间基类

local pb = require "protobuf"

require "game/net_func"
local send2client_pb = send2client_pb

require "game/lobby/base_table"

require "table_func"

-- enum GAME_SERVER_RESULT
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

-- enum GAME_READY_MODE
-- local GAME_READY_MODE_NONE = pb.enum_id("GAME_READY_MODE", "GAME_READY_MODE_NONE")
-- local GAME_READY_MODE_ALL = pb.enum_id("GAME_READY_MODE", "GAME_READY_MODE_ALL")
-- local GAME_READY_MODE_PART = pb.enum_id("GAME_READY_MODE", "GAME_READY_MODE_PART")


base_room = {}
-- 创建
function base_room:new()  
    local o = {}  
    setmetatable(o, {__index = self})
	
    return o 
end

-- 初始化
function base_room:init(room_manager, table_count, chair_count, ready_mode, room_limit, cell_money, roomconfig, room_lua_cfg)
	self.tax_show_ = roomconfig.tax_show -- 是否显示税收信息
	self.tax_open_ = roomconfig.tax_open -- 是否开启税收
	self.tax_ = roomconfig.tax * 0.01
	self.roomConfig = roomconfig
	self.room_manager_ = room_manager
	self.ready_mode_ = ready_mode -- 准备模式
	self.room_limit_ = room_limit or 0 -- 房间分限制
	self.cell_score_ = cell_money or 0 -- 底注
	self.player_count_limit_ = table_count * chair_count -- 房间人数总限制
	self.table_list_ = {}
	self.configid_ = 0
	self.lua_cfg_ = room_lua_cfg
	
	for i = 1, table_count do
		local t = room_manager:create_table()
		--room, table_id, chair_count
		t:init(self, i, chair_count)
		if self.lua_cfg_ ~= nil then
			t:load_lua_cfg()
		end
		self.table_list_[i] = t
	end
	self.room_player_list_ = {}
	self.cur_player_count_ = 0 -- 当前玩家人数
end

-- gm重新更新配置
function base_room:gm_update_cfg(room_manager,table_count, chair_count, room_limit, cell_money, roomconfig, room_lua_cfg)
	self.room_limit_ = room_limit or 0 -- 房间分限制
	self.cell_score_ = cell_money or 0 -- 底注
	self.tax_show_ = roomconfig.tax_show -- 是否显示税收信息
	self.tax_open_ = roomconfig.tax_open -- 是否开启税收
	self.tax_ = roomconfig.tax * 0.01
	self.roomConfig = roomconfig	
	self.player_count_limit_ = table_count * chair_count -- 房间人数总限制
	self.configid_ = self.configid_ + 1
	self.lua_cfg_ = room_lua_cfg

	for i = #self.table_list_+1, table_count do
		local t = room_manager:create_table()
		--room, table_id, chair_count
		t:init(self, i, chair_count)
		if self.lua_cfg_ ~= nil then
			t:load_lua_cfg()
		end
		self.table_list_[i] = t
	end
end

-- 找到桌子
function base_room:find_table(table_id)
	if not table_id then
		return nil
	end
	return self.table_list_[table_id]
end

-- 通过玩家找桌子
function base_room:find_table_by_player(player)
	if not player.table_id then
		log_warning(string.format("guid[%d] not find in table", player.guid))
		return nil
	end

	local tb = self:find_table(player.table_id)
	if not tb then
		log_warning(string.format("table_id[%d] not find in table", player.table_id))
		return nil
	end

	return tb
end

function base_room:get_room_cell_money()
	return self.cell_score_
end

function base_room:get_room_tax()
	-- body
	return self.tax_
end
-- 得到准备模式
function base_room:get_ready_mode()
	return self.ready_mode_
end

-- 得到房间分限制
function base_room:get_room_limit()
	return self.room_limit_
end

-- 找到房间中玩家
function base_room:find_player_list()
	return self.room_player_list_
end

-- 得到玩家
function base_room:get_player(chair_id)
	return self.room_player_list_[chair_id]
end

-- 得到桌子列表
function base_room:get_table_list()
	return self.table_list_
end

-- 遍历房间所有玩家
function base_room:foreach_by_player(func)
	for _, p in pairs(self.room_player_list_) do
		func(p)
	end
end

-- 广播房间中所有人消息
function base_room:broadcast2client_by_player(msg_name, pb)
	local id, msg = get_msg_id_str(msg_name, pb)
	for _, p in pairs(self.room_player_list_) do
		send2client_pb_str(p, id, msg)
	end
end

-- 遍历所有桌子
function base_room:foreach_by_table(func)
	for _, t in pairs(self.table_list_) do
		func(t)
	end
end

-- 玩家进入房间
function base_room:player_enter_room(player, room_id_)
	player.in_game = true
	player.room_id = room_id_
	self.room_player_list_[player.guid] = player
	self.cur_player_count_ = self.cur_player_count_ + 1

	log_info(string.format("GameInOutLog,base_room:player_enter_room, guid %s, room_id %s",
	tostring(player.guid),tostring(player.room_id)))
end

-- 玩家退出房间
function base_room:player_exit_room(player)
	log_info(string.format("GameInOutLog,base_room:player_exit_room, guid %s, room_id %s",
	tostring(player.guid),tostring(player.room_id)))
	
	print("base_room:player_exit_room")
	player.room_id = nil
	self.room_player_list_[player.guid] = false
	self.cur_player_count_ = self.cur_player_count_ - 1
end
