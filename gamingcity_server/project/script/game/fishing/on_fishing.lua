-- 诈金花消息处理

local pb = require "protobuf"

local pb = require "protobuf"
require "game/net_func"
local send2client_pb = send2client_pb

require "game/lobby/base_player"
local base_player = base_player

local room_manager = g_room_manager


require "game/lobby/base_player"
local base_player = base_player

--package.cpath = 'E:/testold/server/project/Debug/?.dll;'
require "GameFishingDLL" 

function StopFishServer()
	CallFishFun.Stop()
end

-- 发送客户端消息
function on_Send2_pb(guid, msgname, msg)
	local player = base_player:find(guid)	
	if not player then
		log_warning(string.format("guid[%d] not find in game", guid))
		return
	end
	send2client_pb(player, msgname, msg)
end

-- 群发用户消息
function on_broadcast2client_pb(guid, msgname, msg)
	local player = base_player:find(guid)	
	if not player then
		log_warning(string.format("guid[%d] not find in game", guid))
		return
	end
	tb = room_manager:find_table_by_player(player)
	tb:broadcast2client(msgname, msg)
end

-- 回存
function on_Send2lua_pb(guid, msgname, msg)
	local player = base_player:find(guid)	
	if not player then
		log_warning(string.format("guid[%d] not find in game", guid))
		return
	end
	player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = msg.money}}, LOG_MONEY_OPT_TYPE_BUYU)
	if(msg.bout) then
		logout(guid, true)
	end
end


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
-- 打开宝箱
function on_cs_fishing_treasureend(player, msg)
	print ("test .................. on_cs_fishing_treasureend")

	local tb = room_manager:find_table_by_player(player)
	if tb then
		tabTreasireEnd = msg
		tabTreasireEnd.GuID = player.guid
		CallFishFun.CSTreasureEnd()
	else
		log_error(string.format("guid[%d] treasureend", player.guid))
	end
end

-- 改变大炮集
function on_cs_fishing_changecannonset(player, msg)
	print ("test .................. on_cs_fishing_changecannonset")
	
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tabChangeCannonSet = msg
		tabChangeCannonSet.GuID = player.guid
		CallFishFun.CSChangeCannonSet()
	else
		log_error(string.format("guid[%d] changecannonset", player.guid))
	end
end

-- 网鱼
function on_cs_fishing_netcast(player, msg)
	print ("test .................. on_cs_fishing_netcast")

	local tb = room_manager:find_table_by_player(player)
	if tb then
		tabNetcast = msg
		tabNetcast.GuID = player.guid
		CallFishFun.CSNetcast()
	else
		log_error(string.format("guid[%d] netcast", player.guid))
	end
end

-- 锁定鱼
function on_cs_fishing_lockfish(player, msg)
	print ("test .................. on_cs_fishing_lockfish")
	
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tabLockFish = msg
		tabLockFish.GuID = player.guid
		CallFishFun.CSLockFish()
	else
		log_error(string.format("guid[%d] lockfish", player.guid))
	end
end

-- 开火
function on_cs_fishing_fire(player, msg)
	print ("test .................. on_cs_fishing_fire")
	
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tabFire = msg
		tabFire.GuID = player.guid
		CallFishFun.CSFire()
	else
		log_error(string.format("guid[%d] fire", player.guid))
	end
end

-- 变换大炮
function on_cs_fishing_changecannon(player, msg)
	print ("test .................. on_cs_fishing_changecannon")
	
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tabChangeCannon = msg
		tabChangeCannon.GuID = player.guid
		CallFishFun.CSChangeCannon()
	else
		log_error(string.format("guid[%d] changecannon", player.guid))
	end
end

-- 获取系统时间
function on_cs_fishing_timesync(player, msg)
	print ("test .................. on_cs_fishing_timesync")
	
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tabTimeSync = msg
		tabTimeSync.GuID = player.guid
		CallFishFun.CSTimeSync()
	else
		log_error(string.format("guid[%d] timesync", player.guid))
	end
end
