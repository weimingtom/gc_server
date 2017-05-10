-- 牛牛逻辑

local pb = require "protobuf"

require "game/lobby/base_table"
require "data/many_ox_data"
require "table_func"
local random = require("utils/random")

--[[-- enum OX_CARD_TYPE
local OX_CARD_TYPE_OX_NONE = pb.enum_id("OX_CARD_TYPE","OX_CARD_TYPE_OX_NONE")
local OX_CARD_TYPE_OX_ONE = pb.enum_id("OX_CARD_TYPE","OX_CARD_TYPE_OX_ONE")
local OX_CARD_TYPE_OX_TWO = pb.enum_id("OX_CARD_TYPE", "OX_CARD_TYPE_OX_TWO")
local OX_CARD_TYPE_FOUR_KING = pb.enum_id("OX_CARD_TYPE", "OX_CARD_TYPE_FOUR_KING")
local OX_CARD_TYPE_FIVE_KING = pb.enum_id("OX_CARD_TYPE", "OX_CARD_TYPE_FIVE_KING")
local OX_CARD_TYPE_FOUR_SAMES = pb.enum_id("OX_CARD_TYPE", "OX_CARD_TYPE_FOUR_SAMES")
local OX_CARD_TYPE_FIVE_SAMLL = pb.enum_id("OX_CARD_TYPE","OX_CARD_TYPE_FIVE_SAMLL")--]]
-- enum OX_SCORE_AREA
local OX_AREA_ONE = pb.enum_id("OX_SCORE_AREA","OX_AREA_ONE")
local OX_AREA_TWO = pb.enum_id("OX_SCORE_AREA","OX_AREA_TWO")
local OX_AREA_THREE = pb.enum_id("OX_SCORE_AREA","OX_AREA_THREE")
local OX_AREA_FOUR = pb.enum_id("OX_SCORE_AREA","OX_AREA_FOUR")
local GAME_SERVER_RESULT_MAINTAIN = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_MAINTAIN")
require "game/ox/ox_robot"

-- enum ITEM_PRICE_TYPE 
local ITEM_PRICE_TYPE_GOLD = pb.enum_id("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")

-- 上庄机器人
local TYPE_ROBOT_BANKER = 1

-- 下注机器人
local TYPE_ROBOT_BET = 2

-- 准备时间
local OX_TIME_READY = 3

-- 下注时间
local OX_TIME_ADD_SCORE = 18
-- 开牌时间
local OX_TIME_OPEN_CARD = 15

-- 等待开始
local OX_STATUS_READY = 1
-- 游戏进行
local OX_STATUS_PLAY = 2
-- 开牌
local OX_STATUS_OVER = 3

-- 是否有大小王
local CLOWN_EXSITS = false

-- 最多可以下注的区域
local MAX_SCORE_AREA = 4

-- 计分板纪录最多的条数
local MAX_SCOREBORD_LEN =10

-- 玩家税收比例5%
local OX_PLAYER_TAX = 0.05

-- 百分比
local OX_EXCHANGE_RATE = 100

-- 最大赔率倍数10倍
local OX_MAX_TIMES = 10

-- 上庄条件金币限制
local OX_BANKER_LIMIT = 500

-- 玩家下注最低金币限制
local OX_PLAYER_MIN_LIMIT = 1000

-- 显示玩家信息最大个数
local OX_PLAYER_LIST_MAX = 300

-- 最大连庄次数限制
local DEFAULT_CONTINUOUS_BANKER_TIMES = 5

-- 玩家申请上庄标识,默认0可以申请,1不可以申请上庄
local DEFAUT_PLAYER_APPLY_BANKER_FLAG = 0

-- 真实玩家个数限制,小于该数则创建下注机器人
local PLAYER_MIN_LIMIT = 5

-- 创建下注机器人个数随机系数
local BET_ROBOT_RAND_COEFF = 5

-- 下注金币选项
local robot_money_option = {100,1000,5000,10000,50000}

-- 下注金币选项总数(下注机器人随机只能取前两位筹码选项)
local ROBOT_BET_MONEY_OPTION_TOTAL = 2

-- 下注机器人下注次数随机系数
local ROBOT_BET_TIMES_COEFF = 10

-- 机器人下注最后时间
local ROBOT_BET_LAST_TIME = 2

-- 下注机器人开关(1开,0关)
local SWITCH_BET_ROBOT = 1

-- 最大索引
local MAX_CARDS_INDEX = 1
-- 最小索引
local MIN_CARDS_INDEX = 2

-- 系统必赢概率5% 
local SYSTEM_MUST_WIN_PROB = 5

-- 系统浮动必赢概率
local SYSTEM_FLOAT_PROB = 3

-- 系统系数
local SYSTEM_COEFF = 10000

-- 台费最小抽税标准1(对应1分)
local MIN_TAX_LIMIT = 1

-- 系统庄家机器人开关(1开,0关)
local SYSTEM_BANKER_SWITCH = 1

-- 上庄机器人初始UID
local BANKER_ROBOT_INIT_UID = 100000

-- 下注机器人初始UID
local BET_ROBOT_INIT_UID = 200000

-- 上庄机器人初始金币
local BANKER_ROBOT_START_MONEY = 10000000

-- 下注机器人初始金币
local BET_ROBOT_START_MONEY = 100000

-- 下注机器人每局最大下注总额
local ROBOT_BET_TOTAL = 5000

-- 下注机器人每秒最多下注个数 
local ROBOT_BET_MAX_NUM = 5


local def_second_game_type = def_second_game_type
local def_game_name = def_game_name


-- 0：方块A，1：梅花A，2：红桃A，3：黑桃A …… 48：方块K，49：梅花K，50：红桃K，51：黑桃K，52:小王 ，53大王

-- 检测2个时间是否是同一天
local function is_same_day(time_sp_a,time_sp_b)
	local a = os.date("*t",time_sp_a)
	local b = os.date("*t",time_sp_b)
	return (a.day == b.day and a.year == b.year and a.month == b.month) and true or false
end

ox_table = base_table:new()

-- 初始化
function ox_table:init(room, table_id, chair_count)
	base_table.init(self, room, table_id, chair_count)
	--math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	
	
	self.status = OX_STATUS_READY
	self.ox_game_player_list = {}
	for i = 1, chair_count do
		self.ox_game_player_list[i] = false
	end
	
	--2低倍场 1高倍场
	self.which_type = 1
	--初始化不同变量和基础配置
	if def_game_name == "ox" then
		if def_second_game_type == 1 then --高倍场
			print("-------def_second_game_type = 1-hight--------")
			require "game/ox/ox_gamelogic_1"
			OX_MAX_TIMES = 10  
		elseif def_second_game_type == 2 then --低倍场
			print("-------def_second_game_type = 2--low-------")
			require "game/ox/ox_gamelogic_2"
			OX_MAX_TIMES = 3     --最高赔率3倍
			CLOWN_EXSITS = true  --要大小王
			self.which_type = 2 
		else
			log_error(string.format("ox_table:def_second_game_type[%d] ", def_second_game_type))
			return
		end
	end	
	
	
	
	self.cards = {}
	local cards_num = CLOWN_EXSITS and 54 or 52
	for i = 1, cards_num do
		self.cards[i] = i - 1
	end
	
	-- 计分板
	self.scoreboard = {}

	-- 上庄列表
	self.bankerlist = {}
	
	-- 庄家uid
	--self.bankeruid = 0

	-- 当前当庄庄家信息
	self.cur_banker_info = {
		guid = 0,
		nickname = nil,
		money = 0,
		bankertimes = 0,
		max_score = 0,
		banker_score = 0,
		left_score = 0,
		header_icon = 0,
	}

	
	-- 上一次当庄庄家uid
	self.lastbankeruid = 0
	
	--第一次初始化推送庄家
	self:get_banker()
	
	self.last_tick_time =0
	local curtime = get_second_time()
	self.time0_ = curtime
	self:init_global_val()
	self:load_many_ox_config_file(self.which_type)
end

function ox_table:re_load_many_ox_config_file()	
 	package.loaded["data/many_ox_data"] = nil 
	require "data/many_ox_data"
end
function ox_table:load_many_ox_config_file(index_num)
	OX_TIME_READY = many_ox_room_config[index_num].Ox_FreeTime
	OX_TIME_ADD_SCORE = many_ox_room_config[index_num].Ox_BetTime
	OX_TIME_OPEN_CARD = many_ox_room_config[index_num].Ox_EndTime
	SYSTEM_MUST_WIN_PROB = many_ox_room_config[index_num].Ox_MustWinCoeff
	OX_BANKER_LIMIT = many_ox_room_config[index_num].Ox_bankerMoneyLimit
	SYSTEM_BANKER_SWITCH = many_ox_room_config[index_num].Ox_SystemBankerSwitch
	DEFAULT_CONTINUOUS_BANKER_TIMES = many_ox_room_config[index_num].Ox_BankerCount
	BANKER_ROBOT_INIT_UID = many_ox_room_config[index_num].Ox_RobotBankerInitUid
	BANKER_ROBOT_START_MONEY = many_ox_room_config[index_num].Ox_RobotBankerInitMoney
	SWITCH_BET_ROBOT = many_ox_room_config[index_num].Ox_BetRobotSwitch
	BET_ROBOT_INIT_UID = many_ox_room_config[index_num].Ox_BetRobotInitUid
	BET_ROBOT_START_MONEY = many_ox_room_config[index_num].Ox_BetRobotInitMoney
	BET_ROBOT_RAND_COEFF = many_ox_room_config[index_num].Ox_BetRobotNumControl
	ROBOT_BET_TIMES_COEFF = many_ox_room_config[index_num].Ox_BetRobotTimeControl
	ROBOT_BET_TOTAL = many_ox_room_config[index_num].Ox_RobotBetMoneyControl
	robot_money_option = many_ox_room_config[index_num].Ox_basic_chip
	SYSTEM_FLOAT_PROB = many_ox_room_config[index_num].Ox_FloatingCoeff --浮动概率
	OX_PLAYER_MIN_LIMIT = many_ox_room_config[index_num].Ox_PLAYER_MIN_LIMIT --携带金币数小于该值不能下注
--[[	print("FreeTime = "..OX_TIME_READY)
	print("BetTime = "..OX_TIME_ADD_SCORE)
	print("EndTime = "..OX_TIME_OPEN_CARD)
	print("MustWinCoeff = "..SYSTEM_MUST_WIN_PROB)
	print("BankerMoneyLimit = "..OX_BANKER_LIMIT)
	print("SystemBankerSwitch = "..SYSTEM_BANKER_SWITCH)
	print("BankerCount = "..DEFAULT_CONTINUOUS_BANKER_TIMES)
	print("RobotBankerInitUid = "..BANKER_ROBOT_INIT_UID)
	print("RobotBankerInitMoney = "..BANKER_ROBOT_START_MONEY)
	print("BetRobotSwitch = "..SWITCH_BET_ROBOT)
	print("BetRobotInitUid = "..BET_ROBOT_INIT_UID)
	print("BetRobotInitMoney = "..BET_ROBOT_START_MONEY)
	print("BetRobotNumControl = "..BET_ROBOT_RAND_COEFF)
	print("BetRobotTimesControl = "..ROBOT_BET_TIMES_COEFF)
	print("RobotBetMoneyControl = "..ROBOT_BET_TOTAL)
	print("robot_money_option = "..robot_money_option[1])
	print("SYSTEM_FLOAT_PROB = "..SYSTEM_FLOAT_PROB)--]]
end



function ox_table:load_lua_cfg()
	print ("--------------------load_lua_cfg", self.room_.lua_cfg_)
	local funtemp = load(self.room_.lua_cfg_)
	local ox_config = funtemp()
	OX_TIME_READY = ox_config.Ox_FreeTime
	OX_TIME_ADD_SCORE = ox_config.Ox_BetTime
	OX_TIME_OPEN_CARD = ox_config.Ox_EndTime
	SYSTEM_MUST_WIN_PROB = ox_config.Ox_MustWinCoeff
	OX_BANKER_LIMIT = ox_config.Ox_bankerMoneyLimit
	SYSTEM_BANKER_SWITCH = ox_config.Ox_SystemBankerSwitch
	DEFAULT_CONTINUOUS_BANKER_TIMES = ox_config.Ox_BankerCount
	BANKER_ROBOT_INIT_UID = ox_config.Ox_RobotBankerInitUid
	BANKER_ROBOT_START_MONEY = ox_config.Ox_RobotBankerInitMoney
	SWITCH_BET_ROBOT = ox_config.Ox_BetRobotSwitch
	BET_ROBOT_INIT_UID = ox_config.Ox_BetRobotInitUid
	BET_ROBOT_START_MONEY = ox_config.Ox_BetRobotInitMoney
	BET_ROBOT_RAND_COEFF = ox_config.Ox_BetRobotNumControl
	ROBOT_BET_TIMES_COEFF = ox_config.Ox_BetRobotTimeControl
	ROBOT_BET_TOTAL = ox_config.Ox_RobotBetMoneyControl
	robot_money_option = ox_config.Ox_basic_chip
	SYSTEM_FLOAT_PROB = ox_config.Ox_FloatingCoeff --浮动概率
	if  ox_config.Ox_PLAYER_MIN_LIMIT ~= nil then
		OX_PLAYER_MIN_LIMIT = ox_config.Ox_PLAYER_MIN_LIMIT
	end	
	print("FreeTime = "..OX_TIME_READY)
	print("BetTime = "..OX_TIME_ADD_SCORE)
	print("EndTime = "..OX_TIME_OPEN_CARD)
	print("MustWinCoeff = "..SYSTEM_MUST_WIN_PROB)
	print("BankerMoneyLimit = "..OX_BANKER_LIMIT)
	print("SystemBankerSwitch = "..SYSTEM_BANKER_SWITCH)
	print("BankerCount = "..DEFAULT_CONTINUOUS_BANKER_TIMES)
	print("RobotBankerInitUid = "..BANKER_ROBOT_INIT_UID)
	print("RobotBankerInitMoney = "..BANKER_ROBOT_START_MONEY)
	print("BetRobotSwitch = "..SWITCH_BET_ROBOT)
	print("BetRobotInitUid = "..BET_ROBOT_INIT_UID)
	print("BetRobotInitMoney = "..BET_ROBOT_START_MONEY)
	print("BetRobotNumControl = "..BET_ROBOT_RAND_COEFF)
	print("BetRobotTimesControl = "..ROBOT_BET_TIMES_COEFF)
	print("RobotBetMoneyControl = "..ROBOT_BET_TOTAL)
	print(string.format("robot_money_option [%d,%d,%d,%d,%d]", robot_money_option[1], robot_money_option[2], robot_money_option[3],robot_money_option[4],robot_money_option[5]))
	print("SYSTEM_FLOAT_PROB = ".. tostring(SYSTEM_FLOAT_PROB))
	print("OX_PLAYER_MIN_LIMIT = "..OX_PLAYER_MIN_LIMIT)
	print("load_lua_cfg ok......")
end
--初始化全局变量
function ox_table:init_global_val()
	local bRet = base_table.start(self,0)
--[[	print (bRet)
	if bRet then
		self:re_load_many_ox_config_file()
		self:load_many_ox_config_file()
	end--]]
	--print(self.tax_show_ , self.tax_open_ ,self.tax_ )
	-- 桌面显示所有玩家信息
	self.all_player_list = {}
	self.area_cards_ = {} --区域里的牌
	self.area_score_ = {} --区域下注的状态
	self.is_open_ = {}
	self.last_score = 0
	self.player_apply_banker_flag = DEFAUT_PLAYER_APPLY_BANKER_FLAG  --玩家申请上庄开关,0默认开,1关
	self.conclude = {} --收益
	self.area_score_total = {
		max_bet_score = self.max_score_,    --最大下注
		bet_tian_total = 0,   --下注天金币总额
		bet_di_total = 0,     --下注地金币总额
		bet_xuan_total = 0,   --下注玄金币总额
		bet_huang_total = 0,  --下注黄金币总额
		left_money_bet = self.max_score_,   --还可下注金额(初始化为默认最大下注金额)
		total_all_area_bet_money = 0, --总下注总额
	}  --各区域下注总额以及总下注总额
	-- 当前正在当庄玩家主动申请下庄标识,1主动申请下庄	
	self.curbankerleave_flag = 0
	self.cardResult = {}
	self.tb_bet_robot = {}  -- 下注机器人
	self.robot_start_bet_flag = 0 -- 机器人下注标志
	self.robot_bet_info = {} -- 机器人下注信息
	self.flag_banker_robot = 0 --默认玩家当庄标志,1机器人当庄
	self.last_bet_time = 0 --控制下注机器人下注频率(模拟每秒下注几个)
	self.change_banker_flag = 0 --切换庄家开关(0不用切换,1切换庄家)
	--OX_PLAYER_TAX = self.room_:get_room_tax() --读取税收比例
	OX_PLAYER_TAX = self.tax_ --读取税收比例
	self.cell_money = self.room_:get_room_cell_money() --读取底注
	self.player_bet_all_info = {} --玩家下注总额
	self.tax_total = 0 --该局总税收
	local curtime = get_second_time()
	self.table_game_id = 0

	-- 记录游戏日志
	self.gamelog = {
		start_game_time = 0, --游戏开始时间
        end_game_time = 0,   --游戏结束时间
		table_game_id = 0,   --table ID
		banker_id = 0,		 --庄家ID
		cell_money = 0,		 --最小底注
		player_count = 0,	 --玩家人数
		system_banker_flag = 0,--系统当庄为1,非系统当庄为0
		system_tax_total = 0,--该局总税收
		tax = 0,			 --税收比例
		CardTypeInfo = {},   --牌型信息
		Record_result = {},   --区域结果()
		--Player_list = {},    --玩家列表
		Area_bet_all_count = {}, --下注区域总计
		Area_bet_info = {},  --区域下注信息
		Game_Conclude = {} --游戏结算
    }

	self.gamelog.start_game_time = curtime
	self.gamelog.tax = OX_PLAYER_TAX
	self:get_curBanker_type()
end



-- 获得庄家最大能下注金币信息
function ox_table:get_max_score(score)
	return math.floor(score/OX_MAX_TIMES)
end

-- 上庄列表人数
function ox_table:get_banker_list_num()
	local banker_num = 0
	for i, v in ipairs(self.bankerlist) do
		if v then
			banker_num = banker_num + 1
		end
	end
	return banker_num
end

-- 更新上庄列表中玩家金币信息
function ox_table:update_bankerlist_info(guid,new_money)
	if #self.bankerlist == 0 then 
		return
	end
	for i, v in ipairs(self.bankerlist) do
		if v and v.guid == guid then
			v.money = new_money
			break
		end
	end
end

-- 发送更新后最新上庄列表信息
function ox_table:send_latest_bankerlist_info()
	local msg = {}
	if #self.bankerlist == 0 then 
		self.bankerlist = self.bankerlist or {}
		msg = {banker_num_total = 0, pb_banker_list = self.bankerlist}
		self:broadcast2client("SC_OxBankerList", msg)
		return
	end
	
	for i, v in ipairs(self.bankerlist) do
		if v and v.money <  OX_BANKER_LIMIT then -- 最新金币该局输了后未达到上庄条件直接移除
			table.remove(self.bankerlist,i)
		end
	end 
	local banker_num_total = self:get_banker_list_num();
	self.bankerlist = self.bankerlist or {}
	msg = {banker_num_total = banker_num_total, pb_banker_list = self.bankerlist}
	self:broadcast2client("SC_OxBankerList", msg)
end

-- 申请上庄
function ox_table:applyforbanker(player)	
	print("applyforbanker ......")
	if self.player_apply_banker_flag == 1 then --为1,禁止玩家申请上庄
		local msg = {
			result = pb.enum_id("Banker_Result","FORBIDAPPLYBANKER_FLAG"), --禁止玩家申请上庄
		}
		send2client_pb(player, "SC_OxForBankerFlag", msg)
		return
	end

	-- 判断上庄条件,满足则加入上庄列表,不满足则返回 
	local player_money = player:get_money()
	local player_headicon = player:get_header_icon()
	if player_money >= OX_BANKER_LIMIT then
		local banker = {
			guid = player.guid,
			nickname = player.nickname,
			money = player_money,
			header_icon = player_headicon,
		}
		table.insert(self.bankerlist, banker)
	--[[	table.sort(self.bankerlist, function (a, b)
			if a.money == b.money then
				return a.guid < b.guid
			else
				return a.money > b.money
			end
		end)--]]
		local msg = {
			result = pb.enum_id("Banker_Result","APPLYFORBANKER_OK"), --上庄成功
		}
		send2client_pb(player, "SC_OxForBankerFlag", msg)
		-- 更新上庄列表
		local banker_num_total = self:get_banker_list_num();
		self.bankerlist = self.bankerlist or {}
		local msg = {banker_num_total = banker_num_total, pb_banker_list = self.bankerlist}
		self:broadcast2client("SC_OxBankerList", msg)
 	else -- 不满足上庄条件回复客户端,上庄失败
		local msg = {
			result = pb.enum_id("Banker_Result","APPLYFORBANKER_FAILED"), --上庄失败
		}
		send2client_pb(player, "SC_OxForBankerFlag", msg)
	end
	
end

-- 在上庄列表中的玩家申请下庄
function ox_table:leaveforbanker(player)	
	print("leaveforbanker ......")
	-- 查找下庄id
	for i, v in ipairs(self.bankerlist) do
		if v and v.guid == player.guid then
			table.remove(self.bankerlist, i)
			local msg = {
				result = pb.enum_id("BankerLeave_Result","LEAVELFORBANKER_OK"), --下庄成功
			}
			send2client_pb(player, "SC_OxBankerLeaveFlag", msg)
			-- 更新上庄列表
			local banker_num_total = self:get_banker_list_num()
			self.bankerlist = self.bankerlist or {}
			local msg = {banker_num_total = banker_num_total, pb_banker_list = self.bankerlist}
			self:broadcast2client("SC_OxBankerList", msg)
			break
		end
	end
end

-- 创建上庄机器人
function ox_table:creat_banker_robot(robot_type,robot_num,uid,money)
	local robot = ox_robot:creat_robot(robot_type, robot_num,uid,money)
	for i,v in pairs (self.ox_game_player_list) do
		if not v then
			robot.chair_id = i
			self.ox_game_player_list[i] = robot
			break
		end
	end
	return robot
end

-- 创建下注机器人
function ox_table:creat_rand_bet_robot(robot_type, robot_num,uid,money)
	local bet_robot_ = {}
	bet_robot_ = ox_robot:creat_robot(TYPE_ROBOT_BET, robot_num,uid,money)
	
	for _,v1 in pairs (bet_robot_) do
		if v1 then
			for i,v in pairs (self.ox_game_player_list) do
				if not v then
					v1.chair_id = i
					local header_icon_ = random.boost_integer(1,10) --下注机器人头像随机抽取1-10中的一个
					v1.header_icon = header_icon_ + 1
					self.ox_game_player_list[i] = v1
					break
				end
			end
		end
	end
	return bet_robot_
end
-- 发送即将当庄庄家信息给客户端
function ox_table:send_banker_info_to_client()
	if #self.bankerlist == 0 then
		-- 机器人上庄 args[机器人类型,机器人数量]
		local banker_robot = self:creat_banker_robot(TYPE_ROBOT_BANKER, 1,BANKER_ROBOT_INIT_UID,BANKER_ROBOT_START_MONEY)
		log_warning("banker list is nil,reobot apply for banker.")
	--[[	self.cur_banker_info = {
				guid = 10000,
				nickname = "system_banker",
				money = 100000,
				bankertimes = 1,
				max_score = 10000,
				banker_score = 0,
				left_score = 10000,
				header_icon = -1,
			}
			--]]
			local max_bet_score = self:get_max_score(banker_robot.money <=0 and 0 or banker_robot.money)
			self.cur_banker_info = {
				guid = banker_robot.guid,
				nickname = banker_robot.nickname,
				money = banker_robot.money,
				bankertimes = 1,
				max_score = max_bet_score,
				banker_score = 0,
				left_score = max_bet_score,
				header_icon = banker_robot.header_icon,
			}
		self.cur_banker_info = self.cur_banker_info or {}
		local msg = {pb_banker_info = self.cur_banker_info}
		self:broadcast2client("SC_OxBankerInfo",msg)
		
	else
		local curbanker = self.bankerlist[1]
		local money_ = self:get_max_score(curbanker.money <= 0 and 0 or curbanker.money)
		if money_ > 0 then
			self.max_score_ = money_
		end
		local banker = {
			guid = curbanker.guid,  --庄家ID
			nickname = curbanker.nickname, --庄家昵称
			money = curbanker.money,   --庄家金币
			bankertimes = 1,           --庄家连续当庄次数
			max_score = self.max_score_, --闲家最大下注金币数
			banker_score = 0,           --庄家成绩累加
			left_score = self.max_score_, --剩余还可下注金币数
			header_icon = curbanker.header_icon, --头像
		}
		banker = banker or {}
		local msg = {pb_banker_info = banker}
		self:broadcast2client("SC_OxBankerInfo",msg)
		-- 更新庄家列表
		table.remove(self.bankerlist, 1)
		local banker_num_total = self:get_banker_list_num();
		self.bankerlist = self.bankerlist or {}
		local msg = {banker_num_total = banker_num_total, pb_banker_list = self.bankerlist}
		self:broadcast2client("SC_OxBankerList", msg)
		
		
		self.cur_banker_info = {
			guid = curbanker.guid,
			nickname = curbanker.nickname,
			money = curbanker.money,
			bankertimes = 1,
			max_score = self.max_score_,
			banker_score = 0,
			left_score = self.max_score_,
			header_icon = curbanker.header_icon, --头像
		}
		
	end	
	self.max_score_ = self.cur_banker_info.max_score
	
end


-- 删除机器人接口
function ox_table:del_robot(uid)
	for i, v in pairs(self.ox_game_player_list) do
		if v and v.guid == uid then
			self.ox_game_player_list[i] = false
			break
		end
	end
end

-- 删除掉线玩家
function ox_table:del_player(uid)
	for i, v in pairs(self.ox_game_player_list) do
		if v and v.guid == uid then
			--table.remove(self.ox_game_player_list, i)
			self.ox_game_player_list[i] = false
			break
		end
	end
end


-- 玩家金币不足强制下庄
function ox_table:force_leavel_banker(banker)
	print("force_leavel_banker......")
	if banker.money < OX_BANKER_LIMIT then
		self.lastbankeruid = banker.guid
		slef:change_banker()
	end
end

-- 切换庄家
function ox_table:change_banker()
	print("change_banker ......")
	self.lastbankeruid = self.cur_banker_info.guid
	self:send_banker_info_to_client()
end

-- 正在当庄玩家申请下庄
function ox_table:leave_cur_banker(player)
	
	if player.guid == self.cur_banker_info.guid then
		self.curbankerleave_flag = 1
	end
	
end


-- 更新当庄庄家信息或者发送当前连庄庄家信息给客户端
function ox_table:send_cur_banker_to_client()
	self.cur_banker_info = self.cur_banker_info or {}
	local msg = {pb_banker_info = self.cur_banker_info}
	self:broadcast2client("SC_OxBankerInfo",msg)
end

-- 获取庄家
function ox_table:get_banker()
	
	-- 有用户上庄时且连庄情况,更新庄家信息发送给客户端
	if self.cur_banker_info.bankeruid == self.lastbankeruid then 
		--连庄次数累加
		self.cur_banker_info.bankertimes = self.cur_banker_info.bankertimes + 1
		self:send_cur_banker_to_client()
	else --else 非连庄庄家切换庄家
		--判断上庄列表是否为空,是则机器人上庄,默认10000金币
		-- todo ++
		if #self.bankerlist == 0 then
			log_warning("banker list is nil")
			-- 机器人上庄BANKER_ROBOT_INIT_UID = msg.RobotBankerInitUid
			local banker_robot = self:creat_banker_robot(TYPE_ROBOT_BANKER, 1,BANKER_ROBOT_INIT_UID,BANKER_ROBOT_START_MONEY)
			local max_bet_score = self:get_max_score(banker_robot.money <=0 and 0 or banker_robot.money)
			self.cur_banker_info = {
				guid = banker_robot.guid,
				nickname = banker_robot.nickname,
				money = banker_robot.money,
				bankertimes = 1,
				max_score = max_bet_score,
				banker_score = 0,
				left_score = max_bet_score,
				header_icon = banker_robot.header_icon,
			}
		
	--[[		self.cur_banker_info = {
				guid = 10000,
				nickname = "system_banker",
				money = 100000,
				bankertimes = 1,
				max_score = 10000,
				banker_score = 0,
				left_score = 10000,
				header_icon = -1, --头像
			}--]]
			self.cur_banker_info = self.cur_banker_info or {}
			local msg = {pb_banker_info = self.cur_banker_info}
			self:broadcast2client("SC_OxBankerInfo",msg)
			
		else --否则列表不为空,则取庄家列表中的庄家成员上庄
			self:send_banker_info_to_client()
			print("banker uid is xxx")
		end
	end
	self.max_score_ = self.cur_banker_info.max_score

end



-- 更新玩家列表
function ox_table:update_online_player_list()
	local playerinfo = {}
	local num_total = 0
	for i,v in pairs(self.ox_game_player_list) do --机器人玩家也发送到客户端显示
		--if v and v.is_player == true then --is_player==true的就为玩家,等于false为机器人
		if v then
			if v.is_player == true then --is_player==true的就为玩家,等于false为机器人
				local money = v:get_money()
				local headericon = v:get_header_icon()
				table.insert(playerinfo, {guid = v.guid,head_id = headericon,nickname = v.nickname,money = money, header_icon = headericon})
			else -- 机器人
				if v.nickname ~= "system_banker" and v.header_icon ~= -1 then --庄家不发送
					local robot_money = v.money
					local robot_headericon = v.header_icon
					table.insert(playerinfo, {guid = v.guid,head_id = robot_headericon,nickname = v.nickname,money = robot_money, header_icon = robot_headericon})
				end
			end
		end
	end
	table.sort(playerinfo, function (a, b)
		if a.money == b.money then
			return a.guid < b.guid
		else
			return a.money > b.money
		end
	end)
	self.all_player_list = {}
	for i=1,OX_PLAYER_LIST_MAX do
		local p = playerinfo[i]
		if p == nil then
			break
		end
		self.all_player_list[i] = p
		num_total = num_total + 1
	end
	return num_total
end

-- 发送按金币排序后的玩家显示在桌面(不包括当庄玩家)
function ox_table:send_player_list()
	print("send_player_list ......")
	local real_num = self:update_online_player_list()
	self.all_player_list = self.all_player_list or {}
	local msg = {top_player_total = real_num,pb_player_info_list = self.all_player_list}
	self:broadcast2client("SC_OxPlayerList",msg)
end

-- 检测下注区域是否正确
function ox_table:check_score_area(score_area_)
	-- 检测已经下注的区域 是否已经超过最多的区域
	if score_area_ < OX_AREA_ONE or score_area_ > OX_AREA_FOUR then
		return false
	end
	local max_score_area =0
	return (max_score_area < MAX_SCORE_AREA) and true or false 
end

-- 加注到指定区域
function ox_table:add_area_score(uid_,area_,score_)
	--[[
		uid_ ：玩家ID
		score_area_ ：下注区域
		score_:加注数量
		--
		{{uid:score_}}
		current_state[uid_]:该玩家在该区域的总下注金额
	]]
	
	local current_state = self.area_score_[area_]
	if not current_state then
		current_state = {}
		current_state[uid_] = score_
		self.area_score_[area_] = current_state
	else
		local old_score_ = (not current_state[uid_]) and 0 or current_state[uid_]
		current_state[uid_] = old_score_ + score_
		self.area_score_[area_] = current_state
	end
	return current_state[uid_]
end

-- 用户下注
function ox_table:add_score(player, score_area_,score_)
	--[[
		score_area_：下注区域
		score_ :下注数目
	]]
	if player == nil then
		log_warning("player is nil,return.")
		return
	end
	local player_money = 0
	if player.is_player  == true then -- 真实玩家
		player_money = player:get_money()
	else --机器人
		player_money = player.money
	end
	
	
	if self.status ~= OX_STATUS_PLAY then
		log_warning(string.format("ox_table:add_score guid[%d] status error", player.guid))
		return
	end
	
	-- 庄家不能下注
	if player.guid == self.cur_banker_info.guid then
		log_warning(string.format("ox_table:add_score, banker[%d] = guid[%d]",self.cur_banker_info.guid,player.chair_id))
		return
	end
	if score_ <= 0 then
		log_error(string.format("ox_table:add_score guid[%d] score[%d] <= 0", player.guid, score_))
		return
	end

	if not self:check_score_area(score_area_) then
		log_error(string.format("ox_table:add_score guid[%d], score_area_[%d] error",player.guid,score_area_))
		return
	end

--[[	--是否是前端可选择的筹码(非法筹码返回错误)
	local isrightscore = false
	for i,v in ipairs (robot_money_option) do
		if score_ == v then
			isrightscore = true
			break
		end
	end
	if isrightscore == false then
		log_error(string.format("ox_table:add_score guid[%d], score_[%d] error",player.guid,score_))
		return
	end --]]
	-- 判断1:玩家不满足最低下注金币限制
	if player_money < OX_PLAYER_MIN_LIMIT then
		local FailMsg = {
			result = pb.enum_id("Bet_Result","MONEY_LIMIT"),
		}
		send2client_pb(player, "SC_OxBetCoin", FailMsg)
		return
	end
	-- 判断2:你下注的金额不够赔(玩家金币不足)
	if score_ * OX_MAX_TIMES > player_money then
		local FailMsg = {
			result = pb.enum_id("Bet_Result","MONEY_ERROR"),
		}
		send2client_pb(player, "SC_OxBetCoin", FailMsg)
		return
	end
	-- 判断3:您的下注总额不能超过下注前携带金币的1/10上限
	if #self.player_bet_all_info == 0 then
		table.insert(self.player_bet_all_info,{guid = player.guid,bet_total = score_} )
	else
		local find_player_flag = 0
		for i, v in pairs (self.player_bet_all_info) do
			if v and v.guid == player.guid then
				find_player_flag = 1
				local bet_money = v.bet_total + score_
				if bet_money * OX_MAX_TIMES > player_money + v.bet_total then --下注总额与原下注前的自身携带金币总数比较
					print("guid bet max.."..player.guid)
					return
				else
					v.bet_total = bet_money
				end
			end
		end
		if find_player_flag == 0 then
			table.insert(self.player_bet_all_info,{guid = player.guid,bet_total = score_} )
		end
	end
	
	-- 判断4:您的下注超过上限()
	local money_ = self.last_score + score_
	if money_ > self.max_score_ then
		local FailMsg = {
			result = pb.enum_id("Bet_Result","BET_MAX"),
		}
		send2client_pb(player, "SC_OxBetCoin", FailMsg)
		return
	else
		self.last_score = money_
	end

	

	local this_area_player_bet_total = self:add_area_score(player.guid,score_area_,score_)

	-- 下注时扣除金币
	if player.is_player == true then -- 真实玩家
		player:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = score_}}, LOG_MONEY_OPT_TYPE_OX)
	else -- 机器人
		ox_robot:robot_cost_money(player,score_)
	end
	

	-- 先发送成功标志,再发送当前玩家下注信息
	local SuccFlag = {
		result = pb.enum_id("Bet_Result","BET_OK"),
	}
	send2client_pb(player, "SC_OxBetCoin", SuccFlag)
	
	local msg = {
		add_score_chair_id = player.guid, --玩家ID
		score_area = score_area_,         --下注区域
		score = score_,                   --该次下注金币数
		player_bet_this_area_money = this_area_player_bet_total, --该玩家在该区域下注总额
		money = player_money - score_,  --更新下注后剩余金币
	}
	self:broadcast2client("SC_OxAddScore", msg)
	

	--更新全局下注信息
	self:count_area_bet_money(score_area_,score_)

	-- 广播各区域下注总额,时时更新
	local nodify = {
		max_bet_score = self.max_score_,               --最大下注总额
		bet_tian_total = self.area_score_total.bet_tian_total,
		bet_di_total = self.area_score_total.bet_di_total,
		bet_xuan_total = self.area_score_total.bet_xuan_total,
		bet_huang_total = self.area_score_total.bet_huang_total,
		left_money_bet = self.area_score_total.left_money_bet, --还可下注金额
		total_all_area_bet_money = self.area_score_total.total_all_area_bet_money,        --所有区域下注金币总计
	}
	
	local msg = {pb_AreaInfo = nodify}
	self:broadcast2client("SC_OxEveryArea", msg)

end

-- 统计各区域下注金额以及下注所有区域总额
function ox_table:count_area_bet_money(_area, betmoney)

	if 1 == _area then
		self.area_score_total.bet_tian_total = self.area_score_total.bet_tian_total + betmoney
	elseif 2 == _area then
		self.area_score_total.bet_di_total = self.area_score_total.bet_di_total + betmoney
	elseif 3 == _area then
		self.area_score_total.bet_xuan_total = self.area_score_total.bet_xuan_total + betmoney
	elseif 4 == _area then
		self.area_score_total.bet_huang_total = self.area_score_total.bet_huang_total + betmoney
	end
	self.area_score_total.total_all_area_bet_money = self.area_score_total.bet_tian_total + self.area_score_total.bet_di_total + self.area_score_total.bet_xuan_total + self.area_score_total.bet_huang_total
	local left_bet_max = self.max_score_ - self.last_score  --还可下注金币数
	self.area_score_total.left_money_bet = left_bet_max
end

-- 求出最大最小索引(index_type:1最大索引,2最小索引)

function ox_table:GetCardMaxOrMinIndex(index_type)
	
	local card_result = self:analyse_cards()
	local max_index = 1
	local min_index = 1
	local tempCard = card_result[1]
	for i =2,MAX_SCORE_AREA+1 do
		--local win = self:compare_cards(tempCard,card_result[i])
		local win = compare_cards(tempCard,card_result[i])
		if index_type == MAX_CARDS_INDEX then
			if win == false then
				tempCard = card_result[i]
				max_index = i
			end
		else
			if win == true then
				tempCard = card_result[i]
				min_index = i
			end
		end
	end
	if index_type == MAX_CARDS_INDEX then
		return max_index
	else
		return min_index
	end
end

-- 分析牌型,求出最大最小牌索引
function ox_table:analyse_cards()
	--body
	local ret ={}
	for i=1,MAX_SCORE_AREA+1 do
		--local ox_type_,value_list_,color_,extro_num_ = self:get_cards_type(self.area_cards_[i])
		local ox_type_,value_list_,color_,extro_num_ = get_cards_type(self.area_cards_[i])
		local times = get_type_times(ox_type_,extro_num_)
		ret[i] = {ox_type = ox_type_,val_list = value_list_,color = color_, extro_num = extro_num_, cards_times = times}
	end
	
	return ret
	
end


--洗牌
function ox_table:shuffle_card()
	local k = #self.cards
	--math.randomseed(tostring(os.time()):reverse():sub(1, 6))

	for i=1,MAX_SCORE_AREA+1 do
		local cards ={}
		for j=1,5 do
			local r = random.boost_integer(1,k)
			cards[j] = self.cards[r]
			if r~=k then
				self.cards[r],self.cards[k] = self.cards[k],self.cards[r]
			end
			k = k-1
		end
		self.area_cards_[i] = cards
	end
	
	-- 做牌,求出最大最小牌型,满足系统必赢概率,若系统当庄则将最大牌给系统,若玩家当庄则将最小牌给玩家,系统抽水
	local max_index = self:GetCardMaxOrMinIndex(MAX_CARDS_INDEX)
	local min_index = self:GetCardMaxOrMinIndex(MIN_CARDS_INDEX)
	if max_index == min_index then -- 获取索引错误
		return false
	end

	-- 满足系统必赢系数,换牌
	local tempCards = {}
	local rand_coeff = random.boost_integer(1,SYSTEM_COEFF)
	local float_coeff = random.boost_integer(1,SYSTEM_FLOAT_PROB)
	local this_time_coeff = (SYSTEM_MUST_WIN_PROB + float_coeff) * OX_EXCHANGE_RATE
	--log_info(string.format("rand_coeff = [%d], float_coeff = [%d], must_win = [%d],this_time_coeff = [%d]\n",rand_coeff,float_coeff,SYSTEM_MUST_WIN_PROB,this_time_coeff))
	if rand_coeff < this_time_coeff then
		if self.flag_banker_robot == 1 then -- 系统当庄
			if max_index ~= 1 then
				self.area_cards_[max_index],self.area_cards_[1] = self.area_cards_[1],self.area_cards_[max_index]
			end
		else -- 玩家当庄
			if min_index ~= 1 then
				self.area_cards_[min_index],self.area_cards_[1] = self.area_cards_[1],self.area_cards_[min_index]
			end
		end
	end	
	
	return true
end

-- 获取当前庄家为机器人还是玩家1机器人,0玩家
function ox_table:get_curBanker_type()
	for i,v in ipairs(self.ox_game_player_list) do
		if v and v.guid == self.cur_banker_info.guid and v.is_player == false then --机器人当庄
			self.flag_banker_robot = 1
			break
		end
	end 
end

-- 统计人数(真实玩家)
function ox_table:count_player_total()
	local total_player_count = 0
	for i, v in pairs (self.ox_game_player_list) do
		if v and v.is_player == true then
			total_player_count = total_player_count + 1
		end
	end
	return total_player_count
end
-- 测试牌型
function ox_table:test_card()
--[[	local k = #self.cards
	--test code
	local banker_card = {4,34,46,38,53}
	local tian_card = {51,24,50,45,52}
	local di_card = {1,21,29,18,52}
	local xuan_card = {47,14,10,35,43}
	local huang_card = {48,24,28,29,7}
	self.area_cards_[1] = banker_card
	self.area_cards_[2] = tian_card
	self.area_cards_[3] = di_card
	self.area_cards_[4] = xuan_card
	self.area_cards_[5] = huang_card--]]
	--test code
	local testcard = {52,53}
	local k = #self.cards
	--math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	for i=1,MAX_SCORE_AREA+1 do
		local cards ={}
		for j=1,5 do
			local r = random.boost_integer(1,k)
			cards[j] = self.cards[r]
			if r~=k then
				self.cards[r],self.cards[k] = self.cards[k],self.cards[r]
			end
			k = k-1
		end
		self.area_cards_[i] = cards
	end
	if self.which_type == 2 then --低倍场(1~~3倍)
		for i=1,2 do
			local num = random.boost_integer(1,5)
			local index_bomb = random.boost_integer(1,5)
			self.area_cards_[num][index_bomb] = 52+i-1
		end
		
	end
end



-- 发牌
function ox_table:send_cards_to_client()
	--self.status = OX_STATUS_OVER
	self.table_game_id = self:get_now_game_id()
	self.gamelog.table_game_id = self.table_game_id --游戏日志
	self.gamelog.banker_id = self.cur_banker_info.guid --游戏日志
	self.gamelog.cell_money = self.cell_money  --游戏日志
	self.gamelog.player_count = self:count_player_total() --游戏日志
	
	self:next_game()
	print("send_cards_to_client......")
	--self:get_curBanker_type()
	self.gamelog.system_banker_flag = self.flag_banker_robot --游戏日志,系统当庄为1,玩家当庄为0
	local msg = {}
	
	local shuffle_cards_times = 0
	while(true)
	do
		if self:shuffle_card() then
			break
		end
		shuffle_cards_times = shuffle_cards_times + 1
		if shuffle_cards_times > 100 then
			break
		end
	end
	
	--self:test_card()
	local all_cards = {}
	for i =1,MAX_SCORE_AREA+1 do
		local cards = {}
		cards.score_area = i
		cards.card = self.area_cards_[i]
		table.insert(all_cards,cards)
	end
	msg.pb_cards = all_cards
	for i,v in ipairs(self.ox_game_player_list) do
		if v and v.is_player == true then --is_player==true就为玩家,false为机器人
			send2client_pb(v,"SC_OxDealCard",msg)
		end
	end

	-- 结算
	self:send_result()

end



-- 计算结果
function ox_table:calc_result()

	local ret ={}
	local cardResult = {}
	for i=1,MAX_SCORE_AREA+1 do
		--local ox_type_,value_list_,color_,extro_num_ = self:get_cards_type(self.area_cards_[i])
		local ox_type_,value_list_,color_,extro_num_ = get_cards_type(self.area_cards_[i])
		local times = get_type_times(ox_type_,extro_num_)
		ret[i] = {ox_type = ox_type_,val_list = value_list_,color = color_, extro_num = extro_num_, cards_times = times}
		local result = {}
		result.score_area = i
		result.card_type = ox_type_
		result.card_times = times
		table.insert(cardResult, result)
		-- 游戏日志牌型
		local card_msg = {
			score_area = i,
			cards = string.format("%s",table.concat(self.area_cards_[i],',')),
			card_type = ox_type_,
			card_times = times
		}
		table.insert(self.gamelog.CardTypeInfo,card_msg)
	end
	local msg = {pb_result = cardResult}
	self.cardResult = cardResult
	self:broadcast2client("SC_CardResult", msg)

	return ret
end

-- 添加结果的计分板
function ox_table:add_scorebord(results)
	table.insert(self.scoreboard,results)
	if #self.scoreboard > MAX_SCOREBORD_LEN then
		table.remove(self.scoreboard,1)
	end
end
-- 清除计分板
function ox_table:clear_scorebord()
	self.scoreboard ={}
end

-- 发送计分板消息
function ox_table:send_ox_record(player)
	local msg = {
		pb_recordresult ={}				
	}
	for i, v in pairs(self.scoreboard) do
		local ret ={}
		ret.result =v
		table.insert(msg.pb_recordresult,ret)
	end
	send2client_pb(player,"SC_OxRecord",msg)
end

-- 广播积分版消息
function ox_table:broadcas_record_result()
	local msg = {
		pb_recordresult ={}				
	}
	local record_len = #self.scoreboard
	for i, v in pairs(self.scoreboard) do
		if i == record_len then --取最后一条记录广播
			local ret ={}
			ret.result =v
			table.insert(msg.pb_recordresult,ret)
		end
		
	end
	self:broadcast2client("SC_OxRecord", msg)
end


-- 发送结束消息
function ox_table:send_result()
	print("send_result......")

	
	local ret = self:calc_result()
	local player_score = {}
	local player_pay_score ={}

	local result_ret ={}
	local record_ret ={}
	local all_win_times = 0 --标识等于4则为通杀
	local all_lose_times = 0 --标识等于4则为通赔
	local flag_all_win_or_lose = 0 --标识1则为通杀,标识2则为通赔,其他不管
	
--[[	-- 游戏日志 玩家列表
	for i,v in pairs(self.ox_game_player_list) do
		if v then
			table.insert(self.gamelog.Player_list,v)
		end
	end--]]
	
	-- 游戏日志区域下注信息
	self.gamelog.Area_bet_all_count = self.area_score_total
	
	for i =2,MAX_SCORE_AREA+1 do
		--local win = self:compare_cards(ret[1],ret[i]) --庄家与天地玄黄比较牌型,庄家赢返回true,庄家输返回false	
		local win = compare_cards(ret[1],ret[i]) --庄家与天地玄黄比较牌型,庄家赢返回true,庄家输返回false	
		--调换win顺序,win为true表示庄家赢,返回0,反之返回1记录到积分板
		local record_flag = false
		if win == true then
			all_win_times = all_win_times + 1
			record_flag = false --表示庄家赢(客户端显示为"X")
			if self.which_type == 2 then --低倍场(1~~3倍)
				local odds_banker = get_cards_odds(ret[1].cards_times)
				table.insert(result_ret,{win,odds_banker}) --庄家赢则按庄家倍数赔付	
			else	--高倍场按实际倍数赔付
				table.insert(result_ret,{win,ret[1].cards_times}) --庄家赢则按庄家倍数赔付
			end
			
		else
			all_lose_times = all_lose_times + 1
			record_flag = true --庄家输(客户端显示为"√")
			if self.which_type == 2 then --低倍场
				local odds_player = get_cards_odds(ret[i].cards_times)
				table.insert(result_ret,{win,odds_player}) --庄家赢则按庄家倍数赔付	
			else --高倍场按实际倍数赔付(1~~10倍)
				table.insert(result_ret,{win,ret[i].cards_times})  --玩家赢在按该区域倍数赔付
			end
			
		end
		table.insert(record_ret,record_flag)
		local msg = {
			area_ = i - 1,
			result = record_flag
		}
		table.insert(self.gamelog.Record_result,msg) --游戏记录,与庄家比较结果
	end
	-- 发送给客户端每个区域牌型比较结果
	local msg = {pb_CompareResult = self.gamelog.Record_result}
	self:broadcast2client("SC_CardCompareResult", msg)
	
	--通杀通赔判断
	if all_win_times == 4 then
		flag_all_win_or_lose = 1 --通杀
	elseif all_lose_times == 4 then
		flag_all_win_or_lose = 2 --通赔
	end
	

	local curtime = get_second_time()
	local banker_uid = self.cur_banker_info.guid

	for j =1,MAX_SCORE_AREA do
		-- {area = {uid=score_}}
		local area_info = (self.area_score_[j] == nil ) and {} or self.area_score_[j]
		-- print_table(area_info,"area_info ")
		for uid,score in pairs(area_info) do
			local win_flag = result_ret[j][1]
			local win_times = result_ret[j][2]
			local old_banker_score = (player_score[banker_uid] == nil) and 0 or player_score[banker_uid]

			-- 单纯记数相关
			local old_pay = player_pay_score[uid] == nil and 0 or player_pay_score[uid]
			local new_pay = old_pay + score
			player_pay_score[uid] = new_pay
			--记录游戏日志 各区域玩家各下注信息
			local msg = {
				area = j,
				guid = uid,
				score = score
			}
			table.insert(self.gamelog.Area_bet_info,msg)
			if win_flag then
				-- 扣钱相关
				-- 庄家赢
				local old_score = (player_score[uid] == nil) and 0 or player_score[uid]
				player_score[uid] = old_score - score*(win_times - 1)
				player_score[banker_uid] = old_banker_score + score *win_times
				
			else
				--- 玩家赢
				local old_score = (player_score[uid] == nil) and 0 or player_score[uid]
				player_score[uid] = old_score + score*(win_times+1)
				player_score[banker_uid] = old_banker_score - score*win_times
			end
		end
	end

	local notify = {
		pb_conclude = {}, --[位置，收益]
	}

	
	--先算庄家结算信息
	local banker_earn_score = 0
	local banker_tax = 0
	for i,v in pairs (self.ox_game_player_list) do
		if v and v.guid == self.cur_banker_info.guid then
			local old_money = 0
			local s_type = 1
			if v.is_player == true then -- 真实玩家
				old_money = v.pb_base_info.money
			else	
				old_money = v.money
			end
			banker_earn_score = player_score[banker_uid] == nil and 0 or player_score[banker_uid] --庄家总收入			
			if banker_earn_score > 0 then
				if self.room_.tax_open_ == 1 then --开启税收
					banker_tax = banker_earn_score * OX_PLAYER_TAX
				end	
				--print("未取整庄家台费= "..banker_tax)
				if banker_tax >= MIN_TAX_LIMIT then
					banker_tax = math.floor(banker_tax + 0.5) -- 台费四舍五入取整
				else
					banker_tax = 0 --小于最低标准则不扣台费
				end
				if v.is_player == true then self:ChannelInviteTaxes(v.channel_id,v.guid,v.inviter_guid,banker_tax) end
				if v.is_player == false then  --不抽机器人的台费2017-04-05
					banker_tax = 0
				end
				self.tax_total = self.tax_total + banker_tax
				--print("四舍五入取整庄家台费= "..banker_tax)
				banker_earn_score = banker_earn_score - banker_tax
				if v.is_player == false then --机器人当庄
					ox_robot:robot_add_money(v,banker_earn_score)
				else --玩家当庄
					v:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = banker_earn_score}}, LOG_MONEY_OPT_TYPE_OX)
				end
				s_type = 2
			elseif banker_earn_score < 0 then
				if v.is_player == false then --机器人当庄					
					ox_robot:robot_cost_money(v,-banker_earn_score)
				else --玩家当庄
					v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = -banker_earn_score}}, LOG_MONEY_OPT_TYPE_OX)
				end
				
			end
		
			if v.is_player == true then -- 真实玩家
				self:PlayerMoneyLog(v,s_type,old_money,banker_tax,banker_earn_score,self.table_game_id)
			else
				self:RobotMoneyLog(v,1,s_type,old_money,banker_tax,banker_earn_score,self.table_game_id)
			end
			--当前庄家信息更新
			local new_max_score = self:get_max_score(self.cur_banker_info.money + banker_earn_score)
			self.cur_banker_info = {
				guid = self.cur_banker_info.guid,
				nickname = self.cur_banker_info.nickname,
				money = self.cur_banker_info.money + banker_earn_score,
				bankertimes = self.cur_banker_info.bankertimes,
				max_score = new_max_score,
				banker_score = self.cur_banker_info.banker_score + banker_earn_score,
				left_score = new_max_score,
				header_icon = self.cur_banker_info.header_icon, --头像
			}
			self:send_cur_banker_to_client()
	
			local result_info = {
				guid = v.guid,
				is_android = v.is_player == false and 1 or 0,
				table_id = curtime,
				banker_id = v.guid,
				nickname = v.nickname,
				money = self.cur_banker_info.money,
				win_money = banker_earn_score,
				bet_money = 0,
				tax = banker_tax,
				curtime = curtime,
			}
			
			-- base_player:player_save_ox_data(result_info)
			break
		end
	end
	
	
	
	for i,v in pairs (self.ox_game_player_list) do
		local result = {}
		if v then
			if v.guid == self.cur_banker_info.guid then --庄家
				result = {
				chair_id = v.guid,
				pay_score = 0 ,  --庄家不能下注
				earn_score = banker_earn_score,
				system_tax = banker_tax,
				banker_score = banker_earn_score,
				all_win_or_lose_flag = flag_all_win_or_lose,
				money = self.cur_banker_info.money,
				tax_show_flag = self.tax_show_       --新增税收显示(1显示,0不显示) 
			}
			else --玩家
				local old_money = 0
				local s_type = 1
				local player_earn_score = player_score[v.guid] == nil and 0 or player_score[v.guid]  --总收入(包含本金)
				local player_bet_money = player_pay_score[v.guid] == nil and 0 or player_pay_score[v.guid]  --本金
				if v.is_player == true then -- 真实玩家
					old_money = v.pb_base_info.money + player_bet_money
				else	
					old_money = v.money + player_bet_money
				end
				local player_tax = 0
				if player_earn_score > 0 then --扣取台费,赢了抽台费,输了不抽取台费
					if self.room_.tax_open_ == 1 then --开启税收
						player_tax = (player_earn_score - player_bet_money) * OX_PLAYER_TAX
					end
					--print("未取整玩家台费= "..player_tax)
					if player_tax >= MIN_TAX_LIMIT then
						player_tax = math.floor(player_tax + 0.5) -- 台费四舍五入取整
					else
						player_tax = 0 --小于最低标准则不扣台费
					end
					if v.is_player == true then self:ChannelInviteTaxes(v.channel_id,v.guid,v.inviter_guid,player_tax) end
					if v.is_player == false then  --不抽机器人的台费2017-04-05
						player_tax = 0
					end
					self.tax_total = self.tax_total + player_tax
					--print("四舍五入取整玩家台费= "..player_tax)
					player_earn_score = player_earn_score - player_tax
					if v.is_player == false then -- 机器人
						ox_robot:robot_add_money(v,player_earn_score)
					else -- 真实玩家
						v:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = player_earn_score}}, LOG_MONEY_OPT_TYPE_OX)
					end
					--player_earn_score = player_earn_score -  player_bet_money -- 实际赢的金币总数(去除已下注的和台费)
					s_type = 2
				elseif player_earn_score < 0 then
					if v.is_player == false then -- 机器人
						ox_robot:robot_cost_money(v,-player_earn_score) 
					else -- 真实玩家
						v:cost_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = -player_earn_score}}, LOG_MONEY_OPT_TYPE_OX)
					end
					--player_earn_score = player_earn_score -  player_bet_money -- 输的金币总数(包含已下注的)
				end
				player_earn_score = player_earn_score -  player_bet_money
				local cur_money = 0
				if v.is_player == false then -- 机器人
					cur_money = v.money
					self:RobotMoneyLog(v,0,s_type,old_money,player_tax,player_earn_score,self.table_game_id)
				else
					cur_money = v.pb_base_info.money
					self:PlayerMoneyLog(v,s_type,old_money,player_tax,player_earn_score,self.table_game_id)
				end
				
				result = {
					chair_id = v.guid,                --玩家ID
					pay_score = player_bet_money ,    --玩家下注金额
					earn_score = player_earn_score,   --玩家总收入(扣除台费)
					system_tax = player_tax,		  --玩家台费
					banker_score = banker_earn_score, --庄家总得分(扣除台费)
					all_win_or_lose_flag = flag_all_win_or_lose, --通杀通赔标识
					money = cur_money,
					tax_show_flag = self.tax_show_       --新增税收显示(1显示,0不显示) 
					
				}	
				
				local result_info = {
					guid = v.guid,
					is_android = v.is_player == false and 1 or 0,
					table_id = curtime,
					banker_id = banker_uid,
					nickname = v.nickname,
					money = cur_money,
					win_money = player_earn_score,
					bet_money = player_bet_money,
					tax = player_tax,
					curtime = curtime,
				}
				-- base_player:player_save_ox_data(result_info)
				-- 更新上庄列表中玩家信息(该局下注输了后不够上庄的玩家移除)
				if v.is_player == true then --真实玩家
					self:update_bankerlist_info(v.guid,cur_money)
				end
						
			end
			local msg = {pb_player_result = result}
			send2client_pb(v,"SC_OxResult", msg)
			
			table.insert(notify.pb_conclude, result)
		
		end
	end

	--增加记录板信息
	self:add_scorebord(record_ret)

	-- 游戏日志 记录结算信息
	self.gamelog.Game_Conclude = notify.pb_conclude
	self.conclude = notify.pb_conclude
	
	-- 更新最新桌面玩家信息显示
	local real_num = self:update_online_player_list()
	self.all_player_list = self.all_player_list or {}
	local msg = {top_player_total = real_num,pb_player_info_list = self.all_player_list}
	self:broadcast2client("SC_OxPlayerList", msg)

	--写入游戏日志
	local Game_total_time = OX_TIME_READY + OX_TIME_ADD_SCORE + OX_TIME_OPEN_CARD --游戏总时间
	self.gamelog.end_game_time = self.gamelog.start_game_time + Game_total_time
	self.gamelog.system_tax_total = self.tax_total
	local s_log = lua_to_json(self.gamelog)
	--print(s_log)
	self:Save_Game_Log(self.gamelog.table_game_id,self.def_game_name,s_log,self.gamelog.start_game_time,self.gamelog.end_game_time)
	
	-- 更新上庄列表玩家最新信息
	self:send_latest_bankerlist_info()

	-- 删除下注机器人
	for i,v in pairs (self.tb_bet_robot) do
		if v then
			self:del_robot(v.guid)
		end
	end
	
	-- 踢人
	--self:del_offline_player()
	--local iRet = base_table.check_game_maintain(self)--检查游戏是否将进入维护阶段
	--if iRet == true then--游戏将进入维护阶段
	if game_switch == 1 then
		for i,v in pairs (self.ox_game_player_list) do
			if  v and v.is_player == true and v.vip ~= 100 then 
				table.remove(self.ox_game_player_list,i)
			end
		end
	end
	--机器人只上庄一次后切换
	if self.flag_banker_robot == 1 then
	--if banker_uid ~= 0 and banker_uid >= PLAYER_MAX_UID and banker_uid < BANKER_ROBOT_UID then 
		self:del_robot(banker_uid)
		self.change_banker_flag = 1 --切换庄家
		--self:change_banker()
		return
	end

	-- 非庄家主动下庄时判断庄家连庄次数,达到最大次数则切换庄家 
	-- 非庄家主动下庄但金币不足下次当庄时,强制下庄,切换庄家
	if self.cur_banker_info.bankertimes == DEFAULT_CONTINUOUS_BANKER_TIMES  or self.cur_banker_info.money < OX_BANKER_LIMIT then
		-- 切换庄家
		self.change_banker_flag = 1 --切换庄家
		--self:change_banker()
		return
	end

	-- 庄家这局完成后金币数够且没有达到连庄次数时,主动下庄
	if self.curbankerleave_flag == 1 then
		self.change_banker_flag = 1 --切换庄家
		-- self:change_banker()
		return
	end
	--更新连庄庄家上庄次数
	self.cur_banker_info.bankertimes = self.cur_banker_info.bankertimes + 1
	self.cur_banker_info = {
		guid = self.cur_banker_info.guid,
		nickname = self.cur_banker_info.nickname,
		money = self.cur_banker_info.money,
		bankertimes = self.cur_banker_info.bankertimes,
		max_score = self.cur_banker_info.max_score,
		banker_score = self.cur_banker_info.banker_score,
		left_score = self.cur_banker_info.max_score,
		header_icon = self.cur_banker_info.header_icon,
	}
	self:send_cur_banker_to_client()
	
	
end


--请求玩家数据  todo++
function ox_table:PlayerConnectionOxGame(player)
	
	print("PlayerConnectionOxGame ......")
	base_table.ReconnectionPlayMsg(self,player)
	-- 先发送个人信息到客户端
	print("player coming ox game : "..player.guid)
	--发送基础配置(上庄条件,筹码信息)
	local chip_info = {}
	for i = 1, 5 do	
		local info_chip = {}
		info_chip.chip_index = i
		info_chip.chip_money = robot_money_option[i]
		table.insert(chip_info,info_chip)
	end
	local config_msg = {banker_limit = OX_BANKER_LIMIT,pb_info_chip = chip_info,bet_min_limit_money = OX_PLAYER_MIN_LIMIT}
	send2client_pb(player, "SC_Ox_config_info", config_msg)
	
	local notify = {
		pb_player_info = {}
		}
	
	local v = {
			guid = player.guid,
			nickname = player.nickname,
			money = player:get_money(),
			header_icon = player:get_header_icon()
		}
	table.insert(notify.pb_player_info, v)
	
	send2client_pb(player, "SC_OxPlayerConnection", notify)
	
	
	
	local msg = {
		
			}

	local reconnect_flag = 0 -- 断线重连标志
	for i, v in pairs (self.ox_game_player_list) do
		if v and player.guid == v.guid then
			self.ox_game_player_list[i] = player
			reconnect_flag = 1 --断线重连的用户更新列表
		end
	end
	if reconnect_flag == 0 then --非断线重连用户直接插入
		for i, v in pairs (self.ox_game_player_list) do
			if not v then
				self.ox_game_player_list[i] = player
				break
			end
		end
	end
	--再通过当前桌子状态判断发送相关信息到桌面显示
	if self.status == OX_STATUS_READY then
		local curtime = get_second_time()
		local down_time  =  self.time0_ + OX_TIME_READY - curtime
		msg["status"] = OX_STATUS_READY --当前状态
		msg["count_down_time"] = down_time --状态倒计时
		msg["pb_curBanker"] = self.cur_banker_info or {} --当前庄家
		msg["pb_player_info_list"] = self.all_player_list or {} --当前玩家列表
		msg["pb_banker_list"] = self.bankerlist or {}  --当前申请上庄列表
		
	elseif self.status == OX_STATUS_PLAY then
	
		local player_bet = {}
		local player_bet_info = {}
		for k = 1,MAX_SCORE_AREA do
			local area_info = (self.area_score_[k] == nil ) and {} or self.area_score_[k]
			for uid,score in pairs(area_info) do
				if player.guid == uid then
					local bet_money = (area_info[uid] == nil) and 0 or area_info[uid]
					local player_bet_area = {which_area = k, bet_money =bet_money}
					table.insert(player_bet_info, player_bet_area)
					break
				end				
			end
		end
		local curtime = get_second_time()
		local down_time  = self.time0_ + OX_TIME_ADD_SCORE - curtime
		msg["status"] = OX_STATUS_PLAY   --当前状态
		msg["count_down_time"] = down_time  --状态倒计时
		msg["pb_curBanker"] = self.cur_banker_info or {}    --当前庄家
		msg["pb_player_info_list"] = self.all_player_list or {}  --当前玩家列表
		msg["pb_banker_list"] = self.bankerlist or {}  --当前申请上庄列表
		msg["pb_AreaInfo"] = self.area_score_total or {}  --当前每个区域下注总额以及总下注总额
		msg["pb_player_area_bet_info"] = player_bet_info or {}  --当前玩家在每个区域下注
	
	elseif self.status == OX_STATUS_OVER then
		local result = {}
		for _,v in ipairs(self.conclude) do
			if v and v.chair_id == player.guid then
				result = v
				break
			end
		end 
		--区域以及相应的扑克列表
		local cardInfo = {}
		local cardResult = {} --当前每个区域牌型
		for i=1,MAX_SCORE_AREA+1 do
			table.insert(cardInfo,{score_area = i,card = self.area_cards_[i]})
		end
		local curtime = get_second_time()
		local down_time  = self.time0_ + OX_TIME_OPEN_CARD - curtime
		msg["status"] = OX_STATUS_OVER  --当前状态
		msg["count_down_time"] = down_time --状态倒计时
		msg["pb_curBanker"] = self.cur_banker_info or {}    --当前庄家
		msg["pb_player_info_list"] = self.all_player_list or {} --当前玩家列表
		msg["pb_banker_list"] = self.bankerlist or {} --当前申请上庄列表
		msg["pb_AreaInfo"] = self.area_score_total or {} --当前每个区域下注总额以及总下注总额
		msg["pb_player_area_bet_info"] = player_bet_info or {} --当前玩家在每个区域下注
		msg["pb_cards"] = cardInfo or {}  --当前扑克列表
		msg["pb_result"] = self.cardResult or {} --当前每个区域牌型
		msg["pb_conclude"] = result or {}  -- 玩家结果

	end
	send2client_pb(player, "SC_OxTableInfo", msg)
	self:send_player_list() --广播玩家列表
	self:send_ox_record(player)
end

-- 机器人下注信息存入全局表中
function ox_table:robot_bet_money(bet_robot)
	
	if bet_robot.money <= 0 then
		return
	end
	
	-- 下注次数
	local bet_times = random.boost_integer(1,ROBOT_BET_TIMES_COEFF)
	local cur_bet_money = 0
	for i=1,bet_times,1
	do
		-- 每次下注区域随机
		local bet_area = random.boost_integer(1,MAX_SCORE_AREA)
		-- 每次下注金额
		local bet_index_money =  random.boost_integer(1,ROBOT_BET_MONEY_OPTION_TOTAL)
		cur_bet_money = cur_bet_money + robot_money_option[bet_index_money]
		if cur_bet_money * OX_MAX_TIMES > bet_robot.money then --不够赔
			break
		end
		table.insert(self.robot_bet_info,{bet_robot = bet_robot, bet_area = bet_area, bet_money = robot_money_option[bet_index_money]})
	end
end

-- 打乱机器人下注信息
function ox_table:shuffle_robot_betinfo_table()
	
	local len = #self.robot_bet_info
	for i=1,len do
		local info_bet = {}
		local x = random.boost_integer(1,len)
		local y = random.boost_integer(1,len)
		if x ~= y then
			self.robot_bet_info[x], self.robot_bet_info [y] = self.robot_bet_info[y], self.robot_bet_info[x]
		end
		len = len - 1
	end
end


-- 开启下注机器人
function ox_table:start_bet_money_robot()
--[[	local player_acturel_total = 0 --真实玩家
	for i, p in ipairs(self.ox_game_player_list) do
		if p and p.is_player == true then
			player_acturel_total = player_acturel_total + 1
		end
	end--]]

	--if player_acturel_total < PLAYER_MIN_LIMIT then --真实玩家个数小于PLAYER_MIN_LIMIT,调用机器人下注,机器人个数随机
	if self.flag_banker_robot == 1 then --条件更改:机器人上庄则创建下注机器人
		--math.randomseed(tostring(os.time()):reverse():sub(1, 6))
		local rand_num = BET_ROBOT_RAND_COEFF + random.boost_integer(1,BET_ROBOT_RAND_COEFF)	
		self.tb_bet_robot = self:creat_rand_bet_robot(TYPE_ROBOT_BET,rand_num,BET_ROBOT_INIT_UID,BET_ROBOT_START_MONEY)
	end

	for i, v in pairs (self.tb_bet_robot) do
		if v then
			self:robot_bet_money(v)
		end
	end	
	self:shuffle_robot_betinfo_table()
end

-- 玩家离开游戏
function ox_table:playerLeaveOxGame(player)
	print(string.format("player[%d] leave ox game",player.guid))
	for i,v in pairs (self.ox_game_player_list) do
		if v and v.guid == player.guid then
			self.ox_game_player_list[i] = false
			break
		end
	end
	
	for i, v in pairs(self.bankerlist) do
		if v and v.guid == player.guid then
			table.remove(self.bankerlist,i)
			break
		end
	end
	self:send_player_list() --广播玩家列表
	self:send_latest_bankerlist_info()
end

--[[-- 判断是否游戏中
function  ox_table:isPlay( ... )
	print("ox_table:isPlay :"..self.status)
	return true
end
--]]
-- 检查是否可取消准备
function ox_table:check_cancel_ready(player, is_offline)
	base_table.check_cancel_ready(self,player,is_offline)
	player:setStatus(is_offline)
	if is_offline then
		--掉线处理
		self:del_player(player.guid)
		self:playeroffline(player)
		player:forced_exit()
		self:send_player_list() --广播玩家列表
		return false
	end	
	--退出
	return true
end

-- 删除掉线真实玩家
function ox_table:del_offline_player()
	for i, v in pairs (self.player_list_) do
		if v and v.is_player == true and v.is_offline == true then
			del_player(v.guid)
			v:forced_exit()
		end
	end
end


-- 心跳
function ox_table:tick()
	-- 游戏逻辑
	if self.status == OX_STATUS_READY then
		local curtime = get_second_time()
		if curtime - self.time0_ >= OX_TIME_READY then
			if self:count_player_total() > 0 then
				local msg = {status = OX_STATUS_PLAY,count_down_time = OX_TIME_ADD_SCORE}
				self:broadcast2client("SC_OxSatusAndDownTime", msg)	
		
				self.time0_ = curtime
				self.status = OX_STATUS_PLAY
				self:init_global_val()
			else
				--local msg = {status = OX_STATUS_READY,count_down_time = OX_TIME_READY}
				--self:broadcast2client("SC_OxSatusAndDownTime", msg)
				self.time0_ = curtime
				self.status = OX_STATUS_READY
				--self:init_global_val()
				--print("============cashswitch gameswitch",cash_switch, game_switch)
			end
			
		end
	elseif self.status == OX_STATUS_PLAY then
		if self.robot_start_bet_flag == 0 then
			if SWITCH_BET_ROBOT == 1 then
				self:start_bet_money_robot()
				self.last_bet_time = get_second_time()
				self:send_player_list()
			end
			self.robot_start_bet_flag = 1
		end
		
				
		local curtime = get_second_time()
		-- 每循环1s在self.robot_bet_info随机抽取几个机器人下注信息模拟下注,直到在下注时间结束前全部下注完成
		local bet_info_table_len = #self.robot_bet_info
		--local rand_seconds = random.boost_integer(1,3)
		--if bet_info_table_len > 0 and curtime - self.last_bet_time >= rand_seconds then
		if bet_info_table_len > 0 then
			local rand_seconds = random.boost_integer(1,3)
			if curtime - self.last_bet_time >= rand_seconds then
				local rand_bet_robot_num = 1
				if bet_info_table_len > ROBOT_BET_MAX_NUM then --下注机器人总数超过ROBOT_BET_MAX_NUM则每秒最多下注ROBOT_BET_MAX_NUM个
					rand_bet_robot_num = random.boost_integer(1,ROBOT_BET_MAX_NUM)
				else
					rand_bet_robot_num = random.boost_integer(1,bet_info_table_len)
				end
				
				bet_info_table_len = bet_info_table_len - rand_bet_robot_num
				for i,v in pairs (self.robot_bet_info) do
					local tempTable = {}
					tempTable = self.robot_bet_info[1]
					self:add_score(tempTable.bet_robot, tempTable.bet_area,tempTable.bet_money)
					table.remove(self.robot_bet_info,1)
					if i == rand_bet_robot_num then
						break
					end
				end
				self.last_bet_time = curtime
			end
		end
		
		
		-- 若离下注时间结束2s内,机器人下注还没有全部下完时则将self.robot_bet_info剩余的信息全部下完
		if curtime - self.time0_ >= OX_TIME_ADD_SCORE - ROBOT_BET_LAST_TIME and bet_info_table_len > 0then
			for i,v in pairs (self.robot_bet_info) do
				local tempTable = {}
				tempTable = self.robot_bet_info[1] --取一个删一个
				self:add_score(tempTable.bet_robot, tempTable.bet_area,tempTable.bet_money)
				table.remove(self.robot_bet_info,1)
			end
		
		end
		
		if curtime - self.time0_ >= OX_TIME_ADD_SCORE then
			local msg = {status = OX_STATUS_OVER,count_down_time = OX_TIME_OPEN_CARD}
			self:broadcast2client("SC_OxSatusAndDownTime", msg)
			self.time0_ = curtime
			self.status = OX_STATUS_OVER
			-- 下注结束,推送牌数据以及结算和开牌时间
			self:send_cards_to_client()	
		end
	elseif self.status == OX_STATUS_OVER then
		local curtime = get_second_time()
		if curtime - self.time0_ >= OX_TIME_OPEN_CARD then
			if self.change_banker_flag == 1 then --切换庄家
				self:change_banker()
			end
			self:broadcas_record_result() --广播上局游戏结果
			local msg = {status = OX_STATUS_READY,count_down_time = OX_TIME_READY}
			self:broadcast2client("SC_OxSatusAndDownTime", msg)
			self.time0_ = curtime
			self.status = OX_STATUS_READY	
			self:init_global_val()
		end

	end
	-- 计分板清除
	if not is_same_day(get_second_time(),self.last_tick_time) then
		self:clear_scorebord()
		local curtime = get_second_time()
		self.last_tick_time = curtime
	end
end
