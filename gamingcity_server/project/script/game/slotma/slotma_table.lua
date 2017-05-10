-- 老虎机逻辑
local pb = require "protobuf"

local random = require("utils/random")


require "data/slotma_data"
local slotma_col_num = slotma_col_num
local slotma_row_num = slotma_row_num
local slotma_lines   = slotma_lines
local slotma_items   = slotma_items
local slotma_room_config   = slotma_room_config
local slotma_results = {slotma_results_line1,slotma_results_line2,slotma_results_line3,slotma_results_line4,slotma_results_line5,slotma_results_line6,slotma_results_line7,slotma_results_line8,slotma_results_line9}
local slotma_times   = {slotma_times_line1,slotma_times_line2,slotma_times_line3,slotma_times_line4,slotma_times_line5,slotma_times_line6,slotma_times_line7,slotma_times_line8,slotma_times_line9}


require "game/lobby/base_table"

require "game/net_func"
local send2client_pb = send2client_pb

require "game/slotma/slotma_line"
local slotma_line = slotma_line

require "game/slotma/slotma_item"
local slotma_item = slotma_item

-- 老虎机人数
local SLOTMA_PLAYER_COUNT = 1

local LOG_MONEY_OPT_TYPE_SLOTMA = pb.enum_id("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_SLOTMA")

local ITEM_PRICE_TYPE_GOLD = pb.enum_id("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")

-- enum LAND_CARD_TYPE
local SLOTMA_TYPE_SUCESS = pb.enum_id("SLOTMA_TYPE", "SLOTMA_TYPE_SUCESS")					--成功
local SLOTMA_TYPE_ERRORID = pb.enum_id("SLOTMA_TYPE", "SLOTMA_TYPE_ERRORID")				--chairid错误
local SLOTMA_TYPE_NOMONEY = pb.enum_id("SLOTMA_TYPE", "SLOTMA_TYPE_NOMONEY")				--金钱不足
local SLOTMA_TYPE_LINERROR = pb.enum_id("SLOTMA_TYPE", "SLOTMA_TYPE_LINERROR")				--线型错误
local SLOTMA_TYPE_NOLINE = pb.enum_id("SLOTMA_TYPE", "SLOTMA_TYPE_NOLINE")					--未选择线型

-- 等待开始
local SLOTMA_STATUS_FREE = 1
-- 游戏进行
local SLOTMA_STATUS_PLAY = 2



slotma_table = base_table:new()
-- 初始化
function slotma_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	self.status = SLOTMA_STATUS_FREE
	self.slotma_line_list = {}
	self.slotma_item_list = {}
	self.playerlinelist_ = {}
	self.cell_times_ = 1

	self.time0_ = get_second_time()

	--self:load_lua_cfg()

	for i,v in ipairs(slotma_lines) do
		local t = slotma_line:new()
		t:init(v,slotma_col_num)
		self.slotma_line_list[t.lineID_] = t

	end

	for _,v in ipairs(slotma_items) do
		local t = slotma_item:new()
		t:init(v)
		self.slotma_item_list[t.itemID_] = t
	end

	--self:test()
end


-- 检查是否可准备
function slotma_table:check_ready(player)
	if self.status ~= SLOTMA_STATUS_FREE then
		return false
	end
	return true
end

-- 检查是否可取消准备
function slotma_table:check_cancel_ready(player, is_offline)
	if is_offline then
		--掉线	
		if  self.status ~= SLOTMA_STATUS_FREE then
			--掉线处理
			self:playeroffline(player)
			return false
		end
	end	
	--退出
	return true
end


function slotma_table:show_items(items)
	print("show items-------------------------------------------------------------start")
	for i=slotma_row_num,1,-1 do
		local lineItems = ""
		for j=1,slotma_col_num do
			lineItems = lineItems..items[(i-1)*slotma_col_num + j].."-"
		end
		print(lineItems)
	end
	print("show items-------------------------------------------------------------end")
end

function  slotma_table:respones(player, n )
	-- body	
	local notify = {
		status = n
	}
	send2client_pb(player, "SC_SimpleRespons", notify)
end
--选线
function slotma_table:select_line(player,msg)
	--判断线型
	local playerlinelist = {}
	for i,v in ipairs(msg.lines) do
		if self.slotma_line_list[v] ~= nil then
			--print("select line",v)
			playerlinelist[i] = self.slotma_line_list[v]
		else
			print("error line->",v)
			self:respones(player,SLOTMA_TYPE_LINERROR)
		end
	end
	return playerlinelist
end

function  slotma_table:Calculation(items)
	-- body
	local winline = {}
	local timesSum = 0
	for _,v in ipairs(self.playerlinelist_) do
		local getLineResult = v:getResult(items)
		for i,n in pairs(getLineResult) do
			if self.slotma_item_list[i] then
				local times_ = self.slotma_item_list[i]:getTimes(n)
				if times_ > 0 then
					timesSum = timesSum + times_
					tempTab = {
						lineid = v.lineID_,
						itemid = i,
						itemNum = n,
						times = times_,
					}
					print("reward lineid->",tempTab.lineid,"itemid->",tempTab.itemid,"itemNum->",n,"times->",tempTab.times)
					table.insert(winline,tempTab)
				end
			end
		end		
	end
	return timesSum,winline
end
function  slotma_table:Check_Result(items)

	local timesSum,winline = self:Calculation(items)

	local money = timesSum * self.room_.cell_score_ * self.cell_times_
	local tax = money * self.room_:get_room_tax()

	--不小于1才收税 并且四舍五入
	if tax >= 1 then
		tax = math.floor(tax + 0.5)
	else
		tax = 0
	end
	--print("money->",money,"rate->",self.room_:get_room_tax(),"Check_Result--------tax->",tax)

	-- body
	local  notify = {
		items = items,
		money = money,
		tax = tax,
		pb_winline = winline,
	}
	
	return notify
end

function slotma_table:load_lua_cfg()
	local funtemp = load(self.room_.lua_cfg_)
	slotma_room_config = funtemp()
	
end

--玩家进入游戏或者断线重连
function slotma_table:PlayerConnectionSlotmaGame(player)
	print(string.format("playerr[%d] coming slotma game",player.guid))
end

-- 玩家离开游戏
function slotma_table:playerLeaveSlotmaGame(player)
	print(string.format("player[%d]  leave slotma game",player.guid))
end


--碰撞检测：lineId线 times倍数 addition概率加成
function slotma_table:check_hit(lineId,times,addition)
	if times == 0 then
		return false
	end

	local hit_rate = lineId/(times*9)+lineId*addition/9
	
	if random.boost_01() < hit_rate then
		return true
	end

	return false
end

--低倍碰撞
function slotma_table:get_low_times(lineNum)
	--2-8随机倍碰撞
	local times = random.boost_integer(2,8)
	if slotma_results[lineNum][times] ~= nil and self:check_hit(lineNum,times,0) then
		return times
	end

	return 0
end


--从有效倍数中随机N次,如果不中，9线直接给2-8倍，其余低倍随机
function slotma_table:RandomEffectiveTimes(user_random_count,lineNum,min,max)
	local current_slotma_results = slotma_results[lineNum]
	local current_slotma_times = slotma_times[lineNum]

	local max_random_count = 9

	local times_between = {}

	for _,v in ipairs(current_slotma_times) do
		if v >= min and v <= max then
			table.insert(times_between,v)
		end
	end

    --没有有效倍数
	if #times_between == 0 then
		print("no right times")
		return self:get_low_times(lineNum)
	end
	
	local random_count = slotma_room_config.random_count + user_random_count

	if random_count > max_random_count then
		random_count = max_random_count
	end
	print("RandomEffectiveTimes random_count->",random_count)

	for i=1,random_count do
		local timesIndex = random.boost_integer(1,#times_between)
		local times = times_between[timesIndex]

		if current_slotma_results[times] ~= nil and self:check_hit(lineNum,times,0) then
			return times
		end
	end

	--9线直接给2-8倍
	if lineNum == 9 then
		return math.random(2,8)
	end

	return self:get_low_times(lineNum)
end


function slotma_table:RandomResult(user_random_count,lineNum)
	--2-1000有效倍数随机
	local times = self:RandomEffectiveTimes(user_random_count,lineNum,2,slotma_room_config.max_times);
	local items_index = random.boost_integer(1,#slotma_results[lineNum][times])
	print("RandomTimes->",times,"items_index->",items_index)

	return slotma_results[lineNum][times][items_index]
end


function slotma_table:test()

	local playerlinelist = {}
	for v=1,9 do
		if self.slotma_line_list[v] ~= nil then
			playerlinelist[v] = self.slotma_line_list[v]
		else
			print("error line",v)
		end
	end
	self.playerlinelist_ = playerlinelist
	local lineNum = #self.playerlinelist_
	print("lineNum->",lineNum)

	self.cell_times_ = 1


	for i=1,10 do
		local items = self:RandomResult(0,lineNum)
		local notify = self:Check_Result(items)

		local times_sum = 0
		for _,v in ipairs(notify.pb_winline) do
			times_sum = times_sum + v.times
		end

   		if times_sum > 0 then
   			print("Check_Result times_sum->",times_sum,"notify.money->",notify.money,"notify.tax->",notify.tax)
			self:show_items(items)
		end

	end
end


-- 开始游戏
function slotma_table:slotma_start(player,msg)

	print("player slotma_start--------->1")

	local start_game_time = get_second_time()

	self.cell_times_ = msg.cell_times

	self.playerlinelist_ = self:select_line(player,msg)

	local lineNum = #self.playerlinelist_
	print("lineNum->",lineNum)

	if lineNum < 1 or lineNum > 9 then
		print("error line->",lineNum)
		self:respones(player,SLOTMA_TYPE_LINERROR)
		return
	end
	
	local cost = lineNum * self.room_.cell_score_ * self.cell_times_
	local old_money = player:get_money()

	if player:get_money() < cost then
		log_warning(string.format("slotma_table:select_line guid[%d] chairid[%d] error, Money shortage", player.guid, player.chair_id))
		self:respones(player,SLOTMA_TYPE_NOMONEY)
		return
	end	

	player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = cost}}, LOG_MONEY_OPT_TYPE_SLOTMA)

	local user_random_count = player.pb_base_info.slotma_addition
	print("guid->",player.guid,"user_random_count->",user_random_count)
	
	local items = self:RandomResult(user_random_count,lineNum)
	local notify = self:Check_Result(items)
	
	if notify.money > 0 then
		player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = notify.money-notify.tax}}, LOG_MONEY_OPT_TYPE_SLOTMA)
	end
	
	send2client_pb(player, "SC_Slotma_Start", notify)

	--log start-----------------------
	local end_game_time = get_second_time()
	local change_money = notify.money-notify.tax-cost

	local gamelog = {
	    room_id = self.room_.id,
        table_id = self.table_id_,        
        select_line_num = lineNum,
        cell_times = self.cell_times_,
        cell_score = self.room_.cell_score_,
        result_items = items,
        money_cost = cost,
        tax = notify.tax,
        money_prize = notify.money-notify.tax,
        money_earn  = change_money,
        player_money_end = player:get_money(),
        line_stake = self.room_.cell_score_ * self.cell_times_,
        winline = {}
    }

	for _,v in ipairs(notify.pb_winline) do
		if v.times > 0 then
			local line_ret = {
				line_id = v.lineid,
				times = v.times,
				prize = v.times * self.room_.cell_score_ * self.cell_times_
			}
			table.insert(gamelog.winline,line_ret)
		end
	end

 	local game_id = self:get_now_game_id()

    local s_log = lua_to_json(gamelog)
    self:Save_Game_Log(game_id, self.def_game_name, s_log, start_game_time, end_game_time)


    local s_type = 1
    if change_money > 0 then
    	s_type = 2
    end
	self:PlayerMoneyLog(player,s_type,old_money,notify.tax,change_money,game_id)
	--log end--------------------------

--[[	local iRet = base_table.check_game_maintain(self)--检查游戏是否维护
	if iRet == true then
		print("Game slotma will maintain......")
	end--]]
	self:clear()
end

function slotma_table:clear( ... )
	-- body
	self.playerlinelist_ = {}
	self.cell_times_ = 1
	self.status = SLOTMA_STATUS_FREE
	self:next_game()
end

-- 重新上线
function slotma_table:reconnect(player)
	print("slotma_table:reconnect--------------------->",player.chair_id)
end

-- 心跳
function slotma_table:tick()
	--检测维护状态
	if self.status == SLOTMA_STATUS_FREE then
		local curtime = get_second_time()
		if curtime - self.time0_ >= 5 then
			--[[local iRet = base_table.check_game_maintain(self)--检查游戏是否维护
			if iRet == true then
				print("Game slotma will maintain......")
			end--]]
			self.time0_ = curtime
		end
	end
end