-- 炸金花逻辑

local pb = require "protobuf"
require "data/zhajinhua_data"
require "game/lobby/base_table"
-- enum ZHAJINHUA_CARD_TYPE
local ZHAJINHUA_CARD_TYPE_SPECIAL = pb.enum_id("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SPECIAL")
local ZHAJINHUA_CARD_TYPE_SINGLE = pb.enum_id("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SINGLE")
local ZHAJINHUA_CARD_TYPE_DOUBLE = pb.enum_id("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_DOUBLE")
local ZHAJINHUA_CARD_TYPE_SHUN_ZI = pb.enum_id("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SHUN_ZI")
local ZHAJINHUA_CARD_TYPE_JIN_HUA = pb.enum_id("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_JIN_HUA")
local ZHAJINHUA_CARD_TYPE_SHUN_JIN = pb.enum_id("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_SHUN_JIN")
local ZHAJINHUA_CARD_TYPE_BAO_ZI = pb.enum_id("ZHAJINHUA_CARD_TYPE", "ZHAJINHUA_CARD_TYPE_BAO_ZI")
local GAME_SERVER_RESULT_SUCCESS = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
local GAME_SERVER_RESULT_MAINTAIN = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_MAINTAIN")
local LOG_MONEY_OPT_TYPE_ZHAJINHUA = pb.enum_id("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_ZHAJINHUA")

local PLAYER_STAND = -1         -- 观战
local PLAYER_FREE = 0           -- 空闲
local PLAYER_READY = 1          -- 准备
local PLAYER_WAIT = 2           -- 等待下注
local PLAYER_CONTROL = 3        -- 准备操作
local PLAYER_LOOK = 4           -- 看牌
local PLAYER_COMPARE = 5        -- 比牌
local PLAYER_DROP = 6           -- 弃牌
local PLAYER_LOSE = 7           -- 淘汰
local PLAYER_EXIT = 8           -- 离开

local room_manager = g_room_manager
local def_second_game_type = def_second_game_type
local def_game_name = def_game_name

-- enum ITEM_PRICE_TYPE 
local ITEM_PRICE_TYPE_GOLD = pb.enum_id("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")

--游戏准备时间
local ZHAJINHUA_TIMER_READY = 11

-- 等待开始
local ZHAJINHUA_STATUS_FREE = 1
-- 游戏准备开始
local ZHAJINHUA_STATUS_READY =  2
-- 游戏进行
local ZHAJINHUA_STATUS_PLAY = 3


-- 得到牌大小
local function get_value(card)
	return math.floor(card / 4)
end

-- 得到牌花色
local function get_color(card)
	return card % 4
end
-- 0：方块2，1：梅花2，2：红桃2，3：黑桃2 …… 48：方块A，49：梅花A，50：红桃A，51：黑桃A



zhajinhua_table = base_table:new()
--错误
function XXXX_XXXXX()
	print("XXXXXXXXXXXXXXXXXX")
	for i, v in ipairs(t) do
	end
end
-- 初始化
function zhajinhua_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	self.status = ZHAJINHUA_STATUS_FREE
    self.chair_count = chair_count
	self.cards = {}
	self.add_score_ = {}
	self.player_online = {}
	self.Round = 1
	self.Round_Times = 1 
    self.dead_count_ = 0
	self.is_dead_ = {} -- 放弃或比牌输了
	self.max_add_score_ = 0
	self.allready = false
	self.ready_count_down = 12
	self.show_card_list = {}

	--添加筹码值
	if def_game_name == "zhajinhua" then
		if def_second_game_type == 1 then
			self.add_score_ = zhajinhua_room_score[1]
		elseif def_second_game_type == 2 then
			self.add_score_ = zhajinhua_room_score[2]
		elseif def_second_game_type == 3 then
			self.add_score_ = zhajinhua_room_score[3]
		elseif def_second_game_type == 4 then
			self.add_score_ = zhajinhua_room_score[4]
		elseif def_second_game_type == 5 then
			self.add_score_ = zhajinhua_room_score[5]
		else
			log_error(string.format("zhajinhua_table:init def_second_game_type[%d] ", def_second_game_type))
			return
		end
	end

	for i,v in pairs(self.add_score_) do
		if self.max_add_score_ < v then
			self.max_add_score_ = v
		end
	end

	self.player_status = {}

	for i = 1, chair_count do
		self.player_status[i] = PLAYER_FREE
		self.player_online[i] = false
		self.show_card_list[i] = {}
		for j = 1, chair_count do
			self.show_card_list[i][j] = false 
		end
	end
	for i = 1, 52 do
		self.cards[i] = i - 1
	end
end
-- 检查是否可准备
function zhajinhua_table:check_ready(player)
	if self.status ~= ZHAJINHUA_STATUS_FREE and   self.status ~= ZHAJINHUA_STATUS_READY then
		return false
	end
	return true
end

function zhajinhua_table:canEnter(player)
	--[[
	if true then
		return true
	end--]]
	print("zhajinhua_table:canEnter ===============")
	if player then
		print ("player have date")
	else
		print ("player no data")
	end
	-- body
	for _,v in ipairs(self.player_list_) do		
		if v then
			print("===========judgePlayTimes")
			if player:judgeIP(v) then
				if not player.ipControlflag then
					print("zhajinhua_table:canEnter ipcontorl change false")
					return false
				else
					-- 执行一次后 重置
					print("zhajinhua_table:canEnter ipcontorl change true")
					return true
				end
			end
		end
	end
	print("land_table:canEnter true")
	return true
end

-- 检查是否可取消准备
function zhajinhua_table:check_cancel_ready(player, is_offline)
	base_table.check_cancel_ready(self,player,is_offline)
	player:setStatus(is_offline)
	if is_offline then
		--掉线
		if  self.status ~= ZHAJINHUA_STATUS_FREE then
			--掉线处理
			self:playeroffline(player)
			return false
		end
	end	
	--退出
	return true
end

function zhajinhua_table:all_compare()
	local player = nil
	local oldcur = self.cur_turn
	local next_player_cur = nil
	for i = 1, self.player_count_, 1 do
		oldcur = self.cur_turn
		player = self.player_list_[self.cur_turn]
		self:next_turn()
		next_player_cur = self.cur_turn
		self.cur_turn = oldcur
		local bRet = self:compare_card(player, next_player_cur, true)
		print("all compare------- bRet:", bRet)
		if bRet == false then
			self:next_turn()
			--self:next_round()
		end
		if self.status ~= ZHAJINHUA_STATUS_PLAY then
			return 
		end
	end
end
-- 下一个
function zhajinhua_table:next_turn()
	print("---------------------------------next_turn", #self.ready_list_)
	local old = self.cur_turn
	repeat
		self.cur_turn = self.cur_turn + 1
		if self.cur_turn > #self.ready_list_ then
			self.cur_turn = 1
		end
		if old == self.cur_turn then	

			for i = 1, #self.ready_list_ do
				print("self.ready_list_[i] :", self.ready_list_[i] )
			end

			for i = 1, #self.is_dead_ do
				print("self.is_dead_[i] :", self.is_dead_[i] )
			end

			print ("turn error old is", old, "#self.ready_list_ is", #self.ready_list_)		
			print(debug.traceback())
				log_error("turn error")
				return
		end
	until(self.ready_list_[self.cur_turn] and (not self.is_dead_[self.cur_turn]))
	print("-----------------------------------next_turn end", old, "turn", self.cur_turn )


	--断线运算
	if( (self.status == ZHAJINHUA_STATUS_PLAY ) and (self.player_online[self.cur_turn] == false)) then
		player = self.player_list_[self.cur_turn]
		print ("lc  online   check_start-----------------AAAAAAAAAAA")
		self:give_up(player)
		self:next_turn()
		self:next_round()
	end

end

function zhajinhua_table:next_round()
	--运算回合
	if self.status == ZHAJINHUA_STATUS_PLAY and self.Round <= 20 then
		self.Round_Times = self.Round_Times + 1
		--print ("self.Round_Times :", self.Round_Times - 1)
		--print ("self.Round_Times + 1:", self.Round_Times)
		if self.Round_Times > self.Live_Player then
			self.Round = self.Round + 1
			print ("self.Round :", self.Round - 1)
			print ("self.Round + 1:", self.Round)
			--超过上限轮数处理
			if self.Round > 20 then	
				self:all_compare()
			end
			self.Round_Times = self.dead_count_ + 1
		end
	end	
end


function zhajinhua_table:check_start(part)
	print ("check_start-----------------AAAAAAAAAAA")
	local n = 0
	local k = 0
	for i, v in ipairs(self.player_list_) do
		if v then
			k = k + 1
			if self.ready_list_[i] then
				n = n+1
				if self.status ~= ZHAJINHUA_STATUS_PLAY and self.player_status[i] ~= PLAYER_READY then
					self.player_status[i] = PLAYER_READY
				end
			end
		end
	end

	if n == k and n >= 2 and self.status  ~= ZHAJINHUA_STATUS_PLAY then
		print ("--------------------------------allready")
		self.allready = true
	end
	--[[if n >= 2 and self.status == ZHAJINHUA_STATUS_FREE then
		self.status = ZHAJINHUA_STATUS_READY
		self.ready_time = get_second_time()
		if not self.allready  then
			local msg = {
			time = ZHAJINHUA_TIMER_READY,
			}
			self:broadcast2client("SC_ZhaJinHuaStart", msg)
		end
	end]]
	return
end
-- 
-- 进入房间并坐下
function zhajinhua_table:get_en_and_sit_down(player, room_id_, table_id_, chair_id_, result_, tb)
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
		send2client_pb(player, "SC_ZhaJinHuaGetSitDown", notify)
end

function zhajinhua_table:get_sit_down(player)
	print ("get_sit_down-----------------AAAAAAAAAAA")
	self.player_online[player.chair_id] = true
	print ("player.room_id_, player.table_id_, player.chair_id",self.room_.id, self.table_id_, player.chair_id)
	self:get_en_and_sit_down(player, self.room_.id, self.table_id_, player.chair_id, GAME_SERVER_RESULT_SUCCESS, self)

	if self.tax_show_ == 1 then 
		self.notify_msg.flag = 3
	else
		self.notify_msg.flag = 4
	end	
	print( self.notify_msg)
	send2client_pb(player, "SC_ShowTax", self.notify_msg)
end

-- 重新上线
function zhajinhua_table:reconnect(player)
	print("zhajinhua_table:reconnect~~~~~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!",player.chair_id)
		for i,v in ipairs(self.player_list_) do
			if v then
				print (v.chair_id)
				print (v, player)
				if v == player then
					local msg = { 
					isseecard = true,
					}
					print("send reconnect~~~~~~~~~!")
					send2client_pb(player, "SC_ZhaJinHuaReConnect", msg)
					player.table_id = self.table_id_
					player.room_id = self.room_.id

					local offline = {
					chair_id = player.chair_id,
					turn = self.Round,
					reconnect = true,
					}
					table.insert(self.gamelog.offlinePlayers, offline)	
					return
				end
			end
		end
		local msg = { 
		isseecard = false,
		}

		send2client_pb(player, "SC_ZhaJinHuaReConnect", msg)
		return
end

--重载注码配置
function zhajinhua_table:require_zhangjinhua_db()
 	package.loaded["data/zhajinhua_data"] = nil 
	require "data/zhajinhua_data"

	--添加筹码值
	if def_game_name == "zhajinhua" then
		if def_second_game_type == 1 then
			self.add_score_ = zhajinhua_room_score[1]
		elseif def_second_game_type == 2 then
			self.add_score_ = zhajinhua_room_score[2]
		elseif def_second_game_type == 3 then
			self.add_score_ = zhajinhua_room_score[3]
		elseif def_second_game_type == 4 then
			self.add_score_ = zhajinhua_room_score[4]
		elseif def_second_game_type == 5 then
			self.add_score_ = zhajinhua_room_score[5]
		else
			log_error(string.format("zhajinhua_table:init def_second_game_type[%d] ", def_second_game_type))
			return
		end
	end

	for i,v in pairs(self.add_score_) do
			print(v)
		if self.max_add_score_ < v then
			self.max_add_score_ = v
		end
	end
end
function zhajinhua_table:load_lua_cfg()
	print ("--------------------load_lua_cfg", self.room_.lua_cfg_)
	local funtemp = load(self.room_.lua_cfg_)
	local zhajinhua_room_score = funtemp()
	--添加筹码值
	print (self.room_.lua_cfg_, zhajinhua_room_score)
	if def_game_name == "zhajinhua" then
		if def_second_game_type == 1 then
			self.add_score_ = zhajinhua_room_score[1]
		elseif def_second_game_type == 2 then
			self.add_score_ = zhajinhua_room_score[2]
		elseif def_second_game_type == 3 then
			self.add_score_ = zhajinhua_room_score[3]
		elseif def_second_game_type == 4 then
			self.add_score_ = zhajinhua_room_score[4]
		elseif def_second_game_type == 5 then
			self.add_score_ = zhajinhua_room_score[5]
		else
			log_error(string.format("zhajinhua_table:init def_second_game_type[%d] ", def_second_game_type))
			return
		end
	end

	for i,v in pairs(self.add_score_) do
			print(v)
		if self.max_add_score_ < v then
			self.max_add_score_ = v
		end
	end
end
-- 开始游戏
function zhajinhua_table:start(player_count)
	print("old----", self.tax_show_ , self.tax_open_ ,self.tax_,self.room_limit_, self.cell_score_)
	local bRet = base_table.start(self,player_count)
	print (bRet)
	print("new----", self.tax_show_ , self.tax_open_ ,self.tax_,self.room_limit_, self.cell_score_)
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	self.player_count_ = player_count
	self.player_cards_ = {} -- 玩家手里的牌
	self.player_cards_type_ = {}
	self.is_look_card_ = {} -- 是否看过牌
	self.is_dead_ = {} -- 放弃或比牌输了
	self.player_score = {}
	local cell_score = self.cell_score_
	self.last_score = cell_score   --当前单注
	self.player_money = {}
	self.all_money = 0  --总金币
	self.max_score_ = cell_score * 200 --最大筹码
    self.ball_score_ = {}  --是否全压
	self.cur_turn = 1
	self.Round = 1 -- 当前回合
	self.Live_Player = player_count
	self.Round_Times = 1
	self.player_online = {}
	self.ready_time = 0
    self.randomA = math.random(self.player_count_)
    self.player_status = {}
    self.ball_begin = false     -- 是否开始全压
    self.dead_count_ = 0
    self.player_oldmoney = {}
    self.betscore = {}
    self.betscore_count_ = 1
    self.gamer_player = {}
	self.allready = false
	self.ready_count_down = 12
	self.show_card_list = {}

	self.gamelog = {
		room_id = self.room_.id,
		table_id = self.table_id_,		
        start_game_time = get_second_time(),
        end_game_time = 0,
        table_game_id = self:get_now_game_id(),
        win_chair = 0,
        tax = 0,
        banker = 0,
        add_score = {},	--加油
        look_chair = {},  --看牌
        compare = {},   --比牌
        give_up = {}, --弃牌
        playInfo = {},
        offlinePlayers = {},
        cards = {},
        finisgameInfo = {},
        cell_score = self.cell_score_,
        all_money = 0,
    }

    print("cell_score:", cell_score, " self.max_score_:",self.max_score_)  

	for i = 1, self.chair_count  do
		self.player_status[i] = PLAYER_FREE
		self.is_look_card_[i] = false
		self.player_online[i] = false
		if self.ready_list_[i] then
			self.is_dead_[i] = false
		else
			self.is_dead_[i] = true
		end
		self.player_money[i] = 0
		self.player_score[i] = 0
		self.player_oldmoney[i] = 0
		self.show_card_list[i] = {}
		for j = 1,  self.chair_count  do
			self.show_card_list[i][j] = false
		end
	end	

	for i = 1, self.chair_count  do
		print (self.is_dead_[i], self.ready_list_[i])
	end

	local itemp = 2
	repeat		
		self:next_turn()
		itemp = itemp + 1
	until(itemp > self.randomA)

	self.gamelog.banker = self.cur_turn


	-- 发牌
	self.log_guid = ""
	local k = #self.cards
	local chari_list_tp_ = {}
	local guid_list_tp_ = {}
	for i,v in ipairs(self.player_list_) do
		if v then
			-- 洗牌
			local cards = {}
			for j=1,3 do
				local r = math.random(k)
				cards[j] = self.cards[r]
				if r ~= k then
					self.cards[r], self.cards[k] = self.cards[k], self.cards[r]
				end
				k = k-1
			end
			self.player_cards_[i] = cards
			print ("AAAAAcards1:",cards[1],"cards2:",cards[2],"cards3:",cards[3])
			local type, v1, v2, v3 = self:get_cards_type(cards)
			local item = {cards_type = type}
			print ("AAAAAV1:",v1,"V2:",v2,"V3:",v3)
			if v1 then
				item[1] = v1
			end
			if v2 then
				item[2] = v2
			end
			if v3 then
				item[3] = v3
			end
			self.player_cards_type_[i] = item
			self.player_online[i] = true
			self.ball_score_ [i] = false
			self.player_status[i] = PLAYER_WAIT
			self.log_guid = self.log_guid ..v.guid..":"
			self.gamelog.cards[v.chair_id] =
			{
				chair_id = v.chair_id,
				card = cards,
			} 
			v.is_offline = false
			table.insert(chari_list_tp_, v.chair_id)
			table.insert(guid_list_tp_, v.guid)
    		self.gamer_player[v.chair_id] =
    		{
				chair_id = v.chair_id,
				card = cards,
				guid = v.guid,
				phone_type = v.phone_type,
				new_money = v.pb_base_info.money,
				ip = v.ip,
				player = v,
				channel_id =  v.create_channel_id,
				money = 0,
				header_icon = v:get_header_icon(),
				name = v.ip_area,
    		}
			self.gamelog.playInfo[v.chair_id] = {
				chair_id = v.chair_id,
				guid = v.guid,
				old_money = v.pb_base_info.money,
				new_money = v.pb_base_info.money,
				tax = 0,
				all_score = 0,
			}
			self.show_card_list[v.chair_id][v.chair_id] = true
			-- 底注
			self.player_oldmoney[i] = v:get_money()
			v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = cell_score}}, LOG_MONEY_OPT_TYPE_ZHAJINHUA)

			self.betscore[self.betscore_count_] = cell_score
			self.betscore_count_ = self.betscore_count_ + 1

			self.player_money[i] = cell_score
			self.all_money = self.all_money+cell_score
			local money_ = v:get_money()
			if not self.max_score_ or self.max_score_ > money_ then
				self.max_score_ = money_
				print ("self.max_score_ :", self.max_score_)
			end
		end
	end

	self.status = ZHAJINHUA_STATUS_PLAY
	local msg = {
		banker_chair_id = self.cur_turn,
		chair_id = chari_list_tp_,
		guid = guid_list_tp_,
	}
	self:broadcast2client("SC_ZhaJinHuaStart", msg)
    print("cell_score:", cell_score, " self.max_score_:",self.max_score_)
	log_info(string.format("gmse start ID =%s   guid=%s   timeis:%s", self.gamelog.table_game_id, self.log_guid, os.date("%y%m%d%H%M%S")))
	self.time0_ = get_second_time()
end

-- 加注
function zhajinhua_table:add_score(player, score_)
	print("Add___SOCRE -------------------------------------!!!!!!!!",player.chair_id)
	local b_all_score_ = false

	print("self.add_score_[score_]", self.add_score_[score_])
	if (not self.add_score_[score_])then
		if(score_ ~= 1 ) then
			log_warning(string.format("zhajinhua_table:add_score guid[%d] status error", player.guid))
			return
		end
		if self.ball_begin == false then
			--获取玩家数量
			local playernum = 0
			local otherplayer = 0
			for i,v in ipairs(self.player_list_) do
				if v and (not self.is_dead_[i]) then
					playernum = playernum + 1
					--获取另一玩家
					if i ~= player.chair_id then
						otherplayer = i
					end
				end
			end
			if playernum == 2 then
				local all_add_score = (21 - self.Round) * self.max_add_score_

				local player_money_temp1 = all_add_score
				local player_money_temp2 = all_add_score

				if self.is_look_card_[player.chair_id] then 
					player_money_temp1 = all_add_score * 2

				end

				if self.is_look_card_[self.player_list_[otherplayer].chair_id] then
					player_money_temp2 = all_add_score * 2
				end

				if player_money_temp1 > player:get_money() then
					player_money_temp1 = player:get_money()
				end


				if player_money_temp2 > self.player_list_[otherplayer]:get_money() then
					player_money_temp2 = self.player_list_[otherplayer]:get_money()
				end
				print(player:get_money(), self.player_list_[otherplayer]:get_money())
				print(player_money_temp1, player_money_temp2)

				if player_money_temp1 > player_money_temp2 then					
					if self.is_look_card_[self.player_list_[otherplayer].chair_id] then
						all_add_score =  player_money_temp2 / 2
					else
						all_add_score =  player_money_temp2
					end		
				else	
					if self.is_look_card_[player.chair_id] then 
						all_add_score =  player_money_temp1 / 2
					else
						all_add_score =  player_money_temp1
					end		
				end


				self.max_score_ = all_add_score
				score_ = self.max_score_ 

				print("add_score self.max_score_:", self.max_score_)
			else				
				log_warning(string.format("zhajinhua_table:add_score guid[%d] status error", player.guid))
				return
			end
		else
			score_ = self.max_score_ 
		end
		b_all_score_ = true
	end

	if self.ball_score_[player.chair_id] then		
			log_warning(string.format("zhajinhua_table:add_score guid[%d] status error  is all_score_  true", player.guid))
			return
	end
	if self.status ~= ZHAJINHUA_STATUS_PLAY then
		log_warning(string.format("zhajinhua_table:add_score guid[%d] status error", player.guid))
		return
	end

	if player.chair_id ~= self.cur_turn then
		log_warning(string.format("zhajinhua_table:add_score guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_turn))
		return
	end

	if self.is_dead_[player.chair_id] then
		log_error(string.format("zhajinhua_table:add_score guid[%d] is dead", player.guid))
		return
	end

	if score_ < self.last_score and not b_all_score_ then
		log_error(string.format("zhajinhua_table:add_score guid[%d] score[%d] < last[%d]", player.guid, score_, self.last_score))
		return
	end
	
	local money_ = score_
	if money_ > self.max_score_ then
		log_error(string.format("zhajinhua_table:add_score guid[%d] score[%d] > max[%d]", player.guid, money_, self.max_score_))
		return
	end

	if self.is_look_card_[player.chair_id] then
		money_ = score_ * 2
	end

	print("------------------------------socre is ",score_, money_)

	if player:get_money() < money_ then
		return false
	end

	local bRet = player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = money_}}, LOG_MONEY_OPT_TYPE_ZHAJINHUA)

	if bRet == false and money_ ~= 0 then
		log_error(string.format("zhajinhua_table:add_score guid[%d] money[%d] > player_money[%d]", player.guid, money_, player:get_money()))
		return
	end


	self.betscore[self.betscore_count_] = score_
	self.betscore_count_ = self.betscore_count_ + 1

	self.last_score = score_
	self.player_score[player.chair_id] = score_
	local playermoney = self.player_money[player.chair_id] + money_
	self.player_money[player.chair_id] = playermoney
	self.all_money = self.all_money+money_

	--日志处理
	local process = {
	chair_id = player.chair_id,
	score = score_, -- 注码
	money = money_,
	turn = self.Round,
	isallscore = b_all_score_ ,  --是否全压
	}
	table.insert(self.gamelog.add_score, process)

	--处理全押

	self:next_turn()
	local istemp = 0
	if b_all_score_ then
		istemp = 2
	else
		istemp = 3
	end
	local notify = {
		add_score_chair_id = player.chair_id,
		cur_chair_id = self.cur_turn,
		score = score_,
		money = money_,
		is_all = istemp,
	}
	print("-------------------is_all:",notify.is_all )
	self:broadcast2client("SC_ZhaJinHuaAddScore", notify)
	self:next_round()

	print("b_all_score_:",b_all_score_)
	if b_all_score_ == true then
		print("player  ：", player.chair_id)
		print("all score money ：", score_)
		self.ball_score_[player.chair_id] = true

		if self.ball_score_[self.cur_turn]  == true then
			self:compare_card(self.player_list_[self.cur_turn], player.chair_id, true, true)	
		end
		self.ball_begin = true
	end

	self.time0_ = get_second_time()
end

-- 放弃跟注
function zhajinhua_table:give_up(player)
	print("zhajinhua_table:give_up AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", player.chair_id)
	if self.status ~= ZHAJINHUA_STATUS_PLAY then
		log_warning(string.format("zhajinhua_table:give_up guid[%d] status error", player.guid))
		return
	end

	if self.is_dead_[player.chair_id] then
		print("Error_chairID", player.chair_id, "cur_turn", self.cur_turn)
		log_error(string.format("zhajinhua_table:add_score guid[%d] is dead", player.guid))
		return
	end

	self.is_dead_[player.chair_id] = true
	self.player_status[player.chair_id] = PLAYER_DROP
    self.dead_count_ = self.dead_count_  + 1
	
	if self.cur_turn > player.chair_id then
		self.Round_Times = self.Round_Times + 1  --去掉该玩家出手序列 
	end
	
	local notify = {
		giveup_chair_id = player.chair_id,
		cur_chair_id = self.cur_turn,
	}

	--日志处理
	local giveup = {
		chair_id = player.chair_id,
		turn = self.Round,
		now_chair = self.cur_turn,
	}
	table.insert(self.gamelog.give_up, giveup)

	if self:check_end("SC_ZhaJinHuaGiveUp", notify) then -- 结束
		return
	end



	if(player.chair_id == self.cur_turn) then
		self:next_turn()
		self:next_round()
		self.time0_ = get_second_time()
	end
	notify.cur_chair_id = self.cur_turn
	self:broadcast2client("SC_ZhaJinHuaGiveUp", notify)
	
end

-- 看牌
function zhajinhua_table:look_card(player)	
	print("LOOK___CARD AAAAAAAAAAAAAAAAAAZZZZZZZZZZZZZZZZZZZZzzzzzzzzzzzzzzzzzz!!!!!!!!",player.chair_id)
	if self.status ~= ZHAJINHUA_STATUS_PLAY then
		log_warning(string.format("zhajinhua_table:look_card guid[%d] status error", player.guid))
		return
	end

	if self.is_look_card_[player.chair_id] then
		log_error(string.format("zhajinhua_table:look_card guid[%d] has look", player.guid))
		return
	end

	if self.ball_begin and player:get_money() < (self.max_score_  * 2)  then
		log_error(string.format("zhajinhua_table:look_card guid[%d] ball_begin and player money error", player.guid))
		return
	end

	self.is_look_card_[player.chair_id] = true

	send2client_pb(player, "SC_ZhaJinHuaLookCard", {
		lookcard_chair_id = player.chair_id,
		cards = self.player_cards_[player.chair_id],
	})

	local notify = {
		lookcard_chair_id = player.chair_id,
	}
	self:broadcast2client_except(player.guid, "SC_ZhaJinHuaNotifyLookCard", notify)


	--日志处理
	local look = {
		chair_id = player.chair_id,
		turn = self.Round,
	}
	table.insert(self.gamelog.look_chair, look)
end

-- 终
 -- 比牌
function zhajinhua_table:compare_card(player, compare_chair_id, allcompare, nosendflag)	
	print("COMPARE_CARD AAAAAAAAAAAAAAAAAAZZZZZZZZZZZZZZZZZZZZ: ",player.chair_id , "-------", compare_chair_id)
	if self.status ~= ZHAJINHUA_STATUS_PLAY then
		log_warning(string.format("zhajinhua_table:compare_card guid[%d] status error", player.guid))
		return
	end

	if player.chair_id ~= self.cur_turn then
		log_warning(string.format("zhajinhua_table:compare_card guid[%d] turn[%d] error, cur[%d]", player.guid, player.chair_id, self.cur_turn))
		return
	end

 	local target = self.player_list_[compare_chair_id]
 	if not target then
		log_error(string.format("zhajinhua_table:compare_card guid[%d] compare[%d] error", player.guid, compare_chair_id))
 		return
 	end

	if self.is_dead_[player.chair_id] then
		log_error(string.format("zhajinhua_table:compare_card guid[%d] is dead", player.guid))
		return
	end

	if self.is_dead_[compare_chair_id] then
		log_error(string.format("zhajinhua_table:compare_card guid[%d] is dead", target.guid))
		return
	end



	local bRetAllCompare = false   --是否金钱不足开始全比

	print("compare_card------------------------------ball_begin-----1 ")
	if not allcompare  then

		print("compare_card------------------------------ball_begin-----2 ")
		local money_ = 0

		if self.ball_begin then
			money_ = self.last_score
			print("compare_card------------------------------ball_begin-----3 ")
		else
			money_ = self.last_score
			print("compare_card------------------------------ball_begin-----4 ")
			if self.is_look_card_[player.chair_id]  then
				print("compare_card------------------------------ball_begin-----5 ")
				money_ = money_ * 2
			end
		end
		print("compare_card------------------------------ball_begin-----6 ", self.last_score, money_)

		if money_ > player:get_money() then
			money_ = player:get_money()
			bRetAllCompare = true
		end

		local bRet = player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = money_}}, LOG_MONEY_OPT_TYPE_ZHAJINHUA)		
		if bRet == false and money_ ~= 0 then
			log_error(string.format("zhajinhua_table:add_score guid[%d] money[%d] > player_money[%d]", player.guid, money_, player:get_money()))
			return
		end
		local playermoney = self.player_money[player.chair_id] + money_
		self.player_money[player.chair_id] = playermoney
		self.all_money = self.all_money+money_

	end

	-- 比牌
	card_temp1 = self.player_cards_[player.chair_id]
	for i = 1, 3 do
		print("A  color:", get_color(card_temp1[i]), "  value:",  get_value(card_temp1[i]))
	end	

	card_temp2 = self.player_cards_[compare_chair_id]
	for i = 1, 3 do
		print("B  color:", get_color(card_temp2[i]), "  value:",  get_value(card_temp2[i]))
	end	
	local ret = self:compare_cards(self.player_cards_type_[player.chair_id], self.player_cards_type_[compare_chair_id])

	--修改双方结束时对方牌可见
	self.show_card_list[player.chair_id][compare_chair_id] = true
	self.show_card_list[compare_chair_id][player.chair_id] = true

	if ret then
		print("first is win~~~~~~~~~~~~")
	else
		print("second is win~~~~~~~~~~~~~~")
	end
	if ret then
		self.is_dead_[compare_chair_id] = true		
		self.player_status[compare_chair_id] = PLAYER_LOSE
		if compare_chair_id > player.chair_id then
			self.Round_Times = self.Round_Times + 1  --去掉该玩家出手序列 
		end
	else
		self.is_dead_[player.chair_id] = true		
		self.player_status[player.chair_id] = PLAYER_LOSE
	end

    self.dead_count_ = self.dead_count_  + 1

	local notify = {
		cur_chair_id = self.cur_turn,
	}
	local loster_msg = {}
	local loster = target
	if ret then
		--loster_msg.win_cards = self.player_cards_[player.chair_id]
		--loster_msg.loster_cards = self.player_cards_[compare_chair_id]
		notify.win_chair_id = player.chair_id
		notify.lost_chair_id = compare_chair_id
	else
		--loster_msg.win_cards = self.player_cards_[compare_chair_id]
		--loster_msg.loster_cards = self.player_cards_[player.chair_id]
		notify.win_chair_id = compare_chair_id
		notify.lost_chair_id = player.chair_id
		loster = player
	end
	
	--send2client_pb(loster, "SC_ZhaJinHuaLostCards", loster_msg)
	if allcompare and not nosendflag then
		notify.is_all = 3
	else
		notify.is_all = 4
	end
	
	--日志处理
	local compare = {
		chair_id = player.chair_id,
		turn = self.Round,
		otherplayer = compare_chair_id,		--被比牌玩家
		money = money_,		--比牌花费
		win = ret,		--是否获胜
	}
	table.insert(self.gamelog.compare, compare)

	if self:check_end("SC_ZhaJinHuaCompareCard", notify) then -- 结束
		print("AAAAAAAAAAAAA  This Game Is  Over~~~~~~! ")
		return true
	end


	self:next_turn()
	notify.cur_chair_id = self.cur_turn
	self:broadcast2client("SC_ZhaJinHuaCompareCard", notify)
	self:next_round()

	print("COMPARE_CARD BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBZZZZZZZZZZZZZZZZZZZZ: ",player.chair_id , "-------", compare_chair_id)


	if bRetAllCompare then
		self:all_compare()
	end

	self.time0_ = get_second_time()
	return false
end

function deepcopy(object)      
    local lookup_table = {}  
    local function _copy(object)  
        if type(object) ~= "table" then  
            return object  
        elseif lookup_table[object] then  
  
            return lookup_table[object]  
        end  -- if          
        local new_table = {}  
        lookup_table[object] = new_table  
  
  
        for index, value in pairs(object) do  
            new_table[_copy(index)] = _copy(value)  
        end   
        return setmetatable(new_table, getmetatable(object))      
    end       
    return _copy(object)  
end  

-- 检查结束
function zhajinhua_table:check_end(sendname, fmsg)
	local win = nil
	for i,v in ipairs(self.player_list_) do
		if v and (not self.is_dead_[i]) then
			if win then
				return false
			else
				win = i
			end
		end
	end

	if win then
		print("Game is Over ~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		self.status = ZHAJINHUA_STATUS_FREE

		local notify = {
			win_chair_id = win,
			pb_conclude = {}
		}
		
		for i,v in pairs(self.gamer_player) do
			if v then
				local item = {
					chair_id = i,
					cards = self.player_cards_[i],
					guid = self.gamer_player[i].guid,
					header_icon = self.gamer_player[i].header_icon,
					name = self.gamer_player[i].name,
					status = self.player_status[i] ,
				}
				local money_tax = 0
				local money_temp = 0
				local money_change = 0
				local money_type = 1
				if i == win then
					money_temp = self.all_money - self.player_money[i]
					--税收运算
					if self.tax_open_ == 1 then
						print("---------------------------------tax")
						money_tax = money_temp * self.tax_
						if money_tax < 1 then
							money_tax = 0
						end
						money_tax = math.ceil(money_tax)			
						print("self.all_money", self.all_money, "self.player_money[i]",self.player_money[i], "money_temp", money_temp, "money_tax", money_tax)
						if money_tax < 1 then
							money_temp = self.all_money 
							money_tax = 0
						else
							money_temp = self.all_money - money_tax
						end
					end
					notify.tax = money_tax
					item.score = money_temp
					money_change = money_temp
					self:ChannelInviteTaxes(v.player.channel_id,v.player.guid,v.player.inviter_guid,money_tax)
					v.player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = money_temp}}, LOG_MONEY_OPT_TYPE_ZHAJINHUA)
					money_change = self.all_money - self.player_money[i]
					money_type = 2

					self.gamelog.win_chair = v.chair_id
					self.gamelog.tax = money_tax

					v.money =  v.player.pb_base_info.money
				else
					item.score = -(self.player_money[i] or 0)
					money_change =  -(self.player_money[i] or 0)
					v.money = self.player_oldmoney[v.chair_id] -(self.player_money[i] or 0)
				end

				self:PlayerMoneyLogNoPlayer(v.guid, v.phone_type, v.money, v.ip, money_type, self.player_oldmoney[v.chair_id], money_tax, money_change, self:get_now_game_id(), v.channel_id)

				print("end-----------------------",i,self.player_list_[i])
				if self.player_list_[i] then		
					send2client_pb(v.player,"SC_Gamefinish",{
						money = v.player.pb_base_info.money
					})
				end
				self.gamelog.playInfo[v.chair_id].new_money = self.player_oldmoney[v.chair_id] +  money_change

				table.insert(self.gamelog.finisgameInfo, item)	

				table.insert(notify.pb_conclude, item)
			end
		end
		self.gamelog.all_money = self.all_money

		self:broadcast2client(sendname, fmsg)

		for i, p in ipairs(self.player_list_) do
			if not p then
				--print("p is nil:"..i)
			else
				if p.online and p.in_game then
					local pb = deepcopy(notify)

					for j,v in pairs(self.gamer_player) do
						if v then
							--print ("p.chair_id  j", p.chair_id, j , self.show_card_list[p.chair_id][j])
							if self.show_card_list[p.chair_id][j] == false then
								for x,y in ipairs(pb.pb_conclude) do
									--print("y.cards", y.cards[1],y.cards[2],y.cards[3])
									if y.chair_id == j then
										--print ("change -- y.chair_id j", y.chair_id, j)
										y.cards = {-1,-1,-1}
									end
								end
							end
						end
					end
					--print ("send -- SC_ZhaJinHuaEnd")
					send2client_pb(p, "SC_ZhaJinHuaEnd", pb)
					local xmsg = {
						time = 23,
					}
					send2client_pb(p, "SC_ZhaJinHuaClientReadyTime", xmsg)					
				else
					if p.is_player == false then --非玩家(机器人)
						-- do nothing
					else
						print("p offline :"..p.chair_id)
					end
				end
			end
		end

		--self:broadcast2client("SC_ZhaJinHuaEnd", notify)
		self:clear_ready()
		return true
	end

	return false
end

function zhajinhua_table:clear_ready( ... )		
	self.gamelog.end_game_time = get_second_time()

	local s_log = lua_to_json(self.gamelog)
	--print(s_log)
	self:Save_Game_Log(self.gamelog.table_game_id, self.def_game_name, s_log, self.gamelog.start_game_time, self.gamelog.end_game_time)
	log_info(string.format("gmse end ID =%s   guid=%s   timeis:%s", self.gamelog.table_game_id, self.log_guid, os.date("%y%m%d%H%M%S")))

	base_table.clear_ready(self)
	print("self.chair_count ", self.chair_count )
	for i = 1, self.chair_count  do
		self.player_status[i] = PLAYER_FREE
		self.is_look_card_[i] = false
		self.is_dead_[i] = false
		self.player_money[i] = 0
		self.player_online[i] = false			
		if self.player_list_[i] then
			local player = 	self.player_list_[i]	
			print(i, self.player_list_[i].is_offline)
			if self.player_list_[i].is_offline == true then		
				print("offline exit----------------------!", self.player_list_[i].is_offline )
				player:forced_exit()
				logout(player.guid)
			else
			--检查T人
				print("check_money-----------------------!")
				player:check_forced_exit(self.room_:get_room_limit())
				if  player.disable == 1 then
					player:forced_exit()
				end
			end
		end
	end
	self.all_money = 0
	self.last_score = 0
	self.Round = 1
	self.betscore = {}
	self.allready  = false
	self:next_game()
	self:check_sit_player_num(true)

end

-- 得到牌类型
function zhajinhua_table:get_cards_type(cards)

	print ("cards1:",cards[1],"cards2:",cards[2],"cards3:",cards[3])

	local v = {
		get_value(cards[1]),
		get_value(cards[2]),
		get_value(cards[3]),
	}

	-- 豹子
	if v[1] == v[2] and v[2] == v[3] then
		return ZHAJINHUA_CARD_TYPE_BAO_ZI, v[1]
	end

	-- 对子
	if v[1] == v[2] then
		return ZHAJINHUA_CARD_TYPE_DOUBLE, v[1], v[3]
	elseif v[1] == v[3] then
		return ZHAJINHUA_CARD_TYPE_DOUBLE, v[1], v[2]
	elseif v[2] == v[3] then
		return ZHAJINHUA_CARD_TYPE_DOUBLE, v[2], v[1]
	end
	
	print ("1111111V1:",v[1],"V2:",v[2],"V3:",v[3])
	table.sort(v)

	print ("222222222V1:",v[1],"V2:",v[2],"V3:",v[3])
	local val = nil
	local is_shun_zi = false
	if v[1]+1 == v[2] and v[2]+1 == v[3] then 
		is_shun_zi = true
		val = v[3]
	elseif v[1] == 0 and v[2] == 1 and v[3] == 12 then
		is_shun_zi = true
		val = 1
	end

	print ("33333333333V1:",v[1],"V2:",v[2],"V3:",v[3])
	local c1 = get_color(cards[1])
	local c2 = get_color(cards[2])
	local c3 = get_color(cards[3])
	if c1 == c2 and c2 == c3 then
		if is_shun_zi then
			-- 顺金
			return ZHAJINHUA_CARD_TYPE_SHUN_JIN, val
		else
			-- 金花
			return ZHAJINHUA_CARD_TYPE_JIN_HUA, v[3], v[2], v[1]
		end
	elseif is_shun_zi then
		-- 顺子
		return ZHAJINHUA_CARD_TYPE_SHUN_ZI, val
	end

	print ("4444444444444V1:",v[1],"V2:",v[2],"V3:",v[3])
	if v[1] == 0 and v[2] == 1 and v[3] == 3 then
		return ZHAJINHUA_CARD_TYPE_SPECIAL
	end

	print ("55555555555555V1:",v[1],"V2:",v[2],"V3:",v[3])
	return ZHAJINHUA_CARD_TYPE_SINGLE, v[3], v[2], v[1]
end

-- 比较牌 first 申请比牌的
function zhajinhua_table:compare_cards(first, second)	
	print("COMPARE_CARDS AAAAAAAAAAAAAAAAAAZZZZZZZZZZZZZZZZZZZZzzzzzzzzzzzzzzzzzz!!!!!!!!")
	if first.cards_type ~= second.cards_type then
		-- 特殊
		if first.cards_type == ZHAJINHUA_CARD_TYPE_BAO_ZI and second.cards_type == ZHAJINHUA_CARD_TYPE_SPECIAL then
			return false
		elseif second.cards_type == ZHAJINHUA_CARD_TYPE_BAO_ZI and first.cards_type == ZHAJINHUA_CARD_TYPE_SPECIAL then
		 	return true
		end
		return first.cards_type > second.cards_type
	end

	if first.cards_type == ZHAJINHUA_CARD_TYPE_SHUN_ZI or first.cards_type == ZHAJINHUA_CARD_TYPE_SHUN_JIN or first.cards_type == ZHAJINHUA_CARD_TYPE_BAO_ZI then
		return first[1] > second[1]
	end

	if first.cards_type == ZHAJINHUA_CARD_TYPE_DOUBLE then
		if first[1] > second[1] then
			return true
		elseif first[1] == second[1] then
			return first[2] > second[2]
		end
		return false
	end

	if first[1] > second[1] then
		return true
	elseif first[1] == second[1] then
		if first[2] > second[2] then
			return true
		elseif first[2] == second[2] then
			return first[3] > second[3]
		end
	end
	return false
end


function zhajinhua_table:check_sit_player_num(bRet)
	print("-----------------------------self.allready ", self.allready )
	local n = 0
	for i,v in pairs(self.player_list_) do
		if v then
			n = n + 1
		else
			print("-------------Null player clear:", i)
			self.player_list_[i] = false
		end
	end
	if n >= 2 and self.status == ZHAJINHUA_STATUS_FREE then
		if bRet then
			self.ready_count_down = 23
		end
		if not self.allready  then
			local msg = {
			time = self.ready_count_down,
			}
			self:broadcast2client("SC_ZhaJinHuaReadyTime", msg)
		end
		self.ready_time = get_second_time()
		print ("-----------------Game  Ready :", n)
		self.status = ZHAJINHUA_STATUS_READY
	end
end

function base_table:send_playerinfo(player)
	self:get_sit_down(player)
end
		
-- 玩家坐下
function zhajinhua_table:player_sit_down(player, chair_id_)
	print("player_sit_down  AKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK", chair_id_)

	for i,v in pairs(self.player_list_) do
		if v == player then
			player.chari_id_ = v.chari_id_
			player:on_stand_up(self.table_id_, chari_id_, GAME_SERVER_RESULT_SUCCESS)
			return
		end
	end
	if self.status == ZHAJINHUA_STATUS_FREE or self.status == ZHAJINHUA_STATUS_READY then
		player.table_id = self.table_id_
		player.chair_id = chair_id_
		player.room_id = self.room_.id	
		player.noready = true 
		self.player_list_[chair_id_] = player

		self.player_status[player.chair_id] = PLAYER_FREE
		if player.is_player then
			for i, p in ipairs(self.player_list_) do
				if p == false then
					-- 主动机器人坐下
					player:on_notify_android_sit_down(player.room_id, self.table_id_, i)
				end
			end
		end	
		if  self.status == ZHAJINHUA_STATUS_READY then
			msg = {
				time = get_second_time() - self.ready_time,
			}		
			send2client_pb(player, "SC_ZhaJinHuaReadyTime", msg)
		else
			self:check_sit_player_num()
		end
	else
		if self.player_list_[chair_id_] then
			log_warning(string.format("zhajinhua_table:player_sit_down !ZHAJINHUA_STATUS_FREE guid[%d]", player.guid))
			return
		end
		player.table_id = self.table_id_
		player.chair_id = chair_id_
		player.room_id = self.room_.id
		player.noready = true 
		self.player_list_[chair_id_] = player
		self.ready_list_[chair_id_] = false
		--观众坐下
		self.player_status[player.chair_id] = PLAYER_STAND
	end
	print ("chair = ", chair_id_, "player.chair_id = ", player.chair_id)	
	log_info(string.format("GameInOutLog,zhajinhua_table:player_sit_down, guid %s, table_id %s, chair_id %s",
	tostring(player.guid),tostring(player.table_id),tostring(player.chair_id)))
end

-- 获取玩家状态
function zhajinhua_table:get_play_Status(player)
	local notify = {
		isseecard = self.is_look_card_,
		banker_chair_id = self.cur_turn,
		room_status = self.status,
		totalmoney = self.all_money,
		score = self.last_score,
		round = self.Round,
		status = self.player_status,
		playermoney = self.player_money,
		allbet = self.betscore
	}

	send2client_pb(player, "SC_ZhaJinHuaWatch", notify)
end
-- 判断是否游戏中
function  zhajinhua_table:isPlay( ... )
	print("zhajinhua_table:isPlay :"..self.status)
	-- body
	if self.status == ZHAJINHUA_STATUS_PLAY then
		print("isPlay  return true")
		return true
	end
	return false
end

-- 玩家站起
function zhajinhua_table:player_stand_up(player, is_offline)
	log_info(string.format("GameInOutLog,zhajinhua_table:player_stand_up, guid %s, table_id %s, chair_id %s, is_offline %s",
	tostring(player.guid),tostring(player.table_id),tostring(player.chair_id),tostring(is_offline)))

	print("STAND_UPPPP AAAAAAAAAAAAAAAAAAZZZZZZZZZZZZZZZZZZZZzzzzzzzzzzzzzzzzzz!!!!!!!!" ,player.chair_id, is_offline)	
	print("base_table.player_stand_up(self,player,is_offline)")
    print(player.table_id,player.chair_id,player.guid)


	if self.status == ZHAJINHUA_STATUS_READY then
		--[[if self.ready_list_[player.chair_id] then
			self.ready_list_[player.chair_id] = false			
			local n = 0
			for i, v in ipairs(self.player_list_) do
				if v then
					if self.ready_list_[i] then
						n = n+1
					end
				end
			end
			if n < 2 then
				self.status = ZHAJINHUA_STATUS_FREE
			end
		end]]
		local n = 0
		for i,v in pairs(self.player_list_) do
			n = n + 1
		end

		if n < 2 then
			self.status = ZHAJINHUA_STATUS_FREE
		end
		--player:forced_exit()
		--logout(player.guid)		
	elseif self.status == ZHAJINHUA_STATUS_PLAY and not is_offline  and not self.is_dead_[player.chair_id] then
		self:give_up(player)
		return 

	elseif self.status == ZHAJINHUA_STATUS_PLAY and is_offline  and not self.is_dead_[player.chair_id] then
			local offline = {
			chair_id = player.chair_id,
			turn = self.Round,
			reconnect = false,
			}

			table.insert(self.gamelog.offlinePlayers, offline)	
	end

	if not is_offline and self.player_online[player.chair_id] == false then
		local notify = {
			table_id = player.table_id,
			chair_id = player.chair_id,
			guid = player.guid,
		}
		print (player.table_id,player.chair_id,player.guid)
		self:broadcast2client("SC_NotifyStandUp",notify)
	end


	if self.status ~= ZHAJINHUA_STATUS_PLAY and is_offline then	
		print("-------------------------------------------A")	
		base_table.player_stand_up(self,player,is_offline)
		self.room_:player_exit_room(player)
	else
		print("-------------------------------------------B")
		local bRet = false
		print("-------------------------------------------C",self.player_status[player.chair_id] , player.chair_id, PLAYER_STAND)
		if self.player_status[player.chair_id] ~= PLAYER_STAND and self.player_status[player.chair_id] ~= PLAYER_READY then
			bRet = true
		end
		base_table.player_stand_up(self,player,is_offline)
		if bRet and not is_offline then
			print("-------------------------------------------D")
			send2client_pb(player,"SC_Gamefinish",{
					money = player.pb_base_info.money
				})
			self.room_:player_exit_room(player)
		end
	end
end

-- 心跳
function zhajinhua_table:tick()
	if self.status == ZHAJINHUA_STATUS_PLAY then
		local curtime = get_second_time()
		if curtime - self.time0_ >= 17 then
			-- 超时
			print("Time_out Cur_turn is : ", self.cur_turn)
			local player = self.player_list_[self.cur_turn]
			if player then
				print("Time_out player is: " , player.chair_id)
				print("Ready Time out give_up AAAAAAAAAAAAAAAAAAZZZZZZZZZZZZZZZZZZZZzzzzzzzzzzzzzzzzzz!!!!!!!!")
				self.player_online[player.chair_id] = false
				self:player_stand_up(player, false)
			end
			self.time0_ = curtime
		end
	end

	--准备开始状态
	if self.status == ZHAJINHUA_STATUS_READY then
		local curtime = get_second_time()
		if curtime - self.ready_time >= self.ready_count_down  or self.allready then
			-- 达到准备时间
			print("Ready Time out AAAAAAAAAAAAAAAAAAZZZZZZZZZZZZZZZZZZZZzzzzzzzzzzzzzzzzzz!!!!!!!!", self.allready )
			--[[	local iRet = base_table.check_game_maintain(self)--检查游戏是否维护
				if iRet == true then
					print("Game zhajinhua  will maintain......")
				end--]]
			print("#######################################start maintain: count player :",#self.player_list_)
			local n = 0
			for i, p in ipairs(self.player_list_) do
				if p then
					print("self.player_list_",i)
					print("self.player_list_ chair",p.chair_id)
					if self.ready_list_[p.chair_id] ~= true then
						print("stand up  :" , p.chair_id)	
						self.player_online[p.chair_id] = false
						self:player_stand_up(p, false)
					else
						n = n + 1
					end
				end
			end
			
			if n >= 2 then
					print("Ready start   AAAAAAAAAAAAAAAAAAZZZZZZZZZZZZZZZZZZZZzzzzzzzzzzzzzzzzzz!!!!!!!!")
				self:start(n)
			else
					print("Ready start no  AAAAAAAAAAAAAAAAAAZZZZZZZZZZZZZZZZZZZZzzzzzzzzzzzzzzzzzz!!!!!!!!")
				self.status = ZHAJINHUA_STATUS_FREE
				self.allready  = false
			end
		end
	end
end