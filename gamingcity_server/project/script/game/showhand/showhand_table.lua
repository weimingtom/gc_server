-- 梭哈逻辑

local pb = require "protobuf"

require "game/lobby/base_table"

-- enum SHOWHAND_CARD_TYPE
local SHOWHAND_CARD_TYPE_ZILCH = pb.enum_id("SHOWHAND_CARD_TYPE", "SHOWHAND_CARD_TYPE_ZILCH")
local SHOWHAND_CARD_TYPE_ONE_PAIRS = pb.enum_id("SHOWHAND_CARD_TYPE", "SHOWHAND_CARD_TYPE_ONE_PAIRS")
local SHOWHAND_CARD_TYPE_TWO_PAIRS = pb.enum_id("SHOWHAND_CARD_TYPE", "SHOWHAND_CARD_TYPE_TWO_PAIRS")
local SHOWHAND_CARD_TYPE_THREE = pb.enum_id("SHOWHAND_CARD_TYPE", "SHOWHAND_CARD_TYPE_THREE")
local SHOWHAND_CARD_TYPE_STRAIGHT = pb.enum_id("SHOWHAND_CARD_TYPE", "SHOWHAND_CARD_TYPE_STRAIGHT")
local SHOWHAND_CARD_TYPE_FLUSH = pb.enum_id("SHOWHAND_CARD_TYPE", "SHOWHAND_CARD_TYPE_FLUSH")
local SHOWHAND_CARD_TYPE_FULLHOUSE = pb.enum_id("SHOWHAND_CARD_TYPE", "SHOWHAND_CARD_TYPE_FULLHOUSE")
local SHOWHAND_CARD_TYPE_BOMB = pb.enum_id("SHOWHAND_CARD_TYPE", "SHOWHAND_CARD_TYPE_BOMB")
local SHOWHAND_CARD_TYPE_STRAIGHT_FLUSH = pb.enum_id("SHOWHAND_CARD_TYPE", "SHOWHAND_CARD_TYPE_STRAIGHT_FLUSH")

local SHOWHAND_ADD_SCORE_GIVEUP = pb.enum_id("SHOWHAND_ADD_SCORE_TYPE", "SHOWHAND_ADD_SCORE_GIVEUP")
local SHOWHAND_ADD_SCORE_NO = pb.enum_id("SHOWHAND_ADD_SCORE_TYPE", "SHOWHAND_ADD_SCORE_NO")
local SHOWHAND_ADD_SCORE_CALL = pb.enum_id("SHOWHAND_ADD_SCORE_TYPE", "SHOWHAND_ADD_SCORE_CALL")
local SHOWHAND_ADD_SCORE_ADD = pb.enum_id("SHOWHAND_ADD_SCORE_TYPE", "SHOWHAND_ADD_SCORE_ADD")
local SHOWHAND_ADD_SCORE_ALLIN = pb.enum_id("SHOWHAND_ADD_SCORE_TYPE", "SHOWHAND_ADD_SCORE_ALLIN")
-- enum ITEM_PRICE_TYPE 
local ITEM_PRICE_TYPE_GOLD = pb.enum_id("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")

-- 等待开始
local SHOWHAND_STATUS_FREE = 1
-- 游戏进行
local SHOWHAND_STATUS_PLAY = 2
-- 玩家掉线
local SHOWHAND_STATUS_PLAYOFFLINE = 3
-- 玩家掉线等待时间
local SHOWHAND_TIME_WAIT_OFFLINE = 30



local SHOWHAND_TIME_GIVEUP = 30


-- 得到牌大小
local function get_value(card)
	return math.floor(card / 4)
end

-- 得到牌花色
local function get_color(card)
	return card % 4
end
-- 0：方块2，1：梅花2，2：红桃2，3：黑桃2 …… 48：方块A，49：梅花A，50：红桃A，51：黑桃A


showhand_table = base_table:new()

-- 初始化
function showhand_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	self.status = SHOWHAND_STATUS_FREE	
	self.Max_Call = self.room_.roomConfig.max_call
	print("Max_Call : "..self.Max_Call)
	self.cards = {}
	for i = 1, 52 do
		self.cards[i] = i - 1
	end
end

-- 检查是否可准备
function showhand_table:check_ready(player)
	if self.status ~= SHOWHAND_STATUS_FREE then
		return false
	end
	return true
end

-- 检查是否可取消准备
function showhand_table:check_cancel_ready(player, is_offline)
	base_table.check_cancel_ready(self,player,is_offline)
	player:setStatus(is_offline)
	if is_offline then
		--掉线	
		if  self.status ~= SHOWHAND_STATUS_FREE then
			--掉线处理
			self:playeroffline(player)
			return false
		end
	end	
	--退出
	return true
end

-- 下一个
function showhand_table:next_turn()
	local old = self.cur_turn
	repeat
		self.cur_turn = self.cur_turn + 1
		if self.cur_turn > #self.ready_list_ then
			self.cur_turn = 1
		end
		if old == self.cur_turn then
			log_error("turn error")
			return
		end
	until(self.ready_list_[self.cur_turn] and (not self.is_dead_[self.cur_turn]))
end

-- 开始游戏
function showhand_table:start(player_count)
	self.player_count_ = player_count
	self.player_cards_ = {} -- 玩家手里的牌
	self.is_dead_ = {} -- 放弃或比牌输了
	self.player_score = {}	--玩家当前局所押注
	self.player_score_all = {} --整局游戏所押注
	local cell_score = self.cell_score_
	self.round_ = 0

	self.first_turn = nil

	-- 发牌
	local last_type = nil
	local last_val = nil
	local last_clr = nil
	local k = #self.cards
	for i,v in ipairs(self.player_list_) do
		if v then
			-- 洗牌
			local cards = {}
			for j=1,5 do
				local r = math.random(k)
				cards[j] = self.cards[r]
				if r ~= k then
					self.cards[r], self.cards[k] = self.cards[k], self.cards[r]
				end
				k = k-1
			end
			self.player_cards_[v.chair_id] = cards			
			-- 底注
			self.player_score_all[v.chair_id] = 0
			self.player_score[v.chair_id] = cell_score			
			v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = cell_score}}, LOG_MONEY_OPT_TYPE_SHOWHAND)
			local money_ = v:get_money()
		end
	end
	self.status = SHOWHAND_STATUS_PLAY
	--发底牌
	local msg = {
	}
	for i,v in ipairs(self.player_list_) do
		if v then
			msg.hide_card = self.player_cards_[v.chair_id][5]
			send2client_pb(v, "SC_ShowHandStart", msg)
		end
	end
	-- 发第一张明牌
	self:check_round()
	self.time0_ = get_second_time()
end
-- 判断 是否大于最大下注
function showhand_table:FinalScore(player,score_)
	-- body
	if score_ + self.player_score[player.chair_id] + self.player_score_all[player.chair_id] > self.Max_Call then
		return self.Max_Call - self.player_score[player.chair_id] - self.player_score_all[player.chair_id]
	end
	return score_
end
-- 加注
function showhand_table:add_score(player, type_ ,score_)
	if self.status ~= SHOWHAND_STATUS_PLAY then
		log_warning(string.format("showhand_table:add_score guid[%d] status error", player.guid))
		return
	end

	if player.chair_id ~= self.cur_turn then
		log_warning(string.format("showhand_table:add_score guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_turn))
		return
	end

	if self.is_dead_[player.chair_id] then
		log_error(string.format("showhand_table:add_score guid[%d] is dead", player.guid))
		return
	end

	if type_ ~= SHOWHAND_ADD_SCORE_GIVEUP and  type_ ~= SHOWHAND_ADD_SCORE_NO and type_ ~= SHOWHAND_ADD_SCORE_CALL and type_ ~= SHOWHAND_ADD_SCORE_ADD and type_ ~= SHOWHAND_ADD_SCORE_ALLIN then
		log_warning(string.format("showhand_table:add_score guid[%d] type error", player.guid))
		return
	end
	if type_ == SHOWHAND_ADD_SCORE_GIVEUP then
		self:give_up(player)
		return
	end
	if type_ == SHOWHAND_ADD_SCORE_NO then
		if self.call_type ~= nil and self.call_type ~= SHOWHAND_ADD_SCORE_NO then
			log_warning(string.format("showhand_table:add_score guid[%d] cannot SHOWHAND_ADD_SCORE_NO lastType [%d]", player.guid , (self.call_type or 0)))
			return
		end
		score_ = 0
	end
	if type_ == SHOWHAND_ADD_SCORE_CALL then
		if self.call_type == nil or self.call_type == SHOWHAND_ADD_SCORE_NO then
			log_warning(string.format("showhand_table:add_score guid[%d] cannot SHOWHAND_ADD_SCORE_CALL lastType [%d]", player.guid , (self.call_type or 0)))
			return
		end
		score_ = self.last_score - self.player_score[player.chair_id]
		if score_ < 0 then
			-- 本身 下注 比记录最大注还大，这不可能
			log_error(string.format("guid[%d] SHOWHAND_ADD_SCORE_CALL error  last_score[%d] player_score[%d]", player.guid , score.last_score , self.player_score[player.chair_id]))
			return
		end
		if score_ > player:get_money() then
			log_warning(string.format("showhand_table:add_score guid[%d] SHOWHAND_ADD_SCORE_CALL faild player_money[%d] call_score[%d]", player.guid, player:get_money(), score_))
			return
		end
	end
	if type_ == SHOWHAND_ADD_SCORE_ADD then --加注 1 不能比之前低 2 不能钱不够 3 不能在ALLIN的时候加注 
		if self.call_type ~= nil and self.call_type == SHOWHAND_ADD_SCORE_ALLIN then
			log_warning(string.format("showhand_table:add_score guid[%d] cannot SHOWHAND_ADD_SCORE_ALLIN , It is ShowHand Time", player.guid ))
			return
		end
		if score_ < 0 then
			log_warning(string.format("showhand_table:add_score guid[%d] faild score_[%d] < 0", player.guid,score_))
			return
		end
		if score_ == 0 then
			type_ = SHOWHAND_ADD_SCORE_CALL
		end
		score_ = score_ + self.last_score - self.player_score[player.chair_id]
		score_ = self:FinalScore(player,score_)

		if score_ > player:get_money() then
			log_warning(string.format("showhand_table:add_score guid[%d] SHOWHAND_ADD_SCORE_ADD faild player_money[%d] call_score[%d]", player.guid, player:get_money(), score_))
			return
		end
	end
	if type_ == SHOWHAND_ADD_SCORE_ALLIN then
		score_ = player:get_money()
		score_ = self:FinalScore(player,score_)
	end
	self.call_type = type_
	-- 扣除下注金额
	if score_ > 0 then
		player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = score_}}, LOG_MONEY_OPT_TYPE_SHOWHAND)
		self.player_score[player.chair_id] = score_ + self.player_score[player.chair_id]
	end
	-- 更新最大金额数
	if self.player_score[player.chair_id] > self.last_score then
		self.last_score = self.player_score[player.chair_id]
		-- 新的一轮叫分
		self.first_turn = self.cur_turn
	end

	self:next_turn()
	local b_round = self.cur_turn == self.first_turn
	
	local notify = {
		add_score_chair_id = player.chair_id,
		cur_chair_id = self.cur_turn,
		add_score_type = type_,
		score = score_,
		round = b_round,
		max_call = ((self.player_score[player.chair_id] + self.player_score_all[player.chair_id]) == self.Max_Call),
	}
	self:broadcast2client("SC_ShowHandAddScore", notify)
	
	if b_round then
		self:check_round()
	end

	self.time0 = get_second_time()
end

-- 放弃跟注
function showhand_table:give_up(player)
	if self.status ~= SHOWHAND_STATUS_PLAY then
		log_warning(string.format("showhand_table:give_up guid[%d] status error", player.guid))
		return
	end

	if player.chair_id ~= self.cur_turn then
		log_warning(string.format("showhand_table:give_up guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_turn))
		return
	end

	if self.is_dead_[player.chair_id] then
		log_error(string.format("showhand_table:add_score guid[%d] is dead", player.guid))
		return
	end

	self.is_dead_[player.chair_id] = true
	self.player_score_all[player.chair_id] = self.player_score_all[player.chair_id] + self.player_score[player.chair_id]
	self.player_score[player.chair_id] = 0
	self:next_turn()
	local b_round = self.cur_turn == self.first_turn
	
	local notify = {
		add_score_chair_id = player.chair_id,
		cur_chair_id = self.cur_turn,
		add_score_type = SHOWHAND_ADD_SCORE_GIVEUP,
		score = 0,
		round = b_round,
	}
	self:broadcast2client("SC_ShowHandAddScore", notify)
	
	if self:check_end() then -- 结束
		return
	end
	
	if b_round then
		self:check_round()
	end

	self.time0 = get_second_time()
end

-- 发牌
function showhand_table:deal_cards()
	local last_type = nil
	local last_val = nil
	local last_clr = nil
	for i,v in ipairs(self.player_list_) do
		if v and (not self.is_dead_[v.chair_id]) then
			local type, val, clr = self:get_cards_type(self.player_cards_[v.chair_id], self.round_)
			if not last_type then
				last_type, last_val, last_clr = type, val, clr
				self.first_turn = v.chair_id
			elseif self:compare_cards(type, val, clr, last_type, last_val, last_clr) then
				last_type, last_val, last_clr = type, val, clr
				self.first_turn = v.chair_id
			end
		end
	end
	self.cur_turn = self.first_turn


	local msg = {
		banker_chair_id = self.cur_turn,
		cards = {},
	}
	for i,v in pairs(self.player_cards_) do
		if v and (not self.is_dead_[i]) then
			table.insert(msg.cards, {
				chair_id = i,
				card = v[self.round_],
			})
		end
	end
	self:broadcast2client("SC_ShowHandDealCard", msg)
end

 -- 开牌
function showhand_table:open_card()
	local last_type = nil
	local last_val = nil
	local last_clr = nil
	local win = nil
	for i,v in ipairs(self.player_list_) do
		if v and (not self.is_dead_[v.chair_id]) then
			local type, val, clr = self:get_cards_type(self.player_cards_[v.chair_id], 5)
			if not last_type then
				last_type, last_val, last_clr = type, val, clr
				win = v.chair_id
			elseif self:compare_cards(type, val, clr, last_type, last_val, last_clr) then
				last_type, last_val, last_clr = type, val, clr
				win = v.chair_id
			end
		end
	end
	self:send_end(win, true)
end

-- 发送结束消息
function showhand_table:send_end(win, is_open)
	self.status = SHOWHAND_STATUS_FREE
	
	local all  = 0
	for i,v in ipairs(self.player_list_) do
		if v.chair_id ~= win then
			all = all + self.player_score_all[v.chair_id]
		end
	end
	-- 赢的部分扣百分之五
	all = math.ceil(all - all * 0.05)
	all = all + self.player_score_all[win] -- 再加上自己押上的注

	local notify = {
		win_chair_id = win,
		conclude = {}
	}
	for i,v in ipairs(self.player_list_) do
		if v then
			local item = {
				chair_id = v.chair_id,
			}

			if is_open and (not self.is_dead_[v.chair_id]) then
				item.card = self.player_cards_[v.chair_id]
			end

			if v.chair_id == win then
				item.score = all
				v:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = all}}, LOG_MONEY_OPT_TYPE_SHOWHAND)
			else
				item.score = -(self.player_score_all[v.chair_id] or 0)
			end
			table.insert(notify.conclude, item)
		end
	end
	self:broadcast2client("SC_ShowHandEnd", notify)

	-- 踢人
	local room_limit = self.room_:get_room_limit()
	for i,v in ipairs(self.player_list_) do
		if v then
			v:check_forced_exit(room_limit)
		end
	end
	
	self:clear_ready()
end

-- 检查一轮
function showhand_table:check_round()
	local max_flag = false
	for i,v in ipairs(self.player_list_) do
		if v and (not self.is_dead_[v.chair_id]) then
			-- 总押注收集 (放弃统计在giveup中)
			self.player_score_all[v.chair_id] = self.player_score_all[v.chair_id] + self.player_score[v.chair_id]
			self.player_score[v.chair_id] = 0
			if self.Max_Call == self.player_score_all[v.chair_id] then  -- 这种是ALLIN 或 已经叫到上限了
				max_flag = true
			elseif v:get_money() == 0 then								-- 这种是 玩家身上钱不够选择ALLIN
				max_flag = true
			end
		end
	end
	-- 如果 last_score 达到 最大值
	self.last_score = 0
	self.call_type = nil
	self.round_ = self.round_ + 1
	if self.round_ < 5 and (not max_flag) then
		self:deal_cards()
	else
		self:open_card()
	end
end

-- 检查结束
function showhand_table:check_end()
	local win = nil
	for i,v in ipairs(self.player_list_) do
		if v and (not self.is_dead_[v.chair_id]) then
			if win then
				return false
			else
				win = i
			end
		end
	end

	if win then
		self:send_end(win, false)
		return true
	end

	return false
end

-- 分析牌
function showhand_table:analyseb_cards(cards)
	local ret = {{}, {}, } -- 依次单，双，三，四
	local last_id = nil
	local j = 0
	for i, card in ipairs(cards) do
		local val = get_value(card)
		if not last_id then
			last_id = i
			j = 1
		elseif get_value(cards[last_id]) == val then
			j = j + 1
		else
			if j <= 2 then
				table.insert(ret[j] , cards[last_id])
			else
				ret[j]= cards[last_id]
			end
			last_id = i
			j = 1
		end
	end
	if j <= 2 then
		table.insert(ret[j], cards[last_id])
	else
		ret[j]= cards[last_id]
	end
	return ret
end

-- 判断顺子
function showhand_table:is_straight(cards)
	local cur_val = nil
	local is_a = false
	for _, card in ipairs(cards) do
		if not cur_val then
			local c = get_value(card)
			if c == 12 then
				is_a = true
			else
				cur_val = c - 1
			end
		elseif cur_val == get_value(card) then
			cur_val = cur_val - 1
		else
			return nil
		end
	end

	if is_a then
		local s = get_value(cards[2])
		if s == 11 then
			return 12
		elseif get_value(cards[#cards]) == 0 then
			return  s
		else
			return nil
		end
	end

	return get_value(cards[1])
end

-- 判断同花
function showhand_table:is_flush(cards)
	local clr = nil
	for _, card in ipairs(cards) do
		if not clr then
			clr = get_color(card)
		elseif clr ~= get_color(card) then
			return nil
		end
	end

	return clr
end
-- 比较牌
function showhand_table:compare_cards(first_type, first_val, first_clr, second_type, second_val, second_clr)
	if first_type ~= second_type then
		return first_type > second_type
	end
	if first_type == SHOWHAND_CARD_TYPE_ZILCH or first_type == SHOWHAND_CARD_TYPE_ONE_PAIRS or 
		first_type == SHOWHAND_CARD_TYPE_TWO_PAIRS or first_type == SHOWHAND_CARD_TYPE_FLUSH then
		local n = #first_val
		for i=1,n do
			local v1 = first_val[i]
			local v2 = second_val[i]
			if v1 > v2 then
				return true
			elseif v1 < v2 then
				return false
			end
		end
		return first_clr > second_clr
	end
	return first_val > second_val
end
--	SHOWHAND_CARD_TYPE_ERROR					= 0;								//错误类型
--	SHOWHAND_CARD_TYPE_ZILCH					= 1;								//散牌类型   type table(cards 里面为原始值) color
--	SHOWHAND_CARD_TYPE_ONE_PAIRS				= 2;								//对子类型   type table(cards 里面为原始值) color
--	SHOWHAND_CARD_TYPE_THREE					= 3;								//三条类型   type val最大值
--	SHOWHAND_CARD_TYPE_TWO_PAIRS				= 4;								//二对类型   type table(cards 里面为原始值) color
--	SHOWHAND_CARD_TYPE_STRAIGHT					= 5;								//顺子类型   type val最大值
--	SHOWHAND_CARD_TYPE_FLUSH					= 6;								//同花类型   type table(cards 里面为原始值) color
--	SHOWHAND_CARD_TYPE_FULLHOUSE				= 7;								//葫芦类型   type val最大值
--	SHOWHAND_CARD_TYPE_BOMB						= 8;								//铁支类型   type val最大值
--	SHOWHAND_CARD_TYPE_STRAIGHT_FLUSH			= 9;								//同花顺类型 type val最大值
-- 得到牌类型 n=5比胜负，其他确定谁先下注
function showhand_table:get_cards_type(cards, n)
	if n == 1 then
		return SHOWHAND_CARD_TYPE_ZILCH, {get_value(cards[1])}, get_color(cards[1])
	end

	local list = {}
	for i=1,n do
		list[i] = cards[i]
	end
	table.sort(list, function (a, b)
		return a > b
	end)

	local ret = self:analyseb_cards(list)
	local temp = ret[4]
	if temp then
		return SHOWHAND_CARD_TYPE_BOMB, temp
	end

	temp = ret[3]
	if temp then
		if #ret[2] > 0 then
			return SHOWHAND_CARD_TYPE_FULLHOUSE, temp
		else
			return SHOWHAND_CARD_TYPE_THREE, temp
		end
	end

	temp = #ret[2]
	if temp == 2 then
		local new_cards = {
			ret[2][1],
			ret[2][2], 
		}
		for _,v in ipairs(ret[1]) do
			table.insert(new_cards, v)
		end
		--其实不用get_color new_cards 里面的数值越大 color越大
		return SHOWHAND_CARD_TYPE_TWO_PAIRS, new_cards, get_color(ret[2][1])
	elseif temp > 0 then
		local new_cards = {
			get_value(ret[2][1]),
		}
		for _,v in ipairs(ret[1]) do
			table.insert(new_cards, get_value(v))
		end
		--同上
		return SHOWHAND_CARD_TYPE_ONE_PAIRS, new_cards, get_color(ret[2][1])
	end

	temp = self:is_straight(list)
	local flush = self:is_flush(list)

	if temp then
		if flush then
			return SHOWHAND_CARD_TYPE_STRAIGHT_FLUSH, list[1]
		else
			return SHOWHAND_CARD_TYPE_STRAIGHT, list[1]
		end
	end

	local clr = flush or get_color(list[1])
	--for i,v in ipairs(list) do
	--	list[i] = get_value(v)
	--end
	if flush then
		return SHOWHAND_CARD_TYPE_FLUSH, list, clr
	end

	return SHOWHAND_CARD_TYPE_ZILCH, list, clr
end

-- 心跳
function showhand_table:tick()
	if self.status == SHOWHAND_STATUS_PLAY then
		local curtime = get_second_time()
		if curtime - self.time0_ >= SHOWHAND_TIME_GIVEUP then
			-- 超时
			local player = self.player_list_[self.cur_turn]
			self:give_up(player)
			--self:add_score(player, 1)
			self.time0_ = curtime
		end
	end
	if self.status == SHOWHAND_STATUS_PLAYOFFLINE then
		local curtime = get_second_time()
		if curtime - self.time0_ >= SHOWHAND_TIME_WAIT_OFFLINE then
			for i,v in ipairs(self.player_list_) do
				if v.offtime then
					if curtime - v.offtime >= SHOWHAND_TIME_WAIT_OFFLINE then
						self:give_up(v)
					end
				end
			end
		end
	end
end

function  showhand_table:playeroffline( player )
	-- body
	--等 SHOWHAND_TIME_WAIT_OFFLINE 秒后 弃牌
	-- 玩家掉线
	if self.status == SHOWHAND_STATUS_PLAY then
		--有人掉线 通知玩家
		local notify = {
			cur_chair_id = player.chair_id,
			wait_time = SHOWHAND_TIME_WAIT_OFFLINE,
		}
		self:broadcast2client("SC_ShowHandCallScorePlayerOffline", notify)
		--设置状态为等待
		player.offtime = get_second_time()
		self.status = SHOWHAND_STATUS_PLAYOFFLINE
		self.time0_ = get_second_time()
	elseif self.status == SHOWHAND_STATUS_PLAYOFFLINE then
		local notify = {
			cur_chair_id = player.chair_id,
			wait_time = SHOWHAND_TIME_WAIT_OFFLINE,
		}
		self:broadcast2client("SC_ShowHandCallScorePlayerOffline", notify)
		player.offtime = get_second_time()
	end
end

function showhand_table:ready(player)
	base_table.ready(self,player)
	player.offtime = nil
end

--请求玩家数据
function showhand_table:ReconnectionPlayMsg(player)
	-- body self.round_
	print("player online : "..player.chair_id)
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
			header_icon = player:get_header_icon(),
			ip_area = p.ip_area,
		}
		notify.pb_visual_info = notify.pb_visual_info or {}
		table.insert(notify.pb_visual_info, v)
	end)	
	send2client_pb(player, "SC_PlayerReconnection", notify)

	self:recoveryplayercard(player)
	local notify = {
		cur_online_chair_id = player.chair_id,
		cur_chair_id = self.cur_turn,
	}
	self:broadcast2client("SC_ShowHandPlayerOnline", notify)
end

--恢复玩家当前数据
function  showhand_table:recoveryplayercard(player)
	-- 游戏进行时发牌
	if self.status == SHOWHAND_STATUS_PLAYOFFLINE then
		if not self.is_dead_[player.chair_id] then
			local notify = {
				cur_chair_id = self.cur_turn,
				call_score = self.last_score,
				cards = v_cards,
				Holecards = self.player_cards_[player.chair_id][5],
				pb_playerOfflineMsg = {},
				pb_other = {},
			}
			local v_cards = {}
			for i,v in ipairs(player_list_) do
				local m = {}
				m.chair_id = v.chair_id
				if not self.is_dead_[v.chair_id] then
					m.is_dead_ = false
					m.cards = {}
					if v.chair_id == player.chair_id then
						for  j = 1,(self.round_-1) do
							table.insert(v_cards,self.player_cards_[player.chair_id][j])
						end
					else
						for  j = 1,(self.round_-1) do
							table.insert(m.cards,self.player_cards_[v.chair_id][j])
						end
					end
				else
					m.isDead = true
				end
				table.insert(notify.pb_other,m)
			end
			--未处理断线信息 明天处理
			player.offtime = nil
			local waitT = 0
			for i,v in ipairs(self.player_list_) do
				if v then
					if v.offtime then
						local pptime = get_second_time() - v.offtime
						if pptime >= SHOWHAND_TIME_WAIT_OFFLINE then
							pptime = 0
						else
							pptime = SHOWHAND_TIME_WAIT_OFFLINE - pptime
						end
						local xxnotify = {
							chair_id = v.chair_id,
							outTimes = pptime,
						}
						table.insert(notify.pb_playerOfflineMsg, xxnotify)
						if v.offtime > waitT then
							waitT = v.offtime
						end
					end
				end
			end
			send2client_pb(player, "SC_ShowHandRecoveryPlayerCallScore", notify)
			if waitT == 0 then
				self.time0_ = get_second_time()
				self.status = SHOWHAND_STATUS_PLAY
			end
		end
	end
end