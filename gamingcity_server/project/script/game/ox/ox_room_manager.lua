-- 牛牛房间

local pb = require "protobuf"

require "game/lobby/base_room_manager"
require "game/ox/ox_table"

-- enum GAME_SERVER_RESULT
local GAME_SERVER_RESULT_SUCCESS = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")

-- 等待开始
local OX_STATUS_FREE = 1
-- 获取排行的间隔
local OX_GET_TOP_DIS = 10
-- 排名最大显示数量
local TOP_MAX_NUM =300

ox_room_manager = base_room_manager:new()

-- 初始化房间
function ox_room_manager:init(tb, chair_count, ready_mode, room_lua_cfg)
	base_room_manager.init(self, tb, chair_count,ready_mode,room_lua_cfg)

	-- 上次获取排名的时间
	self.last_get_top_time =0
	-- 玩家总数
	self.count_all_player =0
	-- 排名信息
	self.top_info = {}

end

-- 创建桌子
function ox_room_manager:create_table()
	return ox_table:new()
end

-- 坐下处理
function ox_room_manager:on_sit_down(player)
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
function ox_room_manager:auto_sit_down(player)
	print "test ox auto sit down ....................."

	local result_, table_id_, chair_id_ = base_room_manager.auto_sit_down(self, player)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end

-- 坐下
function ox_room_manager:sit_down(player, table_id_, chair_id_)
	print "test ox sit down ....................."

	local result_, table_id_, chair_id_ = base_room_manager.sit_down(self, player, table_id_, chair_id_)
	
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end

-- 站起
function ox_room_manager:stand_up(player)
	print "test ox stand up ....................."

	local tb = self:find_table_by_player(player)
	if tb then
		local chat = {
		chat_content = player.account .. " stand up!",
			chat_guid = player.guid,
			chat_name = player.account,
		}
		--tb:broadcast2client("SC_ChatTable", chat)
	end
	return base_room_manager.stand_up(self, player)
end

-- 获取本房间的所有玩家信息
function ox_room_manager:get_top_info(player)
	if get_second_time() > (OX_GET_TOP_DIS + self.last_get_top_time) then
		-- 获取新的排行数据
		self.count_all_player =0
		self.top_info = {}
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

		for i=1,TOP_MAX_NUM do
			local p = playerinfo[i]
			if p == nil then
				break
			end
			self.top_info[i] = p  
		end
		self.last_get_top_time = get_second_time()
	end
	-- print_table(self.top_info)
	local msg = { count_all = self.count_all_player, pb_player_top_info =self.top_info}
	send2client_pb(player,"SC_OxTop",msg)
end
