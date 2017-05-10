--百人牛牛机器人逻辑

--local room_manager = g_room_manager
local pb = require "protobuf"
require "game/lobby/base_character"
require "game/lobby/base_table"
require "table_func"
require "game/lobby/base_player"
require "game/lobby/base_android"
require "game/lobby/android_manager"
--require "game/ox/ox_table"
--require "game/ox/ox_room_manager"


-- 上庄机器人
local TYPE_ROBOT_BANKER = 1

-- 上庄机器人初始UID
local BANKER_ROBOT_INIT_UID = 1000000

-- 下注机器人初始UID
local BET_ROBOT_INIT_UID = 2000000

-- 机器人随机UID系数
local ROBOT_UID_COEFF = 100000

-- 下注机器人
local TYPE_ROBOT_BET = 2

-- 上庄机器人初始金币
local BANKER_ROBOT_START_MONEY = 10000000

-- 下注机器人初始金币
local BET_ROBOT_START_MONEY = 100000

-- 下注机器人初始金币的随机数值
local RAND_MONEY = 20000

-- 下注区域
local BET_AREA_TOTAL = 4




--[[if not ox_robot then
	ox_robot = base_character:new()
end--]]
ox_robot = {}

function ox_robot:new()  
    local o = {}  
    setmetatable(o, {__index = self})
	
    return o 
end

-- 机器人初始化
function ox_robot:init(guid_, account_, nickname_)
	-- base_character.init(self, guid_, account_, nickname_)
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	self.guid = guid_
	self.is_player = false
	self.nickname = nickname_
	self.chair_id = 0
	self.money = 0
	self.header_icon = -1
end


-- 先手动创建虚拟机器人,后再从数据库中读取
-- guid,nickname_,money,account,
-- 上庄机器人guid区间范围[10000~~20000],下注机器人guid区间范围[20000~~30000]
temp_number = 0
-- 创建机器人(游戏服调用创建)
function ox_robot:creat_robot(robot_type, robot_num, uid, money)
	if TYPE_ROBOT_BANKER == robot_type then --  创建上庄机器人
		local banker_robot = ox_robot:new()
		local robot_uid = uid + math.random(ROBOT_UID_COEFF)
		banker_robot:init(robot_uid, "test_banker_robot", "system_banker")
		--banker_robot.money = self:get_money(TYPE_ROBOT_BANKER)
		banker_robot.money = money
		return banker_robot
	elseif TYPE_ROBOT_BET == robot_type then --  创建下注机器人
		local tb_bet_robot = {}
		local robot_ret_uid = uid + math.random(ROBOT_UID_COEFF)
		for i=1,robot_num,1
		do
			local bet_robot = ox_robot:new()
			bet_robot:init(robot_ret_uid, "test_bet_robot", "bet_robot")
			--bet_robot.money = self:get_money(TYPE_ROBOT_BET)
			math.randomseed(os.time() + temp_number)
			local rand_num = math.random(RAND_MONEY)
			temp_number = temp_number + math.random(10)
			bet_robot.money = money + math.random(rand_num+1)
			table.insert(tb_bet_robot,bet_robot)
			robot_ret_uid = robot_ret_uid + 1
		end
		return tb_bet_robot
	else
		log_error("creat_robot error.")
		return	
	end	
	
	return
end

-- 获得金币
function ox_robot:get_money(robot_type)
	if TYPE_ROBOT_BANKER == robot_type then
		return BANKER_ROBOT_START_MONEY
	elseif TYPE_ROBOT_BET == robot_type then --todo++ 后续加上随机金币数 math.random(RAND_MONEY)
		return BET_ROBOT_START_MONEY + math.random(RAND_MONEY)
	else 
		log_error("get_money error.")
		return 0
	end
end

-- 加金币
function ox_robot:robot_add_money(robot,robot_earn_money)
	local old_money = robot.money
	
	if robot_earn_money <= 0 then
		return false
	end
	
	local new_money = old_money + robot_earn_money
	robot.money = new_money
	return true
end

-- 花金币
function ox_robot:robot_cost_money(robot,robot_earn_money)
	local old_money = robot.money
	
	if robot_earn_money <= 0 then
		return false
	end
	
	local new_money = old_money - robot_earn_money
	robot.money = new_money
	return true
end


-- 上庄机器人初始化条件(金币限制,上庄次数限制,guid,nickname,money等)
function ox_robot:banker_robot_init()
	
end

-- 下注机器人初始化条件(初始金币随机,下注总金额限制,总次数限制等)
function ox_robot:bet_robot_init()
	
end


-- 进入游戏房间(重点:如何进入房间桌子并新增到玩家列表中?)
function ox_robot:Enter_Game()
	
end

-- 下注机器人随机下注(区域随机,金额随机等)
function ox_robot:control_bet_robot()
	
end

