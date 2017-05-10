-- 注册消息

local pb = require "protobuf"

pb.register_file("../pb/common_enum_define.proto")
pb.register_file("../pb/common_player_define.proto")
pb.register_file("../pb/common_msg_define.proto")
pb.register_file("../pb/verify_define.proto")
pb.register_file("../pb/redis_define.proto")
pb.register_file("../pb/config_define.proto")
pb.register_file("../pb/msg_server.proto")

require "db/msg/on_login_logout"
require "db/msg/on_bank"
require "db/msg/on_chat_mail"
require "db/msg/on_log"


local show_log = not (b_register_dispatcher_hide_log or false)
-- 处理服务器之间消息
function on_server_dispatcher(server_id, func, msgname, stringbuffer)
	local f = _G[func]
	assert(f, string.format("on_server_dispatcher func:%s", func))
	local msg = nil
	if stringbuffer ~= "" then
		msg = pb.decode(msgname, stringbuffer)
	end
	f(msg)
end
-- 处理game服务器发送来的消息
function on_gameserver_dispatcher(server_id, func, msgname, stringbuffer)
	local f = _G[func]
	assert(f, string.format("on_gameserver_dispatcher func:%s", func))
	local msg = nil
	if stringbuffer ~= "" then
		msg = pb.decode(msgname, stringbuffer)
	end
	f(server_id, msg)
end
-- 处理login服务器发送来的消息
function on_loginserver_dispatcher(server_id, func, msgname, stringbuffer)
	local f = _G[func]
	assert(f, string.format("on_loginserver_dispatcher func:%s", func))
	local msg = nil
	if stringbuffer ~= "" then
		msg = pb.decode(msgname, stringbuffer)
	end
	f(server_id, msg)
end

-- 注册处理Game消息的函数
local function register_game_dispatcher(msgname, func)
	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s, func:%s", msgname, func))
	reg_game_dispatcher(msgname, id, func, "on_gameserver_dispatcher", show_log)
end
-- 注册处理Login消息的函数
local function register_login_dispatcher(msgname, func)
	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s, func:%s", msgname, func))
	reg_login_dispatcher(msgname, id, func, "on_loginserver_dispatcher", show_log)
end
b_register_dispatcher_hide_log = true

	
--------------------------------------------------------------------
-- 注册Center发过来的消息分派函数
--register_center_dispatcher("S_Logout", "on_s_logout")
--register_center_dispatcher("SD_BankTransfer", "on_sd_bank_transfer")



--------------------------------------------------------------------
-- 注册Login发过来的消息分派函数
register_login_dispatcher("SD_BankTransfer", "on_sd_bank_transfer")
register_login_dispatcher("S_BankTransferByGuid", "on_s_bank_transfer_by_guid")

--------------------------------------------------------------------
-- 注册Game发过来的消息分派函数

register_game_dispatcher("SD_Delonline_player", "on_sd_delonline_player")
register_game_dispatcher("SD_OnlineAccount", "on_SD_OnlineAccount")
register_game_dispatcher("S_Logout", "on_s_logout")
register_game_dispatcher("SD_QueryPlayerMsgData","on_sd_query_player_msg")
register_game_dispatcher("SD_QueryPlayerMarquee","on_sd_query_player_marquee")
register_game_dispatcher("SD_SetMsgReadFlag","on_sd_Set_Msg_Read_Flag")
register_game_dispatcher("SD_QueryPlayerData", "on_sd_query_player_data")
register_game_dispatcher("SD_SavePlayerData", "on_sd_save_player_data")
register_game_dispatcher("SD_SavePlayerMoney", "on_SD_SavePlayerMoney")
register_game_dispatcher("SD_SavePlayerBank", "on_SD_SavePlayerBank")
register_game_dispatcher("SD_BankSetPassword", "on_sd_bank_set_password")
register_game_dispatcher("SD_BankChangePassword", "on_sd_bank_change_password")
register_game_dispatcher("SD_BankLogin", "on_sd_bank_login")
register_game_dispatcher("SD_BankTransfer", "on_sd_bank_transfer")
register_game_dispatcher("SD_SaveBankStatement", "on_sd_save_bank_statement")
register_game_dispatcher("SD_BankStatement", "on_sd_bank_statement")
register_game_dispatcher("SD_BankLog", "on_SD_BankLog")
register_game_dispatcher("SD_SendMail", "on_sd_send_mail")
register_game_dispatcher("SD_DelMail", "on_sd_del_mail")
register_game_dispatcher("SD_ReceiveMailAttachment", "on_sd_receive_mail_attachment")
register_game_dispatcher("SD_LogMoney", "on_sd_log_money")
register_game_dispatcher("SD_LoadAndroidData", "on_sd_load_android_data")
register_login_dispatcher("LD_NewNotice","on_ld_NewNotice")
register_login_dispatcher("LD_DelMessage","on_ld_DelMessage")
register_login_dispatcher("LD_AlipayEdit","on_ld_AlipayEdit")
register_game_dispatcher("SD_CashMoneyType", "on_sd_cash_money_type")
register_game_dispatcher("SD_CashMoney", "on_sd_cash_money")
register_game_dispatcher("SD_SavePlayerOxData", "on_sd_save_player_Ox_data")
register_game_dispatcher("SL_Log_Money","on_sl_log_money")
register_game_dispatcher("SD_QueryOxConfigData", "on_sd_query_Ox_config_data")
register_game_dispatcher("SL_Log_Game","on_sl_log_Game")
register_game_dispatcher("SL_Channel_Invite_Tax","on_sl_channel_invite_tax")
register_game_dispatcher("SD_QueryPlayerInviteReward","on_sd_query_player_invite_reward")
register_game_dispatcher("SD_QueryChannelInviteCfg","on_sd_query_channel_invite_cfg")
register_login_dispatcher("LD_AgentsTransfer_finish","on_ld_AgentTransfer_finish")
register_login_dispatcher("LD_CC_ChangeMoney","on_ld_cc_changemoney")
register_game_dispatcher("SL_Log_Robot_Money","on_sl_robot_log_money")
register_login_dispatcher("LD_DO_SQL","on_ld_do_sql")

