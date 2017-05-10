local pb = require "protobuf"
require "game/lobby/base_room_manager"
local room_manager = g_room_manager
require "game/lobby/base_player"
local base_player = base_player
local LOG_MONEY_OPT_TYPE_GM = pb.enum_id("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_GM")
local def_game_id = def_game_id

require "game/net_func"
local send2client_pb = send2client_pb
local send2db_pb = send2db_pb
local send2loginid_pb = send2loginid_pb

function gm_change_money(guid,money,log_type)
    local player = base_player:find(guid)
	if not player then
		log_warning(string.format("guid[%d] not find in game=%d", guid, def_game_id))
			return
	end
    player:change_money(money, log_type or LOG_MONEY_OPT_TYPE_GM)

	send2db_pb("SD_SavePlayerData", {
		guid = guid,
		pb_base_info = player.pb_base_info,		
	})
end

function gm_change_bank_money(guid,money,log_type)
    local player = base_player:find(guid)
	if not player then
		log_warning(string.format("guid[%d] not find in game=%d", guid, def_game_id))
		return
	end
    player:change_bank(money,log_type or LOG_MONEY_OPT_TYPE_GM)

	send2db_pb("SD_SavePlayerData", {
		guid = guid,
		pb_base_info = player.pb_base_info,
	})
end

function gm_change_bank(web_id_, login_id, guid, money, log_type)
	local player = base_player:find(guid)
	if not player then
		log_warning(string.format("guid[%d] not find in game=%d", guid, def_game_id))
		send2loginid_pb(login_id, "SL_LuaCmdPlayerResult", {
	    	web_id = web_id_,
	    	result = 0,
	    	})
		return
	end

	print ("web_id_, login_id, guid, money, log_type", web_id_, login_id, guid, money, log_type)
    player:change_bank(money, log_type or LOG_MONEY_OPT_TYPE_GM, true)

    send2loginid_pb(login_id, "SL_LuaCmdPlayerResult", {
    	web_id = web_id_,
    	result = 1,
    	})
end

function gm_broadcast_client(json_str)
	print("gm_broadcast_client comming......")
	local msg = {
		update_info = json_str
	}
	base_player:broadcast2client_pb("SC_BrocastClientUpdateInfo", msg)
	print "gm_broadcast_client ok..................."
end

function gm_set_slotma_rate(guid,count)
    local player = base_player:find(guid)
	if not player then
		log_warning(string.format("guid[%d] not find in game=%d", guid, def_game_id))
		return
	end
    
	print ("old random_count-> is :",player.pb_base_info.slotma_addition)
	player.pb_base_info.slotma_addition = count
	print ("random_count-> is :",player.pb_base_info.slotma_addition)
	player.flag_base_info = true


	send2db_pb("SD_SavePlayerData", {
		guid = guid,
		pb_base_info = player.pb_base_info,
	})
end




