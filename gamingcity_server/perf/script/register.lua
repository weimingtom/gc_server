-- 注册消息

local pb = require "protobuf"

pb.register_file("../../project/pb/common_enum_define.proto")
pb.register_file("../../project/pb/common_player_define.proto")
pb.register_file("../../project/pb/common_msg_define.proto")
pb.register_file("../../project/pb/common_msg_demo.proto")

require "player"
require "player_manager"

local client_account_password = client_account_password
g_player_manager = player_manager:new()
local player_manager_ = g_player_manager


local show_log = not (b_register_dispatcher_hide_log or false)
-- 处理服务器消息
function on_server_dispatcher(client_id, func, msgname, stringbuffer)
	local player = player_manager_:find_player_by_id(client_id)
	if not player then
		local acc_pwd = client_account_password[client_id+1]
		player = player_manager_:create_player(client_id, acc_pwd.account, acc_pwd.password)
	end
	
	local f = _G[func]
	assert(f, string.format("on_server_dispatcher func:%s", func))
	local msg = nil
	if stringbuffer ~= "" then
		msg = pb.decode(msgname, stringbuffer)
	end
	f(player, msg)
end
-- 注册处理服务器消息的函数
local function register_perf_dispatcher(msgname, func)
	local id = pb.enum_id(msgname .. ".MsgID", "ID")
	assert(id, string.format("msg:%s, func:%s", msgname, func))
	reg_perf_dispatcher(msgname, id, func, "on_server_dispatcher", show_log)
end
b_register_dispatcher_hide_log = true

	
--------------------------------------------------------------------
-- 注册服务器发过来的消息分派函数
register_perf_dispatcher("GC_GameServerCfg", "on_GC_GameServerCfg")
register_perf_dispatcher("C_PublicKey", "on_C_PublicKey")
register_perf_dispatcher("LC_Login", "on_LC_Login")
register_perf_dispatcher("SC_ReplyPlayerInfo", "on_SC_ReplyPlayerInfo")
register_perf_dispatcher("SC_ReplyPlayerInfoComplete", "on_SC_ReplyPlayerInfoComplete")
register_perf_dispatcher("SC_HEARTBEAT", "on_SC_HEARTBEAT")
register_perf_dispatcher("SC_QueryPlayerMarquee", "on_SC_QueryPlayerMarquee")
register_perf_dispatcher("SC_NewMarquee", "on_SC_NewMarquee")
register_perf_dispatcher("SC_QueryPlayerMsgData", "on_SC_QueryPlayerMsgData")
register_perf_dispatcher("SC_NewMsgData", "on_SC_NewMsgData")
