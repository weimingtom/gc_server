-- 斗地主逻辑
local pb = require "protobuf"

require "game/lobby/base_table"

require "game/net_func"
local send2client_pb = send2client_pb

require "game/land/land_cards"
local land_cards = land_cards

local offlinePunishment_flag = false

local LOG_MONEY_OPT_TYPE_LAND = pb.enum_id("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_LAND")
-- enum LAND_CARD_TYPE
local ITEM_PRICE_TYPE_GOLD = pb.enum_id("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")
local LAND_CARD_TYPE_SINGLE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_SINGLE")
local LAND_CARD_TYPE_DOUBLE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_DOUBLE")
local LAND_CARD_TYPE_THREE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE")
local LAND_CARD_TYPE_SINGLE_LINE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_SINGLE_LINE")
local LAND_CARD_TYPE_DOUBLE_LINE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_DOUBLE_LINE")
local LAND_CARD_TYPE_THREE_LINE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE_LINE")
local LAND_CARD_TYPE_THREE_TAKE_ONE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE_TAKE_ONE")
local LAND_CARD_TYPE_THREE_TAKE_TWO = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE_TAKE_TWO")
local LAND_CARD_TYPE_FOUR_TAKE_ONE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_FOUR_TAKE_ONE")
local LAND_CARD_TYPE_FOUR_TAKE_TWO = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_FOUR_TAKE_TWO")
local LAND_CARD_TYPE_BOMB = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_BOMB")
local LAND_CARD_TYPE_MISSILE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_MISSILE")

-- 斗地主人数
local LAND_PLAYER_COUNT = 3

-- 出牌时间
local LAND_TIME_OUT_CARD = 15
-- 叫分时间
local LAND_TIME_CALL_SCORE = 15
-- 首出时间
local LAND_TIME_HEAD_OUT_CARD = 15
-- 玩家掉线等待时间
local LAND_TIME_WAIT_OFFLINE = 30
-- ip限制等待时间
local LAND_TIME_IP_CONTROL = 20
-- ip限制开启人数
local LAND_IP_CONTROL_NUM = 20

-- 等待开始
local LAND_STATUS_FREE = 1
-- 叫分状态
local LAND_STATUS_CALL = 2
-- 游戏进行
local LAND_STATUS_PLAY = 3
-- 玩家掉线
local LAND_STATUS_PLAYOFFLINE = 4
-- 加倍阶段
local LAND_STATUS_DOUBLE = 5

--地主掉线基础倍数
local LAND_ESCAPE_SCORE_BASE = 10
--地主掉线低于基础倍数后的扣分倍数
local LAND_ESCAPE_SCORE_LESS = 10
--地主掉线高于基础倍数后的扣分 乘以倍数
local LAND_ESCAPE_SCORE_GREATER = 2
--农民掉线基础倍数
local FARMER_ESCAPE_SCORE_BASE = 10
--农民掉线低于基础倍数后的扣分倍数
local FARMER_ESCAPE_SCORE_LESS = 10
--农民掉线高于基础倍数后的扣分 乘以倍数
local FARMER_ESCAPE_SCORE_GREATER = 2

local LAND_TIME_OVER = 1000

land_table = base_table:new()

-- 初始化
function land_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)	
	self.callsore_time = 0
	self.status = LAND_STATUS_FREE
	self.land_player_cards = {}
	for i = 1, chair_count do
		self.land_player_cards[i] = land_cards:new()
	end

	self.cards = {}
	for i = 1, 54 do
		self.cards[i] = i - 1
	end
	self:clear_ready()
	self.GameLimitCdTime = self.room_.roomConfig.GameLimitCdTime
end

-- 检查是否可准备
function land_table:check_ready(player)
	if self.status ~= LAND_STATUS_FREE then
		return false
	end
	return true
end

-- 检查是否可取消准备
function land_table:check_cancel_ready(player, is_offline)
	base_table.check_cancel_ready(self,player,is_offline)
	player:setStatus(is_offline)
	if is_offline then
		--掉线
		if  self.status ~= LAND_STATUS_FREE then
			--掉线处理
			self:playeroffline(player)
			return false
		end
	end	
	--退出
	return true
end

-- 洗牌
function land_table:shuffle()
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	for i = 1, 27 do
		local x = math.random(54)
		local y = math.random(54)
		if x ~= y then
			self.cards[x], self.cards[y] = self.cards[y], self.cards[x]
		end
	end
	self.valid_card_idx = math.random(51)
end

function land_table:load_lua_cfg()
	print ("--------------------###############################load_lua_cfg", self.room_.lua_cfg_)
	local fucT = load(self.room_.lua_cfg_)
	local land_config = fucT()
	if land_config then
		if land_config.GameLimitCdTime then
			self.GameLimitCdTime = land_config.GameLimitCdTime
			print("#########GameLimitCdTime:"..self.GameLimitCdTime)
		end
	else
		print("land_config is nil")
	end
end

-- 开始游戏
function land_table:start()
	base_table.start(self)
	self.gamelog.start_game_time = get_second_time()
	self:shuffle()
	-- 发牌
	self.first_turn = math.floor((self.valid_card_idx-1)/17)+1
	self.callpoints_log = {
		start_time = get_second_time(),
		first_turn = self.first_turn,
		player_cards = {},
		callpoints_process = {},
		land_card = string.format("%d %d %d",self.cards[52], self.cards[53], self.cards[54]),
	}
	local msg = {
		valid_card_chair_id = self.valid_card_idx,
		valid_card = self.cards[self.valid_card_idx],
	}
	
	local cur = 0
	for i,v in ipairs(self.player_list_) do
		if v then
			local cards = {}
			for j = cur+1, cur+17 do
				table.insert(cards, self.cards[j])
			end
			cur = cur + 17
			table.sort(cards, function(a, b) return a < b end)
			v.outTime = 0
			v.isTrusteeship = false
			v.is_double = nil
			self.land_player_cards[v.chair_id]:init(cards)
			msg.cards = cards
			send2client_pb(v, "SC_LandStart", msg)
			log_info("----------------------")
			log_info("v.chair_id:" .. v.chair_id)
			log_info(table.concat(msg.cards, ','))

			----------- 日志相关
			local player_card = {
				chair_id = v.chair_id,
				guid = v.guid,
				cards = table.concat(msg.cards, ','),
			}
			table.insert(self.callpoints_log.player_cards,player_card)
		end
	end

	log_info("first call soure chairid : "..self.first_turn)
	self.cur_turn = self.first_turn
	self.cur_call_score = 0
	self.cur_call_score_chair_id = 0
	self.status = LAND_STATUS_CALL

	--add new 通知客服端叫分
	local notify = {
		cur_chair_id = self.cur_turn,
		call_chair_id = cur_chair_id,
		call_score = 0,
		}
	self:broadcast2client("SC_LandCallScore", notify)
	self.time0_ = get_second_time()
end
-- 发地主底牌
function land_table:send_land_cards(player)
	self:startsaveInfo()
	log_info("==========send_land_cards:"..self.cur_call_score_chair_id)
	self.flag_land = self.cur_call_score_chair_id
	self.flag_chuntian = true
	self.flag_fanchuntian = true
	self.time_outcard_ = LAND_TIME_HEAD_OUT_CARD
	self.cur_turn = self.cur_call_score_chair_id

	local cards_ = {self.cards[52], self.cards[53], self.cards[54]}
	self.landcards = cards_
	log_info(string.format("landcards [%s]",table.concat(cards_,",")))	
	log_info(string.format("befor landplayercards [%s]",table.concat(self.land_player_cards[self.cur_call_score_chair_id].cards_,",")))
	self.land_player_cards[self.cur_call_score_chair_id]:add_cards(cards_)
	log_info(string.format("after number [%d] landplayercards [%s]",#self.land_player_cards[self.cur_call_score_chair_id].cards_,table.concat(self.land_player_cards[self.cur_call_score_chair_id].cards_,",")))

	self.last_out_cards = nil
	self.Already_Out_Cards = {}
	local msg = {
		land_chair_id = self.first_turn,
		call_score = self.cur_call_score,
		cards = cards_,
		}
	self:broadcast2client("SC_LandInfo", msg)

	self.status = LAND_STATUS_DOUBLE
	self.time0_ = get_second_time()
	for i,v in ipairs(self.player_list_) do
		if v and v.chair_id == self.first_turn then
			v.is_double = false
			break
		end
	end
end
function land_table:status_double_finish()
	self.status = LAND_STATUS_PLAY
	self.time0_ = curtime

	local msg = {
		land_chair_id = self.first_turn
		}
	self:broadcast2client("SC_LandCallDoubleFinish", msg)

	--游戏开始
	self:startGame()
end
-- 加倍
function land_table:call_double(player,is_double)
	if self.status ~= LAND_STATUS_DOUBLE or self.first_turn == player.chair_id then
		return --地主不能加倍
	end
	log_info("call_double begin ----",tostring(is_double))
	player.is_double = is_double --is_double and true or false
	local notify = {
		call_chair_id = player.chair_id,
		is_double = 1
	}
	if is_double then notify.is_double = 2 end
	self:broadcast2client("SC_LandCallDouble", notify) -- SC_LandCallScorePlayerOffline
	log_info("SC_LandCallDouble call_double end ----",tostring(notify))
	local all_is_done = true
	for i,v in ipairs(self.player_list_) do
		if v and v.is_double == nil then
			all_is_done = false
			break
		end
	end
	if all_is_done then self:status_double_finish()	end
end

function land_table:startGame( ... )
	-- body
	-- 获取 牌局id
	log_info("gamestart =================================================")
	self.table_game_id = self:get_now_game_id()
	log_info(self.table_game_id)
	self:next_game()	
	log_info(self:get_now_game_id())
	-- 获取开始时间
	self.time0_ = get_second_time()
	self.start_time = self.time0_

	-- 记录日志
	table.insert(self.gamelog.CallPoints,self.callpoints_log)
	self.gamelog.landid = self.flag_land
	self.gamelog.land_cards = string.format("%s",table.concat(self.land_player_cards[self.flag_land].cards_,","))
	self.gamelog.table_game_id = self.table_game_id
	self.gamelog.start_game_time = self.time0_

	for i,v in ipairs(self.player_list_) do
		if v then
			local t_guid = v.guid or 0
			local t_room_id = v.room_id or 0
			local t_table_id = v.table_id or 0
			log_info(string.format("Player InOut Log,land_table:startGame player %s, table_id %s ,room_id %s,game_id %s",
			tostring(t_guid),tostring(t_table_id),tostring(t_room_id),tostring(self.table_game_id)))
		end
	end
end
function land_table:setTrusteeship(player,flag)
	-- body
	player.TrusteeshipTimes = 0
	player.isTrusteeship = not player.isTrusteeship
	log_info("chair_id:"..player.chair_id)
	if player.isTrusteeship then 
		log_info("**************:true")
		if self.cur_turn == player.chair_id then
			self:trusteeship(player)
		end
		if flag == true then
			player.finishOutGame = true
		end
	else
		log_info("**************:false")
		player.finishOutGame = false
	end
	local msg = {
		chair_id = player.chair_id,
		isTrusteeship = player.isTrusteeship,
		}
	self:broadcast2client("SC_LandTrusteeship", msg)
end
-- 叫分
function land_table:call_score(player, callscore)
	log_info("==========call_score")	
	if self.status ~= LAND_STATUS_CALL then
		log_warning(string.format("land_table:call_score guid[%d] status error", player.guid))
		return
	end

	if player.chair_id ~= self.cur_turn then
		log_warning(string.format("land_table:call_score guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_turn))
		return
	end

	if callscore < 0 or callscore > 3 then
		log_error(string.format("land_table:call_score guid[%d] score[%d] error", player.guid, callscore))
		return
	end

	if callscore > 0 and callscore <= self.cur_call_score then
		log_error(string.format("land_table:call_score guid[%d] score[%d] error, cur[%d]", player.guid, callscore, self.cur_call_score))
		return
	end
	-- 记录叫分 日志
	local call_log = {
		chair_id = player.chair_id,
		callscore = callscore,
		calltimes = self.callsore_time + 1,
	}	
	table.insert(self.callpoints_log.callpoints_process,call_log)


	log_info("callscore is :"..callscore)
	if callscore == 3 then
		local notify = {
			cur_chair_id = 0,
			call_chair_id = player.chair_id,
			call_score = callscore,
			}
		self:broadcast2client("SC_LandCallScore", notify)

		self.cur_call_score = callscore
		self.cur_call_score_chair_id = self.cur_turn
		self.first_turn = self.cur_turn
		self:send_land_cards(player)
		return
	end

	if callscore == 0 then
		--do nothing
	end
	if callscore > 0 then
		self.cur_call_score_chair_id = self.cur_turn
		self.cur_call_score = callscore
	end	

	if self.cur_turn == 3 then
		self.cur_turn = 1
	else
		self.cur_turn = self.cur_turn + 1
	end
	local notify = {
		cur_chair_id = self.cur_turn,
		call_chair_id = player.chair_id,
		call_score = callscore,
		}
	self:broadcast2client("SC_LandCallScore", notify)

	if self.first_turn == self.cur_turn then
		if self.cur_call_score > 0 then
			self.first_turn = self.cur_call_score_chair_id
			self:send_land_cards(player)
		else
			self.callsore_time = self.callsore_time + 1
			if self.callsore_time < 3 then
				self:broadcast2client("SC_LandCallFail")
				-- 重新洗牌 记录叫分日志
				table.insert(self.gamelog.CallPoints,self.callpoints_log)
				self:start() 
			else
				self.cur_call_score_chair_id = self.first_turn
				self.cur_call_score = 1
				self:send_land_cards(player)
			end
			return
		end
	end
	self.time0_ = get_second_time()
	self:Next_Player_Proc()
end

-- 出牌
function land_table:out_card(player, cardslist, flag)
	log_info("player:" .. player.chair_id)
	log_info(table.concat(cardslist,","))
	if self.status ~= LAND_STATUS_PLAY then
		log_warning(string.format("land_table:out_card guid[%d] status error", player.guid))
		return
	end

	if player.chair_id ~= self.cur_turn then
		log_warning(string.format("land_table:out_card guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_turn))
		return
	end

	local playercards = self.land_player_cards[player.chair_id]
	if not playercards:check_cards(cardslist) then
		log_error(string.format("land_table:out_card guid[%d] out cards[%s] error, has[%s]", player.guid, table.concat(cardslist, ','), table.concat(playercards.cards_, ',')))
		return
	end

	-- 排序
	if #cardslist > 1 then
		table.sort(cardslist, function(a, b) return a < b end)
	end

	local cardstype, cardsval = playercards:get_cards_type(cardslist)
	if not cardstype then
		log_error(string.format("land_table:out_card guid[%d] get_cards_type error, cards[%s]", player.guid, table.concat(cardslist, ',')))
		return
	end
	if cardstype == LAND_CARD_TYPE_SINGLE and cardslist[1] == 53 then
		cardsval = 14
	end
	local cur_out_cards = {cards_type = cardstype, cards_count = #cardslist, cards_val = cardsval}
	if not playercards:compare_cards(cur_out_cards, self.last_out_cards) then
		log_error(string.format("land_table:out_card guid[%d] compare_cards error, cards[%s], cur_out_cards[%d,%d,%d], last_out_cards[%d,%d,%d]", player.guid, table.concat(cardslist, ','), 
			cur_out_cards.cards_type , cur_out_cards.cards_count, cur_out_cards.cards_val,self.last_out_cards.cards_type,self.last_out_cards.cards_count,self.last_out_cards.cards_val))
		return
	end	

	if not flag or flag == false then
		player.TrusteeshipTimes = 0
	end

	-- 记录日志
	local outcard = {
		chair_id = player.chair_id,
		outcards = string.format("%s",table.concat(cardslist, ',')),
		sparecards = "",
		time = get_second_time(),
		isTrusteeship = player.isTrusteeship and 1 or 0,
	}

	self.last_out_cards = cur_out_cards
	self.last_cards = cardslist
	table.insert(self.Already_Out_Cards,cardslist)
	if self.flag_fanchuntian == true and self.cur_turn == self.flag_land and #self.land_player_cards[self.cur_turn].cards_ < 20 then
		self.flag_fanchuntian = false
	end

	if self.cur_turn ~= self.flag_land and self.flag_chuntian then
		self.flag_chuntian = false
	-- elseif self.time_outcard_ == LAND_TIME_OUT_CARD then
	-- 	self.flag_fanchuntian = false
	end
	if self.flag_chuntian == false and self.cur_turn == self.flag_land then
		-- 如果 春天没有的情况下 地主出牌 则 反春天不成立 另外 结算时 没有农民玩家牌数达到17也没有反春天
		self.flag_fanchuntian = false
	end	
	self.time_outcard_ = LAND_TIME_OUT_CARD
	if cardstype == LAND_CARD_TYPE_MISSILE or cardstype == LAND_CARD_TYPE_BOMB then
		playercards:add_bomb_count()
		self.bomb = self.bomb + 1
	end

	self.first_turn = self.cur_turn
	if cardstype ~= LAND_CARD_TYPE_MISSILE then
		if self.cur_turn == 3 then
			self.cur_turn = 1
		else
			self.cur_turn = self.cur_turn + 1
		end
	else
		self.last_out_cards = nil
	end

	local notify = {
		cur_chair_id = self.cur_turn,
		out_chair_id = player.chair_id,
		cards = cardslist,
		turn_over = (cardstype == LAND_CARD_TYPE_MISSILE and 1 or 0),
		}
	self:broadcast2client("SC_LandOutCard", notify)
	log_info(string.format("outcard ==========================   chair_id [%d] cards[%s]", player.chair_id, table.concat(cardslist, ',')))
	player.outTime = 0
	self.time0_ = get_second_time()

	local outCardFlag = not playercards:out_cards(cardslist)
	-- 记录剩下的牌
	outcard.sparecards = string.format("%s",table.concat(playercards.cards_, ','))
	table.insert(self.gamelog.outcard_process,outcard)

	if outCardFlag then
		self:finishgame(player)
	else
		self:Next_Player_Proc()
	end
end

-- 放弃出牌
function land_table:pass_card(player, flag)
	if self.status ~= LAND_STATUS_PLAY then
		log_warning(string.format("land_table:pass_card guid[%d] status error", player.guid))
		return
	end

	if player.chair_id ~= self.cur_turn then
		log_warning(string.format("land_table:pass_card guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_turn))
		return
	end

	if not self.last_out_cards then
		log_error(string.format("land_table:pass_card guid[%d] first turn", player.guid))
		return
	end

	if not flag or flag == false then
		player.TrusteeshipTimes = 0
	end

	-- 记录日志
	local outcard = {
		chair_id = player.chair_id,
		outcards = "pass card",
		sparecards = string.format("%s",table.concat(self.land_player_cards[player.chair_id].cards_, ',')),
		time = get_second_time(),		
		isTrusteeship = player.isTrusteeship and 1 or 0,
	}
	table.insert(self.gamelog.outcard_process,outcard)


	if self.cur_turn == 3 then
		self.cur_turn = 1
	else
		self.cur_turn = self.cur_turn + 1
	end

	local is_turn_over = (self.cur_turn == self.first_turn and 1 or 0)
	if is_turn_over == 1 then
		self.last_out_cards = nil
	end
	-- self.time0_ = get_second_time()
	local notify = {
		cur_chair_id = self.cur_turn,
		pass_chair_id = player.chair_id,
		turn_over = is_turn_over,
		}
	log_info(string.format("cur_chair_id[%d],pass_chair_id[%d]",notify.cur_chair_id,notify.pass_chair_id))
	self:broadcast2client("SC_LandPassCard", notify)
	self:Next_Player_Proc()
end
function land_table:Next_Player_Proc( ... )
	-- body
	if  self.status == LAND_STATUS_CALL then
		if not self.player_list_[self.cur_turn] then
			log_error(string.format("not find player gameTableid [%s]",self.table_game_id))
			self:finishgameError()
		elseif self.player_list_[self.cur_turn].Dropped or self.player_list_[self.cur_turn].isTrusteeship then
			-- self:call_score(self.player_list_[self.cur_turn], 0)
			self.time0_ = get_second_time() - LAND_TIME_CALL_SCORE + 1
		end
	elseif self.status == LAND_STATUS_PLAY then
		log_info("========================================Next_Player_Proc")
		if self.player_list_[self.cur_turn].Dropped or self.player_list_[self.cur_turn].isTrusteeship then
			log_info("========================================Trusteeship123")
			--self:trusteeship(self.player_list_[self.cur_turn])
			log_info(self.time0_,get_second_time(),self.time_outcard_)
			self.time0_ = get_second_time() - self.time_outcard_ + 1
			log_info(self.time0_,get_second_time(),self.time_outcard_)
		else
			self.time0_ = get_second_time()
		end
	end
end
--玩家上线处理
function  land_table:reconnect(player)
	-- body
	-- 新需求 玩家掉线不暂停游戏 只是托管
end
function  land_table:isPlay( ... )
	log_info("land_table:isPlay :"..self.status)
	-- body
	if self.status == LAND_STATUS_PLAY or self.status == LAND_STATUS_PLAYOFFLINE or self.status == LAND_STATUS_CALL then
		log_info("isPlay  return true")
		return true
	end
	return false
end
--请求玩家数据
function land_table:ReconnectionPlayMsg(player)
	-- body
	log_info("player online : "..player.chair_id)
	base_table.ReconnectionPlayMsg(self,player)
	local notify = {
			room_id = player.room_id,
			table_id = player.table_id,
			chair_id = player.chair_id,
			result = GAME_SERVER_RESULT_SUCCESS,
			ip_area = player.ip_area,
		}
	self:foreach_except(player.chair_id, function (p)
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
	
	send2client_pb(player, "SC_PlayerReconnection", notify)
	self:recoveryplayercard(player)

	--发送加倍情况
	local notify_double = {
		pb_double_state = {},
		double_count_down = 0
	}

	if self.status == LAND_STATUS_DOUBLE and player.is_double == nil then
		local curtime = get_second_time()
		notify_double.double_count_down = LAND_TIME_CALL_SCORE + self.time0_ - curtime 
		log_info("-------------------------------cool down------",notify_double.double_count_down)
	end

	for i,v in ipairs(self.player_list_) do
		if v then
			local m = {
				chair_id = v.chair_id,
				is_double = 1
			}
			if v.is_double then 
				m.is_double = 2
			elseif v.is_double == nil then
				m.is_double = 3
			end
			table.insert(notify_double.pb_double_state,m)
		end
	end
	
	send2client_pb(player, "SC_LandRecoveryPlayerDouble", notify_double)

	local notify = {
		cur_online_chair_id = player.chair_id,
		cur_chair_id = self.cur_turn,
	}
	self:broadcast2client("SC_LandPlayerOnline", notify)
	player.isTrusteeship = true
	self:setTrusteeship(player,false)
end
function land_table:ready(player)
	log_info("land_table:ready ======= :"..player.table_id)
	if self:isPlay() then
		log_info("land_table: is play  can not ready ======= tableid:"..player.table_id)
		return
	end
	--[[
	for _,v in ipairs(self.player_list_) do		
		if v and v.guid ~= player.guid then
			log_info("===========judgePlayTimes")
			local LimtCDTime = 0
			if self.GameLimitCdTime then
				log_info("============self.room_.GameLimitCdTime:"..self.GameLimitCdTime)
				LimtCDTime = self.GameLimitCdTime
			end
			if player:judgePlayTimes(v,LimtCDTime) then
				log_info(string.format("tableid [%d] ready judgePlayTimes is true playerGuid[%d] otherGuid[%d]",self.table_id_,player.guid,v.guid))
			else
				-- 再判断
				if v:judgePlayTimes(player,LimtCDTime) then
					log_info(string.format("tableid [%d] ready judgePlayTimes is true playerGuid[%d] otherGuid[%d]",self.table_id_,player.guid,v.guid))
				else
					log_info(string.format("tableid [%d] ready judgePlayTimes is false playerGuid[%d] otherGuid[%d]",self.table_id_,player.guid,v.guid))
					player.ipControlTime = get_second_time()
		            log_info("===============land_table tick")
		            self.room_.room_manager_:change_table(player)
		            local tab = self.room_:find_table(player.table_id)
		            tab:ready(player)
					return
				end
			end
		end
	end
	]]
	if not self:canEnter(player) then
		self.room_.room_manager_:change_table(player)
		local tab = self.room_:find_table(player.table_id)
		tab:ready(player)
		return
	end

	base_table.ready(self,player)
	player.offtime = nil
	player.isTrusteeship = false
	player.finishOutGame = false
end
--恢复玩家当前数据
function  land_table:recoveryplayercard(player)
	-- 游戏进行时发牌
	if self.status == LAND_STATUS_PLAY or self.status == LAND_STATUS_DOUBLE then
		local notify = {
			cur_chair_id = player.chair_id,
			cards = self.land_player_cards[player.chair_id].cards_,
			pb_msg = {},
			landchairid = self.flag_land,
			landcards = self.landcards,
			call_score = self.cur_call_score,
			lastCards  = self.last_cards,
			lastcardid = self.first_turn,
			outcardid  = self.cur_turn,
			alreadyoutcards = self.Already_Out_Cards,
			bomb = self.bomb,
		}
		for i,v in ipairs(self.player_list_) do
			if v.chair_id ~= player.chair_id then
				local m = {
					chair_id = v.chair_id,
					cardsnum = #self.land_player_cards[v.chair_id].cards_,
					isTrusteeship = v.isTrusteeship,
				}
				table.insert(notify.pb_msg,m)
			end
		end

		log_info(string.format("chairid[%d] cards[%s]",player.chair_id,table.concat( self.land_player_cards[player.chair_id].cards_, ", ")))
		log_info("---------SC_LandRecoveryPlayerCard-----------")
		send2client_pb(player, "SC_LandRecoveryPlayerCard", notify)
	elseif self.status == LAND_STATUS_PLAYOFFLINE or self.status == LAND_STATUS_CALL then
		local notify = {
			cur_chair_id = self.cur_turn,
			call_chair_id = self.cur_call_score_chair_id,
			call_score = self.cur_call_score,
			cards = self.land_player_cards[player.chair_id].cards_,
			pb_playerOfflineMsg = {}
		}
		player.offtime = nil
		local waitT = 0
		for i,v in ipairs(self.player_list_) do
			if v then
				if v.offtime then
					local pptime = get_second_time() - v.offtime
					if pptime >= LAND_TIME_WAIT_OFFLINE then
						pptime = 0
					else
						pptime = LAND_TIME_WAIT_OFFLINE - pptime
					end
					local xxnotify = {
						chair_id = v.chair_id,
						outTimes = pptime,
					}
					table.insert(notify.pb_playerOfflineMsg, xxnotify)
					if v.offtime then
						if v.offtime > waitT then
							waitT = v.offtime
						end
					end
				end
			end
		end
		send2client_pb(player, "SC_LandRecoveryPlayerCallScore", notify)
		if waitT == 0 then
			self.time0_ = get_second_time()
			self.status = LAND_STATUS_CALL
		else
			self.time0_ = waitT
		end
	end
end
--玩家掉线处理
function  land_table:playeroffline( player )
	log_info("land_table:playeroffline")
	base_table.playeroffline(self,player)
	log_info("player offline : ".. player.chair_id)
	-- body
	if self.status == LAND_STATUS_FREE then
		-- 等待开始时 掉线则强制退出玩家
		player:forced_exit()
	--elseif self.status == LAND_STATUS_CALL then
	--	-- 叫分状态时 掉线则所有玩家待
	--	--发送掉线消息
	--	local notify = {
	--		cur_chair_id = player.chair_id,
	--		wait_time = LAND_TIME_WAIT_OFFLINE,
	--	}
	--	self:broadcast2client("SC_LandCallScorePlayerOffline", notify)
	--	--设置状态为等待
	--	player.offtime = get_second_time()
	--	log_info("set LAND_STATUS_PLAYOFFLINE")
	--	self.status = LAND_STATUS_PLAYOFFLINE		
	--	self.time0_ = get_second_time()
	elseif self.status == LAND_STATUS_PLAY or self.status == LAND_STATUS_CALL or self.status == LAND_STATUS_DOUBLE then
		-- 游戏进行时 则暂停游戏
		-- 新需求更新为 不再暂停游戏 托管玩家
		self:setTrusteeship(player,true)
	elseif self.status == LAND_STATUS_PLAYOFFLINE then
		-- 叫分状态时 掉线则所有玩家待
		--发送掉线消息
		local notify = {
			cur_chair_id = player.chair_id,
			wait_time = LAND_TIME_WAIT_OFFLINE,
		}
		self:broadcast2client("SC_LandCallScorePlayerOffline", notify)
		--设置状态为等待
		player.offtime = get_second_time()
		local i = 0
		for i,v in ipairs(self.player_list_) do
			if v then
				i = i + 1
			end
		end
		if i == 3 then
			--3个玩家都退出了 直接结束游戏 踢人
			local room_limit = self.room_:get_room_limit()
			for i,v in ipairs(self.player_list_) do
				if v then
					log_info(string.format("chair_id [%d] is offline forced_exit~! guid is [%d]" , v.chair_id, v.guid))
					v:forced_exit()
				end
			end
			log_info("game init")
			self:clear_ready()
			return
		end
	end		
end

function land_table:finishgameError()
	for i,v in ipairs(self.player_list_) do
		if v then
			local t_guid = v.guid or 0
			local t_room_id = v.room_id or 0
			local t_table_id = v.table_id or 0
			log_info(string.format("Player InOut Log,land_table:finishgameError player %s, table_id %s ,room_id %s,game_id %s",
			tostring(t_guid),tostring(t_table_id),tostring(t_room_id),tostring(self.table_game_id)))
		end
	end

	log_info("============finishgameError")
	local notify = {
		pb_conclude = {},
		chuntian = 0,
		fanchuntian = 0,
	}
	for i=1,3 do
		c = {}
		c.score = 0
		c.bomb_count = 0
		c.cards = {}
		c.flag = self.room_.tax_show_
		c.tax = 0
		notify.pb_conclude[i] = c
	end
	self:broadcast2client("SC_LandConclude",notify)
	-- body 异常牌局
	self.gamelog.end_game_time = get_second_time()
	self.gamelog.onlinePlayer = {}
	for i,v in pairs(self.player_list_) do
		if v then -- 保存在线的玩家 并T出游戏
			table.insert(self.gamelog.onlinePlayer, i)
			v:forced_exit()
		end
	end

	local s_log = lua_to_json(self.gamelog)
	log_info(s_log)
	self:Save_Game_Log(self.gamelog.table_game_id,self.def_game_name,s_log,self.gamelog.start_game_time,self.gamelog.end_game_time)
	self:clear_ready()
end

function  land_table:finishgame(player)
	for i,v in ipairs(self.player_list_) do
		if v then
			local t_guid = v.guid or 0
			local t_room_id = v.room_id or 0
			local t_table_id = v.table_id or 0
			log_info(string.format("Player InOut Log,land_table:finishgame player %s, table_id %s ,room_id %s,game_id %s",
			tostring(t_guid),tostring(t_table_id),tostring(t_room_id),tostring(self.table_game_id)))
		end
	end

	-- body	
	-- 游戏结束 进行结算
	self.gamelog.end_game_time = get_second_time()
	local notify = {
		pb_conclude = {},
		chuntian = 0,
		fanchuntian = 0,
	}
	local bomb_count = 0
	--剩余牌数
	local carNum
	local carNums = 0
	local land_M = {
		chair_id = self.flag_land,
		landMoney = 0,
	}
	local farmer_M = {}


	local offcharid = 0
	local offtimes = get_second_time()
	log_info(string.format("self.room_.tax_show_ [%d]",self.room_.tax_show_))
	for i,v in ipairs(self.player_list_) do
		if v then
			local c = {}
			carNum = 0
			carNum = #self.land_player_cards[v.chair_id].cards_
			c.cards = self.land_player_cards[v.chair_id].cards_
			c.bomb_count = self.land_player_cards[v.chair_id]:get_bomb_count()
			c.score = 0
			bomb_count = bomb_count + c.bomb_count
			if #c.cards == 0 then
				--c.cards = {99}
			end
			notify.pb_conclude[v.chair_id] = c
			log_info("player:"..v.chair_id.." cards:"..carNum)
			-- 一个假设判断
			if v.chair_id ~= self.flag_land and carNum == 17 then
				carNums = carNums + 1;
			end
			if v.offtime ~= nil then
				local offlinePlayers = {
					chair_id = v.chair_id,
					offtime = v.offtime,
				}
				table.insert(self.gamelog.offlinePlayers,offlinePlayers)
			end
			self.gamelog.playInfo[v.chair_id] = {
				chair_id = v.chair_id,
				guid = v.guid,
				old_money = v.pb_base_info.money,
				new_money = v.pb_base_info.money,
				tax = 0,
				gameEndStatus = "",
			}
			if v.chair_id == self.flag_land then
				land_M.landMoney = v.pb_base_info.money
				land_M.is_double = v.is_double
			else
				local farmerM = {
					farmerMoney = v.pb_base_info.money,
					chair_id = v.chair_id,
					is_double = v.is_double
				}
				table.insert(farmer_M,farmerM)
			end


			if v.offtime ~= nil then
				if v.offtime < offtimes then
					offcharid = v.chair_id
					offtimes = v.offtime
				end
			end
		else
			log_error(string.format("========player_list_ [%d] is nil or false",i))
		end
	end

	if carNums == 2 then
		--有两个人 还剩17张牌
		self.flag_chuntian = true
	end

	--local score = self.room_.cell_score_*(self.cur_call_score + 1)
	local score = self.cur_call_score
	if self.cur_call_score <= 0 then
		score = 1
	end
	if bomb_count > 0 then
		score = score * (2^bomb_count)
	end
	local score_multiple = 0
	local room_cell_score = self.cell_score_
	local land_master_win = true
	if self.status == LAND_STATUS_PLAYOFFLINE then
		-- 掉线玩家扣分


		land_M = {}
		farmer_M = {}

		for i,v in ipairs(self.player_list_) do
			if v.chair_id == offcharid then
				land_M.landMoney = v.pb_base_info.money
				land_M.is_double = v.is_double
			else
				local farmerM = {
					farmerMoney = v.pb_base_info.money,
					chair_id = v.chair_id,
					is_double = v.is_double
				}
				table.insert(farmer_M,farmerM)
			end
		end

		--- 新需求 输赢加上 最大上限 提前算出 值			
		local land_score = 0
		land_score = score* room_cell_score

		local m_f1_score = land_score
		local m_f2_score = land_score
		if land_M.is_double then
			m_f1_score = m_f1_score*2
			m_f2_score = m_f2_score*2
		end
		if farmer_M[1].is_double then
			m_f1_score = m_f1_score*2
		end
		if farmer_M[2].is_double then
			m_f2_score = m_f2_score*2
		end
		if m_f1_score > farmer_M[1].farmerMoney then
			m_f1_score = farmer_M[1].farmerMoney
		end
		if m_f2_score > farmer_M[2].farmerMoney then
			m_f2_score = farmer_M[2].farmerMoney
		end
		
		local f_score_total = m_f1_score+m_f2_score
		if (m_f1_score+m_f2_score) > land_M.landMoney then
			--按比例平分
			m_f1_score = math.floor((land_M.landMoney*m_f1_score)/f_score_total)
			m_f2_score = math.floor((land_M.landMoney*m_f2_score)/f_score_total)
		end

		--[[
		--- 比较地主身上的钱 得出 最多收益
		if land_score > land_M.landMoney/2 then
			land_score = land_M.landMoney/2
		end

		if farmer_M[1].farmerMoney > land_score then
			farmer_M[1].farmerMoney = land_score
		end
		if farmer_M[2].farmerMoney > land_score then
			farmer_M[2].farmerMoney = land_score
		end
		]]

		--扣分

		log_info(string.format("offline player chairid is [%d] offtime is [%d]",offcharid,offtimes))
		self.table_game_id = self:get_now_game_id()
		self.gamelog.table_game_id = self.table_game_id
		self:next_game()

		for i,v in ipairs(self.player_list_) do
			log_info("======== chairid is "..v.chair_id)
			if self:isDroppedline(v) then
				log_info("this player is offline:"..v.chair_id)
			end
			local s_type = 1
			local s_old_money = v.pb_base_info.money
			local s_tax = 0
			if v.chair_id == offcharid then	
				s_type = 3
				--land_score = farmer_M[1].farmerMoney + farmer_M[2].farmerMoney
				self.gamelog.playInfo[v.chair_id].gameEndStatus = "callsoure offline loss"
				notify.pb_conclude[v.chair_id].score = -(m_f1_score + m_f2_score)-- -land_score * 2
				v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = (m_f1_score + m_f2_score)--[[land_score *2]]}}, LOG_MONEY_OPT_TYPE_LAND,true)
			else
				s_type = 2
				local farmer_score = 0
				if v.chair_id == farmer_M[1].chair_id then
					farmer_score = m_f1_score --farmer_M[1].farmerMoney
				else
					farmer_score = m_f2_score --farmer_M[2].farmerMoney
				end
				self.gamelog.playInfo[v.chair_id].gameEndStatus = "callsoure online win"
				notify.pb_conclude[v.chair_id].score = farmer_score				
				s_tax = math.ceil(notify.pb_conclude[v.chair_id].score * self.room_:get_room_tax())
				-- 收取%5 税收 math.ceil 可能没必要
				notify.pb_conclude[v.chair_id].score = notify.pb_conclude[v.chair_id].score - s_tax
				v:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = notify.pb_conclude[v.chair_id].score}}, LOG_MONEY_OPT_TYPE_LAND)

				self:ChannelInviteTaxes(v.channel_id,v.guid,v.inviter_guid,s_tax)
			end
			self.gamelog.playInfo[v.chair_id].tax = s_tax
			self.gamelog.playInfo[v.chair_id].new_money = v.pb_base_info.money
			log_info(string.format("game finish playerid[%d] guid[%d] money [%d]",v.chair_id,v.guid,v.pb_base_info.money))
			self:PlayerMoneyLog(v,s_type,s_old_money,s_tax,notify.pb_conclude[v.chair_id].score,self.table_game_id)
		end
	else
		self.gamelog.win_chair = player.chair_id
		-- 配合客户端 两位小数精确 服务器 用整数下发 客户端 自动除以100
		if self.flag_land == player.chair_id then
			log_info("land win")
			land_master_win = true
			-- 地主赢了
			if self.flag_chuntian then
				score = score * 2
				notify.chuntian = 1
			end
			score_multiple = score
			-- score = score_multiple * room_cell_score
			log_info(string.format("score_multiple[%d] room_cell_score[%d]",score_multiple,room_cell_score))

			--- 新需求 输赢加上 最大上限 提前算出 值			
			local land_score = 0
			land_score = score_multiple * room_cell_score

			local m_f1_score = land_score
			local m_f2_score = land_score
			if land_M.is_double then
				m_f1_score = m_f1_score*2
				m_f2_score = m_f2_score*2
			end
			if farmer_M[1].is_double then
				m_f1_score = m_f1_score*2
			end
			if farmer_M[2].is_double then
				m_f2_score = m_f2_score*2
			end
			if m_f1_score > farmer_M[1].farmerMoney then
				m_f1_score = farmer_M[1].farmerMoney
			end
			if m_f2_score > farmer_M[2].farmerMoney then
				m_f2_score = farmer_M[2].farmerMoney
			end
			
			local f_score_total = m_f1_score+m_f2_score
			if (m_f1_score+m_f2_score) > land_M.landMoney then
				--按比例平分
				m_f1_score = math.floor((land_M.landMoney*m_f1_score)/f_score_total)
				m_f2_score = math.floor((land_M.landMoney*m_f2_score)/f_score_total)
			end
			
			--[[
			--- 比较地主身上的钱 得出 最多收益
			if land_score > land_M.landMoney/2 then
				land_score = land_M.landMoney/2
			end

			if farmer_M[1].farmerMoney > land_score then
				farmer_M[1].farmerMoney = land_score
			end
			if farmer_M[2].farmerMoney > land_score then
				farmer_M[2].farmerMoney = land_score
			end
			]]

			for i,v in ipairs(self.player_list_) do
				local s_type = 1
				local s_old_money = v.pb_base_info.money
				local s_tax = 0
				if self.flag_land == v.chair_id then
					s_type = 2
					if self:isDroppedline(v) and offlinePunishment_flag then
						s_type = 3
						log_info(string.format("land win chair_id[%d] but offline",v.chair_id))
						notify.pb_conclude[v.chair_id].score = 0

						self.gamelog.playInfo[v.chair_id].gameEndStatus = "land win but offline"
					else
						notify.pb_conclude[v.chair_id].score = m_f1_score + m_f2_score --farmer_M[1].farmerMoney + farmer_M[2].farmerMoney
						s_tax = math.ceil(notify.pb_conclude[v.chair_id].score * self.room_:get_room_tax())
						-- 收取%5 税收 math.ceil 可能没必要
						log_info("ceil befor :"..notify.pb_conclude[v.chair_id].score)
						notify.pb_conclude[v.chair_id].score = notify.pb_conclude[v.chair_id].score - s_tax
						log_info("ceil after :"..notify.pb_conclude[v.chair_id].score)
						v:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = notify.pb_conclude[v.chair_id].score}}, LOG_MONEY_OPT_TYPE_LAND)
						log_info("land win add money:"..notify.pb_conclude[v.chair_id].score)

						self:ChannelInviteTaxes(v.channel_id,v.guid,v.inviter_guid,s_tax)
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "land win"
					end
				else
					s_type = 1
					local farmer_score = 0
					if v.chair_id == farmer_M[1].chair_id then
						farmer_score = m_f1_score --farmer_M[1].farmerMoney
					else
						farmer_score = m_f2_score --farmer_M[2].farmerMoney
					end
					self.gamelog.playInfo[v.chair_id].gameEndStatus = "farmer loss"
					if self:isDroppedline(v) and offlinePunishment_flag then
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "farmer loss and offline"
						s_type = 3
						log_info("farmer is Dropped")
						if score_multiple < FARMER_ESCAPE_SCORE_BASE then
							farmer_score = FARMER_ESCAPE_SCORE_LESS* room_cell_score
						else
							farmer_score = score_multiple * room_cell_score * FARMER_ESCAPE_SCORE_GREATER
						end
						if farmer_score > v.pb_base_info.money then
							farmer_score = v.pb_base_info.money
						end
					end
					notify.pb_conclude[v.chair_id].score = -farmer_score
					v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = farmer_score}}, LOG_MONEY_OPT_TYPE_LAND,true)
					log_info("farmer loss cost money:"..notify.pb_conclude[v.chair_id].score)
				end
				self.gamelog.playInfo[v.chair_id].tax = s_tax
				self.gamelog.playInfo[v.chair_id].new_money = v.pb_base_info.money				
				notify.pb_conclude[v.chair_id].tax = s_tax
				notify.pb_conclude[v.chair_id].flag = self.room_.tax_show_
				log_info(string.format("game finish playerid[%d] guid[%d] money [%d] tax[%d]",v.chair_id,v.guid,v.pb_base_info.money,s_tax))
				self:PlayerMoneyLog(v,s_type,s_old_money,s_tax,notify.pb_conclude[v.chair_id].score,self.table_game_id)
			end
		else
			log_info("land loss")
			land_master_win = false
			-- 地主输了
			if self.flag_fanchuntian then
				score = score * 2
				notify.fanchuntian = 1
			end
			score_multiple = score
			--score = score_multiple * room_cell_score
			log_info(string.format("score_multiple[%d] room_cell_score[%d]",score_multiple,room_cell_score))

			--- 新需求 输赢加上 最大上限 提前算出 值			
			local land_score = 0
			land_score = score_multiple * room_cell_score
			--[[--- 比较地主身上的钱 得出 最多收益
			if land_score > land_M.landMoney/2 then
				land_score = land_M.landMoney/2
			end

			if farmer_M[1].farmerMoney > land_score then
				farmer_M[1].farmerMoney = land_score
			end
			if farmer_M[2].farmerMoney > land_score then
				farmer_M[2].farmerMoney = land_score
			end
			]]
			
			local m_f1_score = land_score
			local m_f2_score = land_score
			if land_M.is_double then
				m_f1_score = m_f1_score*2
				m_f2_score = m_f2_score*2
			end
			if farmer_M[1].is_double then
				m_f1_score = m_f1_score*2
			end
			if farmer_M[2].is_double then
				m_f2_score = m_f2_score*2
			end
			if m_f1_score > farmer_M[1].farmerMoney then
				m_f1_score = farmer_M[1].farmerMoney
			end
			if m_f2_score > farmer_M[2].farmerMoney then
				m_f2_score = farmer_M[2].farmerMoney
			end
			local f_score_total = m_f1_score+m_f2_score
			if (m_f1_score+m_f2_score) > land_M.landMoney then
				--按比例平分
				m_f1_score = math.floor((land_M.landMoney*m_f1_score)/f_score_total)
				m_f2_score = math.floor((land_M.landMoney*m_f2_score)/f_score_total)
			end
			
			for i,v in ipairs(self.player_list_) do
				local s_type = 1
				local s_old_money = v.pb_base_info.money
				local s_tax = 0
				if self.flag_land == v.chair_id then
					s_type = 1
					self.gamelog.playInfo[v.chair_id].gameEndStatus = "land loss"
					if self:isDroppedline(v) and offlinePunishment_flag then
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "land loss and offline"
						s_type = 3
						log_info("land is Dropped")
						--如果地主是掉线 果逃跑时的游戏倍数不足 10 倍（指游戏行为的倍数非初始倍数），按照 20 倍分数扣。如果超过 10 倍按照实际的分数的 4 倍扣除。
						if score_multiple < LAND_ESCAPE_SCORE_BASE then
							land_score = LAND_ESCAPE_SCORE_LESS * room_cell_score
						else
							land_score = score_multiple * LAND_ESCAPE_SCORE_GREATER * room_cell_score
						end						
						if land_score > land_M.landMoney/2 then
							land_score = land_M.landMoney
						end
					else
						--land_score = farmer_M[1].farmerMoney + farmer_M[2].farmerMoney
						land_score = m_f1_score + m_f2_score
					end
					notify.pb_conclude[v.chair_id].score = -land_score
					v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = land_score}}, LOG_MONEY_OPT_TYPE_LAND,true)
					log_info("land loss cost money:"..notify.pb_conclude[v.chair_id].score)
				else
					s_type = 2
					local farmer_score = 0
					if v.chair_id == farmer_M[1].chair_id then
						farmer_score = m_f1_score --farmer_M[1].farmerMoney
					else
						farmer_score = m_f2_score --farmer_M[2].farmerMoney
					end
					if not self:isDroppedline(v) or not offlinePunishment_flag then
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "farmer win"
						notify.pb_conclude[v.chair_id].score = farmer_score
						s_tax = math.ceil(notify.pb_conclude[v.chair_id].score * self.room_:get_room_tax())
						-- 收取%5 税收 math.ceil 可能没必要
						log_info("ceil befor :"..notify.pb_conclude[v.chair_id].score)
						notify.pb_conclude[v.chair_id].score = notify.pb_conclude[v.chair_id].score - s_tax
						log_info("ceil after :"..notify.pb_conclude[v.chair_id].score)
						v:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = notify.pb_conclude[v.chair_id].score}}, LOG_MONEY_OPT_TYPE_LAND)
						self:ChannelInviteTaxes(v.channel_id,v.guid,v.inviter_guid,s_tax)
					else
						s_type = 3
						log_info(string.format("chair_id[%d] win but offline",v.chair_id))
						notify.pb_conclude[v.chair_id].score = 0
						self.gamelog.playInfo[v.chair_id].gameEndStatus = "farmer win but offline"
					end
					log_info("farmer win add money:"..notify.pb_conclude[v.chair_id].score)
				end
				self.gamelog.playInfo[v.chair_id].tax = s_tax
				self.gamelog.playInfo[v.chair_id].new_money = v.pb_base_info.money
				log_info(string.format("game finish playerid[%d] guid[%d] money[%d] tax[%d]",v.chair_id,v.guid,v.pb_base_info.money,s_tax))
				self:PlayerMoneyLog(v,s_type,s_old_money,s_tax,notify.pb_conclude[v.chair_id].score,self.table_game_id,s_tax)
				notify.pb_conclude[v.chair_id].tax = s_tax
				notify.pb_conclude[v.chair_id].flag = self.room_.tax_show_
			end
		end
	end

	for i,v in ipairs(self.player_list_) do
		if v then
			if v.is_double then
				self.gamelog.playInfo[v.chair_id].is_double = 1
			else
				self.gamelog.playInfo[v.chair_id].is_double = 0
			end
			v.friend_list = {}
			if land_master_win then
				if v.chair_id == self.flag_land then
					for ct,pt in ipairs(self.player_list_) do
						if ct ~= v.flag_land then
							table.insert( v.friend_list, pt.guid )
						end
					end
				end
			else
				if v.chair_id ~= self.flag_land then
					for ct,pt in ipairs(self.player_list_) do
						if ct ~= v.chair_id and ct ~= v.flag_land then
							table.insert( v.friend_list, pt.guid )
						end
					end
				end
			end
		end
	end
	self.gamelog.cell_score = self.cell_score_
	self.gamelog.finishgameInfo = notify
	local s_log = lua_to_json(self.gamelog)
	log_info(s_log)
	self:Save_Game_Log(self.gamelog.table_game_id,self.def_game_name,s_log,self.gamelog.start_game_time,self.gamelog.end_game_time)
	-- end
	log_info("game end")
	log_info(string.format("chuntian [%d] ,fanchuntian [%d]",notify.chuntian,notify.fanchuntian))
	for _,var in ipairs(notify.pb_conclude) do 
		log_info(string.format("score [%d] ,bomb_count [%d], cards[%s]",var.score,var.bomb_count,table.concat( var.cards, ", ")))
	end	

	self:broadcast2client("SC_LandConclude", notify)

	-- 踢人
	local room_limit = self.room_:get_room_limit()
	for i,v in ipairs(self.player_list_) do
		if v then
			if  self:isDroppedline(v) or (v.isTrusteeship and v.finishOutGame) then
				log_info(string.format("chair_id [%d] is offline forced_exit~! guid is [%d]" , v.chair_id, v.guid))
				if self:isDroppedline(v) or v.isTrusteeship then
					log_info("====================1")
					v.isTrusteeship = false
					v.finishOutGame = false
				end
				v:forced_exit()
				--if self:isDroppedline(v) then
				--		log_info("====================2")
				--	if not player.online then
				--		log_info("====================3")
				--	end
				--	if player.Dropped then
				--		log_info("====================4")
				--	end
				--	logout(v.guid)
				--end
			else
				v:check_forced_exit(room_limit)
			end
			v.ipControlTime = get_second_time()
		else
			log_info("v is nil:"..i)
		end
	end

--[[	local iRet = base_table.check_game_maintain(self)--检查游戏是否维护
	if iRet == true then
		print("Game land  card will maintain......")
	end--]]
	log_info("game init")
	self:clear_ready()
end
function  land_table:isDroppedline(player)
	-- body
	if player then
		player.ipControlTime = get_second_time()
		if player.chair_id then
			log_info("land_table:isDroppedline:"..player.chair_id)
		end
		return not player.online or player.Dropped
	end
	return false
end
function land_table:clear_ready( ... )	
	-- body
	base_table.clear_ready(self)
	log_info("set LAND_STATUS_FREE")
	self.status = LAND_STATUS_FREE
	self.time0_ = get_second_time()
	self.landcards = nil
	self.last_cards = nil
	self.Already_Out_Cards = {}
	self.bomb = 0
	self.callsore_time = 0
	self.table_game_id = 0
	self.gamelog = {
        CallPoints = {},
        landid = 0,
        land_cards = "",
        table_game_id = 0,
        start_game_time = 0,
        end_game_time = 0,
        win_chair = 0,
        outcard_process = {},
        finishgameInfo = {},
        playInfo = {},
        offlinePlayers = {},
        cell_score = 0,
    }
end
-- 托管
function land_table:trusteeship(player)	
	-- body	
	-- log_info("trusteeship:"..player.chair_id)
	if self.last_out_cards and player.chair_id ~= self.first_turn then
		log_info("time out call pass")
		self:pass_card(player,true)
	else
		log_info("time out call out card")
		local playercards = self.land_player_cards[self.cur_turn]
		self:out_card(player, {playercards.cards_[1]} , true)
	end
	--self.time0_ = get_second_time()
end
function land_table:canEnter(player)
	log_info("land_table:canEnter ===============")
	--if true then
	--	return true
	--end
	if player then
		log_info ("player have date")
	else
		log_info ("player no data")
		return false
	end
	-- body
	if self.status ~= LAND_STATUS_FREE then
		log_info("land_table:canEnter false")
		return false
	end
	for _,v in ipairs(self.player_list_) do		
		if v and v.guid ~= player.guid then
			if player:judgeIP(v) then
				log_info("land_table:canEnter false ip limit")
				return false			
			end

			player.friend_list = player.friend_list or {}
			for k1,v1 in pairs(player.friend_list) do
				if v.guid == v1 then
					log_info("land_table:canEnter false friend limit")
					return false
				end
			end

			v.friend_list = v.friend_list or {}
			for k1,v1 in pairs(v.friend_list) do
				if player.guid == v1 then
					log_info("land_table:canEnter false friend limit")
					return false
				end
			end
		end
	end

	log_info("land_table:canEnter true")
	return true
	--[[
	for _,v in ipairs(self.player_list_) do		
		if v and v.guid ~= player.guid then
			log_info("===========judgePlayTimes")
			local LimtCDTime = 0
			if self.GameLimitCdTime then
				log_info("============self.room_.GameLimitCdTime:"..self.GameLimitCdTime)
				LimtCDTime = self.GameLimitCdTime
			end
			if player:judgePlayTimes(v,LimtCDTime) then
				log_info(string.format("tableid[%d] judgePlayTimes is true playerGuid[%d] otherGuid[%d]",self.table_id_,player.guid,v.guid))
				v.ipControlTime = get_second_time()
			else				
				-- 再判断
				if v:judgePlayTimes(player,LimtCDTime)	then				
					log_info(string.format("tableid[%d] judgePlayTimes is true playerGuid[%d] otherGuid[%d]",self.table_id_,player.guid,v.guid))
					v.ipControlTime = get_second_time()
				else					
					log_info(string.format("tableid[%d] judgePlayTimes is false playerGuid[%d] otherGuid[%d]",self.table_id_,player.guid,v.guid))
					return false
				end
			end
			log_info(self.room_.cur_player_count_)
			log_info(LAND_IP_CONTROL_NUM)
			player.ipControlTime = get_second_time()
			if player:judgeIP(v) then
				if not player.ipControlflag then
					log_info("land_table:canEnter ipcontorl change false")
					return false
				else
					-- 执行一次后 重置
					player.ipControlflag = false
					log_info("land_table:canEnter ipcontorl change true")
					return true
				end
			end
		end
	end
	log_info("land_table:canEnter true")
	return true
	]]
end
function  aaaaaaaaaa( ... )
	log_info "aaaaaaaaaa .........................."

	-- body
	--send2db_pb("SD_QueryPlayerMsgData", {
	--			guid = 1,
	--		})
	--on_cs_SetMsgReadFlag()
end
aTemp = 1
-- 心跳
function land_table:tick()
	--if self.status == LAND_STATUS_FREE  and (aTemp == 1 or self.tempT) then
	--	local curtime = get_second_time()
	--	if not self.tempT then
	--		self.tempT = get_second_time()
	--		aTemp = 2
	--	else
	--		if curtime - self.tempT > 10 then
	--			aaaaaaaaaa()
	--			self.tempT = get_second_time()
	--		end
	--	end
	--end
	if self.status == LAND_STATUS_FREE then
		if get_second_time() - self.time0_ > 2 then
			self.time0_ = get_second_time()
			local curtime = self.time0_
			local maintainFlg = 0
			for _,v in ipairs(self.player_list_) do
				if v then
					v.ipControlTime = v.ipControlTime or get_second_time()
					local t = v.ipControlTime
					--维护时将准备阶段正在匹配的玩家踢出
					--[[local iRet = base_table:onNotifyReadyPlayerMaintain(v)--检查游戏是否维护
					if iRet == true then
						maintainFlg = 1
					end--]]
					if t then
						if curtime -  t >= LAND_TIME_IP_CONTROL then
							v.ipControlTime = get_second_time()
							if self:isDroppedline(v) then
								--掉线了就T掉
								if self:isDroppedline(v) or v.isTrusteeship then
									log_info("====================1")
									v.isTrusteeship = false
									v.finishOutGame = false
								end
								v:forced_exit()
							else
								log_info(v.table_id)
								v.ipControlflag = true
								log_info("===============land_table tick")
								--[[]]
															
								if self:get_player_count() == 1 and self.ready_list_[v.chair_id] then
									self.room_.room_manager_:change_table(v)
									local tab = self.room_:find_table(v.table_id)
									tab:ready(v)
								end
							end
						end
					end
				end
			end
	--[[		if maintainFlg == 1 then
				print("############Game ready player land  card will maintain.")
			end	--]]
		end
	elseif self.status == LAND_STATUS_PLAY then
		local curtime = get_second_time()
		if curtime == nil then
			log_info("curtime is nil")
		end
		if self.time0_ == nil then
			log_info("self.time0_ is nil")
		end
		if self.time_outcard_ == nil then
			log_info("self.time_outcard_ is nil")
		end
		if curtime - self.time0_ >= self.time_outcard_ then
			-- 超时
			log_info(string.format("time0[%d],time[%d],out[%d],cur_turn[%d]",self.time0_,curtime,self.time_outcard_,self.cur_turn))
			local player = self.player_list_[self.cur_turn]
			if player and player.chair_id then
				log_info("time out :" ..player.chair_id)
				if not player.TrusteeshipTimes then
					player.TrusteeshipTimes = 0
				end
				player.TrusteeshipTimes = player.TrusteeshipTimes + 1
				if player.TrusteeshipTimes >= 2 and not player.isTrusteeship then
					self:setTrusteeship(player,true)
				else
					self:trusteeship(player)
				end
			else
				-- 游戏出现异常 结束 游戏
				log_error(string.format("not find player gameTableid [%s]",self.table_game_id))
				self:finishgameError()
			end
		elseif curtime - self.gamelog.start_game_time > LAND_TIME_OVER then
			self:finishgameError()	
			log_warning(string.format("LAND_TIME_OVER gameTableid [%s]",self.table_game_id))	
		end
	elseif self.status == LAND_STATUS_CALL then
		local curtime = get_second_time()
		if curtime - self.time0_ >= LAND_TIME_CALL_SCORE then
			-- 超时
			local player = self.player_list_[self.cur_turn]
			if player then
				log_info("call_score time out call 0:".. player.chair_id)
				self:call_score(player, 0)
			else
				log_info(string.format("player is offline chairid [%d]",self.cur_turn))
			end
			self.time0_ = curtime
		end	
	elseif self.status == LAND_STATUS_DOUBLE then
		local curtime = get_second_time()
		if curtime - self.time0_ >= LAND_TIME_CALL_SCORE then
			-- 超时
			for i,v in ipairs(self.player_list_) do
				if v and v.is_double == nil then
					self:call_double(v,false)
				end
			end
		end
	elseif self.status == LAND_STATUS_PLAYOFFLINE then
		local curtime = get_second_time()
		if curtime - self.time0_ >= LAND_TIME_WAIT_OFFLINE then
		-- 游戏结束 进行结算
			log_info(string.format("LAND_TIME_WAIT_OFFLINE time out time0[%d] curtime[%d]",self.time0_ ,curtime))
			self:finishgame()
		end
	end
end
-- function abc( ... )
--     -- body
--     log_info("================================abc=================================")
--     local aTest = {
--         startTime = 123456,
--         endTime = 987654321,
--         callsource = {},
--         abc = {},
--     }
--     local callsource1 = {
--         calltime = 111111111,
--         source = 1,
--         chairid = 1,
--     }
--     local callsource2 = {
--         calltime = 222222222,
--         source = 2,
--         chairid = 2,
--     }
--     local callsource3 = {
--         calltime = 3333333,
--         source = 3,
--         chairid = 3,
--     }
--     table.insert(aTest.callsource,callsource1)
--     table.insert(aTest.callsource,callsource2)
--     table.insert(aTest.callsource,callsource3)
--     local f = lua_to_json(aTest)
--     log_info("================================abc=================================")
--     log_info(f)
-- end
-- abc()
--