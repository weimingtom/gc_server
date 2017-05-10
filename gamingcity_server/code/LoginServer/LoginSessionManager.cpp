#include "LoginSessionManager.h"
#include "LoginSession.h"
#include "LoginDBSession.h"
#include "LoginServer.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG

#define REG_GATE_DISPATCHER(Msg, Function) dispatcher_manager_gate_.register_dispatcher(new GateMsgDispatcher< Msg, LoginSession >(&LoginSession::Function));
#define REG_GAME_DISPATCHER(Msg, Function) dispatcher_manager_game_.register_dispatcher(new MsgDispatcher< Msg, LoginSession >(&LoginSession::Function));
#define REG_DB_DISPATCHER(Msg, Function) dispatcher_manager_db_.register_dispatcher(new MsgDispatcher< Msg, LoginDBSession >(&LoginDBSession::Function));
#define REG_WEB_DISPATCHER(Msg, Function) dispatcher_manager_web_.register_dispatcher(new MsgDispatcher< Msg, LoginSession >(&LoginSession::Function));

LoginSessionManager::LoginSessionManager()
	: cur_db_session_(0)
	, first_connect_db_(0)
{
	register_connect_message();
	register_gate2login_message();
	register_login2db_message();
	register_game2login_message();
	register_web2login_message();
	register_login2sms_message();
}

LoginSessionManager::~LoginSessionManager()
{
}

void LoginSessionManager::register_connect_message()
{
	dispatcher_manager_.register_dispatcher(new MsgDispatcher<S_Connect, LoginSession>(&LoginSession::on_s_connect));
}

void LoginSessionManager::register_gate2login_message()
{
	dispatcher_manager_gate_.register_dispatcher(new MsgDispatcher< S_Logout, LoginSession >(&LoginSession::on_s_logout));
	dispatcher_manager_gate_.register_dispatcher(new MsgDispatcher< L_KickClient, LoginSession >(&LoginSession::on_L_KickClient));
    dispatcher_manager_gate_.register_dispatcher(new MsgDispatcher< GL_NewNotice, LoginSession >(&LoginSession::on_gl_NewNotice));
	dispatcher_manager_gate_.register_dispatcher(new MsgDispatcher< CS_RequestSms, LoginSession >(&LoginSession::on_cs_request_sms));
	REG_GATE_DISPATCHER(CL_Login, on_cl_login);
	REG_GATE_DISPATCHER(CL_RegAccount, on_cl_reg_account);
	REG_GATE_DISPATCHER(CL_LoginBySms, on_cl_login_by_sms);
    REG_GATE_DISPATCHER(CS_ChatWorld, on_cs_chat_world);
    REG_GATE_DISPATCHER(GL_GetServerCfg, on_gl_get_server_cfg);
	REG_GATE_DISPATCHER(CL_GetInviterInfo, on_cl_get_server_cfg);
}

void LoginSessionManager::register_game2login_message()
{
	REG_GAME_DISPATCHER(L_KickClient, on_L_KickClient);
	REG_GAME_DISPATCHER(S_UpdateGamePlayerCount, on_S_UpdateGamePlayerCount);
	REG_GAME_DISPATCHER(SS_ChangeGame, on_ss_change_game);
	REG_GAME_DISPATCHER(SL_ChangeGameResult, on_SL_ChangeGameResult);
	REG_GAME_DISPATCHER(SD_BankTransfer, on_sd_bank_transfer);
	REG_GAME_DISPATCHER(S_BankTransferByGuid, on_sd_bank_transfer_by_guid);
	REG_GAME_DISPATCHER(SC_ChatPrivate, on_sc_chat_private);
	REG_GAME_DISPATCHER(SL_WebGameServerInfo, on_sl_web_game_server_info);
    REG_GAME_DISPATCHER(SL_CashReply, on_sl_cash_false_reply);
	REG_GAME_DISPATCHER(SL_ChangeTax, on_sl_change_tax_reply);
	REG_GAME_DISPATCHER(SL_LuaCmdPlayerResult, on_SL_LuaCmdPlayerResult);
	REG_GAME_DISPATCHER(SL_CC_ChangeMoney, on_SL_AT_ChangeMoney);
    REG_GAME_DISPATCHER(SL_FreezeAccount, on_sl_FreezeAccount);
    REG_GAME_DISPATCHER(SL_AddMoney, on_SL_AddMoney);
}

void LoginSessionManager::register_login2db_message()
{
	REG_DB_DISPATCHER(DL_VerifyAccountResult, on_dl_verify_account_result);
	REG_DB_DISPATCHER(DL_RegAccount, on_dl_reg_account);
	REG_DB_DISPATCHER(DL_RegAccount2, on_dl_reg_account2);
    REG_DB_DISPATCHER(DL_NewNotice, on_dl_NewNotice);
    REG_DB_DISPATCHER(DL_DelMessage, on_dl_DelMessage);
    REG_DB_DISPATCHER(DL_CashFalseInfo, on_dl_cashfalseinfo);
    REG_DB_DISPATCHER(DL_CashReply, on_dl_cashreply);
    REG_DB_DISPATCHER(DL_PhoneQuery, on_dl_reg_phone_query);
    REG_DB_DISPATCHER(DL_ServerConfig, on_dl_server_config);
    REG_DB_DISPATCHER(DL_DBGameConfigMgr, on_dl_server_config_mgr);
	REG_DB_DISPATCHER(LC_GetInviterInfo, on_dl_get_inviter_info);
	REG_DB_DISPATCHER(DL_LuaCmdPlayerResult, on_DL_LuaCmdPlayerResult);
	REG_DB_DISPATCHER(DL_CC_ChangeMoney, on_cc_ChangMoney);
	REG_DB_DISPATCHER(DL_DO_SQL, on_dl_doSql);
	REG_DB_DISPATCHER(DL_AlipayEdit, on_dl_AlipayEdit);
	
}

void LoginSessionManager::register_web2login_message()
{
	REG_WEB_DISPATCHER(WL_RequestGameServerInfo, on_wl_request_game_server_info);
    REG_WEB_DISPATCHER(WL_GMMessage, on_wl_request_GMMessage);
//    REG_WEB_DISPATCHER(WL_CashFalse, on_wl_request_cash_false);
//    REG_WEB_DISPATCHER(WL_Recharge, on_wl_request_recharge);
    REG_WEB_DISPATCHER(WL_ChangeTax, on_wl_request_change_tax);
	REG_WEB_DISPATCHER(WL_ChangeMoney, on_wl_request_gm_change_money);
	REG_WEB_DISPATCHER(WL_LuaCmdPlayerResult, on_WL_LuaCmdPlayerResult);
	REG_WEB_DISPATCHER(WL_BroadcastClientUpdate, on_wl_broadcast_gameserver_cmd);
}

void LoginSessionManager::register_login2sms_message()
{
}

void LoginSessionManager::close_all_session()
{
	NetworkAllocator::close_all_session();

	for (auto item : db_session_)
		item->close();
}

void LoginSessionManager::release_all_session()
{
	NetworkAllocator::release_all_session();

	for (auto item : db_session_)
	{
		item->on_closed();
	}
	db_session_.clear();
}

bool LoginSessionManager::tick()
{
	bool ret = NetworkAllocator::tick();

	for (auto item : db_session_)
	{
		if (!item->tick())
			ret = false;
	}

	if (first_connect_db_ == 1)
	{
		on_first_connect_db();
		first_connect_db_ = 2;
	}
	return ret;
}

std::shared_ptr<NetworkSession> LoginSessionManager::create_session(boost::asio::ip::tcp::socket& socket)
{
	return std::static_pointer_cast<NetworkSession>(std::make_shared<LoginSession>(socket));
}

std::shared_ptr<NetworkSession> LoginSessionManager::create_db_session(const std::string& ip, unsigned short port)
{
	auto session = std::make_shared<LoginDBSession>(network_server_->get_io_server_pool().get_io_service());
	session->set_ip_port(ip, port);
	return std::static_pointer_cast<NetworkSession>(session);
}

void LoginSessionManager::set_network_server(NetworkServer* network_server)
{
	NetworkAllocator::set_network_server(network_server);

	auto& cfg = static_cast<LoginServer*>(BaseServer::instance())->get_config();

	for (auto& attr : cfg.db_addr())
	{
		db_session_.push_back(create_db_session(attr.ip(), attr.port()));
	}
}

std::shared_ptr<NetworkSession> LoginSessionManager::get_gate_session(int server_id)
{
	for (auto item : gate_session_)
	{
		if (item->get_server_id() == server_id)
			return item;
	}
	return std::shared_ptr<NetworkSession>();
}

void LoginSessionManager::add_gate_session(std::shared_ptr<NetworkSession> session)
{
	gate_session_.push_back(session);

	//send_open_game_list(session);
}

void LoginSessionManager::del_gate_session(std::shared_ptr<NetworkSession> session)
{
	for (auto it = gate_session_.begin(); it != gate_session_.end(); ++it)
	{
		if (*it == session)
		{
			gate_session_.erase(it);

			//send_open_game_list(session);
			break;
		}
	}
}

std::shared_ptr<NetworkSession> LoginSessionManager::get_game_session(int server_id)
{
	for (auto item : game_session_)
	{
		if (item->get_server_id() == server_id)
			return item;
	}
	return std::shared_ptr<NetworkSession>();
}

void LoginSessionManager::add_game_session(std::shared_ptr<NetworkSession> session)
{
	game_session_.push_back(session);
}

void LoginSessionManager::del_game_session(std::shared_ptr<NetworkSession> session)
{
	for (auto it = game_session_.begin(); it != game_session_.end(); ++it)
	{
		if (*it == session)
		{
			game_session_.erase(it);
			break;
		}
	}
}

std::shared_ptr<NetworkSession> LoginSessionManager::get_db_session()
{
	if (db_session_.empty())
		return std::shared_ptr<NetworkSession>();

	if (cur_db_session_ >= db_session_.size())
		cur_db_session_ = 0;

	return db_session_[cur_db_session_++];
}

void LoginSessionManager::add_game_server_info(int game_id, int first_game_type, int second_game_type, bool default_lobby, int player_limit)
{
	RegGameServerInfo info;
	info.first_game_type = first_game_type;
	info.second_game_type = second_game_type;
	info.default_lobby = default_lobby;
	info.player_limit = player_limit;
	info.cur_player_count = 0;
	std::lock_guard<std::recursive_mutex> lock(mutex_reg_game_server_info_);
	reg_game_server_info_[game_id] = info;

	//broadcast_open_game_list();
}

void LoginSessionManager::remove_game_server_info(int game_id)
{
	std::lock_guard<std::recursive_mutex> lock(mutex_reg_game_server_info_);
	reg_game_server_info_.erase(game_id);

	//broadcast_open_game_list();
}

bool LoginSessionManager::has_game_server_info(int game_id)
{
	std::lock_guard<std::recursive_mutex> lock(mutex_reg_game_server_info_);
	return reg_game_server_info_.find(game_id) != reg_game_server_info_.end();
}

void LoginSessionManager::update_game_server_player_count(int game_id, int count)
{
	std::lock_guard<std::recursive_mutex> lock(mutex_reg_game_server_info_);
	auto it = reg_game_server_info_.find(game_id);
	if (it != reg_game_server_info_.end())
	{
		it->second.cur_player_count = count;
	}
}

int LoginSessionManager::find_a_default_lobby()
{
	int game_id = 0;
	std::lock_guard<std::recursive_mutex> lock(mutex_reg_game_server_info_);
	for (auto& item : reg_game_server_info_)
	{
		if (item.second.default_lobby && item.second.cur_player_count < item.second.player_limit)
		{
			game_id = item.first;
			break;
		}
	}

	return game_id;
}

void LoginSessionManager::print_game_server_info()
{
	std::stringstream ss;
	ss << "print_game_server_info:";
	std::lock_guard<std::recursive_mutex> lock(mutex_reg_game_server_info_);
	for (auto& item : reg_game_server_info_)
	{
		ss << "(" << item.first << "," << item.second.default_lobby << ")";
	}
	LOG_WARN(ss.str().c_str());

}

int LoginSessionManager::find_a_game_id(int first_game_type, int second_game_type)
{
	int game_id = 0;
	std::lock_guard<std::recursive_mutex> lock(mutex_reg_game_server_info_);
	for (auto& item : reg_game_server_info_)
	{
		if (item.second.first_game_type == first_game_type && item.second.second_game_type == second_game_type && item.second.cur_player_count < item.second.player_limit)
		{
			game_id = item.first;
			break;
		}
	}

	return game_id;
}

/*void LoginSessionManager::send_open_game_list(std::shared_ptr<NetworkSession> session)
{
	LG_OpenGameList reply;

	for (auto& item : reg_game_server_info_)
	{
		reply.add_game_id_list(item.first);
	}

	session->send_pb(&reply);
}

void LoginSessionManager::broadcast_open_game_list()
{
	if (gate_session_.empty())
		return;

	LG_OpenGameList reply;

	for (auto& item : reg_game_server_info_)
	{
		reply.add_game_id_list(item.first);
	}

	broadcast2gate_pb(&reply);
}*/

void LoginSessionManager::set_first_connect_db()
{
	if (first_connect_db_ == 0)
	{
		first_connect_db_ = 1;
	}
}

bool LoginSessionManager::is_first_connect_db()
{
	return first_connect_db_ > 0;
}

void LoginSessionManager::on_first_connect_db()
{
	printf(">>>>>>>>>>>>>>>>>>> on_first_connect_db\n");
}

void LoginSessionManager::Add_DB_Server_Session(const std::string& ip, int port)
{
	db_session_.push_back(create_db_session(ip, port));
}
