-- 桌子基类

local pb = require "protobuf"

require "game/net_func"
local get_msg_id_str = get_msg_id_str
local send2client_pb_str = send2client_pb_str
local send2client_pb = send2client_pb
local def_game_id = def_game_id
local def_game_name = def_game_name

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
local GAME_READY_MODE_NONE = pb.enum_id("GAME_READY_MODE", "GAME_READY_MODE_NONE")
local GAME_READY_MODE_ALL = pb.enum_id("GAME_READY_MODE", "GAME_READY_MODE_ALL")
local GAME_READY_MODE_PART = pb.enum_id("GAME_READY_MODE", "GAME_READY_MODE_PART")


base_table = {}
-- 创建
function base_table:new()  
    local o = {}  
    setmetatable(o, {__index = self})
	
    return o 
end

-- 获取当前游戏ID
function base_table:get_now_game_id()
	local guid = string.format([[%03d%03d%04d%s%07d]], def_game_id, self.room_.id, self.table_id_, self.ID_date_,self.table_gameid)
	print(guid)
	return guid
end
-- 刷新游戏ID到下一个
function base_table:next_game()
	self.ID_date_ = os.date("%y%m%d%H%M")
	self.table_gameid = self.table_gameid + 1
end
function base_table:startsaveInfo()
	-- body
	for _,v in ipairs(self.player_list_) do
		-- 添加游戏场次
		v:IncPlayTimes()
		-- 记录对手
		v:SetPlayerIpContrl(self.player_list_)
	end

end
function base_table:canEnter(player)
	-- body
	print("base_table:canEnter")
	return true
end
-- 初始化
function base_table:init(room, table_id, chair_count)
	self.table_gameid = 1
	self.room_ = room
	self.table_id_ = table_id
	self.def_game_name = def_game_name
	self.def_game_id = def_game_id
	self.player_list_ = {}
	self.player_guid_list_ = {}
	self.ID_date_ = os.date("%y%m%d%H%M")

	self.configid_ = room.configid_

	self.tax_show_ = room.tax_show_ -- 是否显示税收信息
	self.tax_open_ = room.tax_open_ -- 是否开启税收
	self.tax_ = room.tax_ 

	self.room_limit_ = room.room_limit_ -- 房间分限制
	self.cell_score_ = room.cell_score_ -- 底注

	for i = 1, chair_count do
		--print(string.format("set player_list_[%d] is false",i))
		self.player_list_[i] = false
	end
	if room:get_ready_mode() ~= GAME_READY_MODE_NONE then
		self.ready_list_ = {}
		for i = 1, chair_count do
			self.ready_list_[i] = false
		end
	end

	self.notify_msg = {}
	if self.tax_show_ == 1 then 
		self.notify_msg.flag = 3
	else
		self.notify_msg.flag = 4
	end	
end

function base_table:isPlay( ... )
	print("base_table:isPlay")
	-- body
	return false
end

function base_table:load_lua_cfg( ... )
	print("base_table:load_lua_cfg")
	-- body
	return false
end

-- 得到玩家
function base_table:get_player(chair_id)
	if not chair_id then
		return nil
	end
	return self.player_list_[chair_id]
end

-- 设置玩家
function base_table:set_player(chair_id, player)
	self.player_list_[chair_id] = player
	if player then
		self.player_guid_list_[chair_id] = player.guid
	else
		self.player_guid_list_[chair_id] = false
	end
end

-- 得到玩家列表
function base_table:get_player_list()
	return self.player_list_
end

--用户数量
function base_table:get_player_count()
	local count = 0
	for k,chair in pairs(self.player_list_) do
		if chair then
			count = count + 1
		end
	end
	return count
end

-- 遍历桌子
function base_table:foreach(func)
	for i, p in pairs(self.player_list_) do
		if p then
			func(p)
		end
	end
end
function base_table:foreach_except(except, func)
	for i, p in pairs(self.player_list_) do
		if p and i ~= except then 
			func(p)
		end
	end
end
function  base_table:Save_Game_Log(s_playid,s_playType,s_log,s_starttime,s_endtime)
	-- body
	print("==============================base_table:Save_Game_Log")
	local nMsg = {
		playid = s_playid,
		type = s_playType,
		log = s_log,
		starttime = s_starttime,
		endtime = s_endtime,
	}
	send2db_pb("SL_Log_Game",nMsg)
end
function base_table:PlayerMoneyLog(player,s_type,s_old_money,s_tax,s_change_money,s_id)
	-- body
	print("==============================base_table:PlayerMoneyLog")
	local nMsg = {
		guid = player.guid,
		type = s_type,
		gameid = self.def_game_id,
		game_name = self.def_game_name,
		phone_type = player.phone_type,
		old_money = s_old_money,
		new_money = player.pb_base_info.money,
		tax = s_tax,
		change_money = s_change_money,
		ip = player.ip,
		id = s_id,
		channel_id = player.create_channel_id,
	}
	send2db_pb("SL_Log_Money",nMsg)
	send2client_pb(player,"SC_Gamefinish",{
		money = player.pb_base_info.money
	})
end

function base_table:RobotMoneyLog(robot,banker_flag,winorlose,old_money,tax,money_change,table_id)
	print("==============================base_table:RobotMoneyLog")
	local nMsg = {
		guid = robot.guid,
		isbanker = banker_flag,
		winorlose = winorlose,
		gameid = self.def_game_id,
		game_name = self.def_game_name,
		old_money = old_money,
		new_money = robot.money,
		tax = tax,
		money_change = money_change,
		id = table_id,
	}
	send2db_pb("SL_Log_Robot_Money",nMsg)
end

--渠道税收分成
function base_table:ChannelInviteTaxes(channel_id_p,guid_p,guid_invite_p,tax_p)
	print("ChannelInviteTaxes channel_id:" .. channel_id_p .. " guid:" .. guid_p .. " guid_invite:" .. tostring(guid_invite_p) .. " tax:" .. tax_p)
	if tax_p == 0 or guid_invite_p == nil or guid_invite_p == 0 then
		return
	end
	local cfg = channel_invite_cfg(channel_id_p)
	if cfg and cfg.is_invite_open == 1 then
		print("ChannelInviteTaxes step 2--------------------------------")
		local nMsg = {
			channel_id = channel_id_p,
			guid = guid_p,--贡献者
			guid_invite = guid_invite_p,--受益者
			val = math.floor(tax_p*cfg.tax_rate/100)
		}
		send2db_pb("SL_Channel_Invite_Tax",nMsg)
	end
end

function base_table:PlayerMoneyLogNoPlayer(guid, phone_type,money, ip, s_type,s_old_money,s_tax,s_change_money,s_id,channel_id)
	-- body
	print("==============================base_table:PlayerMoneyLog")
	local nMsg = {
		guid = guid,
		type = s_type,
		gameid = self.def_game_id,
		game_name = self.def_game_name,
		phone_type = phone_type,
		old_money = s_old_money,
		new_money = money,
		tax = s_tax,
		change_money = s_change_money,
		ip = ip,
		id = s_id,
		channel_id = channel_id,
	}
	send2db_pb("SL_Log_Money",nMsg)
end

-- 广播桌子中所有人消息
function base_table:broadcast2client(msg_name, pb)
	--print("send msg :"..msg_name)
	local id, msg = get_msg_id_str(msg_name, pb)
	for i, p in pairs(self.player_list_) do
		if not p or p.noready == true then
			--print("p is nil:"..i)
		else
			if p.online and p.in_game then
				send2client_pb_str(p, id, msg)
			else
				if p.is_player == false then --非玩家(机器人)
					-- do nothing
				else
					print("p offline :"..p.chair_id)
				end
			end
		end
	end
end
function base_table:broadcast2client_except(except, msg_name, pb)
	local id, msg = get_msg_id_str(msg_name, pb)
	for i, p in ipairs(self.player_list_) do
		if p and i ~= except then
			send2client_pb_str(p, id, msg)
		end
	end
end

-- 玩家坐下
function base_table:player_sit_down(player, chair_id_)
	player.table_id = self.table_id_
	player.chair_id = chair_id_
	self.player_list_[chair_id_] = player
	log_info(string.format("GameInOutLog,base_table:player_sit_down, guid %s, table_id %s, chair_id %s",
	tostring(player.guid),tostring(player.table_id),tostring(player.chair_id)))
	if player.is_player then
		for i, p in ipairs(self.player_list_) do
			if p == false then
				-- 主动机器人坐下
				player:on_notify_android_sit_down(player.room_id, self.table_id_, i)
			end
		end
	end
end
--处理掉线玩家
function base_table:playeroffline(player)
	-- body
	print("base_table:playeroffline")
	player.in_game = false
end
-- 玩家站起
function base_table:player_stand_up(player, is_offline)
	log_info(string.format("GameInOutLog,base_table:player_stand_up, guid %s, table_id %s, chair_id %s, is_offline %s",
	tostring(player.guid),tostring(player.table_id),tostring(player.chair_id),tostring(is_offline)))

	print("base_table:player_stand_up")
	if is_offline then
		print ("is_offline is true")
	else
		print ("is_offline is false")
	end
	if self:check_cancel_ready(player, is_offline) then
		print("base_table:player_stand_up set nil ")
		local chairid = player.chair_id
		print(string.format("set player_list_[%d] is false",chairid))
		self.player_list_[chairid] = false
		player.table_id = nil
		player.chair_id = nil

		if self.ready_list_[chairid] then
			self.ready_list_[chairid] = false
			local notify = {
				ready_chair_id = chairid,
				is_ready = false,
			}
			self:broadcast2client("SC_Ready", notify)
		end

		return true
	end
	if is_offline then
		print("set player is_offline true")
		player.is_offline = true -- 掉线了
	end
	return false
end
function base_table:setTrusteeship(player)
	print("====================base_table:setTrusteeship")
end
-- 准备开始
function base_table:ready(player)
	if player.disable == 1 then
		--当玩家处理冻结状态时
		player:forced_exit()
		return
	end
	if not self:check_ready(player) then
		return
	end

	if not player.room_id then
		log_warning(string.format("guid[%d] not find in room", player.guid))
		return
	end
	if not player.table_id then
		log_warning(string.format("guid[%d] not find in table", player.guid))
		return
	end
	if not player.chair_id then
		log_warning(string.format("guid[%d] not find in chair_id", player.guid))
		return
	end

	local ready_mode = self.room_:get_ready_mode()
	if ready_mode == GAME_READY_MODE_NONE then
		log_warning(string.format("guid[%d] mode=GAME_READY_MODE_NONE", player.guid))
		return
	end
	if self.ready_list_[player.chair_id] ~= false then
		log_warning(string.format("chair_id[%d] ready error", player.chair_id))
		print(self.ready_list_[player.chair_id])
		return
	end

	print(string.format("set tableid [%d] chair_id[%d]  ready_list is true ",self.table_id_,player.chair_id))
	self.ready_list_[player.chair_id] = true
	
	-- 机器人准备
	self:foreach(function(p)
		if p.is_android and (not self.ready_list_[p.chair_id]) then
			self.ready_list_[p.chair_id] = true

			local notify = {
				ready_chair_id = p.chair_id,
				is_ready = true,
				}
			self:broadcast2client("SC_Ready", notify)
		end
	end)
	print("set Dropped false")
	player.Dropped = false
	-- 通知自己准备
	local notify = {
		ready_chair_id = player.chair_id,
		is_ready = true,
		}
	self:broadcast2client("SC_Ready", notify)

	self:check_start(false)
end
function base_table:ReconnectionPlayMsg(player)
	-- 重新上线
	print("---------base_table:ReconnectionPlayMsg-----------")
	print("set Dropped is false")
	player.Dropped = false
	print("set online is true")
	player.online = true
	player.in_game = true
end
-- 检查是否可准备
function base_table:check_ready(player)
	return true
end

-- 检查是否可取消准备
function base_table:check_cancel_ready(player, is_offline)
	if is_offline then
		--掉线 用于结算
		print("set Dropped true")
		player.Dropped = true
	end
	return self.room_:get_ready_mode() ~= GAME_READY_MODE_NONE
end

-- 检查开始
function base_table:check_start(part)
	local ready_mode = self.room_:get_ready_mode()
	if ready_mode == GAME_READY_MODE_PART then
		local n = 0
		for i, v in ipairs(self.player_list_) do
			if v then
				if self.ready_list_[i] then
					n = n+1
				else
					return
				end
			end
		end
		if n >= 2 then
			self:start(n)
		end
	end
	if part then
		return
	end

	if ready_mode == GAME_READY_MODE_ALL then
		local n =0
		for i,v in ipairs(self.ready_list_) do
			if not v then
				return
			end
			n = n +1
		end
		self:start(n)
	end
end
function base_table:send_playerinfo(player)
	return true  
end
-- 开始游戏
function base_table:start(player_count)
	--print("================================base_table:start")
	local bRet = false
	if self.configid_ ~= self.room_.configid_ then 
		print ("-------------configid:",self.configid_ ,self.room_.configid_)
		print (self.room_.tax_show_, self.room_.tax_open_ , self.room_.tax_)
		self.tax_show_ = self.room_.tax_show_ -- 是否显示税收信息
		self.tax_open_ = self.room_.tax_open_ -- 是否开启税收
		self.tax_ = self.room_.tax_ 
		self.room_limit_ = self.room_.room_limit_ -- 房间分限制
		self.cell_score_ = self.room_.cell_score_ -- 底注

		if self.tax_show_ == 1 then 
			self.notify_msg.flag = 3
		else
			self.notify_msg.flag = 4
		end	

		self.configid_ = self.room_.configid_ 

		bRet = true	
		print ("self.room_.lua_cfg_ --------" ,self.room_.lua_cfg_ )	
		if self.room_.lua_cfg_ ~= nil then
			self:load_lua_cfg()
		end
	end

	self:broadcast2client("SC_ShowTax", self.notify_msg)
	return bRet
end

-- 检查是否维护
function base_table:check_game_maintain()
	local iRet = false
	if game_switch == 1 then--游戏将进入维护阶段
		log_warning(string.format("All Game will maintain..game_switch=[%d].....................",game_switch))
		for i,v in pairs (self.player_list_) do
			if  v and v.is_player == true and v.vip ~= 100 then 
				send2client_pb(v, "SC_GameMaintain", {
				result = GAME_SERVER_RESULT_MAINTAIN,
				})
				v:forced_exit()
			end
		end
		iRet = true
	end
	return iRet
end

--准备玩家通知维护
function base_table:onNotifyReadyPlayerMaintain(player)
	local iRet = false
	if game_switch == 1 and player.vip ~= 100 then--游戏将进入维护阶段
		send2client_pb(player, "SC_GameMaintain", {
		result = GAME_SERVER_RESULT_MAINTAIN,
		})
		player:forced_exit()
		iRet = true
	end
	return iRet
end

-- 重新上线
function base_table:reconnect(player)
end

-- 清除准备
function base_table:clear_ready()
	for i,v in ipairs(self.ready_list_) do
		self.ready_list_[i] = false
	end
end

-- 心跳
function base_table:tick()
end