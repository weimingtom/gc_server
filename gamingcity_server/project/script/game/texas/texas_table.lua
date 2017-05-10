local pb = require "protobuf"
tablex = require "utils/tablex"

require "game/lobby/base_table"
require "game/texas/gamelogic"
require "data/texas_data"
require "table_func"

local ITEM_PRICE_TYPE_GOLD = pb.enum_id("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")
local GAME_SERVER_RESULT_SUCCESS = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")

texas_table = base_table:new()

local ROUND_THINK_TIME 		= 15
local ACTION_INTERVAL_TIME  = 1
local AWARD_TIME 			= 8

local POSITION_LITTLE_BLIND		= 1--小盲
local POSITION_BIG_BLIND 		= 2--大盲
local POSITION_BUTTON			= 3--庄家
local POSITION_NORMAL			= 4--普通玩家

local STATUS_WAITING  	= 1 
local STATUS_PRE_FLOP 	= 2
local STATUS_FLOP 		= 3
local STATUS_TURN 		= 4
local STATUS_RIVER 		= 5
local STATUS_SHOW_DOWN	= 6

--TABLE_STAT_WAITING  = 1	--等待/发牌环节
--TABLE_STAT_BETTING  = 1	--下注环节

local PLAYER_STATUS_WAITING	= 0		--等待
local PLAYER_STATUS_GAME	= 1
local PLAYER_STATUS_ALL_IN	= 2
local PLAYER_STATUS_FOLD	= 3
--local PLAYER_STATUS_LEAVE	= 4

local ACT_CALL 		= 1 --跟注2
local ACT_RAISE 	= 2 --加注
local ACT_CHECK 	= 3 --让牌
local ACT_FOLD 		= 4 --弃牌
local ACT_ALL_IN 	= 5 --全下
local ACT_NORMAL 	= 6 --普通
local ACT_THINK 	= 7 --牌局轮到此玩家，开始思考的计时状态
local ACT_WAITING	= 8 --刚进入的玩家

local CS_ERR_OK = 0 		--正常
local CS_ERR_MONEY = 1   --钱不够
local CS_ERR_STATUS = 2  --状态和阶段不同步错误

local LOG_MONEY_OPT_TYPE_TEXAS = 12

function texas_table:init_load_texas_config_file()	
 	package.loaded["data/texas_data"] = nil 
	require "data/texas_data"
end

function texas_table:load_texas_config_file()
	TEXAS_FreeTime = texas_room_config.Texas_FreeTime
	--print("BetTime = "..OX_TIME_ADD_SCORE)
end

--重置
function texas_table:reset()
	self.t_status = STATUS_WAITING
	self.t_timer = 0
	--self.t_status_table = TABLE_STAT_BETTING
	self.blind_small_bet = 10
	self.blind_big_bet = self.blind_small_bet * 2
	self.t_pot = 0		--主池
	self.t_idx = 1		--计算主池的index
	self.t_award_flag = 0

	self.t_side_pot = {}
	self.t_side_generator = {}
	--self.t_side_pot = {0,0,0,0,0,0}  -- for testing 
	
	self.think_time = ROUND_THINK_TIME
	--self.t_pot_player = {}	-- to load from config
	self.t_side_pot_players = {}
	self.t_public_cards = {}
	self.t_public_show = {}
	
	self.t_min_bet = 10		--read from config
	self.t_max_bet = 10000	--read from config
	self.t_bet = {}
	--self.t_cur_pot = 0
	self.t_cur_max_bet = 0
	self.t_cur_min_bet = 0
	self.t_round = 1
	self.play_count = 0
	self.pass_count = 0
	self.t_player_count = 0
	self.t_ready_begin = 0 
	self.t_active_player = {guid = 0,chair = 0}
	self.t_next_player = {guid = 0,chair = 0}
	self.t_SB_pos = {guid = 0,chair = 0}
	self.t_BB_pos = {guid = 0,chair = 0}
	self.t_final_pool = {}

	for t_guid, t_player in pairs(self.t_player) do
		self.t_bet[t_guid] = {0,0,0,0}
	end
end

-- 初始化
function texas_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)

	self.t_card_set = {
		0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,	--方块 A - K
		0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,	--梅花 A - K
		0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2A,0x2B,0x2C,0x2D,	--红桃 A - K
		0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x3A,0x3B,0x3C,0x3D,	--黑桃 A - K
	}
	base_table.init(self, room, table_id, chair_count)

	self.t_player = {}
	self:reset()
	--self:init_load_texas_config_file()
	--self:load_texas_config_file()
	
	--测试
--[[	self.t_bet[10] = {10,20,30,0}
	self.t_bet[20] = {10,20,30,40,0}
	self.t_bet[30] = {10,20,30,35}
	
	self:add_pool(10,30,3)
	self:add_pool(20,40,4)]]	
end

-- 心跳
function texas_table:tick()
	if get_second_time() < self.t_timer then 
		return
	end

	if self.t_player_count > 1 and self.t_ready_begin > 0 then
		if self.t_status == STATUS_WAITING and self.play_count == 0 then
		    self:position_init()
		else
			self:start_game()
		end
	end

	if self.t_status == STATUS_SHOW_DOWN then
		if self.t_award_flag == 0 then
			self:show_down_and_award()	--结算
		else
			self:info_ready_to_all()
		end
	end
end

function texas_table:count_ready_player()
	local len = 0
 	for k, p in pairs(self.t_player) do
        if p then
            len = len +1
        end
    end
	return len
end

function texas_table:position_init()
	self.play_count = self.t_player_count
	--大小盲注
	self:set_button_and_blind()
	
    local big_blind = self:get_big_blind()
	for i = 1,7 do
		local l_chair = big_blind.chair + i
		if l_chair > 7 then
			l_chair = l_chair - 7
		end

		local l_player = self:get_player(l_chair)
		if l_player and self.t_player[l_player.guid] and self.t_player[l_player.guid].status == PLAYER_STATUS_WAITING then
			self.t_active_player = {
				chair = l_chair,
				guid = l_player.guid 
			}
			break
		end
	end

	for i = 1,7 do
		local l_chair = self.t_active_player.chair + i
		if l_chair > 7 then
			l_chair = l_chair - 7
		end

		local l_player = self:get_player(l_chair)
		if l_player and self.t_player[l_player.guid] and self.t_player[l_player.guid].status == PLAYER_STATUS_WAITING then
			self.t_next_player = {
				chair = l_chair,
				guid = l_player.guid 
			}
			break
		end
	end

	-- if self.t_player[l_small_bind.guid].position ~= POSITION_BUTTON then
	-- 	self.t_player[l_small_bind.guid].position = POSITION_LITTLE_BLIND
	-- end

	-- if self.t_player[self.t_next_player.guid].position ~= POSITION_BUTTON then
	-- 	self.t_player[self.t_next_player.guid].position = POSITION_BIG_BLIND
	-- end

	self.t_timer = get_second_time() + ACTION_INTERVAL_TIME
end

--检查是否进入下一阶段
function texas_table:check_next_round()
	--检查是否所有玩家下注的钱 是否等于最大下注
	local in_game_num =0
	local all_in_num = 0
	for t_guid,v in pairs(self.t_player) do
		if v.status == PLAYER_STATUS_GAME then
			in_game_num = in_game_num + 1
			if self.t_cur_max_bet ~= self.t_bet[t_guid][self.t_round] then
				return false
			end
		elseif v.status == PLAYER_STATUS_ALL_IN then
			all_in_num = all_in_num + 1
		end
	end

	if in_game_num == 1 then
		if all_in_num == 0 then
			self.t_status = STATUS_SHOW_DOWN
		end
		self.t_timer = 0
		return true
	end

	--判断一轮下注过牌未全等
	if self.t_status > STATUS_WAITING and self.play_count > self.pass_count  then  --and self.t_cur_max_bet == 0 
		return false
	end

	-- if self.t_status == STATUS_PRE_FLOP and self.play_count ~= self.pass_count  then 
	-- 	return false 
	-- end

	self.t_timer = 0
	return true
end

--game
function texas_table:start_game()
	if self:check_next_round() then
		if self.t_status == STATUS_WAITING then 
			self:send_user_cards()
		elseif self.t_status < STATUS_SHOW_DOWN then
			self:send_public_cards()
		else
			return
		end
	else
		--押注切换   超时/玩家等待中/离线
		if get_second_time() > self.t_timer then
			if self.t_player[self.t_active_player.guid] and 
				self.t_player[self.t_active_player.guid].status == PLAYER_STATUS_GAME then
				self:cur_active_player_time_pass()
			end
			self:set_next_player()
		end
	end
end

function texas_table:send_user_cards()
	self.t_round = 1
	self.t_status = STATUS_PRE_FLOP
	self.play_count = 0
	self.pass_count = 0
	--self.t_cur_pot = 0		--当前轮底池清零
	self.t_cur_max_bet = 0	--最大下注清零

	local user_cards_idx = 0
	
	--5张公共牌
	for i = 0,4 do
		user_cards_idx = user_cards_idx + i
		local idx = math.random(1,#self.t_card_set - user_cards_idx)
		local card = self.t_card_set[idx]

		table.insert(self. t_public_cards, card)

		--把最后5张的牌移到之前抽出公共牌的地方,5个idx
		self.t_card_set[idx] = self.t_card_set[#self.t_card_set - user_cards_idx]
 		self.t_card_set[#self.t_card_set - user_cards_idx] = card
	end
	
	--扣除小盲注,底注
	local small_blind = self:get_small_blind()
	local l_player = self:get_player(small_blind.chair)
	self:add_bet(l_player, self.blind_small_bet)
	
	--扣除大盲注，2倍底注
	local big_blind = self:get_big_blind()
	l_player = self:get_player(big_blind.chair)
	self.t_cur_max_bet = self.blind_big_bet
	self:add_bet(l_player, self.blind_big_bet)

	--table info
	local notify = {}
	notify.pb_table = {
		state = STATUS_PRE_FLOP,
		pot = self.t_pot
	}
	notify.pb_user = {}

	--发牌给准备的玩家
	for _guid, p in pairs(self.t_player) do
		if self.t_player[_guid].status == PLAYER_STATUS_WAITING then
			local l_player = self:get_player(p.chair)
			if l_player then
				--选出两张牌发给玩家
				local l_user_cards = {}
				for i = 0,1 do
					user_cards_idx = user_cards_idx + i
					local idx = math.random(1,#self.t_card_set - user_cards_idx)
					local card = self.t_card_set[idx]
					table.insert(l_user_cards,card)
					self.t_card_set[idx] = self.t_card_set[#self.t_card_set - user_cards_idx]
					self.t_card_set[#self.t_card_set - user_cards_idx] = card
				end

				self.t_player[_guid].cards = l_user_cards
				self.t_player[_guid].status = PLAYER_STATUS_GAME
				
				local v = {
					guid = _guid,
					chair = p.chair,
					money = l_player:get_money(),
					hole_cards = 1,
					position = self.t_player[_guid].position,
					countdown = 0,
					bet_money = self.t_bet[_guid][self.t_round],
					win_money = 0,
					main_pot_money = 0
				}

				--当前玩家，动作为在思考
				if self.t_active_player.guid == _guid then
					v.countdown = ROUND_THINK_TIME
					v.action = ACT_THINK
				end
				
				table.insert(notify.pb_user, v)
				self.play_count = self.play_count + 1
			end
		end
	end
	
	--发给每个人(加上自己的底牌)
	local msg = notify
 	for k, p in pairs(notify.pb_user) do
		msg.pb_user[k].cards = self.t_player[p.guid].cards
		local l_player = self:get_player(p.chair)
		send2client_pb(l_player,"SC_TexasSendUserCards", msg)
		msg.pb_user[k].cards = {}
	end

	--清除准备状态进入游戏  
	--self:clear_ready() base_table:clear_ready()
	self.t_timer = get_second_time() + ROUND_THINK_TIME
end


function texas_table:send_public_cards()	
	--下一轮
	self.t_status = self.t_status + 1
	if self.t_status > STATUS_RIVER then
		return
	end

	if #self.t_side_generator > 0 then
		self:cal_side_pot()
	end

	self.t_round = self.t_round + 1	
	--self.t_cur_pot = 0	  --当前轮底池清零
	self.t_cur_max_bet = 0	  --最大下注清零
	self.pass_count = 0
	self.play_count = 0

	--公共牌
	--self.t_public_show = self.t_public_cards		
	self.t_public_show = {}
	for i = 1, self.t_status do
		table.insert(self.t_public_show, self.t_public_cards[i])
	end

	--公共牌增量
	local l_public_show = {}
	if self.t_status == STATUS_FLOP then
		l_public_show = self.t_public_show
	else
		l_public_show[1] = self.t_public_show[self.t_status]
	end

	local msg = {}
	msg.pb_table = {
		state = self.t_status,
		public_cards = self.t_public_show,
		side_pot = self.t_side_pot
	}
	msg.pb_user = {}
	msg.public_cards = l_public_show

	--本轮牌桌上玩家状态重置 bet_money, action
	for t_guid, t_player in pairs(self.t_player) do		
		local l_player = self:get_player(t_player.chair)
		if l_player then			

			local l_has_cards = 1
			if self.t_player[t_guid].status == PLAYER_STATUS_GAME then
				self.play_count = self.play_count + 1
			elseif self.t_player[t_guid].status == PLAYER_STATUS_WAITING or 
				self.t_player[t_guid].status == PLAYER_STATUS_FOLD then
				l_has_cards = 0
			end

			local l_user = {
				chair = l_player.chair_id,
				guid = t_guid,
				money = l_player:get_money(),
				bet_money = self.t_bet[t_guid][self.t_round],
		 		hole_cards = l_has_cards,
				countdown = 0,
				win_money = 0,
				main_pot_money = 0
			}
			
			table.insert(msg.pb_user, l_user)
		end
	end
	self:t_broadcast("SC_TexasSendPublicCards", msg)

	if self.play_count > 1 then
	    --第一个行动 小盲位
		local l_SB = self:get_small_blind()
		self.t_active_player.chair = l_SB.chair
		self.t_active_player.guid = l_SB.guid
		--确定t_next_player
		for i = 1,7 do
			local l_chair = self.t_active_player.chair + i
			l_chair = l_chair > 7 and l_chair - 7 or l_chair

			local l_player = self:get_player(l_chair)
			if l_player and self.t_player[l_player.guid] and self.t_player[l_player.guid].status == PLAYER_STATUS_GAME then
				self.t_next_player = {
					chair = l_chair,
					guid = l_player.guid 
				}
				break
			end
		end

	    --wait to added 中间加延时
		if self.t_player[self.t_active_player.guid] and 
			self.t_player[self.t_active_player.guid].status == PLAYER_STATUS_GAME then
			local nofity = {
				chair = self.t_active_player.chair,
				action = ACT_THINK,
				bet_money = 0
			}
			local l_player = self:get_player(self.t_active_player.chair)
			nofity.pb_action = {
				chair = self.t_active_player.chair,
				guid = self.t_active_player.guid,
				money = l_player:get_money(),
				bet_money = self.t_bet[self.t_active_player.guid],
				action = ACT_THINK,
		 		hole_cards = 1,
				countdown = ROUND_THINK_TIME + 1,
				win_money = 0,
				main_pot_money = 0
			}
			nofity.pb_table = {
				state = self.t_status,
				max_bet = self.t_cur_max_bet,
				min_bet = self.t_cur_min_bet,
				pot = self.t_pot,
			}
			self:t_broadcast("SC_TexasUserAction",nofity)
		else
			--如果小盲位已弃牌，查找下一个玩家
			self:set_next_player()
		end
		--发牌后需要播动画，时间加长延迟
		self.t_timer = get_second_time() + ROUND_THINK_TIME + ACTION_INTERVAL_TIME
	else
		--只有一位玩家，直接发牌
		self.t_timer = get_second_time() + ACTION_INTERVAL_TIME
	end
end


--确定庄家，盲位
function texas_table:set_button_and_blind()
	local l_player = nil
	local l_chair = nil
	if self.t_button == nil then	--or self.t_button.chair == 0
		self.t_button = {}
		for t_guid, t_player in pairs(self.t_player) do		
			l_player = self:get_player(t_player.chair)
			if l_player then
				self.t_button.chair = t_player.chair
				self.t_button.guid = t_guid

				self.t_player[t_guid].position = POSITION_BUTTON
				break
			end
		end
	else
		l_chair = self.t_button.chair
		self.t_player[self.t_button.guid].position = POSITION_NORMAL
		for i = 1,7 do
			l_chair = self.t_button.chair + i
			l_chair = l_chair > 7 and l_chair - 7 or l_chair
			l_player = self:get_player(l_chair)
			if l_player and self.t_player[l_player.guid] then
				self.t_button = {chair = l_chair, guid = l_player.guid}
				self.t_player[l_player.guid].position = POSITION_BUTTON
				break
			end
		end
	end

	--大小盲位
	for i = 1,7 do
		l_chair = self.t_button.chair + i
		l_chair = l_chair > 7 and l_chair - 7 or l_chair
		l_player = self:get_player(l_chair)
		if l_player and self.t_player[l_player.guid] then 
			if self.t_SB_pos.guid == 0 then
				self.t_SB_pos = {chair = l_chair, guid = l_player.guid}
			else
				self.t_BB_pos = {chair = l_chair, guid = l_player.guid}
				break
			end
		end
	end
end

--获取小盲位
function texas_table:get_small_blind()
	return self.t_SB_pos
end

--获取大盲位
function texas_table:get_big_blind()
	return self.t_BB_pos
end


--超时
function texas_table:cur_active_player_time_pass()
	--当前玩家
	local msg = {
		chair = self.t_active_player.chair,
		bet_money = self.t_bet[self.t_active_player.guid][self.t_round]
	}
	local l_player = self:get_player(self.t_active_player.chair)
	if l_player then
		--checked !!   如果当前玩家本轮已下注筹码，小于本轮桌上评价每一份筹码，弃牌
		if self.t_bet[l_player.guid][self.t_round] == self.t_cur_max_bet then
			--超时让牌

			self.pass_count = self.pass_count + 1
			msg.action = ACT_CHECK
		else

			-- 	self.t_player[self.t_active_player.guid].status = PLAYER_STATUS_FOLD
			-- 	--超时弃牌
			-- 	msg.pb_action.action = ACT_FOLD
			-- 	msg.action = ACT_FOLD
			-- 	self.play_count = self.play_count - 1
			-- end
			--self.t_player[self.t_active_player.guid].status = PLAYER_STATUS_FOLD


			local own_money = l_player:get_money()

			--测试用 默认跟注 for testing
			local l_bet_money = self.t_cur_max_bet - self.t_bet[l_player.guid][self.t_round]

			--钱不够，全下
			if own_money <= l_bet_money then
				l_bet_money = own_money
				msg.action = ACT_ALL_IN
				self.t_player[l_player.guid].status = PLAYER_STATUS_ALL_IN

				self.play_count = self.play_count - 1
			else 
				msg.bet_money = l_bet_money	--增量
				msg.action = ACT_CALL

				self.pass_count = self.pass_count + 1
			end

			self:add_bet(l_player, l_bet_money)
		end
		--广播玩家动作
		msg.pb_action = {
			guid = self.t_active_player.guid,
			chair = self.t_active_player.chair,
			money = l_player:get_money(),
			bet_money = self.t_bet[l_player.guid][self.t_round],
			action = msg.action,
	 		hole_cards = 1,
			countdown = 0,
			win_money = 0,
			main_pot_money = 0
		}

		msg.pb_table = {
			state = self.t_status,
			pot = self.t_pot,
			side_pot = self.t_side_pot
		}
		self:t_broadcast("SC_TexasUserAction", msg)
	end
end

--设置下一个说话玩家
function texas_table:set_next_player()
	if self:check_next_round() then
		return
	end

	self.t_active_player.guid = self.t_next_player.guid
	self.t_active_player.chair = self.t_next_player.chair

	for i = 1,7 do
		local l_chair = self.t_next_player.chair + i
		if l_chair > 7 then
			l_chair = l_chair - 7
		end

		local l_player = self:get_player(l_chair)
		if l_player and self.t_player[l_player.guid] and self.t_player[l_player.guid].status == PLAYER_STATUS_GAME then
			-- wait to set next player
			self.t_next_player = {
				guid = l_player.guid,
				chair = l_chair
			}

			--broadcasst next turn l_player is in thinking
			local tmp_player = self:get_player(self.t_active_player.chair)
			if tmp_player then
				local msg = {
					chair = self.t_active_player.chair,
					action = ACT_THINK,
					bet_money = 0
				}
				msg.pb_table = {
					state = self.t_status,
					pot = self.t_pot
				}

				msg.pb_action = {
					guid = self.t_active_player.guid,
					chair = self.t_active_player.chair,
					money = tmp_player:get_money(),
					hole_cards = 1,
					action = ACT_THINK,
					countdown = ROUND_THINK_TIME,
					bet_money = self.t_bet[self.t_active_player.guid][self.t_round],
					win_money = 0,
					main_pot_money = 0
				}
				self:t_broadcast("SC_TexasUserAction", msg)
				self.t_timer = get_second_time() + ROUND_THINK_TIME
				return
			end
		end
	end
	--异常退出
	self.t_timer = get_second_time() + ACTION_INTERVAL_TIME
end

--结算 --发放奖励
function texas_table:show_down_and_award()	
	if #self.t_side_generator > 0 then
		self:cal_side_pot()
	end

	--同步游戏数据
	local msg = {}
	msg.pb_table = {
		state = self.t_status,
		pot = self.t_pot,
		side_pot = self.t_side_pot,
	}
	msg.pb_user = {}

	local t_side_pool_array = {}
	--设置sc_proto返回数组
	for k, _guid in ipairs(self.t_side_pot) do
		table.insert(t_side_pool_array, 0)
	end

	local in_game_num =0
	for t_guid, v in pairs(self.t_player) do
		if v.status == PLAYER_STATUS_GAME or v.status == PLAYER_STATUS_ALL_IN then
			in_game_num = in_game_num + 1
		end
	end

	if in_game_num < 2 or self.t_player_count < 2 then
		self:show_down_with_one_player(msg, t_side_pool_array)
		return
	end

	--每个玩家计算牌型
	for t_guid, t_player in pairs(self.t_player) do		
		local l_player = self:get_player(t_player.chair)
		if l_player then
			local l_cards = {}
			local l_user = {
				chair = t_player.chair,
				guid = t_guid,
				bet_money = self.t_bet[t_guid][self.t_round],
				hole_cards = 0,
				cards = self.t_player[t_guid].cards,
				countdown = 0,
				victory = 2,	        -- 1-win; 2-lose
				biggest_winner = 2,
				win_money = 0,
				main_pot_money = 0,
			}

			if self.t_player[t_guid].status == PLAYER_STATUS_GAME or
			   self.t_player[t_guid].status == PLAYER_STATUS_ALL_IN then
				l_cards = tablex.copy(self.t_player[t_guid].cards)
				
				if #self.t_public_show == 5 then
					l_user.cards_type = t_get_type_five_from_seven(l_cards,self.t_public_show)
				end
				-- elseif #self.t_public_show == 3 then
				--  	local cards = tablex.copy(l_cards)
				--  	for k,v in ipairs(self.t_public_show) do
				--  		table.insert(table,v)
				-- 	end
				--  	l_user.cards_type = t_get_card_type(cards)
				-- elseif #self.t_public_show == 4 then
				--  	l_user.cards_type = t_get_type_five_from_six(l_cards,self.t_public_show)
				-- end
			end
			
			msg.pb_user[t_player.chair] = l_user;
		end
	end


	local l_candidate = {}
	for guid, t_player in pairs(self.t_player) do
        if t_player.status == PLAYER_STATUS_GAME or t_player.status == PLAYER_STATUS_ALL_IN  then
			local l_info = {guid = guid, card_type = 0,cards = {}}
			l_info.card_type, l_info.cards = t_get_type_five_from_seven(self.t_player[guid].cards, self.t_public_cards)
			table.insert(l_candidate, l_info)
        end
	end

	local l_card_type, main_win_array = get_win_player(l_candidate)

	local per_money_from_main_pot = math.floor(self.t_pot / #main_win_array)
	
	--最后玩家赢取的筹码池
	self.t_final_pool = {}

	--主池赢家
	for k, _guid in ipairs(main_win_array) do
		self.t_final_pool[_guid] = per_money_from_main_pot
		
		local mian_chair = self.t_player[_guid].chair
		msg.pb_user[mian_chair].victory = 1
		msg.pb_user[mian_chair].biggest_winner = 1	--biggest winnwer
		msg.pb_user[mian_chair].main_pot_money = per_money_from_main_pot
	end

	--遍历所有边池，计算每个边池赢家
	for _pot_id, _pot_money in ipairs(self.t_side_pot) do
		local side_win_num = 0
		local per_money_form_one_side_pot = 0
		local side_pot_winner_flag = 0
		local side_candidate = {}
		
		if self.t_side_pot_players[_pot_id] then
			for p_key, p_guid in ipairs(self.t_side_pot_players[_pot_id]) do
				--统计主池赢家在当前边池里的数量
				if self.t_final_pool[p_guid] then
					side_pot_winner_flag = side_pot_winner_flag + 1
				end

				local l_info = {guid = p_guid, card_type = 0,cards = {}}
				l_info.card_type, l_info.cards = t_get_type_five_from_seven(self.t_player[p_guid].cards, self.t_public_cards)
				table.insert(side_candidate, l_info)
			end
		end

		--如果赢家在边池里，赢家分享边池
		if side_pot_winner_flag > 0 then
			per_money_form_one_side_pot = math.floor(_pot_money / side_pot_winner_flag)

			for p_key, p_guid in ipairs(self.t_side_pot_players[_pot_id]) do
				if self.t_final_pool[p_guid] then
					self.t_final_pool[p_guid] = self.t_final_pool[p_guid] + per_money_form_one_side_pot

					local side_chair = self.t_player[p_guid].chair
					-- if msg.pb_user[side_chair].side_pot_money == nil then
					-- 	msg.pb_user[side_chair].side_pot_money = t_side_pool_array
					-- end

					msg.pb_user[side_chair].side_pot_money = msg.pb_user[side_chair].side_pot_money or t_side_pool_array
					msg.pb_user[side_chair].side_pot_money[_pot_id] = per_money_form_one_side_pot
				end
			end
		else 
			--主池赢家不在边池中，重新计算边池赢家
			local l_card_type, side_win_array = get_win_player(side_candidate)
			local per_money_form_one_side_pot = math.floor(_pot_money / #side_win_array)

			for p_key, p_guid in ipairs(side_win_array) do
				self.t_final_pool[p_guid] = self.t_final_pool[p_guid] or 0
				self.t_final_pool[p_guid] = self.t_final_pool[p_guid] + per_money_form_one_side_pot
				local side_chair = self.t_player[p_guid].chair

				local side_chair = self.t_player[p_guid].chair
				-- if msg.pb_user[side_chair].side_pot_money == nil then
				-- 	msg.pb_user[side_chair].side_pot_money = t_side_pool_array
				-- end

				msg.pb_user[side_chair].side_pot_money = msg.pb_user[side_chair].side_pot_money or t_side_pool_array
				msg.pb_user[side_chair].side_pot_money[_pot_id] = per_money_form_one_side_pot
			end
		end
	end

	--返回消息
	for _guid, _final_money in pairs(self.t_final_pool) do
		if self.t_player[_guid] then
			local l_chair = self.t_player[_guid].chair
			local l_player = self:get_player(l_chair)
			if l_player then
				msg.pb_user[l_chair].win_money = _final_money
				l_player:add_money(
					{{ money_type = ITEM_PRICE_TYPE_GOLD, 
					money = _final_money }}, 
					LOG_MONEY_OPT_TYPE_TEXAS
				)
				print("-------player add money",_guid,"   ",_final_money)
			end
		end
	end

	for i, _v in pairs(msg.pb_user) do
		local l_player = self:get_player(msg.pb_user[i].chair)
		if l_player then
			msg.pb_user[i].money = l_player:get_money()
		end
	end

	--for id, val in pairs(l_players) do table.insert(msg.pb_user, val) end
	self:t_broadcast("SC_TexasTableEnd", msg)
	--重置
	self.t_award_flag = 1
	self.t_timer = get_second_time() + AWARD_TIME
end


function texas_table:show_down_with_one_player(msg, t_side_pool_array)
	local survive_player = {
		chair = 0,
		guid = 0
	}
	local last_one_win_money = 0
	for _guid, t_player in pairs(self.t_player) do
		local player = self:get_player(t_player.chair)
		if player and self.t_player[_guid] then
			local val = {
				guid = _guid,
				chair = t_player.chair,
				money = player:get_money(),
				hole_cards = 1,
				countdown = l_countdown,
				bet_money = self.t_bet[_guid][self.t_round],
				tax = 1,
				victory = 2,
				biggest_winner = 2,
				win_money = 0,
				main_pot_money = 0
			}

			if self.t_player[_guid].status == PLAYER_STATUS_GAME or 
				self.t_player[_guid].status == PLAYER_STATUS_ALL_IN then
				val.win_money = self.t_pot
				val.biggest_winner = 1
				val.victory = 1
				val.win_money = last_one_win_money
				val.main_pot_money = main_pot_money
				survive_player.chair = t_player.chair
				survive_player.guid = _guid
			end
			table.insert(msg.pb_user, val)
		end
	end

	if survive_player.chair then
		for _pot_id, _pot_money in ipairs(self.t_side_pot) do
			local side_win_num = 0
			local per_money_form_one_side_pot = 0
			local side_pot_winner_flag = 0
			local side_candidate = {}
			
			--如果赢家在当前边池里，单独分享边池
			for p_key, p_guid in ipairs(self.t_side_pot_players[_pot_id]) do
				if p_guid == survive_player.guid then
					last_one_win_money = last_one_win_money + _pot_money

					msg.pb_user[1].side_pot_money = msg.pb_user[1].side_pot_money or t_side_pool_array
					msg.pb_user[1].side_pot_money[_pot_id] = _pot_money
				end
			end		
		end
		msg.pb_user[1].win_money = msg.pb_user[1].win_money + last_one_win_money

		--返回消息
		local l_player = self:get_player(survive_player.chair)
		if l_player then
			l_player:add_money(
				{{money_type = ITEM_PRICE_TYPE_GOLD, 
				money = msg.pb_user[1].win_money}}, 
				LOG_MONEY_OPT_TYPE_TEXAS
			)
		end
	end
	
	self:t_broadcast("SC_TexasTableEnd", msg)
	--重置
	self.t_award_flag = 1
	self.t_timer = get_second_time() + AWARD_TIME
end

--玩家下注
function texas_table:add_bet(player, money)
	-- if not player or player:get_money() < money then
	-- 	return false
	-- end
	
	print("  [[[-------------  ]]]] bet money: ", money)

	player:cost_money(
		{{money_type = ITEM_PRICE_TYPE_GOLD, money = money}}, 
		LOG_MONEY_OPT_TYPE_TEXAS
	)

	--to be check!!!	
	--self.t_cur_pot = self.t_cur_pot + money

	self.t_pot = self.t_pot + money
	self.t_bet[player.guid][self.t_round] = self.t_bet[player.guid][self.t_round] + money

	--当前最大注
	if self.t_bet[player.guid][self.t_round] >= self.t_cur_max_bet then
		self.t_cur_max_bet = self.t_bet[player.guid][self.t_round]
	end

	if player:get_money() == 0 then
		--player.guid == self.t_button.guid then --if player:get_money() == 0 then
		self.t_player[player.guid].status = PLAYER_STATUS_ALL_IN
		
		self:record_side_generator(player.guid)
		--local diff_money = self.t_cur_max_bet - self.t_bet[player.guid][self.t_round]
		--if diff_money > 0 then
		--记录边池拥有玩家
		--self:add_side_pot(diff_money) --player.guid for testing
	end

	-- if self.t_status > STATUS_WAITING then --for testing
	-- 	self:add_side_pot(50, 3) end
	return true
end

--计算边池
function texas_table:record_side_generator(guid)
	table.insert(self.t_side_generator, guid)
end

--增加边池记录
function texas_table:cal_side_pot()	--  t_guid for testing
	--local round_allin_num = #self.t_side_generator
	--local _allin_bet_list = {}
	local side_pot_id = 1
	for _id, g_guid in pairs(self.t_side_generator) do
		
		--table.insert(_allin_bet_list, g_bet_money)
		local g_bet_money = self.t_bet[g_guid][self.t_round]   --5  10 15
		local g_min_bet_money = self.t_cur_max_bet			   --10 15 20	
		local side_money = 0
		
		local g_bigger_than_min_num = 0
		for t_guid, t_player in pairs(self.t_player) do
			
			--只要比全下玩家大，都计入统计
	        if self.t_bet[t_guid][self.t_round] > g_bet_money then  
	        	g_bigger_than_min_num = g_bigger_than_min_num + 1
				
				self.t_side_pot_players[side_pot_id] = self.t_side_pot_players[side_pot_id] or {}
				table.insert(self.t_side_pot_players[side_pot_id], t_guid)
				--找除了此全下玩家之外，最小下注筹码
				if self.t_bet[t_guid][self.t_round] < g_min_bet_money  then
		        	g_min_bet_money = self.t_bet[t_guid][self.t_round]
		        end
	        end
	    end
	    side_money = g_bigger_than_min_num * (g_min_bet_money - g_bet_money)

	    --在玩数量 self.play_count
	    -- side_money = side_money + money           
	    -- self.t_side_pot_players[side_pot_num] = self.t_side_pot_players[side_pot_num] or {}
	    -- table.insert(self.t_side_pot_players[side_pot_num], t_guid)

		self.t_side_pot[side_pot_id] = side_money
		side_pot_id = side_pot_id + 1
	end

    self.t_side_generator = {}
end

--动作处理
function texas_table:player_action(player, talbeInstance, t_action, t_money)
	if self.t_active_player.guid ~= player.guid then
		return CS_ERR_STATUS
	end

	if t_money < 0 then
		t_money = 0
	end
	
	--cur player action
	local l_money = t_money
	local msg = {
		chair = player.chair_id,
		action = t_action,
		bet_money = l_money
	}

	print("   (((--- player_action  ---)))   guid: ", player.guid, "  action: ",t_action)
	--t_var_dump(msg)

	if t_action == ACT_CHECK then
		if self.t_cur_max_bet ~= self.t_bet[player.guid][self.t_round] then
			return CS_ERR_STATUS
		end

		self.pass_count = self.pass_count + 1
		msg.bet_money = 0
	elseif t_action == ACT_FOLD then
		self.t_player[player.guid].status = PLAYER_STATUS_FOLD

		self.play_count = self.play_count - 1
		msg.bet_money = 0
	elseif t_action == ACT_RAISE then
		if t_money == 0 then
			return CS_ERR_MONEY
		end
		local own_money = player:get_money()

		if t_money >= own_money then
			t_money = own_money
			t_action = ACT_ALL_IN			

			self.t_player[player.guid].status = PLAYER_STATUS_ALL_IN

			self.play_count = self.play_count - 1
		else 
			self.pass_count = self.pass_count + 1
		end

		-- t_money > self.t_cur_max_bet	or t_money < self.t_cur_min_bet
		-- if t_money > own_money or t_money > self.t_pot then
		-- 	return CS_ERR_MONEY
		-- end

		msg.bet_money = t_money
		self:add_bet(player, t_money)
	elseif t_action == ACT_CALL then
		t_money = self.t_cur_max_bet - self.t_bet[player.guid][self.t_round]
		if t_money == 0 then
			return CS_ERR_MONEY
		end

		local own_money = player:get_money()
		if t_money >= own_money then
			t_money = own_money
			t_action = ACT_ALL_IN			

			self.t_player[player.guid].status = PLAYER_STATUS_ALL_IN

			self.play_count = self.play_count - 1
		else
			self.pass_count = self.pass_count + 1
		end		

		msg.bet_money = t_money
		self:add_bet(player, t_money)
	elseif t_action == ACT_ALL_IN then
		local own_money = player:get_money()
		self.t_player[player.guid].status = PLAYER_STATUS_ALL_IN
		t_money = own_money

		self.play_count = self.play_count - 1

		-- t_money > self.t_cur_max_bet	or t_money < self.t_cur_min_bet
		-- if t_money > own_money or t_money > self.t_pot then
		-- 	return CS_ERR_MONEY
		-- end

		msg.bet_money = t_money
		self:add_bet(player, t_money)
		--本轮最小下注 = 本轮最大下注-本轮玩家已下注
		--self.t_cur_min_bet = self.t_cur_max_bet - self.t_bet[player.guid][self.t_round]
	end
	t_var_dump(msg)
	
	--广播玩家动作
	msg.pb_action = {
		chair = player.chair_id,
		guid = player.guid,
		money = player:get_money(),
		bet_money = self.t_bet[player.guid][self.t_round],
		action = t_action,
 		hole_cards = 1,
		countdown = 0,
		win_money = 0,
		main_pot_money = 0
	}

	msg.pb_table = {
		state = self.t_status,
		max_bet = self.t_cur_max_bet,
		--min_bet = self.small_blind,
		pot = self.t_pot,
	}

	--计算边池 wait to added
	self:t_broadcast("SC_TexasUserAction", msg)
	
	--下一玩家
	self:set_next_player()

	return CS_ERR_OK
end


--打赏荷官
function texas_table:reward_dealer(player)
	self:broadcast2client("SC_TexasReward",{guid = player.guid})
end

function texas_table:info_ready_to_all()
	if get_second_time() < self.t_timer then
		return
	end

	self:reset()
	local notify = {}
	notify.pb_user = {}
	notify.pb_table = {
		state = self.t_status,
		min_bet = self.blind_small_bet,
		max_bet	= self.blind_small_bet*5,
		blind_bet = self.blind_small_bet,
		pot = self.t_pot,
		side_pot = {},
		think_time = 15,
		public_cards = {},
	}

	--遍历桌上其它玩家的数据
	for i, p in pairs(self.player_list_) do
		if self.player_list_[i] ~= false then
			local l_player = self.player_list_[i]
			if self.player_list_[i].is_offline == true then		
				print("----------offline exit----------------")
				l_player:forced_exit()
				logout(l_player.guid)
			else
				--检查T人
				print("-----------check_money-----------------")
				local room_limit = self.room_:get_room_limit()
				local _l_money = l_player:get_money()
				l_player:check_forced_exit(room_limit)
				if  _l_money < room_limit then
					local msg = {}
					msg.reason = "金币不足，请您充值后再继续"
					send2client_pb(l_player, "SC_TexasForceLeave", msg)
					l_player:forced_exit()
				elseif self.t_player[p.guid] then
					self.t_player[p.guid].cards = {}
					self.t_player[p.guid].status = PLAYER_STATUS_WAITING
					self.t_bet[p.guid] = {0,0,0,0}

					local l_player = self:get_player(p.chair_id)
					if l_player then
						local v = {
							chair = p.chair_id,
							guid = p.guid,
							icon =  p:get_header_icon(),
							name = p.nickname,
							money = p:get_money(),
							bet_money = 0,
							position = POSITION_NORMAL,
							hole_cards = 0,
							cards = {},
							countdown = 0,
							victory = 3,
							biggest_winner = 2,
							win_money = 0,
							main_pot_money = 0
						}
						table.insert(notify.pb_user, v)
					end
				end
			end
		end
	end

	local tmp_player = {}
	for i, _v in pairs(notify.pb_user) do
		local l_chair = notify.pb_user[i].chair
		notify.pb_table.own_chair = l_chair
		notify.pb_user[i].position = self.t_player[_v.guid].position

		tmp_player = self:get_player(l_chair)
		if tmp_player then
			send2client_pb(tmp_player, "SC_TexasTableInfo", notify)
		end
	end
	print("--------------- begin new game  SC_TexasTableInfo -----------------")


	self.t_timer = get_second_time() + ACTION_INTERVAL_TIME	+ 1
	self.t_player_count = self:count_ready_player()
	if self.t_player_count > 1 then
		self.t_ready_begin = 1
		self.t_status = STATUS_WAITING
	end
end

-- 进入房间并坐下
function texas_table:do_sit_down(player)
	print("||||| ----do_sit_down---- |||||", player.guid)
	local notify = {}
	notify.pb_user = {}
	notify.pb_table = {
		state = self.t_status,
		min_bet = self.t_min_bet,
		max_bet	= self.t_max_bet,
		blind_bet = self.blind_small_bet,
		pot = self.t_pot,
		side_pot = self.t_side_pot,
		think_time = 15,
		public_cards = self.t_public_show,
		own_chair = player.chair_id
	}

	local newPlayerVal = {
		chair = player.chair_id,
		guid = player.guid,
		icon =  player:get_header_icon(),
		name = player.nickname,
		money = player:get_money(),
		bet_money = 0,
		action = ACT_WAITING,
		position = POSITION_NORMAL,
		hole_cards = 0,
		cards = {},
		countdown = 0,
		victory = 3,
		win_money = 0,
		main_pot_money = 0
	}
	local toNewUser = {}
	toNewUser.pb_user = newPlayerVal
	table.insert(notify.pb_user, newPlayerVal)

	--遍历桌上其它玩家的数据
	for _guid, p in pairs(self.t_player) do
		local l_player = self:get_player(p.chair)
		if l_player then
			local l_hole_cards = 1
			if self.t_player[_guid].status == PLAYER_STATUS_WAITING or 
				self.t_player[_guid].status == PLAYER_STATUS_FOLD then
				l_hole_cards = 0
			end

			local l_bet_money = self.t_bet[_guid][self.t_round] or 0
			
			local v = {
				chair = p.chair,
				guid = _guid,
				icon =  l_player:get_header_icon(),
				name = l_player.nickname,
				money = l_player:get_money(),
				bet_money = l_bet_money,
				position = self.t_player[_guid].position,
		 		hole_cards = l_hole_cards,
				cards = self.t_player.cards,
				countdown = 0,
				victory = 3,
				biggest_winner = 2,
				win_money = 0,
				main_pot_money = 0
			}
			table.insert(notify.pb_user, v)
			send2client_pb(l_player, "SC_TexasNewUser", toNewUser)
		end
	end
	
	send2client_pb(player, "SC_TexasTableInfo", notify)
	print("--------------- player_sit_down  SC_TexasTableInfo -----------------chair.id: ",player.chair_id)
	--t_var_dump(notify)

	print("--------------- newUser comming  SC_TexasNewUser-----------------chair.id: ",player.chair_id)
	--t_var_dump(toNewUser)
	-- for _guid, p in pairs(self.t_player) do
	-- 	if l_player and player.guid ~= _guid then
	-- 		send2client_pb(l_player, "SC_TexasNewUser", toNewUser)
	-- 	end
	-- end
	

	self.t_player[player.guid] = {
		chair = player.chair_id,
		cards = {},
		status = PLAYER_STATUS_WAITING,
		action = ACT_WAITING,
		position = POSITION_NORMAL
	}
	self.t_bet[player.guid] = {0,0,0,0}
	
	self.t_timer = get_second_time() + ACTION_INTERVAL_TIME
	self.t_player_count = self.t_player_count + 1
	if self.t_player_count > 1 then
		self.t_ready_begin = 1
	end
end

function texas_table:reconnect(player)
	print("texas_table:reconnect~~~~~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!",player.chair_id)
	print("---------- reconnect~~~~~~~~~!",player.guid)

	--send2client_pb(player, "SC_ZhaJinHuaReConnect", msg)
	return
end

--玩家坐下、初始化
function texas_table:player_sit_down(player, chair_id_)
	print("---------------texas_table player_sit_down  -----------------", chair_id_)
	for i,v in pairs(self.player_list_) do
		if v == player then
			player:on_stand_up(self.table_id_, v.chair_id, GAME_SERVER_RESULT_SUCCESS)
			return
		end
	end
	
	player.table_id = self.table_id_
	player.chair_id = chair_id_
	player.room_id = self.room_.id
	self.player_list_[chair_id_] = player

	log_info(string.format("GameInOutLog,texas_table:player_sit_down, guid %s, table_id %s, chair_id %s",
	tostring(player.guid),tostring(player.tzable_id),tostring(player.chair_id)))
end


function texas_table:sit_on_chair(player, _chair_id)
	print ("get_sit_down-----------------  texase   ----------------")
	local result_, table_id_, chair_id_ = base_room_manager.sit_down(self, player, self.table_id_, _chair_id)

	print ("player.room_id_, player.table_id_, player.chair_id",self.room_.id, self.table_id_, _chair_id)
	self:do_sit_down(player)
end

--玩家站起离开房间
function texas_table:player_stand_up(player, is_offline)
	log_info(string.format("GameInOutLog,texas_table:player_stand_up, guid %s, table_id %s, chair_id %s, is_offline %s",
	tostring(player.guid),tostring(player.table_id),tostring(player.chair_id),tostring(is_offline)))

	print("!!!!!-----------STAND_UPPPP --------------" ,player.chair_id, is_offline)	
    print(player.table_id,player.chair_id,player.guid)
	
	self.t_player_count = self.t_player_count - 1
	if self.t_player[player.guid] and (self.t_player[player.guid].status == PLAYER_STATUS_GAME or 
		self.t_player[player.guid].status == PLAYER_STATUS_ALL_IN) then
		self.play_count = self.play_count - 1
	end

	if self.t_button and player.guid == self.t_button.guid then
		self.t_button = nil
	end

    --广播此玩家离线
    local msg = {}
	msg.pb_user = {
		guid = player.guid,
		chair = player.chair_id,
		action = ACT_FOLD,
		money = 0,
		hole_cards = 0,
		countdown = 0,
		win_money = 0,
		main_pot_money = 0
	}
	self:t_broadcast("SC_TexasUserLeave", msg)
	t_var_dump(msg)

	base_table.player_stand_up(self,player,is_offline)
	self.room_:player_exit_room(player)
	self.t_player[player.guid] = nil

	if self.t_player_count < 1 then
		self:reset()
		return
	end
	
    if self.t_player_count < 2 then
    	if self.t_pot == 0 then
    		self:info_ready_to_all()
		else
			self.t_status = STATUS_SHOW_DOWN
		end
    	return
	end

	if player.chair_id == self.t_active_player.chair then
		self:set_next_player()
	elseif player.chair_id == self.t_next_player.chair then
		for i = 1,7 do
			l_chair = player.chair_id + i
			if l_chair > 7 then
				l_chair = l_chair - 7
			end

			local player = self:get_player(l_chair)
			if player and self.t_player[player.guid] and self.t_player[player.guid].status == PLAYER_STATUS_GAME 
			then
				self.t_next_player = {
					guid = player.guid,
					chair = l_chair
				}
				return
			end
		end
	end
end

function texas_table:player_leave(player)
	print ("player_leave-----------------  texase   ----------------")
	--self.player_online[player.chair_id] = true
	print ("player.room_id_, player.table_id_, player.chair_id",self.room_.id, self.table_id_, player.chair_id)
	--player, self.room_.id, self.table_id_, player.chair_id, GAME_SERVER_RESULT_SUCCESS, self	
	--broad cast leave
	self:player_stand_up(player, 1)
end


function texas_table:t_broadcast(ProtoName, msg)
	for _guid, t_player in pairs(self.t_player) do
		local l_player = self:get_player(t_player.chair)
		if l_player then
			send2client_pb(l_player, ProtoName, msg)
		end
	end
end