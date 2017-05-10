-- 注册消息

local pb = require "protobuf"

pb.register_file("../pb/common_enum_define.proto")
pb.register_file("../pb/common_player_define.proto")
pb.register_file("../pb/common_msg_define.proto")
pb.register_file("../pb/verify_define.proto")
pb.register_file("../pb/redis_define.proto")
pb.register_file("../pb/config_define.proto")
pb.register_file("../pb/msg_server.proto")


-- enum GAME_READY_MODE
local GAME_READY_MODE_NONE = pb.enum_id("GAME_READY_MODE", "GAME_READY_MODE_NONE")
local GAME_READY_MODE_ALL = pb.enum_id("GAME_READY_MODE", "GAME_READY_MODE_ALL")
local GAME_READY_MODE_PART = pb.enum_id("GAME_READY_MODE", "GAME_READY_MODE_PART")

local def_game_id = def_game_id

require "table_func"

function query_many_ox_config_data()
	send2db_pb("SD_QueryOxConfigData", {
		cur_time = get_second_time(),
	})
end

-- 第一次连接db服务?
function on_first_connect_db()
	if def_game_name == "ox" then
		--query_many_ox_config_data()
	end
	send2db_pb("SD_QueryChannelInviteCfg", {})
end

local function get_game_cfg()
	local json = get_gameserver_config()
	if json then
		return load_json_buffer(json)
	end

	error(string.format("get_game_cfg failed,game id = %d", def_game_id))
end
local game_cfg_ = get_game_cfg()

local function get_game_lua_cfg()
	local json = get_gameserver_room_lua_cfg()
	--[[if json then
		if json == "" then
			return nil
		else
			return parse_table(json)
		end
	end--]]
	return json;
	--error(string.format("get_game_lua_cfg failed,game id = %d", def_game_id))
end
local game_lua_cfg_ = get_game_lua_cfg()

local tb_game_obj = {
	lobby = function ()
		require "game/lobby/base_room_manager"
		local mgr = base_room_manager:new()
		mgr:init(game_cfg_, 2, GAME_READY_MODE_NONE, game_lua_cfg_)
		return mgr
	end,
	
	fishing = function ()
		require "game/fishing/fishing_room_manager"
		local mgr = fishing_room_manager:new()
		mgr:init(game_cfg_, 2, GAME_READY_MODE_NONE, game_lua_cfg_)
		return mgr
	end,
	
	demo = function ()
		require "game/demo/demo_room_manager"
		local mgr = demo_room_manager:new()
		mgr:init(game_cfg_, 2, GAME_READY_MODE_NONE, game_lua_cfg_)
		return mgr
	end,

	shuihu_zhuan = function ()
		local game_rooms = require("game/shuihu_zhuan/game_rooms")
		local mgr = game_rooms:new()
		mgr:init(game_cfg_, 1, GAME_READY_MODE_NONE, game_lua_cfg_)
		local manager = require("game/shuihu_zhuan/game_manager")
		manager.init(1, 300, 1)
		return mgr
	end,
	
	land = function ()
		pb.register_file("../pb/common_msg_land.proto")
		require "game/land/land_room_manager"
		local mgr = land_room_manager:new()
		mgr:init(game_cfg_, 3, GAME_READY_MODE_ALL, game_lua_cfg_)
		return mgr
	end,

	zhajinhua = function ()
		pb.register_file("../pb/common_msg_zhajinhua.proto")
		require "game/zhajinhua/zhajinhua_room_manager"
		local mgr = zhajinhua_room_manager:new()
		mgr:init(game_cfg_, 5, GAME_READY_MODE_PART, game_lua_cfg_)
		return mgr
	end,

	showhand = function ()
		pb.register_file("../pb/common_msg_showhand.proto")
		require "game/showhand/showhand_room_manager"
		local mgr = showhand_room_manager:new()
		mgr:init(game_cfg_, 5, GAME_READY_MODE_PART, game_lua_cfg_)
		return mgr
	end,

	ox = function ()
		pb.register_file("../pb/common_msg_ox.proto")
		require "game/ox/ox_room_manager"
		local mgr = ox_room_manager:new()
		mgr:init(game_cfg_, 2000, GAME_READY_MODE_ALL, game_lua_cfg_)
		return mgr
	end,
	
	texas = function ()
		pb.register_file("../pb/common_msg_texas.proto")
		require "game/texas/texas_room_manager"
		local mgr = texas_room_manager:new()
		mgr:init(game_cfg_, 7, GAME_READY_MODE_ALL, game_lua_cfg_)
		return mgr
	end,

	slotma = function ()
		pb.register_file("../pb/common_msg_slotma.proto")
		require "game/slotma/slotma_room_manager"
		local mgr = slotma_room_manager:new()
		mgr:init(game_cfg_, 2000, GAME_READY_MODE_ALL, game_lua_cfg_)
		return mgr
	end,

	maajan = function ()
		pb.register_file("../pb/common_msg_maajan.proto")
		require "game/maajan/maajan_room_manager"
		local mgr = maajan_room_manager:new()
		mgr:init(game_cfg_, 2, GAME_READY_MODE_ALL, game_lua_cfg_)
		return mgr
	end,
}
if not g_room_manager then
	g_room_manager = tb_game_obj[def_game_name]()
end

function on_gm_update_cfg()
	local tb = get_game_cfg()
	g_room_manager:gm_update_cfg(tb)
end

function g_get_game_cfg()
    return get_game_cfg()
end

require "game/lobby/base_player"
local base_player = base_player


require "game/lobby/on_login_logout"
require "game/lobby/on_bank"
require "game/lobby/on_item"
require "game/lobby/on_award"
require "game/lobby/on_room"
require "game/lobby/on_chat"
require "game/lobby/on_mail"
require "game/lobby/on_recharge_cash"


local show_log = not (b_register_dispatcher_hide_log or false)
-- 处理服务器之间消?
function on_server_dispatcher(server_id, func, msgname, stringbuffer)
	local f = _G[func]
	assert(f, string.format("on_server_dispatcher func:%s", func))
	local msg = nil
	if stringbuffer ~= "" then
		msg = pb.decode(msgname, stringbuffer)
	end
	f(msg)
end
-- 处理客户端消?
function on_client_dispatcher(guid, func, msgname, stringbuffer)
	local player = base_player:find(guid)
	if not player then
		log_warning(string.format("guid[%d] not find in game=%d msg[%s]", guid, def_game_id, msgname))
		return
	end
	local f = _G[func]
	assert(f, string.format("on_client_dispatcher func:%s", func))
	local msg = nil
	if stringbuffer ~= "" then
		msg = pb.decode(msgname, stringbuffer)
	end
	f(player, msg)
end
-- 注册处理DB消息的函?
function register_db_dispatcher(msgname, func)
	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s, func:%s", msgname, func))
	reg_db_dispatcher(msgname, id, func, "on_server_dispatcher", show_log)
end
local register_db_dispatcher = register_db_dispatcher
-- 注册处理Login消息的函?
function register_login_dispatcher(msgname, func)
	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s, func:%s", msgname, func))
	reg_login_dispatcher(msgname, id, func, "on_server_dispatcher", show_log)
end
local register_login_dispatcher = register_login_dispatcher
-- 注册处理客户端消息的函数
function register_client_dispatcher(msgname, func)
	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s, func:%s", msgname, func))
	reg_gate_dispatcher(msgname, id, func, "on_client_dispatcher", show_log)
end
-- 注册CFG消息
function register_cfg_dispatcher(msgname, func)
	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s, func:%s", msgname, func))
	reg_cfg_dispatcher(msgname, id, func, "on_server_dispatcher", show_log)
end
-- 注册gate消息
function register_gate_dispatcher(msgname, func)
	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s, func:%s", msgname, func))
	reg_gate_server_dispatcher(msgname, id, func, "on_server_dispatcher", show_log)
end
local register_client_dispatcher = register_client_dispatcher
b_register_dispatcher_hide_log = true

	
--------------------------------------------------------------------
-- 注册Center发过来的消息分派函数
--register_center_dispatcher("DES_SendMail", "on_des_send_mail_from_center")


--------------------------------------------------------------------

-- 注册cfg发过来的消息分派函数
register_cfg_dispatcher("FS_ChangeGameCfg", "on_fs_chang_config")
register_cfg_dispatcher("CS_QueryMaintain", "on_cs_change_maintain")
-- 注册DB发过来的消息分派函数
register_db_dispatcher("DS_LoadPlayerData", "on_ds_load_player_data")
register_db_dispatcher("DS_ResetAccount", "on_ds_reset_account")
register_db_dispatcher("DS_SetPassword", "on_ds_set_password")
register_db_dispatcher("DS_SetNickname", "on_ds_set_nickname")
register_db_dispatcher("DS_BankChangePassword", "on_ds_bank_change_password")
register_db_dispatcher("DS_BankLogin", "on_ds_bank_login")
register_db_dispatcher("DS_BankTransfer", "on_ds_bank_transfer")
register_db_dispatcher("DS_BankTransferByGuid", "on_ds_bank_transfer_by_guid")
register_db_dispatcher("DS_SaveBankStatement", "on_ds_save_bank_statement")
register_db_dispatcher("DS_BankStatement", "on_ds_bank_statement")
register_db_dispatcher("DES_SendMail", "on_des_send_mail")
register_db_dispatcher("DS_LoadAndroidData", "on_ds_load_android_data")
register_db_dispatcher("DS_QueryPlayerMsgData", "on_ds_QueryPlayerMsgData")
register_db_dispatcher("DS_QueryPlayerMarquee", "on_ds_QueryPlayerMarquee")
register_db_dispatcher("DS_CashMoneyType", "on_ds_cash_money_type")
register_db_dispatcher("DS_CashMoney", "on_ds_cash_money")
register_db_dispatcher("DS_BandAlipay", "on_ds_bandalipay")
register_db_dispatcher("DS_BandAlipayNum", "on_ds_bandalipaynum")
--register_db_dispatcher("DS_OxConfigData", "on_ds_LoadOxConfigData")
register_db_dispatcher("DS_ServerConfig", "on_ds_server_config")
register_db_dispatcher("DS_QueryPlayerInviteReward", "on_ds_load_player_invite_reward")
register_db_dispatcher("DS_QueryChannelInviteCfg", "on_ds_load_channel_invite_cfg")





--------------------------------------------------------------------
-- 注册Login发过来的消息分派函数
register_login_dispatcher("LS_LoginNotify", "on_ls_login_notify")
register_login_dispatcher("S_Logout", "on_s_logout")
register_login_dispatcher("SS_ChangeGame", "on_ss_change_game")
register_login_dispatcher("LS_ChangeGameResult", "on_LS_ChangeGameResult")
register_login_dispatcher("LS_BankTransferSelf", "on_ls_bank_transfer_self")
register_login_dispatcher("LS_BankTransferTarget", "on_ls_bank_transfer_target")
register_login_dispatcher("LS_BankTransferByGuid", "on_ls_bank_transfer_by_guid")
register_login_dispatcher("LS_LoginNotifyAgain", "on_ls_login_notify_again")
register_login_dispatcher("LS_NewNotice", "on_new_nitice")
register_login_dispatcher("LS_DelMessage", "on_ls_DelMessage")
register_login_dispatcher("LS_CashDeal", "on_cash_false_deal")
register_login_dispatcher("LS_ChangeTax", "on_ls_set_tax")
register_login_dispatcher("LS_AlipayEdit","on_ls_AlipayEdit")
register_login_dispatcher("LS_CC_ChangeMoney", "on_ls_cc_changemoney")
register_login_dispatcher("LS_FreezeAccount", "on_ls_FreezeAccount")
register_login_dispatcher("LS_AddMoney", "on_ls_addmoney")

--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函?
register_client_dispatcher("CS_RequestPlayerInfo", "on_cs_request_player_info")
register_client_dispatcher("CS_LoginValidatebox", "on_cs_login_validatebox")
register_client_dispatcher("CS_ChangeGame", "on_cs_change_game")
register_client_dispatcher("CS_ResetAccount", "on_cs_reset_account")
register_client_dispatcher("CS_SetPassword", "on_cs_set_password")
register_client_dispatcher("CS_SetPasswordBySms", "on_cs_set_password_by_sms")
register_client_dispatcher("CS_SetNickname", "on_cs_set_nickname")
register_client_dispatcher("CS_ChangeHeaderIcon", "on_cs_change_header_icon")
register_client_dispatcher("CS_BankSetPassword", "on_cs_bank_set_password")
register_client_dispatcher("CS_BankChangePassword", "on_cs_bank_change_password")
register_client_dispatcher("CS_BankLogin", "on_cs_bank_login")
register_client_dispatcher("CS_BankDeposit", "on_cs_bank_deposit")
register_client_dispatcher("CS_BankDraw", "on_cs_bank_draw")
register_client_dispatcher("CS_BankTransfer", "on_cs_bank_transfer")
register_client_dispatcher("CS_BankTransferByGuid", "on_cs_bank_transfer_by_guid")
register_client_dispatcher("CS_BankStatement", "on_cs_bank_statement")
register_client_dispatcher("CS_BuyItem", "on_cs_buy_item")
register_client_dispatcher("CS_DelItem", "on_cs_del_item")
register_client_dispatcher("CS_UseItem", "on_cs_use_item")
register_client_dispatcher("CS_SendMail", "on_cs_send_mail")
register_client_dispatcher("CS_DelMail", "on_cs_del_mail")
register_client_dispatcher("CS_ReceiveMailAttachment", "on_cs_receive_mail_attachment")
register_client_dispatcher("CS_ReceiveRewardLogin", "on_cs_receive_reward_login")
register_client_dispatcher("CS_ReceiveRewardOnline", "on_cs_receive_reward_online")
register_client_dispatcher("CS_ReceiveReliefPayment", "on_cs_receive_relief_payment")
register_client_dispatcher("CS_EnterRoom", "on_cs_enter_room")
register_client_dispatcher("CS_AutoEnterRoom", "on_cs_auto_enter_room")
register_client_dispatcher("CS_AutoSitDown", "on_cs_auto_sit_down")
register_client_dispatcher("CS_SitDown", "on_cs_sit_down")
register_client_dispatcher("CS_StandUp", "on_cs_stand_up")
register_client_dispatcher("CS_EnterRoomAndSitDown", "on_cs_enter_room_and_sit_down")
register_client_dispatcher("CS_StandUpAndExitRoom", "on_cs_stand_up_and_exit_room")
register_client_dispatcher("CS_ChangeChair", "on_cs_change_chair")
register_client_dispatcher("CS_Ready", "on_cs_ready")
register_client_dispatcher("CS_ChatWorld", "on_cs_chat_world")
register_client_dispatcher("CS_ChatPrivate", "on_cs_chat_private")
register_client_dispatcher("SC_ChatPrivate", "on_sc_chat_private")
register_client_dispatcher("CS_ChatServer", "on_cs_chat_server")
register_client_dispatcher("CS_ChatRoom", "on_cs_chat_room")
register_client_dispatcher("CS_ChatTable", "on_cs_chat_table")
register_client_dispatcher("CS_ChangeTable", "on_cs_change_table")
register_client_dispatcher("CS_Exit", "on_cs_exit")
register_client_dispatcher("CS_ReconnectionPlay","on_cs_ReconnectionPlayMsg")
register_client_dispatcher("CS_QueryPlayerMsgData","on_cs_QueryPlayerMsgData")
register_client_dispatcher("CS_QueryPlayerMarquee","on_cs_QueryPlayerMarquee")
register_client_dispatcher("CS_SetMsgReadFlag","on_cs_SetMsgReadFlag")
register_client_dispatcher("CS_CashMoney","on_cs_cash_money")
register_client_dispatcher("CS_CashMoneyType","on_cs_cash_money_type")
register_client_dispatcher("CS_BandAlipay","on_cs_bandalipay")
register_client_dispatcher("CS_Trusteeship","on_cs_Trusteeship")

register_gate_dispatcher("FS_ChangMoneyDeal", "on_changmoney_deal")



local tb_reg_msg_dispatcher = {
	demo = function ()
		require "game/demo/register"
	end,
	shuihu_zhuan = function()
		require "game/shuihu_zhuan/register"
	end,
	land = function ()
		require "game/land/register"
	end,
	zhajinhua = function ()
		require "game/zhajinhua/register"
	end,
	showhand = function ()
		require "game/showhand/register"
	end,
	ox = function ()
		require "game/ox/register"
	end,
	
	texas = function ()
		require "game/texas/register"
	end,

	slotma = function ()
		require "game/slotma/register"
	end,

	maajan = function ()
		require "game/maajan/register"
	end,
}
local f = tb_reg_msg_dispatcher[def_game_name]
if f then
	f()
end

