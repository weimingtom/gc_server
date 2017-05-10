-- game room

local pb = require "protobuf"

require "game/net_func"
local send2client_pb = send2client_pb

require "game/lobby/base_room"
require "game/lobby/base_table"
--require "game/lobby/base_player"

require "table_func"

-- enum GAME_SERVER_RESULT
local GAME_SERVER_RESULT_SUCCESS = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
local GAME_SERVER_RESULT_IN_GAME = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_GAME")
local GAME_SERVER_RESULT_IN_ROOM = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_ROOM")
local GAME_SERVER_RESULT_FREEZEACCOUNT = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_FREEZEACCOUNT")
local GAME_SERVER_RESULT_OUT_ROOM = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OUT_ROOM")
local GAME_SERVER_RESULT_NOT_FIND_ROOM = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
local GAME_SERVER_RESULT_NOT_FIND_TABLE = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
local GAME_SERVER_RESULT_NOT_FIND_CHAIR = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_CHAIR")
local GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER")
local GAME_SERVER_RESULT_PLAYER_NO_CHAIR = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_PLAYER_NO_CHAIR")
local GAME_SERVER_RESULT_OHTER_ON_CHAIR = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OHTER_ON_CHAIR")

-- enum GAME_READY_MODE
local GAME_READY_MODE_NONE = pb.enum_id("GAME_READY_MODE", "GAME_READY_MODE_NONE")
local GAME_READY_MODE_ALL = pb.enum_id("GAME_READY_MODE", "GAME_READY_MODE_ALL")
local GAME_READY_MODE_PART = pb.enum_id("GAME_READY_MODE", "GAME_READY_MODE_PART")


-- 房间
base_room_manager = base_room_manager or {}

function base_room_manager:new()  
    local o = {}  
    setmetatable(o, {__index = self})  
    return o 
end

-- 初始化房间
function base_room_manager:init(tb, chair_count, ready_mode, room_lua_cfg)
	self.time0_ = get_second_time()
	self.chair_count_ = chair_count
	self.ready_mode_ = ready_mode
	self.room_list_ = {}
	for i,v in ipairs(tb) do
		local r = self:create_room()
		r:init(self, v.table_count, chair_count, ready_mode, v.money_limit, v.cell_money, v, room_lua_cfg)
		r.id = i
		self.room_list_[i] = r
	end
end

-- gm重新更新配置, room_lua_cfg
function base_room_manager:gm_update_cfg(tb, room_lua_cfg)
	local old_count = #self.room_list_
	for i,v in ipairs(tb) do
		if i <= old_count then
			print("change----gm_update_cfg", v.table_count, self.chair_count_, v.money_limit, v.cell_money)
			self.room_list_[i]:gm_update_cfg(self,v.table_count, self.chair_count_, v.money_limit, v.cell_money, v, room_lua_cfg)
		else
			local r = self:create_room()
			print("Init----gm_update_cfg", v.table_count, self.chair_count_, v.money_limit, v.cell_money)
			r:init(self, v.table_count, self.chair_count_, self.ready_mode_, v.money_limit, v.cell_money, v, room_lua_cfg)
			self.room_list_[i] = r
		end
	end
end

-- 创建房间
function base_room_manager:create_room()
	return base_room:new()
end

-- 创建桌子
function base_room_manager:create_table()
	return base_table:new()
end

-- 找到房间
function base_room_manager:find_room(room_id)
	return self.room_list_[room_id]
end

-- 通过玩家找房间
function base_room_manager:find_room_by_player(player)
	if not player.room_id then
		log_warning(string.format("guid[%d] not find in room", player.guid))
		return nil
	end

	local room = self:find_room(player.room_id)
	if not room then
		log_warning(string.format("room_id[%d] not find in room", player.room_id))
		return nil
	end

	return room
end

-- 通过玩家找桌子
function base_room_manager:find_table_by_player(player)
	local room = self:find_room_by_player(player)
	if room then
		return room:find_table_by_player(player)
	end
	return nil
end

-- 遍历房间所有玩家
function base_room_manager:foreach_by_player(func)
	for i,v in ipairs(self.room_list_) do
		v:foreach_by_player(func)
	end
end

-- 广播房间中所有人消息
function base_room_manager:broadcast2client_by_player(msg_name, pb)
	for i,v in ipairs(self.room_list_) do
		v:broadcast2client_by_player(msg_name, pb)
	end
end

function base_room_manager:get_table_players_status( player )
	-- body
	print("--------get_table_player_status-------------")
end

-- 进入房间并坐下
function base_room_manager:enter_room_and_sit_down(player)
	print("player guid is :"..player.guid)	
	if player.disable == 1 then
		print("get_table_players_status player is Freeaz forced_exit")
		return GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	if player.room_id then
		print("player room_id is :"..player.room_id)
		return GAME_SERVER_RESULT_IN_ROOM
	end

	if player.table_id or player.chair_id then
		print(string.format("player tableid is [%d] chairid is [%d]",player.table_id,player.chair_id))
		return GAME_SERVER_RESULT_PLAYER_ON_CHAIR
	end

	local ret = GAME_SERVER_RESULT_NOT_FIND_ROOM

	for i,room in ipairs(self.room_list_) do
		if not player:check_room_limit(room:get_room_limit()) and room.cur_player_count_ < room.player_count_limit_ then
			ret = GAME_SERVER_RESULT_NOT_FIND_TABLE
			local tb,k,j = self:get_suitable_table(room,player,false)
			if tb then
				room:player_enter_room(player, i)
				-- 通知消息
				local notify = {
					table_id = j,
					pb_visual_info = {
					chair_id = k,
					guid = player.guid,
					account = player.account,
					nickname = player.nickname,
					level = player:get_level(),
					money = player:get_money(),
					header_icon = player:get_header_icon(),
					ip_area = player.ip_area,
					}
				}
				print("ip_area--------------------A",  player.ip_area)
				print("ip_area--------------------B",  notify.pb_visual_info.ip_area)
				tb:foreach(function (p)
					p:on_notify_sit_down(notify)
				end)
				tb:player_sit_down(player, k)
				return GAME_SERVER_RESULT_SUCCESS, i, j, k, tb
			end
		end
	end

	return ret
end

-- 站起并离开房间
function base_room_manager:stand_up_and_exit_room(player)
	if not player.room_id then
		return GAME_SERVER_RESULT_OUT_ROOM
	end
	if not player.table_id then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
	if not player.chair_id then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end
	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end
	local tb = room:find_table(player.table_id)
	if not tb then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
	if tb:isPlay() then
		return GAME_SERVER_RESULT_IN_GAME
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
	return GAME_SERVER_RESULT_SUCCESS, roomid, tableid, chairid
end

-- 切换座位
function base_room_manager:change_chair(player)
	if player.disable == 1 then
		print("stand_up_and_exit_room player is Freeaz forced_exit")
		return GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	if not player.room_id then
		return GAME_SERVER_RESULT_OUT_ROOM
	end

	if not player.table_id then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	if not player.chair_id then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	local room = self:find_room(player.room_id)
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
	
	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	local tableid = player.table_id
	local chairid = player.chair_id
	local targettb = nil
	local targetid = nil

	for i,v in ipairs(room:get_table_list()) do
		if i > tableid then
			for k,chair in ipairs(v:get_player_list()) do
				if chair == false then
					targettb = v
					targetid = k
				end
			end
		end
	end
	if targetid == nil then
		for i,v in ipairs(room:get_table_list()) do
			if i < tableid then
				for k,chair in ipairs(v:get_player_list()) do
					if chair == false then
						targettb = v
						targetid = k
					end
				end
			end
		end
	end

	if targetid == nil then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	-- 旧桌子站起
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

	-- 通知消息
	local notify = {
		table_id = targettb.table_id_,
		pb_visual_info = {
			chair_id = targetid,
			guid = player.guid,
			account = player.account,
			nickname = player.nickname,
			level = player:get_level(),
			money = player:get_money(),
			header_icon = player:get_header_icon(),
			ip_area = player.ip_area,
		}
	}
	print("ip_area--------------------A",  player.ip_area)
	print("ip_area--------------------B",  notify.pb_visual_info.ip_area)
	targettb:foreach(function (p)
		p:on_notify_sit_down(notify)
	end)

	targettb:player_sit_down(player, targetid)

	return GAME_SERVER_RESULT_SUCCESS, targettb.table_id_, targetid, targettb
end

-- 快速进入房间
function base_room_manager:auto_enter_room(player)
	if player.disable == 1 then
		print("auto_enter_room player is Freeaz forced_exit")
		return GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	if player.room_id then
		return GAME_SERVER_RESULT_IN_ROOM
	end

	for i,room in ipairs(self.room_list_) do
		if not player:check_room_limit(room:get_room_limit()) and room.cur_player_count_ < room.player_count_limit_ then
			-- 通知消息
			local notify = {
				room_id = i,
				guid = player.guid,
			}
			room:foreach_by_player(function (p)
				p:on_notify_enter_room(notify)
			end)

			room:player_enter_room(player, i)
			return GAME_SERVER_RESULT_SUCCESS, i
		end
	end

	return GAME_SERVER_RESULT_NOT_FIND_ROOM
end

-- 进入房间
function base_room_manager:enter_room(player, room_id_)
	if player.disable == 1 then
		print("enter_room player is Freeaz forced_exit")
		return GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	if player.room_id then
		return GAME_SERVER_RESULT_IN_ROOM
	end

	local room = self:find_room(room_id_)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	if player:check_room_limit(room:get_room_limit()) then
		log_warning(string.format("guid[%d] check money limit fail,limit[%d],self[%d]", player.guid, room:get_room_limit(), player.pb_base_info.money))
		return GAME_SERVER_RESULT_ROOM_LIMIT
	end

	-- 通知消息
	local notify = {
		room_id = room_id_,
		guid = player.guid,
	}
	room:foreach_by_player(function (p)
		p:on_notify_enter_room(notify)
	end)

	room:player_enter_room(player, room_id_)

	return GAME_SERVER_RESULT_SUCCESS
end
function base_room_manager:CS_Trusteeship(player)
	-- body
	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	local tb = room:find_table(player.table_id)
	if not tb then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
	tb:setTrusteeship(player,true)
end
-- 离开房间
function base_room_manager:exit_room(player)
	print("base_room_manager:exit_room")
	if not player.room_id then
		print("GAME_SERVER_RESULT_OUT_ROOM")
		return GAME_SERVER_RESULT_OUT_ROOM
	end

	--if not player.table_id then
	--	return GAME_SERVER_RESULT_NOT_FIND_TABLE
	--end

	--if not player.chair_id then
	--	return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	--end

	local roomid = player.room_id
	local room = self:find_room(roomid)
	if not room then
		print("GAME_SERVER_RESULT_NOT_FIND_ROOM")
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	room:player_exit_room(player)
	
	local notify = {
			room_id = roomid,
			guid = player.guid,
		}
	room:foreach_by_player(function (p)
		if p then
			p:on_notify_exit_room(notify)
		end
	end)

	return GAME_SERVER_RESULT_SUCCESS, roomid
end

-- 玩家掉线
function base_room_manager:player_offline(player)
	local room = self:find_room(player.room_id)
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

		return GAME_SERVER_RESULT_SUCCESS, false
	end

	local notify = {
		table_id = tableid,
		chair_id = chairid,
		guid = player.guid,
		is_offline = true,
	}
	tb:foreach_except(chairid, function (p)
		p:on_notify_stand_up(notify)
	end)

	return GAME_SERVER_RESULT_SUCCESS, true
end
function base_room_manager:isPlay(player)
	print("=========base_room_manager:isPlay")
	-- body
	if player.room_id and player.table_id and player.chair_id then
		local room = self:find_room(player.room_id)
		if not room then
			print("=========base_room_manager:isPlay not room")
			return false
		end
		local tb = room:find_table(player.table_id)
		if not tb then
			print("=========base_room_manager:isPlay not tb")
			return false
		end
		return tb:isPlay()
	end
	print("=========base_room_manager:isPlay false")
	return false
end
-- 玩家上线
function base_room_manager:player_online(player)
	
	if player.room_id and player.table_id and player.chair_id then

		local room = self:find_room(player.room_id)
		if not room then
			return GAME_SERVER_RESULT_NOT_FIND_ROOM
		end
		player:on_enter_room(player.room_id, GAME_SERVER_RESULT_SUCCESS)

		local tb = room:find_table(player.table_id)
		if not tb then
			return GAME_SERVER_RESULT_NOT_FIND_TABLE
		end
		
		local chair = tb:get_player(player.chair_id)
		if not chair then
			return GAME_SERVER_RESULT_NOT_FIND_CHAIR
		end

		if chair.guid ~= player.guid then
			player.table_id = nil
			player.chair_id = nil
			return GAME_SERVER_RESULT_OHTER_ON_CHAIR
		end

		player.is_offline = nil

		-- 通知消息
		local notify = {
			table_id = player.table_id,
			pb_visual_info = {
				chair_id = player.chair_id,
				guid = player.guid,
				account = player.account,
				nickname = player.nickname,
				level = player:get_level(),
				money = player:get_money(),
				header_icon = player:get_header_icon(),				
				ip_area = player.ip_area,
			},
			is_onfline = true,
		}

		print("ip_area--------------------A",  player.ip_area)
		print("ip_area--------------------B",  notify.pb_visual_info.ip_area)
		tb:foreach_except(player.chair_id, function (p)
			p:on_notify_sit_down(notify)
		end)

		-- 重连
		tb:reconnect(player)

		return GAME_SERVER_RESULT_SUCCESS
	end
end

-- 退出服务器
function base_room_manager:exit_server(player)
	if player.room_id and player.table_id and player.chair_id then
		--self:stand_up(player)
		local result_, is_offline_ = self:player_offline(player)
		if result_ == GAME_SERVER_RESULT_SUCCESS then
			if is_offline_ then
				return true
			end
			self:exit_room(player)
		end
	end
	return false
end

-- 快速坐下
function base_room_manager:auto_sit_down(player)
	if player.disable == 1 then
		print("auto_sit_down player is Freeaz forced_exit")
		return GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	if not player.room_id then
		return GAME_SERVER_RESULT_OUT_ROOM
	end
	
	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	for i,tb in ipairs(room:get_table_list()) do
		for j,chair in ipairs(tb:get_player_list()) do
			if chair == false then
				return self:sit_down(player, i, j)
			end
		end
	end

	return GAME_SERVER_RESULT_NOT_FIND_TABLE
end

-- 坐下
function base_room_manager:sit_down(player, table_id_, chair_id_)
	if player.disable == 1 then
		print("sit_down player is Freeaz forced_exit")
		return GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	if not player.room_id then
		return GAME_SERVER_RESULT_OUT_ROOM
	end
	
	if player.table_id or player.chair_id then
		return GAME_SERVER_RESULT_PLAYER_ON_CHAIR
	end
	
	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end
	
	local tb = room:find_table(table_id_)
	if not tb then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
	
	local chair = tb:get_player(chair_id_)
	if chair then
		return GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER
	elseif chair == nil then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end
	
	-- 通知消息
	local notify = {
		table_id = table_id_,
		pb_visual_info = {
			chair_id = chair_id_,
			guid = player.guid,
			account = player.account,
			nickname = player.nickname,
			level = player:get_level(),
			money = player:get_money(),
			header_icon = player:get_header_icon(),			
			ip_area = player.ip_area,
		},
	}

	print("ip_area--------------------A",  player.ip_area)
	print("ip_area--------------------B",  notify.pb_visual_info.ip_area)
	tb:foreach(function (p)
		p:on_notify_sit_down(notify)
	end)

	tb:player_sit_down(player, chair_id_)

	return GAME_SERVER_RESULT_SUCCESS, table_id_, chair_id_
end

-- 站起
function base_room_manager:stand_up(player)
	print("base_room_manager:stand_up")
	if not player.room_id then
		return GAME_SERVER_RESULT_OUT_ROOM
	end

	if not player.table_id then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end

	if not player.chair_id then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end

	local room = self:find_room(player.room_id)
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

	return GAME_SERVER_RESULT_SUCCESS, tableid, chairid
end

-- 找一个被动机器人位置
function base_room_manager:find_android_pos(room_id)
	local room = self:find_room(room_id)
	if not room then
		return nil
	end

	local isplayer = false
	local tableid, chairid
	for i,tb in ipairs(room:get_table_list()) do
		for j,chair in ipairs(tb:get_player_list()) do
			if chair == true then
				if isplayer then
					return i, j
				else
					isplayer = true
					tableid = i
					chairid = j
				end
			elseif chair.is_player then
				if tableid and chairid then
					return tableid, chairid
				end
				isplayer = true
			end
		end
	end

	return nil
end

-- 心跳
function base_room_manager:tick()
	for i,v in ipairs(self.room_list_) do
		for _,tb in ipairs(v:get_table_list()) do
			tb:tick()
		end
	end

end
function base_room_manager:get_suitable_table(room,player,bool_change_table)
	local player_count = -1
	local suitable_table = nil
	local chair_id = nil
	local table_id = nil
	for j,tb in ipairs(room:get_table_list()) do
		if suitable_table == nil or (suitable_table ~= nil and suitable_table:get_player_count() < tb:get_player_count()) then
			for k,chair in ipairs(tb:get_player_list()) do
				if (bool_change_table and player.table_id ~= tb.table_id_) or (not bool_change_table) then
					if chair == false and tb:canEnter(player) then
						local tmp_player_count = tb:get_player_count()	
						if player_count < tmp_player_count then
							player_count = tmp_player_count	
							suitable_table = tb
							chair_id = k
							table_id = j
							break
						end
					end
				end
			end
		end
		
		if tb:get_player_count() > 0 then
			--log_warning(string.format("table pcount %d, table_id is %d",tb:get_player_count(),j))
		end
	end	
	
	--log_warning(string.format("final, room pcount %d,suitable_table table_id is %d, chair_id is %d,player_count is %d",
	--room.cur_player_count_,table_id,chair_id,suitable_table:get_player_count()))
	return suitable_table,chair_id,table_id
end
function base_room_manager:change_table(player)
	print("======================base_room_manager:change_table")
	-- body
	if player.disable == 1 then
		print("change_table player is Freeaz forced_exit")
		return GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	local tb = self:find_table_by_player(player)
	if tb then
		local room = self:find_room_by_player(player)
		if room then	
			local tb,k,j = self:get_suitable_table(room,player,true)
			if tb then
				--离开当前桌子
				local result_, table_id_, chair_id_  = self:stand_up(player)
				player:on_stand_up(table_id_, chair_id_, result_)
				-- 通知消息
				local notify = {
					table_id = j,
					pb_visual_info = {
					chair_id = k,
					guid = player.guid,
					account = player.account,
					nickname = player.nickname,
					level = player:get_level(),
					money = player:get_money(),
					header_icon = player:get_header_icon(),
					ip_area = player.ip_area,
					}
				}
					
				print("ip_area--------------------A",  player.ip_area)
				print("ip_area--------------------B",  notify.pb_visual_info.ip_area)
				tb:foreach(function (p)
					p:on_notify_sit_down(notify)
				end)
				--在新桌子坐下
				tb:player_sit_down(player,k)
				player:change_table(player.room_id, j, k, GAME_SERVER_RESULT_SUCCESS, tb)
				self:get_table_players_status(player)
				return
			end	
		else
			print("not in room")
		end
	else
		print("no find tb")
	end
end


function base_room_manager:change_tax(tax, tax_show, tax_open)
	print("======================base_room_manager:change_tax")
	tax_ = tax * 0.01
	for i , v in pairs (self.room_list_) do		
		print (tax_, tax_show, tax_open)
		v.tax_show_ = tax_show -- 是否显示税收信息
		v.tax_open_ = tax_open -- 是否开启税收
		v.tax_ = tax_
	end
end
