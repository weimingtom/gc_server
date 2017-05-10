-- 斗地主消息处理

local pb = require "protobuf"

require "game/net_func"
local send2client_pb = send2client_pb

require "game/lobby/base_player"
local base_player = base_player

local room_manager = g_room_manager


-- 用户叫分
function on_cs_land_call_score(player, msg)
	if player then
		if player.chair_id then
			print ("test .................. on_cs_land_call_score:"..player.chair_id)
		else
			print ("test .................. player.chair_id nil")
		end
	else
		print ("test .................. player nil")
	end

	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:call_score(player, msg.call_score - 1)
	else
		log_error(string.format("guid[%d] stand up", player.guid))
	end
end

-- 用户加倍
function on_cs_land_call_double(player, msg)
	local tb = room_manager:find_table_by_player(player)
	print("on_cs_land_call_double ----",tostring(player),tostring(tb),tostring(msg))
	print(tostring(msg.is_double))
	if tb then
		tb:call_double(player, msg.is_double == 2)
	else
		log_error(string.format("guid[%d] call double", player.guid))
	end
end

-- 出牌
function on_cs_land_out_card(player, msg)
	if player and player.chair_id then
		print ("test .................. on_cs_land_out_card:"..player.chair_id)
	end
	local tb = room_manager:find_table_by_player(player)
	if tb then
		newCards = {}
		print("=========================1")
		print(string.format("on_cs_land_out_card card_count[%d],cards[%s]",#msg.cards , table.concat(msg.cards, ", ")))
		if msg ~= nil then
			local i = 0
			for _,card in ipairs(msg.cards) do
				table.insert(newCards, card - 1)
			end
		end		
		print(string.format("on_cs_land_out_card newCards_count[%d],newCards[%s]",#newCards , table.concat(newCards, ", ")))
		tb:out_card(player, newCards)
		print("=========================2")
	else
		log_error(string.format("guid[%d] stand up", player.guid))
	end
end

-- 放弃出牌
function on_cs_land_pass_card(player, msg)
	print ("test .................. on_cs_land_pass_card")

	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:pass_card(player)
	else
		log_error(string.format("guid[%d] stand up", player.guid))
	end
end

function  on_cs_LandTrusteeship(  player, msg )
	-- body
	print("=============on_cs_LandTrusteeship================")
	local tb = room_manager:find_table_by_player(player)
	if tb then
		tb:setTrusteeship(player,false)
	else
		log_error(string.format("guid[%d] LandTrusteeship", player.guid))
	end
end