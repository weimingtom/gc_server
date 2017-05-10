-- 玩家和机器人基类
local pb = require "protobuf"

require "game/net_func"
local send2client_pb = send2client_pb

--require "game/lobby/base_room_manager"
local room_manager = g_room_manager

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
local GAME_SERVER_RESULT_ROOM_LIMIT = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_ROOM_LIMIT")


base_character = {}
-- 创建
function base_character:new()  
    local o = {}  
    setmetatable(o, {__index = self})
	
    return o 
end

-- 初始化
function base_character:init(guid_, account_, nickname_)  
    self.guid = guid_
    self.account = account_
    self.nickname = nickname_
end

-- 删除
function base_character:del()
end

-- 检查房间限制
function base_character:check_room_limit(score)
	return false
end

-- 进入房间并坐下
function base_character:on_enter_room_and_sit_down(room_id_, table_id_, chair_id_, result_, tb)
end

-- 站起并离开房间
function base_character:on_stand_up_and_exit_room(room_id_, table_id_, chair_id_, result_)
end

-- 切换座位
function base_character:on_change_chair(table_id_, chair_id_, result_, tb)
end

-- 进入房间
function base_character:on_enter_room(room_id_, result_)
end

-- 通知进入房间
function base_character:on_notify_enter_room(notify)
end

-- 离开房间
function base_character:on_exit_room(room_id_, result_)
end

-- 通知离开房间
function base_character:on_notify_exit_room(notify)
end

-- 坐下
function base_character:on_sit_down(table_id_, chair_id_, result_)
end

-- 通知坐下
function base_character:on_notify_sit_down(notify)
end
-- 站起
function base_character:on_stand_up()
end

-- 通知站起
function base_character:on_notify_stand_up(notify)
end

-- 通知空位置坐机器人
function base_character:on_notify_android_sit_down(room_id_, table_id_, chair_id_)
end



-- 检查强制踢出房间
function base_character:check_forced_exit(score)
	if self:check_room_limit(score) then
		self:forced_exit()
	end
end

-- 强制踢出房间
function base_character:forced_exit()
	local ret = 0
	if room_manager == nil then
		print("room_manager is nil")
		if g_room_manager == nil then
			print("g_room_manager is nil")
		else
			local ret = g_room_manager:stand_up(self)
			print("ret is :"..ret)
			if ret == GAME_SERVER_RESULT_SUCCESS then
			   g_room_manager:exit_room(self)
			end
		end
	else
		local ret = room_manager:stand_up(self)
		print("ret is :"..ret)
		if ret == GAME_SERVER_RESULT_SUCCESS then
		   room_manager:exit_room(self)
		end
	end
end

-- 得到等级
function base_character:get_level()
	return 1
end

-- 得到钱
function base_character:get_money()
	return 0
end

-- 得到头像
function base_character:get_header_icon()
	return 0
end

-- 花钱
function base_character:cost_money(price, opttype)
end

-- 加钱
function base_character:add_money(price, opttype)
end