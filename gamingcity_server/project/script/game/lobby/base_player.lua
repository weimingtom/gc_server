-- game player

local pb = require "protobuf"

require "game/lobby/base_character"
require "game/lobby/base_android"
local base_active_android = base_active_android

require "data/item_details_table"
local item_details_table = item_details_table

require "game/net_func"
local send2client_pb = send2client_pb
local send2redis_pb = send2redis_pb

require "redis_opt"
local redis_command = redis_command
local redis_cmd_query = redis_cmd_query


local Set_GameTimes = Set_GameTimes
local def_game_id = def_game_id
local IncPlayTimes = IncPlayTimes
local judgePlayTimes = judgePlayTimes
local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type

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
local LOG_MONEY_OPT_TYPE_LAND = pb.enum_id("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_LAND")

local ChangMoney_Success = pb.enum_id("ChangeMoneyRecode", "ChangMoney_Success")
local ChangMoney_NotEnoughMoney = pb.enum_id("ChangeMoneyRecode", "ChangMoney_NotEnoughMoney")

-- enum ITEM_PRICE_TYPE 
local ITEM_PRICE_TYPE_GOLD = pb.enum_id("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")

-- enum ITEM_TYPE 
local ITEM_TYPE_MONEY = pb.enum_id("ITEM_TYPE", "ITEM_TYPE_MONEY")
local ITEM_TYPE_BOX = pb.enum_id("ITEM_TYPE", "ITEM_TYPE_BOX")

-- enum LOG_MONEY_OPT_TYPE
local LOG_MONEY_OPT_TYPE_BOX = pb.enum_id("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_BOX")

local def_game_id = def_game_id

g_init_player_ = g_init_player_ or {}
g_accout_player_ = g_accout_player_ or {}

local init_player_ = g_init_player_
local accout_player_ = g_accout_player_

-- 玩家
if not base_player then
	base_player = base_character:new()
	base_player.player_count = 0
end

-- 更新游戏服务器人数
function base_player:UpdateGamePlayerCount()
	--redis_command(string.format("HSET game_server_online_count %d %d", def_game_id, self.player_count))
	broadcast_player_count(self.player_count)
end

-- 初始化
function base_player:init(guid_, account_, nickname_)
	base_character.init(self, guid_, account_, nickname_)
	self.online = true
	self.is_player = true
	self.in_game = true

	init_player_[guid_] = self
	accout_player_[account_] = self
	
	self.player_count = self.player_count + 1
	self:UpdateGamePlayerCount()
end

-- 删除
function base_player:del()
	accout_player_[self.account] = nil
	init_player_[self.guid] = nil
	
	self.player_count = self.player_count - 1
	self:UpdateGamePlayerCount()
end

-- 注册账号
function base_player:reset_account(account_, nickname_)
	accout_player_[self.account] = nil
	self.account = account_
	self.nickname = nickname_
	accout_player_[account_] = self
end

-- 检查房间限制
function base_player:check_room_limit(score)
	if not self.pb_base_info then
		return false
	end
	return self.pb_base_info.money < score
end

-- 进入房间并坐下
function base_player:on_enter_room_and_sit_down(room_id_, table_id_, chair_id_, result_, tb)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		local notify = {
			room_id = room_id_,
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
			ip_area = self.ip_area,
		}
		tb:foreach_except(chair_id_, function (p)
			local v = {
				chair_id = p.chair_id,
				guid = p.guid,
				account = p.account,
				nickname = p.nickname,
				level = p:get_level(),
				money = p:get_money(),
				header_icon = p:get_header_icon(),
				ip_area = p.ip_area,
			}
			notify.pb_visual_info = notify.pb_visual_info or {}
			table.insert(notify.pb_visual_info, v)
		end)
		
		send2client_pb(self, "SC_EnterRoomAndSitDown", notify)
	else
		send2client_pb(self, "SC_EnterRoomAndSitDown", {
			result = result_,
			})
	end
end

function base_player:change_table( room_id_, table_id_, chair_id_, result_, tb )
	print("===========base_player:change_table")
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		local notify = {
			room_id = room_id_,
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
		}
		tb:foreach_except(chair_id_, function (p)
			local v = {
				chair_id = p.chair_id,
				guid = p.guid,
				account = p.account,
				nickname = p.nickname,
				level = p:get_level(),
				money = p:get_money(),
				header_icon = p:get_header_icon(),
				ip_area = p.ip_area,
			}
			notify.pb_visual_info = notify.pb_visual_info or {}
			table.insert(notify.pb_visual_info, v)
		end)
		
		send2client_pb(self, "SC_ChangeTable", notify)
	else
		send2client_pb(self, "SC_ChangeTable", {
			result = result_,
			})
	end
end

-- 站起并离开房间
function base_player:on_stand_up_and_exit_room(room_id_, table_id_, chair_id_, result_)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		print("send SC_StandUpAndExitRoom :"..result_)
		send2client_pb(self, "SC_StandUpAndExitRoom", {
			room_id = room_id_,
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
			})

		-- 更新在线信息
		send2db_pb("SD_OnlineAccount", {
			guid = self.guid,
			first_game_type = def_first_game_type,
			second_game_type = def_second_game_type,
			gamer_id = def_game_id,
			})
	else
		print("send SC_StandUpAndExitRoom nil"..result_)
		send2client_pb(self, "SC_StandUpAndExitRoom", {
			result = result_,
			})
	end
end

-- 切换座位
function base_player:on_change_chair(table_id_, chair_id_, result_, tb)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		local notify = {
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
			ip_area = self.ip_area,
		}
		tb:foreach_except(chair_id_, function (p)
			local v = {
				chair_id = p.chair_id,
				guid = p.guid,
				account = p.account,
				nickname = p.nickname,
				level = p:get_level(),
				money = p:get_money(),
				header_icon = p:get_header_icon(),
				ip_area = p.ip_area,
			}
			notify.pb_visual_info = notify.pb_visual_info or {}
			table.insert(notify.pb_visual_info, v)
		end)
		
		send2client_pb(self, "SC_ChangeChair", notify)
	else
		send2client_pb(self, "SC_ChangeChair", {
			result = result_,
			})
	end
end

-- 进入房间
function base_player:on_enter_room(room_id_, result_)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		send2client_pb(self, "SC_EnterRoom", {
			room_id = room_id_,
			result = result_,
			})
	else
		send2client_pb(self, "SC_EnterRoom", {
			result = result_,
			})
	end
end

-- 通知进入房间
function base_player:on_notify_enter_room(notify)
	send2client_pb(self, "SC_NotifyEnterRoom", notify)
end

-- 离开房间
function base_player:on_exit_room(room_id_, result_)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		send2client_pb(self, "SC_ExitRoom", {
			room_id = room_id_,
			result = result_,
		})
	else
		send2client_pb(self, "SC_ExitRoom", {
			result = result_,
		})
	end
end

-- 通知离开房间
function base_player:on_notify_exit_room(notify)
	send2client_pb(self, "SC_NotifyExitRoom", notify)
end

-- 坐下
function base_player:on_sit_down(table_id_, chair_id_, result_)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		send2client_pb(self, "SC_SitDown", {
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
			})
	else
		send2client_pb(self, "SC_SitDown", {
			result = result_,
			})
	end

	return result_
end

-- 通知坐下
function base_player:on_notify_sit_down(notify)	
	log_info(string.format("on_notify_sit_down ip_area =%s", notify.pb_visual_info.ip_area))
	send2client_pb(self, "SC_NotifySitDown", notify)
end

-- 站起
function base_player:on_stand_up(table_id_, chair_id_, result_)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		print("=========base_player:on_stand_up true")
		send2client_pb(self, "SC_StandUp", {
			table_id = table_id_,
			chair_id = chair_id_,
			result = result_,
			})
	else
		print("=========base_player:on_stand_up false")
		send2client_pb(self, "SC_StandUp", {
			result = result_,
			})
	end
end

-- 通知站起
function base_player:on_notify_stand_up(notify)
	send2client_pb(self, "SC_NotifyStandUp", notify)
end

-- 通知空位置坐机器人
function base_player:on_notify_android_sit_down(room_id_, table_id_, chair_id_)
	local a = base_active_android:find_active_android(room_id_)
	if a then
		a:think_on_sit_down(room_id_, table_id_, chair_id_) 
	end
end



--------------------------------------------------------------
-- 以上继承于base_character
--------------------------------------------------------------



-- 得到玩家数量
function base_player:get_count()
	return self.player_count
end

-- 查找
function base_player:find(guid)
	return init_player_[guid]
end
function base_player:find_by_account(account)
	return accout_player_[account]
end

-- 遍历
function base_player:foreach(func)
	for _, player in pairs(init_player_) do
		func(player)
	end
end

-- 广播所有人消息
function base_player:broadcast2client_pb(msg_name, pb)
	for _, player in pairs(init_player_) do
		send2client_pb(player, msg_name, pb)
	end
end

-- 玩家存档发送到db
function base_player:save()
	--if self.flag_save_db or self.flag_base_info or self.flag_item_bag then
	if self.flag_base_info then
		self.flag_base_info = false
		send2db_pb("SD_SavePlayerData", {
			guid = self.guid,
			pb_base_info = self.pb_base_info,
		})
	end
end
-- 设置玩家读取信息
--function base_player:SetMsgReadFlag(msg)
--	if self.msg_data_info then
--		for _,datainfo in ipairs(self.msg_data_info) do
--			if datainfo.msg_type == msg.msg_type and datainfo.id == msg.id then
--				datainfo.is_read = 2
--				local msg = {
--					pb_msg_data_info = self.msg_data_info,
--				}
--				--redis_command(string.format("HSET player_Msg_info %d %s", self.guid, to_hex(pb.encode("Msg_Data", msg))))
--				return true
--			end
--		end
--	end
--	return false
--end
-- 公告

function base_player:getinfo()


end
function base_player:updateNoticeEverone(msg)
	-- body
	for _,player in pairs(init_player_) do
		player:updateNotice(msg)
	end
	-- 通知服务器 消息发送完成
	--print("send SL_NewNotice =====================")
	--send2login_pb("SL_NewNotice",{ retID = msg.retID })
end
-- 公告或消息
function base_player:updateNotice(msg)
	-- body
	print("updateNotice=====================:"..self.guid)
	if msg.msg_type == 3 then
		
		local notify = {
			id = msg.id,
			content = msg.content,
			start_time = msg.start_time,
			end_time = msg.end_time,
			number = msg.number,
			interval_time = msg.interval_time,
		}

		local msg_data = {
			pb_msg_data = {},
		}
		table.insert(msg_data.pb_msg_data,notify)
		
		send2client_pb(self,"SC_QueryPlayerMarquee",msg_data)
		return
	end

	--if self.msg_data_info then
		print("updateNotice-------------------------------1")
		-- 更新服务器数据
		local notify = {
			id = msg.id,
			is_read = msg.is_read,
			msg_type = msg.msg_type,
			content = msg.content,
			start_time = msg.start_time,
			end_time = msg.end_time,
		}
		--table.insert(self.msg_data_info,notify)
		--local msg = {
		--	pb_msg_data_info = self.msg_data_info,
		--}
		--更新redis
		--redis_command(string.format("HSET player_Msg_info %d %s", self.guid, to_hex(pb.encode("Msg_Data", msg))))
		--下发新数据
		local msg_data = {
			pb_msg_data = nil,
		}
		msg_data.pb_msg_data = {}
		table.insert(msg_data.pb_msg_data,notify)
		print("updateNotice-------------------------------2")
		send2client_pb(self,"SC_NewMsgData",msg_data)
		print("updateNotice-------------------------------3")
	--end
	print("updateNotice-------------------------------4")
end
-- 删除公告
function base_player:deleteNoticeEverone(msg)
	-- body
	for _,player in pairs(init_player_) do
		player:deleteNotice(msg)
	end
end
function base_player:deleteNotice(msg)
	-- body
	print("updateNotice=====================:"..self.guid)
	local notify = {
		msg_id = msg.msg_id,
		msg_type = msg.msg_type,
	}
	send2client_pb(self,"SC_DeletMsg",msg_data)
end
--function base_player:UpdateMsg( ... )
--	-- body
--	-- 公告及消息
--	redis_cmd_query(string.format("HGET player_Msg_info %d",self.guid),function (reply)
--		-- body
--		if reply:is_string() then
--			local data = pb.decode("Msg_Data", from_hex(reply:get_string()))
--			self.msg_data_info = data.pb_msg_data_info
--			--更新客服端有另外的流程这里只更新游戏服务器
--			--[[send2client_pb(player,"SC_QueryPlayerMsgData",{
--				pb_msg_data = data.pb_msg_data_info
--			})]]
--		end
--	end)
--end
-- 玩家存档到redis
function base_player:save2redis()
	if self.flag_base_info then
		self.flag_base_info = false
		if self.pb_base_info then
			--redis_command(string.format("HSET player_base_info %d %s", self.guid, to_hex(pb.encode("PlayerBaseInfo", self.pb_base_info))))
		end
		self.flag_save_db = true
	end
	
	--[[if self.flag_item_bag then
		self.flag_item_bag = false
		if self.pb_item_bag then
			redis_command(string.format("HSET player_bag_info %d %s", self.guid, to_hex(pb.encode("ItemBagInfo", self.pb_item_bag))))
		end
		self.flag_save_db = true
	end]]--
end
function base_player:save_all()
	for _, player in pairs(init_player_) do
		player:save()
	end
end

-- 得到等级
function base_player:get_level()
	if not self.pb_base_info then
		return 0
	end
	return self.pb_base_info.level
end

-- 得到钱
function base_player:get_money()
	if not self.pb_base_info then
		return 0
	end
	return self.pb_base_info.money
end

-- 得到头像
function base_player:get_header_icon()
	return self.pb_base_info.header_icon
end

-- 花钱
function base_player:cost_money(price, opttype, bRet)
	log_info ("cost_money begin player :"..  self.guid)
	--print("base_player:cost_money :"..self.chair_id)
	local money = self.pb_base_info.money
	local oldmoney = money
	local iRet = true
	for _, p in ipairs(price) do
		log_info(string.format("money_type[%d]  money[%d]" , p.money_type, p.money))
		if p.money_type == ITEM_PRICE_TYPE_GOLD then
			if p.money <= 0 or money < p.money then
				log_error("=====cost_money==============="..money.."=="..p.money)
				if money < p.money then
					money = p.money
				end
				iRet = false
				if bRet == nil  then
					return false
				end
			end
			log_info(string.format("money[%d] - p[%d]" , money,p.money))
			money = money - p.money
		end
	end

	self.pb_base_info.money = money
	self.flag_base_info = true
	
	local money_ = money
	send2client_pb(self, "SC_NotifyMoney", {
		opt_type = opttype,
		money = money_,
		change_money = money_-oldmoney,
		})

	send2db_pb("SD_LogMoney", {
			guid = self.guid,
			old_money = oldmoney,
			new_money = self.pb_base_info.money,
			old_bank = self.pb_base_info.bank,
			new_bank = self.pb_base_info.bank,
			opt_type = opttype,
		})
	log_info(string.format("cost_money  end oldmoney[%d] new_money[%d]" , oldmoney, self.pb_base_info.money))
	return iRet
end

-- 加钱
function base_player:add_money(price, opttype)
	--print("base_player:add_money :"..self.chair_id)
	local money = self.pb_base_info.money
	local oldmoney = money

	for _, p in ipairs(price) do
		if p.money_type == ITEM_PRICE_TYPE_GOLD then
			if p.money <= 0 then
				return false
			end
			
			--print(string.format("money[%d] + p[%d]" , money,p.money))
			money = money + p.money
		end
	end

	self.pb_base_info.money = money
	self.flag_base_info = true
	
	local money_ = money
	send2client_pb(self, "SC_NotifyMoney", {
		opt_type = opttype,
		money = money_,
		change_money = money_-oldmoney,
		})
	
	send2db_pb("SD_LogMoney", {
			guid = self.guid,
			old_money = oldmoney,
			new_money = self.pb_base_info.money,
			old_bank = self.pb_base_info.bank,
			new_bank = self.pb_base_info.bank,
			opt_type = opttype,
		})
	return true
end

-- 添加物品
function base_player:add_item(id, num)
	local item = item_details_table[id]
	if not item then
		log_error(string.format("guid[%d] item id[%d] not find in item details table", self.guid, id))
		return
	end
	
	if item.item_type == ITEM_TYPE_MONEY then
		local oldmoney = self.pb_base_info.money
		self.pb_base_info.money = self.pb_base_info.money + num
		self.flag_base_info = true
		
		-- 收益
		send2db_pb("SD_UpdateEarnings", {
			guid = self.guid,
			money = num,
		})

		-- log
		send2db_pb("SD_LogMoney", {
			guid = self.guid,
			old_money = oldmoney,
			new_money = self.pb_base_info.money,
			old_bank = self.pb_base_info.bank,
			new_bank = self.pb_base_info.bank,
			opt_type = LOG_MONEY_OPT_TYPE_BOX,
		})
		return
	end
	
	self.pb_item_bag = self.pb_item_bag or {}
	self.pb_item_bag.items = self.pb_item_bag.items or {}
	for _, item in ipairs(self.pb_item_bag.items) do
		if item.item_id == id then
			item.item_num = item.item_num + num
			self.flag_item_bag = true
			return
		end
	end
	
	table.insert(self.pb_item_bag.items, {item_id = id, item_num = num})
	self.flag_item_bag = true
end

-- 删除物品
function base_player:del_item(id, num)
	if self.pb_item_bag and self.pb_item_bag.items then
		for i, item in ipairs(self.pb_item_bag.items) do
			if item.item_id == id and item.item_num >= num then
				if item.item_num == num then
					table.remove(self.pb_item_bag.items, i)
				else
					item.item_num = item.item_num - num
				end
				
				self.flag_item_bag = true
				return true
			end
		end
	end
	
	return false
end

-- 使用物品
function base_player:use_item(id, num)
	if self.pb_item_bag and self.pb_item_bag.items then
		for i, item in ipairs(self.pb_item_bag.items) do
			if item.item_id == id and item.item_num >= num then
				if item.item_num == num then
					table.remove(self.pb_item_bag.items, i)
				else
					item.item_num = item.item_num - num
				end
				
				self.flag_item_bag = true
				
				local itemdetail = item_details_table[id]
				if itemdetail.item_type == ITEM_TYPE_BOX then
					for _, v in ipairs(itemdetail.sub_item) do
						self:add_item(v.item_id, v.item_num * num)
					end
				end
				
				return true
			end
		end
	end
	
	return false
end

function base_player:setStatus(is_onLine)
	-- body
	if is_onLine then
	-- 掉线
		print("set online false")
		self.online = false
	else
	-- 强退
		print("set online true")
		self.online = true
	end
end

-- c修改银行钱
function  base_player:changeBankMoney( value )
	-- body
	local bank = self.pb_base_info.bank
	if value < 0 then
		if bank + value < 0 then
			return ChangMoney_NotEnoughMoney
		end
	end	
	self.pb_base_info.bank = bank + value
	return ChangMoney_Success,bank,self.pb_base_info.bank
end
--修改银行钱
function base_player:change_bank(value, opttype, is_savedb, bReturn)
	log_info(string.format("change_money  player[%d] begin value[%d] opttype[%d]" , self.guid, value, opttype))
	local bank = self.pb_base_info.bank
	local oldbank = bank
	local bRet = true

	if(value < 0) then
		local tempMoney = bank + value
		if(tempMoney < 0) then
			log_error("-------------------------------"..bank .."--" ..value)
			value = bank
			bRet = false
			if bReturn == nil then
				return false
			end
		end
	end


	self.pb_base_info.bank = bank + value
	self.flag_base_info = true
	
	local bank_ = self.pb_base_info.bank
	send2client_pb(self, "SC_NotifyBank", {
		opt_type = opttype,
		bank = bank_,
		change_bank = bank_ - oldbank,
		})
	
	log_info("opttype--------------".. opttype)
	send2db_pb("SD_LogMoney", {
			guid = self.guid,
			old_money = self.pb_base_info.money,
			new_money = self.pb_base_info.money,
			old_bank =  oldbank,
			new_bank = self.pb_base_info.bank,
			opt_type = opttype,
		})

	if is_savedb then
		send2db_pb("SD_SavePlayerBank", {
			guid = self.guid,
			bank = bank_,
		})
	end
	log_info(string.format("change_bank  end oldbank[%d] new_bank[%d]" , oldbank, self.pb_base_info.bank))
	return bRet
end
-- 修改身上钱
function base_player:change_money(value, opttype, is_savedb, bReturn)	
	log_info(string.format("change_money  player[%d] begin value[%d] opttype[%d]" , self.guid, value, opttype))
	local money = self.pb_base_info.money
	local oldmoney = money
	local bRet = true
	if(value < 0) then
		local tempMoney = money + value
		if(tempMoney < 0) then
			log_error("-------------------------------"..money .."--" ..value)
			value = money
			bRet = false
			if bReturn == nil  then
				return false
			end
		end
	end

	log_info ("old money is :"..self.pb_base_info.money)
	self.pb_base_info.money = money + value
	log_info ("money is :"..self.pb_base_info.money)
	self.flag_base_info = true
	
	local money_ = self.pb_base_info.money 
	send2client_pb(self, "SC_NotifyMoney", {
		opt_type = opttype,
		money = money_,
		change_money = money_ - oldmoney,
		})
	log_info("opttype--------------".. opttype)
	send2db_pb("SD_LogMoney", {
			guid = self.guid,
			old_money = oldmoney,
			new_money = self.pb_base_info.money,
			old_bank =  self.pb_base_info.bank,
			new_bank = self.pb_base_info.bank,
			opt_type = opttype,
		})
	if is_savedb then
		send2db_pb("SD_SavePlayerMoney", {
			guid = self.guid,
			money = money_,
		})
	end
	log_info(string.format("change_money  end oldmoney[%d] new_money[%d]" , oldmoney, self.pb_base_info.money))
	return bRet
end

-- 2017-02-17 by rocky add玩家每局百人牛牛信息存档发送到db
function base_player:player_save_ox_data(player_info)

	send2db_pb("SD_SavePlayerOxData", {
		guid = player_info.guid,
		is_android = player_info.is_android,
		table_id = player_info.table_id,
		banker_id = player_info.banker_id,
		nickname = player_info.nickname,
		money = player_info.money,
		win_money = player_info.win_money,
		bet_money = player_info.bet_money,
		tax = player_info.tax,
		curtime = player_info.curtime,
	})
	
end

--记录游戏对手
function base_player:SetPlayerIpContrl(player_list)
	-- body
	print("==================SetPlayerIpContrl")
	local gametype = string.format("%d_%d",def_first_game_type,def_second_game_type)
	for _,v in ipairs(player_list) do
		if v.guid ~= self.guid then
			Set_GameTimes(gametype,self.guid,v.guid,true)
		end
	end
end
--增加游戏场数
function base_player:IncPlayTimes()
	-- body
	print("==================IncPlayTimes")
	local gametype = string.format("%d_%d",def_first_game_type,def_second_game_type)
	IncPlayTimes(gametype,self.guid,true)
end
--判断游戏场次 judgePlayTimes
function base_player:judgePlayTimes(other,GameLimitCdTime)
	-- body
	print("==================judgePlayTimes")
	local gametype = string.format("%d_%d",def_first_game_type,def_second_game_type)
	if judgePlayTimes(gametype,self.guid,other.guid,GameLimitCdTime,true) then
		print(string.format("%d : %d judgePlayTimes is true",self.guid,other.guid))
		return true
	else
		print(string.format("%d : %d judgePlayTimes is false",self.guid,other.guid))
		return false
	end
end
--判断游戏IP
function  base_player:judgeIP(player)
	-- body
	firstip = self:GetIP()
	secondip = self:GetIP(player)
	print(string.format("[%s] [%s]",firstip,secondip))
	return firstip == secondip
end

function base_player:GetIP(player)	
	-- body
	local str = self.ip
	if player then
		str = player.ip
	end
	local ts = string.reverse(str)
	_,i = string.find(ts,"%p")
	m = string.len(ts) - i
	return string.sub(str, 1, m)
end