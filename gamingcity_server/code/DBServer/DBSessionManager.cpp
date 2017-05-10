#include "DBSessionManager.h"
#include "DBSession.h"
#include "GameTimeManager.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG

#define REG_LOGIN_DISPATCHER(Msg, Function) dispatcher_manager_login_.register_dispatcher(new MsgDispatcher< Msg, DBSession >(&DBSession::Function));
#define REG_GAME_DISPATCHER(Msg, Function) dispatcher_manager_game_.register_dispatcher(new MsgDispatcher< Msg, DBSession >(&DBSession::Function));

DBSessionManager::DBSessionManager()
{
	register_connect_message();
	register_login2db_message();
	register_game2db_message();
}

DBSessionManager::~DBSessionManager()
{
}

void DBSessionManager::register_connect_message()
{
	dispatcher_manager_.register_dispatcher(new MsgDispatcher<S_Connect, DBSession>(&DBSession::on_s_connect));
}

void DBSessionManager::register_login2db_message()
{
	REG_LOGIN_DISPATCHER(LD_VerifyAccount, on_ld_verify_account);
	REG_LOGIN_DISPATCHER(LD_RegAccount, on_ld_reg_account);
    REG_LOGIN_DISPATCHER(LD_SmsLogin, on_ld_sms_login);
    REG_LOGIN_DISPATCHER(LD_CashFalse, on_ld_cash_false);
    REG_LOGIN_DISPATCHER(LD_CashReply, on_ld_cash_reply);
    REG_LOGIN_DISPATCHER(LD_CashDeal, on_ld_cash_deal);
//    REG_LOGIN_DISPATCHER(LD_Recharge, on_ld_recharge);
//    REG_LOGIN_DISPATCHER(LD_RechargeReply, on_ld_recharge_reply);
//    REG_LOGIN_DISPATCHER(LD_RechargeDeal, on_ld_recharge_deal);
	REG_LOGIN_DISPATCHER(LD_PhoneQuery, on_ld_phone_query);
    REG_LOGIN_DISPATCHER(LD_OfflineChangeMoney, on_ld_offlinechangemoney_query);
    REG_LOGIN_DISPATCHER(LD_GetServerCfg, on_ld_get_server_cfg);
	REG_LOGIN_DISPATCHER(CL_GetInviterInfo, on_ld_get_inviter_info);
    REG_LOGIN_DISPATCHER(LD_LuaCmdPlayerResult, on_LD_LuaCmdPlayerResult);
    REG_LOGIN_DISPATCHER(LD_AddMoney, on_ld_re_add_player_money);
}

void DBSessionManager::register_game2db_message()
{
	REG_GAME_DISPATCHER(SD_ResetAccount, on_sd_reset_account);
	REG_GAME_DISPATCHER(SD_SetPassword, on_sd_set_password);
	REG_GAME_DISPATCHER(SD_SetPasswordBySms, on_sd_set_password_by_sms);
	REG_GAME_DISPATCHER(SD_SetNickname, on_sd_set_nickname);
    REG_GAME_DISPATCHER(SD_UpdateEarnings, on_sd_update_earnings);
    REG_GAME_DISPATCHER(SD_BandAlipay, on_sd_band_alipay);
    REG_GAME_DISPATCHER(SD_ServerConfig, on_sd_server_cfg);
    REG_GAME_DISPATCHER(SD_ChangMoneyReply, on_sd_changemoney);
    REG_GAME_DISPATCHER(FD_ChangMoneyDeal, on_fd_changemoney);
}

std::shared_ptr<NetworkSession> DBSessionManager::create_session(boost::asio::ip::tcp::socket& socket)
{
	return std::static_pointer_cast<NetworkSession>(std::make_shared<DBSession>(socket));
}

std::shared_ptr<NetworkSession> DBSessionManager::get_login_session(int login_id)
{
	for (auto item : login_session_)
	{
		if (item->get_server_id() == login_id)
			return item;
	}
	return std::shared_ptr<NetworkSession>();
}

void DBSessionManager::add_login_session(std::shared_ptr<NetworkSession> session)
{
	login_session_.push_back(session);
}

void DBSessionManager::del_login_session(std::shared_ptr<NetworkSession> session)
{
	for (auto it = login_session_.begin(); it != login_session_.end(); ++it)
	{
		if (*it == session)
		{
			login_session_.erase(it);
			break;
		}
	}
}

std::shared_ptr<NetworkSession> DBSessionManager::get_game_session(int server_id)
{
	for (auto item : game_session_)
	{
		if (item->get_server_id() == server_id)
			return item;
	}
	return std::shared_ptr<NetworkSession>();
}

void DBSessionManager::add_game_session(std::shared_ptr<NetworkSession> session)
{
	game_session_.push_back(session);
}

void DBSessionManager::del_game_session(std::shared_ptr<NetworkSession> session)
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

void DBSessionManager::add_verify_account(const std::string& account)
{
	verify_account_list_[account] = GameTimeManager::instance()->get_second_time();
}

void DBSessionManager::remove_verify_account(const std::string& account)
{
	verify_account_list_.erase(account);
}

bool DBSessionManager::find_verify_account(const std::string& account)
{
	auto it = verify_account_list_.find(account);
	if (it == verify_account_list_.end())
	{
		return false;
	}

	if (GameTimeManager::instance()->get_second_time() - it->second >= 10)
	{
		verify_account_list_.erase(it);
		return false;
	}
	return true;
}