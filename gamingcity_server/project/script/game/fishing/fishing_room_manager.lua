-- 捕鱼房间
local pb = require "protobuf"
require "game/lobby/base_room_manager"

require "game/fishing/on_fishing"

-- enum GAME_SERVER_RESULT
local GAME_SERVER_RESULT_SUCCESS = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")


fishing_room_manager = base_room_manager:new()  

-- 初始化房间
function fishing_room_manager:init(tb, chair_count, ready_mode)

	print("1111111111111111111111111111BBBBBBBBBBBBBBBBBBBBBBBBBBB")
	base_room_manager.init(self, tb, chair_count, ready_mode)

	ServerInit = {}
	ServerInit.TableNum = 100--tb.table_count
	print("1111111111111111111111111111CCCCCCCCCCCCCCCCCCCCCC")
	print(ServerInit.TableNum )
	CallFishFun.CFishingInit()	
	print("1111111111111111111111111111DDDDDDDDDDDDDDDDDDDDDDDDD")
end

-- 加入
function fishing_room_manager:fishing_add_player(player)
	local tb = self:find_table_by_player(player)
	if not tb then
		log_error(string.format("guid[%d] not find in room", player.guid))
		return
	end

	--if not tb.userdata then
		--tb.userdata = CTableFrameSink()
		--初始化
		--tb.userdata:Initialization()
		--开始游戏
		--tb.userdata:OnEventGameStart()
	--end
	
	tabEventGameStart = {}
	tabActionUserStandUp.TableID = player.table_id_
    CallFishFun.EventGameStart()

	local chair_id = player.chair_id - 1
	--添加玩家到桌子
	--add_player_table(chair_id, player.guid, player.gate_id, tb.userdata)
	--玩家坐下
	tabActionUserStandUp = {}
	tabActionUserStandUp.TableID = player.table_id_
	tabActionUserStandUp.GuID = player.guid
	tabActionUserStandUp.wChairID = chair_id
	tabActionUserStandUp.bRet = true
    CallFishFun.ActionUserStandUp()
	--tb.userdata:OnActionUserSitDown(chair_id, true)
	--设置昵称
	tabNickName = {}
	tabNickName.TableID = player.table_id_
	tabNickName.nickname = player.nickname
	tabNickName.money = player:get_money()
	tabNickName.wChairID = chair_id
	CallFishFun.SetNickNameAndMoney()
	--tb.userdata:set_nickname(chair_id, player.nickname)
	--发送场景	
	tabEventSendGameScene = {}
	tabEventSendGameScene.TableID = player.table_id_
	tabEventSendGameScene.wChairID = chair_id
	tabEventSendGameScene.cbReason = 100
	tabEventSendGameScene.bRet = false
	CallFishFun.EventSendGameScene()
	--tb.userdata:OnEventSendGameScene(chair_id, 100, false)
end

-- 快速坐下
function fishing_room_manager:auto_sit_down(player)
	print "test fishing auto sit down ....................."

	local result_, table_id_, chair_id_ = base_room_manager.auto_sit_down(self, player)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:fishing_add_player(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end

-- 坐下
function fishing_room_manager:sit_down(player, table_id_, chair_id_)
	print "test fishing sit down ....................."

	local result_, table_id_, chair_id_ = base_room_manager.sit_down(self, player, table_id_, chair_id_)
	
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:fishing_add_player(player)
		return result_, table_id_, chair_id_
	end
	
	return result_
end

-- 站起
function fishing_room_manager:stand_up(player)
	
	print "test fishing stand up ....................."

	local tb = self:find_table_by_player(player)
	local chair_id = player.chair_id - 1
	local result_, table_id_, chair_id_ = base_room_manager.stand_up(self, player)
	if result_ ~= GAME_SERVER_RESULT_SUCCESS then
		return result_
	end




	tabActionUserStandUp = {}
	tabActionUserStandUp.TableID = player.table_id_
	tabActionUserStandUp.wChairID = chair_id
	tabActionUserStandUp.GuID = player.guid
	tabActionUserStandUp.bRet = true
	CallFishFun.OnActionUserStandUp()



	tabEventGameConclude = {}
	tabEventGameConclude.TableID = player.table_id_
	tabEventGameConclude.wChairID = chair_id

	tabEventGameConclude.cbReason = 2
	CallFishFun.EventGameConclude()

	
	return result_, table_id_, chair_id_
end


