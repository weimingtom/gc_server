#include "LoginSession.h"
#include "LoginDBSession.h"
#include "LoginSessionManager.h"
#include "GameLog.h"
#include "common_enum_define.pb.h"
#include "RedisConnectionThread.h"
#include "CryptoManager.h"
#include "redis_define.pb.h"
#include "WebGmManager.h"
#include "GameTimeManager.h"
#include "LoginServer.h"

LoginSession::LoginSession(boost::asio::ip::tcp::socket& sock)
	: NetworkSession(sock)
	, dispatcher_manager_(nullptr)
	, port_(0)
	, type_(0)
	, server_id_(0)
{
}

LoginSession::~LoginSession()
{
}

bool LoginSession::on_dispatch(MsgHeader* header)
{
	if (NetworkSession::on_dispatch(header))
	{
		return true;
	}

	if (nullptr == dispatcher_manager_)
	{
		LOG_ERR("dispatcher manager is null");
		return false;
	}

	auto dispatcher = dispatcher_manager_->query_dispatcher(header->id);
	if (nullptr == dispatcher)
	{
		LOG_WARN("msg[%d] not registered", header->id);
		return true;
	}

	return dispatcher->parse(this, header);
}

bool LoginSession::on_accept()
{
	port_ = get_remote_ip_port(ip_);
	LOG_INFO("accept session ... [%s:%d]", ip_.c_str(), port_);

	dispatcher_manager_ = LoginSessionManager::instance()->get_dispatcher_manager();

	return true;
}

void LoginSession::on_closed()
{
	LOG_INFO("session disconnect ... [%s:%d] type:%d", ip_.c_str(), port_, type_);

	switch (type_)
	{
	case ServerSessionFromGate:
		LoginSessionManager::instance()->del_gate_session(shared_from_this());
		break;
	case ServerSessionFromGame:
		LoginSessionManager::instance()->del_game_session(shared_from_this());
		LoginSessionManager::instance()->remove_game_server_info(server_id_);
		break;
	case ServerSessionFromWeb:
		break;
	default:
		LOG_WARN("unknown connect closed %d", type_);
		break;
	}
}

void LoginSession::on_s_connect(S_Connect* msg)
{
	type_ = msg->type();
	switch (type_)
	{
	case ServerSessionFromGate:
		dispatcher_manager_ = LoginSessionManager::instance()->get_dispatcher_manager_gate();
		server_id_ = msg->server_id();
		LoginSessionManager::instance()->add_gate_session(shared_from_this());

		if (LoginSessionManager::instance()->is_first_connect_db())
		{
			S_ConnectDB notify;
			send_pb(&notify);
		}

		LOG_INFO("S_Connect session gateid=%d ... [%s:%d]", server_id_, ip_.c_str(), port_);
		break;
	case ServerSessionFromGame:
		dispatcher_manager_ = LoginSessionManager::instance()->get_dispatcher_manager_game();
		server_id_ = msg->server_id();
		LoginSessionManager::instance()->add_game_session(shared_from_this());
		LoginSessionManager::instance()->add_game_server_info(server_id_, msg->first_game_type(), msg->second_game_type(),
			msg->default_lobby(), msg->player_limit());

		LOG_INFO("S_Connect session gameid=%d ... [%s:%d]", server_id_, ip_.c_str(), port_);
		break;
	case ServerSessionFromWeb:
		dispatcher_manager_ = LoginSessionManager::instance()->get_dispatcher_manager_web();

		LOG_INFO("S_Connect web session ... [%s:%d]", ip_.c_str(), port_);
		break;
	default:
		LOG_WARN("unknown connecting %d", type_);
		close();
	}
}

void LoginSession::on_S_UpdateGamePlayerCount(S_UpdateGamePlayerCount* msg)
{
	LoginSessionManager::instance()->update_game_server_player_count(server_id_, msg->cur_player_count());
}

void LoginSession::on_s_logout(S_Logout* msg)
{
	std::string account = msg->account();
	int session_id = msg->session_id();
	int gate_id = msg->gate_id();
	int guid_ = msg->guid();

	RedisConnectionThread::instance()->command_impl([account, session_id, gate_id, guid_](RedisConnection* con) {
		std::string acc = account;
		if (account.empty())
		{
			con->command(str(boost::format("HGET player_session_gate %1%@%2%") % session_id % gate_id));
			RedisReply reply = con->get_reply();
			if (reply.is_string())
			{
				acc = reply.get_string();
			}
			else
			{
				// 还没有登录成功
				return;
			}
		}

		int guid = guid_;

		if (guid == 0)
		{
			PlayerLoginInfo info;
			if (con->get_player_login_info(acc, &info))
			{
				guid = info.guid();
			}
		}

		if (guid == 0)
		{
			// 还没有返回数据
			con->command(str(boost::format("HDEL player_login_info %1%") % acc));
			return;
		}

		int game_id = con->get_gameid_by_guid(guid);
		if (game_id)
		{
			// 退出消息通知game
		 	S_Logout notify;
		  	notify.set_account(acc);
		  	notify.set_guid(guid);
  
		  	LoginSessionManager::instance()->send2game_pb(game_id, &notify);
		}
	});
}

void LoginSession::on_cl_login(int session_id, CL_Login* msg)
{
	std::string password = msg->password();

	PlayerLoginInfo info;
	info.set_session_id(session_id);
	info.set_gate_id(server_id_);
	info.set_account(msg->account());
	info.set_phone(msg->phone());
	info.set_phone_type(msg->phone_type());
	info.set_version(msg->version());
	info.set_channel_id(msg->channel_id());
	info.set_package_name(msg->package_name());
	info.set_imei(msg->imei());
	info.set_ip(msg->ip());
	info.set_ip_area(msg->ip_area());
	info.set_password(password);

	RedisConnectionThread::instance()->command_impl([info, password](RedisConnection* con) {
		con->command(str(boost::format("HSETNX player_login_info %1% %2%") % info.account() % CryptoManager::to_hex(info.SerializeAsString())));
		RedisReply reply = con->get_reply();
		if (reply.is_integer() && reply.get_integer() == 1)
		{
			if (info.guid())
				con->command(str(boost::format("HSET player_login_info_guid %1% %2%") % info.guid() % CryptoManager::to_hex(info.SerializeAsString())));

			RedisConnectionThread::instance()->add_reply([info, password]() {
				LD_VerifyAccount request;
				auto p = request.mutable_verify_account();
				p->set_account(info.account());
				p->set_password(password);
				request.set_session_id(info.session_id());
				request.set_gate_id(info.gate_id());

				LoginSessionManager::instance()->send2db_pb(&request);
				LOG_INFO("login step login[offline]->LD_VerifyAccount ok,account=%s", info.account().c_str());
			});

			LOG_INFO("login step login[offline]->LD_VerifyAccount,account=%s", info.account().c_str());
		}
		else
		{
			PlayerLoginInfo other;
			if (!con->get_player_login_info(info.account(), &other))
			{
				LC_Login result_;
				result_.set_result(LOGIN_RESULT_REDIS_ERROR);

				LoginSessionManager::instance()->send2client_pb(info.session_id(), info.gate_id(), &result_);
				LOG_ERR("login step login get_player_login_info false[%s]", info.account().c_str());
				return;
			}

			/*if (!other.has_guid())
			{
				LC_Login result_;
				result_.set_result(LOGIN_RESULT_UNCOMPLETED_LOGIN);

				LoginSessionManager::instance()->send2client_pb(info.session_id(), info.gate_id(), &result_);
				LOG_ERR("login step login get_player_login_info uncompleted login[%s]", info.account().c_str());
				return;
			}*/

			if (info.session_id() == other.session_id())
			{
				// 当前已经登陆的客户端再次发送登陆消息
				/*int guid_ = other.guid();
				int game_id = con->get_gameid_by_guid(guid_);
				if (game_id)
				{
					if (LoginSessionManager::instance()->has_game_server_info(game_id))
					{
						RedisConnectionThread::instance()->add_reply([guid_, password, game_id]() {

							LS_LoginNotifyAgain notify;
							notify.set_guid(guid_);
							notify.set_password(password);

							LoginSessionManager::instance()->send2game_pb(game_id, &notify);
						});

						LOG_INFO("login step login[online]->LS_LoginNotifyAgain,account=%s,gameid=%d", info.account().c_str(), game_id);
						return;
					}
				}*/

				LD_VerifyAccount request;
				auto p = request.mutable_verify_account();
				p->set_account(info.account());
				p->set_password(password);
				request.set_session_id(info.session_id());
				request.set_gate_id(info.gate_id());

				LoginSessionManager::instance()->send2db_pb(&request);
				LOG_INFO("login step login[onlin]->LD_VerifyAccount re ok,account=%s", info.account().c_str());
				return;
			}

			RedisConnectionThread::instance()->add_reply([info, other, password]() {
				LG_KickClient reply;
				reply.set_session_id(other.session_id());
				reply.set_reply_account(info.account());
				reply.set_user_data(2);

				if (!LoginSessionManager::instance()->send2gate_pb(other.gate_id(), &reply))
				{
					RedisConnectionThread::instance()->command_impl([info, password, other](RedisConnection* con) {
						con->command(str(boost::format("HDEL player_online_gameid %d") % other.guid()));
						con->command(str(boost::format("HDEL player_session_gate %d@%d") % other.session_id() % other.gate_id()));

						con->command(str(boost::format("HSET player_login_info %1% %2%") % info.account() % CryptoManager::to_hex(info.SerializeAsString())));
						if (info.guid())
							con->command(str(boost::format("HSET player_login_info_guid %1% %2%") % info.guid() % CryptoManager::to_hex(info.SerializeAsString())));

						RedisConnectionThread::instance()->add_reply([info, password]() {
							LD_VerifyAccount request;
							auto p = request.mutable_verify_account();
							p->set_account(info.account());
							p->set_password(password);
							request.set_session_id(info.session_id());
							request.set_gate_id(info.gate_id());

							LoginSessionManager::instance()->send2db_pb(&request);
						});
					});

					LOG_INFO("login step login[online]->LD_VerifyAccount,account=%s", info.account().c_str());
				}
				else
				{
					// 先缓存数据
					RedisConnectionThread::instance()->command(str(boost::format("HSET player_login_info_temp %1% %2%") % info.account() % CryptoManager::to_hex(info.SerializeAsString())));
					LOG_INFO("login step login[online]->LG_KickClient,account=%s, session_id=%d,other_session_id=%d", info.account().c_str(), info.session_id(), other.session_id());
				}
			});
		}
	});
}

void LoginSession::on_cl_reg_account(int session_id, CL_RegAccount* msg)
{
	LD_RegAccount request;
	if (msg->has_account())
	{
		request.set_account(msg->account());
	}
	if (msg->has_password())
	{
		request.set_password(msg->password());
	}
	request.set_session_id(session_id);
	request.set_gate_id(server_id_);
	request.set_phone(msg->phone());
	request.set_phone_type(msg->phone_type());
	request.set_version(msg->version());
	request.set_channel_id(msg->channel_id());
	request.set_package_name(msg->package_name());
	request.set_imei(msg->imei());
	request.set_ip(msg->ip());
	request.set_ip_area(msg->ip_area());

	LoginSessionManager::instance()->send2db_pb(&request);
}

void LoginSession::on_cl_login_by_sms(int session_id, CL_LoginBySms* msg)
{
	PlayerLoginInfo info;
	info.set_session_id(session_id);
	info.set_gate_id(server_id_);
	info.set_account(msg->account());
	info.set_phone(msg->phone());
	info.set_phone_type(msg->phone_type());
	info.set_version(msg->version());
	info.set_channel_id(msg->channel_id());
	info.set_package_name(msg->package_name());
	info.set_imei(msg->imei());
	info.set_ip(msg->ip());
	info.set_ip_area(msg->ip_area());

	std::string phone_ = msg->phone();
	std::string phone_type_ = msg->phone_type();
	std::string version_ = msg->version();
	std::string channel_id_ = msg->channel_id();
	std::string package_name_ = msg->package_name();
	std::string imei_ = msg->imei();
	std::string ip_ = msg->ip();
	std::string ip_area_ = msg->ip_area();

	RedisConnectionThread::instance()->command_impl([info, phone_, phone_type_, version_, channel_id_, package_name_, imei_, ip_, ip_area_](RedisConnection* con) {
		con->command(str(boost::format("HSETNX player_login_info %1% %2%") % info.account() % CryptoManager::to_hex(info.SerializeAsString())));
		RedisReply reply = con->get_reply();
		if (reply.is_integer() && reply.get_integer() == 1)
		{
			RedisConnectionThread::instance()->add_reply([info, phone_, phone_type_, version_, channel_id_, package_name_, imei_, ip_, ip_area_]() {
				LD_SmsLogin request;
				request.set_account(info.account());
				request.set_session_id(info.session_id());
				request.set_gate_id(info.gate_id());
				request.set_phone(phone_);
				request.set_phone_type(phone_type_);
				request.set_version(version_);
				request.set_channel_id(channel_id_);
				request.set_package_name(package_name_);
				request.set_imei(imei_);
				request.set_ip(ip_);
				request.set_ip_area(ip_area_);

				LoginSessionManager::instance()->send2db_pb(&request);
			});
		}
		else
		{
			PlayerLoginInfo other;
			if (!con->get_player_login_info(info.account(), &other))
			{
				LOG_ERR("player[%s] not find", info.account().c_str());
				return;
			}

			/*if (!other.has_guid())
			{
				LC_Login result_;
				result_.set_result(LOGIN_RESULT_UNCOMPLETED_LOGIN);

				LoginSessionManager::instance()->send2client_pb(info.session_id(), info.gate_id(), &result_);
				LOG_ERR("login step loginsms get_player_login_info uncompleted login[%s]", info.account().c_str());
				return;
			}*/

			if (info.session_id() == other.session_id())
			{
				// 当前已经登陆的客户端再次发送登陆消息
				/*int guid_ = other.guid();
				int game_id = con->get_gameid_by_guid(guid_);
				if (game_id)
				{
					if (LoginSessionManager::instance()->has_game_server_info(game_id))
					{
						RedisConnectionThread::instance()->add_reply([guid_, game_id]() {

							LS_LoginNotifyAgain notify;
							notify.set_guid(guid_);

							LoginSessionManager::instance()->send2game_pb(game_id, &notify);
						});
						return;
					}
				}*/

				LD_SmsLogin request;
				request.set_account(info.account());
				request.set_session_id(info.session_id());
				request.set_gate_id(info.gate_id());
				request.set_phone(phone_);
				request.set_phone_type(phone_type_);
				request.set_version(version_);
				request.set_channel_id(channel_id_);
				request.set_package_name(package_name_);
				request.set_imei(imei_);
				request.set_ip(ip_);
				request.set_ip_area(ip_area_);

				LoginSessionManager::instance()->send2db_pb(&request);
				return;
			}

			RedisConnectionThread::instance()->add_reply([info, other]() {
				LG_KickClient reply;
				reply.set_session_id(other.session_id());
				reply.set_reply_account(info.account());
				reply.set_user_data(3);

				if (!LoginSessionManager::instance()->send2gate_pb(other.gate_id(), &reply))
				{
					RedisConnectionThread::instance()->command_impl([info, other](RedisConnection* con) {
						con->command(str(boost::format("HDEL player_online_gameid %d") % other.guid()));
						con->command(str(boost::format("HDEL player_session_gate %d@%d") % other.session_id() % other.gate_id()));

						con->command(str(boost::format("HSET player_login_info %1% %2%") % info.account() % CryptoManager::to_hex(info.SerializeAsString())));
                        con->command(str(boost::format("HSET player_login_info_guid %1% %2%") % info.guid() % CryptoManager::to_hex(info.SerializeAsString())));

						RedisConnectionThread::instance()->add_reply([info]() {
							LD_SmsLogin request;
							request.set_account(info.account());
							request.set_session_id(info.session_id());
							request.set_gate_id(info.gate_id());

							LoginSessionManager::instance()->send2db_pb(&request);
						});
					});
				}
				else
				{
					// 先缓存数据
					RedisConnectionThread::instance()->command(str(boost::format("HSET player_login_info_temp %1% %2%") % info.account() % CryptoManager::to_hex(info.SerializeAsString())));
					LOG_INFO("login step loginsms[online]->LG_KickClient,account=%s", info.account().c_str());
				}
			});
		}
	});
}

void LoginSession::on_L_KickClient(L_KickClient* msg)
{
	std::string account_ = msg->reply_account();
	int userdata = msg->user_data();
	if (userdata == 1)
	{
		RedisConnectionThread::instance()->command_impl([account_](RedisConnection* con) {
			// 登陆请求状态判断
			PlayerLoginInfo info;
			if (con->get_player_login_info_temp(account_, &info))
			{
				LOG_INFO("[%s] reg account, guid = %d", info.account().c_str(), info.guid());

				// 找一个默认大厅服务器
				int gameid = LoginSessionManager::instance()->find_a_default_lobby();
				if (gameid == 0)
				{
					int session_id = info.session_id();
					int gate_id = info.gate_id();

					RedisConnectionThread::instance()->add_reply([session_id, gate_id]() {
						LC_Login reply;
						reply.set_result(LOGIN_RESULT_NO_DEFAULT_LOBBY);

						LoginSessionManager::instance()->send2client_pb(session_id, gate_id, &reply);
					});

					RedisConnectionThread::instance()->command(str(boost::format("HDEL player_login_info %1%") % info.account()));
					RedisConnectionThread::instance()->command(str(boost::format("HDEL player_login_info_guid %1%") % info.guid()));
					LOG_WARN("no default lobby");
					LoginSessionManager::instance()->print_game_server_info();
					return;
				}

				// 存入redis
				con->command(str(boost::format("HDEL player_login_info_temp %1%") % info.account()));

				con->command(str(boost::format("HSET player_online_gameid %1% %2%") % info.guid() % gameid));
				con->command(str(boost::format("HSET player_session_gate %1%@%2% %3%") % info.session_id() % info.gate_id() % info.account()));
				con->command(str(boost::format("HSET player_login_info %1% %2%") % info.account() % CryptoManager::to_hex(info.SerializeAsString())));
				con->command(str(boost::format("HSET player_login_info_guid %1% %2%") % info.guid() % CryptoManager::to_hex(info.SerializeAsString())));
				RedisConnectionThread::instance()->add_reply([gameid, info]() {
					LS_LoginNotify notify;
					notify.mutable_player_login_info()->CopyFrom(info);

					LoginSessionManager::instance()->send2game_pb(gameid, &notify);
				});
			}
		});
	}
	else if (userdata == 2)
	{
		RedisConnectionThread::instance()->command_impl([account_](RedisConnection* con) {
			PlayerLoginInfo info;
			if (con->get_player_login_info_temp(account_, &info))
			{
				LOG_INFO("[%s] login account, guid = %d", info.account().c_str(), info.guid());

				con->command(str(boost::format("HDEL player_login_info_temp %1%") % account_));

				con->command(str(boost::format("HSET player_login_info %1% %2%") % info.account() % CryptoManager::to_hex(info.SerializeAsString())));
				con->command(str(boost::format("HSET player_login_info_guid %1% %2%") % info.guid() % CryptoManager::to_hex(info.SerializeAsString())));

				RedisConnectionThread::instance()->add_reply([info]() {
					LD_VerifyAccount request;
					auto p = request.mutable_verify_account();
					p->set_account(info.account());
					p->set_password(info.password());
					request.set_session_id(info.session_id());
					request.set_gate_id(info.gate_id());

					LoginSessionManager::instance()->send2db_pb(&request);
				});
			}
		});
	}
	else if (userdata == 3)
	{
		RedisConnectionThread::instance()->command_impl([account_](RedisConnection* con) {
			PlayerLoginInfo info;
			if (con->get_player_login_info_temp(account_, &info))
			{
				LOG_INFO("[%s] loginsms account, guid = %d", info.account().c_str(), info.guid());

				con->command(str(boost::format("HDEL player_login_info_temp %1%") % account_));

				con->command(str(boost::format("HSET player_login_info %1% %2%") % info.account() % CryptoManager::to_hex(info.SerializeAsString())));
				con->command(str(boost::format("HSET player_login_info_guid %1% %2%") % info.guid() % CryptoManager::to_hex(info.SerializeAsString())));

				RedisConnectionThread::instance()->add_reply([info]() {
					LD_SmsLogin request;
					request.set_account(info.account());
					request.set_session_id(info.session_id());
					request.set_gate_id(info.gate_id());

					LoginSessionManager::instance()->send2db_pb(&request);
				});
			}
		});
	}

	LOG_INFO("login step login[online]->L_KickClient,account=%s,userdata=%d", account_.c_str(), userdata);
}

void LoginSession::on_ss_change_game(SS_ChangeGame* msg)
{
	// 找目标的服务器
	int gameid = LoginSessionManager::instance()->find_a_game_id(msg->first_game_type(), msg->second_game_type());
	if (gameid == 0)
	{

		SC_EnterRoomAndSitDown reply;
		reply.set_game_id(msg->game_id());
		reply.set_first_game_type(msg->first_game_type());
		reply.set_second_game_type(msg->second_game_type());
		reply.set_result(GAME_SERVER_RESULT_NO_GAME_SERVER);
		LoginSessionManager::instance()->send2client_pb(msg->guid(), msg->gate_id(), &reply);

		LS_ChangeGameResult notify;
		notify.set_guid(msg->guid());
		send_pb(&notify);

		LOG_ERR("gameid=0, (%d,%d)", msg->first_game_type(), msg->second_game_type());
		LoginSessionManager::instance()->print_game_server_info();
		return;
	}

	LS_ChangeGameResult notify;
	notify.set_guid(msg->guid());
	notify.set_success(true);
	notify.mutable_change_msg()->CopyFrom(*msg);
	notify.set_game_id(gameid);
	send_pb(&notify);

	// 转发
	//LoginSessionManager::instance()->send2game_pb(gameid, msg);
}

void LoginSession::on_SL_ChangeGameResult(SL_ChangeGameResult* msg)
{
	// 转发
	LoginSessionManager::instance()->send2game_pb(msg->game_id(), msg->mutable_change_msg());
}

void LoginSession::on_cs_request_sms(CS_RequestSms* msg)
{
	LD_PhoneQuery request;
	request.set_phone(msg->tel());
	request.set_gate_session_id(msg->gate_session_id());
	LoginSessionManager::instance()->send2db_pb(&request);
	return;
	/*
	if (!LoginServerConfigManager::instance()->get_config().using_sms())
	{
		SC_RequestSms notify;
		notify.set_result(LOGIN_RESULT_SMS_CLOSED);
		send_xc_pb(session_id, &notify);
		return;
	}

	int r = rand() % 1000 + (rand() % 1000) * 1000;
	std::string sms_no_ = str(boost::format("%06d") % r);
	LoginSessionManager::instance()->send2sms(session_id, server_id_, msg->tel(), sms_no_);
	*/
}

void LoginSession::on_sd_bank_transfer(SD_BankTransfer* msg)
{
	SD_BankTransfer message = *msg;
	int self_game_id = server_id_;

	RedisConnectionThread::instance()->command_impl([message, self_game_id](RedisConnection* con) {
		PlayerLoginInfo info;
		if (con->get_player_login_info(message.target(), &info))
		{
			int game_id = con->get_gameid_by_guid(info.guid());
			if (game_id)
			{
				if (LoginSessionManager::instance()->has_game_server_info(game_id))
				{
					RedisConnectionThread::instance()->add_reply([message, self_game_id, game_id]() {
						LS_BankTransferSelf notifyself;

						notifyself.set_guid(message.guid());
						notifyself.set_time(message.time());
						notifyself.set_target(message.target());
						notifyself.set_money(message.money());
						notifyself.set_bank_balance(message.bank_balance());

						LoginSessionManager::instance()->send2game_pb(self_game_id, &notifyself);

						LS_BankTransferTarget notifytarget;
						notifytarget.set_selfname(message.selfname());
						notifytarget.set_time(message.time());
						notifytarget.set_target(message.target());
						notifytarget.set_money(message.money());

						LoginSessionManager::instance()->send2game_pb(game_id, &notifytarget);
					});
					return;
				}
			}
		}

		// 不在服务器情况
		RedisConnectionThread::instance()->add_reply([message]() {
			LoginSessionManager::instance()->send2db_pb(&message);
		});
	});
}

void LoginSession::on_sd_bank_transfer_by_guid(S_BankTransferByGuid* msg)
{
	S_BankTransferByGuid message = *msg;
	message.set_game_id(server_id_);

	RedisConnectionThread::instance()->command_impl([message](RedisConnection* con) {
		int game_id = con->get_gameid_by_guid(message.target_guid());
		if (game_id)
		{
			if (LoginSessionManager::instance()->has_game_server_info(game_id))
			{
				RedisConnectionThread::instance()->add_reply([message, game_id]() {
					LS_BankTransferByGuid notify;

					notify.set_guid(message.guid());
					notify.set_money(-message.money());

					LoginSessionManager::instance()->send2game_pb(message.game_id(), &notify);

					notify.set_guid(message.target_guid());
					notify.set_money(message.money());

					LoginSessionManager::instance()->send2game_pb(game_id, &notify);
				});
				return;
			}
		}

		// 不在服务器情况
		RedisConnectionThread::instance()->add_reply([message]() {
			LoginSessionManager::instance()->send2db_pb(&message);
		});
	});
}

void LoginSession::on_cs_chat_world(int session_id, CS_ChatWorld* msg)
{
	LoginSessionManager::instance()->broadcast2game_pb(msg);
}

void LoginSession::on_sc_chat_private(SC_ChatPrivate* msg)
{
	SC_ChatPrivate message = *msg;
	RedisConnectionThread::instance()->command_impl([message](RedisConnection* con) {
		PlayerLoginInfo info;
		if (con->get_player_login_info(message.private_name(), &info))
		{
			int guid = info.guid();
			int game_id = con->get_gameid_by_guid(guid);
			if (game_id)
			{
				RedisConnectionThread::instance()->add_reply([message, game_id]() {
					LoginSessionManager::instance()->send2game_pb(game_id, &message);
				});
			}
		}
	});
}

void LoginSession::on_wl_request_game_server_info(WL_RequestGameServerInfo* msg)
{
	msg->set_id(get_id());
	int n = LoginSessionManager::instance()->broadcast2game_pb(msg);

	auto p = new WebGmGameServerInfo(get_id(), n);
	WebGmManager::instance()->addWebGm(p);
}

void LoginSession::on_sl_web_game_server_info(SL_WebGameServerInfo* msg)
{
	auto p = dynamic_cast<WebGmGameServerInfo*>(WebGmManager::instance()->getWebGm(msg->id()));
	if (p && p->add_info(msg->mutable_info()))
	{
		LoginSessionManager::instance()->send2web_pb(msg->id(), p->get_msg());
		WebGmManager::instance()->removeWebGm(p);
	}
}

void LoginSession::on_wl_request_GMMessage(WL_GMMessage * msg){
    if (msg->gmcommand() == "MSG"){      //公告 消息 //反馈更新
        rapidjson::Document document;
        document.Parse(msg->data().c_str());
        if (checkJsonMember(document, "type", "int", "content", "string", "start_time", "string", "end_time" , "string")){
            LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_MsgParamMiss, get_id());
            return;
        }
        LD_NewNotice request;
		int type = document["type"].GetInt();
		if (type == 3)
		{
			if (!document.HasMember("number") || !document.HasMember("interval_time"))
			{
				Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_MsgParamMiss, get_id());
				return;
			}
		}
		else
		{
			if (!document.HasMember("name") || !document.HasMember("author"))
			{
				Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_MsgParamMiss, get_id());
				return;
			}
		}


        if (document["type"].GetInt() == 1) {   //1消息
            if (!document.HasMember("guid")){
                LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_MsgParamMiss, get_id());
                return;
            }
            request.set_guid(document["guid"].GetInt());
        }
        else if (document["type"].GetInt() == 2){  //公告
        }
		else if (document["type"].GetInt() == 3){  //跑马灯
		}
        else {            // 未知
            LOG_ERR("on_wl_request_GMMessage  type not find : %d", document["type"].GetInt());
            LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_MsgTypeError, get_id());
            return;
        }
        request.set_type(document["type"].GetInt());
        request.set_content(document["content"].GetString());
        request.set_start_time(document["start_time"].GetString());
		request.set_end_time(document["end_time"].GetString());
		if (type == 3)
		{
			request.set_number(document["number"].GetInt());
			request.set_interval_time(document["interval_time"].GetInt());
		}
		else
		{
			request.set_name(document["name"].GetString());
			request.set_author(document["author"].GetString());
		}
        request.set_retid(get_id());
        LOG_INFO("retid:%d", get_id());
        LoginSessionManager::instance()->send2db_pb(&request);
    }
    else if (msg->gmcommand() == "MSG_DELET"){
        rapidjson::Document document;
        document.Parse(msg->data().c_str());
        if (checkJsonMember(document, "type","int", "id","int")){
            LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_MsgParamMiss, get_id());
            return;
        }
        if (document["type"].GetInt() != 1 && document["type"].GetInt() != 2 && document["type"].GetInt() != 3){
            LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_MsgTypeError, get_id());
            return;
        }
        LD_DelMessage request;
        request.set_msg_type(document["type"].GetInt());
        request.set_msg_id(document["id"].GetInt());
        request.set_retid(get_id());
        LoginSessionManager::instance()->send2db_pb(&request);
    }
    else if (msg->gmcommand() == "FeedBack"){
        rapidjson::Document document;
        document.Parse(msg->data().c_str());
        if (checkJsonMember(document, "guid","int","type", "int","updatetime","int", "feedbackid","int")){
            LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_FBParamMiss, get_id());
            return;
        }
        UpdateFeedBack(document);
    }
    else if (msg->gmcommand() == "newServer"){
        rapidjson::Document document;
        document.Parse(msg->data().c_str());
        if (checkJsonMember(document, "ip", "string","port","int")){
            LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_GmParamMiss, get_id());
            return;
        }
        LG_AddNewGameServer request;
        request.set_ip(document["ip"].GetString());
        request.set_port(document["port"].GetInt());
        request.set_retid(get_id());
        LoginSessionManager::instance()->sendgate_All(&request);
        LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_Success, get_id());
    }
	else if (msg->gmcommand() == "EditAlipay"){
		rapidjson::Document document;
		document.Parse(msg->data().c_str());
		if (checkJsonMember(document, "guid", "int", "alipay_name", "string", "alipay_name_y", "string", "alipay_account", "string", "alipay_account_y", "string")){
			LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_FBParamMiss, get_id());
			return;
		}
		EditAliPay(document);
	}
	else if (msg->gmcommand() == "AgentsTransfer"){
		rapidjson::Document document;
		document.Parse(msg->data().c_str());
		if (checkJsonMember(document, "proxy_guid", "int", "player_guid", "int", "transfer_id", "int", "transfer_type", "int", "transfer_money", "int")){
			LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_GmParamMiss, get_id());
			return;
		}
		AgentsTransferData stData;
		stData.set_agentsid(document["proxy_guid"].GetInt());
		stData.set_playerid(document["player_guid"].GetInt());
		stData.set_transfer_id(document["transfer_id"].GetInt());
		stData.set_transfer_type(document["transfer_type"].GetInt());
		stData.set_transfer_money(document["transfer_money"].GetInt());
		stData.set_retid(get_id());
		if (stData.transfer_money() <= 0){
			/*LD_AgentsTransfer_finish stFinish;
			stFinish.mutable_pb_result()->CopyFrom(stData);
			stFinish.set_retid();
			LoginSessionManager::instance()->send2db_pb(&stFinish);*/
			LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_ATMoneyParamError, get_id());
			return;
		}
		if (stData.transfer_type() == 0){
			//查两个号是否有转账功能
		}
		else if (stData.transfer_type() == 1){
			//查玩家A是否有转账功能
		}
		else if (stData.transfer_type() == 2){
			//查玩家B是否有转账功能

		}
		else{
			// type 错误
			LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_ATtypeError, get_id());
			return;
		}
		if (stData.agentsid() == stData.playerid()){
			// 代理商id 与 玩家id 相同
			LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_AT_PL_onePlayer, get_id());			
		}
		std::string keyid = boost::lexical_cast<std::string>(stData.transfer_id()) + boost::lexical_cast<std::string>(GameTimeManager::instance()->get_second_time());
		std::string strSQL = str(boost::format("call check_is_agent(%1%,%2%)") % stData.agentsid() % stData.playerid());
		create_do_Sql(keyid, "account", strSQL, CryptoManager::to_hex(stData.SerializeAsString()),[=](int retCode,std::string retData, std::string strData){
			if (retCode == 9999){
				LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_DBRquestError, get_id());
				return;
			}
			AgentsTransferData stDataR;
			stDataR.ParseFromString(CryptoManager::from_hex(strData));
			int pl = retCode % 10;
			int ATe = retCode / 10;

			if (pl == 9){
				//查无此人
				LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_PLnofindUser, get_id());
				return;
			}
			if (ATe == 9){
				//查无此人
				LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_ATnofindUser, get_id());
				return;
			}
			if (stData.transfer_type() == 0){
				//查两个号是否有转账功能
				if (pl + ATe != 0){
					//返回错误
					if (ATe != 0){
						//返回错误
						LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_ATCantTransfer, get_id());
						return;
					}
					if (pl != 0){
						//返回错误
						LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_PLCantTransfer, get_id());
						return;
					}
				}
			}
			else if (stData.transfer_type() == 1){
				//查玩家A是否有转账功能
				if (ATe != 0){
					//返回错误
					LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_ATCantTransfer, get_id());
					return;
				}
			}
			else if (stData.transfer_type() == 2){
				//查玩家B是否有转账功能
				if (pl != 0){
					//返回错误
					LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_PLCantTransfer, get_id());
					return;
				}
			}
			on_AT_PL_ChangeMoney(stData);
		});		
	}
	else if (msg->gmcommand() == "FreezeAccount"){
		rapidjson::Document document;
		document.Parse(msg->data().c_str());
		if (checkJsonMember(document, "guid", "int", "status", "int")){
			LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_GmParamMiss, get_id());
			return;
		}
		LS_FreezeAccount stData;
		stData.set_guid(document["guid"].GetInt());
		stData.set_status(document["status"].GetInt());
		stData.set_retid(get_id());
		stData.set_login_id(server_id_);


		std::string keyid = boost::lexical_cast<std::string>(stData.guid()) + boost::lexical_cast<std::string>(GameTimeManager::instance()->get_second_time());
		std::string strSQL = str(boost::format("call FreezeAccount(%1%,%2%)") % stData.guid() % stData.status());
		create_do_Sql(keyid, "account", strSQL, CryptoManager::to_hex(stData.SerializeAsString()), [=](int retCode, std::string retData, std::string strData){
			if (retCode != 0){
				// 修改数据库失败 报错
				LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_DBRquestError, get_id());
				return;
			}
			LS_FreezeAccount stDataR;
			stDataR.ParseFromString(CryptoManager::from_hex(strData));
			int guid = stDataR.guid();
			int status = stDataR.status();
			int retid = stDataR.retid();
			int server_idT = stData.login_id();
			LoginSession::player_is_online(stDataR.guid(), [stDataR, guid, status, retid, server_idT](int gateid, int sessionid, std::string aacount){
				if (!(gateid == -1)) {
					//玩家在线
					RedisConnectionThread::instance()->command_impl([stDataR,guid, status, retid](RedisConnection* con){
						char cBuff[256] = { 0 };
						sprintf(cBuff, "HGET player_online_gameid %d", guid);
						std::string strB = cBuff;
						con->command(strB);
						RedisReply reply = con->get_reply();
						reply = con->get_reply();
						if (reply.is_string())
						{
							int Server_id = boost::lexical_cast<int>(reply.get_string());
							LoginSessionManager::instance()->send2game_pb(Server_id, &stDataR);
						}
						else
						{
							// 未取到所在服务器 不处理 GMmessageRetCode_FreezeAccountOnLineFaild
							LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_FreezeAccountOnLineFaild, retid);
							return;
						}
					});
				}
				else{
					//玩家不在线 返回成功
					LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_Success, retid);
					return;
				}
			});
		});
	}
    else{
        LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_GmCommandError, get_id());
        return;
    }
}
void LoginSession::EditAliPay(rapidjson::Document &document){
	int guid = document["guid"].GetInt();
	std::string alipay_name = document["alipay_name"].GetString();
	std::string alipay_name_y = document["alipay_name_y"].GetString();
	std::string alipay_account = document["alipay_account"].GetString();
	std::string alipay_account_y = document["alipay_account_y"].GetString();
	int retid = get_id();
	LoginSession::player_is_online(guid, [guid, alipay_name, alipay_name_y, alipay_account, alipay_account_y, retid](int gateid, int sessionid, std::string aacount){
		if (!(gateid == -1)) {
			//玩家在线
			RedisConnectionThread::instance()->command_impl([guid, alipay_name, alipay_name_y, alipay_account, alipay_account_y](RedisConnection* con){
				con->command(str(boost::format("HGET player_online_gameid %1%") % guid));
				RedisReply reply = con->get_reply();
				reply = con->get_reply();
				if (reply.is_string())
				{
					int Server_id = boost::lexical_cast<int>(reply.get_string());
					LS_AlipayEdit notifyresult;

					notifyresult.set_guid(guid);
					notifyresult.set_alipay_name(alipay_name);
					notifyresult.set_alipay_name_y(alipay_name_y);
					notifyresult.set_alipay_account(alipay_account);
					notifyresult.set_alipay_account_y(alipay_account_y);

					LoginSessionManager::instance()->send2game_pb(Server_id, &notifyresult);
				}
				else
				{
					// 未取到所在服务器 不处理
				}
			});
		}

		LD_AlipayEdit stData;
		stData.set_guid(guid);
		stData.set_alipay_name(alipay_name);
		stData.set_alipay_name_y(alipay_name_y);
		stData.set_alipay_account(alipay_account);
		stData.set_alipay_account_y(alipay_account_y);
		stData.set_retid(retid);
		LoginSessionManager::instance()->send2db_pb(&stData);
	});

}
void LoginSession::on_AT_PL_ChangeMoney(AgentsTransferData stData){
	//扣减代理商bank金钱
	std::string keyid = boost::lexical_cast<std::string>(stData.transfer_id())+boost::lexical_cast<std::string>(GameTimeManager::instance()->get_second_time());
	cost_player_bank_money(keyid, stData.agentsid(), -(stData.transfer_money()), CryptoManager::to_hex(stData.SerializeAsString()), [=](int  retCode, int oldmoeny, int newmoney, std::string strData){
		AgentsTransferData stData;
		stData.ParseFromString(CryptoManager::from_hex(strData));
		if (retCode == ChangeMoneyRecode::ChangMoney_Success){
			//下一步给用户加钱
			int oldmoeny_ = oldmoeny;
			int newmoney_ = newmoney;
			std::string keyid = boost::lexical_cast<std::string>(stData.transfer_id()) + boost::lexical_cast<std::string>(GameTimeManager::instance()->get_second_time());
			cost_player_bank_money(keyid, stData.playerid(), stData.transfer_money(), strData, [=](int  retCode, int oldmoeny, int newmoney, std::string strData){
				AgentsTransferData stData;
				stData.ParseFromString(CryptoManager::from_hex(strData));
				if (retCode == ChangeMoneyRecode::ChangMoney_Success){
					//都成功了 下发消息
					LD_AgentsTransfer_finish stFinish;
					stFinish.mutable_pb_result()->CopyFrom(stData);
					stFinish.set_retid(GMmessageRetCode::GMmessageRetCode_Success);
					stFinish.set_a_oldmoney(oldmoeny_);
					stFinish.set_a_newmoney(newmoney_);
					stFinish.set_p_oldmoney(oldmoeny);
					stFinish.set_p_newmoney(newmoney);
					LoginSessionManager::instance()->send2db_pb(&stFinish);
					LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_Success, stData.retid());
				}
				else {
					//回退代理商金钱
					int playerChangeErrroCode = retCode;
					cost_player_bank_money(keyid, stData.agentsid(), stData.transfer_money(), strData, [=](int  retCode, int oldmoeny, int newmoney, std::string strData){
						AgentsTransferData stData;
						stData.ParseFromString(CryptoManager::from_hex(strData));
						if (retCode == ChangeMoneyRecode::ChangMoney_Success){
							//都成功了 下发消息
							int endCode = GMmessageRetCode::GMmessageRetCode_ATtypeError + playerChangeErrroCode;
							LD_AgentsTransfer_finish stFinish;
							stFinish.mutable_pb_result()->CopyFrom(stData);
							stFinish.set_retid(endCode);
							stFinish.set_a_oldmoney(0);
							stFinish.set_a_newmoney(0);
							stFinish.set_p_oldmoney(0);
							stFinish.set_p_newmoney(0);
							LoginSessionManager::instance()->send2db_pb(&stFinish);
							LoginSession::Ret_GMMessage(endCode, stData.retid());
						}
						else {
							//回退代理商金钱失败
							int endCode = (GMmessageRetCode::GMmessageRetCode_ATtypeError + playerChangeErrroCode) * 1000 + retCode;
							LD_AgentsTransfer_finish stFinish;
							stFinish.mutable_pb_result()->CopyFrom(stData);
							stFinish.set_retid(endCode);
							stFinish.set_a_oldmoney(0);
							stFinish.set_a_newmoney(0);
							stFinish.set_p_oldmoney(0);
							stFinish.set_p_newmoney(0);
							LoginSessionManager::instance()->send2db_pb(&stFinish);
							LoginSession::Ret_GMMessage(endCode, stData.retid());
						}
					});
				}
			});
		}
		else{
			//返回失败
			LD_AgentsTransfer_finish stFinish;
			stFinish.mutable_pb_result()->CopyFrom(stData);
			stFinish.set_retid(GMmessageRetCode::GMmessageRetCode_ATMoneyParamError + retCode);
			stFinish.set_a_oldmoney(0);
			stFinish.set_a_newmoney(0);
			stFinish.set_p_oldmoney(0);
			stFinish.set_p_newmoney(0);
			LoginSessionManager::instance()->send2db_pb(&stFinish);
			LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_ATMoneyParamError + retCode, stData.retid());
		}
	});
}
bool LoginSession::cost_player_bank_money(std::string keyid, int guid, int money, std::string strData, std::function<void(int  retCode, int oldmoeny, int newmoney, std::string strData)> func){
	while (m_mapCostBankFunc.find(keyid) != m_mapCostBankFunc.end()){
		keyid = boost::lexical_cast<std::string>(boost::lexical_cast<int>(keyid)+1);
	}
	stCostBankMoeny stData;
	stData.m_data = strData;
	stData.func = func;
	m_mapCostBankFunc[keyid] = stData;

	int guid_ = guid;
	std::string keyid_ = keyid;
	int money_ = money;
	int retid = get_id();
	int server_id = server_id_;
	std::map<std::string, stCostBankMoeny > * lpMap = &m_mapCostBankFunc;
	//开始扣减
	//判断玩家是否在线
	player_is_online(guid, [guid_, keyid_, money_, retid, server_id, func, lpMap](int gateid, int sessionid, std::string aacount){
		// 修改玩家数据
		LS_CC_ChangeMoney request;
		request.set_guid(guid_);
		request.set_money(money_);
		request.set_keyid(keyid_);
		request.set_retid(retid);
		request.set_login_id(server_id);
		if (gateid == -1) {

            //直接修改数据库中数据
            LD_CC_ChangeMoney stDB_Data;
            stDB_Data.set_guid(request.guid());
            stDB_Data.set_money(request.money());
            stDB_Data.set_keyid(request.keyid());
            stDB_Data.set_retid(request.retid());
            stDB_Data.set_login_id(request.login_id());
            LoginSessionManager::instance()->send2db_pb(&stDB_Data);
			//玩家不在线 查询redis
			//RedisConnectionThread::instance()->command_impl([request, lpMap](RedisConnection* con){
			//	con->command(str(boost::format("HGET player_base_info %1%") % request.guid()));
			//	RedisReply data = con->get_reply();
			//	if (data.is_string())
			//	{
			//		PlayerBaseInfo pb_info;
			//		pb_info.ParseFromString(CryptoManager::from_hex(data.get_string()));
			//		if (request.money() < 0){
			//			if (pb_info.bank() + request.money() < 0){
			//				//返回错误
			//				auto aIterator = lpMap->find(request.keyid());
			//				if (aIterator == lpMap->end()){
			//					// 不能吧，才入一值，如果是这样 应该是匿名函数 传递值 出了问题。
			//					LOG_ERR("===========cost_player_bank_money 中 查询 player_online_gameid失败 且才入了map的值 又未取到");
			//					return;
			//				}
			//				stCostBankMoeny tempData = aIterator->second;
			//				lpMap->erase(aIterator);
			//				tempData.func(ChangeMoneyRecode::ChangMoney_NotEnoughMoney, 0, 0, tempData.m_data);
			//				return;
			//			}
			//		}
			//		int oldmoen = pb_info.bank();
			//		pb_info.set_bank(pb_info.bank() + request.money());
			//		con->command(str(boost::format("HSET player_base_info %1% %2%") % request.guid() % CryptoManager::to_hex(pb_info.SerializeAsString())));
			//		// 成功处理
			//		auto aIterator = lpMap->find(request.keyid());
			//		if (aIterator == lpMap->end()){
			//			// 不能吧，才入一值，如果是这样 应该是匿名函数 传递值 出了问题 回退扣减金钱。
			//			LOG_ERR("===========cost_player_bank_money 中 查询 player_online_gameid失败 且才入了map的值 又未取到");
			//			LOG_ERR("guid[%d] money[%d]", request.guid(), request.money());
			//			pb_info.set_bank(pb_info.bank() - request.money());
			//			con->command(str(boost::format("HSET player_base_info %1% %2%") % request.guid() % CryptoManager::to_hex(pb_info.SerializeAsString())));
			//			return;
			//		}
			//		stCostBankMoeny tempData = aIterator->second;
			//		lpMap->erase(aIterator);
			//		tempData.func(ChangeMoneyRecode::ChangMoney_Success, oldmoen, pb_info.bank(), tempData.m_data);
			//	}
			//	else{
			//		//直接修改数据库中数据
			//		LD_CC_ChangeMoney stDB_Data;
			//		stDB_Data.set_guid(request.guid());
			//		stDB_Data.set_money(request.money());
			//		stDB_Data.set_keyid(request.keyid());
			//		stDB_Data.set_retid(request.retid());
			//		stDB_Data.set_login_id(request.login_id());
			//		LoginSessionManager::instance()->send2db_pb(&stDB_Data);
			//	}
			//});
			return;
		}
		RedisConnectionThread::instance()->command_impl([request, lpMap](RedisConnection* con){
			con->command(str(boost::format("HGET player_online_gameid %1%") % request.guid()));
			RedisReply reply = con->get_reply();
			reply = con->get_reply();
			if (reply.is_string())
			{
				int Server_id = boost::lexical_cast<int>(reply.get_string());
				LoginSessionManager::instance()->send2game_pb(Server_id, &request);
				return;
			}
			else
			{
				// 处理失败
				auto aIterator = lpMap->find(request.keyid());
				if (aIterator == lpMap->end()){
					// 不能吧，才入一值，如果是这样 应该是匿名函数 传递值 出了问题。
					LOG_ERR("===========cost_player_bank_money 中 查询 player_online_gameid失败 且才入了map的值 又未取到 请联系程序解决问题");
					return;
				}
				stCostBankMoeny tempData = aIterator->second;
				lpMap->erase(aIterator);
				tempData.func(ChangeMoneyRecode::ChangMoney_JudgmentPlayerOnlineError, 0, 0, tempData.m_data);
			}
		});
	});
	return true;
}

void LoginSession::create_do_Sql(std::string  keyid, std::string database, std::string strSql, std::string strData, std::function<void(int  retCode, std::string retData, std::string stData)> func){
	while (m_mapDoSql.find(keyid) != m_mapDoSql.end()){
		keyid = boost::lexical_cast<std::string>(boost::lexical_cast<int>(keyid)+1);
	}
	stDoSql stData;
	stData.m_data = strData;
	stData.func = func;
	m_mapDoSql[keyid] = stData;

	LD_DO_SQL stDB_Data;
	stDB_Data.set_sql(strSql);
	stDB_Data.set_retid(get_id());
	stDB_Data.set_keyid(keyid);
	stDB_Data.set_database(database);
	LoginSessionManager::instance()->send2db_pb(&stDB_Data);

}
void LoginSession::on_do_SqlReQuest(DL_DO_SQL * msg){
	auto aIterator = m_mapDoSql.find(msg->keyid());
	if (aIterator == m_mapDoSql.end()){
		LOG_ERR("===========on_do_SqlReQuest 未取到map数据 retcode[%d] retdata[%s]  请联系程序解决问题 ", msg->retcode(), msg->retdata().c_str());
		return;
	}
	stDoSql tempData = aIterator->second;
	m_mapDoSql.erase(aIterator);
	tempData.func(msg->retcode(), msg->retdata(), tempData.m_data);	
}
void LoginSession::on_DB_Request(DL_CC_ChangeMoney * msg){
	auto aIterator = m_mapCostBankFunc.find(msg->keyid());
	if (aIterator == m_mapCostBankFunc.end()){		
		LOG_ERR("===========on_DB_Request 未取到map数据guid[%d]money[%d]retCode[%d] 请联系程序解决问题",msg->guid(),msg->money(),msg->retcode());
		return;
	}
	stCostBankMoeny tempData = aIterator->second;
	m_mapCostBankFunc.erase(aIterator);
	tempData.func(msg->retcode(), msg->oldmoney(), msg->newmoney(), tempData.m_data);
}
void LoginSession::on_sl_FreezeAccount(SL_FreezeAccount * msg){
	if (msg->ret() == 0){
		LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_Success, msg->retid());
	}
	else{
		LoginSession::Ret_GMMessage(GMmessageRetCode::GMmessageRetCode_FreezeAccountGameFaild, msg->retid());
	}
}
void LoginSession::on_SL_AT_ChangeMoney(SL_CC_ChangeMoney* msg){
	auto t_iterator = m_mapCostBankFunc.find(msg->keyid());
	if (t_iterator == m_mapCostBankFunc.end()){
		//错误处理

	}
	stCostBankMoeny tempData = t_iterator->second;
	m_mapCostBankFunc.erase(t_iterator);
	tempData.func(msg->retcode(), msg->oldmoney(), msg->newmoney(), tempData.m_data);
}
void LoginSession::UpdateFeedBack(rapidjson::Document &document){
    int guid = document["guid"].GetInt();
    int RetID = get_id();
    int type = document["type"].GetInt();
    int updatetime = document["updatetime"].GetInt();
    int feedbackid = document["feedbackid"].GetInt();
    LoginSession::player_is_online(guid, [guid, type, updatetime, RetID, feedbackid](int gateid, int sessionid, std::string aacount){
        if (gateid == -1) {
            //玩家不在线
            LW_GMMessage notify;
            notify.set_result(GMmessageRetCode::GMmessageRetCode_FBPlayerOffline);
            LoginSessionManager::instance()->send2web_pb(RetID, &notify);
            return;
        }
        LG_FeedBackUpdate request;
        request.set_guid(guid);
        request.set_type(type);
        request.set_updatetime(updatetime);
        request.set_retid(RetID);
        request.set_feedbackid(feedbackid);
        LoginSessionManager::instance()->send2gate_pb(gateid, &request);
    });
}
void LoginSession::player_is_online(int guid, const std::function<void(int  gateid, int sessionid, std::string account)>& func){
    RedisConnectionThread::instance()->command_query([func](RedisReply * reply){
        int gateid = -1;
        int sessionid = -1;
        std::string account = "";
        if (reply->is_string()){
            PlayerLoginInfo other;
            if (!other.ParseFromString(CryptoManager::from_hex(reply->get_string())))
            {
                LOG_ERR("ParseFromString failed, accout:%s", other.account().c_str());
            }
            gateid = other.gate_id();
            sessionid = other.session_id();
            account = other.account();
        }
        func(gateid, sessionid, account);
    }, str(boost::format("HGET player_login_info_guid %1%") % guid));
}
void LoginSession::on_gl_NewNotice(GL_NewNotice * msg){
    LoginSession::Ret_GMMessage(msg->result(), msg->retid());
}
void LoginSession::Ret_GMMessage(int retCode, int retID){
    LW_GMMessage notify;
    notify.set_result(retCode);
    LoginSessionManager::instance()->send2web_pb(retID, &notify);
}
bool LoginSession::checkJsonMemberT(rapidjson::Document &document,int start, ...){
    va_list args;
    char * lp = NULL;
    char * lp_type = NULL;
    va_start(args, start);
    do
    {
            lp = va_arg(args, char *);
            if (lp != NULL){
                if (strcmp(lp, endStr) == 0){
                    break;
                }
                if (!document.HasMember(lp)){
                    LOG_ERR("param [%s] not find", lp);
                    return true;
                }
            }
            lp_type = va_arg(args, char *);
            if (lp_type != NULL){
                if (strcmp(lp_type, endStr) == 0){
                    break;
                }
                if (strcmp(lp_type, "int") == 0){
                    if (!document[lp].IsInt()){
                        return true;
                    }
                }
                if (strcmp(lp_type, "int64") == 0){
                    if (!document[lp].IsInt64()){
                        return true;
                    }
                }
                else if (strcmp(lp_type, "string") == 0){
                    if (!document[lp].IsString()){
                        return true;
                    }
                }
                else if (strcmp(lp_type, "bool") == 0){
                    if (!document[lp].IsBool()){
                        return true;
                    }
                }
                else if (strcmp(lp_type, "float") == 0){
                    if (!document[lp].IsFloat()){
                        return true;
                    }
                }
            }
    } while (true);
    va_end(args);
    return false;
}
//void LoginSession::on_wl_request_cash_false(WL_CashFalse* msg)
//{
//    LD_CashFalse notify;
//    notify.set_web_id (get_id());
//    notify.set_order_id(msg->order_id());
//	notify.set_login_id(get_server_id());
//	notify.set_del(msg->del());
//    LoginSessionManager::instance()->send2db_pb(&notify); 
//}
extern void dl_cashfalseinfo(DL_CashFalseInfo * msg);
extern void Re_Add_Player_Money(int Guid, int Money, int Add_Type);
void LoginSession::on_sl_cash_false_reply(SL_CashReply* msg)
{
    if (msg->result() != 5)
    {
        LD_CashReply  notify;
        notify.set_web_id(msg->web_id());
        notify.set_result(msg->result());
        notify.set_order_id(msg->order_id());
        LoginSessionManager::instance()->send2db_pb(&notify);

        LW_CashFalse reply;
        reply.set_result(msg->result());
        LoginSessionManager::instance()->send2web_pb(msg->web_id(), &reply);
    }
    else
    {
        /*DL_CashFalseInfo nmsg;
        nmsg.set_web_id(msg->web_id());
        nmsg.mutable_info()->CopyFrom(msg->info());
        dl_cashfalseinfo(&nmsg);*/
        LW_CashFalse reply;
        reply.set_result(msg->result());
        LoginSessionManager::instance()->send2web_pb(msg->web_id(), &reply);
    }
}

//void LoginSession::on_wl_request_recharge(WL_Recharge* msg)
//{
//    LD_Recharge notify;
//    notify.set_web_id(get_id());
//    notify.set_order_id(msg->order_id());
//    notify.set_login_id(get_server_id());
//    LoginSessionManager::instance()->send2db_pb(&notify);
//}
//extern void dl_rechargeinfo(DL_RechargeInfo * msg);
//void LoginSession::on_sl_recharge_reply(SL_RechargeReply* msg)
//{
//    if (msg->result() != 5)
//    {
//        LD_RechargeReply  notify;
//        notify.set_web_id(msg->web_id());
//        notify.set_result(msg->result());
//        notify.set_order_id(msg->order_id());
//        notify.set_befor_bank(msg->befor_bank());
//        notify.set_after_bank(msg->after_bank());
//        LoginSessionManager::instance()->send2db_pb(&notify);
//
//        LW_Recharge reply;
//        reply.set_result(msg->result());
//        LoginSessionManager::instance()->send2web_pb(msg->web_id(), &reply);
//    }
//    else
//    {
//        /*DL_RechargeInfo nmsg;
//        nmsg.set_web_id(msg->web_id());
//        nmsg.mutable_info()->CopyFrom(msg->info());
//        dl_rechargeinfo(&nmsg);*/
//		
//        LW_Recharge reply;
//        reply.set_result(msg->result());
//        LoginSessionManager::instance()->send2web_pb(msg->web_id(), &reply);
//    }
//}

void LoginSession::on_wl_request_change_tax(WL_ChangeTax* msg)
{
    LS_ChangeTax notify;
    notify.set_webid(get_id());
    notify.set_tax(msg->tax());
    notify.set_is_show(msg->is_show());
    notify.set_is_enable(msg->is_enable());
    auto session = LoginSessionManager::instance()->get_game_session(msg->id());
    if (session)
    {
        LoginSessionManager::instance()->send2game_pb(msg->id(), &notify);
    }
    else
    {
        LW_ChangeTax reply;
        reply.set_result(2);
        LoginSessionManager::instance()->send2web_pb(get_id(), &reply);
    }
}

void LoginSession::on_sl_change_tax_reply(SL_ChangeTax* msg)
{
    LW_ChangeTax reply;
    reply.set_result(msg->result());
    LoginSessionManager::instance()->send2web_pb(msg->webid(), &reply);
}

void LoginSession::on_wl_request_gm_change_money(WL_ChangeMoney *msg)
{
	WL_ChangeMoney tempmsg;
	tempmsg.set_guid(msg->guid());
	tempmsg.set_gmcommand(msg->gmcommand());
	int webid = get_id();
	//判断是否在线
	LoginSession::player_is_online(tempmsg.guid(), [tempmsg,webid](int gateid, int sessionid, std::string account){
		if (gateid == -1)
		{
			//玩家不在线,返回失败
		/*	LW_ChangeMoney replyResult;
			replyResult.set_result(2);
			LoginSessionManager::instance()->send2web_pb(webid, &replyResult);*/
			LD_OfflineChangeMoney queryInfo;
			queryInfo.set_guid(tempmsg.guid());
			queryInfo.set_gmcommand(tempmsg.gmcommand());
			LoginSessionManager::instance()->send2db_pb(&queryInfo);
			LW_ChangeMoney replyinfo;//直接返回成功,因为是异步调用
			replyinfo.set_result(1);
			LoginSessionManager::instance()->send2web_pb(webid, &replyinfo);
			return;
		}
		else
		{
			RedisConnectionThread::instance()->command_impl([tempmsg, gateid, sessionid, account,webid](RedisConnection* con){
				con->command(str(boost::format("HGET player_online_gameid %1%") % tempmsg.guid()));
				RedisReply reply = con->get_reply();
				reply = con->get_reply();
				if (reply.is_string())
				{
					int Server_id = boost::lexical_cast<int>(reply.get_string());
					LS_ChangeMoney notifyresult;
					notifyresult.set_webid(webid);
					notifyresult.set_guid(tempmsg.guid());
					notifyresult.set_gmcommand(tempmsg.gmcommand());
					LoginSessionManager::instance()->send2game_pb(Server_id, &notifyresult);
					LW_ChangeMoney reply;//直接返回成功,因为是异步调用
					reply.set_result(1);
					LoginSessionManager::instance()->send2web_pb(webid, &reply);
					return;
				}
				else
				{
					LD_OfflineChangeMoney query_Info;
					query_Info.set_guid(tempmsg.guid());
					query_Info.set_gmcommand(tempmsg.gmcommand());
					LoginSessionManager::instance()->send2db_pb(&query_Info);
					LW_ChangeMoney reply_info;//直接返回成功,因为是异步调用
					reply_info.set_result(1);
					LoginSessionManager::instance()->send2web_pb(webid, &reply_info);
					//LoginSessionManager::instance()->send2web_pb(webid, &replyinfo);
					////返回失败
					//LW_ChangeMoney Result;
					//Result.set_result(2);
					//LoginSessionManager::instance()->send2web_pb(webid, &Result);
				}
			});
		}
		
	});
	return;
}
void LoginSession::on_WL_LuaCmdPlayerResult(WL_LuaCmdPlayerResult* msg)
{
	int webid = get_id();
	int guid = msg->guid();
	std::string cmd = msg->cmd();

	RedisConnectionThread::instance()->command_impl([webid, guid, cmd](RedisConnection* con) {
		if (con->get_player_login_info_guid(guid))
		{
			int game_id = con->get_gameid_by_guid(guid);
			if (game_id)
			{
				// 在线
				LS_LuaCmdPlayerResult notify;
				notify.set_web_id(webid);
				notify.set_cmd(cmd);
				LoginSessionManager::instance()->send2game_pb(game_id, &notify);
				return;
			}
		}

		// 不在线
		LD_LuaCmdPlayerResult notify;
		notify.set_web_id(webid);
		notify.set_cmd(cmd);
		LoginSessionManager::instance()->send2db_pb(&notify);
	});
}

void LoginSession::on_SL_LuaCmdPlayerResult(SL_LuaCmdPlayerResult* msg)
{
	LW_LuaCmdPlayerResult notify;
	notify.set_result(msg->result());
	LoginSessionManager::instance()->send2web_pb(msg->web_id(), &notify);
}

void LoginSession::on_gl_get_server_cfg(int session_id, GL_GetServerCfg* msg)
{
    LD_GetServerCfg nmsg;
    nmsg.set_gid(server_id_);
    LoginSessionManager::instance()->send2db_pb(&nmsg);
}

void LoginSession::on_cl_get_server_cfg(int session_id, CL_GetInviterInfo* msg)
{
    msg->set_gate_session_id(session_id);
    msg->set_gate_id(server_id_);
    LoginSessionManager::instance()->send2db_pb(msg);
}

void LoginSession::on_wl_broadcast_gameserver_cmd(WL_BroadcastClientUpdate *msg)
{
	int webid = get_id();
	LW_ClientUpdateResult result;
	
	if (LoginSessionManager::instance()->broadcast2game_pb(msg) <= 0)
	{
		LOG_ERR("broadcast gameserver client update error.\n");
		result.set_result(2);
		LoginSessionManager::instance()->send2web_pb(webid, &result);
	}
	else
	{
		result.set_result(1);
		LoginSessionManager::instance()->send2web_pb(webid, &result);
	}
}

void LoginSession::on_SL_AddMoney(SL_AddMoney* msg)
{
    //Re_Add_Player_Money(msg->guid(),msg->money(),msg->add_type());
}